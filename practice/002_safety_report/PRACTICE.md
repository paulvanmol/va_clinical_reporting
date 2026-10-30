# Module 2 – Safety Review in SAS Visual Analytics (CDISC pilot ADaM)

**Scenario.** You support the safety review team of the CDISC pilot study (xanomeline TTS versus placebo in Alzheimer's disease). Before each Data Safety Monitoring Board (DSMB) meeting the static TFL package arrives late, and every follow-up question ("which subject is that outlier?") means another programming request.

You will build a **"Safety Review"** report with one page per question.

| Page | Clinical question | VA feature practised | Table |
|---|---|---|---|
| Exposure | How long were subjects treated? Why did they stop? | Key values, button bar, list table | ADSL |
| Heart Rate | Is there a dose-related effect? Who is bradycardic? | Line chart, box plot, display rules | ADVS |
| Lab Shift | Did subjects move from normal to high? | Crosstab, heat map | ADLBC |
| Liver Safety (eDISH) | Any potential Hy's Law cases? | Scatter plot, reference lines, data tips | ADEDISH |
| What Drives Bradycardia? | Which factors go with low heart rate? | Automated explanation | ADVS |
| Subject Profile | What happened to this subject? | Page prompt, linked visuals | all |

> The data are real CDISC pilot test data. They contain a placebo subject in the potential Hy's Law quadrant, subjects with pulse below 50 bpm, and many discontinuations due to adverse events. Check your results against [`SOLUTIONS.md`](SOLUTIONS.md) (check ids M2_01 …).

---

## Exercise 0 – Load the tables

Run `programs/01_load_data_to_cas.sas` (loads `ADSL`, `ADVS`, `ADLBC`, `ADLBHY`, `ADEDISH`). It derives `ADEDISH` with SAS code from `ADLBC`. Add the tables to a new report and save it as **Safety Review**. Use `Public` in a training environment, `CASUSER` for study data.

> 💡 Each page uses one data source. All tables contain `USUBJID`. Define a **data source mapping** on `USUBJID` (Data pane → data source menu → **Map data sources**) so that a page prompt can filter all tables (Exercise 8).

---

## Exercise 1 – Shared preparation

For every table:

1. Use the descriptive labels of the data items ([`DATA_DICTIONARY.md`](DATA_DICTIONARY.md) if you imported CSV).
2. Create **Subject Count** = distinct count of `USUBJID`.
3. Sort **Analysis Visit** by **Analysis Visit (N)**, otherwise Week 12 sorts before Week 2. `AVISITN = 99` is *End of Treatment* and duplicates the last visit: exclude it in charts over time.

---

## Exercise 2 – Page "Exposure" (ADSL)

1. **Button bar** on Actual Treatment (`TRT01A`) at the top of the page.
2. Four **key values** on *Duration of Treatment* (`TRTDUR`): Count, Minimum, Average, Maximum.
3. **Bar chart**: Reason for discontinuation (`DCDECOD`) × Subject Count, grouped by Actual Treatment. Filter: `DCDECOD` not `COMPLETED`.
4. **List table** with subject, arm, treatment start and end, duration, completion flag.

❓ *Are discontinuations due to an adverse event more frequent on xanomeline?* (Placebo 8, Low 44, High 40: check M2_02.)

---

## Exercise 3 – Page "Heart Rate" (ADVS)

1. Page filters: **PARAMCD = PULSE** and **Analysis Timepoint (N) = 815** (lying down 5 minutes).
2. **Line chart**: Analysis Visit (N) 0–26 × Analysis Value (Average), group Actual Treatment.
3. **Box plot**: Analysis Visit × Analysis Value, group Actual Treatment, outliers on.
4. **List table** with subject, arm, visit, value. Filter: Value < 50 and Analysis Relative Day ≥ 1.
5. **Display rule** on the list table: Analysis Value < 50 in red.

❓ *Is the heart-rate change dose-related? Which subjects drop below 50 bpm?* (7 subjects: 4 low dose, 3 high dose, none on placebo: check M2_03.)

---

## Exercise 4 – Optional: glucose and creatinine (ADLBC)

The CDISC pilot has no HbA1c. Use the same technique with `PARAMCD = GLUC` or `CREAT`: line chart of **Change from Baseline** by visit and arm, reference line at 0.

---

## Exercise 5 – Page "Lab Shift" (ADLBC)

1. **Drop-down list** on Parameter, default ALT.
2. **Crosstab**: rows Actual Treatment and Baseline Range Indicator, columns Analysis Range Indicator, measure Subject Count. Filter: Analysis Relative Day ≥ 1.
3. Alternative: **heat map**.

❓ *How many subjects shift from normal to high on ALT, per arm?* SOLUTIONS.md uses the **worst post-baseline** value per subject (M2_05). The crosstab on all visits counts a subject in several cells. Explain the difference.

---

## Exercise 6 – Page "Liver Safety (eDISH)" (ADEDISH) ⭐

eDISH plots each subject's **peak ALT** against **peak total bilirubin**, both as multiples of the upper limit of normal (ULN).

1. `ADEDISH` already has **one row per subject** (derived by `programs/02_derive_edish.sas`). Open the program and read the derivation rules.
2. **Scatter plot**: X = Peak ALT x ULN, Y = Peak Bilirubin x ULN, color = Actual Treatment, data tip = Unique Subject Identifier.
3. **Reference lines** at X = 3 and Y = 2. Set both axes to a **logarithmic** scale.
4. **Action**: selecting a point filters a list table on the same page, and a page link to the Subject Profile page.

🤖 `in a new page create a scatter plot of peak ALT x ULN versus peak bilirubin x ULN per unique subject identifier colored by actual treatment, with reference lines at 3 on the x axis and 2 on the y axis`

❓ *Which subjects fall in the upper-right quadrant?* **One: `01-705-1186`, on placebo** (ALT 3.3, AST 4.0, bilirubin 5.9 × ULN). Two subjects have ALT above 3 × ULN only, one has bilirubin above 2 × ULN only. Check M2_06 and M2_07.

> 💡 A static eDISH figure shows the point. VA also shows **who** the subject is and opens their profile in one click.

---

## Exercise 7 – Page "What Drives Bradycardia?" (ADVS) – automated explanation

1. Calculated item **Bradycardia** = `IF ( 'Analysis Value' < 55 ) RETURN 'Y' ELSE 'N'`. Page filters: `PARAMCD = PULSE`, `ATPTN = 815`, Analysis Relative Day ≥ 1, `AVISITN` ≤ 26.
2. Right-click **Bradycardia** → **Explain** (or add an **Automated explanation**). Event level: **Y**.
3. Review the ranked factors and the generated text.

❓ *Does the explanation identify the treatment arm as the main factor? Why must this be called hypothesis-generating and not a confirmatory analysis?* (44 subjects have a pulse below 55 in total, so the ranking is unstable: check M2_04.)

---

## Exercise 8 – Page "Subject Profile"

1. **Drop-down list** on Unique Subject Identifier as page prompt.
2. **Line chart** (ADLBC) of ALT, AST and bilirubin × ULN by study day, reference line at 1.
3. **Line chart** (ADVS) of pulse by study day.
4. **Key value** (ADSL) for treatment duration and a text for discontinuation reason.
5. Let the prompt filter all data sources through the `USUBJID` mapping.
6. Page links from the eDISH scatter and the heart-rate list.

❓ *Open `01-705-1186`. When did ALT rise and when did bilirubin follow? (Module 1 lists the AE.)* Both rise at Week 2 (study day 16). Treatment stopped on day 19. ALT is still above the upper limit of normal on day 31.

---

## Exercise R – Reconciliation checkpoint ⭐

Read [`../../reconciliation/RECONCILIATION.md`](../../reconciliation/RECONCILIATION.md).

**R1. Double programming.** Run `programs/03_reconcile_module2.sas`. Part B compares the SAS-derived `ADEDISH` with the Python reference `ADEDISH_REF` using `PROC COMPARE`. The log must say `DOUBLE PROGRAMMING PASSED`. Change the ULN rule in `02_derive_edish.sas` (for example `>= 3` to `> 3`) and rerun. Which check fails?

**R2. Published versus derived.** The CDISC pilot also ships `ADLBHY`. Check M2_07 counts the subjects flagged `HYLAW`. Does your eDISH quadrant agree?

**R3. Report versus SAS.** Enter the numbers you see in VA (Module 2 rows `M2_*`) in `reconciliation/va_values.csv` and run `programs/05_compare_va.sas`.

---

## Exercise 9 – Finish and share

1. Give each page and visual a clear title. Add a text object: *"CDISC pilot test data – exploratory review, not a validated output."*
2. **Share → Link** for reviewers, or **Export → PDF** for a dated DSMB snapshot.
3. Optional: schedule the report as a PDF.

---

## Discussion

- **Which static TFLs could become "review-only" pages** in VA (exposure summaries, lab shift, eDISH, subject profile), and which must stay validated code outputs?
- **Traceability.** The numbers in VA come from the same ADaM tables as the TFLs. Which reconciliation evidence would you file with the study (expected counts, SAS log, PROC COMPARE output, report version)?
- **Who uses it?** Medical monitors, safety physicians, DSMB statisticians, medical writers.
