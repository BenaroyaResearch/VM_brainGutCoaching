## ----setup, include=FALSE---------------------------------------------------------------------------------------------------------------------------------------------------------------------
library(knitr)
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(scales)
library(patchwork)
library(ggalluvial)
library(boot)

opts_chunk$set(
  fig.width = 13, fig.height = 7.3, cache = FALSE,
  echo = FALSE, warning = FALSE, message = FALSE,
  results = "markup"
)
options(stringsAsFactors = FALSE)

baseDir <- "/Users/tedwards/Documents/projects/VM_brainGutCoaching"
setwd(baseDir)

dataOutputDir <- file.path(baseDir, "data/outputData")
plotDir <- file.path(baseDir, "figures")

# Output figures are stamped with the date the analysis was run.
dataDate <- Sys.Date()
filenameSuffix <- paste0("VMBGCC.", dataDate)

# Input cleaned data may have been generated on a different date — locate the
# most recent matching RDS so the pipeline keeps working as the clean data
# stamp drifts forward in time.
cleanFiles <- list.files(dataOutputDir, pattern = "^VMBGCC\\..*_bgccClean\\.rds$",
  full.names = FALSE)
if (length(cleanFiles) == 0) {
  stop("No *_bgccClean.rds file found in ", dataOutputDir)
}
inputStamp <- sub("_bgccClean\\.rds$", "", sort(cleanFiles, decreasing = TRUE)[1])
cat("Input data stamp: ", inputStamp, "\n", sep = "")
cat("Output figure stamp: ", filenameSuffix, "\n", sep = "")

source(file.path(baseDir, "code/VMBGCC_functions.R"))

bgcc.df <- readRDS(file.path(dataOutputDir, paste0(inputStamp, "_bgccClean.rds")))
thematic.df <- readRDS(file.path(dataOutputDir, paste0(inputStamp, "_thematicCoding.rds")))

cat("Loaded:", nrow(bgcc.df), "patients,", nrow(thematic.df), "thematic rows\n")


## ----grand-rounds-theme-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ---- Grand Rounds palette ----
# Theme groups: khroma "high contrast" (Paul Tol) — CVD-safe for all common
# color vision deficiencies, distinguishable in grayscale.
# Severity: Paul Tol "sunset" diverging, 4 ordered stops (cool = better,
# warm = worse). CVD-safe and ordinal semantics read at a glance.
grColors <- list(
  pre = "#004488",
  post = "#BB5566",
  mainTheme = "#004488",
  subTheme = "#DDAA33",
  flow = "#004488",
  caveat = "#AA3377",
  severity = c(
    "Remission" = "#4A7BB7",
    "Mild"      = "#98CAE1",
    "Moderate"  = "#F67E4B",
    "Severe"    = "#A50026"
  ),
  themeGroup = c(
    "Positive Community Atmosphere"                     = "#004488",
    "Collaborative Engaging Educational Environment"    = "#DDAA33",
    "Equipping Patients with Hope and Actionable Tools" = "#BB5566"
  )
)

# ---- Grand Rounds ggplot theme (projector-safe, base_size = 16) ----
theme_grandRounds <- function(base_size = 16) {
  theme_minimal(base_size = base_size) %+replace%
    theme(
      plot.title = element_text(size = base_size + 4, face = "bold", hjust = 0,
        margin = margin(b = 6)),
      plot.subtitle = element_text(size = base_size, hjust = 0, color = "grey30",
        margin = margin(b = 10)),
      plot.caption = element_text(size = base_size - 2, hjust = 0, color = "grey30",
        margin = margin(t = 8)),
      axis.title = element_text(size = base_size, face = "bold"),
      axis.text = element_text(size = base_size - 1, color = "grey20"),
      legend.title = element_text(size = base_size - 1, face = "bold"),
      legend.text = element_text(size = base_size - 1),
      legend.position = "bottom",
      panel.grid.minor = element_blank(),
      strip.text = element_text(size = base_size, face = "bold"),
      plot.margin = margin(14, 18, 12, 14)
    )
}

# Convenience wrapper for 16:9 slide-fill saves (default 13 x 7.3 in)
gr_save <- function(plot, filename, height = 7.3, width = 13) {
  savePlot(plot, plotDir, filename, height = height, width = width)
}

# ---- Theme vectors and labels ----
# NOTE: Data column names retain legacy identifiers (themePositiveSharedExperience,
# themePatientEmpowerment, themePatientActivation) for compatibility with the
# cleaned RDS. Display labels reflect the clinician-researcher consensus
# overarching/theme/subtheme structure (see DDW 2026 poster).
#
# Overarching theme: Patient Empowerment
#   Theme 1: Positive Community Atmosphere               (53.2%)
#   Theme 2: Collaborative Engaging Educational Environment (86.2%)
#   Theme 3: Equipping Patients with Hope and Actionable Tools for
#            Self-directed Care                          (73.4%)
mainThemes <- c("themePositiveSharedExperience", "themePatientEmpowerment",
  "themePatientActivation")
subThemes <- c("subIsolationReduced", "subValidation", "subSharedCommunity",
  "subChangeNegHealthcare", "subGratitude", "subEnjoymentPositive",
  "subContent", "subTeachingCoachingStyle", "subCoachingStructure",
  "subSelfEfficacy", "subAgencyKnowledgeSkills", "subAgencyActionableTools")
allThemes <- c(mainThemes, subThemes)

overarchingTheme <- "Patient Empowerment"

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

# Short labels for tight layouts (e.g., voices tiles)
themeLabelsShort <- c(
  themePositiveSharedExperience = "Positive Community\nAtmosphere",
  themePatientEmpowerment       = "Collaborative Engaging\nEducational Environment",
  themePatientActivation        = "Hope &\nActionable Tools"
)

subToMain <- c(
  subIsolationReduced       = "Positive Community Atmosphere",
  subValidation             = "Positive Community Atmosphere",
  subSharedCommunity        = "Positive Community Atmosphere",
  subChangeNegHealthcare    = "Positive Community Atmosphere",
  subGratitude              = "Positive Community Atmosphere",
  subEnjoymentPositive      = "Positive Community Atmosphere",
  subContent                = "Collaborative Engaging Educational Environment",
  subTeachingCoachingStyle  = "Collaborative Engaging Educational Environment",
  subCoachingStructure      = "Collaborative Engaging Educational Environment",
  subSelfEfficacy           = "Equipping Patients with Hope and Actionable Tools",
  subAgencyKnowledgeSkills  = "Equipping Patients with Hope and Actionable Tools",
  subAgencyActionableTools  = "Equipping Patients with Hope and Actionable Tools"
)

themeOrder <- c(
  "Positive Community Atmosphere",
  "Collaborative Engaging Educational Environment",
  "Equipping Patients with Hope and Actionable Tools",
  # Theme 1 subthemes
  "Gratitude", "Isolation Reduced", "Positive Experience",
  "Validation", "Shared Community", "Change from Negative Healthcare Experiences",
  # Theme 2 subthemes
  "Presentation Content", "Virtual Coaching Class Format",
  "Presenter Teaching/Coaching Style",
  # Theme 3 subthemes
  "Patient Agency (Knowledge, Skills)", "Patient Agency (Actionable Tools)",
  "Patient Self-Efficacy"
)

# Pre-compute respondent subset reused across chunks
themeRespondents <- thematic.df %>%
  filter(!is.na(surveyLiked) & tolower(surveyLiked) != "did not respond")
