/*====================================================================
  03_reconcile_module2.sas
  Module 2 (safety review): recompute the checks in SAS and compare them
  with reconciliation/expected_counts.csv (Python program).
  Part A  checks 1-7 (counts)
  Part B  double programming: SAS-derived ADEDISH vs Python reference
          ADEDISH_REF (PROC COMPARE)
  Result: vaclinic.sas_checks_m2 (values used by 05_compare_va.sas)
====================================================================*/
%let datapath = /home/student/va_clinical_reporting;
options dlcreatedir;
libname vaclinic "&datapath/sasdata";
%include "&datapath/programs/03_compare_macro.sas";

/* ---------- Part A: count checks ---------- */
proc sql;
   create table work.alt_post as
   select usubjid, max(trta) as trta length=40, max(anrind = 'H') as anyh
   from vaclinic.adlbc where paramcd = 'ALT' and ady >= 1 group by usubjid;

   create table work.alt_base as
   select distinct usubjid, bnrind from vaclinic.adlbc where paramcd = 'ALT' and ablfl = 'Y';

   create table work.sas_checks as
   select 'M2_01_N_EXPOSURE' as check_id length=120, trt01a as grp length=60, count(trtdur) as value
          from vaclinic.adsl group by trt01a
   union all
   select 'M2_02_DISCONTINUED_ADVERSE_EVENT', trt01a, count(*)
          from vaclinic.adsl where dcdecod = 'ADVERSE EVENT' group by trt01a
   union all
   select 'M2_03_PULSE_LT50_SUBJECTS', trta, count(distinct usubjid)
          from vaclinic.advs
          where paramcd = 'PULSE' and atptn = 815 and 0 <= avisitn <= 26 and ady >= 1 and aval < 50
          group by trta
   union all
   select 'M2_04_PULSE_LT55_SUBJECTS', trta, count(distinct usubjid)
          from vaclinic.advs
          where paramcd = 'PULSE' and atptn = 815 and 0 <= avisitn <= 26 and ady >= 1 and aval < 55
          group by trta
   union all
   select 'M2_05_ALT_NORMAL_TO_HIGH_SUBJECTS', a.trta, count(*)
          from work.alt_post as a inner join work.alt_base as b on a.usubjid = b.usubjid
          where b.bnrind = 'N' and a.anyh = 1 group by a.trta
   union all
   select 'M2_06_EDISH|' || strip(edishcat), trt01a, count(distinct usubjid)
          from vaclinic.adedish group by edishcat, trt01a
   union all
   select 'M2_06_EDISH_N', 'all', count(*) from vaclinic.adedish
   union all
   select 'M2_07_ADLBHY_HYLAW_SUBJECTS', 'all', count(distinct usubjid)
          from vaclinic.adlbhy where paramcd = 'HYLAW' and aval = 1;
quit;

data vaclinic.sas_checks_m2; set work.sas_checks; run;

%read_expected(prefix=M2_, out=work.expected_m2)
%reconcile(expected=work.expected_m2, sas=work.sas_checks, out=work.recon_m2)

title "Module 2 reconciliation: Python expected vs SAS";
proc print data=work.recon_m2 noobs; where status ne 'PASS'; run;
title;

/* ---------- Part B: SAS ADEDISH versus Python ADEDISH_REF ---------- */
proc sort data=vaclinic.adedish     out=work.ed_sas; by usubjid; run;
proc sort data=vaclinic.adedish_ref out=work.ed_py;  by usubjid; run;

proc compare base=work.ed_py compare=work.ed_sas method=absolute criterion=1e-9 listall;
   id usubjid;
run;

/* SYSINFO bits: 4096 values unequal, 64/128 observation only in one table,
   1024/2048 variable only in one table, 8192 type conflict, 16384/32768 fatal */
%let cmp = &sysinfo;
%if %sysfunc(band(&cmp, 4096+64+128+1024+2048+8192+16384+32768)) = 0 %then
   %put NOTE: DOUBLE PROGRAMMING PASSED - SAS and Python ADEDISH agree.;
%else %put ERROR: DOUBLE PROGRAMMING FAILED - SYSINFO=&cmp.. Check PROC COMPARE output.;
