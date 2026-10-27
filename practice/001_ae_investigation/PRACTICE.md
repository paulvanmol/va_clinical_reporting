# Module 1 – Clinical Trials AE Investigation Report in SAS Visual Analytics

**Scenario.** You are a study physician preparing the safety review before writing the Clinical Study Report (CSR). You need an interactive view of demographics and adverse events by treatment arm, with drill-down to individual subjects.

Each exercise has:

- 🖱️ **Manual path**: build it in the VA interface.
- 🤖 **Copilot path**: type the prompt in *Ask SAS Viya Copilot*, then check what Copilot built. (Copilot should have been activated by your Administrator)
- ✅ **Check**: compare your result with [`SOLUTIONS.md`](SOLUTIONS.md).

> Menu names can differ slightly between SAS Viya releases. If something is not where described, right-click the object or check the right-hand panes (Options, Roles, Actions, Filters).

---

## Exercise 0 – Import the data

1. Open **SAS Visual Analytics** → **New report**.
2. In the **Data** pane, select **Add data** → **Import** → **Local files**, then select `data/table_ae_dm.sas7bdat`.
3. Keep the table name `TABLE_AE_DM`. Choose a target library such as `cas-shared-default / Public`.
4. Select **Import item**, then **Add to report**.
5. Save the report as **Clinical Trials Adverse Events**.

---

## Exercise 1 – Prepare the data items

**1a. Readable names (Optional).**
When import data from a sas table, the Data Items received descriptive names from the labels in the dataset.
When import data from a CSV file, the Data Items may need to be renamed: 
🖱️ Right-click a data item → **Edit properties** → **Name**. Use the labels in [`DATA_DICTIONARY.md`](DATA_DICTIONARY.md).

🤖
```
rename data items in the TABLE_AE_DM data source as
ARM Planned Arm Description, ACTARM Actual Arm Description, SEX Sex,
AESEV AE Severity (Mild / Moderate / Severe), AEBODSYS System Organ Class / Body System,
AEDECOD Dictionary-Derived Term, USUBJID Unique Subject Identifier, AGE Age
```

**1b. Create Data Items: Distinct-count measure.**
> 💡 The table has one row per AE. *Frequency* counts **AE records**. *Subject Count* counts **subjects** (incidence).
🖱️ Right-click **Unique Subject Identifier** → **New calculation** → **Distinct count**. Rename the result **Subject Count**.

🤖
```
create an aggregation variable for usubjid of type distinct count
```
Age uses Aggregation: SUM, change it to Aggregation: Average


---

## Exercise 2 – Page "Arm Planned vs Actual"

Build two pie charts: Planned Arm × Subject Count, and Actual Arm × Subject Count.

🤖
```
create Pie or Bar charts for planned arm by usubjid by distinct count and actual arm by usubjid by distinct count
```

❓ *Which subjects received a different treatment than planned?* 
Hint: Add list table with USUBJID, Planned ARM and Actual ARM to the same page, 
Actions: Automatic actions on all objects: 
- Select Planned ARM (High Dose, Low Dose) >filter the one that received Placebo

---

## Exercise 3 – Page "Arm by Gender"

🖱️ **Bar chart**. Category: Actual Arm. Measure: Subject Count. Group: Sex. Direction: horizontal.

🤖
```
in a new page create a bar graph with actual arm by usubjid distinct count grouped by sex
```

> ⚠️ If the bars add up to about 800, the chart uses Frequency instead of Subject Count.

---

## Exercise 4 – Page "AE Severity by Subject"

🖱️ **Bar chart**. Category: AE Severity. Measure: Subject Count. Group: Sex. Page filter: AE Severity is not missing.

🤖
```
in a new page create bar chart for AE severity by unique subject id (distinct count) and sex
```

❓ *Why do the bars add up to more than the 218 subjects who had at least one AE?*

---

## Exercise 5 – Page "Severe AEs Table" + drill-down

**5a.** 🖱️ **List table** with AE Severity, Actual Arm, System Organ Class, Unique Subject Identifier, Sex, Dictionary-Derived Term and Start Date of AE. Filter: AE Severity = SEVERE.

🤖
```
in a new page create a table list with severe AESeverity, actual arm and body system organ class and count of usubjid
```
then
```
Can you add unique subject ID column
```

**5b. Drill-down.** Select the bar chart from Exercise 4 → **Actions** pane → **Page links** → **Severe AEs Table**. In view mode, double-click the **SEVERE** bar.

---

## Exercise 6 – Page "AE Severity by 5-Year Age Group"

**6a.** 🖱️ Right-click **Age** → **New custom category**. Create 5-year intervals (50–54 … 85–89) and name it **5-Year Age Grouping**.

**6b.** 🖱️ **Bar chart**. Category: 5-Year Age Grouping (sorted descending). Measure: Subject Count. Group: AE Severity.

🤖
```
On a new page, create a bar chart that uses 'Age 5-Year Bin Categorization' as the category (subject age grouped into 5-year bins), 'USUBJID (Distinct count) 1' as the measure, and 'AESEV' as the group, so the chart shows the distinct count of subjects by 5-year age bins, broken down by AE severity. Sort the age bins in descending order so the oldest age groups appear at the top of the Y-axis.
```

> ⚠️ If Copilot used *AE Count / Frequency*, ask: `change the measure to the distinct count of unique subject identifier`. Compare both tables in SOLUTIONS.md.

---

## Exercise 7 – Page "Subject Profile"

🖱️ **List table** with subject, arm, age, sex, AE start date, Dictionary-Derived Term (preferred term), severity, serious and causality. Add a **drop-down list** on Unique Subject Identifier.

---

## Exercise 8 – AE on Body System
🖱️ **Bar Chart** with Category: System Organ Class/Body System, Measure: Subject Count
🖱️ **Bar Chart** with Category: Dictionary-Derived Term, Measure: Subject Count
🖱️ **Cross Tab** with Rows: System Organ Class/Body System, Columns: Actual ARM, Measure: Subject Count (add Options>Totals)
Add several **drop-down list** to Page Controls on Study Site Identifier, AE Severity, Causality, Serious Event.
Add Actions: Bar Chart Filters Dictionary Derived Term, Crosstab Actual ARM, 
Add Page Link from Bar Chart System Organ Class/Body System>Subject Profile Page
---

### Exercise 9 - Explore AE on Body System: 

- Filter on AE Severity: SEVERE, Causality: POSSIBLE, Serious: Y
- Select Bar Chart System Organ Class, Double click to use the page link and see the Subject Profile list
❓ *Summarize subjects 01-708-1019 and 01-701-1211 in two sentences each.*

## Discussion

- Events vs subjects: which belongs in a safety summary?
- Every Copilot visual needed checking (measure, filter, sort). How would you document that review?
- This report supports exploration and medical review. Validated TLFs for the CSR are still produced and QC'd separately.