nThemeResp <- nrow(themeRespondents)


## ----slide1-cohort, fig.width=13, fig.height=7.3----------------------------------------------------------------------------------------------------------------------------------------------
N <- nrow(bgcc.df)
nF <- sum(bgcc.df$sex == "F", na.rm = TRUE)
nM <- sum(bgcc.df$sex == "M", na.rm = TRUE)
nOther <- N - nF - nM
meanAge <- mean(bgcc.df$age, na.rm = TRUE)
sdAge <- sd(bgcc.df$age, na.rm = TRUE)
nClasses <- length(unique(na.omit(bgcc.df$classDate)))
dateMin <- format(min(bgcc.df$classDate, na.rm = TRUE), "%b %Y")
dateMax <- format(max(bgcc.df$classDate, na.rm = TRUE), "%b %Y")

# --- Panel A: Sex (three separate horizontal bars) ---
sexData <- data.frame(
  group = factor(c("Female", "Male", "Other / Unknown"),
    levels = c("Other / Unknown", "Male", "Female")),
  n = c(nF, nM, nOther)
) %>% mutate(pct = 100 * n / sum(n))

pSex <- ggplot(sexData, aes(x = group, y = n, fill = group)) +
  geom_col(width = 0.6) +
  geom_text(aes(label = sprintf("%d (%.0f%%)", n, pct)),
    hjust = -0.1, size = 5, fontface = "bold") +
  scale_fill_manual(values = c("Female" = "#4477AA", "Male" = "#EE6677",
    "Other / Unknown" = "grey60")) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.55))) +
  coord_flip() +
  labs(x = NULL, y = NULL, title = "Sex") +
  theme_grandRounds() +
  theme(legend.position = "none",
    axis.text.x = element_blank(),
    panel.grid = element_blank(),
    plot.title = element_text(size = 16, face = "bold"))

# --- Panel B: Age histogram ---
pAge <- ggplot(bgcc.df, aes(x = age)) +
  geom_histogram(binwidth = 5, fill = grColors$flow, color = "white",
    boundary = 20) +
  geom_vline(xintercept = meanAge, linetype = "dashed", linewidth = 0.8,
    color = grColors$caveat) +
  annotate("label", x = meanAge + 1, y = Inf,
    label = sprintf("Mean %.0f (SD %.0f)", meanAge, sdAge),
    hjust = 0, vjust = 1.2, color = grColors$caveat,
    fontface = "bold", size = 5,
    label.size = 0, fill = alpha("white", 0.85)) +
  labs(x = "Age (years)", y = "Patients", title = "Age Distribution") +
  theme_grandRounds() +
  theme(plot.title = element_text(size = 16, face = "bold"))

# --- Panel C: Top diagnoses ---
dxCols <- c(IBS_C = "IBS-C", IBS_D = "IBS-D", IBS_M = "IBS-M",
  functionalDyspepsia = "Functional Dyspepsia",
  chronicIdiopathicConstipation = "Chronic Idiopathic Constipation",
  functionalAbdominalPain = "Functional Abdominal Pain",
  functionalBloating = "Functional Bloating")

dxData <- data.frame(
  diagnosis = unname(dxCols),
  n = sapply(names(dxCols), function(d) sum(bgcc.df[[d]] == 1, na.rm = TRUE)),
  stringsAsFactors = FALSE
) %>%
  mutate(pct = 100 * n / N) %>%
  arrange(desc(n)) %>%
  slice_head(n = 6) %>%
  mutate(diagnosis = factor(diagnosis, levels = rev(diagnosis)))

pDx <- ggplot(dxData, aes(x = diagnosis, y = pct)) +
  geom_col(fill = grColors$mainTheme, width = 0.7) +
  geom_text(aes(label = sprintf("%d (%.0f%%)", n, pct)),
    hjust = -0.1, size = 5, fontface = "bold") +
  coord_flip() +
  scale_y_continuous(expand = expansion(mult = c(0, 0.35)),
    labels = function(x) paste0(x, "%")) +
  labs(x = NULL, y = "% of cohort", title = "Top DGBI Diagnoses") +
  theme_grandRounds() +
  theme(plot.title = element_text(size = 16, face = "bold"),
    panel.grid.major.y = element_blank())

figCohort <- (pSex / pAge) | pDx
medDx <- median(bgcc.df$nDiagnoses, na.rm = TRUE)
figCohort <- figCohort +
  plot_layout(widths = c(1, 1.2)) +
  plot_annotation(
    title = sprintf("Brain-Gut Coaching Class Cohort (N = %d)", N),
    subtitle = sprintf("%d virtual classes, %s – %s | %.0f%% female | median %d DGBI %s per patient",
      nClasses, dateMin, dateMax,
      100 * nF / N, medDx, ifelse(medDx == 1, "diagnosis", "diagnoses")),
    theme = theme_grandRounds()
  )

print(figCohort)
gr_save(figCohort, "gr_cohortSnapshot")


## ----slide2-flow, fig.width=13, fig.height=7.3------------------------------------------------------------------------------------------------------------------------------------------------
nResp <- sum(bgcc.df$respondedToSurvey, na.rm = TRUE)
nIBS <- sum(!is.na(bgcc.df$preIBSSSS) & !is.na(bgcc.df$postIBSSSS))
nPHQ <- sum(!is.na(bgcc.df$prePHQ2) & !is.na(bgcc.df$postPHQ2))
nGAD <- sum(!is.na(bgcc.df$preGAD7) & !is.na(bgcc.df$postGAD7))

# Three-stage horizontal flow: Pre -> Class -> Post
flowNodes <- data.frame(
  x = c(1, 3, 5),
  y = c(3, 3, 3),
  width = c(1.6, 1.8, 1.6),
  height = c(2.2, 2.6, 2.6),
  fill = c(grColors$pre, grColors$mainTheme, grColors$post),
  title = c("Pre-Class Surveys",
    "90-min Virtual\nBrain-Gut Coaching Class",
    "Post-Class Surveys\n& Outcomes"),
  body = c(
    "IBS-SSS, PHQ-2, GAD-7\nDemographics, diagnoses",
    "Brain-gut education\nShared experience\nMicro-goal setting\nBrain Gut Game Plan",
    sprintf("Survey respondents:\n%d / %d (%.0f%%)\n\nPaired outcomes:\nIBS-SSS  n = %d\nPHQ-2    n = %d\nGAD-7    n = %d",
      nResp, nrow(bgcc.df), 100 * nResp / nrow(bgcc.df),
      nIBS, nPHQ, nGAD)
  ),
  stringsAsFactors = FALSE
)

# Arrows between nodes
arrows <- data.frame(
  x = c(1.8, 3.9),
  xend = c(2.1, 4.2),
  y = c(3, 3), yend = c(3, 3)
)

