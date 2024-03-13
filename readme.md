# Stochastic Logic Programming (SLP)

This lightweight library is currently just an excercise for experimenting in simplicity/readability of SLP while strictly remaining in standard Prolog.

Actually, I quickly wrote this library to support an argument for a blog post. If interested in contributing, please feel free to reach out on Linkedin (<https://www.linkedin.com/in/mauro-dinuzzo/>).

**DISCLAIMER**: USE FOR EDUCATIONAL PURPOSES ONLY.

## Features

The library includes:
- `true/1` and `false/1` predicates that implement success/failure with a given probability.
- `sample/[2,3]` predicates that implement sampling through the all-solution method.
- `learn/[2,3]` predicates that implement learning through the gradient-descent method.

## Planned improvements

Currently, the `learn/[2,3]` predicate accepts only one predicate indicator for learning.
Future versions of the library should allow for concurrent multiple predicates optimization.

## Limitations

The library has not been developed with performance in mind (everything is written in Prolog). There are many points where better choices could have been made to reduce CPU time.
Please also note that the library has been developed and tested on SWI Prolog version 9.2.1 (<https://www.swi-prolog.org/>).
Compatibility with other Prolog systems/versions is not warranted.
Finally, this SLP implementation is substantially different (e.g., in the way stochastic predicates are expressed) from other more robust and comprehensive systems (for example, see [ccprism](https://github.com/samer--/ccprism) or [cplint](https://github.com/friguzzi/cplint/)). 

## Known issues

When the probability sampled using `sample/[2,3]` is zero, variable bindings cannot take place.

## Installation

Download the SLP files and unpack the archive in your favourite folder. From the SWI Prolog toplevel, import the `slp` module predicates in the current namespace:

```prolog
:- use_module('path_to_folder/slp.pl').
```

## Sampling

Probabilities are declared using the `true/1` and `false/1` predicates. For example:

```prolog
coin(head) :- false(0.5). % or true(0.5)
coin(tail) :- not(coin(head)).
```

Probabilities are sampled using the `sample/[2,3]` predicate. For example:

```prolog
?- sample(coin(Coin),Probability). % toss 1 coin
   Coin = head, Probability = 0.5
   Coin = tail, Probability = 0.5

?- sample((coin(Coin1),coin(Coin2)),Probability). % toss 2 coins
   Coin1 = head, Coin2 = head, Probability = 0.25
   Coin1 = head, Coin2 = tail, Probability = 0.25
   Coin1 = tail, Coin2 = head, Probability = 0.25
   Coin1 = tail, Coin2 = tail, Probability = 0.25
```

Let's consider the following problem expressed in natural language:

> *If somebody has the flu and the climate is cold, there is the possibility that an epidemic arises with 60% probability and the possibility that a pandemic arises with 30% probability.*

Now let's assume the following two observations. 

> *First, there is 70% probability that is cold. Second, David and Robert have the flu for sure.* 

We want to answer the questions:
 
> *What is the probability that an epidemic arises? What is the probability that a pandemic arises?*

In the present SLP implementation, we can write the "rules" block of the problem as:

```prolog
epidemic :- once(flu(_)), cold, true(0.6).
pandemic :- once(flu(_)), cold, true(0.3).
```

and similarly we can write the "facts" block of the problem as:

```prolog
cold :- true(0.7). 

flu(david).
flu(robert).
```

That's it. Now we can query the given questions through sampling as follows:

```prolog
% probability of an epidemic 
?- sample(epidemic,Probability).
   Probability = 0.42

% probability of a pandemic 
?- sample(pandemic,Probability).
   Probability = 0.21
```

## Learning

Let's consider the standard dependence of blood type upon genotype, which we can simplify as:

```prolog
gene(a) :- true(_Unknown).
gene(b) :- true(_Unknown).
gene(o) :- true(_Unknown).

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
```

As you can see, we have no information about the probability of individual ABO genes/alleles. Notice that we enumerate the possibilities for the `bloodtype/1` predicate for the sake of clarity.

Now let's assume we know the final probability (e.g., observation frequency) of the blood types a, ab, b, and o (for example: 40%, 10%, 20%, and 30%, respectively). We can train the `gene/1` predicate so that we correctly predict the observed blood types frequency as follows:

```prolog
?- learn(gene/1,[
        0.40-bloodtype(a), 
        0.10-bloodtype(ab), 
        0.20-bloodtype(b), 
        0.30-bloodtype(o)
    ]).
```

which gives the following:

```prolog
%  resulting facts with associated probability
gene(a) :- true(0.292).
gene(b) :- true(0.163).
gene(o) :- true(0.545).
```

We can easily verify that learning occurred correctly using `sample(gene(Gene),P)` and correspondingly `sample(bloodtype(Type),P)`.

Please see the Prolog source code of the SLP library for more detailed information on the usage of the relevant predicates.

## Other examples

Here I provide few examples with problems expressed both in natural language and in SLP. I have crafted problems for which several large language models (LLMs) would often fail to provide correct responses (I haven't attempted "prompt engineering", as the outcome might depend on subtleties).

### Example 1

Natural language:

> *You have two well-shuffled card decks. Each deck contains 10 cards with distinct numbers from 1 to 10. You pick a card from the first deck and a card from the second deck. What is the probability of picking up two cards such that the first number is odd and is the double of the second number?*

SLP:

```prolog
odd(Card) :- 1 is Card mod 2.
double(Card1,Card2) :- Card1 is 2*Card2.

card(_Deck,Card) :- random_between(1, 10, Card). 

action :- 
   card(deck1,Card1),
   card(deck2,Card2),
   odd(Card1),
   double(Card1,Card2). 

% of course...
?- sample(action,Probability).
   Probability = 0
```

### Example 2

Natural language:

> *There are three friends: a, b, and c. Each of them is independently plannning to visit each of the other two friends with a 25% probability, or otherwise stay home. What is the probability that the three friends will meet all together?*

SLP:

```prolog
friend(a).
friend(b).
friend(c).

visit(X,Y) :- friend(X),friend(Y),not(X==Y),true(0.25).

meetup :- visit(X,Z),visit(Y,Z),not(X==Y).

?- sample(meetup,Probability).
   Probability = 0.375
```

### Example 3

Natural language:

> *There are three friends: a, b, and c. Each of them is independently plannning to visit each of the other two friends with a certain probability, or otherwise stay home. Since the probability that the three friends meet all together is 37.5%, what is the probability that each of them visit one of the others?*

SLP:

```prolog
visit(a,b).
visit(a,c).
visit(b,a).
visit(b,c).
visit(c,a).
visit(c,b).

meetup :- visit(X,Z),visit(Y,Z),not(X==Y).

?- learn(visit/2,[0.375-meetup]).

% wide range of solutions (just one is reported here)
?- sample(visit(X,Y),Probability).
   X = a, Y = b, Probability = 0.23
   X = a, Y = c, Probability = 0.37 
   X = b, Y = a, Probability = 0.52
   X = b, Y = c, Probability = 0.15
   X = c, Y = a, Probability = 0.18
   X = c, Y = b, Probability = 0.13
```

## Further reading

Cussens J. (2007) Logic-based formalisms for statistical relational learning. In: Getoor L, Taskar B, editors. Introduction to Statistical Relational Learning.  

Puech A, Muggleton S. (2003) A Comparison of Stochastic Logic Programs and Bayesian Logic Programs. Proceedings of the IJCAI Workshop on Learning Statistical Models from Relational Data. 
