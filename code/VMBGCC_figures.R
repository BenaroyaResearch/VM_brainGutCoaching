## ----setup, echo=FALSE, message=FALSE, warning=FALSE--------------------------
library(knitr)
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(scales)
library(patchwork)
library(ggalluvial)
library(UpSetR)
library(gtsummary)

opts_chunk$set(
  fig.width = 6, fig.height = 4, cache = FALSE,
  echo = FALSE, warning = FALSE, message = FALSE,
  results = "markup"
)

options(stringsAsFactors = FALSE)

baseDir <- "/Users/tedwards/Documents/projects/VM_brainGutCoaching"
setwd(baseDir)

dataOutputDir <- file.path(baseDir, "data/outputData")
plotDir <- file.path(baseDir, "figures")
dataDate <- "2026-03-19"
filenameSuffix <- paste0("VMBGCC.", dataDate)

source(file.path(baseDir, "code/VMBGCC_functions.R"))

bgcc.df <- readRDS(file.path(dataOutputDir, paste0(filenameSuffix, "_bgccClean.rds")))
thematic.df <- readRDS(file.path(dataOutputDir, paste0(filenameSuffix, "_thematicCoding.rds")))
outcomeResults <- readRDS(file.path(dataOutputDir, paste0(filenameSuffix, "_outcomeResults.rds")))

cat("Loaded data and results.\n")


## ----table1Manuscript---------------------------------------------------------
diagCols <- c(
  "IBS_C", "IBS_D", "IBS_M",
  "chronicIdiopathicConstipation", "functionalConstipation",
  "functionalDiarrhea", "cmAbdominalPainSyndrome",
  "functionalAbdominalPain", "functionalDyspepsia",
  "functionalBloating", "cyclicVomiting",
  "ruminationSyndrome", "idiopathicGastroparesis",
  "opioidInducedConstipation", "cannabinoidHyperemesis",
  "functionalHeartburn", "functionalNeurologicSyndrome"
)

diagLabels <- c(
  IBS_C = "IBS-C", IBS_D = "IBS-D", IBS_M = "IBS-M",
  chronicIdiopathicConstipation = "Chronic Idiopathic Constipation",
  functionalConstipation = "Functional Constipation",
  functionalDiarrhea = "Functional Diarrhea",
  cmAbdominalPainSyndrome = "CM Abdominal Pain Syndrome",
  functionalAbdominalPain = "Functional Abdominal Pain",
  functionalDyspepsia = "Functional Dyspepsia",
  functionalBloating = "Functional Bloating",
  cyclicVomiting = "Cyclic Vomiting",
  ruminationSyndrome = "Rumination Syndrome",
  idiopathicGastroparesis = "Idiopathic Gastroparesis",
  opioidInducedConstipation = "Opioid-Induced Constipation",
  cannabinoidHyperemesis = "Cannabinoid Hyperemesis",
  functionalHeartburn = "Functional Heartburn",
  functionalNeurologicSyndrome = "Functional Neurologic Syndrome"
)

# Create formatted diagnosis indicator columns
tbl1Data <- bgcc.df %>%
  mutate(
    Sex = sex,
    Age = age,
    `No. Diagnoses` = factor(nDiagnoses),
    `Pre-class IBS-SSS` = preIBSSSS,
    `Pre-class IBS-SSS Severity` = preIBSSSSBand,
    `Pre-class PHQ-2` = prePHQ2,
    `Pre-class PHQ-2 Screen` = factor(prePHQ2Screen,
      levels = c("Negative", "Positive")),
    `Pre-class GAD-7` = preGAD7,
    `Pre-class GAD-7 Severity` = preGAD7Band,
    `Pre-class Office Visits` = preOfficeVisits,
    `Pre-class Portal Messages` = prePortalMessages,
    `Pre-class ER Visits` = preERVisits,
    `Survey Respondent` = respondedToSurvey
  )

# Add diagnosis indicators with nice names
for (d in diagCols) {
  tbl1Data[[diagLabels[d]]] <- factor(
    ifelse(bgcc.df[[d]] == 1, "Yes", "No"),
    levels = c("No", "Yes")
  )
}

