# Quick script to read and inspect all sheets from the BGCC data Excel file
library(openxlsx)

excelFile <- file.path(
  "/Users/tedwards/Documents/projects/VM_brainGutCoaching",
  "data/inputData/BGCC Data Sheet 031626.xlsx"
)

# List all sheet names
sheetNames <- getSheetNames(excelFile)
cat("=== SHEET NAMES ===\n")
cat(paste(seq_along(sheetNames), sheetNames, sep = ": "), sep = "\n")
cat("\n")

# Read each sheet and print structure + first rows
for (i in seq_along(sheetNames)) {
  cat(paste0("\n========== SHEET ", i, ": '", sheetNames[i], "' ==========\n"))
  
  df <- tryCatch(
    read.xlsx(excelFile, sheet = i, colNames = TRUE),
    error = function(e) {
      cat("  ERROR reading sheet:", conditionMessage(e), "\n")
      return(NULL)
    }
  )
  
  if (is.null(df)) next
  
  cat("Dimensions:", nrow(df), "rows x", ncol(df), "cols\n\n")
  
  cat("--- Column names and types ---\n")
  for (j in seq_along(colnames(df))) {
    col <- colnames(df)[j]
    colClass <- class(df[[j]])[1]
    nNA <- sum(is.na(df[[j]]))
    nUnique <- length(unique(df[[j]][!is.na(df[[j]])]))
    cat(sprintf("  [%2d] %-50s | type: %-10s | %d unique | %d NA\n", j, col, colClass, nUnique, nNA))
  }
  
  cat("\n--- First 8 rows (transposed for readability if wide) ---\n")
  if (ncol(df) > 8) {
    # Print each column's first values
    for (j in seq_along(colnames(df))) {
      vals <- head(df[[j]], 8)
      vals_str <- paste(ifelse(is.na(vals), "NA", as.character(vals)), collapse = " | ")
      cat(sprintf("  %-50s: %s\n", colnames(df)[j], vals_str))
    }
  } else {
    print(as.data.frame(head(df, 8)))
  }
  cat("\n")
}
