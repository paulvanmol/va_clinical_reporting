# Data dictionary – table_AE_DM.csv (Module 1)

One row per adverse event. The demographic (DM) columns repeat on every AE row of the same subject. A subject with no AE has **one** row with empty AE columns.

> Use **distinct count of USUBJID** for subject counts. *Frequency* counts rows, which means AE records.

| Variable | Label to use in VA | Domain |
|---|---|---|
| STUDYID | Study Identifier | DM |
| USUBJID | Unique Subject Identifier | DM |
| SUBJID | Subject Identifier for the Study | DM |
| SITEID | Study Site Identifier | DM |
| AGE / AGEU | Age / Age Units | DM |
| SEX | Sex | DM |
| RACE / ETHNIC | Race / Ethnicity | DM |
| ARMCD / ARM | Planned Arm Code / Description | DM |
| ACTARMCD / ACTARM | Actual Arm Code / Description | DM |
| COUNTRY | Country | DM |
| RFSTDTC / RFENDTC | Subject Reference Start / End Date | DM |
| DTHFL / DTHDTC | Death Flag / Date of Death | DM |
| AESEQ / AESPID | AE Sequence Number / Sponsor AE Identifier | AE |
| AETERM | Reported Term for the AE | AE |
| AEDECOD | Dictionary-Derived Term | AE |
| AEBODSYS | System Organ Class / Body System | AE |
| AESEV | AE Severity (Mild / Moderate / Severe) | AE |
| AESER | Serious Event (Y/N) | AE |
| AEREL | Causality | AE |
| AEACN | Action Taken with Study Treatment | AE |
| AEOUT | Outcome of AE | AE |
| AESTDTC / AEENDTC | Start / End Date of AE | AE |
| AESTDY / AEENDY | Study Day of Start / End of AE | AE |
