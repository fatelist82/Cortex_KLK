# * Create All Shen Parcel Nifit Images for each of the 7 NeuroSynth Masks
# 2020-01-21

# * V2:
# After discussion with Scott
# - reduce the % overlap to 20%
# - dilate the NeuroSynth Masks

# The next step is to extract the gray matter volumes from the gray matter maps using masks based on the NeuroSynth maps. For this, we will use the Shen atlas nodes that overlap with the voxels from the NeuroSynth masks. Together with Scott, we came up with the following rules:
# 1) For Shen parcels to be selected, the center of mass (COM) of the shen ROI has to be inside the NeuroSynth mask that it is overlapping.
# 2) The cluster size has to have a minimal size (number of voxels) of 100-150.
# 3) The cluster has to be for at least 50% in the parcel.
# 4) The cluster must at least be 10/20/30% of the parcel (sensitivity analysis to check which is best).
# 5) After the center of mass calculation, the overlap should be calculated by masking out the white matter voxels from the clusters and the parcels.

# * Libraries
import os
from glob import glob
import nibabel as nb
from nipype.interfaces import freesurfer
from nipype.interfaces import fsl
import numpy as np
from shutil import copy2

# * Environment
sFile='/Users/vincent/Data/Documents/Utah/Kladblok/20171002_Neuroimaging/20170629_Atlases/20200107_Shen_in_MNI152/output/shenToMNI152.nii.gz'
base='/Users/vincent/Data/Documents/Utah/Kladblok/20181230_Langenecker/20190411_Kim_Langenecker_project'
mDir=base+'/20191118_NeuroSynth/outputMasks/03_dilated'
oDir=base+'/20200121_makeShenParcels/outputParcels'

