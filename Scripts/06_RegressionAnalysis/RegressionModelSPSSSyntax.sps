* Encoding: UTF-8.
* Regression Model for Dimension #1: Emotional Memory.
REGRESSION 
  /MISSING LISTWISE 
  /STATISTICS COEFF OUTS R ANOVA ZPP 
  /CRITERIA=PIN(.05) POUT(.10) 
  /NOORIGIN 
  /DEPENDENT Factor1_EM 
  /METHOD=ENTER Gender0Male1Female Age Education Group0HC1rMDDoreBP Age2GroupINT EMcluster01 
    EMcluster02 EMcluster03 EMcluster04 EMcluster05 EMcluster06 EMcluster07 
  
* Regression Model for Dimension #2: Interference Resolution.
REGRESSION 
  /MISSING LISTWISE 
  /STATISTICS COEFF OUTS R ANOVA ZPP 
  /CRITERIA=PIN(.05) POUT(.10) 
  /NOORIGIN 
  /DEPENDENT Factor2_IR 
  /METHOD=ENTER Gender0Male1Female Age Education Group0HC1rMDDoreBP Age2GroupINT IRcluster01 
    IRcluster02 IRcluster03 IRcluster04 IRcluster05 IRcluster06 IRcluster07 IRcluster08 IRcluster09 
    IRcluster10 

* Regression Model for Dimension #3: Reward Sensitivity.
REGRESSION 
  /MISSING LISTWISE 
  /STATISTICS COEFF OUTS R ANOVA ZPP 
  /CRITERIA=PIN(.05) POUT(.10) 
  /NOORIGIN 
  /DEPENDENT Factor3_RS 
  /METHOD=ENTER Gender0Male1Female Age Education Group0HC1rMDDoreBP Age2GroupINT RScluster01 
    RScluster02 RScluster03 RScluster04 RScluster05
    
* Regression Model for Dimension #4: Complex Inhibitory Control.
REGRESSION 
  /MISSING LISTWISE 
  /STATISTICS COEFF OUTS R ANOVA ZPP 
  /CRITERIA=PIN(.05) POUT(.10) 
  /NOORIGIN 
  /DEPENDENT Factor4_CI 
  /METHOD=ENTER Gender0Male1Female Age Education Group0HC1rMDDoreBP Age2GroupINT CIcluster01 
    CIcluster02 CIcluster03 CIcluster04 CIcluster05 CIcluster06 CIcluster07 CIcluster08 CIcluster09 
    CIcluster10
    
* Regression Model for Dimension #5: Facial Emotion Sensitivity.
REGRESSION 
  /MISSING LISTWISE 
  /STATISTICS COEFF OUTS R ANOVA ZPP 
  /CRITERIA=PIN(.05) POUT(.10) 
  /NOORIGIN 
  /DEPENDENT Factor5_FE 
  /METHOD=ENTER Gender0Male1Female Age Education Group0HC1rMDDoreBP Age2GroupINT FEcluster01 
    FEcluster02 FEcluster03 FEcluster04 FEcluster05
    
* Regression Model for Dimension #6: Sustained Attention.
REGRESSION 
  /MISSING LISTWISE 
  /STATISTICS COEFF OUTS R ANOVA ZPP 
  /CRITERIA=PIN(.05) POUT(.10) 
  /NOORIGIN 
  /DEPENDENT Factor6_SA 
  /METHOD=ENTER Gender0Male1Female Age Education Group0HC1rMDDoreBP Age2GroupINT SAcluster01 
    SAcluster02 SAcluster03 SAcluster04 SAcluster05
    
* Regression Model for Dimension #7: Simple Impulsivity/Response Style.
REGRESSION 
  /MISSING LISTWISE 
  /STATISTICS COEFF OUTS R ANOVA ZPP 
  /CRITERIA=PIN(.05) POUT(.10) 
  /NOORIGIN 
  /DEPENDENT Factor7_SI 
  /METHOD=ENTER Gender0Male1Female Age Education Group0HC1rMDDoreBP Age2GroupINT SIcluster01 
    SIcluster02 SIcluster03 SIcluster04 SIcluster05 SIcluster06 SIcluster07