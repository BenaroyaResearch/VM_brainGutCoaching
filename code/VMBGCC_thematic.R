## ----setup, echo=FALSE, message=FALSE, warning=FALSE--------------------------
library(knitr)
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(scales)
library(patchwork)
library(effectsize)
library(openxlsx)

opts_chunk$set(
  fig.width = 6, fig.height = 4, cache = FALSE,
  echo = FALSE, warning = FALSE, message = FALSE,
  results = "markup"
)

options(stringsAsFactors = FALSE)

baseDir <- "/Users/tedwards/Documents/projects/VM_brainGutCoaching"
setwd(baseDir)

dataInputDir <- file.path(baseDir, "data/inputData")
dataOutputDir <- file.path(baseDir, "data/outputData")
plotDir <- file.path(baseDir, "figures")
dataDate <- "2026-03-19"
filenameSuffix <- paste0("VMBGCC.", dataDate)

source(file.path(baseDir, "code/VMBGCC_functions.R"))

bgcc.df <- readRDS(file.path(dataOutputDir, paste0(filenameSuffix, "_bgccClean.rds")))
thematic.df <- readRDS(file.path(dataOutputDir, paste0(filenameSuffix, "_thematicCoding.rds")))

cat("Loaded:", nrow(bgcc.df), "patients,", nrow(thematic.df), "thematic rows\n")


## ----themePrevalence, fig.width=8, fig.height=6-------------------------------
# Main themes (3) and sub-themes (12)
mainThemes <- c(
  "themePositiveSharedExperience",
  "themePatientEmpowerment",
  "themePatientActivation"
)

subThemes <- c(
  "subIsolationReduced", "subValidation", "subSharedCommunity",
  "subChangeNegHealthcare", "subGratitude", "subEnjoymentPositive",
  "subContent", "subTeachingCoachingStyle", "subCoachingStructure",
  "subSelfEfficacy", "subAgencyKnowledgeSkills", "subAgencyActionableTools"
)

allThemes <- c(mainThemes, subThemes)

# Filter to survey respondents only (those with text in surveyLiked)
thematicRespondents <- thematic.df %>%
  filter(!is.na(surveyLiked) & tolower(surveyLiked) != "did not respond")
nRespondents <- nrow(thematicRespondents)

cat("=== Theme Prevalence (among", nRespondents, "survey respondents) ===\n\n")

# Nice labels for display
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

# Compute prevalence with Wilson 95% CIs
themeResults <- data.frame(
  theme = allThemes,
  label = themeLabels[allThemes],
  n = sapply(allThemes, function(t) sum(thematicRespondents[[t]] == 1)),
  stringsAsFactors = FALSE
) %>%
  mutate(
    pct = 100 * n / nRespondents,
    type = ifelse(theme %in% mainThemes, "Main Theme", "Sub-Theme")
  )

# Wilson CIs
for (i in 1:nrow(themeResults)) {
  ci <- prop.test(themeResults$n[i], nRespondents, correct = FALSE)$conf.int
  themeResults$ciLow[i] <- 100 * ci[1]
  themeResults$ciHigh[i] <- 100 * ci[2]
}

cat("Main Themes:\n")
for (i in which(themeResults$type == "Main Theme")) {
  cat(sprintf("  %-40s: %3d/%d (%5.1f%%), 95%% CI [%.1f%%, %.1f%%]\n",
    themeResults$label[i], themeResults$n[i], nRespondents,
    themeResults$pct[i], themeResults$ciLow[i], themeResults$ciHigh[i]))
}

cat("\nSub-Themes:\n")
for (i in which(themeResults$type == "Sub-Theme")) {
  cat(sprintf("  %-40s: %3d/%d (%5.1f%%), 95%% CI [%.1f%%, %.1f%%]\n",
    themeResults$label[i], themeResults$n[i], nRespondents,
    themeResults$pct[i], themeResults$ciLow[i], themeResults$ciHigh[i]))
}


