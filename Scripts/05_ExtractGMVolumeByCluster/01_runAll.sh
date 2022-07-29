#!/bin/bash

# * Grab Labels And Create Masks for All Clusters
# 2020-10-23


# * Environment
base="/Users/vincent/Data/Documents/Utah/Kladblok/20181230_Langenecker/20190411_Kim_Langenecker_project/20200302_GM_Factors"
iDir="${base}/20200203_FromJoe/20201023_All"
script="${base}/20200203_GrabROIs/00_grabClusters_unique.R"


# * Loop over all Factor files
for factorFile in $(ls ${iDir}/*.csv); do

    # Run Script
    ${script} ${factorFile}

done

exit


