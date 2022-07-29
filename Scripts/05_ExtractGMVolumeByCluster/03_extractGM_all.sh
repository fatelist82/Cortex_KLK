#!/bin/bash

# * Extract GM per cognitive domain per factor
# 2020-10-24
# This is a loop for the R function


# * Environment
base='/Users/vincent/Data/Documents/Utah/Kladblok/20181230_Langenecker/20190411_Kim_Langenecker_project'
pDir=${base}/20200302_GM_Factors/20200203_GrabROIs/Output_Unique
iDir=${base}/20200121_makeShenParcels/outputGMvolumes/patched
script=${base}/20200302_GM_Factors/20200421_GMExtraction/02_extractGM.R

# * Loop over dimension numbers
# Dimension number = cognitive domain number
for i in {1..7}; do

    ${script} \
        $(find ${pDir} -iname "Dim${i}_*factors*_N.csv") \
        $(find ${iDir} -iname "${i}_*_patched.csv")

done

exit


