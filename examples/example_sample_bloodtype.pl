
:- use_module('../slp.pl').

%% Example: blood type (take from the PRISM tutorial)
%
% ?- sample(bloodtype(T),P).
%       T = a,   P = 0.4 ;
%       T = ab,  P = 0.1 ;
%       T = b,   P = 0.2 ;
%       T = o,   P = 0.3.

gene(a) :- true(0.292).
gene(b) :- true(0.163).
gene(o) :- true(0.545).

genotype(X,Y) :- gene(X),gene(Y).

bloodtype(T) :-
    genotype(X,Y),
    ( X=Y -> T=X
    ; X=o -> T=Y
    ; Y=o -> T=X
    ; T=ab
    ).    