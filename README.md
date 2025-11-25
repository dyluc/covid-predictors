# COVID-19 Diagnosis using Prolog and Decision Trees

Two Prolog diagnostic systems for COVID-19 classification: 

- A perceptron-like arch using weighted scoring.
- A simplified Bayesian Belief Network (3 symptoms, PoC).

Feature weights are derived in part from decision tree analysis of 129k patient cases from the [Mexican Ministry of Health public dataset](https://www.gob.mx/salud/documentos/datos-abiertos-152127).

## Some Observations

- Pneumonia is among the stronger predictors.
- Elderly folk over 68 represent a significant risk threshold.
- Accuracy plateaued around 70% with patient bio-data and comorbidity features (symptom related information required for improved accuracy).