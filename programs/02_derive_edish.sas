/*====================================================================
  02_derive_edish.sas
  Derive ADEDISH: one row per subject with the PEAK post-baseline
  ALT, AST and bilirubin as a multiple of the upper limit of normal.

  Input : vaclinic.adlbc (R2A1HI = AVAL / A1HI), vaclinic.adsl
  Output: vaclinic.adedish
  Rules : post-baseline = ADY >= 1 (scheduled and unscheduled visits)
          subject needs at least one post-baseline ALT and bilirubin
          category: ALT >= 3 and BILI >= 2  Potential Hy's Law
                    ALT >= 3 only           Temple's Corollary
                    BILI >= 2 only          Hyperbilirubinemia
  Second program: programs/00_build_data.py (Python). Compare the two
  with programs/03_reconcile_module2.sas (double programming).
====================================================================*/
proc sql;
   create table work.edish_peaks as
   select usubjid,
          max(case when paramcd = 'ALT'  then r2a1hi end) as altxuln  label="Peak ALT x ULN",
          max(case when paramcd = 'AST'  then r2a1hi end) as astxuln  label="Peak AST x ULN",
          max(case when paramcd = 'BILI' then r2a1hi end) as bilixuln label="Peak Bilirubin x ULN"
   from vaclinic.adlbc
   where paramcd in ('ALT', 'AST', 'BILI') and ady >= 1
   group by usubjid;

   create table work.edish_base as
   select s.studyid, s.usubjid, s.siteid, s.trt01a, s.age, s.sex, s.race,
          p.altxuln, p.astxuln, p.bilixuln
   from vaclinic.adsl as s
        inner join work.edish_peaks as p on s.usubjid = p.usubjid
   where p.altxuln is not missing and p.bilixuln is not missing
   order by s.usubjid;
quit;

data vaclinic.adedish;
   set work.edish_base;
   length edishcat $20;
   if altxuln >= 3 and bilixuln >= 2 then edishcat = "Potential Hy's Law";
   else if altxuln >= 3              then edishcat = "Temple's Corollary";
   else if bilixuln >= 2             then edishcat = "Hyperbilirubinemia";
   else                                   edishcat = "Normal";
   label studyid  = "Study Identifier"
         usubjid  = "Unique Subject Identifier"
         siteid   = "Study Site Identifier"
         trt01a   = "Actual Treatment for Period 01"
         age      = "Age"
         sex      = "Sex"
         race     = "Race"
         edishcat = "eDISH Category";
run;
