
:- use_module('../slp.pl').

/* 
Consider two well-shuffled card decks. 
Each deck contains 10 cards with distinct numbers from 1 to 10. 
You pick a card from the first deck and a card from the second deck. 
What is the probability of picking up two cards such that 
the first number is odd and is the double of the second number? 
*/

:- op(500,fx,(pick)).
:- op(200,xfx,(from)).
:- op(500,xf,(is_odd)).

Card is_odd :- 1 is Card mod 2.

pick Card from _Deck :- random_between(1,10,Card). 

action :-
    pick Card1 from deck1,
    pick Card2 from deck2,
    Card1 is_odd,
    Card1 is 2*Card2.

% ?- sample(action,Probability).
%    Probability = 0
 