"""Generate the synthetic table_AE_DM.csv (AE left-joined to DM, one row per AE).
Structure mirrors the SDTM CDISC pilot (Xanomeline). Values are SYNTHETIC - no real patients.
Run: python scripts/generate_data.py   (fixed seed -> reproducible)"""
import random, csv, datetime as dt
random.seed(2026)
ARMS=[("Placebo","Pbo",86),("Xanomeline Low Dose","Xan_Lo",84),("Xanomeline High Dose","Xan_Hi",84)]
SITES=["701","702","703","704","705","706","707","708","709","710","711","713","714","715","716","717","718"]
AES=[
("APPLICATION SITE PRURITUS","APPLICATION SITE PRURITUS","GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",1,6,7),
("APPLICATION SITE ERYTHEMA","APPLICATION SITE ERYTHEMA","GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",1,4,5),
("APPLICATION SITE IRRITATION","APPLICATION SITE IRRITATION","GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",1,3,4),
("FATIGUE","FATIGUE","GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS",1,2,2),
("PRURITUS","PRURITUS","SKIN AND SUBCUTANEOUS TISSUE DISORDERS",2,5,5),
("ERYTHEMA","ERYTHEMA","SKIN AND SUBCUTANEOUS TISSUE DISORDERS",2,3,3),
("RASH","RASH","SKIN AND SUBCUTANEOUS TISSUE DISORDERS",2,3,3),
("DIZZINESS","DIZZINESS","NERVOUS SYSTEM DISORDERS",1,3,4),
("HEADACHE","HEADACHE","NERVOUS SYSTEM DISORDERS",2,2,2),
("SYNCOPE","SYNCOPE","NERVOUS SYSTEM DISORDERS",0.2,1,1.2),
("NAUSEA","NAUSEA","GASTROINTESTINAL DISORDERS",1,2,3),
("VOMITING","VOMITING","GASTROINTESTINAL DISORDERS",1,1,2),
("DIARRHOEA","DIARRHOEA","GASTROINTESTINAL DISORDERS",2,1,1),
("SINUS BRADYCARDIA","SINUS BRADYCARDIA","CARDIAC DISORDERS",0.5,1.5,2),
("MYOCARDIAL INFARCTION","MYOCARDIAL INFARCTION","CARDIAC DISORDERS",0.3,0.5,0.5),
("NASOPHARYNGITIS","NASOPHARYNGITIS","INFECTIONS AND INFESTATIONS",1.5,1,1),
("UPPER RESPIRATORY TRACT INFECTION","UPPER RESPIRATORY TRACT INFECTION","INFECTIONS AND INFESTATIONS",1.5,1,1),
("FALL","FALL","INJURY, POISONING AND PROCEDURAL COMPLICATIONS",0.8,1,1),
("BACK PAIN","BACK PAIN","MUSCULOSKELETAL AND CONNECTIVE TISSUE DISORDERS",1,1,1),
("AGITATION","AGITATION","PSYCHIATRIC DISORDERS",1,1,1),
("CONFUSIONAL STATE","CONFUSIONAL STATE","PSYCHIATRIC DISORDERS",0.5,1,1),
("HYPERHIDROSIS","HYPERHIDROSIS","SKIN AND SUBCUTANEOUS TISSUE DISORDERS",0.3,1,2),
]
RACES=[("WHITE",0.86),("BLACK OR AFRICAN AMERICAN",0.09),("AMERICAN INDIAN OR ALASKA NATIVE",0.01),("ASIAN",0.04)]
def wpick(items,weights): return random.choices(items,weights=weights)[0]
def d(x): return x.strftime("%Y-%m-%d") if x else ""
rows=[]; subjects=[]
for arm,armcd,n in ARMS:
    for _ in range(n): subjects.append((arm,armcd))
random.shuffle(subjects)
used=set()
FIXED={"01-708-1019":("Xanomeline Low Dose","Xan_Lo",68,"M","WHITE"),
       "01-701-1211":("Xanomeline High Dose","Xan_Hi",76,"F","WHITE")}
ids=list(FIXED)
while len(ids)<len(subjects):
    s=f"01-{random.choice(SITES)}-{random.randint(1001,1450)}"
    if s not in used and s not in FIXED: used.add(s); ids.append(s)
subj=[]
for i,usub in enumerate(ids):
    if usub in FIXED: arm,armcd,age,sex,race=FIXED[usub]
    else:
        arm,armcd=subjects[i]; age=max(51,min(89,int(random.gauss(75,8)))); sex=wpick(["F","M"],[0.56,0.44])
        race=wpick([r for r,_ in RACES],[w for _,w in RACES])
    subj.append((usub,arm,armcd,age,sex,race))
