"""Module 2 data: SYNTHETIC cardiometabolic safety data (ADaM-like, long format) for the
same 254 subjects as data/table_AE_DM.csv. Fixed seed -> reproducible.
Planted teaching signals:
 - 2 potential Hy's Law cases (ALT > 3xULN and BILI > 2xULN) on High Dose
 - dose-related heart-rate decrease + a few bradycardia outliers (< 50 bpm)
 - small HbA1c / glucose decrease on active arms
Run (after generate_data.py): python scripts/generate_module2.py"""
import random, datetime as dt
import pandas as pd
random.seed(42)
dm=pd.read_csv("data/table_AE_DM.csv",dtype=str).drop_duplicates("USUBJID").reset_index(drop=True)
VIS=[("BASELINE",0,1),("WEEK 2",1,15),("WEEK 8",2,57),("WEEK 16",3,113),("WEEK 24",4,169)]
LAB=[("ALT","Alanine Aminotransferase","U/L",6,34,20,7),
     ("AST","Aspartate Aminotransferase","U/L",10,36,22,6),
     ("BILI","Bilirubin","umol/L",3,21,9,3),
     ("CREAT","Creatinine","umol/L",53,115,85,15),
     ("GLUC","Glucose (fasting)","mmol/L",3.9,6.1,6.4,1.3),
     ("HBA1C","HbA1c","%",4.0,6.0,6.6,0.8)]
VSP=[("SYSBP","Systolic Blood Pressure","mmHg",137,15),("DIABP","Diastolic Blood Pressure","mmHg",78,9),("PULSE","Heart Rate","beats/min",74,9)]
hi=dm[dm.ACTARMCD=="Xan_Hi"].USUBJID.tolist()
HYS=["01-701-1211",[u for u in hi if u!="01-701-1211"][5]]
BRADY=set(dm[dm.ACTARMCD=="Xan_Hi"].USUBJID.sample(4,random_state=1))|set(dm[dm.ACTARMCD=="Xan_Lo"].USUBJID.sample(2,random_state=2))
def ncat(v,lo,hi_): return "LOW" if v<lo else "HIGH" if v>hi_ else "NORMAL"
lb=[];vs=[];ex=[]
for _,s in dm.iterrows():
    arm=s.ACTARMCD; eff={"Pbo":0,"Xan_Lo":1,"Xan_Hi":2}[arm]
    rf=dt.date.fromisoformat(s.RFSTDTC); en=dt.date.fromisoformat(s.RFENDTC); dur=(en-rf).days+1
    if s.USUBJID in HYS: dur=max(dur,170)
    nvis=sum(1 for v in VIS if v[2]<=dur)
    for code,name,u,lo,hi_,m,sd in LAB:
        b=round(max(lo*0.6,random.gauss(m,sd)),1)
        for vn,i,day in VIS[:nvis]:
            v=b
            if i>0:
                v=b*random.gauss(1,0.10)
                if code=="HBA1C": v-=eff*0.12*min(i,3)
                if code=="GLUC":  v-=eff*0.25*min(i,3)
                if code in("ALT","AST") and random.random()<0.015: v=hi_*random.uniform(1.5,3.5)
                if s.USUBJID in HYS:
                    if code=="ALT" and i>=2: v=hi_*random.uniform(4,7)
                    if code=="AST" and i>=2: v=hi_*random.uniform(3,5)
                    if code=="BILI" and i>=3: v=hi_*random.uniform(2.2,3)
            v=round(max(v,lo*0.3),1)
            lb.append(dict(USUBJID=s.USUBJID,PARAMCD=code,PARAM=f"{name} ({u})",AVISIT=vn,AVISITN=i,ADY=day,AVAL=v,BASE=b,
                CHG=round(v-b,1),ANRLO=lo,ANRHI=hi_,BNRIND=ncat(b,lo,hi_),ANRIND=ncat(v,lo,hi_),XULN=round(v/hi_,2)))
    for code,name,u,m,sd in VSP:
        b=round(random.gauss(m,sd))
        for vn,i,day in VIS[:nvis]:
            v=b if i==0 else b+random.gauss(0,sd*0.4)
            if code=="PULSE" and i>0:
                v-=eff*3*min(i,2)
                if s.USUBJID in BRADY and i>=2: v=random.uniform(42,49)
            v=round(v)
            vs.append(dict(USUBJID=s.USUBJID,PARAMCD=code,PARAM=f"{name} ({u})",AVISIT=vn,AVISITN=i,ADY=day,AVAL=v,BASE=b,CHG=v-b))
    dose={"Pbo":0,"Xan_Lo":54,"Xan_Hi":81}[arm]
    comp=dur>=169
    ex.append(dict(USUBJID=s.USUBJID,EXTRT="PLACEBO" if dose==0 else "XANOMELINE",EXDOSE=dose,EXDOSU="mg",EXDOSFRM="PATCH",EXDOSFRQ="QD",
        TRTSDY=1,TRTEDY=dur,TRTDURD=dur,COMPLFL="Y" if comp else "N",
        DCREAS="" if comp else random.choice(["ADVERSE EVENT","ADVERSE EVENT","WITHDREW CONSENT","LACK OF EFFICACY","PHYSICIAN DECISION"])))
sub=dm[["USUBJID","SITEID","AGE","SEX","RACE","ACTARM","ACTARMCD"]]
for name,rows in [("adlb",lb),("advs",vs),("adex",ex)]:
    pd.DataFrame(rows).merge(sub,on="USUBJID").to_csv(f"data/module2/{name}.csv",index=False)
print(len(lb),len(vs),len(ex),"Hy's Law:",HYS,"Bradycardia:",sorted(BRADY))
