# Run VMBGCC_poster.Rmd
# Usage: Rscript code/run_poster.R
# Depends on: run_cleaning.R (produces clean RDS files)

baseDir <- "/Users/tedwards/Documents/projects/VM_brainGutCoaching"
setwd(baseDir)

dataDate <- "2026-03-19"
filenameSuffix <- paste0("VMBGCC.", dataDate)
dataOutputDir <- file.path(baseDir, "data/outputData")

# Ensure clean data exists
if (!file.exists(file.path(dataOutputDir, paste0(filenameSuffix, "_bgccClean.rds")))) {
  cat("Clean data not found — running cleaning first...\n")
  source("code/run_cleaning.R")
}

# Ensure thematic coding exists
if (!file.exists(file.path(dataOutputDir, paste0(filenameSuffix, "_thematicCoding.rds")))) {
  cat("Thematic coding not found — running cleaning first...\n")
  source("code/run_cleaning.R")
}

cat("Running poster analysis...\n")
knitr::purl("code/VMBGCC_poster.Rmd", output = "code/VMBGCC_poster.R", quiet = TRUE)
source("code/VMBGCC_poster.R")
cat("Done.\n")
