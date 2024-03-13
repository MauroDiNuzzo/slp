
:- use_module('../slp.pl').

%% Example: blood type (take from the PRISM tutorial)
%
%
% ?- sample(bloodtype(T),P).
%       T = a,   P = 1 ;
%       T = ab,  P = 1 ;
%       T = b,   P = 1 ;
%       T = o,   P = 1.
%
% ?- learn(gene/1,[0.4-bloodtype(a), 0.1-bloodtype(ab), 0.2-bloodtype(b), 0.3-bloodtype(o)]).
% ?- sample(bloodtype(T),P).
%       T = a,   P = 0.4 ;
%       T = ab,  P = 0.1 ;
%       T = b,   P = 0.2 ;
%       T = o,   P = 0.3.
%
% ?- sample(gene(Gene),P).
%   Gene = a, P = 0.292 ;
%   Gene = b, P = 0.163 ;
%   Gene = o, P = 0.545.


gene(a).
gene(b).
gene(o).

genotype(X,Y) :- gene(X),gene(Y).

bloodtype(a)  :- genotype(a,a).
bloodtype(a)  :- genotype(a,o).
bloodtype(a)  :- genotype(o,a).
bloodtype(ab) :- genotype(a,b).
bloodtype(ab) :- genotype(b,a).
bloodtype(b)  :- genotype(b,b).
bloodtype(b)  :- genotype(b,o).
bloodtype(b)  :- genotype(o,b).
bloodtype(o)  :- genotype(o,o).


/*
% this is equivalent to the above
bloodtype(T) :-
    genotype(X,Y),
    ( X=Y -> T=X
    ; X=o -> T=Y
    ; Y=o -> T=X
    ; T=ab
    ).    
*/
  