## ----setup, echo=FALSE, message=FALSE, warning=FALSE--------------------------
library(knitr)
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(scales)
library(patchwork)
library(effectsize)
library(rstatix)
library(pwr)
library(lme4)
library(lmerTest)
library(broom)

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
cat("Loaded:", nrow(bgcc.df), "patients x", ncol(bgcc.df), "variables\n")


## ----ibsSSS_paired------------------------------------------------------------
ibsPaired.df <- bgcc.df %>%
  filter(!is.na(preIBSSSS) & !is.na(postIBSSSS))
nIBS <- nrow(ibsPaired.df)

cat("=== IBS-SSS Paired Analysis (N =", nIBS, ") ===\n\n")

# Descriptives
cat("Pre:  mean =", round(mean(ibsPaired.df$preIBSSSS), 1),
  " (SD =", round(sd(ibsPaired.df$preIBSSSS), 1),
  "), median =", median(ibsPaired.df$preIBSSSS), "\n")
cat("Post: mean =", round(mean(ibsPaired.df$postIBSSSS), 1),
  " (SD =", round(sd(ibsPaired.df$postIBSSSS), 1),
  "), median =", median(ibsPaired.df$postIBSSSS), "\n")
cat("Delta: mean =", round(mean(ibsPaired.df$deltaIBSSSS), 1),
  " (SD =", round(sd(ibsPaired.df$deltaIBSSSS), 1),
  "), median =", median(ibsPaired.df$deltaIBSSSS), "\n\n")

# Wilcoxon signed-rank test
ibsWilcox <- wilcox.test(ibsPaired.df$preIBSSSS, ibsPaired.df$postIBSSSS,
  paired = TRUE, conf.int = TRUE)
cat("Wilcoxon signed-rank test:\n")
cat("  V =", ibsWilcox$statistic, "\n")
cat("  p-value =", format.pval(ibsWilcox$p.value, digits = 4), "\n")
cat("  Hodges-Lehmann estimate (pseudomedian):", ibsWilcox$estimate, "\n")
cat("  95% CI:", ibsWilcox$conf.int, "\n\n")

# Paired t-test for mean difference CI
ibsTtest <- t.test(ibsPaired.df$preIBSSSS, ibsPaired.df$postIBSSSS, paired = TRUE)
cat("Paired t-test (for mean difference CI):\n")
cat("  Mean difference:", round(ibsTtest$estimate, 1), "\n")
cat("  95% CI:", round(ibsTtest$conf.int, 1), "\n")
cat("  t =", round(ibsTtest$statistic, 2), ", df =", ibsTtest$parameter,
  ", p =", format.pval(ibsTtest$p.value, digits = 4), "\n\n")

# Effect size: matched-pairs rank-biserial correlation (r)
ibsRankBiserial <- rank_biserial(ibsPaired.df$preIBSSSS, ibsPaired.df$postIBSSSS,
  paired = TRUE)
cat("Rank-biserial correlation r =", round(ibsRankBiserial$r_rank_biserial, 3), "\n")
cat("  95% CI:", round(ibsRankBiserial$CI_low, 3), "to",
  round(ibsRankBiserial$CI_high, 3), "\n\n")

# Cohen's d for paired data
ibsCohenD <- effectsize::cohens_d(ibsPaired.df$preIBSSSS, ibsPaired.df$postIBSSSS,
  paired = TRUE)
cat("Cohen's d (paired) =", round(ibsCohenD$Cohens_d, 3), "\n")
cat("  95% CI:", round(ibsCohenD$CI_low, 3), "to",
  round(ibsCohenD$CI_high, 3), "\n")


## ----phq2_paired--------------------------------------------------------------
phqPaired.df <- bgcc.df %>%
  filter(!is.na(prePHQ2) & !is.na(postPHQ2))
nPHQ <- nrow(phqPaired.df)

cat("=== PHQ-2 Paired Analysis (N =", nPHQ, ") ===\n\n")

