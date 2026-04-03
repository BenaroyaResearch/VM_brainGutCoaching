# =============================================================================
# VMBGCC_functions.R
# Shared functions for VM Brain-Gut Coaching Class (BGCC) analysis pipeline
# =============================================================================

# function for saving plots as both pdf and png
savePlot <- function(
    plot,
    plotDir,
    filename,
    height,
    width,
    units = "in",
    dpi = 600,
    formats = c("pdf", "png")
    ) {
  # Ensure plotDir exists
  if (!dir.exists(plotDir)) dir.create(plotDir, recursive = TRUE)

  # Save as PDF
  if ("pdf" %in% formats) {
    pdf(file.path(plotDir, paste0(filenameSuffix, "_", filename, ".pdf")), height = height, width = width)
    on.exit(dev.off(), add = TRUE)
    print(plot)
    dev.off()
    on.exit(NULL)
  }

  # Save as PNG
  if ("png" %in% formats) {
    png(
      file.path(plotDir, paste0(filenameSuffix, "_", filename, ".png")),
      height = height,
      width = width,
      units = units,
      res = dpi
    )
    on.exit(dev.off(), add = TRUE)
    print(plot)
    dev.off()
    on.exit(NULL)
  }
}

# Convert "Unknown" / "Unkown" / "Uknown" / blank strings to NA, then to numeric
toNumericSafe <- function(x) {
  x <- trimws(as.character(x))
  x[tolower(x) %in% c("unknown", "unkown", "uknown", "")] <- NA
  suppressWarnings(as.numeric(x))
}

# Convert Excel serial date numbers to R Date objects
excelDateToR <- function(x) {
  x <- suppressWarnings(as.numeric(as.character(x)))
  openxlsx::convertToDate(x)
}

# IBS-SSS severity band classification (Francis et al.)
ibsSSSBand <- function(score) {
  cut(score,
    breaks = c(-Inf, 75, 175, 300, Inf),
    labels = c("Remission", "Mild", "Moderate", "Severe"),
    right = FALSE
  )
}

# GAD-7 severity band classification
gad7Band <- function(score) {
  cut(score,
    breaks = c(-Inf, 5, 10, 15, Inf),
    labels = c("Minimal", "Mild", "Moderate", "Severe"),
    right = FALSE
  )
}

# PHQ-2 screening classification (>= 3 is positive)
phq2Screen <- function(score) {
  ifelse(is.na(score), NA_character_,
    ifelse(score >= 3, "Positive", "Negative")
  )
}