tbl1Vars <- c("Sex", "Age", "No. Diagnoses",
  "Pre-class IBS-SSS", "Pre-class IBS-SSS Severity",
  "Pre-class PHQ-2", "Pre-class PHQ-2 Screen",
  "Pre-class GAD-7", "Pre-class GAD-7 Severity",
  "Pre-class Office Visits", "Pre-class Portal Messages", "Pre-class ER Visits",
  "Survey Respondent")

tbl1 <- tbl1Data %>%
  select(all_of(tbl1Vars)) %>%
  tbl_summary(
    statistic = list(
      all_continuous() ~ "{mean} ({sd}); med {median} [{min}, {max}]",
      all_categorical() ~ "{n} ({p}%)"
    ),
    missing = "ifany",
    missing_text = "Missing"
  ) %>%
  bold_labels()

tbl1


## ----flowDiagram--------------------------------------------------------------
cat("=== Study Flow ===\n\n")

nTotal <- nrow(bgcc.df)
nSurvey <- sum(bgcc.df$respondedToSurvey)
nPairedIBS <- sum(!is.na(bgcc.df$preIBSSSS) & !is.na(bgcc.df$postIBSSSS))
nPairedPHQ <- sum(!is.na(bgcc.df$prePHQ2) & !is.na(bgcc.df$postPHQ2))
nPairedGAD <- sum(!is.na(bgcc.df$preGAD7) & !is.na(bgcc.df$postGAD7))
nThematic <- {
  themeCols <- grep("^theme|^sub", names(thematic.df), value = TRUE)
  themeNums <- sapply(thematic.df[, themeCols], as.numeric)
  sum(rowSums(themeNums, na.rm = TRUE) > 0)
}

cat(sprintf("Enrolled in BGCC: %d patients\n", nTotal))
cat(sprintf("  ├─ Completed survey: %d (%.1f%%)\n", nSurvey, 100 * nSurvey / nTotal))
cat(sprintf("  │  └─ With thematic coding: %d\n", nThematic))
cat(sprintf("  ├─ Paired IBS-SSS: %d (%.1f%%)\n", nPairedIBS, 100 * nPairedIBS / nTotal))
cat(sprintf("  ├─ Paired PHQ-2: %d (%.1f%%)\n", nPairedPHQ, 100 * nPairedPHQ / nTotal))
cat(sprintf("  └─ Paired GAD-7: %d (%.1f%%)\n", nPairedGAD, 100 * nPairedGAD / nTotal))


## ----figure2, fig.width=12, fig.height=5--------------------------------------
# Paired spaghetti + summary for IBS-SSS, PHQ-2, GAD-7

makePrePostPlot <- function(df, preCol, postCol, scoreName, ylab, thresholds = NULL,
                            threshLabels = NULL, threshColors = NULL) {
  paired <- df %>%
    filter(!is.na(!!sym(preCol)) & !is.na(!!sym(postCol)))
  nPaired <- nrow(paired)

  long <- paired %>%
    select(patientCode, !!sym(preCol), !!sym(postCol)) %>%
    pivot_longer(cols = c(!!sym(preCol), !!sym(postCol)),
      names_to = "timepoint", values_to = "score") %>%
    mutate(
      timepoint = ifelse(grepl("^pre", timepoint), "Pre", "Post"),
      timepoint = factor(timepoint, levels = c("Pre", "Post"))
    )

  pval <- wilcox.test(paired[[preCol]], paired[[postCol]], paired = TRUE)$p.value
  pLabel <- ifelse(pval < 0.001, sprintf("Wilcoxon p < 0.001"),
    sprintf("Wilcoxon p = %.3f", pval))

  p <- ggplot(long, aes(x = timepoint, y = score)) +
    geom_line(aes(group = patientCode), alpha = 0.2, color = "grey50") +
    geom_point(aes(group = patientCode), alpha = 0.2, size = 0.8) +
    geom_violin(aes(fill = timepoint), alpha = 0.2, width = 0.5) +
    geom_boxplot(width = 0.1, outlier.shape = NA, fill = NA) +
    stat_summary(aes(group = 1), fun = mean, geom = "line",
      color = "firebrick", linewidth = 1.5) +
    stat_summary(aes(group = 1), fun = mean, geom = "point",
      color = "firebrick", size = 3) +
    scale_fill_manual(values = c(Pre = "steelblue", Post = "coral")) +
    labs(x = NULL, y = ylab,
      title = sprintf("%s (n=%d paired)", scoreName, nPaired),
      subtitle = pLabel) +
    theme_minimal() +
    theme(legend.position = "none")

  if (!is.null(thresholds)) {
    for (i in seq_along(thresholds)) {
      p <- p + geom_hline(yintercept = thresholds[i], linetype = "dashed",
        color = threshColors[i], alpha = 0.5)
    }
  }

  p
}

