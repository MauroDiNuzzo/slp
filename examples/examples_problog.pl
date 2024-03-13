
:- use_module('../slp.pl').

% The following examples are taken from: https://dtai.cs.kuleuven.be/problog/natural_language/

%% Example 1
% If 30 percent of all people have an iPhone, what is the probability that 3 randomly selected people all have an iPhone?

has_iphone(_) :- true(0.30).

% ?- sample((has_iphone(person1),has_iphone(person2),has_iphone(person3)),P).
%    P = 0.027.


%% Example 2 (modified)
% A large department store has 500 employees. 
% There are 350 females and 200 of them are under the age of 25. There are 75 males under 25. 
% If an employee is selected for promotion, find the following probabilities: 
% - the employee is under 25 and female, 
% - the employee is under 25 and male, 
% - the employee is over 24 and female, 
% - the employee is over 24 and male.

sex(female) :- true(350/500).
sex(male) :- true(150/500).

age(female,under25) :- true(200/350).
age(male,under25) :- true(75/150).

age(Sex,over24) :- not(age(Sex,under25)).

selected(Sex,Age) :- sex(Sex),age(Sex,Age).

% ?- sample(selected(Sex,Age),P).
%       Sex = male,     Age = under25,  P = 0.15 ;
%       Sex = female,   Age = under25,  P = 0.40 ;
%       Sex = male,     Age = over24,   P = 0.15 ;
%       Sex = female,   Age = over24,   P = 0.30.


%% Example 3
% You roll a fair six-sided die twice. What is the probability that the first roll shows a five and the second roll shows a six?

dice(X) :- between(1,6,X),true(1/6).

% ?- sample((dice(5),dice(6)),P).
%       P = 0.0278


%% Example 4
% A vaccine has a 90 percent probability of being effective in preventing a certain disease. 
% The probability of getting the disease if a person is not vaccinated is 50 percent. 
% In a certain geographic region, 25 percent of the people get vaccinated. 
% If a person is selected at random, find the probability that he or she will contract the disease.

% NOTE: this case is affected by the sampling method because has_disease/1 has 2 clauses.

vaccine_effective :- true(0.90).

has_disease(Person) :- not(vaccinated(Person)),true(0.50).
has_disease(Person) :- vaccinated(Person),not(vaccine_effective).

vaccinated(_) :- true(0.25).

% ?- sample(has_disease(person),P).
%       P = 0.40
