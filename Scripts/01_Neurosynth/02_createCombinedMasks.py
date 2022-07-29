# * Create combined binary masks from neurosynth individual masks
# 2019-11-18

# * Libraries
from glob import glob
import os
from nipype.interfaces import fsl
from datetime import datetime

# * Environment
base = '/Users/vincent/Data/Documents/Utah/Kladblok/20181230_Langenecker/20190411_Kim_Langenecker_project/20191118_NeuroSynth/outputMasks'


# * For each domain, create a mask by combining all masks within that domain
# Define combinedMask
class combinedMask:
    # ** Attributes
    def __init__(self, base, domain):
        self.base = base
        self.domain = domain
        self.iDIR = self.base + '/01_neuroSynth/' + self.domain
        self.oDIR = self.base + '/02_binCombined/' + self.domain
        self.image = []
        self.maskList = []

        # Extract list of features from file names
        self.features = sorted(glob(self.iDIR + '/*'))
        self.features = [os.path.basename(i) for i in self.features]

    # * Create binarized mask for each feature
    def binarize(self):

        # Create Output folder
        os.makedirs(self.oDIR, exist_ok=True)

        # Binarize images
        for fNum in range(0, len(self.features)):

            # Define input file
            self.iFile = self.iDIR + '/' + self.features[fNum] + '/uniformity-test_z_FDR_0.01.nii.gz'
            self.oFile = self.oDIR + '/bin_' + self.features[fNum] + '.nii.gz'

            # The combined mask we eventually want to create needs to be able to show
            # overlap as well as uniquness of contribution of the individual masks. In
            # order to achieve this I will add different values to the initial masks,
            # which will assure unique values in the combined mask. E.g.
            # Mask 1 = voxel value 1
            # Mask 2 = voxel value 2
            # Mask 3 = voxel value 4
            # Mask 4 = voxel value 8
            # This way, if a voxel in the combined mask has value:
            # 1 , then it is unique for mask 1
            # 2 , then it is unique for mask 2
            # 3 , then it is combined mask 1 + 2, but not 3 or 4
            # 4 , then it is unique for mask 3
            # 5 , then it is combined mask 1 + 3, but not 2 or 4
            # 6 , then it is combined mask 2 + 4, but not 1 or 3
            # 7 , then it is combined mask 1 + 2 + 3, but not 4
            # 8 , then it is unique mask 4
            # 9 , then it is combined mask 1 + 4, but not 2 or 3
            # 10, then it is combined mask 2 + 4, but not 1 or 3
            # 11, then it is combined mask 1 + 2 + 4, but not 3
            # 12, then it is combined mask 3 + 4, but not 1 or 2
            # 13, then it is combined mask 1 + 3 + 4, but not 2
            # 14, then it is combined mask 2 + 3 + 4, but not 1
            # 15, then it is the combined mask for all masks
            if fNum == 0:
                self.voxMultiplier = 1
            elif fNum == 1:
                self.voxMultiplier = 2
            elif fNum == 2:
                self.voxMultiplier = 4
            elif fNum == 3:
                self.voxMultiplier = 8

            self.mul = '-mul ' + str(self.voxMultiplier)

            # Binarize
            self.image.append(
                fsl.ImageMaths(
                    in_file=self.iFile,
                    op_string='-thr 0 -bin ' + self.mul,
                    out_file=self.oFile,
                    output_type='NIFTI_GZ'
                )
            )
            self.image[fNum].run()

            # Add output file name to list for fsl_merge
            if fNum == 0:
                self.first = self.oFile
            elif fNum > 0:
                self.maskList.append('-add ' + self.oFile)

        # Combine all masks
        self.combMask = fsl.ImageMaths(
            in_file=self.first,
            op_string=" ".join(self.maskList),
            out_file=self.oDIR + '/combinedMask_' + self.domain + '.nii.gz',
            output_type='NIFTI_GZ'
        )
        self.combMask.run()

    # * Majority voting
    # Create the following masks:
    # 1) All voxels that appear in all masks
    # 2) All voxels that appear in the majority of masks (3/4 or 2/3)
    def majorVote(self):

        # This function is depending on the number of features.
        # There are either 3 or 4 features per domain. If there are
        # 3 features, the max score is 7 (1 + 2 + 4). If there are 4
        # features in the mask, the maximum score is 15 (1 + 2 + 4 + 8).
        if len(self.features) == 3:
            self.allScore = 7
        elif len(self.features) == 4:
            self.allScore = 15

        # Furthermore, if the the number of features is 3, the values
        # indicating majority are: 7 (all), 3 (1 + 2), 4 (1 + 3), and 5 (2 + 3).
        # If the number of features is 4, the values indicating majority are:
        # 15 (all), 7 (1 + 2 + 3), 11 (1 + 2 + 4), 13 (1 + 3 + 4), and 14 (2 + 3 + 4). Make
        # lists of these values for tresholding.
        if len(self.features) == 3:
            self.majList = [3, 4, 5]
        elif len(self.features) == 4:
            self.majList = [7, 11, 13, 14]

        # 1) All voxels that appear in all masks
        self.overlapAll = fsl.ImageMaths(
            in_file=self.oDIR + '/combinedMask_' + self.domain + '.nii.gz',
            op_string='-thr ' + str(self.allScore) + ' -bin',
            out_file=self.oDIR + '/combinedMask_overlapAll_' + self.domain + '.nii.gz',
            output_type='NIFTI_GZ'
        )
        self.overlapAll.run()

        # 2) All voxels that appear in the majority of masks (3/4 or 2/3)
        # Loop over list for thresholding
        self.tmpList = []

        for i in range(0, len(self.majList)):
            # Threshold
            self.tmpThresh = fsl.ImageMaths(
                in_file=self.oDIR + '/combinedMask_' + self.domain + '.nii.gz',
                op_string='-thr ' + str(self.majList[i]) + ' -uthr ' + str(self.majList[i]),
                out_file=self.oDIR + '/tmp_' + str(i) + self.domain + '.nii.gz',
                output_type='NIFTI_GZ'
            )
            self.tmpThresh.run()

            # Add image to list
            self.tmpList.append('-add ' + self.oDIR + '/tmp_' + str(i) + self.domain + '.nii.gz')

        # Now combine all these majority voted masks
        self.majMask = fsl.ImageMaths(
            in_file=self.oDIR + '/combinedMask_overlapAll_' + self.domain + '.nii.gz',
            op_string=" ".join(self.tmpList) + ' -bin',
            out_file=self.oDIR + '/combinedMask_majorityVoted_' + self.domain + '.nii.gz',
            output_type='NIFTI_GZ'
        )
        self.majMask.run()

    # * Clean up tmp files
    def remTmp(self):
        for file in self.tmpList:
            os.remove(file.replace('-add ', ''))

    # * Create display scripts
    def writeScripts(self):
        # Create shell script for opening three masks:
        self.outputMasks = []
        # - All combinations
        self.outputMasks.append('combinedMask_' + self.domain + '.nii.gz')
        # - Only voxels that overlap all
        self.outputMasks.append('combinedMask_overlapAll_' + self.domain + '.nii.gz')
        # - Only voxels that appear in at least the majority of masks
        self.outputMasks.append('combinedMask_majorityVoted_' + self.domain + '.nii.gz')

        # Write luts
        self.lutFilesLut = []
        self.lutFilesFile = []
        # - All combinations
        # This lut differes for domains with 3 and 4 feaures
        if len(self.features) == 3:
            self.lutFilesLut.append(f'''0 0 0 0 In no mask
1 .27343 .50781 .70312 Unique for {self.features[0]}
2 .85156 .89843 .29687 Unique for {self.features[1]}
3 .80078 .24218 .30468 Combined {self.features[0]} + {self.features[1]}
4 .46875 .07031 .52343 Unique for {self.features[2]}
5 .76562 .22656 .97656 Combined {self.features[0]} + {self.features[2]}
6 .00000 .57812 .00000 Combined {self.features[1]} + {self.features[2]}
7 .85937 .96875 .64062 All combined {self.features[0]} + {self.features[1]} + {self.features[2]}''')

        elif len(self.features) == 4:
            self.lutFilesLut.append(f'''0 0 0 0 In no mask
1 .27343 .50781 .70312 Unique for {self.features[0]}
2 .85156 .89843 .29687 Unique for {self.features[1]}
3 .80078 .24218 .30468 Combined {self.features[0]} + {self.features[1]}
4 .46875 .07031 .52343 Unique for {self.features[2]}
5 .76562 .22656 .97656 Combined {self.features[0]} + {self.features[2]}
6 .00000 .57812 .00000 Combined {self.features[1]} + {self.features[2]}
7 .85937 .96875 .64062 Combined {self.features[0]} + {self.features[1]} + {self.features[2]}
8 .89843 .57812 .13281 Unique for {self.features[3]}
9 .00000 .46093 .05468 Combined {self.features[0]} + {self.features[3]}
10 .92187 .05078 .49609 Combined {self.features[1]} + {self.features[3]}
11 .31250 .78125 .99609 Combined {self.features[0]} + {self.features[1]} + {self.features[3]}
12 .92187 .05078 .68750 Combined {self.features[2]} + {self.features[3]}
13 .04687 .18750 .99609 Combined {self.features[0]} + {self.features[2]} + {self.features[3]}
14 .79687 .71093 .55468 Combined {self.features[1]} + {self.features[2]} + {self.features[3]}
15 .16406 .79687 .64062 All combined {self.features[0]} + {self.features[1]} + {self.features[2]} + {self.features[3]} ''')

        self.lutFilesFile.append(self.base + '/02_binCombined/' + self.domain + '/all_masks.lut')
        f = open(self.lutFilesFile[0], 'w')
        f.write(self.lutFilesLut[0])
        f.close()

        # - Only voxels that appear in at least the majority of masks
        self.lutFilesLut.append(f'''0 0 0 0 Not in all of masks
1 1.0000 0.0000 0.0000 Voxels present in all masks''')
        self.lutFilesFile.append(self.base + '/02_binCombined/' + self.domain + '/overlap_all.lut')
        f = open(self.lutFilesFile[1], 'w')
        f.write(self.lutFilesLut[1])
        f.close()

        # - Only voxels that overlap all
        self.lutFilesLut.append(f'''0 0 0 0 Not in majoriy of masks
1 1.0000 1.0000 0.0000 Voxels present in the majority of masks''')
        self.lutFilesFile.append(self.base + '/02_binCombined/' + self.domain + '/majority.lut')
        f = open(self.lutFilesFile[2], 'w')
        f.write(self.lutFilesLut[2])
        f.close()

        # Create Script
        self.timeStamp = datetime.now()
        self.displayScript = f"""#!/bin/bash 
# Display Script for GrayMnMS Domain Masks
# Domain: {self.domain}

# Generated on: {self.timeStamp}
# Vincent Koppelmans

# Go to folder of this script for relative paths to work
cd "$( dirname "${{BASH_SOURCE[0]}}" )"

# Display
fsleyes \\
   -std1mm \\
   ./{self.domain}/{self.outputMasks[0]} -ot label -l ./{self.domain}/{os.path.basename(self.lutFilesFile[0])} -n All_Masks --outline -w 2 -d \\
   ./{self.domain}/{self.outputMasks[2]} -ot label -l ./{self.domain}/{os.path.basename(self.lutFilesFile[2])} -n Majority \\
   ./{self.domain}/{self.outputMasks[1]} -ot label -l ./{self.domain}/{os.path.basename(self.lutFilesFile[1])} -n Overlap_All

"""

        # Write out script
        self.displayScriptFile = self.base + '/02_binCombined/' + self.domain + '.command'
        f = open(self.displayScriptFile, 'w')
        f.write(self.displayScript)
        f.close()

        # Provide permission to execute
        os.chmod(self.displayScriptFile, 0o755)


# * Run
domains = glob(base + '/01_neuroSynth/*')
domains = [os.path.basename(i) for i in domains]

for domain in domains:
    masks = combinedMask(base, domain)
    masks.binarize()
    masks.majorVote()
    masks.remTmp()
    masks.writeScripts()
