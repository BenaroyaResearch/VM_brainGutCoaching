# Run VMBGCC_cleaning.Rmd
# Usage: Rscript code/run_cleaning.R

library(knitr)
setwd("/Users/tedwards/Documents/projects/VM_brainGutCoaching")
purl("code/VMBGCC_cleaning.Rmd", output = "code/.VMBGCC_cleaning_temp.R", documentation = 0)
source("code/.VMBGCC_cleaning_temp.R")
file.remove("code/.VMBGCC_cleaning_temp.R")
