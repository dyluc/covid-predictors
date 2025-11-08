/*
Foundational predicates for building more complex rules on top of.
*/


% == Rules ==

% 1. Rules to check if element is contained within given list. 

% 1.1 Succeeds if list head matches element
contains(E, [E|_]).

% 1.2 Fallback, recursive call to check remaining elements (list tail).
contains(E, [_|Es]) :-
    contains(E, Es).

% ----

% 2. Rules to count occurences of any first list elements in second list, using the accumulator pattern.

% 2.1 In the base case, if first list is empty, unify accumulator with final count
contains_list_acc([], _, Acc, Acc).

% 2.2 In the recursive case, increment the accumulator if the first list head element is contained in the 
% second list, then continue checking remaining elements
contains_list_acc([E1|E1s], E2s, Acc, Count) :-
    (contains(E1, E2s) -> Acc1 is Acc + 1 ; Acc1 = Acc),
    contains_list_acc(E1s, E2s, Acc1, Count).

% 2.3 Define a wrapper predicate that initialises the accumulator to 0
contains_list(L1, L2, Count) :-
    contains_list_acc(L1, L2, 0, Count).

% ----

% 3.

sum_list_acc([], Acc, Acc).

sum_list_acc([N|Ns], Acc, Sum) :-
    Acc1 is Acc + N,
    sum_list_acc(Ns, Acc1, Sum).

sum_list(Ns, Sum) :-
    sum_list_acc(Ns, 0, Sum).

% ----