pFlow <- ggplot() +
  # Boxes
  geom_tile(data = flowNodes, aes(x = x, y = y, width = width, height = height,
    fill = fill), color = NA, alpha = 0.18) +
  geom_tile(data = flowNodes, aes(x = x, y = y, width = width, height = height),
    fill = NA, color = flowNodes$fill, linewidth = 1.4) +
  # Titles
  geom_text(data = flowNodes,
    aes(x = x, y = y + height / 2 - 0.25, label = title),
    fontface = "bold", size = 6, color = "grey15", lineheight = 0.95) +
  # Bodies
  geom_text(data = flowNodes,
    aes(x = x, y = y - 0.1, label = body),
    size = 5.2, color = "grey20", lineheight = 1.1) +
  # Arrows
  geom_segment(data = arrows, aes(x = x, xend = xend, y = y, yend = yend),
    arrow = arrow(length = unit(0.35, "cm"), type = "closed"),
    linewidth = 1.1, color = "grey40") +
  # Cohort header
  annotate("text", x = 3, y = 5.0,
    label = sprintf("N = %d adults with DGBI  |  34 classes  |  Dec 2023 – Jul 2025",
      nrow(bgcc.df)),
    size = 6.5, fontface = "bold", color = "grey15") +
  scale_fill_identity() +
  scale_x_continuous(limits = c(0, 6)) +
  scale_y_continuous(limits = c(1.2, 5.6)) +
  labs(title = "Study Design and Data Flow",
    subtitle = "Single-arm pragmatic pre/post design with paired clinical outcomes and post-class survey") +
  theme_void(base_size = 16) +
  theme(
    plot.title = element_text(size = 22, face = "bold", hjust = 0,
      margin = margin(b = 4)),
    plot.subtitle = element_text(size = 16, hjust = 0, color = "grey30",
      margin = margin(b = 10)),
    plot.margin = margin(14, 18, 12, 14)
  )

print(pFlow)
gr_save(pFlow, "gr_classAnatomy")


## ----slide3-theme-prevalence, fig.width=13, fig.height=7.5------------------------------------------------------------------------------------------------------------------------------------
themeData <- data.frame(
  theme = allThemes,
  label = themeLabels[allThemes],
  n = sapply(allThemes, function(t) sum(themeRespondents[[t]] == 1)),
  stringsAsFactors = FALSE
) %>%
  mutate(
    pct = 100 * n / nThemeResp,
    type = ifelse(theme %in% mainThemes, "Main Theme", "Sub-Theme"),
    parentTheme = ifelse(theme %in% mainThemes, themeLabels[theme], subToMain[theme])
  )

# Wilson CIs
for (i in 1:nrow(themeData)) {
  ci <- prop.test(themeData$n[i], nThemeResp, correct = FALSE)$conf.int
  themeData$ciLow[i] <- 100 * ci[1]
  themeData$ciHigh[i] <- 100 * ci[2]
}

themeData <- themeData %>%
  mutate(
    label = factor(label, levels = rev(themeOrder)),
    faceLabel = factor(ifelse(type == "Main Theme", "Main Themes", "Sub-Themes"),
      levels = c("Main Themes", "Sub-Themes"))
  )

# Plot main themes on top facet, sub-themes below — single panel keeps it readable
figThemePrev <- ggplot(themeData, aes(x = label, y = pct, fill = parentTheme)) +
  geom_col(aes(alpha = type), width = 0.72) +
  geom_errorbar(aes(ymin = ciLow, ymax = ciHigh), width = 0.2,
    linewidth = 0.4, color = "grey40") +
  geom_text(aes(y = ciHigh,
    label = sprintf("%d / %d  (%.0f%%)", n, nThemeResp, pct)),
  hjust = -0.12, size = 5, fontface = "bold") +
  coord_flip() +
  scale_fill_manual(values = grColors$themeGroup, guide = "none") +
  scale_alpha_manual(values = c("Main Theme" = 1, "Sub-Theme" = 0.55),
    guide = "none") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.32)),
    labels = function(x) paste0(x, "%")) +
  facet_grid(faceLabel ~ ., scales = "free_y", space = "free_y") +
  labs(
    x = NULL, y = "Prevalence (% of respondents)",
    title = "Patient Empowerment: Three Themes from Patient Voices",
    subtitle = sprintf("Thematic analysis of open-ended survey responses (N = %d respondents)",
      nThemeResp),
    caption = "Overarching theme: Patient Empowerment. Error bars: Wilson 95% CI."
  ) +
  theme_grandRounds() +
  theme(panel.grid.major.y = element_blank(),
    strip.text.y = element_text(angle = 0, face = "bold", size = 15,
      margin = margin(l = 6, r = 6)),
    strip.background = element_rect(fill = "grey92", color = NA),
    plot.title = element_text(hjust = 0.5),
    plot.subtitle = element_text(hjust = 0.5),
    plot.title.position = "plot",
    plot.caption.position = "plot")

print(figThemePrev)
gr_save(figThemePrev, "gr_themePrevalence", height = 7.5, width = 13)


## ----slide4-voices, fig.width=13, fig.height=7.3----------------------------------------------------------------------------------------------------------------------------------------------
quotesFile <- file.path(baseDir, "code/grandRounds_quotes.csv")
quotes.df <- read.csv(quotesFile, stringsAsFactors = FALSE)

# Establish row order matching theme prevalence ordering.
# CSV may use either the full theme name or a shortened variant (e.g. dropping
# the trailing "for Self-directed Care"). Normalize to the long display name.
quoteThemeAlias <- c(
  "Equipping Patients with Hope and Actionable Tools" =
    "Equipping Patients with Hope and Actionable Tools",
  "Equipping Patients with Hope and Actionable Tools for Self-directed Care" =
    "Equipping Patients with Hope and Actionable Tools"
)
quotes.df$theme <- ifelse(quotes.df$theme %in% names(quoteThemeAlias),
  quoteThemeAlias[quotes.df$theme], quotes.df$theme)
quotes.df$theme <- factor(quotes.df$theme,
  levels = c(
    "Positive Community Atmosphere",
    "Collaborative Engaging Educational Environment",
    "Equipping Patients with Hope and Actionable Tools"
))
quotes.df <- quotes.df %>% arrange(theme)

# Assign within-theme position (top to bottom within a theme block).
# Limit to first 2 quotes per theme so each band stays readable; remaining
# quotes in the CSV are preserved as backup for slide-deck-only swaps.
quotes.df <- quotes.df %>%
  group_by(theme) %>%
  slice_head(n = 2) %>%
  mutate(rowInTheme = row_number(),
    nInTheme = n()) %>%
  ungroup()

# Each theme block occupies vertical band [theme_y - 0.45, theme_y + 0.45]
# Map theme to y center
themeY <- c(
  "Positive Community Atmosphere" = 3,
  "Collaborative Engaging Educational Environment" = 2,
  "Equipping Patients with Hope and Actionable Tools" = 1
)
quotes.df$themeY <- themeY[as.character(quotes.df$theme)]
# Stagger quotes vertically within a theme block
quotes.df$y <- quotes.df$themeY +
  (quotes.df$rowInTheme - (quotes.df$nInTheme + 1) / 2) * 0.35

# Theme prevalence labels for left column
themeCounts <- sapply(mainThemes, function(t) sum(themeRespondents[[t]] == 1))
themePcts <- round(100 * themeCounts / nThemeResp)
themeBlocks <- data.frame(
  theme = themeLabels[mainThemes],
  y = themeY[themeLabels[mainThemes]],
  n = themeCounts,
  pct = themePcts,
  fill = grColors$themeGroup[themeLabels[mainThemes]],
  stringsAsFactors = FALSE
)

# Use pre-defined short labels for tile display (long consensus names won't
# fit cleanly in a 2.2-wide tile).
themeBlocks$themeWrapped <- themeLabelsShort[mainThemes]

