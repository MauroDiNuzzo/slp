% slp.pl
% Last modified: 3/13/2024 by Mauro DiNuzzo

:- module(slp, [
	true/1,
	false/1,
	sample/2,
	sample/3,
	learn/2,
	learn/3
]).

:- use_module(library(debug)).
%:- debug(slp).
%:- nodebug(slp).

:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(pairs)).
:- use_module(library(yall)).
:- use_module(library(random)).
:- use_module(library(option)).

:- use_module(library(error)).

:- dynamic error:has_type/2.
:- multifile error:has_type/2.

error:has_type(probability,Expression) :-
	catch(Probability is Expression,_,fail), 
	Probability >= 0.0, 
	Probability =< 1.0.

error:has_type(predicate_indicator,Functor/Arity) :-
	atom(Functor),
	integer(Arity),
	Arity >= 0.

error:has_type(nonempty_list(Type),List) :-
	is_list(List), 
	List \== [],
	error:element_types(List,Type).

error:has_type(pair(KeyType,ValueType),Key-Value) :-
	error:element_types([Key],KeyType),
	error:element_types([Value],ValueType).

%% true/1
% true(+Expression)
%
% Succeed with a probability expressed by Expression.	
% It does the same as maybe/1 from library(random) but with less ambiguity on its behavior.
% Furthermore, maybe/1 doesn't allow for expressions.
true(Expression) :- 
	must_be(probability,Expression), 
	random(Random), 
	Random =< Expression.

%% false/1
% false(+Expression)
%
% Fail with a probability expressed by Expression.	
false(Expression) :- 
	must_be(probability,Expression), 
	random(Random), 
	Random >= Expression.

%% sample/[2,3]
% sample(+Goal,-Probability)
% sample(+Goal,-Probability,+Options)
%
% Sample Goal and unify Probability with the corresponding success rate.
% Notice that, as defined, there could be multiple solutions during backtracking,  
% reaching "certainty" (i.e., Probability = 1) under certain conditions.
%
% Options:
% 	- size(integer) [default: 10000]
%		
sample(Goal,Probability) :-
	sample(Goal,Probability,[]).
sample(Goal,Probability,Options) :-
	% Ensure Goal is callable
	must_be(callable,Goal),
	% Set sample size
	option(size(SampleSize),Options,10000), 
	must_be(positive_integer,SampleSize),
	% Sample (find all solutions)
	findall(Goal,(between(1,SampleSize,_),call(Goal)),Solutions),
	sort(Solutions,Set),
	(	Set == []
	->	Probability = 0
	;	% Backtrack from here to allow for variable bindings
		select(Goal,Set,_),
		count(Solutions,Goal,Occurrences),
		P is Occurrences/SampleSize,
		(	(P > 1 ; P < 0) 
		-> 	(	once(sample(not(Goal),NP,Options)) 
			-> 	Probability is 1-NP
			;	Probability is 1
			) 
		; 	Probability is P
		)
	).

%% learn/[2,3]
% learn(+Predicate,+Knowledge)
% learn(+Predicate,+Knowledge,+Options)
%
% Learn probabilities from Predicate using gradient-descent optimization.
% Knowledge is expressed as a list of key-value pairs, where key is 
% the probability and value the corresponding goal.
%
% ATTENTION: learn/[1,2] replaces all clause predicates.
%
% Options:
%	- max_iterations(integer) [default: 1000]
%	- tolerance(float) [default: 1E-4]
%	- learning_rate(float) [default: 0.025]
%	- learning_decay(float) [default: 0.01]
%
:- module_transparent learn/2,learn/3.
learn(Predicate,Knowledge) :-
	learn(Predicate,Knowledge,[]).
