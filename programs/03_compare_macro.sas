/*====================================================================
  03_compare_macro.sas
  %reconcile(expected=, sas=, out=) compares the SAS-derived check table
  (check_id, grp, value) with the expected values from the Python program.
  Missing in the SAS table counts as 0, because all checks are counts.
====================================================================*/
%macro reconcile(expected=, sas=, out=);
   proc sql;
      create table &out as
      select coalesce(e.check_id, s.check_id) as check_id length=120,
             coalesce(e.grp, s.grp)           as grp      length=60,
             e.expected                       as expected,
             coalesce(s.value, 0)             as sas_value,
             case when e.check_id is null then 'EXTRA'
                  when abs(e.expected - coalesce(s.value, 0)) < 1e-9 then 'PASS'
                  else 'FAIL' end             as status length=5
      from &expected as e
           full join &sas as s
           on e.check_id = s.check_id and e.grp = s.grp
      order by check_id, grp;

      select status, count(*) as checks from &out group by status;
   quit;

   proc sql noprint;
      select count(*) into :nfail trimmed from &out where status ne 'PASS';
   quit;
   %if &nfail = 0 %then %put NOTE: RECONCILIATION PASSED - all checks in &out agree.;
   %else %put ERROR: RECONCILIATION FAILED - &nfail check(s) differ. Open &out.;
%mend;

%macro read_expected(prefix=, out=work.expected);
   data &out;
      infile "&datapath/reconciliation/expected_counts.csv" dsd firstobs=2 truncover lrecl=32767;
      length check_id $120 grp $60 expected 8;
      input check_id $ grp $ expected;
      if substr(check_id, 1, 3) = "&prefix";
   run;
%mend;