pVoices <- ggplot() +
  # Theme label blocks (left)
  geom_tile(data = themeBlocks,
    aes(x = 1.55, y = y, fill = fill),
    width = 2.95, height = 0.85, alpha = 0.88) +
  geom_text(data = themeBlocks,
    aes(x = 1.55, y = y + 0.13, label = themeWrapped),
    color = "white", fontface = "bold", size = 5.0, lineheight = 0.95) +
  geom_text(data = themeBlocks,
    aes(x = 1.55, y = y - 0.24,
      label = sprintf("%d / %d  (%d%%)", n, nThemeResp, pct)),
    color = "white", size = 4.6) +
  # Quotation marks
  geom_text(data = quotes.df,
    aes(x = 3.25, y = y, color = as.character(theme)),
    label = "\u201C", size = 14, fontface = "bold", hjust = 0, vjust = 0.55) +
  # Quote text
  geom_text(data = quotes.df,
    aes(x = 3.75, y = y, label = str_wrap(quote, width = 60)),
    hjust = 0, vjust = 0.5, size = 5.0, color = "grey15",
    fontface = "italic", lineheight = 1.05) +
  scale_fill_identity() +
  scale_color_manual(values = grColors$themeGroup, guide = "none") +
  scale_x_continuous(limits = c(0, 11.5)) +
  scale_y_continuous(limits = c(0.4, 3.6)) +
  labs(
    title = "Voices: Representative Patient Quotes",
    subtitle = "Overarching theme: Patient Empowerment | Selected exemplars from post-class open-ended survey responses",
    caption = "Quotes edited only for de-identification, grammar, and length; meaning preserved."
  ) +
  theme_void(base_size = 16) +
  theme(
    plot.title = element_text(size = 22, face = "bold", hjust = 0,
      margin = margin(b = 4)),
    plot.subtitle = element_text(size = 16, hjust = 0, color = "grey30",
      margin = margin(b = 12)),
    plot.caption = element_text(size = 13, hjust = 0, color = "grey40",
      margin = margin(t = 10)),
    plot.margin = margin(14, 18, 12, 14)
  )

print(pVoices)
gr_save(pVoices, "gr_voices")


## ----slide5-microgoals, fig.width=13, fig.height=7.3------------------------------------------------------------------------------------------------------------------------------------------
goalsText <- bgcc.df$microGoals[!is.na(bgcc.df$microGoals)]
nGoals <- length(goalsText)

goalCategories <- list(
  "Exercise / Movement" = c("exercise", "walk", "walking", "yoga", "stretch",
    "move", "movement", "physical", "hike", "run", "swim", "gym", "steps"),
  "Mindfulness / Meditation" = c("mindful", "meditat", "breath", "relax",
    "calm", "deep breath", "diaphragm"),
  "Diet / Nutrition" = c("diet", "eat", "food", "meal", "fiber", "water",
    "hydrat", "nutrition", "fodmap", "drink"),
  "Sleep / Rest" = c("sleep", "rest", "bedtime", "nap"),
  "Social Activity" = c("social", "friend", "family", "connect", "community",
    "group", "talk", "spend time"),
  "Screen Time Reduction" = c("screen", "phone", "device", "tv",
    "social media", "limit"),
  "Stress Management" = c("stress", "journal", "writing", "gratitude",
    "self-care", "selfcare"),
  "App / Tool Use" = c("nerva", "mahana", "calmigo", "app")
)

goalCounts <- sapply(goalCategories, function(keywords) {
  sum(sapply(goalsText, function(txt) any(str_detect(tolower(txt), keywords))))
})

goalData <- data.frame(
  category = names(goalCounts),
  n = as.integer(goalCounts),
  pct = 100 * goalCounts / nGoals,
  stringsAsFactors = FALSE
) %>% arrange(desc(n))
goalData$category <- factor(goalData$category, levels = rev(goalData$category))

figGoals <- ggplot(goalData, aes(x = category, y = pct)) +
  geom_col(fill = grColors$mainTheme, width = 0.72) +
  geom_text(aes(label = sprintf("%d  (%.0f%%)", n, pct)),
    hjust = -0.1, size = 5.2, fontface = "bold") +
  coord_flip() +
  scale_y_continuous(expand = expansion(mult = c(0, 0.25)),
    labels = function(x) paste0(x, "%")) +
  labs(
    x = NULL, y = "% of patients with micro-goals",
    title = "Patient-Set Micro-Goals During the Class",
    subtitle = sprintf("Self-directed goals set by patients (N = %d goal-setters)", nGoals),
    caption = "Categories derived by keyword matching; a goal may map to >1 category."
  ) +
  theme_grandRounds() +
  theme(panel.grid.major.y = element_blank())

print(figGoals)
gr_save(figGoals, "gr_microGoals")


## ----outcomes-helpers-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Bootstrap mean CI helper
bootMeanCI <- function(x, R = 2000) {
  set.seed(42)
  b <- boot(x, function(d, i) mean(d[i]), R = R)
  ci <- boot.ci(b, type = "perc")$percent[4:5]
  list(mean = mean(x), ciLow = ci[1], ciHigh = ci[2])
}

# Reusable estimation plot panel (paired spaghetti left + delta strip right)
makeEstimationPanel <- function(df, preCol, postCol, scoreLabel,
                                responderThreshold = NULL,
                                thresholds = NULL, threshColors = NULL,
                                base = 16) {
  paired <- df %>%
    filter(!is.na(.data[[preCol]]) & !is.na(.data[[postCol]])) %>%
    mutate(delta = .data[[postCol]] - .data[[preCol]])
  nP <- nrow(paired)
  m <- bootMeanCI(paired$delta)

  long <- paired %>%
    select(patientCode, !!sym(preCol), !!sym(postCol)) %>%
    pivot_longer(c(!!sym(preCol), !!sym(postCol)),
      names_to = "tp", values_to = "score") %>%
    mutate(time = factor(ifelse(grepl("pre", tp), "Pre", "Post"),
      levels = c("Pre", "Post")))

  pL <- ggplot(long, aes(x = time, y = score)) +
    geom_line(aes(group = patientCode), alpha = 0.22,
      color = "grey45", linewidth = 0.4) +
    geom_point(alpha = 0.25, size = 1.2, color = "grey45") +
    stat_summary(aes(group = 1), fun = mean, geom = "line",
      color = "black", linewidth = 1.8) +
    stat_summary(aes(group = 1), fun = mean, geom = "point",
      color = "black", size = 4, shape = 18) +
    labs(x = NULL, y = scoreLabel) +
    theme_grandRounds(base_size = base) +
    theme(panel.grid.major.x = element_blank())

  if (!is.null(thresholds)) {
    for (i in seq_along(thresholds)) {
      pL <- pL + geom_hline(yintercept = thresholds[i], linetype = "dashed",
        color = threshColors[i], alpha = 0.55)
    }
  }

  subtitleTxt <- sprintf("N = %d  |  Mean \u0394 = %.1f  [%.1f, %.1f]",
    nP, m$mean, m$ciLow, m$ciHigh)

  if (!is.null(responderThreshold)) {
    nR <- sum(paired$delta <= responderThreshold)
    subtitleTxt <- paste0(subtitleTxt,
      sprintf("\nResponders (\u0394 \u2264 %d): %d/%d (%.0f%%)",
        responderThreshold, nR, nP, 100 * nR / nP))
  }

  pL <- pL + labs(title = scoreLabel, subtitle = subtitleTxt)
  pL
}


