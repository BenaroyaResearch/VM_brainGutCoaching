# Run VMBGCC_figures.Rmd
# Usage: Rscript code/run_figures.R
# Depends on: run_cleaning.R, run_outcomes.R, run_thematic.R

baseDir <- "/Users/tedwards/Documents/projects/VM_brainGutCoaching"
setwd(baseDir)

# Ensure upstream outputs exist — run dependencies if needed
dataDate <- "2026-03-19"
filenameSuffix <- paste0("VMBGCC.", dataDate)
dataOutputDir <- file.path(baseDir, "data/outputData")

if (!file.exists(file.path(dataOutputDir, paste0(filenameSuffix, "_bgccClean.rds")))) {
  cat("Clean data not found — running cleaning first...\n")
  source("code/run_cleaning.R")
}
if (!file.exists(file.path(dataOutputDir, paste0(filenameSuffix, "_outcomeResults.rds")))) {
  cat("Outcome results not found — running outcomes first...\n")
  source("code/run_outcomes.R")
}
if (!file.exists(file.path(dataOutputDir, paste0(filenameSuffix, "_themeResults.rds")))) {
  cat("Theme results not found — running thematic first...\n")
  source("code/run_thematic.R")
}

knitr::purl("code/VMBGCC_figures.Rmd", output = "code/VMBGCC_figures.R", quiet = TRUE)
source("code/VMBGCC_figures.R")
