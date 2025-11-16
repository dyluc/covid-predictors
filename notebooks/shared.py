import pandas as pd
from pathlib import Path

def load_csv(dataset="COVID19MEXICO.csv"):
    return pd.read_csv(Path(f"./data/{dataset}"))


def translate_filter_columns(df, optional_includes=None):
    """
    Translate columns from Spanish to English, and filter resultant DataFrame for COVID predictors.
    """
    column_mapping = {
        "FECHA_ACTUALIZACION": "update_date",
        "ID_REGISTRO": "case_id",
        "ORIGEN": "origin",
        "SECTOR": "sector",
        "ENTIDAD_UM": "medical_unit_state",
        "SEXO": "sex",
        "ENTIDAD_NAC": "birth_state",
        "ENTIDAD_RES": "residence_state",
        "MUNICIPIO_RES": "residence_municipality",
        "TIPO_PACIENTE": "patient_type",
        "FECHA_INGRESO": "admission_date",
        "FECHA_SINTOMAS": "symptoms_start_date",
        "FECHA_DEF": "death_date",
        "INTUBADO": "intubated",
        "NEUMONIA": "pneumonia",
        "EDAD": "age",
        "NACIONALIDAD": "nationality",
        "EMBARAZO": "pregnant",
        "HABLA_LENGUA_INDIG": "speaks_indigenous_language",
        "INDIGENA": "indigenous",
        "DIABETES": "diabetes",
        "EPOC": "copd",
        "ASMA": "asthma",
        "INMUSUPR": "immunosuppressed",
        "HIPERTENSION": "hypertension",
        "OTRA_COM": "other_comorbidity",
        "CARDIOVASCULAR": "cardiovascular_disease",
        "OBESIDAD": "obesity",
        "RENAL_CRONICA": "chronic_kidney_disease",
        "TABAQUISMO": "smoking",
        "OTRO_CASO": "contact_with_covid_case",
        "TOMA_MUESTRA_LAB": "lab_sample_taken",
        "RESULTADO_PCR": "pcr_result",
        "RESULTADO_PCR_COINFECCION": "pcr_coinfection_result",
        "TOMA_MUESTRA_ANTIGENO": "antigen_sample_taken",
        "RESULTADO_ANTIGENO": "antigen_result",
        "CLASIFICACION_FINAL_COVID": "covid_classification",
        "CLASIFICACION_FINAL_FLU": "flu_classification",
        "MIGRANTE": "migrant",
        "PAIS_NACIONALIDAD": "country_nationality",
        "PAIS_ORIGEN": "country_origin",
        "UCI": "icu"
    }
    
    df = df.rename(columns=column_mapping)

    filter_columns = [
        "sex", "pneumonia", "age", "pregnant", "diabetes", 
        "copd", "asthma", "immunosuppressed", "hypertension", "other_comorbidity", 
        "cardiovascular_disease", "obesity", "chronic_kidney_disease", "smoking", "contact_with_covid_case", 
        "covid_classification" # target label
    ]

    if optional_includes:
        filter_columns += optional_includes
    
    return df[filter_columns], filter_columns
    