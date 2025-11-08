/* 

Uses simple symbolic rules of symptom combinations to determine virus presence. This approach follows a perceptron
like structure, where symptoms are weighted by severity, summed, then passed through a sigmoid activation 
function to produce a probability of infection. 

However, weights are defined manually, as opposed to learnt from data, there is no bias term and features are counts 
of symptoms per severity level instead of flags for symptom presence.

== Symptom Severities ==
Common Symptoms:
    Fever
    Persistent dry cough
    Tiredness

Less Common Symptoms:
    Aches and pains
    Sore throat
    Diarrhoea
    Conjunctivitis
    Headache
    Anosmia (total loss of sense of smell/taste)
    Hyposmia (partial loss of sense of smell/taste)
    Running nose

Serious Symptoms:
    Difficulty breathing/shortness of breath
    Chest pain/feeling of chest pressure
    Loss of speech
    Loss of movement

*/

:- [building_blocks].

% == Facts ==
% Severity lists of symptom atoms
severity_symptoms(low, [fever, dry_cough, tiredness]).
severity_symptoms(medium,
    [aches_and_pains, sore_throat, diarrhoea, conjunctivitis,
    headache, anosmia, hyposmia, runny_nose]).
severity_symptoms(high,
    [difficulty_breathing, chest_pain, loss_of_speech, loss_of_movement]).

% Severity weights
severity_weight(low, 1).
severity_weight(medium, 2).
severity_weight(high, 5).

% Define patients symptoms as a list of atoms
patient_symptoms(patient1, [fever, dry_cough, sore_throat]).
patient_symptoms(patient2, [hyposmia, runny_nose]).
patient_symptoms(patient3, [aches_and_pains, loss_of_movement]).

% == Rules ==
% 1. Rules used to determine if patient symptom list contains low, medium, or high severity symptoms.
% Using predicate https://www.swi-prolog.org/pldoc/man?predicate=member/2

% 1.1 Determine if head of given list is contained within SeveritySymptoms
contains_symptom_with_severity([S|_], Severity) :- 
    severity_symptoms(Severity, SeveritySymptoms), % SeveritySymptoms: variable representing either low, medium or high severity symptom list
    member(S, SeveritySymptoms), % Using predicate, check if head element is contained in list variable
    !. % Prevent backtracking as we only need to check if at least one element is contained

% 1.2 Fallback match ANY list tail, recursively check remaining elements within list
contains_symptom_with_severity([_|Ss], Severity) :-
    contains_symptom_with_severity(Ss, Severity). % Potentially match above rule

% ----

% 2. Rule to determine if a given patient has any symptoms of a specific severity.
patient_has_symptom_with_severity(Patient, Severity) :-
    patient_symptoms(Patient, PatientSymptoms), % Assign PatientSymptoms
    contains_symptom_with_severity(PatientSymptoms, Severity).

% ----

% 3. Rule to aggregate patient symptoms by given severity and count.
count_symptoms_by_severity(Patient, Severity, Count) :-
    patient_symptoms(Patient, PatientSymptoms), % Assign PatientSymptoms
    severity_symptoms(Severity, SeveritySymptoms), % Assign SeveritySymptoms
    contains_list(PatientSymptoms, SeveritySymptoms, Count). % Assign Count

% ----

% 4. Rule to produce a weighted sum of patient severities, allowing relative scoring without hardcoding
% all possible combinations, using the accumulator pattern.

% 4.1 In the base case, if the severity list is empty, unify accumulator with final score
score_patient_severities_acc(_, [], Acc, Acc).

% 4.2 In the recursive case, compute the weighted count of patient symptoms with current severity, then recurse (repeat 
% accumulating for remaining severities)
score_patient_severities_acc(Patient, [Severity|Severities], AccWeights, Score) :-
    severity_weight(Severity, Weight),
    count_symptoms_by_severity(Patient, Severity, Count),
    WeightedCount is Weight * Count,
    AccWeights1 is AccWeights + WeightedCount,
    score_patient_severities_acc(Patient, Severities, AccWeights1, Score).

% 4.3 Define a wrapper predicate that initialises the accumulator to 0
score_patient_severities(Patient, Score) :-
    score_patient_severities_acc(Patient, [low, medium, high], 0, Score).

% ----

% 5. Rule to produce final probability of infection using patient severity scores using a Sigmoid/Logistic,
% applies sigmoid function to map severity score to continuous infection probability.
% σ(x) = 1 / (1 + e^(-k * (x - c)))
% Source: https://www.cns.nyu.edu/~david/courses/perceptionLab/Handouts/LogisticHandout.pdf
calculate_infected_probability(Score, Probability) :-
    K = 1, % steepness of rise through centre
    Centre = 5, % midpoint: score of 5 gives 0.5 probability
    ShiftedScore is Score - Centre,
    Probability is 1 / (1 + exp(-K * ShiftedScore)).

% ----

% 6. Rule to convert calculated probability to binary outcome.
calculate_infected_classification(Probability, Classification) :-
    DecisionBoundary = 0.5,
    (Probability >= DecisionBoundary -> Classification = 1 ; Classification = 0).

% 7. Rule to produce infected probability and classification of given patient
patient_infected(Patient, Probability, Classification) :-
    score_patient_severities(Patient, Score), 
    calculate_infected_probability(Score, Probability), 
    calculate_infected_classification(Probability, Classification),
    !.

% == Example Queries ==

/* 
Calculate infected probability and classification from a combination of symptoms that
produce a weight of 4:

?- calculate_infected_probability(4, Probability), calculate_infected_classification(Probability, Classification).
Probability = 0.2689414213699951,
Classification = 0.

Check infected probability and classification for patient2 and patient3:

?- patient_infected(patient2, Probability, Classification).
Probability = 0.2689414213699951,
Classification = 0.

?- patient_infected(patient3, Probability, Classification).
Probability = 0.8807970779778823,
Classification = 1.

*/
