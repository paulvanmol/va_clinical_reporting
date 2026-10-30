# Module 1 – AE Investigation in SAS Visual Analytics (CDISC pilot, ADSL + ADAE)

**Scenario.** You are a study physician preparing the safety review before the Clinical Study Report (CSR). You need an interactive view of demographics and adverse events by treatment arm, with drill-down to individual subjects. The data are the real CDISC pilot study ADaM datasets: `ADSL` (254 subjects) and `ADAE` (1191 AEs).

Each exercise has:

- 🖱️ **Manual path**: build it in the VA interface.
- 🤖 **Copilot path**: type the prompt in *Ask SAS Viya Copilot*, then check what Copilot built. Copilot must be activated by your administrator.
- ✅ **Check**: compare your result with [`SOLUTIONS.md`](SOLUTIONS.md). Every number there has a check id (M1_01 …) that SAS recomputes in `programs/03_reconcile_module1.sas`.

> **Population for all AE pages:** safety population, treatment-emergent AEs: `SAFFL = Y` and `TRTEMFL = Y`. Set it as a **report filter** on ADAE. Never make it a prompt a reader can switch off.

> Menu names can differ slightly between SAS Viya releases. If something is not where described, right-click the object or check the right-hand panes (Options, Roles, Actions, Filters).

---

## Exercise 0 – Load the data

1. In SAS Studio, run `programs/01_load_data_to_cas.sas`. It loads `ADSL`, `ADAE` (and the Module 2 tables) to the `Public` caslib. In a shared environment use `CASUSER` for study data.
2. In **SAS Visual Analytics** choose **New report** → **Add data** and select `ADSL` and `ADAE` from the caslib.
   *Fallback without SAS code:* **Import → Local files**, select `data/adsl.csv` and `data/adae.csv`, and rename data items with [`DATA_DICTIONARY.md`](DATA_DICTIONARY.md).
3. Save the report as **Clinical Trials Adverse Events**.

---

## Exercise 1 – Prepare the data items

**1a. Subject Count.** `ADAE` has one row per AE, so *Frequency* counts **AE records**. Create a distinct count of **Unique Subject Identifier** in both tables and name it **Subject Count**.
🤖 `create an aggregation variable for usubjid of type distinct count`
Set the aggregation of **Age** to **Average**.

**1b. Map the data sources.** In the Data pane choose the data source menu → **Map data sources**. Map `ADSL` and `ADAE` on `USUBJID`. You need this in Exercises 9 and R to get the correct denominator.

**1c. Report filter.** On `ADAE` add the report filter `Safety Population Flag = Y` and `Treatment Emergent Analysis Flag = Y`.

---

## Exercise 2 – Page "Demography" (ADSL)

Build automatic charts of **Race**, **Sex** and **Ethnicity** × **Subject Count**, with **Actual Treatment** (`TRT01A`) as group. Add a **box plot** of **Age** by **Sex**.

🤖 `create bar charts of race, sex and ethnicity by distinct count of usubjid grouped by trt01a`

✅ Check M1_01: 86 / 84 / 84 subjects per arm.

---

## Exercise 3 – Page "Arm Planned vs Actual" (ADSL)

Build two pie charts: **Planned Treatment** (`TRT01P`) × Subject Count and **Actual Treatment** (`TRT01A`) × Subject Count. Add a **list table** with `USUBJID`, `TRT01P` and `TRT01A`. Use automatic actions on all objects.

❓ *Which subjects received a different treatment than planned?*
**Answer: none.** In this study `TRT01P` equals `TRT01A` for all 254 subjects. A result you can explain is also a check.

---

## Exercise 4 – Page "Arm by Sex" (ADSL)

🖱️ **Bar chart.** Category: Actual Treatment. Measure: Subject Count. Group: Sex. Direction: horizontal.

> ⚠️ If the bars add up to about 1100 (or 1191), the chart uses Frequency on `ADAE` instead of Subject Count on `ADSL`.

---

## Exercise 5 – Page "AE Severity by Subject" (ADAE)

🖱️ **Bar chart.** Category: AE Severity. Measure: Subject Count. Group: Actual Treatment.

🤖 `in a new page create a bar chart for AE severity by unique subject id (distinct count) and actual treatment`

❓ *Why do the bars add up to more than the 218 subjects with a treatment-emergent AE?* A subject appears in every severity he or she experienced. Compare with the "worst severity per subject" table in SOLUTIONS.md.

---

## Exercise 6 – Page "Severe AEs Table" + drill-down (ADAE)