cat("Pre:  mean =", round(mean(phqPaired.df$prePHQ2), 2),
  " (SD =", round(sd(phqPaired.df$prePHQ2), 2),
  "), median =", median(phqPaired.df$prePHQ2), "\n")
cat("Post: mean =", round(mean(phqPaired.df$postPHQ2), 2),
  " (SD =", round(sd(phqPaired.df$postPHQ2), 2),
  "), median =", median(phqPaired.df$postPHQ2), "\n")
cat("Delta: mean =", round(mean(phqPaired.df$deltaPHQ2), 2),
  " (SD =", round(sd(phqPaired.df$deltaPHQ2), 2),
  "), median =", median(phqPaired.df$deltaPHQ2), "\n\n")

phqWilcox <- wilcox.test(phqPaired.df$prePHQ2, phqPaired.df$postPHQ2,
  paired = TRUE, conf.int = TRUE)
cat("Wilcoxon signed-rank test:\n")
cat("  V =", phqWilcox$statistic, "\n")
cat("  p-value =", format.pval(phqWilcox$p.value, digits = 4), "\n")
cat("  Hodges-Lehmann estimate:", phqWilcox$estimate, "\n")
cat("  95% CI:", phqWilcox$conf.int, "\n\n")

phqTtest <- t.test(phqPaired.df$prePHQ2, phqPaired.df$postPHQ2, paired = TRUE)
cat("Paired t-test:\n")
cat("  Mean difference:", round(phqTtest$estimate, 2), "\n")
cat("  95% CI:", round(phqTtest$conf.int, 2), "\n")
cat("  t =", round(phqTtest$statistic, 2), ", p =",
  format.pval(phqTtest$p.value, digits = 4), "\n\n")

phqRankBiserial <- rank_biserial(phqPaired.df$prePHQ2, phqPaired.df$postPHQ2,
  paired = TRUE)
cat("Rank-biserial r =", round(phqRankBiserial$r_rank_biserial, 3), "\n")
cat("  95% CI:", round(phqRankBiserial$CI_low, 3), "to",
  round(phqRankBiserial$CI_high, 3), "\n\n")

phqCohenD <- effectsize::cohens_d(phqPaired.df$prePHQ2, phqPaired.df$postPHQ2, paired = TRUE)
cat("Cohen's d =", round(phqCohenD$Cohens_d, 3), "\n")
cat("  95% CI:", round(phqCohenD$CI_low, 3), "to",
  round(phqCohenD$CI_high, 3), "\n")


## ----gad7_paired--------------------------------------------------------------
gadPaired.df <- bgcc.df %>%
  filter(!is.na(preGAD7) & !is.na(postGAD7))
nGAD <- nrow(gadPaired.df)

cat("=== GAD-7 Paired Analysis (N =", nGAD, ") ===\n\n")

cat("Pre:  mean =", round(mean(gadPaired.df$preGAD7), 2),
  " (SD =", round(sd(gadPaired.df$preGAD7), 2),
  "), median =", median(gadPaired.df$preGAD7), "\n")
cat("Post: mean =", round(mean(gadPaired.df$postGAD7), 2),
  " (SD =", round(sd(gadPaired.df$postGAD7), 2),
  "), median =", median(gadPaired.df$postGAD7), "\n")
cat("Delta: mean =", round(mean(gadPaired.df$deltaGAD7), 2),
  " (SD =", round(sd(gadPaired.df$deltaGAD7), 2),
  "), median =", median(gadPaired.df$deltaGAD7), "\n\n")

gadWilcox <- wilcox.test(gadPaired.df$preGAD7, gadPaired.df$postGAD7,
  paired = TRUE, conf.int = TRUE)
cat("Wilcoxon signed-rank test:\n")
cat("  V =", gadWilcox$statistic, "\n")
cat("  p-value =", format.pval(gadWilcox$p.value, digits = 4), "\n")
cat("  Hodges-Lehmann estimate:", gadWilcox$estimate, "\n")
cat("  95% CI:", gadWilcox$conf.int, "\n\n")