pIBS <- makePrePostPlot(bgcc.df, "preIBSSSS", "postIBSSSS", "IBS-SSS", "Score",
  thresholds = c(75, 175, 300),
  threshColors = c("green4", "goldenrod", "firebrick"))

pPHQ <- makePrePostPlot(bgcc.df, "prePHQ2", "postPHQ2", "PHQ-2", "Score",
  thresholds = 3, threshColors = "firebrick")

pGAD <- makePrePostPlot(bgcc.df, "preGAD7", "postGAD7", "GAD-7", "Score",
  thresholds = c(5, 10, 15),
  threshColors = c("goldenrod", "orange", "firebrick"))

fig2 <- pIBS + pPHQ + pGAD + plot_layout(ncol = 3)
print(fig2)
savePlot(fig2, plotDir, "fig2_prePostScores",
  height = 5, width = 12)


## ----figure3, fig.width=8, fig.height=6---------------------------------------
ibsPaired <- bgcc.df %>%
  filter(!is.na(preIBSSSSBand) & !is.na(postIBSSSSBand))

alluvialData <- ibsPaired %>%
  count(preIBSSSSBand, postIBSSSSBand) %>%
  rename(Pre = preIBSSSSBand, Post = postIBSSSSBand, Freq = n)

severityColors <- c(
  "Remission" = "#2ca02c", "Mild" = "#98df8a",
  "Moderate" = "#ffbb78", "Severe" = "#d62728"
)

fig3 <- ggplot(alluvialData,
  aes(axis1 = Pre, axis2 = Post, y = Freq)) +
  geom_alluvium(aes(fill = Pre), width = 1 / 3, alpha = 0.7) +
  geom_stratum(width = 1 / 3, fill = "grey90", color = "grey50") +
  geom_text(stat = "stratum", aes(label = after_stat(stratum)), size = 3) +
  scale_x_discrete(limits = c("Pre-class", "Post-class"),
    expand = c(0.15, 0.05)) +
  scale_fill_manual(values = severityColors, name = "Pre-class\nSeverity") +
  labs(y = "Number of Patients",
    title = sprintf("IBS-SSS Severity Transitions (n=%d)", nrow(ibsPaired))) +
  theme_minimal() +
  theme(legend.position = "right")

print(fig3)
savePlot(fig3, plotDir, "fig3_ibsAlluvial",
  height = 6, width = 8)


## ----figure4, fig.width=9, fig.height=6---------------------------------------
# Theme prevalence bar chart (among survey respondents)
themeRespondents <- thematic.df %>%
  filter(!is.na(surveyLiked) & tolower(surveyLiked) != "did not respond")
nResp <- nrow(themeRespondents)

mainThemes <- c("themePositiveSharedExperience", "themePatientEmpowerment",
  "themePatientActivation")
subThemes <- c("subIsolationReduced", "subValidation", "subSharedCommunity",
  "subChangeNegHealthcare", "subGratitude", "subEnjoymentPositive",
  "subContent", "subTeachingCoachingStyle", "subCoachingStructure",
  "subSelfEfficacy", "subAgencyKnowledgeSkills", "subAgencyActionableTools")
allThemes <- c(mainThemes, subThemes)

