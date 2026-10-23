/*====================================================================
  load_module2_cas.sas
  Module 2 - Cardiometabolic Safety Review (SYNTHETIC data)
  Reads adex.csv, adlb.csv, advs.csv, applies labels, loads to CAS.
  Optional: builds ADLB_EDISH (one row per subject) for Exercise 6.

  Expected rows:  ADEX 254 | ADLB 7140 | ADVS 3570 | ADLB_EDISH 254
====================================================================*/

/* ---- 1. Settings: adapt to your environment -------------------- */
%let datapath = /home/student/va_clinical_reporting;
%let caslib   = Public;
libname vaclinic "&datapath/data"; 
/* ---- 2. Subject-level columns shared by all three tables ------- */
%macro subj_attrib;
   length SITEID $3 AGE 8 SEX $1 RACE $40 ACTARM $25 ACTARMCD $8;
%mend;
%macro subj_label;
   SITEID   = "Study Site Identifier"
   AGE      = "Age"
   SEX      = "Sex"
   RACE     = "Race"
   ACTARM   = "Actual Arm Description"
   ACTARMCD = "Actual Arm Code"
%mend;

/* ---- 3. ADEX - Exposure (one row per subject) ------------------ */
data vaclinic.adex;
   infile "&datapath/data/adex.csv" dsd firstobs=2 truncover lrecl=32767 encoding="utf-8";
   length USUBJID $11 EXTRT $10 EXDOSE 8 EXDOSU $2 EXDOSFRM $5 EXDOSFRQ $2
          TRTSDY 8 TRTEDY 8 TRTDURD 8 COMPLFL $1 DCREAS $25;
   %subj_attrib
   input USUBJID EXTRT EXDOSE EXDOSU EXDOSFRM EXDOSFRQ TRTSDY TRTEDY TRTDURD
         COMPLFL DCREAS SITEID AGE SEX RACE ACTARM ACTARMCD;
   label
      USUBJID  = "Unique Subject Identifier"
      EXTRT    = "Treatment"
      EXDOSE   = "Dose"
      EXDOSU   = "Dose Units"
      EXDOSFRM = "Dose Form"
      EXDOSFRQ = "Dosing Frequency"
      TRTSDY   = "Study Day of Start of Treatment"
      TRTEDY   = "Study Day of End of Treatment"
      TRTDURD  = "Treatment Duration (days)"
      COMPLFL  = "Completed Week 24 (Y/N)"
      DCREAS   = "Reason for Discontinuation"
      %subj_label;
run;

/* ---- 4. ADLB - Laboratory (subject x parameter x visit) -------- */
data vaclinic.adlb;
   infile "&datapath/data/adlb.csv" dsd firstobs=2 truncover lrecl=32767 encoding="utf-8";
   length USUBJID $11 PARAMCD $8 PARAM $40 AVISIT $10 AVISITN 8 ADY 8
          AVAL 8 BASE 8 CHG 8 ANRLO 8 ANRHI 8 BNRIND $6 ANRIND $6 XULN 8;
   %subj_attrib
   input USUBJID PARAMCD PARAM AVISIT AVISITN ADY AVAL BASE CHG ANRLO ANRHI
         BNRIND ANRIND XULN SITEID AGE SEX RACE ACTARM ACTARMCD;
   label
      USUBJID = "Unique Subject Identifier"
      PARAMCD = "Parameter Code"
      PARAM   = "Parameter"
      AVISIT  = "Analysis Visit"
      AVISITN = "Analysis Visit (N)"
      ADY     = "Analysis Study Day"
      AVAL    = "Analysis Value"
      BASE    = "Baseline Value"
      CHG     = "Change from Baseline"
      ANRLO   = "Normal Range Lower Limit"
      ANRHI   = "Normal Range Upper Limit"
      BNRIND  = "Baseline Reference Range Indicator"
      ANRIND  = "Analysis Reference Range Indicator"
      XULN    = "Value x ULN"
      %subj_label;
run;

/* ---- 5. ADVS - Vital signs (subject x parameter x visit) ------- */
data vaclinic.advs;
   infile "&datapath/data/advs.csv" dsd firstobs=2 truncover lrecl=32767 encoding="utf-8";
   length USUBJID $11 PARAMCD $8 PARAM $40 AVISIT $10 AVISITN 8 ADY 8
          AVAL 8 BASE 8 CHG 8;
   %subj_attrib
   input USUBJID PARAMCD PARAM AVISIT AVISITN ADY AVAL BASE CHG
         SITEID AGE SEX RACE ACTARM ACTARMCD;
   label
      USUBJID = "Unique Subject Identifier"
      PARAMCD = "Parameter Code"
      PARAM   = "Parameter"
      AVISIT  = "Analysis Visit"
      AVISITN = "Analysis Visit (N)"
      ADY     = "Analysis Study Day"
      AVAL    = "Analysis Value"
      BASE    = "Baseline Value"
      CHG     = "Change from Baseline"
      %subj_label;
run;

/* ---- 6. Optional: ADLB_EDISH for Exercise 6 -------------------- */
/*  One row per subject: peak post-baseline ALT and BILI as x ULN   */
proc sql;
   create table work.adlb_edish as
   select USUBJID, SITEID, AGE, SEX, RACE, ACTARM, ACTARMCD,
          max(case when PARAMCD='ALT'  then XULN end) as ALT_XULN
              label="Peak ALT x ULN",
          max(case when PARAMCD='AST'  then XULN end) as AST_XULN
              label="Peak AST x ULN",
          max(case when PARAMCD='BILI' then XULN end) as BILI_XULN
              label="Peak Total Bilirubin x ULN"
   from vaclinic.adlb
   where AVISITN > 0
   group by USUBJID, SITEID, AGE, SEX, RACE, ACTARM, ACTARMCD;
quit;

data vaclinic.adlb_edish;
   set work.adlb_edish;
   length EDISHQ $35;
   label USUBJID  = "Unique Subject Identifier"
         EDISHQ   = "eDISH Quadrant";
   
   if      ALT_XULN > 3 and BILI_XULN > 2 then EDISHQ = "Potential Hy's Law";
   else if ALT_XULN > 3                   then EDISHQ = "Temple's Corollary (ALT>3xULN)";
   else if BILI_XULN > 2                  then EDISHQ = "Hyperbilirubinemia";
   else                                        EDISHQ = "Normal Range";
run;

/* Quick checks: expect 2 potential Hy's Law cases on High Dose */
proc freq data=vaclinic.adlb_edish;
   tables EDISHQ*ACTARM / nopercent norow nocol;
run;
proc contents data=vaclinic.adlb varnum; run;

/* ---- 7. Load and promote to CAS -------------------------------- */
cas mysession;

%macro load2cas(ds=,caslib=casuser,casout=);
%if &casout= %then %do; %let casout=%upcase(%scan(&ds,2,.)); %end; 
   proc casutil;
      droptable casdata="%upcase(&casout)" incaslib="&caslib" quiet;
      load data=&ds outcaslib="&caslib" casout="%upcase(&casout)" promote;
      save casdata="&casout" incaslib="&caslib" outcaslib="&caslib" casout="&casout.sashdat" replace; 
   quit;
%mend;

%load2cas(ds=vaclinic.adex,caslib=&caslib,casout=adex)
%load2cas(ds=vaclinic.adlb,caslib=&caslib,casout=adlb)
%load2cas(ds=vaclinic.advs,caslib=&caslib,casout=advs)
%load2cas(ds=vaclinic.adlb_edish,caslib=&caslib,casout=adlb_edish)

proc casutil;
   list tables incaslib="&caslib";
quit;

cas mysession terminate;