gadTtest <- t.test(gadPaired.df$preGAD7, gadPaired.df$postGAD7, paired = TRUE)
cat("Paired t-test:\n")
cat("  Mean difference:", round(gadTtest$estimate, 2), "\n")
cat("  95% CI:", round(gadTtest$conf.int, 2), "\n")
cat("  t =", round(gadTtest$statistic, 2), ", p =",
  format.pval(gadTtest$p.value, digits = 4), "\n\n")

gadRankBiserial <- rank_biserial(gadPaired.df$preGAD7, gadPaired.df$postGAD7,
  paired = TRUE)
cat("Rank-biserial r =", round(gadRankBiserial$r_rank_biserial, 3), "\n")
cat("  95% CI:", round(gadRankBiserial$CI_low, 3), "to",
  round(gadRankBiserial$CI_high, 3), "\n\n")

gadCohenD <- effectsize::cohens_d(gadPaired.df$preGAD7, gadPaired.df$postGAD7, paired = TRUE)
cat("Cohen's d =", round(gadCohenD$Cohens_d, 3), "\n")
cat("  95% CI:", round(gadCohenD$CI_low, 3), "to",
  round(gadCohenD$CI_high, 3), "\n")


## ----fdrCorrection------------------------------------------------------------
cat("=== FDR Correction (Benjamini-Hochberg) ===\n\n")

primaryPvals <- c(
  `IBS-SSS` = ibsWilcox$p.value,
  `PHQ-2` = phqWilcox$p.value,
  `GAD-7` = gadWilcox$p.value
)

fdrPvals <- p.adjust(primaryPvals, method = "BH")

fdrResults.df <- data.frame(
  outcome = names(primaryPvals),
  N = c(nIBS, nPHQ, nGAD),
  rawP = primaryPvals,
  fdrP = fdrPvals,
  stringsAsFactors = FALSE
)

cat("Primary pre/post comparisons:\n")
print(fdrResults.df)
cat("\nAll FDR-adjusted p-values < 0.05?", all(fdrPvals < 0.05), "\n")


## ----powerAnalysis------------------------------------------------------------
cat("=== Post-Hoc Achieved Power ===\n\n")

# Compute achieved power using observed Cohen's d and actual N
ibsPower <- pwr.t.test(n = nIBS, d = abs(ibsCohenD$Cohens_d),
  sig.level = 0.05, type = "paired")
phqPower <- pwr.t.test(n = nPHQ, d = abs(phqCohenD$Cohens_d),
  sig.level = 0.05, type = "paired")
gadPower <- pwr.t.test(n = nGAD, d = abs(gadCohenD$Cohens_d),
  sig.level = 0.05, type = "paired")

powerResults.df <- data.frame(
  outcome = c("IBS-SSS", "PHQ-2", "GAD-7"),
  N = c(nIBS, nPHQ, nGAD),
  cohenD = round(c(abs(ibsCohenD$Cohens_d),
    abs(phqCohenD$Cohens_d), abs(gadCohenD$Cohens_d)), 3),
  achievedPower = round(c(ibsPower$power, phqPower$power, gadPower$power), 3),
  stringsAsFactors = FALSE
)

print(powerResults.df)
cat("\nNote: Post-hoc power is informative but should be interpreted cautiously.\n")


## ----ibsSSS_clinicalChange----------------------------------------------------
cat("=== IBS-SSS Clinically Meaningful Change ===\n\n")

# >= 50 point decrease = clinically meaningful (Francis et al.)
ibsPaired.df$ibsResponder <- ibsPaired.df$deltaIBSSSS <= -50
nResponder <- sum(ibsPaired.df$ibsResponder, na.rm = TRUE)
pctResponder <- 100 * nResponder / nIBS

cat("Responder (>=50-pt decrease):", nResponder, "of", nIBS,
  sprintf("(%.1f%%)\n", pctResponder))

# 95% CI for responder proportion (Wilson interval)
responderTest <- prop.test(nResponder, nIBS, correct = FALSE)
cat("  95% CI:", sprintf("%.1f%% to %.1f%%\n",
  100 * responderTest$conf.int[1], 100 * responderTest$conf.int[2]))

