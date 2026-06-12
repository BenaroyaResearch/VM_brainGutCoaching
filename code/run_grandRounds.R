# Run VMBGCC_grandRounds.Rmd
# Generates slide-ready figures (16:9) for the 10-minute Grand Rounds talk.
# Usage: Rscript code/run_grandRounds.R
# Depends on: run_cleaning.R (produces clean RDS files)

baseDir <- "/Users/tedwards/Documents/projects/VM_brainGutCoaching"
setwd(baseDir)

dataOutputDir <- file.path(baseDir, "data/outputData")

# Locate the latest cleaned data (the input stamp may differ from today's date)
cleanFiles <- list.files(dataOutputDir, pattern = "^VMBGCC\\..*_bgccClean\\.rds$")
if (length(cleanFiles) == 0) {
  cat("Clean data not found — running cleaning first...\n")
  source("code/run_cleaning.R")
  cleanFiles <- list.files(dataOutputDir, pattern = "^VMBGCC\\..*_bgccClean\\.rds$")
}
inputStamp <- sub("_bgccClean\\.rds$", "", sort(cleanFiles, decreasing = TRUE)[1])

# Ensure thematic coding exists alongside the cleaned data
if (!file.exists(file.path(dataOutputDir, paste0(inputStamp, "_thematicCoding.rds")))) {
  cat("Thematic coding not found — running cleaning first...\n")
  source("code/run_cleaning.R")
}

# Sanity-check the quotes CSV exists
quotesFile <- file.path(baseDir, "code/grandRounds_quotes.csv")
if (!file.exists(quotesFile)) {
  stop("Missing code/grandRounds_quotes.csv — required for Slide 4 (Voices).")
}

cat("Running grand rounds figure pipeline...\n")
knitr::purl("code/VMBGCC_grandRounds.Rmd",
  output = "code/VMBGCC_grandRounds.R", quiet = TRUE)
source("code/VMBGCC_grandRounds.R")
cat("Done.\n")
