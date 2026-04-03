library(openxlsx)
ef <- "data/inputData/BGCC Data Sheet 031626.xlsx"

# Sheet1 exact row1 values (the real headers)
s1 <- read.xlsx(ef, sheet = 1, colNames = FALSE, rows = 1:3)
cat("=== SHEET 1 ROW 1 (HEADERS) ===\n")
for (j in 1:ncol(s1)) cat(sprintf("[%2d] %s\n", j, as.character(s1[1, j])))

cat("\n=== SHEET 1 ROW 2 (first data) ===\n")
for (j in 1:ncol(s1)) cat(sprintf("[%2d] %s\n", j, as.character(s1[2, j])))

# Stats sheet: check rows 184+ to find boundary
cat("\n=== STATS SHEET (Sheet 6) ROWS 184+ ===\n")
st <- read.xlsx(ef, sheet = 6, colNames = FALSE)
cat("Total rows:", nrow(st), "\n")
for (r in 184:min(nrow(st), 210)) {
  v1 <- as.character(st[r, 1])
  if (is.na(v1)) v1 <- "NA"
  v6 <- as.character(st[r, 6])
  if (is.na(v6)) v6 <- "NA"
  cat(sprintf("Row %d: col1=[%s] col6=[%s]\n", r, substr(v1, 1, 40), substr(v6, 1, 40)))
}

# Sheet 7 (diagnoses)
cat("\n=== SHEET 7 (DIAGNOSES) ===\n")
d7 <- read.xlsx(ef, sheet = 7, colNames = TRUE)
cat("Dims:", nrow(d7), "x", ncol(d7), "\n")
cat("Colnames:", paste(colnames(d7), collapse = " | "), "\n")
cat("Last 5 rows col1:\n")
for (r in (nrow(d7) - 4):nrow(d7)) {
  cat(sprintf("  Row %d: %s\n", r, as.character(d7[r, 1])))
}

# Consensus Review headers
cat("\n=== CONSENSUS REVIEW (Sheet 4) ROW 1 ===\n")
c4 <- read.xlsx(ef, sheet = 4, colNames = FALSE, rows = 1:4)
for (j in 1:ncol(c4)) cat(sprintf("[%2d] %s\n", j, as.character(c4[1, j])))

# Patient code summary
s1full <- read.xlsx(ef, sheet = 1, colNames = FALSE)
cat("\n=== PATIENT CODE SUMMARY ===\n")
codes <- as.character(s1full[2:nrow(s1full), 1])
cat("Total rows (excl header):", length(codes), "\n")
cat("Unique patient codes:", length(unique(codes)), "\n")
dups <- codes[duplicated(codes)]
if (length(dups) > 0) cat("Duplicated codes:", paste(unique(dups), collapse = ", "), "\n")

cat("\n=== SEX VALUES ===\n")
print(table(s1full[2:nrow(s1full), 5], useNA = "always"))

cat("\n=== CLASS DATES (unique) ===\n")
dates <- sort(unique(as.character(s1full[2:nrow(s1full), 2])))
cat(paste(dates, collapse = "\n"), "\n")

cat("\n=== PRE-CLASS PHQ-2 VALUES ===\n")
print(table(s1full[2:nrow(s1full), 11], useNA = "always"))

cat("\n=== PRE-CLASS GAD-7 VALUES ===\n")
print(table(s1full[2:nrow(s1full), 12], useNA = "always"))

cat("\n=== PRE-CLASS IBS-SSS VALUES ===\n")
print(table(s1full[2:nrow(s1full), 13], useNA = "always"))

cat("\n=== POST-CLASS IBS-SSS VALUES ===\n")
print(table(s1full[2:nrow(s1full), 14], useNA = "always"))

# Office visits pre/post
cat("\n=== PRE OFFICE VISITS ===\n")
print(table(s1full[2:nrow(s1full), 7], useNA = "always"))
cat("\n=== POST OFFICE VISITS ===\n")
print(table(s1full[2:nrow(s1full), 16], useNA = "always"))

cat("\n=== PRE ER VISITS ===\n")
print(table(s1full[2:nrow(s1full), 10], useNA = "always"))
