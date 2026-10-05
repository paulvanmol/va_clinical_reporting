
/* --Generate SAS librefs for caslibs-- */

/* Create a default CAS session and create SAS librefs for existing caslibs */
/* so that they are visible in the SAS Studio Libraries tree. */
cas mySession;
caslib _all_ assign;
/* --Load Data to caslib-- */

/* Load file from a client location ("pathToClientFile") into the specified */
/* caslib ("myCaslib") and save it as "tableNameForLoadedFile". */
%macro loadtocas(file=,incaslib=public,outcaslib=public,casout=);
proc casutil;
    droptable casdata="&casout" incaslib="&incaslib" quiet;
	load file="&file" outcaslib="&outcaslib" casout="&casout" promote;
    save casdata="&casout" incaslib="&incaslib" casout="&casout..sashdat" outcaslib="&outcaslib" replace;
run;
%mend;

%loadtocas(file=/workshop/va_clinical_reporting/data/module2/adex.csv,casout=adex)
%loadtocas(file=/workshop/va_clinical_reporting/data/module2/adlb.csv,casout=adlb)
%loadtocas(file=/workshop/va_clinical_reporting/data/module2/advs.csv,outcaslib=public,casout=advs)

