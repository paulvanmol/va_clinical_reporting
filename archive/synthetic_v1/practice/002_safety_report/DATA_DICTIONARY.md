# Data dictionary – Module 2 (ADaM-like, synthetic)

The subject-level columns `SITEID, AGE, SEX, RACE, ACTARM, ACTARMCD` are repeated in every table so that each table can be used on its own in VA.

## adex.csv – Exposure (one row per subject)

| Variable | Label |
|---|---|
| USUBJID | Unique Subject Identifier |
| EXTRT | Treatment |
| EXDOSE / EXDOSU | Dose / Dose Units (0, 54, 81 mg) |
| EXDOSFRM / EXDOSFRQ | Dose Form (PATCH) / Frequency (QD) |
| TRTSDY / TRTEDY | Study Day of Start / End of Treatment |
| TRTDURD | Treatment Duration (days) |
| COMPLFL | Completed Week 24 (Y/N) |
| DCREAS | Reason for Discontinuation |

## adlb.csv – Laboratory (one row per subject × parameter × visit)

| Variable | Label |
|---|---|
| PARAMCD / PARAM | Parameter Code / Parameter (ALT, AST, BILI, CREAT, GLUC, HBA1C) |
| AVISIT / AVISITN | Analysis Visit (BASELINE, WEEK 2, 8, 16, 24) / Visit Number (0–4) |
| ADY | Analysis Study Day |
| AVAL / BASE / CHG | Analysis Value / Baseline Value / Change from Baseline |
| ANRLO / ANRHI | Normal Range Lower / Upper Limit |
| BNRIND / ANRIND | Baseline / Analysis Reference Range Indicator (LOW, NORMAL, HIGH) |
| XULN | Value as a multiple of the Upper Limit of Normal (AVAL / ANRHI) |

## advs.csv – Vital signs (one row per subject × parameter × visit)

| Variable | Label |
|---|---|
| PARAMCD / PARAM | SYSBP, DIABP (mmHg), PULSE (beats/min) |
| AVISIT / AVISITN / ADY | as in adlb |
| AVAL / BASE / CHG | Value / Baseline / Change from Baseline |
