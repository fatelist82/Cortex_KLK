## * Include scan and subject ID and calcualte GM volume
# 2020-02-14

## * Libraries
library('readxl')

## * Environment
base='/Users/vincent/Data/Documents/Utah/Kladblok/20181230_Langenecker/20190411_Kim_Langenecker_project/20200121_makeShenParcels'
iDIR = file.path(base,'outputGMvolumes')
oDIR = file.path(iDIR,'patched')
dir.create(oDIR, showWarnings = FALSE)
# ICV
icvDIR='/Users/vincent/Data/Documents/Utah/Kladblok/20181230_Langenecker/20181230_VBM_for_R01'
ICV1file=file.path(icvDIR,"ProcessedData","ICV.csv")
ICV2file=file.path(icvDIR,"ProcessedData_part2","ICV.csv")
# Voxel Volume (mm^3 per voxel)
voxVol = 1.5^3 

## * Load and merge ICV data
ICV1 = read.csv(ICV1file, header=TRUE, sep=',', stringsAsFactors=FALSE)
ICV2 = read.csv(ICV2file, header=TRUE, sep=',', stringsAsFactors=FALSE)
ICV=rbind(ICV1, ICV2)
names(ICV) = c("ScanID", "ICV")
# Only keep the scan ID of the subject
ICV$ScanID = gsub("[0-9]{4}_[0-9]{1}_", "", ICV$ScanID)


## * List all output files
files = Sys.glob(file.path(iDIR,'*.csv'))

## * Loop over input files
for (file in files) {

  # Load file
  data = read.csv(file, header=TRUE, sep=',', stringsAsFactors=FALSE)

  # Change study names
  data$Study = gsub("20181230_Langenecker_R01_part2", "MINDS", data$Study)
  data$Study = gsub("20181230_Langenecker_R01", "MNMS", data$Study)
  
  # Only keep the scan ID of the subject
  data$Subject = gsub("[0-9]{4}_[0-9]{1}_", "", data$Subject)

  # Remove line with the subject that has 'connect' in the scan name
  data = data[-grep("connect", data$Subject),]

  # Match ICV
  dataAll = merge(dataAll, ICV, by="ScanID", all.x = TRUE)

  # Create new data frame for output data
  dataNew = dataAll[,c("ScanID","SubjID","Time","FullLabel","Study")]
  
  # Build list of selected shen lobules
  ROIs = names(dataAll)[grep("Voxels", names(dataAll))]
  ROIs = as.data.frame(do.call(rbind, strsplit(ROIs, "_")))
  ROIs = as.character(as.array(ROIs$V2))

  # Loop over these ROIs to calculate GM volume
  for (ROI in ROIs) {

    # Variable Names
    voxels = paste("shen",ROI,"Voxels",sep="_")
    meanGM = paste("shen",ROI,"meanGM",sep="_")
    
    # Calculate GM volume per ROI in percent
    # / 1000 to convert volume of the ROI from mm3 to ml
    # ICV is already in ml
    # * 100 to make it a %
    dataNew[ROI] = (((dataAll[voxels] * dataAll[meanGM] * voxVol) / 1000) / dataAll$ICV) * 100

    # Save out data
    oFile = strsplit(file,"/")[[1]][12]
    oFile = paste(oDIR, '/', gsub(".csv", "_patched.csv", oFile), sep="")
    write.csv(dataNew, oFile, row.names=FALSE)
  }
  
}