## ----themeBarplot, fig.width=9, fig.height=6----------------------------------
# Bar chart with CIs — main themes and sub-themes separated
themeResults$label <- factor(themeResults$label,
  levels = rev(themeResults$label[order(themeResults$pct)]))

pThemes <- ggplot(themeResults,
  aes(x = label, y = pct, fill = type)) +
  geom_col(width = 0.7) +
  geom_errorbar(aes(ymin = ciLow, ymax = ciHigh), width = 0.2) +
  coord_flip() +
  scale_fill_manual(values = c("Main Theme" = "steelblue", "Sub-Theme" = "lightblue")) +
  geom_text(aes(label = sprintf("%d (%.0f%%)", n, pct)),
    hjust = -0.1, size = 3) +
  labs(x = NULL, y = "Prevalence (%)",
    title = sprintf("Thematic Coding Prevalence (N=%d respondents)", nRespondents),
    fill = NULL) +
  theme_minimal() +
  theme(legend.position = "bottom") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.25)))

print(pThemes)
savePlot(pThemes, plotDir, "themePrevalence",
  height = 6, width = 9)


## ----themeCooccurrence, fig.width=8, fig.height=7-----------------------------
# Compute pairwise co-occurrence (phi coefficient) for all themes
themeMat <- as.matrix(thematicRespondents[, allThemes])

# Phi coefficient matrix
nThemes <- length(allThemes)
phiMat <- matrix(NA, nThemes, nThemes)
rownames(phiMat) <- colnames(phiMat) <- themeLabels[allThemes]

for (i in 1:(nThemes - 1)) {
  for (j in (i + 1):nThemes) {
    a <- themeMat[, i]
    b <- themeMat[, j]
    tab <- table(factor(a, 0:1), factor(b, 0:1))
    if (all(dim(tab) == c(2, 2))) {
      # Phi coefficient
      n11 <- tab[2, 2]
      n10 <- tab[2, 1]
      n01 <- tab[1, 2]
      n00 <- tab[1, 1]
      denom <- sqrt((n11 + n10) * (n01 + n00) * (n11 + n01) * (n10 + n00))
      if (denom > 0) {
        phi <- (n11 * n00 - n10 * n01) / denom
      } else {
        phi <- 0
      }
    } else {
      phi <- NA
    }
    phiMat[i, j] <- phi
    phiMat[j, i] <- phi
  }
}
diag(phiMat) <- 1

cat("=== Theme Co-occurrence (Phi Coefficients) ===\n\n")

# Print top co-occurring pairs
phiPairs <- expand.grid(i = 1:nThemes, j = 1:nThemes) %>%
  filter(i < j) %>%
  mutate(
    theme1 = themeLabels[allThemes[i]],
    theme2 = themeLabels[allThemes[j]],
    phi = sapply(1:n(), function(k) phiMat[i[k], j[k]])
  ) %>%
  arrange(desc(abs(phi)))

cat("Top 15 co-occurrence pairs (by |phi|):\n")
for (k in 1:min(15, nrow(phiPairs))) {
  cat(sprintf("  %s <-> %s: phi = %.3f\n",
    phiPairs$theme1[k], phiPairs$theme2[k], phiPairs$phi[k]))
}


## ----cooccurrenceHeatmap, fig.width=9, fig.height=8---------------------------
# Heatmap of phi coefficients
phiLong <- phiPairs %>%
  select(theme1, theme2, phi) %>%
  bind_rows(data.frame(theme1 = phiPairs$theme2, theme2 = phiPairs$theme1,
    phi = phiPairs$phi)) %>%
  bind_rows(data.frame(
    theme1 = themeLabels[allThemes],
    theme2 = themeLabels[allThemes],
    phi = 1
  ))

# Order themes by hierarchical clustering on phi matrix
hc <- hclust(as.dist(1 - phiMat))
themeOrder <- themeLabels[allThemes][hc$order]

phiLong$theme1 <- factor(phiLong$theme1, levels = themeOrder)
phiLong$theme2 <- factor(phiLong$theme2, levels = themeOrder)

