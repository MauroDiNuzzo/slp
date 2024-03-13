
:- use_module('../slp.pl').

% These examples are taken from https://github.com/friguzzi/cplint/blob/master/prolog/examples

%% Example: alarm
%
%   ?- sample(alarm,P).
%       P = 0.30.

burg :- true(0.1). % there is a burglary with probability 0.1
earthq :- true(0.2).  % there is an eartquace with probability 0.2
alarm :- burg,earthq. % if there is a burglary and an earthquake then the alarm surely goes off
alarm :- burg,not(earthq),true(0.8). % it there is a burglary and no earthquake then the alarm goes off with probability 0.8
alarm :- not(burg),earthq,true(0.8). % it there is no burglary and an earthquake then the alarm goes off with probability 0.8
alarm :- not(burg),not(earthq),true(0.1). % it there is no burglary and no earthquake then the alarm goes off with probability 0.1


%% Example: sneezing
%
%   ?- sample(strong_sneezing(bob),P).
%       P = 0.50.
%   ?- sample(moderate_sneezing(bob),P).
%       P = 0.80.

% if X has the flu, there is a probability of 0.3 that he has strong sneezing 
% and a probability of 0.5 that she has moderate sneezing
% if X has hay fever, there is a probability of 0.2 that he has strong sneezing 
% and a probability of 0.6 that she has moderate sneezing

strong_sneezing(X) :- flu(X),true(0.3).
strong_sneezing(X) :- hay_fever(X),true(0.2).
moderate_sneezing(X) :- flu(X),true(0.5).
moderate_sneezing(X) :- hay_fever(X),true(0.6).

flu(bob). % bob has certainly the flu
hay_fever(bob). % bob has certainly hay fever


%% Example: epidemic
%
% what is the probability that an epidemic arises?
%   ?- sample(epidemic,P).
%       P = 0.42.
%   ?- sample(pandemic,P).
%       P = 0.21.

% if somebody has the flu and the climate is cold, there is the possibility that an epidemic arises with 60% probability and the possibility that a pandemic arises with 30% probability.
epidemic :- once(has_flu(_)),is_cold,true(0.6).
pandemic :- once(has_flu(_)),is_cold,true(0.3).

% it is cold with 70% probability
is_cold :- true(0.7). 

% david and robert have the flu for sure
has_flu(david).
has_flu(robert).

