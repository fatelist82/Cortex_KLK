#!/usr/local/bin/Rscript

## * Make Parcel List Per Factor Per Cognitive Domain
# 2020-04-21


## * Test
test <- 0 # 0=No, 1=Yes
if (test == 0) {

  # Arguments
  args <- commandArgs(trailingOnly = TRUE)
  # Check for arguments
  if (length(args) != 2) {
    stop(paste("Exactly two arguments must be provided to this script: ",
               "i.e., a  file with factor loadings for a given cognitve ",
               "domain; a file with gray matter volumes for each subject ",
               "for a given cognitive domain", sep = ""),
               call. = FALSE)
  }

  # Assign arguments
  factor_file <- args[1]
  gm_file <- args[2]

} else if (test == 1) {

  ## ** Environment
  domain <- toString(1)
  base <- paste("/Users/vincent/Data/Documents/Utah/Kladblok",
              "/20181230_Langenecker/20190411_Kim_Langenecker_project",
              sep = "")
  # Input files: List of parcels per factor
  pdir <- paste(base, "/20200302_GM_Factors/20200203_GrabROIs/Output_Unique",
                sep = "")
  # Input files: Gray matter per parcel per subject
  idir <- paste(base, "/20200121_makeShenParcels_V2/outputGMvolumes/patched",
                sep = "")
  # Assign testing arguments
  factor_file <- Sys.glob(
    file.path(pdir, paste("Dim", domain, "*_N.csv", sep = "")))
  gm_file <- Sys.glob(file.path(idir, paste(domain, "*.csv", sep = "")))
}


## * Environment
base <- paste("/Users/vincent/Data/Documents/Utah/Kladblok",
              "/20181230_Langenecker/20190411_Kim_Langenecker_project",
              sep = "")
odir <- paste(base,
              "/20200302_GM_Factors/20200421_GMExtraction/output",
              sep = "")
dir.create(odir, showWarnings = FALSE)


## * Load data
factor_data <- read.table(factor_file, header = FALSE, sep = ",", fill = TRUE)
gm_data <- read.table(gm_file, header = TRUE, sep = ",")


## * Parcel Selection
# For each cognitive domain, there is a list of factors which consists
# of a list of unique Shen parcels. Now, select the parcels on a single
# line (a factor), add these up and store in a variable.

## ** Data Frame for Output Data
out_data <- gm_data[, 1:5]

## ** Loop over factors
for (factor in seq_len(nrow(factor_data))) {

  # Convert Shen parcel numbers to labels for subsetting
  # Subset factor
  parcels <- factor_data[factor, ]
  # Remove NA values
  parcels <- parcels[!is.na(parcels)]
  # Zero pad
  parcels <- sprintf("%03d", parcels)
  # Prepend "L"
  parcels <- paste("L", parcels, sep = "")

  # Now sum these columns
  # Subset the columns to their own dataframe
  tmp <- gm_data[, parcels]
  # Factor name
  f_name <- paste("F.", sprintf("%02d", factor), sep = "")
  # Sum columns and store into output data frame
  out_data[f_name] <- rowSums(tmp)

}


## * Write out output file
# ** Output file name
ofile <- strsplit(gm_file, "/")
ofile <- ofile[[1]][length(ofile[[1]])]
ofile <- gsub("_patched", "_GMperFactor", ofile)
ofile <- file.path(odir, ofile)

# ** Write output data
write.table(
    out_data,
    ofile,
    append = FALSE,
    quote = FALSE,
    col.names = TRUE,
    row.names = FALSE,
    sep = ","
)
