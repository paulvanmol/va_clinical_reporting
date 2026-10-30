"""
00_build_data.py
Rebuild the training data of this repository from the public CDISC pilot study
(CDISCPILOT01, Xanomeline TTS in Alzheimer's disease), as published by PHUSE:
https://github.com/phuse-org/phuse-scripts/tree/master/data/adam/cdisc

The data are real ADaM datasets from the CDISC pilot (test data, no real patients).
They contain the cases a teaching set needs:
  - treatment-emergent AEs with a clear dose/arm pattern (application-site events)
  - 3 serious AEs (2x syncope, 1x seizure)
  - a placebo subject in the eDISH "potential Hy's Law" quadrant (01-705-1186)
  - subjects with low pulse after treatment

Usage:   python programs/00_build_data.py
Needs:   pandas, pyreadstat   (pip install pandas pyreadstat)

Output (data/):  <name>.xpt (SAS transport v5, with labels)  and  <name>.csv
  adsl, adae, advs, adlbc, adlbhy   - subsets of the CDISC pilot ADaM datasets
  adedish                        - ONE ROW PER SUBJECT, derived here in Python
                                      (the independent second program for double programming;
                                       programs/02_derive_edish.sas is the SAS version)
"""
import os
import urllib.request
import pandas as pd
import pyreadstat

BASE = "https://raw.githubusercontent.com/phuse-org/phuse-scripts/master/data/adam/cdisc/"
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SRC = os.path.join(ROOT, "source")      # download cache, not committed
OUT = os.path.join(ROOT, "data")
os.makedirs(SRC, exist_ok=True)
os.makedirs(OUT, exist_ok=True)


def get(name):
    path = os.path.join(SRC, name + ".xpt")
    if not os.path.exists(path):
        print("downloading", name)
        urllib.request.urlretrieve(BASE + name + ".xpt", path)
    df, meta = pyreadstat.read_xport(path)
    labels = dict(zip(meta.column_names, meta.column_labels))
    return df, labels


def write(df, labels, name, label, date_cols=()):
    """Write xpt (v5) with labels + csv (ISO dates)."""
    labs = [(labels.get(c) or c)[:40] for c in df.columns]
    fmt = {c: "DATE9" for c in date_cols if c in df.columns}
    pyreadstat.write_xport(df, os.path.join(OUT, name + ".xpt"), table_name=name.upper(),
                           file_label=label, column_labels=labs,
                           file_format_version=5, variable_format=fmt)
    out = df.copy()
    for c in date_cols:
        if c in out.columns:
            out[c] = pd.to_datetime(out[c]).dt.strftime("%Y-%m-%d")
    out.to_csv(os.path.join(OUT, name + ".csv"), index=False)
    print(f"{name:11s} {len(df):6d} rows {len(df.columns):3d} cols")


# ---------------------------------------------------------------- ADSL, ADAE
adsl, l_adsl = get("adsl")
adae, l_adae = get("adae")
write(adsl, l_adsl, "adsl", "Subject-Level Analysis Dataset",
      ["TRTSDT", "TRTEDT", "DISONSDT", "VISIT1DT", "RFENDT"])
write(adae, l_adae, "adae", "Adverse Events Analysis Dataset",
      ["TRTSDT", "TRTEDT", "ASTDT", "AENDT"])

site = adsl.set_index("USUBJID")["SITEID"]

# ---------------------------------------------------------------- ADVS
advs, l_advs = get("advs")
advs = advs[advs.PARAMCD.isin(["SYSBP", "DIABP", "PULSE"])].copy()
keep = ["STUDYID", "SITEID", "USUBJID", "AGE", "AGEGR1", "SEX", "RACE", "SAFFL", "TRTSDT", "TRTEDT",
        "TRTA", "TRTAN", "PARAMCD", "PARAM", "PARAMN", "ADT", "ADY", "ATPTN", "ATPT", "AVISIT", "AVISITN",
        "AVAL", "BASE", "CHG", "ANL01FL", "ABLFL", "ANRLO", "ANRHI", "BNRIND", "ANRIND", "VSSEQ"]
