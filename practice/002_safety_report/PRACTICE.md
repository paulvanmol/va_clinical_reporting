# Module 2 – Cardiometabolic Safety Review Report in SAS Visual Analytics

**Scenario.** You support the safety review team of a cardiometabolic study. Before each Data Safety Monitoring Board (DSMB) meeting, the static TFL package (PDF) arrives late, and every follow-up question ("which subject is that outlier?") means another programming request.

You will build a **"Safety Review"** report with one page per question. The structure is inspired by multi-domain *SDTM SAF Analysis* dashboards: exposure, vital signs, laboratory, lab shift, liver safety (Hy's Law) and subject profile.

| Page | Clinical question | VA feature practised |
|---|---|---|
| Exposure | How long were subjects treated? Why did they stop? | Key values, button bar, list table |
| Heart Rate | Is there a dose-related heart-rate effect? Who is bradycardic? | Line chart over visits, box plot, display rules |
| Glycaemic Control | Does HbA1c change over time by arm? | Calculated items, line chart with change from baseline |
| Lab Shift | Did subjects move from normal to abnormal? | Crosstab, heat map |
| Liver Safety (eDISH) | Any potential Hy's Law cases? | Scatter plot, reference lines, data tips, linked selection |
| What Drives Bradycardia? | Which factors are associated with low heart rate? | Automated explanation (optional: decision tree) |
| Subject Profile | What happened to this subject? | Page-level prompt, multiple linked visuals |

> ⚠️ **The data is synthetic and includes planted signals** for teaching. Check your results against [`SOLUTIONS.md`](SOLUTIONS.md).

---

## Exercise 0 – Import the three tables

Import `adex.sas7bdat`, `adlb.sas7bdat` and `advs.sas7bdat` from `data/`: **Add data** → **Import** → **Local files** → **Import all**. Then add all three tables to a new report and save it as **Safety Review**.

> 💡 **Each page uses one data source.** VA visuals are bound to a single table. All three tables contain `USUBJID`, which lets you link pages through actions and *filter across data sources* (Exercise 7). Optionally, define a **data source mapping** on USUBJID and ACTARM (in the Data pane: data source menu → **Map data sources**).

---

## Exercise 1 – Shared preparation

For every table:

1. Rename the items using [`DATA_DICTIONARY.md`](DATA_DICTIONARY.md).
2. Create **Subject Count** as a distinct count of USUBJID.
3. Set the **AVISIT** sort order to follow visit order: right-click **AVISIT** → **Edit properties**, or sort on **AVISITN**. Otherwise WEEK 16 sorts before WEEK 2.

🤖
```
in the ADLB data source create an aggregation variable for usubjid of type distinct count
```

---

## Exercise 2 – Page "Exposure" (adex)

1. Add a **button bar** on Actual Arm at the top of the page. This control filters the whole page.
2. Add four **key value** objects on *Treatment Duration (days)*, using the aggregations **Count** (Subject Count), **Minimum**, **Average** and **Maximum**.
3. Add a **bar chart** of Reason for Discontinuation × Subject Count, grouped by Actual Arm. Filter: Completed = N.
4. Add a **list table** with subject, arm, dose, start day, end day, duration and completion flag.

🤖
```
in a new page create key values for count, minimum, average and maximum of treatment duration, and a bar chart of discontinuation reason by actual arm for subjects who did not complete
```

❓ *Are discontinuations due to adverse events more frequent on active treatment?*

---

## Exercise 3 – Page "Heart Rate" (advs)

1. Add a page filter: **PARAMCD = PULSE**.
2. Add a **line chart**. Category: Analysis Visit. Measure: Analysis Value (aggregation **Average**). Group: Actual Arm.
3. Add a **box plot**. Category: Analysis Visit. Measure: Analysis Value. Group: Actual Arm. In **Options**, turn on outliers.
4. Add a **list table** with subject, arm, visit and value. Filter: Analysis Value < 50 and Visit Number > 0.
5. Add a **display rule** on the list table: color Analysis Value red when < 50 bpm (*bradycardia*).

🤖
```
in a new page filtered on PARAMCD = PULSE create a line chart of average analysis value by analysis visit grouped by actual arm, and a box plot of analysis value by analysis visit and actual arm
```

❓ *Is the heart-rate decrease dose-related? Which subjects drop below 50 bpm? Does one of them also appear in Module 1 (look up 01-708-1019)?*

---

## Exercise 4 – Page "Glycaemic Control" (adlb)

1. Add a page filter: **PARAMCD = HBA1C**.
2. Add a **line chart** of the average *Change from Baseline* by visit, grouped by arm. Add a reference line at 0.
3. Optional: add a calculated item **HbA1c Responder** = `CHG <= -0.5`, then a bar chart of Subject Count by arm and responder status at WEEK 24.

❓ *Which arm shows the largest mean decrease at Week 24?*

> ⚠️ An average CHG by visit is descriptive. The validated efficacy analysis (MMRM/ANCOVA) is still done in SAS code.

---

## Exercise 5 – Page "Lab Shift" (adlb)

1. Add a **drop-down list** control on Parameter, defaulting to ALT.
2. Add a **crosstab**. Rows: Actual Arm, Baseline Range Indicator. Columns: Analysis Range Indicator. Measure: Subject Count.
3. Add a filter: Visit Number > 0. This shows all post-baseline visits. SOLUTIONS.md uses the *worst* post-baseline value per subject; note that difference.
4. Alternative: show the same data as a **heat map** (Baseline × Post-baseline indicator).

❓ *How many subjects shift from NORMAL to HIGH on ALT, per arm?*

---

## Exercise 6 – Page "Liver Safety (eDISH)" (adlb) ⭐

eDISH (*evaluation of Drug-Induced Serious Hepatotoxicity*) plots each subject's **peak ALT** against **peak total bilirubin**, both expressed as a multiple of the upper limit of normal (ULN).

1. **Prepare one row per subject.** VA needs ALT and BILI as two measures side by side. Two options:
   - **In VA (Data pane):** create two calculated items, `ALT xULN = IF PARAMCD = 'ALT' RETURN XULN ELSE .` and `BILI xULN = IF PARAMCD = 'BILI' RETURN XULN ELSE .`. Then create an **aggregated data source** (or a scatter plot with the aggregation set to **Maximum**), grouped by USUBJID and ACTARM, with a filter on Visit Number > 0.
   - **In SAS Studio** (recommended for reuse): transpose the data to one row per subject with `ALT_XULN` and `BILI_XULN`, then load the result to CAS.
2. Add a **scatter plot**. X: peak ALT ×ULN. Y: peak BILI ×ULN. Color: Actual Arm. Data tip: USUBJID.
3. Add **reference lines** at **X = 3** and **Y = 2**. In **Options**, set both axes to a **logarithmic** scale.
4. Add an **action**: selecting a point filters a list table on the same page (or the Subject Profile page).

🤖
```
in a new page create a scatter plot of maximum ALT xULN versus maximum BILI xULN per unique subject identifier colored by actual arm, with reference lines at 3 on the x axis and 2 on the y axis
```

❓ *Which subjects fall in the upper-right quadrant (potential Hy's Law)? Which arm are they on? Check how the values developed over time in Exercise 8.*

> 💡 This is the clearest example of where interactivity adds value: a static eDISH figure shows the point, but VA also shows **who** the subject is and lets you go to their profile.

---

## Exercise 7 – Page "What Drives Bradycardia?" (advs) — Automated explanation

1. Create a calculated item **Bradycardia** = `IF PARAMCD = 'PULSE' AND AVISITN > 0 AND AVAL < 55 RETURN 'Y' ELSE 'N'`. Filter the page on PARAMCD = PULSE and Visit Number > 0.
2. Right-click **Bradycardia** → **Explain** (or add an **Automated explanation** object). Use **Y** as the event level.
3. Review the factors VA ranks (arm, age, sex, site…) and the generated text.
4. *Optional, with Visual Statistics:* add a **decision tree** or **logistic regression** with Bradycardia as the response, and ACTARM, AGE, SEX and BASE as effects.

❓ *Does the automated explanation identify treatment arm as the main factor? Why must this be called **hypothesis-generating** and not a confirmatory analysis?*

---

## Exercise 8 – Page "Subject Profile"

1. Add a **drop-down list** on USUBJID as a *page prompt* (drag it to the area above the page).
2. Add a **line chart** (adlb) of ALT, AST and BILI ×ULN by study day, with a reference line at 1.
3. Add a **line chart** (advs) of heart rate by study day.
4. Add a **key value** (adex) for treatment duration and a text field for discontinuation reason.
5. Make the drop-down filter **all** data sources: open the control's **Actions** → filter across data sources, mapped on USUBJID.
6. Link the eDISH scatter (Exercise 6) and the heart-rate list (Exercise 3) to this page with **page links**.

❓ *Open 01-701-1211. When did ALT rise, and when did bilirubin follow? (Module 1 lists her AEs.)*

---

## Exercise 9 – Finish and share

1. Give each page and visual a clear title, and add a text object: *"Synthetic data – exploratory review, not a validated output."*
2. Use **Share** → **Link** for reviewers, or **Export** → **PDF** for a dated DSMB snapshot.
3. Optional: schedule the report to be distributed as a PDF.

---

## Discussion

- **Which static TFLs could become "review-only" pages** in VA (exposure summaries, lab shifts, eDISH, subject profiles), and which must stay validated code outputs?
- **Traceability.** The numbers in VA come from the same ADaM tables as the TFLs. How do you prove that (data lineage, frozen CAS table, report version)?
- **Who uses it?** Medical monitors, safety physicians, DSMB statisticians, medical writers (narratives).