# Improved / unchanged / worsened
nImproved <- sum(ibsPaired.df$deltaIBSSSS < 0, na.rm = TRUE)
nWorsened <- sum(ibsPaired.df$deltaIBSSSS > 0, na.rm = TRUE)
nUnchanged <- sum(ibsPaired.df$deltaIBSSSS == 0, na.rm = TRUE)
cat(sprintf("\nImproved (any decrease): %d (%.1f%%)\n", nImproved, 100 * nImproved / nIBS))
cat(sprintf("Unchanged: %d (%.1f%%)\n", nUnchanged, 100 * nUnchanged / nIBS))
cat(sprintf("Worsened (any increase): %d (%.1f%%)\n", nWorsened, 100 * nWorsened / nIBS))


## ----ibsBandTransitions-------------------------------------------------------
cat("\n=== IBS-SSS Severity Band Transitions (N =", nIBS, ") ===\n\n")

# Cross-tab of pre->post severity band
bandTransitions <- table(
  Pre = ibsPaired.df$preIBSSSSBand,
  Post = ibsPaired.df$postIBSSSSBand
)

cat("Transition matrix (rows = pre, cols = post):\n")
print(bandTransitions)

# McNemar test (on collapsed 2x2: moderate/severe vs remission/mild)
ibsPaired.df$preSevere <- ibsPaired.df$preIBSSSSBand %in% c("Moderate", "Severe")
ibsPaired.df$postSevere <- ibsPaired.df$postIBSSSSBand %in% c("Moderate", "Severe")
mcnemarTab <- table(ibsPaired.df$preSevere, ibsPaired.df$postSevere)
cat("\nMcNemar test (moderate/severe vs mild/remission):\n")
print(mcnemarTab)
if (sum(mcnemarTab[1, 2], mcnemarTab[2, 1]) >= 5) {
  mcnemarResult <- mcnemar.test(mcnemarTab)
  cat("  Chi-sq =", round(mcnemarResult$statistic, 2),
    ", p =", format.pval(mcnemarResult$p.value, digits = 4), "\n")
} else {
  cat("  Too few discordant pairs for McNemar test.\n")
}


## ----phq2Transitions----------------------------------------------------------
cat("=== PHQ-2 Screening Transitions (N =", nPHQ, ") ===\n\n")

phqPaired.df$prePositive <- phqPaired.df$prePHQ2 >= 3
phqPaired.df$postPositive <- phqPaired.df$postPHQ2 >= 3

phqTransitions <- table(
  `Pre Positive` = phqPaired.df$prePositive,
  `Post Positive` = phqPaired.df$postPositive
)
cat("PHQ-2 positive screen transitions:\n")
print(phqTransitions)

nPrePos <- sum(phqPaired.df$prePositive)
nPostPos <- sum(phqPaired.df$postPositive)
cat(sprintf("\nPre positive screen: %d (%.1f%%)\n", nPrePos, 100 * nPrePos / nPHQ))
cat(sprintf("Post positive screen: %d (%.1f%%)\n", nPostPos, 100 * nPostPos / nPHQ))

if (sum(phqTransitions[1, 2], phqTransitions[2, 1]) >= 5) {
  phqMcnemar <- mcnemar.test(phqTransitions)
  cat("McNemar p =", format.pval(phqMcnemar$p.value, digits = 4), "\n")
}


## ----gad7Transitions----------------------------------------------------------
cat("=== GAD-7 Severity Band Transitions (N =", nGAD, ") ===\n\n")

gadBandTransitions <- table(
  Pre = gadPaired.df$preGAD7Band,
  Post = gadPaired.df$postGAD7Band
)
cat("GAD-7 transition matrix:\n")
print(gadBandTransitions)

