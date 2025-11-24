/* 

Uses simple symbolic rules of symptom, bio-data and risk factor combinations to determine virus presence. 
This approach follows a perceptron like structure, where symptoms are weighted by severity, summed, then 
passed through a sigmoid activation function to produce a probability of infection. 

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

== Bio Data/Risk Factors ==
    Age
    Sex
    Pre-existing health conditions:
        Pneumonia
        Immunosuppressed
        Hypertension
        Chronic Kidney Disease
        Asthma
        Obesity
        Diabetes
        Cardiovascular disease

Re-normalised risk factor feature importances from decision tree modelling:

pneumonia: 0.72823802548
immunosuppressed: 0.06247995222
hypertension: 0.04027055578
chronic_kidney_disease: 0.03852001738
asthma: 0.03584172216
obesity: 0.03511428152
diabetes: 0.03128664566
cardiovascular_disease: 0.02824879977

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
severity_weight(low, 0.035).
severity_weight(medium, 0.08).
severity_weight(high, 0.8).
all_severity_levels([low, medium, high]).

% Risk factor weights
risk_factor_weight(pneumonia, 0.728).
risk_factor_weight(immunosuppressed, 0.062).
risk_factor_weight(hypertension, 0.040).
risk_factor_weight(chronic_kidney_disease, 0.039).
risk_factor_weight(asthma, 0.036).
risk_factor_weight(obesity, 0.035).
risk_factor_weight(diabetes, 0.031).
risk_factor_weight(cardiovascular_disease, 0.028).
all_risk_factors([
    pneumonia, immunosuppressed, hypertension, chronic_kidney_disease,
    asthma, obesity, diabetes, cardiovascular_disease]).

% Sex risk weights (males slightly more at risk)
sex_risk_weight(male, 0.023).
sex_risk_weight(female, 0.015).

% Define patients symptoms as a list of atoms
patient_symptoms(patient1, [fever, dry_cough, sore_throat]).
patient_symptoms(patient2, [hyposmia, runny_nose]).
patient_symptoms(patient3, [aches_and_pains, loss_of_movement]).
patient_symptoms(patient4, [difficulty_breathing, chest_pain]).
patient_symptoms(patient5, []).
patient_symptoms(patient6, [fever, dry_cough, tiredness, aches_and_pains, sore_throat, headache]).
patient_symptoms(patient7, [loss_of_speech]).
patient_symptoms(patient8, [runny_nose]).

% Define patient risk factors as a list of atoms
patient_risk_factor(patient1, pneumonia).
patient_risk_factor(patient1, diabetes).
patient_risk_factor(patient2, hypertension).
patient_risk_factor(patient4, pneumonia).
patient_risk_factor(patient5, pneumonia).
patient_risk_factor(patient5, diabetes).
patient_risk_factor(patient5, cardiovascular_disease).
patient_risk_factor(patient8, asthma).

% Define patient ages and sex
patient_age(patient1, 72).
patient_age(patient2, 45).
patient_sex(patient1, male).
patient_sex(patient2, female).

% == Rules ==
% 1. Rules used to determine if patient symptom list contains low, medium, or high severity symptoms.
% Using predicate https://www.swi-prolog.org/pldoc/man?predicate=member/2
% NOT USED, JUST TO SHOWCASE USE OF PREDEFINED PREDICATE, ACTUAL APPROACH USES CUSTOM contains_list/3

% 1.1 Determine if head of given list is contained within SeveritySymptoms
contains_symptom_with_severity([S|_], Severity) :- 
    severity_symptoms(Severity, SeveritySymptoms), % SeveritySymptoms: variable representing either low, medium or high severity symptom list
    member(S, SeveritySymptoms), % Using predicate, check if head element is contained in list variable
    !. % Prevent backtracking as we only need to check if at least one element is contained

% 1.2 Fallback match ANY list tail, recursively check remaining elements within list
contains_symptom_with_severity([_|Ss], Severity) :-
    contains_symptom_with_severity(Ss, Severity). % Potentially match above rule

% ----

% 2. Rules to determine if a given patient has any symptoms of a specific severity, or any given risk factor. Also
% included are rules to assign weights for a given age (the only continous value).

% 2.1 Symptoms of severity
% NOT USED, JUST TO SHOWCASE
patient_has_symptom_with_severity(Patient, Severity) :-
    patient_symptoms(Patient, PatientSymptoms), % Assign PatientSymptoms
    contains_symptom_with_severity(PatientSymptoms, Severity).

% 2.2 Risk factors
patient_has_risk_factor(Patient, RiskFactor) :-
    patient_risk_factor(Patient, RiskFactor). % If fact defined

% 2.3 Age risk (rough boundaries derived from decision tree analysis)
age_risk_weight(Age, Weight) :-
    Age < 5, Weight = 0.10. % Higher risk for infants
age_risk_weight(Age, Weight) :-
    Age >= 5, Age < 68, Weight = 0.03. % Baseline minimal risk
age_risk_weight(Age, Weight) :-
    Age >= 68, Age < 75, Weight = 0.15. % High risk for elderly (significant split at 67.5)
age_risk_weight(Age, Weight) :-
    Age >= 75, Weight = 0.234. % Significant risk for very elderly

% ----

% 3. Rule to aggregate patient symptoms by given severity and count them.
count_symptoms_by_severity(Patient, Severity, Count) :-
    patient_symptoms(Patient, PatientSymptoms), % Assign PatientSymptoms
    severity_symptoms(Severity, SeveritySymptoms), % Assign SeveritySymptoms
    contains_list(PatientSymptoms, SeveritySymptoms, Count). % Assign Count

% ----

% 4. Rules to produce a weighted sum of patient severities and risk factors, allowing relative scoring without hardcoding
% all possible combinations, using the accumulator pattern. Also included are rules to score patient age and sex.

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
    all_severity_levels(AllSeverityLevels),
    score_patient_severities_acc(Patient, AllSeverityLevels, 0, Score).

% 4.4 In the base case, if the risk factor list is empty, unify accumulator with final score
score_patient_risk_factors_acc(_, [], Acc, Acc).

% 4.5 In the recursive case, add the risk factor weight to the accumulator for the current risk factor, then recurse 
% (repeat accumulating for remaining severities). Second rule below matches if patient doesn't have this risk factor.
score_patient_risk_factors_acc(Patient, [RiskFactor|RiskFactors], AccWeights, Score) :-
    patient_has_risk_factor(Patient, RiskFactor), % Patient has risk factor
    risk_factor_weight(RiskFactor, Weight),
    AccWeights1 is AccWeights + Weight,
    score_patient_risk_factors_acc(Patient, RiskFactors, AccWeights1, Score).

score_patient_risk_factors_acc(Patient, [RiskFactor|RiskFactors], AccWeights, Score) :-
    \+ patient_has_risk_factor(Patient, RiskFactor), % Patient doesn't have risk factor
    score_patient_risk_factors_acc(Patient, RiskFactors, AccWeights, Score).

% 4.6 Define a wrapper predicate that initialises the accumulator to 0
score_patient_risk_factors(Patient, Score) :-
    all_risk_factors(AllRiskFactors),
    score_patient_risk_factors_acc(Patient, AllRiskFactors, 0, Score).

% 4.7 Produce a score for the patient age
score_patient_age(Patient, Score) :-
    patient_age(Patient, Age),
    age_risk_weight(Age, Score),
    !.
score_patient_age(_, 0). % Without data available, there should be 0 contribution

% 4.8 Produce a score for the patient sex
score_patient_sex(Patient, Score) :-
    patient_sex(Patient, Sex),
    sex_risk_weight(Sex, Score),
    !.
score_patient_sex(_, 0). % Without data available, there should be 0 contribution

% ----

% 5. Rule to aggregate scores for patient severities, risk factors, and bio data (sex and age)
score_patient(Patient, TotalScore) :-
    score_patient_severities(Patient, SymptomScore),
    score_patient_risk_factors(Patient, RiskScore),
    score_patient_age(Patient, AgeScore),
    score_patient_sex(Patient, SexScore),
    % 60%/32%/6%/2% symptom/risk/age/sex relative contribution
    TotalScore is (0.6 * SymptomScore) + (0.32 * RiskScore) + (0.06 * AgeScore) + (0.02 * SexScore),
    !.

% ----

% 6. Rule to produce final probability of infection using patient scores,
% applies sigmoid/logistic function to map scores to continuous infection probabilities.
% σ(x) = 1 / (1 + e^(-k * (x - c)))
% Source: https://www.cns.nyu.edu/~david/courses/perceptionLab/Handouts/LogisticHandout.pdf
calculate_infected_probability(Score, Probability) :-
    K = 1, % steepness of rise through centre
    Centre = 0.2, % midpoint: score of 0.2 gives 0.5 probability
    ShiftedScore is Score - Centre,
    Probability is 1 / (1 + exp(-K * ShiftedScore)).

% ----

% 7. Rule to convert calculated probability to a binary outcome.
calculate_infected_classification(Probability, Classification) :-
    DecisionBoundary = 0.5,
    (Probability >= DecisionBoundary -> Classification = 1 ; Classification = 0).

% 8. Rules to produce infected probability and classification of given patient

% 8.1 Patient requiring at least one symptom to be classified
patient_infected(Patient, Probability, Classification) :-
    score_patient_severities(Patient, SymptomScore),
    SymptomScore > 0, % Adjustment following edge case tests
    score_patient(Patient, Score), 
    calculate_infected_probability(Score, Probability), 
    calculate_infected_classification(Probability, Classification),
    !.

% Symptomless patients cannot be infected
patient_infected(_, 0.0, 0).

% == Example Queries ==

/* 

Ensure patient symptoms are categorised by severity level correctly:

?- count_symptoms_by_severity(patient1, low, LowCount), 
   count_symptoms_by_severity(patient1, medium, MedCount), 
   count_symptoms_by_severity(patient1, high, HighCount).
LowCount = 2,
MedCount = 1,
HighCount = 0.

---

Ensure weighted symptom, risk factor, age and sex scoring work correctly before aggregating:

?- score_patient_severities(patient1, S1), 
   score_patient_severities(patient4, S4), 
   score_patient_severities(patient6, S6).
S1 = 0.15000000000000002,
S4 = 1.6,
S6 = 0.345 .

?- score_patient_risk_factors(patient5, R5), 
   score_patient_risk_factors(patient8, R8).
R5 = 0.787,
R8 = 0.036 .

?- score_patient_age(patient1, A1), 
   score_patient_age(patient2, A2).
A1 = 0.15,
A2 = 0.03.

?- score_patient_sex(patient1, Sex1), 
   score_patient_sex(patient2, Sex2).
Sex1 = 0.023,
Sex2 = 0.015.

---

Ensure the Sigmoid centre point maps to exactly 0.5 probability:

?- calculate_infected_probability(0.2, P2), 
   calculate_infected_probability(0.5, P5), 
   calculate_infected_probability(1.0, P10).
P2 = 0.5,
P5 = 0.574442516811659,
P10 = 0.6899744811276125.

---

Patient 5 is a special case, with high risk factors but no symptoms (must be classified negative):

?- score_patient_risk_factors(patient5, RiskScore), 
   patient_infected(patient5, Probability, Classification).
RiskScore = 0.787,
Probability = 0.0,
Classification = 0 .

Final scoring, infected probabilities and classifications for all patients:

?- score_patient(patient1, Score1), patient_infected(patient1, Proba1, Class1),
   score_patient(patient2, Score2), patient_infected(patient2, Proba2, Class2),
   score_patient(patient3, Score3), patient_infected(patient3, Proba3, Class3),
   score_patient(patient4, Score4), patient_infected(patient4, Proba4, Class4),
   score_patient(patient5, Score5), patient_infected(patient5, Proba5, Class5),
   score_patient(patient6, Score6), patient_infected(patient6, Proba6, Class6),
   score_patient(patient7, Score7), patient_infected(patient7, Proba7, Class7),
   score_patient(patient8, Score8), patient_infected(patient8, Proba8, Class8).
Score1 = 0.34234000000000003,
Proba1 = 0.5355250401347063,
Class1 = Class3, Class3 = Class4, Class4 = Class6, Class6 = Class7, Class7 = 1,
Score2 = 0.1109,
Proba2 = 0.4777397247264924,
Class2 = Class5, Class5 = Class8, Class8 = 0,
Score3 = 0.528,
Proba3 = 0.5812726666092255,
Score4 = 1.19296,
Proba4 = 0.7296721811592222,
Score5 = 0.25184,
Proba5 = 0.0,
Score6 = 0.207,
Proba6 = 0.5017499928542016,
Score7 = 0.48,
Proba7 = 0.569546223939229,
Score8 = 0.05952,
Proba8 = 0.46493764293144785.

*/