pHeatmap <- ggplot(phiLong, aes(x = theme1, y = theme2, fill = phi)) +
  geom_tile(color = "white") +
  scale_fill_gradient2(low = "steelblue", mid = "white", high = "firebrick",
    midpoint = 0, limits = c(-0.5, 1), name = "Phi") +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 8),
    axis.text.y = element_text(size = 8)
  ) +
  labs(x = NULL, y = NULL,
    title = "Theme Co-occurrence (Phi Coefficients)")

print(pHeatmap)
savePlot(pHeatmap, plotDir, "themeCooccurrence",
  height = 8, width = 9)


## ----themeOutcomes------------------------------------------------------------
cat("=== Exploratory: Theme × IBS-SSS Change ===\n\n")

# Merge thematic coding with paired IBS-SSS data
themeOutcome.df <- bgcc.df %>%
  filter(!is.na(preIBSSSS) & !is.na(postIBSSSS)) %>%
  inner_join(thematic.df %>% select(patientCode, all_of(allThemes)),
    by = "patientCode")

nThemeOutcome <- nrow(themeOutcome.df)
cat("Patients with both paired IBS-SSS and thematic coding:", nThemeOutcome, "\n\n")

if (nThemeOutcome >= 10) {
  # Test each main theme: does deltaIBSSSS differ by theme presence?
  themeIBSResults <- data.frame(
    theme = character(), n0 = integer(), n1 = integer(),
    meanDelta0 = numeric(), meanDelta1 = numeric(),
    wilcoxP = numeric(), rankBisR = numeric(),
    stringsAsFactors = FALSE
  )

  for (theme in mainThemes) {
    g0 <- themeOutcome.df$deltaIBSSSS[themeOutcome.df[[theme]] == 0]
    g1 <- themeOutcome.df$deltaIBSSSS[themeOutcome.df[[theme]] == 1]

    if (length(g0) >= 3 && length(g1) >= 3) {
      wt <- wilcox.test(g0, g1)
      rb <- effectsize::rank_biserial(g0, g1)

      themeIBSResults <- bind_rows(themeIBSResults, data.frame(
        theme = themeLabels[theme],
        n0 = length(g0), n1 = length(g1),
        meanDelta0 = round(mean(g0), 1),
        meanDelta1 = round(mean(g1), 1),
        wilcoxP = wt$p.value,
        rankBisR = round(rb$r_rank_biserial, 3),
        stringsAsFactors = FALSE
      ))
    }
  }

  themeIBSResults$fdrP <- p.adjust(themeIBSResults$wilcoxP, method = "BH")

  cat("IBS-SSS delta by main theme presence (Mann-Whitney):\n")
  print(as.data.frame(themeIBSResults))
} else {
  cat("Insufficient overlap between paired IBS-SSS and thematic coding for analysis.\n")
}


## ----themeOutcomesPHQ2--------------------------------------------------------
cat("\n=== Exploratory: Theme × PHQ-2 Change ===\n\n")

themeOutcomePHQ.df <- bgcc.df %>%
  filter(!is.na(prePHQ2) & !is.na(postPHQ2)) %>%
  inner_join(thematic.df %>% select(patientCode, all_of(mainThemes)),
    by = "patientCode")

nThemePHQ <- nrow(themeOutcomePHQ.df)
cat("Patients with both paired PHQ-2 and thematic coding:", nThemePHQ, "\n\n")

if (nThemePHQ >= 10) {
  themePHQResults <- data.frame(
    theme = character(), n0 = integer(), n1 = integer(),
    meanDelta0 = numeric(), meanDelta1 = numeric(),
    wilcoxP = numeric(), stringsAsFactors = FALSE
  )

  for (theme in mainThemes) {
    g0 <- themeOutcomePHQ.df$deltaPHQ2[themeOutcomePHQ.df[[theme]] == 0]
    g1 <- themeOutcomePHQ.df$deltaPHQ2[themeOutcomePHQ.df[[theme]] == 1]

    if (length(g0) >= 3 && length(g1) >= 3) {
      wt <- wilcox.test(g0, g1)
      themePHQResults <- bind_rows(themePHQResults, data.frame(
        theme = themeLabels[theme], n0 = length(g0), n1 = length(g1),
        meanDelta0 = round(mean(g0), 2), meanDelta1 = round(mean(g1), 2),
        wilcoxP = wt$p.value, stringsAsFactors = FALSE
      ))
    }
  }

  themePHQResults$fdrP <- p.adjust(themePHQResults$wilcoxP, method = "BH")
  cat("PHQ-2 delta by main theme presence:\n")
  print(as.data.frame(themePHQResults))
}


