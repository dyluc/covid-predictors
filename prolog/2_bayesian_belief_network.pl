
/* == Prior Probability == 

P(Infected):
+----------------+-------+
| Infected       | P(I)  |
+----------------+-------+
| infected       | 0.15  |
| not_infected   | 0.85  |
+----------------+-------+

*/

prior(infected, 0.15).
prior(not_infected, 0.85).

/* == Conditional Probabilty Tables ==

Fever (Low Severity Symptom):
+-----------+----------------+----------+
| Fever     | Infected       | P(F|I)   |
+-----------+----------------+----------+
| fever     | infected       | 0.70     |
| fever     | not_infected   | 0.15     |
| no_fever  | infected       | 0.30     |
| no_fever  | not_infected   | 0.85     |
+-----------+----------------+----------+

Aches and Pains (Medium Severity Symptom):
+--------------------+----------------+----------+
| Aches and Pains    | Infected       | P(A|I)   |
+--------------------+----------------+----------+
| aches_and_pains    | infected       | 0.85     |
| aches_and_pains    | not_infected   | 0.10     |
| no_aches_and_pains | infected       | 0.15     |
| no_aches_and_pains | not_infected   | 0.90     |
+--------------------+----------------+----------+

Difficulty Breathing (High Severity Symptom):
+-------------------------+----------------+----------+
| Difficulty Breathing    | Infected       | P(D|I)   |
+-------------------------+----------------+----------+
| difficulty_breathing    | infected       | 0.98     |
| difficulty_breathing    | not_infected   | 0.001    |
| no_difficulty_breathing | infected       | 0.02     |
| no_difficulty_breathing | not_infected   | 0.999    |
+-------------------------+----------------+----------+

*/

% Low severity, P(F|I) and P(F|¬I)
cpt(fever, infected, 0.7).
cpt(fever, not_infected, 0.15).
cpt(no_fever, infected, 0.3).
cpt(no_fever, not_infected, 0.85).

% Medium severity, P(A|I) and P(A|¬I)
cpt(aches_and_pains, infected, 0.85).
cpt(aches_and_pains, not_infected, 0.10).
cpt(no_aches_and_pains, infected, 0.15).
cpt(no_aches_and_pains, not_infected, 0.90).

% High severity, P(D|I) and P(D|¬I)
cpt(difficulty_breathing, infected, 0.95).
cpt(difficulty_breathing, not_infected, 0.001).
cpt(no_difficulty_breathing, infected, 0.05).
cpt(no_difficulty_breathing, not_infected, 0.999).

/* == BBN Diagnostic Reasoning ==

Assuming conditional independence of all symptoms (effects), we can find the probability
of infection given symptom combinations using Bayes' rule:

P(I|F,A,D) = 
    (P(F|I) * P(A|I) * P(D|I) * P(I)) / 
    ((P(F|I) * P(A|I) * P(D|I) * P(I)) + P(F|¬I) * P(A|¬I) * P(D|¬I) * P(¬I))

---

Here, our evidence is our observed patient symptom data. Breaking this down further:

Joint probability for case where patient is infected:
P(F,A,D,I) = P(F|I) * P(A|I) * P(D|I) * P(I)

Joint probability for case where patient is not infected:
P(F,A,D,¬I) = P(F|¬I) * P(A|¬I) * P(D|¬I) * P(¬I)

Marginal, the total probability of observing this evidence across all causes: 
P(F,A,D) = P(F,A,D,I) + P(F,A,D,¬I)

Posterior, the probability of patient being infected given evidence
P(I|F,A,D) = P(F,A,D,I) / P(F,A,D)

*/

% P(F,A,D,I) or P(F,A,D,¬I)
compute_joint_probability(Fever, AchesAndPains, DifficultyBreathing, InfectionState, Proba) :-
    cpt(Fever, InfectionState, PF), % P(F): Probability of fever given infected/not infected
    cpt(AchesAndPains, InfectionState, PA), % P(A): Probability of aches and pains given infected/not infected
    cpt(DifficultyBreathing, InfectionState, PD), % P(D): Probability of difficulty breathing given infected/not infected
    prior(InfectionState, PI), % P(I): Base probability of infected/not infected in population
    Proba is PF * PA * PD * PI.

% P(F,A,D)
compute_marginal(Fever, AchesAndPains, DifficultyBreathing, Proba) :-
    compute_joint_probability(Fever, AchesAndPains, DifficultyBreathing, infected, InfectedProba), % P(F,A,D,I)
    compute_joint_probability(Fever, AchesAndPains, DifficultyBreathing, not_infected, NotInfectedProba), % P(F,A,D,¬I)
    Proba is InfectedProba + NotInfectedProba.

% P(I|F,A,D)
compute_posterior(Fever, AchesAndPains, DifficultyBreathing, Proba) :-
    compute_joint_probability(Fever, AchesAndPains, DifficultyBreathing, infected, InfectedProba), % P(F,A,D,I)
    compute_marginal(Fever, AchesAndPains, DifficultyBreathing, TotalProba),
    Proba is InfectedProba / TotalProba.

% Final wrapper rule to obtain probability and classification from combination of fixed binary symptom atoms
patient_infected(Fever, AchesAndPains, DifficultyBreathing, Proba, Class) :-
    compute_posterior(Fever, AchesAndPains, DifficultyBreathing, Proba),
    DecisionBoundary = 0.5,
    (Proba >= DecisionBoundary -> Class = 1 ; Class = 0).

/*

Diagnose patient with all symptoms: fever, aches and pains and difficulty breathing:

?- patient_infected(fever, aches_and_pains, difficulty_breathing, P, C).
P = 0.9998496466696737,
C = 1 ;
false.

All other cases:

?- patient_infected(fever, aches_and_pains, no_difficulty_breathing, P, C).
P = 0.2594514455151964,
C = 0 ;
false.

?- patient_infected(fever, no_aches_and_pains, difficulty_breathing, P, C).
P = 0.9923891956424414,
C = 1 ;
false.

?- patient_infected(fever, no_aches_and_pains, no_difficulty_breathing, P, C).
P = 0.006822745082750151,
C = 0 ;
false.

?- patient_infected(no_fever, aches_and_pains, difficulty_breathing, P, C).
P = 0.9980156414147309,
C = 1 ;
false.

?- patient_infected(no_fever, aches_and_pains, no_difficulty_breathing, P, C).
P = 0.025813113061435213,
C = 0 ;
false.

?- patient_infected(no_fever, no_aches_and_pains, difficulty_breathing, P, C).
P = 0.9079324625676968,
C = 1 ;
false.

?- patient_infected(no_fever, no_aches_and_pains, no_difficulty_breathing, P, C).
P = 0.0005192808998099431,
C = 0 ;
false.

*/