gadPaired.df$preModeratePlus <- gadPaired.df$preGAD7Band %in% c("Moderate", "Severe")
gadPaired.df$postModeratePlus <- gadPaired.df$postGAD7Band %in% c("Moderate", "Severe")
gadMcnemarTab <- table(gadPaired.df$preModeratePlus, gadPaired.df$postModeratePlus)
cat("\nMcNemar test (moderate/severe vs minimal/mild):\n")
print(gadMcnemarTab)
if (sum(gadMcnemarTab[1, 2], gadMcnemarTab[2, 1]) >= 5) {
  gadMcnemar <- mcnemar.test(gadMcnemarTab)
  cat("  Chi-sq =", round(gadMcnemar$statistic, 2),
    ", p =", format.pval(gadMcnemar$p.value, digits = 4), "\n")
}


## ----ibsWaterfall, fig.width=8, fig.height=5----------------------------------
# Waterfall plot of individual IBS-SSS changes
ibsPaired.df <- ibsPaired.df %>%
  arrange(deltaIBSSSS) %>%
  mutate(rank = row_number())

pWaterfall <- ggplot(ibsPaired.df,
  aes(x = rank, y = deltaIBSSSS,
    fill = ifelse(deltaIBSSSS <= -50, "Responder",
      ifelse(deltaIBSSSS < 0, "Improved", "Worsened/Unchanged")))) +
  geom_col() +
  geom_hline(yintercept = -50, linetype = "dashed", color = "green4") +
  geom_hline(yintercept = 0, color = "black") +
  scale_fill_manual(
    values = c(Responder = "steelblue", Improved = "lightblue",
      `Worsened/Unchanged` = "coral"),
    name = "Status"
  ) +
  labs(x = "Patient (ranked by change)", y = "Change in IBS-SSS",
    title = sprintf("IBS-SSS Individual Changes (N=%d)", nIBS),
    caption = "Dashed line: clinically meaningful threshold (50-point decrease)") +
  theme_minimal()

print(pWaterfall)
savePlot(pWaterfall, plotDir, "ibsWaterfall",
  height = 5, width = 8)


## ----mixedModel---------------------------------------------------------------
cat("=== Mixed-Effects Model: IBS-SSS ===\n\n")

# Create long-format data for the mixed model
ibsMixed.df <- bgcc.df %>%
  filter(!is.na(preIBSSSS) & !is.na(postIBSSSS)) %>%
  select(patientCode, classDate, preIBSSSS, postIBSSSS) %>%
  pivot_longer(cols = c(preIBSSSS, postIBSSSS),
    names_to = "timepoint", values_to = "IBSSSS") %>%
  mutate(
    time = ifelse(timepoint == "preIBSSSS", 0, 1),
    classDate = as.factor(classDate)
  )

# Count class dates with paired data
nClassDates <- length(unique(ibsMixed.df$classDate))
cat("Class dates with paired IBS-SSS data:", nClassDates, "\n\n")

# Fit mixed model: IBS-SSS ~ time + (1|classDate)
# time=0 is pre, time=1 is post; coefficient on time = average change
ibsLmer <- lmer(IBSSSS ~ time + (1 | classDate), data = ibsMixed.df)

cat("Model: IBS-SSS ~ time + (1 | classDate)\n\n")
cat("Fixed effects:\n")
print(summary(ibsLmer)$coefficients)

# ICC for class-level clustering
iccVarComp <- as.data.frame(VarCorr(ibsLmer))
classVar <- iccVarComp$vcov[iccVarComp$grp == "classDate"]
residVar <- iccVarComp$vcov[iccVarComp$grp == "Residual"]
icc <- classVar / (classVar + residVar)
cat(sprintf("\nICC (class date): %.4f\n", icc))
cat("  Class variance:", round(classVar, 1), "\n")
cat("  Residual variance:", round(residVar, 1), "\n")
cat(sprintf("  Interpretation: %.1f%% of IBS-SSS variance is between classes\n\n", 100 * icc))

# Compare to simple paired model (no random effect)
ibsLmSimple <- lm(IBSSSS ~ time, data = ibsMixed.df)
cat("Simple model (no random effect):\n")
cat("  Time coefficient:", round(coef(ibsLmSimple)["time"], 1), "\n")
cat("  Mixed model time coefficient:",
  round(fixef(ibsLmer)["time"], 1), "\n")