**6a.** 🖱️ **List table** with AE Severity, Actual Treatment, System Organ Class, Unique Subject Identifier, Sex, Dictionary-Derived Term and Analysis Start Date. Filter: AE Severity = SEVERE.

**6b. Drill-down.** Select the bar chart from Exercise 5 → **Actions** pane → **Page links** → **Severe AEs Table**. In view mode double-click the **SEVERE** bar.

❓ *Which arm has the most subjects with a severe AE?* Low dose (16), not high dose (8). Does that prove a dose effect? No. Open the subjects first.

---

## Exercise 7 – Page "AE by 5-Year Age Group"

**7a.** 🖱️ Right-click **Age** (ADSL) → **New custom category**. Create 5-year intervals 50–54 … 85–89 and name it **5-Year Age Grouping**.

**7b.** 🖱️ **Bar chart.** Category: 5-Year Age Grouping. Measure: Subject Count. Group: Actual Treatment. Compare with the standard `AGEGR1` of ADSL (<65, 65-80, >80).

---

## Exercise 8 – Page "Subject Profile" (ADAE)

🖱️ **List table** with subject, treatment, age, sex, AE start day, preferred term, severity, serious and causality. Add a **drop-down list** on Unique Subject Identifier.

Open these subjects:

- `01-709-1424`, `01-718-1170`: **syncope**, serious.
- `01-718-1371`: **seizure**, serious.
- `01-705-1186`: **hyperbilirubinaemia** on **placebo** (see Module 2).

❓ *Summarize each of the four subjects in two sentences.*

---

## Exercise 9 – Page "AE on Body System"

**9a.** 🖱️ **Bar chart.** Category: System Organ Class. Measure: Subject Count.
**9b.** 🖱️ **Bar chart.** Category: Dictionary-Derived Term. Measure: Subject Count. Lattice columns: Actual Treatment.
**9c.** 🖱️ **Crosstab.** Rows: System Organ Class. Columns: Actual Treatment. Measure: Subject Count. Options → Totals.

- Add **drop-down lists** as page controls on Study Site Identifier, AE Severity, Causality and Serious Event.
- Add actions: bar chart filters the preferred-term chart and the crosstab.
- Add a page link from the SOC chart to the Subject Profile page.

❓ *Which system organ classes show the clearest difference between placebo and xanomeline?* (General disorders and Skin disorders: application-site events.) Filter on `application site` terms and check M1_08.

---

## Exercise 10 – Explore

Filter on **AE Severity = SEVERE**, **Causality = PROBABLE** or **POSSIBLE**. Double-click a system organ class to reach the Subject Profile page.

---

## Exercise R – Reconciliation checkpoint ⭐

This exercise turns the report into something a QC reviewer can sign. Read [`../../reconciliation/RECONCILIATION.md`](../../reconciliation/RECONCILIATION.md) first (10 minutes).

**R1. Incidence needs ADSL.** Build a crosstab with Actual Treatment in the columns and these rows: *N (ADSL Subject Count)*, *Subjects with TEAE*, *%*. First compute the percentage only from `ADAE`: every arm shows 100 %. Then use the mapped `ADSL` Subject Count as denominator and compare with SOLUTIONS.md (Placebo 75.6 %, Low 91.7 %, High 90.5 %).

**R2. Read your numbers.** Open `reconciliation/va_values.csv` (copy of the template) and enter the numbers you see in VA (Module 1 rows `M1_*`).

**R3. Run the SAS reconciliation.** In SAS Studio run `programs/03_reconcile_module1.sas`. It recomputes the checks from `ADSL` and `ADAE` and compares them with the Python results in `reconciliation/expected_counts.csv`. The log must say `RECONCILIATION PASSED`. Then run `programs/05_compare_va.sas` for the comparison of VA against SAS.

**R4. Break it on purpose.** Remove the `TRTEMFL = Y` report filter and re-read the numbers. Which checks fail? (M1_04 becomes 225 subjects in total instead of 218; M1_05 becomes 1191 records.)

**R5. Stamp the report.** Add a text object on page 1: *source tables, CAS load date, git commit of the repository, "Exploratory review – validated TFLs are produced by SAS code"*.

---

## Discussion

- Events vs subjects: which belongs in a safety summary? Which denominator does an incidence use?
- Which of your numbers matched on the first attempt? What did the failures teach?
- This report supports exploration and medical review. The validated TFLs for the CSR are still produced and QC'd separately. How do you show that both use the same ADaM data?