learn(Predicate,Knowledge,Options) :-	
	must_be(predicate_indicator,Predicate),
	must_be(list(pair(number,ground)),Knowledge),	
	% Sort Knowledge according to the standard order of terms
	valuesort(Knowledge,SortedKnowledge),
	prolog_load_context(module,Module),
	% Collect all ground facts and remove them from the database
	Predicate = Functor/Arity,
	length(Args,Arity),
	Head =.. [Functor|Args],
	findall(Module-Head,(clause(Module:Head,_),ground(Head)),Facts),
	must_be(nonempty_list(ground),Facts),	
	% Erase all predicate clauses
	dynamic(Module:Predicate),	
	retractall(Module:Head),
	% Learn probabilities	
	learn_(Facts,SortedKnowledge,Options).

learn_(Facts,Knowledge,_) :- 
	Knowledge == [], !,
	length(Facts,N),
	list_to_set(Facts,Set),
	(	select(Fact,Set,_),
		count(Facts,Fact,Count),
		Probability is Count/N,
		Fact = Module-Goal,
		assertz((Module:Goal :- true(Probability))),
		fail
	;	true
	).
learn_(Facts,Knowledge,Options) :-
	option(max_iterations(MaxIterations),Options,1000),
	must_be(positive_integer,MaxIterations),
	option(tolerance(Tolerance),Options,1E-4), 
	must_be(float,Tolerance),
	option(learning_rate(LearningRate),Options,0.025),
	must_be(probability,LearningRate),
	option(learning_decay(LearningDecay),Options,0.01), 
	must_be(float,LearningDecay),	
	% Estimate probabilities from knowledge
	initialize(Facts,Knowledge,LearningRate,MSE,Refs,Gradients),
	train(Facts,Knowledge,LearningRate,LearningDecay,MaxIterations,Tolerance,MSE,Refs,Gradients,1).

%% initialize/6
% initialize(+Facts,+TargetKnowledge,+Learningrate,-MSE,-Refs,-Gradients)
initialize(Facts,TargetKnowledge,LearningRate,MSE,Refs,Gradients) :-
	update_init(Facts,0.5,InitialRefs,InitialGradients),	
	sample_knowledge(TargetKnowledge,CurrentKnowledge),
	mse(TargetKnowledge,CurrentKnowledge,MSE),	
	update(LearningRate,Facts,InitialRefs,Refs,InitialGradients,0,Gradients).

%% train/10
% train(+Facts,+Knowledge,+LearningRate,+MaxIterations,+Tolerance,+MSE,+Refs,+Gradients,+Iteration)
train(_,_,_,_,_,Tolerance,MSE,_,_,_) :-
	MSE =< Tolerance, !,
	debug(slp,'Converged within tolerance (~q).',[Tolerance]).	
train(_,_,_,_,MaxIterations,_,_,_,_,Iteration) :-
	Iteration > MaxIterations, !,
	debug(slp,'Maximum number of iterations (~q) reached.',[MaxIterations]).
train(Facts,
		Knowledge,
		LearningRate,
		LearningDecay,
		MaxIterations,
		Tolerance,
		OldMSE,
		OldRefs,
		OldGradients,
		CurrentIteration
	) :-
	% Main training loop
	sample_size(OldMSE,SampleSize),	
	sample_knowledge(Knowledge,NewPairs,SampleSize),
	mse(Knowledge,NewPairs,NewMSE),
	CurrentLearningRate is LearningRate*(1-LearningDecay*(CurrentIteration/MaxIterations)),	
	debug(slp,'Iteration #~q @ (LearningRate = ~4f ; SampleSize = ~q): MSE = ~8f',
		[CurrentIteration,CurrentLearningRate,SampleSize,NewMSE]),
	DeltaMSE is NewMSE-OldMSE,
	update(CurrentLearningRate,Facts,OldRefs,NewRefs,OldGradients,DeltaMSE,NewGradients),
	NextIteration is CurrentIteration+1,
	train(Facts,
		Knowledge,
		CurrentLearningRate,
		LearningDecay,
		MaxIterations,
		Tolerance,
		NewMSE,
		NewRefs,
		NewGradients,
		NextIteration
	).


% Helper predicates