themeLabels <- c(
  themePositiveSharedExperience = "Positive Community Atmosphere",
  themePatientEmpowerment       = "Collaborative Engaging Educational Environment",
  themePatientActivation        = "Equipping Patients with Hope and Actionable Tools",
  subIsolationReduced       = "Isolation Reduced",
  subValidation             = "Validation",
  subSharedCommunity        = "Shared Community",
  subChangeNegHealthcare    = "Change from Negative Healthcare Experiences",
  subGratitude              = "Gratitude",
  subEnjoymentPositive      = "Positive Experience",
  subContent                = "Presentation Content",
  subTeachingCoachingStyle  = "Presenter Teaching/Coaching Style",
  subCoachingStructure      = "Virtual Coaching Class Format",
  subSelfEfficacy           = "Patient Self-Efficacy",
  subAgencyKnowledgeSkills  = "Patient Agency (Knowledge, Skills)",
  subAgencyActionableTools  = "Patient Agency (Actionable Tools)"
)

themeData <- data.frame(
  theme = allThemes,
  label = themeLabels[allThemes],
  n = sapply(allThemes, function(t) sum(themeRespondents[[t]] == 1)),
  stringsAsFactors = FALSE
) %>%
  mutate(
    pct = 100 * n / nResp,
    type = ifelse(theme %in% mainThemes, "Main Theme", "Sub-Theme")
  )

# Add CIs
for (i in 1:nrow(themeData)) {
  ci <- prop.test(themeData$n[i], nResp, correct = FALSE)$conf.int
  themeData$ciLow[i] <- 100 * ci[1]
  themeData$ciHigh[i] <- 100 * ci[2]
}

themeData <- themeData %>% arrange(pct)
themeData$label <- factor(themeData$label, levels = themeData$label)

fig4 <- ggplot(themeData, aes(x = label, y = pct, fill = type)) +
  geom_col(width = 0.7) +
  geom_errorbar(aes(ymin = ciLow, ymax = ciHigh), width = 0.2) +
  coord_flip() +
  scale_fill_manual(values = c("Main Theme" = "steelblue", "Sub-Theme" = "grey70")) +
  geom_text(aes(label = sprintf("%d (%.0f%%)", n, pct)),
    hjust = -0.1, size = 3) +
  labs(x = NULL, y = "Prevalence (%)",
    title = sprintf("Thematic Coding (N=%d respondents)", nResp),
    fill = NULL) +
  theme_minimal() +
  theme(legend.position = "bottom") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.25)))

print(fig4)
savePlot(fig4, plotDir, "fig4_themePrevalence",
  height = 6, width = 9)


## ----figure5, fig.width=10, fig.height=6--------------------------------------
diagCols <- c(
  "IBS_C", "IBS_D", "IBS_M",
  "chronicIdiopathicConstipation", "functionalConstipation",
  "functionalDiarrhea", "cmAbdominalPainSyndrome",
  "functionalAbdominalPain", "functionalDyspepsia",
  "functionalBloating", "cyclicVomiting",
  "ruminationSyndrome", "idiopathicGastroparesis",
  "opioidInducedConstipation", "cannabinoidHyperemesis",
  "functionalHeartburn", "functionalNeurologicSyndrome"
)

upsetData <- bgcc.df %>%
  filter(!is.na(dbgiDiagnoses)) %>%
  select(all_of(diagCols))

colnames(upsetData) <- diagLabels[colnames(upsetData)]

# Only include diagnoses with >= 3 patients
diagFreqs <- colSums(upsetData)
keepDiags <- names(diagFreqs[diagFreqs >= 3])
upsetData <- upsetData[, keepDiags]

pdf(file.path(plotDir, paste0(filenameSuffix, "_fig5_diagnosisUpset.pdf")),
  width = 10, height = 6)
upset(as.data.frame(upsetData),
  nsets = ncol(upsetData),
  order.by = "freq",
  main.bar.color = "steelblue",
  sets.bar.color = "grey40",
  text.scale = 1.3,
  point.size = 2.5,
  line.size = 1,
  mb.ratio = c(0.6, 0.4)
)
dev.off()