advs = advs[keep]
write(advs, l_advs, "advs", "Vital Signs Analysis Dataset (subset)", ["TRTSDT", "TRTEDT", "ADT"])

# ---------------------------------------------------------------- ADLBC
adlbc, l_lbc = get("adlbc")
adlbc = adlbc[adlbc.PARAMCD.isin(["ALT", "AST", "ALP", "BILI", "CREAT", "GLUC"])].copy()
adlbc["SITEID"] = adlbc.USUBJID.map(site)
l_lbc["SITEID"] = "Study Site Identifier"
keep = ["STUDYID", "SITEID", "USUBJID", "TRTA", "TRTAN", "AGE", "AGEGR1", "SEX", "RACE", "SAFFL",
        "TRTSDT", "TRTEDT", "AVISIT", "AVISITN", "ADY", "ADT", "PARAM", "PARAMCD", "PARAMN",
        "AVAL", "BASE", "CHG", "A1LO", "A1HI", "R2A1HI", "ANL01FL", "ANRIND", "BNRIND", "ABLFL", "LBSEQ"]
adlbc = adlbc[keep]
write(adlbc, l_lbc, "adlbc", "Lab Chemistry Analysis Dataset (subset)", ["TRTSDT", "TRTEDT", "ADT"])

# ---------------------------------------------------------------- ADLBHY (as published)
adlbhy, l_hy = get("adlbhy")
keep = ["STUDYID", "USUBJID", "TRTA", "TRTAN", "SAFFL", "AVISIT", "AVISITN", "ADY", "ADT",
        "PARAMTYP", "PARAM", "PARAMCD", "PARAMN", "AVAL", "BASE", "A1LO", "A1HI", "R2A1HI",
        "CRIT1", "CRIT1FL", "ANL01FL", "ABLFL"]
adlbhy = adlbhy[keep]
write(adlbhy, l_hy, "adlbhy", "Hy's Law Lab Analysis Dataset", ["ADT"])

# ---------------------------------------------------------------- ADEDISH (derived)
# One row per subject: peak post-baseline ALT, AST and BILI as multiple of the upper limit
# of normal (R2A1HI = AVAL / A1HI). Post-baseline = ADY >= 1, scheduled and unscheduled visits.
lb = adlbc[adlbc.PARAMCD.isin(["ALT", "AST", "BILI"]) & (adlbc.ADY >= 1)]
peak = lb.pivot_table(index="USUBJID", columns="PARAMCD", values="R2A1HI", aggfunc="max")
peak.columns = [c + "XULN" for c in peak.columns]
peak = peak.reset_index()
peak = adsl[["STUDYID", "USUBJID", "SITEID", "TRT01A", "AGE", "SEX", "RACE"]].merge(peak, on="USUBJID", how="inner")
peak = peak.dropna(subset=["ALTXULN", "BILIXULN"])


def quadrant(r):
    alt, bili = r.ALTXULN >= 3, r.BILIXULN >= 2
    if alt and bili:
        return "Potential Hy's Law"
    if alt:
        return "Temple's Corollary"
    if bili:
        return "Hyperbilirubinemia"
    return "Normal"


peak["EDISHCAT"] = peak.apply(quadrant, axis=1)
l_ed = {"STUDYID": "Study Identifier", "USUBJID": "Unique Subject Identifier", "SITEID": "Study Site Identifier",
        "TRT01A": "Actual Treatment for Period 01", "AGE": "Age", "SEX": "Sex", "RACE": "Race",
        "ALTXULN": "Peak ALT x ULN", "ASTXULN": "Peak AST x ULN", "BILIXULN": "Peak Bilirubin x ULN",
        "EDISHCAT": "eDISH Category"}
write(peak, l_ed, "adedish", "eDISH data, one row per subject")
print(peak.EDISHCAT.value_counts().to_string())