## ----microGoals---------------------------------------------------------------
cat("=== Micro-Goals Analysis ===\n\n")

# Extract non-NA micro-goals
goalsText <- bgcc.df$microGoals[!is.na(bgcc.df$microGoals)]
cat("Patients with micro-goals recorded:", length(goalsText), "\n\n")

# Categorize micro-goals by keyword matching
goalCategories <- list(
  "Exercise/Movement" = c("exercise", "walk", "walking", "yoga", "stretch",
    "move", "movement", "physical", "hike", "run", "swim", "gym", "steps"),
  "Mindfulness/Meditation" = c("mindful", "meditat", "breath", "relax",
    "calm", "deep breath", "diaphragm"),
  "Diet/Nutrition" = c("diet", "eat", "food", "meal", "fiber", "water",
    "hydrat", "nutrition", "fodmap", "drink"),
  "Sleep/Rest" = c("sleep", "rest", "bedtime", "nap"),
  "Social Activity" = c("social", "friend", "family", "connect", "community",
    "group", "talk", "spend time"),
  "Screen Time Reduction" = c("screen", "phone", "device", "tv",
    "social media", "limit"),
  "Stress Management" = c("stress", "journal", "writing", "gratitude",
    "self-care", "selfcare"),
  "App/Tool Use" = c("nerva", "mahana", "calmigo", "app")
)

goalCounts <- sapply(goalCategories, function(keywords) {
  sum(sapply(goalsText, function(txt) {
    any(str_detect(tolower(txt), keywords))
  }))
})

cat("Micro-goal categories (keyword-based):\n")
goalCountsSorted <- sort(goalCounts, decreasing = TRUE)
for (i in seq_along(goalCountsSorted)) {
  cat(sprintf("  %-25s: %3d (%.1f%% of those with goals)\n",
    names(goalCountsSorted)[i], goalCountsSorted[i],
    100 * goalCountsSorted[i] / length(goalsText)))
}


## ----brainGutGamePlan---------------------------------------------------------
cat("\n=== Brain Gut Game Plan Analysis ===\n\n")

gamePlanText <- bgcc.df$brainGutGamePlan[!is.na(bgcc.df$brainGutGamePlan)]
cat("Patients with Brain Gut Game Plan:", length(gamePlanText), "\n\n")

# Categorize interventions
interventions <- list(
  "Nerva App" = c("nerva"),
  "Mahana CBT" = c("mahana"),
  "Calmigo" = c("calmigo"),
  "Pain Psychology" = c("pain psych", "psychology"),
  "Diaphragmatic Breathing" = c("diaphragm", "belly breath", "deep breath"),
  "CBT/Therapy" = c("cbt", "therapy", "counseling", "therapist"),
  "Diet Modification" = c("diet", "fodmap", "fiber", "nutrition"),
  "Exercise" = c("exercise", "yoga", "walk", "movement"),
  "GI Follow-up" = c("gi ", "follow-up", "follow up", "gastro")
)

intCounts <- sapply(interventions, function(keywords) {
  sum(sapply(gamePlanText, function(txt) {
    any(str_detect(tolower(txt), keywords))
  }))
})

cat("Game Plan interventions:\n")
intCountsSorted <- sort(intCounts, decreasing = TRUE)
for (i in seq_along(intCountsSorted)) {
  cat(sprintf("  %-25s: %3d (%.1f%%)\n",
    names(intCountsSorted)[i], intCountsSorted[i],
    100 * intCountsSorted[i] / length(gamePlanText)))
}