%% valuesort/2
valuesort(Pairs,Sorted) :-
	transpose_pairs(Pairs,Transposed), % automatically sorted on the new key via keysort/2
	pairs:flip_pairs(Transposed,Sorted).

%% count/3
% count(+List,+Element,-Count)
count([],_,0) :- !.
count([X|T],X,Y):- !,count(T,X,Z),Y is 1+Z.
count([_|T],X,Z):- count(T,X,Z).	

%% sample_knowledge/[2,3]
% sample_knowledge(+TargetKnowledge,-CurrentKnowledge)
% sample_knowledge(+TargetKnowledge,-CurrentKnowledge,+SampleSize)
sample_knowledge(TargetKnowledge,CurrentKnowledge) :-
	sample_knowledge(TargetKnowledge,CurrentKnowledge,1000).
sample_knowledge(TargetKnowledge,CurrentKnowledge,SampleSize) :-	
	pairs_values(TargetKnowledge,Goals),
	maplist(sample_knowledge_(SampleSize),Goals,Probabilities),
	pairs_keys_values(CurrentKnowledge,Probabilities,Goals).
sample_knowledge_(SampleSize,Goal,Probability) :-
	sample(Goal,Probability,[size(SampleSize)]).

sample_size(MSE,SampleSize) :-		
	S is ceil(1/MSE),
	(S < 1000 -> SampleSize = 1000 ; S > 100000 -> SampleSize = 100000 ; SampleSize = S).

%% mse/3
% mse(+TargetKnowledge,+CurrentKnowledge,-MSE)
mse(TargetKnowledge,CurrentKnowledge,MSE) :-
	pairs_keys(TargetKnowledge,TargetProbabilities),
	pairs_keys(CurrentKnowledge,CurrentProbabilities),
	maplist([T,C,S] >> is(S,(T-C)^2),TargetProbabilities,CurrentProbabilities,SquaredErrors),
	sumlist(SquaredErrors,Sum),
	length(SquaredErrors,Length),
	MSE is Sum/Length.

%% update_init/4
% update_init(+Facts,+InitialProbability,-Refs,-Gradients)
update_init([],_,[],[]) :- !.
update_init([Fact|Facts],InitialProbability,[Ref|Refs],[0|Gradients]) :-
	Fact = Module-Goal,
	assertz((Module:Goal :- slp:true(InitialProbability)),Ref),
	update_init(Facts,InitialProbability,Refs,Gradients).

%% update/7
% update(+LearningRate,+Facts,+OldRefs,-NewRefs,+Gradients,+DeltaMSE,-Gradients)
update(_,[],[],[],[],_,[]) :- !.
update(LearningRate,
		[Fact|Facts],
		[OldRef|OldRefs],
		[NewRef|NewRefs],
		[OldGradient|OldGradients],
		DeltaMSE,
		[NewGradient|NewGradients]
	) :-
	clause(_,slp:true(OldProbability),OldRef),
	erase(OldRef),
	update_probability(LearningRate,OldProbability,OldGradient,DeltaMSE,NewProbability),
	NewGradient is NewProbability-OldProbability,
	Fact = Module-Goal,
	assertz((Module:Goal :- slp:true(NewProbability)),NewRef),
	update(LearningRate,Facts,OldRefs,NewRefs,OldGradients,DeltaMSE,NewGradients).		

update_probability(LearningRate,OldProbability,OldGradient,DeltaMSE,Probability) :-
	random(Maybe),
	(	Maybe < 0.05
	->	NewProbability is OldProbability
	;	Maybe < 0.10
	->	NewProbability is OldProbability+LearningRate
	;	Maybe < 0.15
	->	NewProbability is OldProbability-LearningRate
	;	NewProbability is OldProbability-sign(DeltaMSE)*sign(OldGradient)*LearningRate
	),
	update_probability_(NewProbability,Probability).
update_probability_(P,0) :- P < 0, !.
update_probability_(P,1) :- P > 1, !.
update_probability_(P,P).