## ----slide6-outcomes-composite, fig.width=15, fig.height=7.3----------------------------------------------------------------------------------------------------------------------------------
pIBS <- makeEstimationPanel(bgcc.df, "preIBSSSS", "postIBSSSS", "IBS-SSS",
  responderThreshold = -50,
  thresholds = c(75, 175, 300),
  threshColors = c("#228833", "#CCBB44", "#AA3377"), base = 15)
pPHQ <- makeEstimationPanel(bgcc.df, "prePHQ2", "postPHQ2", "PHQ-2",
  thresholds = 3, threshColors = "#AA3377", base = 15)
pGAD <- makeEstimationPanel(bgcc.df, "preGAD7", "postGAD7", "GAD-7",
  thresholds = c(5, 10, 15),
  threshColors = c("#CCBB44", "#EE6677", "#AA3377"), base = 15)

figOutcomes <- pIBS + pPHQ + pGAD +
  plot_layout(widths = c(1.1, 1, 1)) +
  plot_annotation(
    title = "Pre / Post Clinical Outcomes",
    subtitle = "Paired spaghetti with overall mean trajectory; dashed lines = clinical severity thresholds",
    theme = theme_grandRounds(base_size = 16)
  )

print(figOutcomes)
gr_save(figOutcomes, "gr_outcomesComposite", height = 7.3, width = 15)


## ----slide6b-outcomes-ibs-solo, fig.width=13, fig.height=7.3----------------------------------------------------------------------------------------------------------------------------------
pIBSsolo <- makeEstimationPanel(bgcc.df, "preIBSSSS", "postIBSSSS", "IBS-SSS",
  responderThreshold = -50,
  thresholds = c(75, 175, 300),
  threshColors = c("#228833", "#CCBB44", "#AA3377"), base = 17)

figIBSSolo <- pIBSsolo +
  labs(
    title = "IBS Symptom Severity (IBS-SSS), Pre vs Post",
    subtitle = sprintf("%s\nDashed lines: Mild (75), Moderate (175), Severe (300) thresholds",
      pIBSsolo$labels$subtitle)
  ) +
  theme_grandRounds(base_size = 17)

print(figIBSSolo)
gr_save(figIBSSolo, "gr_outcomesIBSSolo")


## ----slide7-heatmap, fig.width=13, fig.height=7.8---------------------------------------------------------------------------------------------------------------------------------------------
# Merge thematic coding with clinical data
themeOutcome.df <- bgcc.df %>%
  inner_join(themeRespondents %>% select(patientCode, all_of(allThemes)),
    by = "patientCode")

outcomes <- c("deltaIBSSSS", "deltaPHQ2", "deltaGAD7")
outcomeLabels <- c(deltaIBSSSS = "IBS-SSS Δ", deltaPHQ2 = "PHQ-2 Δ",
  deltaGAD7 = "GAD-7 Δ")

# Use a lightweight rank-biserial computation (avoid loading effectsize here)
rankBis <- function(x, y) {
  # x = theme present, y = theme absent
  n1 <- length(x)
  n0 <- length(y)
  if (n1 < 3 || n0 < 3) return(c(r = NA, ciLow = NA, ciHigh = NA))
  w <- suppressWarnings(wilcox.test(x, y, conf.int = TRUE, exact = FALSE))
  U <- w$statistic
  r <- as.numeric(1 - 2 * U / (n1 * n0))
  # Simple Fisher-z CI on r
  z <- atanh(max(min(r, 0.999), -0.999))
  se <- sqrt(1 / (n1 + n0 - 3))
  c(r = r, ciLow = tanh(z - 1.96 * se), ciHigh = tanh(z + 1.96 * se))
}

allEffects <- list()
for (theme in allThemes) {
  for (outcome in outcomes) {
    sub <- themeOutcome.df %>% filter(!is.na(.data[[outcome]]))
    g0 <- sub[[outcome]][sub[[theme]] == 0]
    g1 <- sub[[outcome]][sub[[theme]] == 1]
    rb <- rankBis(g1, g0)
    allEffects[[length(allEffects) + 1]] <- data.frame(
      theme = theme,
      themeLabel = themeLabels[theme],
      parentTheme = ifelse(theme %in% mainThemes,
        themeLabels[theme], subToMain[theme]),
      outcomeLabel = outcomeLabels[outcome],
      n0 = length(g0), n1 = length(g1),
      r = rb["r"], rCIlow = rb["ciLow"], rCIhigh = rb["ciHigh"],
      stringsAsFactors = FALSE
    )
  }
}
allEffects <- bind_rows(allEffects)

heatData <- allEffects %>%
  mutate(
    themeLabel = factor(themeLabel, levels = rev(themeOrder)),
    parentTheme = factor(parentTheme, levels = c(
      "Positive Community Atmosphere",
      "Collaborative Engaging Educational Environment",
      "Equipping Patients with Hope and Actionable Tools"
    )),
    outcomeLabel = factor(outcomeLabel,
      levels = c("IBS-SSS Δ", "PHQ-2 Δ", "GAD-7 Δ")),
    sigMarker = ifelse(!is.na(rCIlow) & !is.na(rCIhigh) &
      ((rCIlow > 0 & rCIhigh > 0) | (rCIlow < 0 & rCIhigh < 0)),
    "*", ""),
    cellLabel = ifelse(is.na(r), "NA", sprintf("%+.2f%s", r, sigMarker))
  )

figHeatmap <- ggplot(heatData, aes(x = outcomeLabel, y = themeLabel, fill = r)) +
  geom_tile(color = "white", linewidth = 0.7) +
  geom_text(aes(label = cellLabel),
    size = 5, color = "black", fontface = "bold") +
  scale_fill_gradient2(
    low = "#2166AC", mid = "white", high = "#D6604D",
    midpoint = 0, limits = c(-1, 1), na.value = "grey55",
    breaks = c(-1, -0.5, 0, 0.5, 1),
    labels = c("-1.0", "-0.5", "0", "+0.5", "+1.0"),
    name = "Rank-biserial r",
    guide = guide_colorbar(
      barwidth = 14, barheight = 0.9,
      title.position = "top", title.hjust = 0.5,
      label.theme = element_text(size = 12)
    )
  ) +
  facet_grid(parentTheme ~ ., scales = "free_y", space = "free_y",
    switch = "y", labeller = labeller(parentTheme = label_wrap_gen(18))) +
  labs(
    x = NULL, y = NULL,
    title = "Exploratory: Theme Presence \u00d7 Clinical Outcome Change",
    subtitle = "Negative r (blue) = theme-present group improved more   |   * = 95% CI excludes zero",
    caption = "Exploratory \u2014 no causal inference. No multiplicity correction across sub-themes."
  ) +
  theme_grandRounds(base_size = 15) +
  theme(
    axis.text.x = element_text(size = 15),
    panel.grid = element_blank(),
    panel.spacing.y = unit(6, "pt"),
    strip.placement = "outside",
    strip.background = element_rect(fill = "grey92", color = NA),
    strip.text.y.left = element_text(angle = 0, face = "bold",
      size = 12, hjust = 1, margin = margin(r = 8, l = 4)),
    plot.title = element_text(hjust = 0.5),
    plot.subtitle = element_text(hjust = 0.5),
    plot.title.position = "plot",
    plot.caption.position = "plot",
    legend.position = "bottom"
  )

print(figHeatmap)
gr_save(figHeatmap, "gr_themeOutcomeHeatmap", height = 7.8, width = 13)