## ----ibsPredictors------------------------------------------------------------
cat("=== Predictors of IBS-SSS Change ===\n\n")

# Build predictor dataset: deltaIBSSSS ~ baseline_IBS_SSS + age + sex + nDiagnoses
ibsPred.df <- bgcc.df %>%
  filter(!is.na(preIBSSSS) & !is.na(postIBSSSS)) %>%
  filter(!is.na(age) & !is.na(sex) & !is.na(nDiagnoses))

cat("Predictor model sample size:", nrow(ibsPred.df), "\n\n")

# Check whether we have enough class dates for a random effect
nClassPred <- length(unique(ibsPred.df$classDate))

if (nClassPred >= 5) {
  ibsPredModel <- lmer(deltaIBSSSS ~ preIBSSSS + age + sex + nDiagnoses +
    (1 | classDate), data = ibsPred.df)
  cat("Model: deltaIBSSSS ~ preIBSSSS + age + sex + nDiagnoses + (1|classDate)\n\n")
  cat("Fixed effects:\n")
  predCoefs <- summary(ibsPredModel)$coefficients
  print(predCoefs)

  # FDR correction on predictor p-values (excluding intercept)
  predPvals <- predCoefs[-1, "Pr(>|t|)"]
  predFDR <- p.adjust(predPvals, method = "BH")
  cat("\nFDR-corrected p-values:\n")
  for (i in seq_along(predFDR)) {
    cat(sprintf("  %-15s: raw p = %s, FDR p = %s\n",
      names(predFDR)[i],
      format.pval(predPvals[i], digits = 3),
      format.pval(predFDR[i], digits = 3)))
  }

  # Confidence intervals
  cat("\n95% CIs for fixed effects:\n")
  print(confint(ibsPredModel, method = "Wald", parm = "beta_"))
} else {
  ibsPredModel <- lm(deltaIBSSSS ~ preIBSSSS + age + sex + nDiagnoses,
    data = ibsPred.df)
  cat("Model: deltaIBSSSS ~ preIBSSSS + age + sex + nDiagnoses\n")
  cat("(Too few class dates for random effect)\n\n")
  print(summary(ibsPredModel)$coefficients)
}


## ----ibsSubgroupBySeverity----------------------------------------------------
cat("=== IBS-SSS Change by Baseline Severity ===\n\n")

ibsPaired.df$preIBSSSSBand <- ibsSSSBand(ibsPaired.df$preIBSSSS)

subgroupResults <- ibsPaired.df %>%
  filter(!is.na(preIBSSSSBand)) %>%
  group_by(preIBSSSSBand) %>%
  summarise(
    n = n(),
    meanPre = mean(preIBSSSS),
    meanPost = mean(postIBSSSS),
    meanDelta = mean(deltaIBSSSS),
    sdDelta = sd(deltaIBSSSS),
    medianDelta = median(deltaIBSSSS),
    nResponder = sum(deltaIBSSSS <= -50),
    .groups = "drop"
  ) %>%
  mutate(pctResponder = round(100 * nResponder / n, 1))

print(as.data.frame(subgroupResults))

# Per-subgroup effect sizes (where n >= 5)
cat("\nPer-subgroup Wilcoxon tests:\n")
for (band in levels(ibsPaired.df$preIBSSSSBand)) {
  sub <- ibsPaired.df %>% filter(preIBSSSSBand == band)
  if (nrow(sub) >= 5) {
    wt <- wilcox.test(sub$preIBSSSS, sub$postIBSSSS, paired = TRUE, conf.int = TRUE)
    rb <- rank_biserial(sub$preIBSSSS, sub$postIBSSSS, paired = TRUE)
    cat(sprintf("\n  %s (n=%d): V=%g, p=%s, r=%.3f [%.3f, %.3f]\n",
      band, nrow(sub), wt$statistic, format.pval(wt$p.value, digits = 3),
      rb$r_rank_biserial, rb$CI_low, rb$CI_high))
  } else if (nrow(sub) > 0) {
    cat(sprintf("\n  %s (n=%d): too few for subgroup test\n", band, nrow(sub)))
  }
}


