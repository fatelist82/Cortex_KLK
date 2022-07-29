#!/usr/local/bin/Rscript

## * Grab ROIs per Clsuter
## 2020-11-29
## Read in gray matter factor analysis data (for each cognitive domain) that
## Joe created. Per cognitive domain, test for each factor which Shen ROI's load
## highest on that factor. Per factor, select those ROIs and grab their BA
## labels. For each cognitive domain, write out two matrices (same shape): 1)
## with all the BA numbers (factors in the rows, ROI numbers in the columns); 2)
## with all the anatomical labels (factors in the rows, labels in the collumns).

## * Test
test <- 0 # 0=No, 1=Yes
if (test == 0) {

  ## Arguments
  args <- commandArgs(trailingOnly = TRUE)
  ## Check for arguments
  if (length(args) != 1) {
    stop(paste("Exactly one argument must be provided to this script:",
               "i.e., a  file with factor loadings"),
         call. = FALSE)
  }

  ## Assign arguments
  factorFile <- args[1]

} else if (test == 1) {

  ## Assign arguments
  factorFile <- file.path(
    "/Users/vincent/Data/Documents/Utah/Kladblok",
    "20181230_Langenecker/20190411_Kim_Langenecker_project",
    "20200302_GM_Factors/20200203_FromJoe/20201023_All",
    "Dim1_7factors_EmotionalMemory.csv"
  )
}

print(paste("FactorFile:", factorFile, sep = ""))


## * Environment
oDir <- file.path(
  "/Users/vincent/Data/Documents/Utah/Kladblok/20181230_Langenecker",
  "20190411_Kim_Langenecker_project/20200302_GM_Factors/20200203_GrabROIs",
  "/Output_Unique"
)
dir.create(oDir, showWarnings = FALSE)
## ** Output file
oFile <- strsplit(factorFile, "/")[[1]] [length(strsplit(factorFile, "/")[[1]])]
oFile <- file.path(oDir, oFile)
oFileL <- gsub(".csv", "_L.csv", oFile) # Labels
oFileN <- gsub(".csv", "_N.csv", oFile) # Numbers (for nii extracting)
## Clean files (because we are appending data)
if (file.exists(oFileL)) {
    file.remove(oFileL)
}
if (file.exists(oFileN)) {
    file.remove(oFileN)
}
## ** Labels
lDir <- file.path(
  "/Users/vincent/Data/Documents/Utah/Kladblok/20171002_Neuroimaging",
  "20170629_Atlases/20191209_ShenAtlas/labels_shen_268"
)
## Shen Atlas Labels
sFile <- file.path(lDir, "shen_268_BAindexing.csv")
## Brodmann Labels
bFile <- file.path(lDir, "BA_labels.csv")


## * Read in Shen Atlas Data and Organize the Labels
## ** Read Shen Atlas
sData <- read.table(sFile, sep = ",", skip = 1)
names(sData) <- c(
    "ShenROI", "BA", "X", "Y", "Z",
    "Talairach_X", "Talairach_Y", "Talairach_Z"
)
sData <- sData[order(sData$ShenROI), ]

## ** Read Brodmann Labels
bData <- read.table(bFile, sep = ",", skip = 3, fill = TRUE)
names(bData) <- c("Area", "Label", "Info")

## ** Comibine areas and labels
## Convert BA areas to numbers
sData$BAnum <- sData$BA
sData$BAnum <- as.numeric(
  gsub("[R,L]\\.BA|\\.[0-9]*$", "", sData$BA)
)

## ** Add labels from Brodmann File
lData <- merge(
  sData,
  bData,
  by.x = "BAnum",
  by.y = "Area",
  all.x = TRUE
)
lData <- lData[order(lData$ShenROI), ]


## * Read GM Factor Score Data from Joe
## ** Read data
data <- read.table(
  file = factorFile,
  header = TRUE,
  sep = ",",
  row.names = NULL,
  stringsAsFactors = FALSE
)
names(data)[names(data) == "X..."] <- "ShenROI"
names(data)[names(data) == "X"] <- "ShenROI"

## ** NOTE: Order of Factor Numbers in the Columns
## Factor numbers are _not_ consecutive in the data that Joe gave me (e.g., the
## columns can follow undordered patterns like, "Factor 1", "Factor 4", "Factor
## 7", "Factor 2", etc.). However, This is because the software that Joe uses
## does not order the factors according to the explained variance. Joe ordered
## the columns such that the first column is the highest explained variance, the
## second has the second most explained variance, etc.

## We _don't_ want to reorder the columns because we want to keep the order of
## the data such that the first factor is the one explaining the most variance
## the second explaining the second most, etc. This script writes out a matrix
## with with Shen ROIs by factor that will be used to plot the combined Shen
## clusters. The plotting assigns a color to each cluster that is based on the
## the row number (first row gets 1, second row gets 2). We want the cluster
## one to always have the same color over cognitive domains, so that it is easy
## to see which combined-clusters explain the most variance. Thus, we will _not_
## reorder the columns.

## ** Order rows according to Shen ROI number
dataCensored <- data # Unordered backup for later
data <- data[order(data$ShenROI), ]

## ** Maximum positive factor loading per row
## Note that there are some negative loadings that
## are absolutely higher than the positive loadings.
## This happens very infrequently, but does happen
## (e.g., Cognitive domain 6, Shen Parcel L038)
data$maxFact <- apply(
  data[, grep("Factor.", names(data))],
  1,
  function(x) max(x)
)


## * Create List of ROIs per Factor
## Function for extraction
grabROIs <- function(
                     listOfFactorScores,
                     listOfMaxScores
                     ) {

  ## Rows with scores that match the max score
  ## If the difference with the max score is zero,
  ## then this row is the max score, hence, the
  ## Shen parcel on this row should be assigned to
  ## for this factor.
  diff <- listOfFactorScores - listOfMaxScores
  diff[diff != 0] <- NA
  diff[diff == 0] <- 1
  diff[is.na(diff)] <- 0
  rownumbers <- seq_len(length(diff))
  rowSelectIndex <- rownumbers * diff

  ## Now select these rows from the list of Shen parcels
  tmp <- data$ShenROI[as.numeric(rowSelectIndex)]

  ## Convert to single numbers with commas for csv file
  tmp <- gsub("L[0]*", "", tmp)
  tmpL <- tmp # For labels later
  tmp <- paste(tmp, collapse = ",")
  print(tmp)

  ## Append information to output file
  write.table(
    tmp,
    oFileN,
    append = TRUE,
    quote = FALSE,
    col.names = FALSE,
    row.names = FALSE
  )

  ## Grab labels
  myLabels <- merge(
    as.data.frame(as.numeric(tmpL)),
    lData,
    by.x = "as.numeric(tmpL)",
    by.y = "ShenROI"
  )
  ## Select only the labels
  myLabels <- as.vector(myLabels$Label)

  ## Convert to single string with commas for csv file
  myLabels <- paste(myLabels, collapse = ",")
  print(myLabels)

  ## Append information to output file
  write.table(
    myLabels,
    oFileL,
    append = TRUE,
    quote = FALSE,
    col.names = FALSE,
    row.names = FALSE
  )
}


## * Check if ROIs are Unique per Factor
## for (col in 2:ncol(data)) {
##   dataCensored[col][data[col] < fThresh] <- 0
## }


## * Extract Data
## Labels
## Loop over columns in data file
factCols <- names(data[grep("\\.", names(data))])
factCols <- factCols[grep("Factor", factCols)]
for (factCol in factCols) {
  print(factCol)
  grabROIs(
    data[[factCol]],
    data$maxFact
  )
}