## ----slide7b-heatmap-unpack, fig.width=14, fig.height=7.8-------------------------------------------------------------------------------------------------------------------------------------
# Goal: put raw clinical numbers on the heatmap signals. For each "interesting"
# theme, show (a) baseline IBS-SSS and (b) Delta IBS-SSS for theme-present vs
# theme-absent groups, with bootstrap 95% CIs. This tests two speculations:
#   - Negative-r cells (e.g., Validation, Self-Efficacy, Agency): theme-present
#     patients improved more in raw points.
#   - Positive-r cells (e.g., Presentation Content, Positive Experience):
#     theme-present patients may have started with lower baseline burden
#     (ceiling/floor artifact) rather than benefiting less from the class.

# Themes selected for this view: those whose IBS-SSS cell in the heatmap was
# either CI-significant or part of a directionally coherent cluster.
unpackThemes <- c(
  "subValidation",
  "subSelfEfficacy",
  "subAgencyKnowledgeSkills",
  "themePatientActivation",
  "subEnjoymentPositive",
  "subContent",
  "themePatientEmpowerment",
  "subIsolationReduced"
)

unpackData <- themeOutcome.df %>%
  filter(!is.na(preIBSSSS) & !is.na(postIBSSSS))

# Long-form: one row per (theme, presence, patient)
unpackLong <- bind_rows(lapply(unpackThemes, function(t) {
  unpackData %>%
    transmute(
      theme = t,
      themeLabel = themeLabels[t],
      parentTheme = ifelse(t %in% mainThemes,
        themeLabels[t], subToMain[t]),
      presence = ifelse(.data[[t]] == 1, "Theme present", "Theme absent"),
      preIBSSSS = preIBSSSS,
      deltaIBSSSS = deltaIBSSSS
    )
}))

# Bootstrap mean + 95% CI for both baseline and delta, by theme x presence
summariseMean <- function(x) {
  ci <- bootMeanCI(x)
  data.frame(mean = ci$mean, ciLow = ci$ciLow, ciHigh = ci$ciHigh,
    n = length(x))
}

unpackSummary <- unpackLong %>%
  group_by(theme, themeLabel, parentTheme, presence) %>%
  summarise(
    base = list(summariseMean(preIBSSSS)),
    delta = list(summariseMean(deltaIBSSSS)),
    .groups = "drop"
  ) %>%
  mutate(
    baseMean   = sapply(base,  function(x) x$mean),
    baseLow    = sapply(base,  function(x) x$ciLow),
    baseHigh   = sapply(base,  function(x) x$ciHigh),
    deltaMean  = sapply(delta, function(x) x$mean),
    deltaLow   = sapply(delta, function(x) x$ciLow),
    deltaHigh  = sapply(delta, function(x) x$ciHigh),
    n          = sapply(base,  function(x) x$n)
  ) %>%
  select(-base, -delta)

# Order themes by parent group, then by signal of interest (validation first)
themeDisplayOrder <- rev(c(
  "Validation",
  "Isolation Reduced",
  "Collaborative Engaging Educational Environment",
  "Presentation Content",
  "Positive Experience",
  "Equipping Patients with Hope and Actionable Tools",
  "Patient Agency (Knowledge, Skills)",
  "Patient Self-Efficacy"
))
unpackSummary <- unpackSummary %>%
  mutate(
    themeLabel = factor(themeLabel, levels = themeDisplayOrder),
    presence = factor(presence, levels = c("Theme absent", "Theme present"))
  )

presenceColors <- c("Theme absent" = "grey55", "Theme present" = "#004488")

# Position labels at the *outside* end of each CI bar so they never overlap
# the bar itself; dodge keeps the two presence groups vertically separated.
dodgeW <- 0.6

# ---- Panel A: Baseline IBS-SSS ----
pBase <- ggplot(unpackSummary,
  aes(x = baseMean, y = themeLabel, color = presence)) +
  geom_vline(xintercept = mean(unpackData$preIBSSSS), linetype = "dashed",
    color = "grey55", linewidth = 0.5) +
  geom_errorbarh(aes(xmin = baseLow, xmax = baseHigh),
    height = 0, linewidth = 0.9,
    position = position_dodge(width = dodgeW)) +
  geom_point(aes(size = n), shape = 19,
    position = position_dodge(width = dodgeW)) +
  geom_text(aes(x = baseHigh, label = sprintf("%.0f  (n=%d)", baseMean, n)),
    position = position_dodge(width = dodgeW),
    hjust = -0.12, size = 3.7, show.legend = FALSE) +
  scale_color_manual(values = presenceColors, name = NULL) +
  scale_size_continuous(range = c(2.6, 5.0), guide = "none") +
  scale_x_continuous(expand = expansion(mult = c(0.05, 0.32))) +
  labs(
    x = "Baseline IBS-SSS (mean, 95% CI)", y = NULL,
    title = "A. Where did they start?",
    subtitle = "Dashed line = overall cohort baseline mean"
  ) +
  theme_grandRounds(base_size = 14) +
  theme(
    panel.grid.major.y = element_line(color = "grey92"),
    legend.position = "top",
    plot.title = element_text(size = 15),
    plot.subtitle = element_text(size = 12)
  )

# ---- Panel B: Change in IBS-SSS ----
pDelta <- ggplot(unpackSummary,
  aes(x = deltaMean, y = themeLabel, color = presence)) +
  geom_vline(xintercept = 0, color = "grey55", linewidth = 0.5) +
  geom_vline(xintercept = -50, linetype = "dotted",
    color = "#228833", linewidth = 0.6) +
  geom_errorbarh(aes(xmin = deltaLow, xmax = deltaHigh),
    height = 0, linewidth = 0.9,
    position = position_dodge(width = dodgeW)) +
  geom_point(aes(size = n), shape = 19,
    position = position_dodge(width = dodgeW)) +
  geom_text(aes(x = deltaHigh, label = sprintf("%+0.0f", deltaMean)),
    position = position_dodge(width = dodgeW),
    hjust = -0.25, size = 3.7, show.legend = FALSE) +
  scale_color_manual(values = presenceColors, name = NULL) +
  scale_size_continuous(range = c(2.6, 5.0), guide = "none") +
  scale_x_continuous(expand = expansion(mult = c(0.1, 0.32))) +
  labs(
    x = "\u0394 IBS-SSS (mean, 95% CI)", y = NULL,
    title = "B. How much did they change?",
    subtitle = "Dotted line = 50-pt responder threshold"
  ) +
  theme_grandRounds(base_size = 14) +
  theme(
    panel.grid.major.y = element_line(color = "grey92"),
    axis.text.y = element_blank(),
    legend.position = "top",
    plot.title = element_text(size = 15),
    plot.subtitle = element_text(size = 12)
  )

figUnpack <- pBase + pDelta +
  plot_layout(widths = c(1.3, 1), guides = "collect") +
  plot_annotation(
    title = "Baseline Burden vs Change, by Theme Endorsement",
    subtitle = sprintf("IBS-SSS only (n = %d patients with paired scores + coded thematic survey response); bootstrap 95%% CIs.",
      nrow(unpackData)),
    theme = theme_grandRounds(base_size = 16) +
      theme(plot.title = element_text(hjust = 0.5),
        plot.subtitle = element_text(hjust = 0.5),
        legend.position = "top")
  ) &
  theme(legend.position = "top")

