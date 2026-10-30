/*====================================================================
  01_load_data_to_cas.sas
  Reads the CDISC pilot ADaM subsets (SAS transport files in data/),
  derives ADEDISH with SAS code and loads the tables to CAS for VA.

  Module 1: ADSL, ADAE
  Module 2: ADSL, ADVS, ADLBC, ADLBHY, ADEDISH

  Expected rows: ADSL 254 | ADAE 1191 | ADVS 26662 | ADLBC 12368
                 ADLBHY 9954 | ADEDISH 246
====================================================================*/

/* ---- 1. Settings: adapt to your environment -------------------- */
%let datapath = /home/student/va_clinical_reporting;
%let caslib   = Public;          /* use CASUSER for sensitive study data */

options dlcreatedir;
libname vaclinic "&datapath/sasdata";

/* ---- 2. Transport files -> SAS data sets (labels and DATE9 kept) --- */
%macro xpt2sas(name);
   libname xpt xport "&datapath/data/&name..xpt";
   proc copy inlib=xpt outlib=vaclinic memtype=data; run;
   libname xpt clear;
%mend;
%xpt2sas(adsl)
%xpt2sas(adae)
%xpt2sas(advs)
%xpt2sas(adlbc)
%xpt2sas(adlbhy)
%xpt2sas(adedish)    /* the Python reference version of the eDISH table */

/* Keep the Python reference under another name. The SAS program creates ADEDISH. */
proc datasets lib=vaclinic nolist;
   delete adedish_ref;
   change adedish=adedish_ref;
quit;

/* ---- 3. Derive ADEDISH with SAS code (see 02_derive_edish.sas) ---- */
%include "&datapath/programs/02_derive_edish.sas";

/* ---- 4. Check the row counts ----------------------------------- */
proc sql;
   select "ADSL" as table, count(*) as rows from vaclinic.adsl union all
   select "ADAE",    count(*) from vaclinic.adae    union all
   select "ADVS",    count(*) from vaclinic.advs    union all
   select "ADLBC",   count(*) from vaclinic.adlbc   union all
   select "ADLBHY",  count(*) from vaclinic.adlbhy  union all
   select "ADEDISH", count(*) from vaclinic.adedish;
quit;

/* ---- 5. Load to CAS and promote -------------------------------- */
cas mysession;
%macro load2cas(ds=, caslib=&caslib, casout=);
   %if &casout= %then %let casout=%upcase(%scan(&ds,2,.));
   proc casutil;
      droptable casdata="&casout" incaslib="&caslib" quiet;
      load data=&ds outcaslib="&caslib" casout="&casout" promote;
      save casdata="&casout" incaslib="&caslib" outcaslib="&caslib"
           casout="&casout..sashdat" replace;
   quit;
%mend;
%load2cas(ds=vaclinic.adsl)
%load2cas(ds=vaclinic.adae)
%load2cas(ds=vaclinic.advs)
%load2cas(ds=vaclinic.adlbc)
%load2cas(ds=vaclinic.adlbhy)
%load2cas(ds=vaclinic.adedish)
cas mysession terminate;

/*--------------------------------------------------------------------
  If the XPORT engine is not available in your environment, read the CSV files:

  proc import datafile="&datapath/data/adsl.csv" out=vaclinic.adsl
              dbms=csv replace; guessingrows=max; run;

  Dates are then character (ISO yyyy-mm-dd). Labels are not set.
--------------------------------------------------------------------*/
