# SAS Visual Analytics – Clinical Trials Reporting Practice

Two hands-on modules that show how SAS Visual Analytics (SAS Viya) supports **interactive clinical review**. They sit **alongside** the validated, SAS-code-based TFLs, not instead of them. Every module ends with a **reconciliation checkpoint** that ties the VA numbers back to the ADaM data.

| Module | Report | Data | Time |
|---|---|---|---|
| **1** | AE Investigation: demography, TEAE incidence, severity, severe-AE drill-down, subject profile, reconciliation | `adsl`, `adae` | 75–90 min |
| **2** | Safety Review: exposure, pulse, ALT shift, eDISH / Hy's Law, automated explanation, reconciliation | `adsl`, `advs`, `adlbc`, `adlbhy`, `adedish` | 90–105 min |

Each exercise can be done **manually** in the VA interface or with **SAS Viya Copilot** prompts.

## Data

Real test data: the public **CDISC pilot study** (CDISCPILOT01, xanomeline TTS versus placebo in Alzheimer's disease, 254 subjects) in ADaM form, as published by [PHUSE](https://github.com/phuse-org/phuse-scripts/tree/master/data/adam/cdisc). No real patients. The synthetic data of the first version moved to [`archive/synthetic_v1`](archive/synthetic_v1).

Teaching cases in the real data:

- 218 of 254 subjects have a treatment-emergent AE. Severe AEs: more subjects on low dose (16) than on high dose (8), placebo 5.
- Application-site events concentrate in the xanomeline arms.
- Three serious AEs (two syncope, one seizure).
- `TRT01P = TRT01A` for all subjects: the "planned versus actual" list is empty.
- A **placebo** subject (`01-705-1186`) sits in the eDISH potential Hy's Law quadrant.
- Discontinuation due to an adverse event: 8 placebo, 44 low dose, 40 high dose.

## Repository layout

```
data/            ADaM subsets as SAS transport (.xpt, v5, with labels) and .csv
                 adsl, adae, advs, adlbc, adlbhy, adedish (derived, one row per subject)
programs/
  00_build_data.py          rebuild data/ from the PHUSE files (Python)
  00_git_clone.sas          clone this repository in SAS Studio
  01_load_data_to_cas.sas   xpt -> SAS -> CAS (Public caslib)
  02_derive_edish.sas       ADEDISH in SAS (peak ALT / AST / bilirubin x ULN)
  03_reconcile_module1.sas  SAS checks vs expected values (Module 1)
  03_reconcile_module2.sas  SAS checks vs expected values + PROC COMPARE of ADEDISH
  03_compare_macro.sas      shared macros
  04_expected_results.py    independent Python reference, writes SOLUTIONS and expected_counts.csv
  05_compare_va.sas         numbers read in VA vs SAS
practice/
  001_ae_investigation/   PRACTICE.md  SOLUTIONS.md  DATA_DICTIONARY.md
  002_safety_report/      PRACTICE.md  SOLUTIONS.md  DATA_DICTIONARY.md
reconciliation/
  RECONCILIATION.md       the four layers, check ids, sign-off template
  expected_counts.csv     129 expected values (Python)
  va_values_template.csv  worksheet for numbers read in VA
reports/                  put exported VA report packages (.json) of your solutions here
archive/synthetic_v1/     previous synthetic data, practices and report packages
```

## Prerequisites

- SAS Viya with SAS Visual Analytics.
- SAS Viya Copilot (only for the Copilot path).
- SAS Visual Statistics (only for the optional model exercise).
- Permission to load tables to CAS, for example `cas-shared-default / Public`.

## Getting started

1. Clone the repository (`programs/00_git_clone.sas`) or download it as a zip.
2. Adapt `datapath` and `caslib` at the top of `01_load_data_to_cas.sas` and run it.
3. Open `practice/001_ae_investigation/PRACTICE.md`.

## Rebuild the data and the solutions (optional)

```
pip install pandas pyreadstat
python programs/00_build_data.py          # downloads the PHUSE xpt files into source/
python programs/04_expected_results.py    # SOLUTIONS.md, DATA_DICTIONARY.md, expected_counts.csv
```

## Status of the programs

The Python programs were run and their results cross-checked: the SQL logic of the reconciliation programs was reproduced in SQLite and equals `expected_counts.csv` for all 129 values. The SAS programs have **not yet been run on a SAS Viya system** after this restructure. Run `01` and `03` once and fix any environment-specific path or library setting.

> **Existing VA report packages.** The `.json` report packages in `archive/synthetic_v1/` point to the old synthetic tables. Rebuild the reports with the new practices and export them to `reports/`.
