
:- use_module('../slp.pl').

/* 
Consider two well-shuffled card decks. 
Each deck contains 10 cards with distinct numbers from 1 to 10. 
You pick a card from the first deck and a card from the second deck. 
What is the probability of picking up two cards such that 
the first number is odd and is the double of the second number? 
*/

odd(Card) :- 1 is Card mod 2.
double(Card1,Card2) :- Card1 is 2*Card2.

card(_Deck,Card) :- between(1,10,Card),true(1/10). 

pick_pair :- 
   card(deck1,Card1),
   card(deck2,Card2),
   odd(Card1),
   double(Card1,Card2).

% ?- sample(pick_pair_even_odd,Probability).
%    Probability = 0