print(figUnpack)
gr_save(figUnpack, "gr_heatmapUnpack", height = 7.8, width = 14)


## ----slide7c-status-change, fig.width=13, fig.height=7.3--------------------------------------------------------------------------------------------------------------------------------------
# Categorize each paired patient by direction of severity-band change.
# Pre/post bands are ordered factors: Remission < Mild < Moderate < Severe.
# - Improved: post band lower than pre band
# - No change: post band == pre band
# - Worsened: post band higher than pre band
bandLevels <- c("Remission", "Mild", "Moderate", "Severe")

statusData <- bgcc.df %>%
  filter(!is.na(preIBSSSS) & !is.na(postIBSSSS)) %>%
  mutate(
    preBand  = factor(preIBSSSSBand,  levels = bandLevels),
    postBand = factor(postIBSSSSBand, levels = bandLevels),
    bandShift = as.integer(postBand) - as.integer(preBand),
    statusChange = case_when(
      bandShift <  0 ~ "Improved IBS status",
      bandShift == 0 ~ "Stable IBS status",
      bandShift >  0 ~ "Worsened IBS status"
    ),
    statusChange = factor(statusChange,
      levels = c("Improved IBS status", "Stable IBS status", "Worsened IBS status")),
    responder = deltaIBSSSS <= -50
  )

nPaired <- nrow(statusData)
statusColors <- c(
  "Improved IBS status"  = "#004488",
  "Stable IBS status"    = "#BBBBBB",
  "Worsened IBS status"  = "#BB5566"
)

# ---- Panel A: Overall status-change distribution ----
# Three separate horizontal bars so labels can sit cleanly to the right and
# no segment ever clips a long label like "Worsened band".
overallStatus <- statusData %>%
  count(statusChange) %>%
  mutate(pct = 100 * n / sum(n)) %>%
  mutate(statusChange = factor(statusChange,
    levels = c("Worsened IBS status", "Stable IBS status", "Improved IBS status")))

pOverall <- ggplot(overallStatus,
  aes(x = statusChange, y = pct, fill = statusChange)) +
  geom_col(width = 0.65) +
  geom_text(aes(label = sprintf("%d  (%.0f%%)", n, pct)),
    hjust = -0.12, size = 4.6, fontface = "bold") +
  scale_fill_manual(values = statusColors, guide = "none") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.30)),
    labels = function(x) paste0(x, "%")) +
  coord_flip() +
  labs(
    x = NULL, y = NULL,
    title = "A. Overall IBS status change",
    subtitle = sprintf("N = %d paired patients", nPaired)
  ) +
  theme_grandRounds(base_size = 14) +
  theme(
    axis.text.x = element_blank(),
    panel.grid = element_blank(),
    plot.title = element_text(size = 15),
    plot.subtitle = element_text(size = 12)
  )

# ---- Panel B: Status-change by pre-class severity ----
byPreBand <- statusData %>%
  count(preBand, statusChange) %>%
  group_by(preBand) %>%
  mutate(pct = 100 * n / sum(n), preN = sum(n)) %>%
  ungroup()

# Add x-axis label with N per band
byPreBand <- byPreBand %>%
  mutate(preBandLab = sprintf("%s\n(n=%d)", preBand, preN),
    preBandLab = factor(preBandLab,
      levels = unique(preBandLab[order(preBand)])))

pByBand <- ggplot(byPreBand,
  aes(x = preBandLab, y = pct, fill = statusChange)) +
  geom_col(width = 0.7, color = "white", linewidth = 0.6) +
  geom_text(aes(label = ifelse(pct >= 8,
    sprintf("%d (%.0f%%)", n, pct), "")),
  position = position_stack(vjust = 0.5),
  color = "white", fontface = "bold", size = 4.0) +
  scale_fill_manual(values = statusColors, name = NULL) +
  scale_y_continuous(expand = c(0, 0), labels = function(x) paste0(x, "%")) +
  labs(
    x = "Pre-class severity band", y = "% of patients",
    title = "B. Status change by pre-class severity",
    subtitle = "Bars are 100% within each pre-class band"
  ) +
  theme_grandRounds(base_size = 14) +
  theme(
    panel.grid.major.x = element_blank(),
    plot.title = element_text(size = 15),
    plot.subtitle = element_text(size = 12),
    legend.position = "top"
  )

# ---- Panel C: Responder vs status-change cross-tab ----
respByStatus <- statusData %>%
  group_by(statusChange) %>%
  summarise(n = n(),
    nResp = sum(responder),
    pctResp = 100 * nResp / n,
    meanDelta = mean(deltaIBSSSS),
    .groups = "drop")

pResp <- ggplot(respByStatus,
  aes(x = statusChange, y = pctResp, fill = statusChange)) +
  geom_col(width = 0.65) +
  geom_text(aes(label = sprintf("%d / %d\n(%.0f%%)", nResp, n, pctResp)),
    vjust = -0.25, size = 4.6, fontface = "bold") +
  geom_text(aes(y = 0,
    label = sprintf("mean \u0394 = %+.0f", meanDelta)),
  vjust = 1.6, size = 4.0, color = "grey20") +
  scale_fill_manual(values = statusColors, guide = "none") +
  coord_cartesian(ylim = c(0, 100), clip = "off") +
  scale_y_continuous(expand = expansion(mult = c(0.12, 0.32)),
    labels = function(x) paste0(x, "%"),
    breaks = c(0, 25, 50, 75, 100)) +
  labs(
    x = NULL, y = "% meeting 50-pt responder threshold",
    title = "C. 50-pt responders within each status group",
    subtitle = "Patients without a status change can still meet the responder threshold"
  ) +
  theme_grandRounds(base_size = 14) +
  theme(
    panel.grid.major.x = element_blank(),
    plot.title = element_text(size = 15),
    plot.subtitle = element_text(size = 12)
  )

figStatus <- (pOverall / pByBand) | pResp
figStatus <- figStatus +
  plot_layout(widths = c(1.15, 1), heights = c(1, 2)) +
  plot_annotation(
    title = "IBS-SSS Severity-Status Change: Improvement, Stability, Worsening",
    subtitle = sprintf("N = %d paired patients | Status change uses IBS-SSS clinical cutoffs (Remission/Mild/Moderate/Severe)",
      nPaired),
    theme = theme_grandRounds(base_size = 16) +
      theme(plot.title = element_text(hjust = 0.5),
        plot.subtitle = element_text(hjust = 0.5))
  )

# Console summary so the numbers are easy to quote in a script.
cat("\n--- Severity-status change summary ---\n")
print(overallStatus %>% select(statusChange, n, pct))
cat("\nBy pre-class band:\n")
print(byPreBand %>% select(preBand, statusChange, n, pct))
cat("\nResponder rate within each status group:\n")
print(respByStatus)

print(figStatus)
gr_save(figStatus, "gr_statusChange", height = 7.3, width = 13)


## ----slide7d-status-by-theme, fig.width=14, fig.height=7.5------------------------------------------------------------------------------------------------------------------------------------
# Cross the three status-change groups with thematic endorsement, restricted
# to patients with both paired IBS-SSS and a coded survey response.
statusTheme.df <- statusData %>%
  inner_join(themeRespondents %>% select(patientCode, all_of(allThemes)),
    by = "patientCode")

statusGroupN <- statusTheme.df %>%
  count(statusChange, name = "groupN")
nStatusTheme <- nrow(statusTheme.df)