upset(as.data.frame(upsetData),
  nsets = ncol(upsetData),
  order.by = "freq",
  main.bar.color = "steelblue",
  sets.bar.color = "grey40",
  text.scale = 1.3,
  point.size = 2.5,
  line.size = 1,
  mb.ratio = c(0.6, 0.4)
)


## ----figure6, fig.width=9, fig.height=7---------------------------------------
# Compute effect sizes for subgroups
ibsPaired <- bgcc.df %>%
  filter(!is.na(preIBSSSS) & !is.na(postIBSSSS))

# Helper: compute paired stats for a subset
pairedStats <- function(subset, label) {
  n <- nrow(subset)
  if (n < 5) return(NULL)

  wt <- wilcox.test(subset$preIBSSSS, subset$postIBSSSS,
    paired = TRUE, conf.int = TRUE)
  tt <- t.test(subset$preIBSSSS, subset$postIBSSSS, paired = TRUE)

  data.frame(
    subgroup = label,
    n = n,
    meanDelta = tt$estimate,
    ciLow = tt$conf.int[1],
    ciHigh = tt$conf.int[2],
    pValue = wt$p.value,
    stringsAsFactors = FALSE
  )
}

forestResults <- list()

# Overall
forestResults[["Overall"]] <- pairedStats(ibsPaired, sprintf("Overall (n=%d)", nrow(ibsPaired)))

# By baseline severity
for (band in levels(ibsPaired$preIBSSSSBand)) {
  sub <- ibsPaired %>% filter(preIBSSSSBand == band)
  forestResults[[band]] <- pairedStats(sub, sprintf("%s (n=%d)", band, nrow(sub)))
}

# By sex
for (s in c("F", "M")) {
  sub <- ibsPaired %>% filter(sex == s)
  label <- ifelse(s == "F", "Female", "Male")
  forestResults[[label]] <- pairedStats(sub, sprintf("%s (n=%d)", label, nrow(sub)))
}

# By age median split
ageMed <- median(ibsPaired$age, na.rm = TRUE)
sub1 <- ibsPaired %>% filter(age <= ageMed)
sub2 <- ibsPaired %>% filter(age > ageMed)
forestResults[["Younger"]] <- pairedStats(sub1, sprintf("Age <= %g (n=%d)", ageMed, nrow(sub1)))
forestResults[["Older"]] <- pairedStats(sub2, sprintf("Age > %g (n=%d)", ageMed, nrow(sub2)))

# By number of diagnoses
sub1D <- ibsPaired %>% filter(nDiagnoses == 1)
sub2D <- ibsPaired %>% filter(nDiagnoses >= 2)
forestResults[["1 Dx"]] <- pairedStats(sub1D, sprintf("1 diagnosis (n=%d)", nrow(sub1D)))
forestResults[["2+ Dx"]] <- pairedStats(sub2D, sprintf("2+ diagnoses (n=%d)", nrow(sub2D)))

forestData <- bind_rows(forestResults)

# Insert grouping separator rows
forestData$subgroup <- factor(forestData$subgroup, levels = rev(forestData$subgroup))

fig6 <- ggplot(forestData, aes(x = subgroup, y = meanDelta)) +
  geom_pointrange(aes(ymin = ciLow, ymax = ciHigh), size = 0.6) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_hline(yintercept = -50, linetype = "dotted", color = "green4", alpha = 0.6) +
  coord_flip() +
  labs(x = NULL, y = "Mean IBS-SSS Change (Post - Pre)",
    title = "IBS-SSS Change by Subgroup (95% CI)",
    caption = "Dotted green line: clinically meaningful threshold (50-pt decrease)") +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 10))

print(fig6)
savePlot(fig6, plotDir, "fig6_ibsForest",
  height = 7, width = 9)


## ----suppWaterfall, fig.width=8, fig.height=5---------------------------------
ibsPaired <- ibsPaired %>%
  arrange(deltaIBSSSS) %>%
  mutate(rank = row_number())

