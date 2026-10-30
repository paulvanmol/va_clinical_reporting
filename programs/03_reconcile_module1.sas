/*====================================================================
  03_reconcile_module1.sas
  Module 1 (ADSL + ADAE): recompute the checks in SAS and compare them
  with reconciliation/expected_counts.csv (Python program).
  Result: vaclinic.sas_checks_m1 (values used by 05_compare_va.sas)
====================================================================*/
%let datapath = /home/student/va_clinical_reporting;
options dlcreatedir;
libname vaclinic "&datapath/sasdata";
%include "&datapath/programs/03_compare_macro.sas";

/* TEAE population */
data work.teae;
   set vaclinic.adae;
   where saffl = 'Y' and trtemfl = 'Y';
run;

/* worst severity per subject */
proc sql;
   create table work.worst as
   select trta, usubjid,
          max(case aesev when 'MILD' then 1 when 'MODERATE' then 2 when 'SEVERE' then 3 end) as r
   from work.teae group by trta, usubjid;

   create table work.sas_checks as
   select 'M1_01_N_SUBJECTS' as check_id length=120, trt01a as grp length=60,
          count(distinct usubjid) as value from vaclinic.adsl group by trt01a
   union all
   select 'M1_02_ROWS', 'ADSL', count(*) from vaclinic.adsl
   union all
   select 'M1_02_ROWS', 'ADAE', count(*) from vaclinic.adae
   union all
   select 'M1_02_ROWS', 'ADAE_TEAE', count(*) from work.teae
   union all
   select 'M1_03_SUBJECTS_WITH_AE', 'any AE', count(distinct usubjid) from vaclinic.adae
   union all
   select 'M1_03_SUBJECTS_WITH_AE', 'TEAE', count(distinct usubjid) from work.teae
   union all
   select 'M1_04_TEAE_SUBJECTS', trta, count(distinct usubjid) from work.teae group by trta
   union all
   select 'M1_05_TEAE_RECORDS', trta, count(*) from work.teae group by trta
   union all
   select 'M1_06_SEVERE_SUBJECTS', trta, count(distinct usubjid) from work.teae
          where aesev = 'SEVERE' group by trta
   union all
   select 'M1_06_SEVERE_RECORDS', 'all', count(*) from work.teae where aesev = 'SEVERE'
   union all
   select 'M1_07_SOC_SUBJECTS|' || strip(aebodsys), trta, count(distinct usubjid)
          from work.teae group by aebodsys, trta
   union all
   select 'M1_08_APPLICATION_SITE_SUBJECTS', trta, count(distinct usubjid)
          from work.teae where index(aedecod, 'APPLICATION SITE') > 0 group by trta
   union all
   select 'M1_09_SERIOUS_AE_RECORDS', 'all', count(*) from vaclinic.adae where aeser = 'Y'
   union all
   select 'M1_10_WORST_SEVERITY_SUBJECTS|' ||
          case r when 1 then 'MILD' when 2 then 'MODERATE' else 'SEVERE' end,
          trta, count(*) from work.worst group by r, trta;
quit;

data vaclinic.sas_checks_m1; set work.sas_checks; run;

%read_expected(prefix=M1_, out=work.expected_m1)
%reconcile(expected=work.expected_m1, sas=work.sas_checks, out=work.recon_m1)

title "Module 1 reconciliation: Python expected vs SAS";
proc print data=work.recon_m1 noobs; where status ne 'PASS'; run;
title;