# * Create Parcel Objects
class parcels:
    def __init__(self):
        # Store output folder
        self.oDir = oDir
        os.makedirs(self.oDir, exist_ok=True)

    # Load Shen atlas data
    def loadShen(self, sFile):
        self.shen = nb.load(sFile)

    # List all masks
    def listMasks(self, mDir):
        # Empty object for output
        class Scratch(object):
            pass
        self.masks = Scratch()
        # Put information in object
        # - Paths
        self.masks.paths = glob(mDir+'/**/*majorityVoted*.nii.gz')
        # - Labels
        self.masks.labels={}
        for maskFile in self.masks.paths:
            label = "_".join(maskFile.split('/')[13].split('_')[2:5]).replace('.nii.gz','')
            self.masks.labels[label]=[maskFile]

    # Convert the Shen atlas to the Mask space
    def resliceShen(self):
        self.shenResliced={}
        for k,v in self.masks.labels.items():
            print(k)
            # # Output folder
            ooDir=oDir+'/'+k
            self.masks.labels[k].append(ooDir)
            os.makedirs(v[1], exist_ok=True)
            # Create reslicing object
            self.shenResliced[k] = freesurfer.MRIConvert()
            self.shenResliced[k].inputs.in_file=sFile
            self.shenResliced[k].inputs.out_file=v[1]+'/'+k+'rShen.nii.gz'
            self.shenResliced[k].inputs.reslice_like=v[0]
            # Reslice Shen atlas        
            results = self.shenResliced[k].run()
            self.masks.labels[k].append(results)


    ## * CRITERIUM 1:
    # - COM of Shen is in NeuroSynth mask
    # - Shen is at least 20% filled by NeuroSynth mask
    # - This only applies to GM
    # (last part is redundant, because Shen only covers GM)
            
    # Test for each Shen lobule if it is part of the
    # mask that I extracted from NeuroSynth according to
    # the rules we defined above.
    # This needs to be done for each of our 7 cognitive domains.
    def grabShenLobulesPart1(self):
        # Create dictionary to store output per domain
        self.lobuleTest={}
        # Create dictionary to store NeuroSynth masks
        self.NSmasks={}
        
        # Loop over cognitive domains:
        for k in self.masks.labels.keys():

            # Load NeuroSynth mask into Numpy Array.
            self.NSmasks[k] = nb.load(self.masks.labels[k][0])

            # Create dictionary to store output per domain
            self.lobuleTest[k]={}

            # Loop over all 268 Shen Lobules
            for SL in range(1,269):

                # * Extract the lobule for processing
                # Inout and Output Files and Folders
                iFile=self.masks.labels[k][1]+'/'+k+'rShen.nii.gz'
                oDir1=self.masks.labels[k][1]+'/tmp_1_shenROIs'
                os.makedirs(oDir1, exist_ok=True)
                oFile=oDir1+'/shen_L'+str(SL).zfill(3)+'.nii.gz'
                # Commands for FSLmaths
                fslmathsCmd='-thr '+str(SL)+' -uthr '+str(SL)+' -bin'
                # Create FSLmaths object
                self.lobuleTest[k][SL] = [
                    fsl.ImageMaths(
                        in_file = iFile,
                        op_string = fslmathsCmd,
                        out_file = oFile
                    )
                ]
                # Run FSLmaths
                self.lobuleTest[k][SL][0].run()

                # * Mask NeuroSynth Atlas
                # Mask the NeurSynth Majority Voted Mask
                # using the Shen lobule.
                iFile=self.masks.labels[k][0]
                # Output folder and file
                oDir2=self.masks.labels[k][1]+'/tmp_2_NSshenMasked'
                os.makedirs(oDir2, exist_ok=True)
                oFile=oDir2+'/NSshenMasked_L'+str(SL).zfill(3)+'.nii.gz'
                # Lobule that will be the mask
                shenLobule=oDir1+'/shen_L'+str(SL).zfill(3)+'.nii.gz'
                # Command for FSLmaths
                fslmathsCmd='-mas '+shenLobule
                # Create FSLmaths object
                self.lobuleTest[k][SL].append(
                    fsl.ImageMaths(
                        in_file = iFile,
                        op_string = fslmathsCmd,
                        out_file = oFile
                    )
                )
                # Run FSLmaths
                self.lobuleTest[k][SL][1].run()
                
                # * Test if the COM is inside the cluster
                # Test if the center of mass of the Shen atlas
                # is actually within the NeurSytnh mask. So, the
                # coordinate of the COM of the Shen ROI has to
                # be a '1' (and not a '0') when tested for the
                # NeurSynth mask.
                # ** Get COM for the Shen ROI

                # Command for FSL stats
                self.lobuleTest[k][SL].append(
                    fsl.ImageStats(
                        in_file = shenLobule,
                        op_string = '-C'
                    )
                )
                # Run FSLstats
                self.lobuleTest[k][SL].append(
                    self.lobuleTest[k][SL][2].run()
                )
                # FSLstats returns decimals for the voxel coordinates
                # Round to integers so we can test if the voxel under
                # the coordinate is filled or not.
                self.lobuleTest[k][SL].append(
                    [round(i) for i in self.lobuleTest[k][SL][3].outputs.out_stat]
                )
                
                # ** Test if the COM coordinate is in the Neurosynth mask.
                # If the value of the coordinate in the NeuroSynth image
                # is 1, the COM of the Shen ROI is in the NeuroSynth mask.
                # If it is zero, the COM of the Shen ROI is not in the
                # NeuroSynth mask. Being in the NeuroSynth mask is a
                # prerequisit.
                # Store voxelvalue in variable
                voxelValue =  self.NSmasks[k].get_data()[
                    self.lobuleTest[k][SL][4][0],
                    self.lobuleTest[k][SL][4][1],
                    self.lobuleTest[k][SL][4][2]
                ]
                # Store voxelvalue
                self.lobuleTest[k][SL].append(
                    voxelValue
                )

                # * Test the overlap between Shen ROI and NeurSynth mask
                # For this, first, store:
                # - The size (number of voxels) of the Shen ROI
                # - The number of voxels in the Shen ROI that
                #   are filled by the NeuroSynth mask.
                
                # 1) Shen ROI size
                shenROIimage = nb.load(shenLobule)
                self.lobuleTest[k][SL].append(
                    sum(shenROIimage.get_data().flatten())
                )
                
                # 2) Number of NeuroSynth voxels in Shen ROI
                # Here, I load the 3d matrices and flatten them
                # to 1D arrays, then I calculate the dot product
                # which then results in the sum of voxels that
                # is the sum of voxels that are 1 in both the
                # Shen ROI and the NeuroSynth mask.
                neurSynthMasked=np.dot(
                    self.NSmasks[k].get_data().flatten(),
                    shenROIimage.get_data().flatten()
                )
                self.lobuleTest[k][SL].append( neurSynthMasked )

                # 3) Calculate the % overlap
                self.lobuleTest[k][SL].append(
                    neurSynthMasked /  self.lobuleTest[k][SL][6]
                )

                # * Select Shen ROIs
                # Select those ROIs with COM in the NeuroSynth, and
                # also the Shen ROI has to be filled for at least 20%
                # by the NeuroSynth mask.
                if voxelValue == 1 and neurSynthMasked >= 0.2:

                    # Create Output Folder
                    oDir3=self.masks.labels[k][1]+'/tmp_3_selectedShenROIs'
                    os.makedirs(oDir3, exist_ok=True)

                    # Copy over Shen ROI masks
                    copy2(shenLobule, oDir3)

                    
    ## * CRITERIUM 2:
    # - NeuroSynth mask is for at least 50% in a single Shen ROI
    # - The number of voxels of the NeuroSynth in Shen ROI is
    #   at least 100 voxels.
    # (obviosuly, this does not apply to very large NeuroSynth
    # masks, because they will be too large to fit at least
    # for half part inside a singel Shen ROI).
    def grabShenLobulesPart2(self):
        # Create dictionary to store output per domain
        self.lobuleTest2={}
        # Create dictionary to store NeuroSynth masks
        self.NSmasks2={}
        
        # Loop over cognitive domains:
        for k in self.masks.labels.keys():
            
            # Split NeuroSynth Masks into Individual Clusters
            # Output folder
            oDir1=self.masks.labels[k][1]+'/tmp_4_NSclusters'
            os.makedirs(oDir1, exist_ok=True)
            # Split up cluster into independent clusters with
            # a minimal clsuter size of 100
            self.lobuleTest2[k]=[
                fsl.Cluster(
                    threshold=0.1,
                    in_file=self.masks.labels[k][0],
                    out_size_file=oDir1+'/clusters_'+k+'.nii.gz',
                )
            ]
            self.lobuleTest2[k][0].inputs.out_localmax_txt_file = oDir1+'/clusters_'+k+'.txt'
            # Run fsl cluster
            # self.lobuleTest2[k].append(
            #     self.lobuleTest2[k][0].run()
            # )
            

# * Run code
def runMe():
    myParcels = parcels()
    myParcels.loadShen(sFile)
    myParcels.listMasks(mDir)
    myParcels.resliceShen()
    myParcels.grabShenLobulesPart1()
    myParcels.grabShenLobulesPart2()
    
runMe()
