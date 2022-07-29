#!/bin/bash

# 2020-01-21

# * Dilate NeuroSynth Masks
# Compared to V1, in V2 (after discussion with Scott):
# - Reduce overlap to 20%
# - Use dilated NeuroSynth Masks

# * Environment
base='/Users/vincent/Data/Documents/Utah/Kladblok/20181230_Langenecker/20190411_Kim_Langenecker_project/20191118_NeuroSynth/outputMasks'
iDir="${base}/02_binCombined"
oDir="${base}/03_dilated"
mkdir -p ${oDir}

# * Loop over masks for dilation
for M in $(find ${iDir} -iname "combinedMask_majorityVoted_*.nii.gz"); do

    # Basename
    mask=$(basename ${M})

    # Cognitive Domain
    cogDom=$(echo "${mask}" | cut -d_ -f3- | sed 's/.nii.gz//g')

    # Output folder
    ooDir=${oDir}/${cogDom}
    mkdir -p ${ooDir}
    
    # Dilate
    fslmaths \
        ${M} \
        -dilM \
        ${ooDir}/combinedMask_majorityVoted_${cogDom}.nii.gz
done

exit