## ----utilizationPaired--------------------------------------------------------
cat("=== Healthcare Utilization Pre/Post ===\n\n")

utilVars <- c("OfficeVisits", "PortalMessages", "ERVisits")
utilResults <- list()

for (varName in utilVars) {
  preName <- paste0("pre", varName)
  postName <- paste0("post", varName)
  deltaName <- paste0("delta", varName)

  paired <- bgcc.df %>%
    filter(!is.na(!!sym(preName)) & !is.na(!!sym(postName)))
  nPaired <- nrow(paired)

  preVals <- paired[[preName]]
  postVals <- paired[[postName]]
  deltaVals <- paired[[deltaName]]

  cat(sprintf("--- %s (N=%d) ---\n", varName, nPaired))
  cat("Pre:  mean =", round(mean(preVals), 2),
    " (SD =", round(sd(preVals), 2), "), median =", median(preVals), "\n")
  cat("Post: mean =", round(mean(postVals), 2),
    " (SD =", round(sd(postVals), 2), "), median =", median(postVals), "\n")
  cat("Delta: mean =", round(mean(deltaVals), 2),
    " (SD =", round(sd(deltaVals), 2), "), median =", median(deltaVals), "\n")

  wt <- wilcox.test(preVals, postVals, paired = TRUE, conf.int = TRUE)
  cat("Wilcoxon: V =", wt$statistic, ", p =", format.pval(wt$p.value, digits = 4), "\n")
  cat("  Hodges-Lehmann:", wt$estimate, ", 95% CI:", wt$conf.int, "\n")

  rb <- rank_biserial(preVals, postVals, paired = TRUE)
  cat("  Rank-biserial r =", round(rb$r_rank_biserial, 3),
    " [", round(rb$CI_low, 3), ",", round(rb$CI_high, 3), "]\n\n")

  utilResults[[varName]] <- list(p = wt$p.value, r = rb$r_rank_biserial, n = nPaired)
}

# FDR correction for utilization tests
utilPvals <- sapply(utilResults, function(x) x$p)
utilFDR <- p.adjust(utilPvals, method = "BH")
cat("Utilization FDR-corrected p-values:\n")
for (i in seq_along(utilFDR)) {
  cat(sprintf("  %s: raw p = %s, FDR p = %s\n",
    names(utilFDR)[i], format.pval(utilPvals[i], digits = 3),
    format.pval(utilFDR[i], digits = 3)))
}


## ----sensitivityMissingness---------------------------------------------------
cat("=== Sensitivity: IBS-SSS Missingness Comparison ===\n\n")

# Compare demographics of patients with vs without paired IBS-SSS
bgcc.df$hasPairedIBS <- !is.na(bgcc.df$preIBSSSS) & !is.na(bgcc.df$postIBSSSS)

cat("Patients with paired IBS-SSS:", sum(bgcc.df$hasPairedIBS), "\n")
cat("Patients without:", sum(!bgcc.df$hasPairedIBS), "\n\n")

# Age
ageWithIBS <- bgcc.df$age[bgcc.df$hasPairedIBS]
ageWithoutIBS <- bgcc.df$age[!bgcc.df$hasPairedIBS]
cat("Age — With paired: mean=", round(mean(ageWithIBS, na.rm = TRUE), 1),
  "; Without: mean=", round(mean(ageWithoutIBS, na.rm = TRUE), 1), "\n")
cat("  Wilcoxon p =", format.pval(wilcox.test(ageWithIBS, ageWithoutIBS)$p.value,
  digits = 3), "\n\n")

# Sex
sexTab <- table(bgcc.df$sex, bgcc.df$hasPairedIBS)
cat("Sex:\n")
print(sexTab)
cat("  Chi-sq p =", format.pval(chisq.test(sexTab)$p.value, digits = 3), "\n\n")