# Themes to show: same set used in the unpack figure for continuity.
statusThemeSet <- unpackThemes

# Long-form: rate of endorsement per (status, theme)
statusThemeLong <- bind_rows(lapply(statusThemeSet, function(t) {
  statusTheme.df %>%
    group_by(statusChange) %>%
    summarise(
      themeKey = t,
      themeLabel = themeLabels[t],
      parentTheme = ifelse(t %in% mainThemes,
        themeLabels[t], subToMain[t]),
      n = sum(.data[[t]] == 1, na.rm = TRUE),
      groupN = n(),
      pct = 100 * n / groupN,
      .groups = "drop"
    )
}))

# Order themes by the unpack-figure ordering (Validation first, Self-Efficacy last)
statusThemeLong <- statusThemeLong %>%
  mutate(themeLabel = factor(themeLabel, levels = themeDisplayOrder),
    statusChange = factor(statusChange,
      levels = c("Improved IBS status", "Stable IBS status", "Worsened IBS status")))
statusLabelN <- statusTheme.df %>%
  count(statusChange) %>%
  mutate(facetLab = sprintf("%s\n(n = %d)", statusChange, n))
labMap <- setNames(statusLabelN$facetLab, as.character(statusLabelN$statusChange))
statusThemeLong$facetLab <- factor(labMap[as.character(statusThemeLong$statusChange)],
  levels = labMap[c("Improved IBS status", "Stable IBS status", "Worsened IBS status")])

figStatusTheme <- ggplot(statusThemeLong,
  aes(x = themeLabel, y = pct, fill = statusChange)) +
  geom_col(width = 0.72) +
  geom_text(aes(label = sprintf("%d/%d  (%.0f%%)", n, groupN, pct)),
    hjust = -0.1, size = 3.7, fontface = "bold") +
  scale_fill_manual(values = statusColors, guide = "none") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.02)),
    labels = function(x) paste0(x, "%"),
    limits = c(0, 100),
    breaks = c(0, 25, 50, 75, 100),
    oob = scales::squish) +
  coord_flip(clip = "off") +
  facet_wrap(~facetLab, nrow = 1) +
  labs(
    x = NULL, y = "Endorsement rate within status group",
    title = "Themes Endorsed by Each Status-Change Group",
    subtitle = sprintf("Restricted to %d patients with paired IBS-SSS + coded survey response | Themes: heatmap-flagged set",
      nStatusTheme)
  ) +
  theme_grandRounds(base_size = 14) +
  theme(
    plot.title = element_text(hjust = 0.5),
    plot.subtitle = element_text(hjust = 0.5),
    plot.title.position = "plot",
    strip.text = element_text(face = "bold", size = 13,
      margin = margin(t = 4, b = 4)),
    strip.background = element_rect(fill = "grey92", color = NA),
    panel.grid.major.y = element_blank(),
    panel.spacing.x = unit(14, "pt")
  )

# Console summary: per-status, per-theme rate
cat("\n--- Theme endorsement by status-change group (n =", nStatusTheme,
  "with paired IBS-SSS + coded survey) ---\n")
print(statusThemeLong %>%
  select(statusChange, themeLabel, n, groupN, pct) %>%
  arrange(themeLabel, statusChange))

# Differences between Improved and Worsened, for ease of scripting
diffTbl <- statusThemeLong %>%
  filter(statusChange %in% c("Improved IBS status", "Worsened IBS status")) %>%
  select(themeLabel, statusChange, pct) %>%
  pivot_wider(names_from = statusChange, values_from = pct) %>%
  mutate(diff_ImprovedMinusWorsened = `Improved IBS status` - `Worsened IBS status`) %>%
  arrange(desc(diff_ImprovedMinusWorsened))
cat("\n--- Endorsement gap: Improved minus Worsened (percentage points) ---\n")
print(diffTbl)

print(figStatusTheme)
gr_save(figStatusTheme, "gr_statusByTheme", height = 7.5, width = 14)


## ----slide8-alluvial, fig.width=13, fig.height=7.3--------------------------------------------------------------------------------------------------------------------------------------------
ibsPaired <- bgcc.df %>%
  filter(!is.na(preIBSSSS) & !is.na(postIBSSSS)) %>%
  mutate(ibsResponder = deltaIBSSSS <= -50)

alluvialData <- ibsPaired %>%
  count(preIBSSSSBand, postIBSSSSBand) %>%
  rename(Pre = preIBSSSSBand, Post = postIBSSSSBand, Freq = n)

respBySev <- ibsPaired %>%
  group_by(preIBSSSSBand) %>%
  summarise(n = n(), nResp = sum(ibsResponder),
    pctResp = round(100 * nResp / n, 0),
    .groups = "drop")

respParts <- sprintf("%s: %d%% responders (%d/%d)",
  respBySev$preIBSSSSBand, respBySev$pctResp,
  respBySev$nResp, respBySev$n)
# Split into two lines: first half and second half of bands
nBands <- length(respParts)
mid <- ceiling(nBands / 2)
respLine <- paste0(
  paste(respParts[seq_len(mid)], collapse = "   |   "),
  "\n",
  paste(respParts[seq(mid + 1, nBands)], collapse = "   |   ")
)

figAlluvial <- ggplot(alluvialData,
  aes(axis1 = Pre, axis2 = Post, y = Freq)) +
  geom_alluvium(aes(fill = Pre), width = 1 / 3, alpha = 0.78) +
  geom_stratum(width = 1 / 3, fill = "grey92", color = "grey45") +
  geom_text(stat = "stratum", aes(label = after_stat(stratum)),
    size = 5.2, fontface = "bold") +
  scale_x_discrete(limits = c("Pre-class", "Post-class"),
    expand = c(0.15, 0.05)) +
  scale_fill_manual(values = grColors$severity, name = "Pre-class\nseverity") +
  labs(
    y = "Patients",
    title = sprintf("IBS-SSS Severity Transitions (N = %d paired)", nrow(ibsPaired)),
    subtitle = paste0("Responder = \u226550-pt decrease in IBS-SSS\n", respLine),
  ) +
  theme_grandRounds()

print(figAlluvial)
gr_save(figAlluvial, "gr_ibsAlluvial")


## ----summary----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
cat("============================================================\n")
cat("GRAND ROUNDS FIGURE OUTPUT SUMMARY\n")
cat("============================================================\n\n")
genFiles <- c(
  "gr_cohortSnapshot", "gr_classAnatomy", "gr_themePrevalence",
  "gr_voices", "gr_microGoals", "gr_outcomesComposite",
  "gr_outcomesIBSSolo", "gr_themeOutcomeHeatmap", "gr_heatmapUnpack",
  "gr_statusChange", "gr_statusByTheme", "gr_ibsAlluvial"
)
for (f in genFiles) {
  pdfPath <- file.path(plotDir, paste0(filenameSuffix, "_", f, ".pdf"))
  pngPath <- file.path(plotDir, paste0(filenameSuffix, "_", f, ".png"))
  cat(sprintf("  %-30s PDF:%s PNG:%s\n", f,
    ifelse(file.exists(pdfPath), "OK", "MISSING"),
    ifelse(file.exists(pngPath), "OK", "MISSING")))
}
cat("\nQuote source CSV: code/grandRounds_quotes.csv\n")
cat("Edit that file to refine quotes; re-run code/run_grandRounds.R to regenerate Slide 4.\n")

