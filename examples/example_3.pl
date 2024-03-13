
:- use_module('../slp.pl').

/*
Consider three friends: a, b, and c. 
Each of them is independently plannning to visit each of the other two friends 
with a certain probability, or otherwise stay home. 
Since the probability that the three friends meet all together is 37.5%, 
what is the probability that each of them visit one of the others?
*/

visit(a,b).
visit(a,c).
visit(b,a).
visit(b,c).
visit(c,a).
visit(c,b).

meetup :- visit(X,Z),visit(Y,Z),not(X==Y).

% ?- learn(visit/2,[0.375-meetup]).
% ?- sample(visit(X,Y),Probability).
%   