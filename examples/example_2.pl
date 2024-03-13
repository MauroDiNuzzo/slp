
:- use_module('../slp.pl').

/*
Consider three friends: a, b, and c. 
Each of them plan to visit each of the other two friends 
with a 50% probability or otherwise stay home. 
What is the probability that the three friends will meet together?
*/

friend(a).
friend(b).
friend(c).

visit(X,Y) :- friend(X),friend(Y),not(X==Y),true(0.25).

meetup :- visit(X,Z),visit(Y,Z),not(X==Y),not(visit(Z,_Anyone)).

%   ?- sample(meetup,Probability).
%   Probability = 0.21