pSuppWaterfall <- ggplot(ibsPaired,
  aes(x = rank, y = deltaIBSSSS,
    fill = case_when(
      deltaIBSSSS <= -50 ~ "Clinically Meaningful\nImprovement",
      deltaIBSSSS < 0 ~ "Improved",
      TRUE ~ "Worsened/Unchanged"
))) +
  geom_col() +
  geom_hline(yintercept = c(-50, 0), linetype = c("dashed", "solid"),
    color = c("green4", "black")) +
  scale_fill_manual(
    values = c(
      "Clinically Meaningful\nImprovement" = "steelblue",
      "Improved" = "lightblue",
      "Worsened/Unchanged" = "coral"
    ),
    name = NULL
  ) +
  labs(x = "Patient (ranked by change)", y = "Change in IBS-SSS (Post - Pre)",
    title = sprintf("IBS-SSS Individual Changes (n=%d)", nrow(ibsPaired))) +
  theme_minimal() +
  theme(legend.position = "bottom")

print(pSuppWaterfall)
savePlot(pSuppWaterfall, plotDir, "suppWaterfall",
  height = 5, width = 8)


## ----suppUtilization, fig.width=10, fig.height=4------------------------------
utilCols <- c("OfficeVisits", "PortalMessages", "ERVisits")
utilLabels <- c("Office Visits", "Portal Messages", "ER Visits")

utilPlots <- list()
for (i in seq_along(utilCols)) {
  preName <- paste0("pre", utilCols[i])
  postName <- paste0("post", utilCols[i])

  utilLong <- bgcc.df %>%
    select(patientCode, !!sym(preName), !!sym(postName)) %>%
    pivot_longer(cols = c(!!sym(preName), !!sym(postName)),
      names_to = "timepoint", values_to = "count") %>%
    mutate(
      timepoint = ifelse(grepl("^pre", timepoint), "Pre", "Post"),
      timepoint = factor(timepoint, levels = c("Pre", "Post"))
    )

  nPaired <- sum(!is.na(bgcc.df[[preName]]) & !is.na(bgcc.df[[postName]]))

  utilPlots[[i]] <- ggplot(utilLong %>% filter(!is.na(count)),
    aes(x = timepoint, y = count, fill = timepoint)) +
    geom_violin(alpha = 0.3) +
    geom_boxplot(width = 0.15, outlier.shape = NA) +
    scale_fill_manual(values = c(Pre = "steelblue", Post = "coral")) +
    labs(x = NULL, y = "Count",
      title = sprintf("%s (n=%d)", utilLabels[i], nPaired)) +
    theme_minimal() +
    theme(legend.position = "none")
}

pSuppUtil <- utilPlots[[1]] + utilPlots[[2]] + utilPlots[[3]] + plot_layout(ncol = 3)
print(pSuppUtil)
savePlot(pSuppUtil, plotDir, "suppUtilization",
  height = 4, width = 10)


## ----suppPower----------------------------------------------------------------
cat("=== Supplementary: Power Analysis ===\n\n")

powerResults <- outcomeResults$powerResults
print(powerResults)

cat("\nSample size needed for 80% power at each observed effect size:\n")
for (i in 1:nrow(powerResults)) {
  nNeeded <- pwr::pwr.t.test(d = powerResults$cohenD[i], sig.level = 0.05,
    power = 0.80, type = "paired")$n
  cat(sprintf("  %s (d=%.3f): n=%d needed\n",
    powerResults$outcome[i], powerResults$cohenD[i], ceiling(nNeeded)))
}


## ----manifest-----------------------------------------------------------------
cat("=== Output Files ===\n\n")

figFiles <- list.files(plotDir, pattern = filenameSuffix, full.names = FALSE)
cat("Figures generated:", length(figFiles), "\n")
for (f in sort(figFiles)) cat("  ", f, "\n")

dataFiles <- list.files(dataOutputDir, pattern = filenameSuffix, full.names = FALSE)
cat("\nData files:\n")
for (f in sort(dataFiles)) cat("  ", f, "\n")

