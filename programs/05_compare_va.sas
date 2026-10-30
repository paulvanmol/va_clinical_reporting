/*====================================================================
  05_compare_va.sas
  Compare the numbers you read in your VA report with the SAS-derived
  values. Fill in reconciliation/va_values.csv first (copy of
  va_values_template.csv, column va_value). Run the two programs
  03_reconcile_module1.sas and 03_reconcile_module2.sas before.
  Output: work.va_recon with PASS / FAIL / NOT FILLED per row.
====================================================================*/
%let datapath = /home/student/va_clinical_reporting;
libname vaclinic "&datapath/sasdata";

data work.va;
   infile "&datapath/reconciliation/va_values.csv" dsd firstobs=2 truncover lrecl=32767;
   length check_id $120 grp $60 va_value 8;
   input check_id $ grp $ va_value;
run;

data work.sas_all;
   set vaclinic.sas_checks_m1 vaclinic.sas_checks_m2;
run;

proc sql;
   create table work.va_recon as
   select v.check_id, v.grp, v.va_value,
          coalesce(s.value, 0) as sas_value,
          case when v.va_value is missing then 'NOT FILLED'
               when abs(v.va_value - coalesce(s.value, 0)) < 1e-9 then 'PASS'
               else 'FAIL' end as status length=10
   from work.va as v
        left join work.sas_all as s on v.check_id = s.check_id and v.grp = s.grp;
quit;

title "VA report versus SAS-derived values";
proc print data=work.va_recon noobs; run;
proc freq data=work.va_recon; tables status / nocum; run;
title;
