library(openxlsx)
ef <- "data/inputData/BGCC Data Sheet 031626.xlsx"

# Check exact row count
s1 <- read.xlsx(ef, sheet = 1, colNames = FALSE)
cat("Total rows raw:", nrow(s1), "\n")
cat("Row 1 col1:", as.character(s1[1, 1]), "\n")
cat("Row 2 col1:", as.character(s1[2, 1]), "\n")
cat("Row 3 col1:", as.character(s1[3, 1]), "\n")
cat("Last row col1:", as.character(s1[nrow(s1), 1]), "\n")

# Consensus Review debug
c4 <- read.xlsx(ef, sheet = 4, colNames = FALSE)
cat("\nConsensus rows:", nrow(c4), "\n")

# Row 1 = merged header, Row 2 = sub-headers, Row 3+ = data
# Check actual values in theme columns for data rows
cat("Row 3 cols 4-7:", paste(sapply(c4[3, 4:7], as.character), collapse = " | "), "\n")
cat("Row 4 cols 4-7:", paste(sapply(c4[4, 4:7], as.character), collapse = " | "), "\n")
cat("Row 5 cols 4-7:", paste(sapply(c4[5, 4:7], as.character), collapse = " | "), "\n")
cat("Row 6 cols 4-7:", paste(sapply(c4[6, 4:7], as.character), collapse = " | "), "\n")
cat("Row 7 cols 4-7:", paste(sapply(c4[7, 4:7], as.character), collapse = " | "), "\n")
cat("Row 8 cols 4-7:", paste(sapply(c4[8, 4:7], as.character), collapse = " | "), "\n")

# check class of the theme column values
cat("\nClass of col4 values:\n")
for (r in 3:10) {
  v <- c4[r, 4]
  cat(sprintf("  Row %d: class=%s value=[%s]\n", r, class(v), as.character(v)))
}

# Diagnosis matching issue - check trailing whitespace/comma
cat("\nUnmatched diagnoses (exact bytes):\n")
cat("  [Functional Dyspepsia, Gastroparesis] length:", nchar("Functional Dyspepsia, Gastroparesis"), "\n")
cat("  [Functional abdominal pain syndrome,] length:", nchar("Functional abdominal pain syndrome,"), "\n")

# Check Sheet 7 for these
d7 <- read.xlsx(ef, sheet = 7, colNames = FALSE)
cat("\nSheet7 searching for gastroparesis:\n")
for (r in 1:nrow(d7)) {
  v <- as.character(d7[r, 1])
  if (!is.na(v) && grepl("astro|abdom.*pain.*synd", v, ignore.case = TRUE)) {
    cat(sprintf("  Row %d: [%s]\n", r, v))
  }
}
