# Reconciliation: how to show that a VA report agrees with the validated numbers

A VA dashboard is not a validated TFL. It can still be **reconciled** to the validated ADaM data and to independent calculations. That is the evidence a QC reviewer or a study team can accept for a review report. Four layers:

| Layer | Question | Evidence in this repository |
|---|---|---|
| 1. Lineage | Does VA read the same data as the TFLs? | `ADSL`, `ADAE` etc. come unchanged from the CDISC pilot ADaM files (`programs/00_build_data.py`). Row counts are checked in `01_load_data_to_cas.sas`. |
| 2. Double programming | Do two independent programs derive the same table? | `ADEDISH` is derived in SAS (`02_derive_edish.sas`) and in Python (`00_build_data.py`). `PROC COMPARE` in `03_reconcile_module2.sas` must find no differences. |
| 3. Independent expected values | Do the SAS numbers equal an independent calculation? | `04_expected_results.py` writes `expected_counts.csv`. `03_reconcile_module1.sas` and `03_reconcile_module2.sas` recompute each check in SAS and report PASS or FAIL. |
| 4. Report versus SAS | Does the number I see in VA equal the SAS number? | Enter the VA values in `va_values.csv`, run `05_compare_va.sas`. |

## The checks (ids)

| Id | What | Population |
|---|---|---|
| M1_01 | Subjects per arm | ADSL |
| M1_02 | Row counts of ADSL, ADAE, TEAE records | |
| M1_03 | Subjects with any AE / with a TEAE | ADAE |
| M1_04, M1_05 | TEAE subjects / records per arm | SAFFL = Y, TRTEMFL = Y |
| M1_06 | Severe TEAE subjects per arm, records | |
| M1_07 | Subjects per system organ class and arm | |
| M1_08 | Application-site events, subjects per arm | |
| M1_09 | Serious AE records | |
| M1_10 | Subjects by worst severity | |
| M2_01 … M2_07 | Exposure, discontinuations, pulse < 50 / < 55, ALT shift, eDISH categories, Hy's Law flag | see `SOLUTIONS.md` of Module 2 |

## Typical reasons for a mismatch (taught in the exercises)

1. **Events instead of subjects.** *Frequency* is not *Subject Count* (1126 records versus 218 subjects).
2. **Population filter missing.** Without `TRTEMFL = Y` the AE counts include events before first dose.
3. **Denominator from the wrong table.** Percentages on `ADAE` alone are 100 %, because only subjects with an AE are in the table. The denominator comes from `ADSL`.
4. **Visit handling.** `AVISITN = 99` (End of Treatment) duplicates the last visit. Charts over time must exclude it.
5. **Worst versus all visits.** A shift table over all visits counts a subject several times. A worst post-baseline table counts a subject once.
6. **Unscheduled visits.** `ADY >= 1` includes visits without a scheduled week label.

## How to run

1. `python programs/04_expected_results.py` (already run; rerun after changing the data).
2. SAS Studio: `01_load_data_to_cas.sas`, then `03_reconcile_module1.sas` and `03_reconcile_module2.sas`. Both end with a `NOTE: RECONCILIATION PASSED` or an `ERROR` line in the log.
3. Copy `va_values_template.csv` to `va_values.csv`, fill `va_value` from the VA report, run `05_compare_va.sas`.

## Sign-off template

| Item | Done by | Date | Result |
|---|---|---|---|
| Data loaded, row counts equal expected | | | |
| `03_reconcile_module1.sas` log: PASSED | | | |
| `03_reconcile_module2.sas` log: PASSED, `PROC COMPARE` without differences | | | |
| `05_compare_va.sas`: all rows PASS | | | |
| Report stamped: source tables, load date, git commit | | | |
| Statement on the report: exploratory, TFLs validated separately | | | |

## What this does not prove

Reconciliation shows that **the numbers agree** for these checks. It does not validate the VA software, the Copilot output, or checks you did not define. Keep the validated SAS programs as the source of the TFLs.
