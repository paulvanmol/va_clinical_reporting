options dlcreatedir;
%let repoPath = %sysfunc(getoption(WORK))/va_clinical_reporting;
%let repoPath = /home/student/va_clinical_reporting;
libname repo "&repoPath.";
libname repo clear;  

/* Fetch latest code from GitHub */
data _null_;
rc = git_clone("https://github.com/paulvanmol/va_clinical_reporting/", "&repoPath.");
put rc=; 
run;
