# Run VMBGCC_thematic.Rmd
# Usage: Rscript code/run_thematic.R
# Depends on: run_cleaning.R (produces clean RDS files)

baseDir <- "/Users/tedwards/Documents/projects/VM_brainGutCoaching"
setwd(baseDir)

# Ensure clean data exists — run cleaning if needed
dataDate <- "2026-03-19"
filenameSuffix <- paste0("VMBGCC.", dataDate)
dataOutputDir <- file.path(baseDir, "data/outputData")
if (!file.exists(file.path(dataOutputDir, paste0(filenameSuffix, "_bgccClean.rds")))) {
  cat("Clean data not found — running cleaning first...\n")
  source("code/run_cleaning.R")
}

knitr::purl("code/VMBGCC_thematic.Rmd", output = "code/VMBGCC_thematic.R", quiet = TRUE)
source("code/VMBGCC_thematic.R")