for usub,arm,armcd,age,sex,race in subj:
    site=usub.split("-")[1]
    rfst=dt.date(2012,7,1)+dt.timedelta(days=random.randint(0,700))
    if usub=="01-708-1019": rfst=dt.date(2013,12,2)
    dur=random.choice([182]*6+[random.randint(14,181)])
    rfen=rfst+dt.timedelta(days=dur-1)
    actarm,actarmcd=arm,armcd
    if random.random()<0.02 and armcd!="Pbo": actarm,actarmcd="Placebo","Pbo"
    dm=dict(STUDYID="CDISCPILOT01",USUBJID=usub,SUBJID=usub.split("-")[2],SITEID=site,AGE=age,AGEU="YEARS",
            SEX=sex,RACE=race,ETHNIC=wpick(["NOT HISPANIC OR LATINO","HISPANIC OR LATINO"],[0.94,0.06]),
            ARMCD=armcd,ARM=arm,ACTARMCD=actarmcd,ACTARM=actarm,COUNTRY="USA",
            RFSTDTC=d(rfst),RFENDTC=d(rfen),DTHFL="",DTHDTC="")
    k={"Pbo":3,"Xan_Lo":4,"Xan_Hi":4}[actarmcd]
    col={"Pbo":3,"Xan_Lo":4,"Xan_Hi":5}[actarmcd]
    nae=0 if random.random()<{"Pbo":0.22,"Xan_Lo":0.08,"Xan_Hi":0.07}[actarmcd] else max(1,int(random.expovariate(1/k)))
    aes=[]
    for _ in range(nae):
        a=random.choices(AES,weights=[x[col] for x in AES])[0]
        sevw=[0.62,0.31,0.07] if age<75 else [0.52,0.36,0.12]
        if actarmcd=="Xan_Hi": sevw=[sevw[0]-0.04,sevw[1]+0.02,sevw[2]+0.02]
        sev=wpick(["MILD","MODERATE","SEVERE"],sevw)
        aes.append((a,sev))
    if usub=="01-708-1019":
        aes=[(("HEADACHE","HEADACHE","NERVOUS SYSTEM DISORDERS"),"SEVERE"),
             (("STUPOR","STUPOR","NERVOUS SYSTEM DISORDERS"),"SEVERE"),
             (("TRANSIENT ISCHAEMIC ATTACK","TRANSIENT ISCHAEMIC ATTACK","NERVOUS SYSTEM DISORDERS"),"SEVERE"),
             (("APPLICATION SITE PRURITUS","APPLICATION SITE PRURITUS","GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS"),"MILD")]
    if usub=="01-701-1211":
        aes=[((a[0],a[1],a[2]),s) for a,s in [(AES[0],"MODERATE"),(AES[7],"SEVERE"),(AES[17],"SEVERE"),(AES[20],"SEVERE"),(AES[10],"MILD"),(AES[13],"MODERATE")]]
    if not aes: rows.append({**dm}); continue
    for seq,(a,sev) in enumerate(aes,1):
        stdy=random.randint(1,dur)
        if usub=="01-708-1019" and seq<=3: stdy=53
        st=rfst+dt.timedelta(days=stdy-1)
        en=st+dt.timedelta(days=random.randint(0,30)) if random.random()>0.1 else None
        ser="Y" if sev=="SEVERE" and random.random()<0.35 else "N"
        if usub=="01-708-1019" and seq<=3: ser="Y"
        rel=wpick(["NONE","REMOTE","POSSIBLE","PROBABLE"],[0.35,0.15,0.3,0.2] if a[2].startswith("GENERAL") else [0.45,0.2,0.25,0.1])
        if usub=="01-708-1019" and seq<=3: rel="POSSIBLE"
        rows.append({**dm,"AESEQ":seq,"AESPID":f"E{seq:02d}","AETERM":a[0],"AEDECOD":a[1],
            "AEBODSYS":a[2],"AESEV":sev,"AESER":ser,"AEREL":rel,"AEACN":"DOSE NOT CHANGED" if sev!="SEVERE" else wpick(["DRUG WITHDRAWN","DOSE NOT CHANGED"],[0.4,0.6]),
            "AEOUT":"RECOVERED/RESOLVED" if en else "NOT RECOVERED/NOT RESOLVED",
            "AESTDTC":d(st),"AEENDTC":d(en),"AESTDY":stdy,"AEENDY":(en-rfst).days+1 if en else ""})
cols=["STUDYID","USUBJID","SUBJID","SITEID","AGE","AGEU","SEX","RACE","ETHNIC","ARMCD","ARM","ACTARMCD","ACTARM","COUNTRY",
      "RFSTDTC","RFENDTC","DTHFL","DTHDTC","AESEQ","AESPID","AETERM","AEDECOD","AEBODSYS","AESEV","AESER","AEREL","AEACN",
      "AEOUT","AESTDTC","AEENDTC","AESTDY","AEENDY"]
with open("data/table_AE_DM.csv","w",newline="") as f:
    w=csv.DictWriter(f,fieldnames=cols); w.writeheader(); [w.writerow({c:r.get(c,"") for c in cols}) for r in rows]
print(len(rows),"rows,",len(subj),"subjects")
