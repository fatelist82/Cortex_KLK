#!/bin/bash
set -e
# 2020-01-28

# * Extract Gray Matter Volume for all subjects
# All subjects in the sample that Scott sent met

# * Data is stored on thalia, so it should be mounted
if [ ! -d /Volumes/thalia ]; then
    echo "Thalia not mounted. Mounting Thalia."
    server_Ut
fi

# * Environment
base="/Users/vincent/Data/Documents/Utah/Kladblok/20181230_Langenecker/20190411_Kim_Langenecker_project/20200121_makeShenParcels"
pDir="${base}/outputParcels"
tDir="/Users/vincent/Data/tmp/20200127_gmExtractiontmp"
mkdir -p ${tDir}
#iBase="/Volumes/thalia/data/MoCoLab/Kladblok/20181230_Langenecker"
#iDir1="${iBase}/20181230_Langenecker_R01/01_Segment"
#iDir2="${iBase}/20181230_Langenecker_R01_part2/01_Segment"
iBase="/Users/vincent/Data/tmp"
iDir1="${iBase}/20181230_Langenecker_R01/01_Segment"
iDir2="${iBase}/20181230_Langenecker_R01_part2/01_Segment"
oDir="${base}/outputGMvolumes"
mkdir -p ${oDir}

# * Reslice Shen Parcels
tDirP=${tDir}/Parcels
mkdir -p ${tDirP}

# Reference image
refImage=$(find ${iDir1} -iname "mwp1hiRes.nii" | head -1)
#refImage="/Applications/Matlab_Toolboxes/SPM_toolboxes/cat12_r1364/templates_1.50mm/Template_6_IXI555_MNI152.nii"

# Loop over cognitive domains
for cogDom in $(ls -p ${pDir} | grep \/ | sed 's/\///g'); do

    # Cognitive Domain Name
    cDom=$(basename ${cogDom})
    tDirPCD=${tDirP}/${cDom}
    mkdir -p ${tDirPCD}

    # Announce
    echo "$(tput setaf 1)${cDom}$(tput sgr0)"

    # Combine Slected Shen Parcels into a Single File
    first=yes
    for FILE in $(ls ${pDir}/${cDom}/tmp_3_selectedShenROIs/*.nii.gz); do
        
        # Basename
        F=$(basename ${FILE})

        # ROI value
        V=$(echo ${F} | cut -c 7-9)

        # Add value
        fslmaths \
            ${FILE} \
            -mul ${V} \
            ${tDirPCD}/Shen_${V}.nii.gz
        
        # If this is the first image, this will be the base image
        # for the sum of ROI images
        if [ ${first} = "yes" ]; then
            cp ${tDirPCD}/Shen_${V}.nii.gz ${tDirPCD}/Shen_${cDom}.nii.gz
            first="no"
            # ...else, add to the existing Shen_all image
        else
            fslmaths \
                ${tDirPCD}/Shen_${cDom}.nii.gz \
                -add ${tDirPCD}/Shen_${V}.nii.gz \
                ${tDirPCD}/Shen_tmp.nii.gz
            
            mv ${tDirPCD}/Shen_tmp.nii.gz ${tDirPCD}/Shen_${cDom}.nii.gz
        fi

    done

    # Reslice atlas
    mri_convert \
        ${tDirPCD}/Shen_${cDom}.nii.gz \
        -rl ${refImage} \
        -rt nearest \
        ${tDirPCD}/${cDom}_parcels_r.nii.gz
    
    # List parcel numbers
    pidV=$(
        ls ${pDir}/${cDom}/tmp_3_selectedShenROIs/*.nii.gz \
            | xargs basename \
            | sed 's/.nii.gz/_Voxels/g' \
            | tr "\n" "," \
            | sed -e 's/  *//g' -e 's/,$//g'
        )
    pidGM=$(echo "${pidV}" | sed 's/_Voxels/_meanGM/g')



    
    # GM Volume Output Text File
    oFile=${oDir}/${cDom}.csv
    echo "Study,Subject,${pidV},${pidGM}" > "${oFile}"
    
    # Mask out GM volume
    # Loop over studies
    for STUDY in ${iDir1} ${iDir2}; do

        # Study Name
        sName=$(basename $(dirname ${STUDY}))

        # Announce
        echo "$(tput setaf 2)${sName}$(tput sgr0)"

        # Loop over Subjects
        for SUB in $(ls -p ${STUDY} | grep \/ | sed 's/\///g'); do
            
            # Basename
            subject=$(basename ${SUB})

            # Mask out GM volume
            # Number of voxels per Shen Parcel
            # !! fslstats changed in fsl 6.0.3 from fsl 5, so I will use
            # explicitly use the version from fsl 5 as to not break things.
            ROIvol=$(/Applications/fsl/fsl_5.0.10/bin/fslstats \
                         -K ${tDirPCD}/${cDom}_parcels_r.nii.gz \
                         ${tDirPCD}/${cDom}_parcels_r.nii.gz \
                         -V \
                         | tr " " "\n" \
                         | awk '{if (NR % 2 == 1) print $0}' \
                         | sed 's/^0$//g' \
                         | tr "\n" "," \
                         | sed -e 's/,,*/,/g' -e 's/^,//g' -e 's/,$//g'
                  )

            # Mean GM value in Shen Parcel
            if [ -f ${STUDY}/${subject}/mri/mwp1hiRes.nii ]; then
                gmMean=$(/Applications/fsl/fsl_5.0.10/bin/fslstats \
                             -K ${tDirPCD}/${cDom}_parcels_r.nii.gz \
                             ${STUDY}/${subject}/mri/mwp1hiRes.nii \
                             -m 2>/dev/null \
                             | sed -e 's/0.000000//g' -e 's/  */,/g' -e 's/^,//g' -e 's/,$//g'
                      )
                
            else
                gmMean=NA
                
            fi
            
            # Add information to table
            echo "${subject}"
            echo "${sName},${subject},${ROIvol},${gmMean}" >> ${oFile}
            
        done

        echo "[done]"
        
    done
done        


exit


