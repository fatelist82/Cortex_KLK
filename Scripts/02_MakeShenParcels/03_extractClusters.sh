#!/bin/bash

# * Extract Clusters from the NeuroSynth atlas
# 2020-01-09

## * CRITERIUM 2:
# - NeuroSynth mask is for at least 50% in a single Shen ROI
# - The number of voxels of the NeuroSynth in Shen ROI is
#   at least 100 voxels.
# (obviosuly, this does not apply to very large NeuroSynth
# masks, because they will be too large to fit at least
# for half part inside a singel Shen ROI).

# * Environment
base='/Users/vincent/Data/Documents/Utah/Kladblok/20181230_Langenecker/20190411_Kim_Langenecker_project'
nsDir="${base}/20191118_NeuroSynth/outputMasks/02_binCombined"
shenDir="${base}/20200121_makeShenParcels/outputParcels"
#mkdir -p ${outDir}

# * Loop over domains
for D in $(ls -p ${nsDir} | grep \/ | sed 's/\///g'); do
    
    # Extract Cognitive Domain
    domain=$(basename ${D})
    dShort=$(echo ${domain} | cut -d_ -f 1-3)
    echo ${dShort}
        
    # NeuroSynth mask
    nsMask=${nsDir}/${domain}/combinedMask_majorityVoted_${domain}.nii.gz
    
    # Output folders
    oDir1=${shenDir}/${dShort}/tmp_4_NSclusters
    oDir2=${shenDir}/${dShort}/tmp_5_selectedShenROIs2
    mkdir -p ${oDir1} ${oDir2}
    
    # Extract clusters
    cluster \
        --in=${nsMask} \
        --thresh=0.1 \
        --minextent=100 \
        --osize=${oDir1}/clusters_${dShort}.nii.gz \
        > ${oDir1}/clusters_${dShort}.txt

    # * Extract the list of clusters
    list=$(
        cat ${oDir1}/clusters_${dShort}.txt \
            | grep -v vox \
            | awk '{ print $2 }'
        )

    # * Loop over all clusters in the NeurSynth mask
    for cluster in $(echo ${list}); do

        # NOTE THAT 'cluster' is also the SIZE OF THE ENTIRE CLUSTER IN # VOXELS
        
        # Extract cluster
        fslmaths \
            ${oDir1}/clusters_${dShort}.nii.gz \
            -thr ${cluster} \
            -uthr ${cluster} \
            -bin \
            ${oDir1}/cluster_${cluster}.nii.gz

        # Loop over all shen lobules
        for shenROI in $(ls ${shenDir}/${dShort}/tmp_1_shenROIs/*.nii.gz); do

            # Number
            S=$(basename ${shenROI} | cut -c 7-9)
        
            # Test the size of the Shen lobule
            shenSize=$(fslstats ${shenROI} -V | awk '{ print $1 }')

            # Test the number of voxels of the NeuroSynth
            # cluster -within- the ShenROI
            fslmaths \
                ${oDir1}/cluster_${cluster}.nii.gz \
                -mas ${shenROI} \
                ${oDir1}/cluster_${cluster}_masked_${S}.nii.gz

            NSmaskedSize=$(
                fslstats \
                    ${oDir1}/cluster_${cluster}_masked_${S}.nii.gz -V \
                    | awk '{ print $1 }'
                        )

            # Now do the testing:
            # - NeuroSynth mask is for at least 50% in a single Shen ROI
            proportion=$(echo "scale=3; ${NSmaskedSize} / ${cluster}" | bc)
            test=$(echo "python -c \"if ${proportion}>0.5: print('1')\"")
            output=$(eval ${test})
            if [ -z ${output} ]; then output=0; fi


            
            if [ ${output} -eq 1 ]; then

                # - The number of voxels of the NeuroSynth in Shen ROI is
                #   at least 100 voxels.
                if [ ${NSmaskedSize} -ge 100 ]; then

                    # THEN copy over the Shen ROI to the output folder
                    cp ${shenROI} ${oDir2}

                    # Announce:
                    echo $(tput setaf 2)"${dShort} - ${cluster} - ${S} - ${shenSize} - ${NSmaskedSize} - ${proportion}"$(tput sgr0)

                fi
                    
            else

                # Announce:
                echo $(tput setaf 1)"${dShort} - ${cluster} - ${S} - ${shenSize} - ${NSmaskedSize} - ${proportion}"$(tput sgr0)

            fi

        done

    done
    
done

        
    
