/*--------------------------------------------------------------------
  Read table_AE_DM.csv, apply VA labels, load to CAS (Public)
--------------------------------------------------------------------*/
%let datapath=/home/student/va_clinical_reporting;
libname vaclinic "&datapath/data";
%let caslib=public;

filename aecsv "&datapath/data/table_AE_DM.csv" encoding="utf-8";
data vaclinic.table_ae_dm;
   infile aecsv dsd firstobs=2 truncover lrecl=32767;

   /* Column order = CSV header order */
   length STUDYID  $12  USUBJID  $11  SUBJID   $4   SITEID  $3
          AGE       8   AGEU     $5   SEX      $1   RACE    $40
          ETHNIC  $25   ARMCD    $8   ARM      $25  ACTARMCD $8
          ACTARM  $25   COUNTRY  $3   RFSTDTC  $10  RFENDTC  $10
          DTHFL    $1   DTHDTC   $10  AESEQ     8   AESPID   $3
          AETERM  $60   AEDECOD  $60  AEBODSYS $80  AESEV    $8
          AESER    $1   AEREL    $10  AEACN    $20  AEOUT    $30
          AESTDTC $10   AEENDTC  $10  AESTDY    8   AEENDY    8;

   input STUDYID USUBJID SUBJID SITEID AGE AGEU SEX RACE ETHNIC
         ARMCD ARM ACTARMCD ACTARM COUNTRY RFSTDTC RFENDTC DTHFL DTHDTC
         AESEQ AESPID AETERM AEDECOD AEBODSYS AESEV AESER AEREL AEACN
         AEOUT AESTDTC AEENDTC AESTDY AEENDY;

   label
      /* DM */
      STUDYID  = "Study Identifier"
      USUBJID  = "Unique Subject Identifier"
      SUBJID   = "Subject Identifier for the Study"
      SITEID   = "Study Site Identifier"
      AGE      = "Age"
      AGEU     = "Age Units"
      SEX      = "Sex"
      RACE     = "Race"
      ETHNIC   = "Ethnicity"
      ARMCD    = "Planned Arm Code"
      ARM      = "Planned Arm Description"
      ACTARMCD = "Actual Arm Code"
      ACTARM   = "Actual Arm Description"
      COUNTRY  = "Country"
      RFSTDTC  = "Subject Reference Start Date"
      RFENDTC  = "Subject Reference End Date"
      DTHFL    = "Death Flag"
      DTHDTC   = "Date of Death"
      /* AE */
      AESEQ    = "AE Sequence Number"
      AESPID   = "Sponsor AE Identifier"
      AETERM   = "Reported Term for the AE"
      AEDECOD  = "Dictionary-Derived Term"
      AEBODSYS = "System Organ Class / Body System"
      AESEV    = "AE Severity (Mild / Moderate / Severe)"
      AESER    = "Serious Event (Y/N)"
      AEREL    = "Causality"
      AEACN    = "Action Taken with Study Treatment"
      AEOUT    = "Outcome of AE"
      AESTDTC  = "Start Date of AE"
      AEENDTC  = "End Date of AE"
      AESTDY   = "Study Day of Start of AE"
      AEENDY   = "Study Day of End of AE";
run;

/* Check: labels, types and row count (expect 839 rows / 254 subjects) */
proc contents data=vaclinic.table_ae_dm varnum; run;

/*--------------------------------------------------------------------
  Load to CAS and promote, so VA can use the table
--------------------------------------------------------------------*/
cas mysession;
%macro load2cas(ds=,caslib=public,casout=);
%if &casout= %then %do; %let casout=%upcase(%scan(&ds,2,.)); %end; 
   proc casutil;
      droptable casdata="%upcase(&casout)" incaslib="&caslib" quiet;
      load data=&ds outcaslib="&caslib" casout="%upcase(&casout)" promote;
      save casdata="&casout" incaslib="&caslib" outcaslib="&caslib" casout="&casout.sashdat" replace; 
   quit;
%mend;

%load2cas(ds=vaclinic.table_ae_dm,casout=TABLE_AE_DM)

cas mysession terminate;