# nDiagnoses
nDiagWith <- bgcc.df$nDiagnoses[bgcc.df$hasPairedIBS]
nDiagWithout <- bgcc.df$nDiagnoses[!bgcc.df$hasPairedIBS]
cat("nDiagnoses — With: mean=", round(mean(nDiagWith, na.rm = TRUE), 1),
  "; Without: mean=", round(mean(nDiagWithout, na.rm = TRUE), 1), "\n")
cat("  Wilcoxon p =", format.pval(wilcox.test(nDiagWith, nDiagWithout)$p.value,
  digits = 3), "\n")

bgcc.df$hasPairedIBS <- NULL


## ----resultsSummary-----------------------------------------------------------
cat("=== Comprehensive Results Summary ===\n\n")

cat("--- Primary Outcomes (Wilcoxon signed-rank, FDR-corrected) ---\n")
cat(sprintf("IBS-SSS (N=%d): Hodges-Lehmann=%.1f, 95%% CI [%.1f, %.1f], ",
  nIBS, ibsWilcox$estimate, ibsWilcox$conf.int[1], ibsWilcox$conf.int[2]))
cat(sprintf("r=%.3f [%.3f, %.3f], raw p=%s, FDR p=%s\n",
  ibsRankBiserial$r_rank_biserial, ibsRankBiserial$CI_low, ibsRankBiserial$CI_high,
  format.pval(ibsWilcox$p.value, digits = 4), format.pval(fdrPvals["IBS-SSS"], digits = 4)))

cat(sprintf("PHQ-2 (N=%d): Hodges-Lehmann=%.2f, 95%% CI [%.2f, %.2f], ",
  nPHQ, phqWilcox$estimate, phqWilcox$conf.int[1], phqWilcox$conf.int[2]))
cat(sprintf("r=%.3f [%.3f, %.3f], raw p=%s, FDR p=%s\n",
  phqRankBiserial$r_rank_biserial, phqRankBiserial$CI_low, phqRankBiserial$CI_high,
  format.pval(phqWilcox$p.value, digits = 4), format.pval(fdrPvals["PHQ-2"], digits = 4)))

cat(sprintf("GAD-7 (N=%d): Hodges-Lehmann=%.2f, 95%% CI [%.2f, %.2f], ",
  nGAD, gadWilcox$estimate, gadWilcox$conf.int[1], gadWilcox$conf.int[2]))
cat(sprintf("r=%.3f [%.3f, %.3f], raw p=%s, FDR p=%s\n",
  gadRankBiserial$r_rank_biserial, gadRankBiserial$CI_low, gadRankBiserial$CI_high,
  format.pval(gadWilcox$p.value, digits = 4), format.pval(fdrPvals["GAD-7"], digits = 4)))

cat(sprintf("\n--- Clinical Meaningfulness ---\n"))
cat(sprintf("IBS-SSS responders (>=50-pt decrease): %d/%d (%.1f%%), 95%% CI [%.1f%%, %.1f%%]\n",
  nResponder, nIBS, pctResponder,
  100 * responderTest$conf.int[1], 100 * responderTest$conf.int[2]))

cat("\n--- Achieved Power ---\n")
print(powerResults.df)

# Export results table
resultsFile <- file.path(dataOutputDir, paste0(filenameSuffix, "_outcomeResults.rds"))
saveRDS(list(
  fdrResults = fdrResults.df,
  powerResults = powerResults.df,
  ibsWilcox = ibsWilcox,
  phqWilcox = phqWilcox,
  gadWilcox = gadWilcox,
  ibsCohenD = ibsCohenD,
  phqCohenD = phqCohenD,
  gadCohenD = gadCohenD,
  ibsRankBiserial = ibsRankBiserial,
  phqRankBiserial = phqRankBiserial,
  gadRankBiserial = gadRankBiserial,
  responderTest = responderTest
), file = resultsFile)
cat("\nResults saved to:", resultsFile, "\n")