## ----goalFollowUp-------------------------------------------------------------
cat("\n=== Goal Follow-Up ===\n\n")

followUpText <- bgcc.df$goalFollowUp[!is.na(bgcc.df$goalFollowUp)]
cat("Patients with goal follow-up:", length(followUpText), "\n\n")

# Simple categorization
followUpCats <- c(
  "Yes/Achieved" = "yes|achieved|accomplish|success|doing|done|started|continue",
  "Partial/In Progress" = "partial|some|trying|working on|attempt",
  "No/Not Yet" = "no|not yet|haven't|didn't|unable"
)

for (catName in names(followUpCats)) {
  nMatch <- sum(str_detect(tolower(followUpText), followUpCats[catName]))
  cat(sprintf("  %-25s: %3d (%.1f%%)\n",
    catName, nMatch, 100 * nMatch / length(followUpText)))
}


## ----aiReview-----------------------------------------------------------------
cat("=== AI Review (Sheet 5) Exploration ===\n\n")

excelFile <- file.path(dataInputDir, "BGCC Data Sheet 031626.xlsx")
aiReview.df <- read.xlsx(excelFile, sheet = 5, colNames = TRUE)

cat("AI Review dimensions:", nrow(aiReview.df), "x", ncol(aiReview.df), "\n")
cat("Column names:", paste(colnames(aiReview.df), collapse = ", "), "\n\n")

# Check if AI codes exist or if this is just staged text
nColsWithData <- sum(sapply(aiReview.df, function(x) sum(!is.na(x)) > 0))
cat("Columns with any data:", nColsWithData, "\n")

# Show first few rows structure
cat("\nFirst 5 rows preview:\n")
for (j in 1:min(ncol(aiReview.df), 5)) {
  vals <- head(aiReview.df[[j]], 3)
  cat(sprintf("  [%d] %s: %s\n", j, colnames(aiReview.df)[j],
    paste(substr(as.character(vals), 1, 60), collapse = " | ")))
}

# If AI codes exist alongside survey text, assess agreement with Consensus
# The AI Review sheet appears to primarily contain raw survey text staged for
# AI-assisted coding. Document availability for methods section.
cat("\nNote: AI Review sheet contents documented for manuscript methods.\n")
cat("If AI-generated codes become available, Cohen's kappa vs Consensus\n")
cat("Review can be computed using the thematic coding columns.\n")


## ----thematicSummary----------------------------------------------------------
cat("=== Thematic Analysis Summary ===\n\n")

cat("Survey respondents:", nRespondents, "of", nrow(bgcc.df),
  sprintf("(%.1f%%)\n\n", 100 * nRespondents / nrow(bgcc.df)))

# Patients with any theme coded
nAnyCoded <- sum(rowSums(thematicRespondents[, allThemes]) > 0)
cat("Respondents with >=1 theme coded:", nAnyCoded, "of", nRespondents,
  sprintf("(%.1f%%)\n\n", 100 * nAnyCoded / nRespondents))

# Average themes per respondent (among those with any)
nThemesPerPatient <- rowSums(thematicRespondents[, allThemes])
cat("Themes per respondent: mean =", round(mean(nThemesPerPatient), 1),
  "(SD =", round(sd(nThemesPerPatient), 1),
  "), median =", median(nThemesPerPatient),
  "[", min(nThemesPerPatient), "-", max(nThemesPerPatient), "]\n\n")

# Main theme summary for manuscript text
mainOnly <- themeResults %>% filter(type == "Main Theme")
subOnly <- themeResults %>% filter(type == "Sub-Theme")

cat("Most prevalent main theme:",
  mainOnly$label[which.max(mainOnly$pct)],
  sprintf("(%.1f%%)\n", max(mainOnly$pct)))

cat("Most prevalent sub-theme:",
  subOnly$label[which.max(subOnly$pct)],
  sprintf("(%.1f%%)\n", max(subOnly$pct)))

# Export thematic results
saveRDS(themeResults, file.path(dataOutputDir,
  paste0(filenameSuffix, "_themeResults.rds")))
cat("\nTheme results saved.\n")

