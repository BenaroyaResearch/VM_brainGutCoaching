# Plan: VMBGCC Academic Poster — Analysis, Figures & Communication

## TL;DR
Push the VMBGCC analysis toward a high-quality ePoster presentation. The existing pipeline is largely complete. The work focuses on: (1) enhanced theme × clinical outcome crossed analysis (both regression and descriptive, decide communication based on power), (2) poster-ready figure design leading with thematic results, (3) clear framing of what the pilot data can/cannot claim, and (4) articulating how a prospective follow-up study addresses limitations. The investigator has a draft ePoster — we provide the analytical content, figures, and conclusions.

## Current State
- **Complete**: Table 1, pre/post outcomes (Wilcoxon, effect sizes, FDR), IBS-SSS severity transitions, theme prevalence with CIs, theme co-occurrence, micro-goals/game plan categorization, 32 publication figures
- **Partial**: Theme × outcome exploratory Mann-Whitney tests exist but are basic (no interaction models, no responder-status logistic regression, no multi-theme adjustment)
- **Missing**: Poster-consolidated figures, formal theme × outcome crossed analysis, limitations documentation in code/figures

## Steps

### Phase A: Missingness, Selection Bias & Enhanced Theme × Outcome Analysis

0. **Selection bias / missingness table (Table S1)** — HIGH PRIORITY credibility check
   - Define cohort strata: A (all attendees, N=183) → B (survey respondents, ~109) → C (paired IBS-SSS, ~47) → D (paired PHQ-2, ~131) → E (intersection: paired IBS-SSS + survey response)
   - Compare baseline characteristics across strata: age, sex, baseline IBS-SSS, IBS-SSS severity band, nDiagnoses, classDate wave (early vs late enrollment)
   - Wilcoxon (continuous) and chi-squared/Fisher (categorical) tests
   - Output: formatted comparison table for poster footnote or supplementary

1. **Check intersection sample size** — Count patients with BOTH paired IBS-SSS data AND survey response/thematic coding. This determines model complexity. *(blocks steps 2-3)*

2. **Logistic regression: IBS-SSS responder status ~ theme presence**
   - Binary outcome: responder (≥50-pt IBS-SSS decrease) vs non-responder
   - Predictors: 3 main themes (binary), adjusting for baseline IBS-SSS severity, age, sex
   - Forest plot of odds ratios with 95% CIs
   - *Note small N for paired IBS-SSS (~47) — may need to simplify model*
   - **Add**: Responder rate stratified by baseline severity band (Remission/Mild/Moderate/Severe) with Wilson CIs — responder definition most meaningful for moderate/severe baseline

3. **Multi-theme linear model for deltaIBSSSS**
   - `deltaIBSSSS ~ themePositiveSharedExperience + themePatientEmpowerment + themePatientActivation + preIBSSSS + age + sex`
   - Report standardized betas, CIs, FDR-corrected p-values
   - *Depends on step 1 feasibility assessment*

4. **Sub-theme × outcome analysis (all 12 sub-themes)** — ADJUSTED testing approach
   - Compute effect sizes (rank-biserial r + bootstrap 95% CI) for ALL 12 sub-themes × 3 delta scores (IBS-SSS, PHQ-2, GAD-7) — 36 effect sizes total
   - **Formal hypothesis tests limited to**: 3 main themes × deltaIBSSSS only (3 tests, FDR-corrected)
   - Everything else: descriptive effect sizes + bootstrap CIs, NO p-values
   - Heatmap: sub-theme × outcome effect sizes with CI markers (not significance stars)
   - Run full analysis to surface unexpected associations; decide poster display after reviewing results

5. **Micro-goal category × outcome associations** (exploratory)
   - Patients with exercise/mindfulness/diet micro-goals: compare delta scores
   - Simple descriptive (bar chart of mean delta by micro-goal category)

### Phase B: Poster Figure Consolidation

6. **Create poster-specific composite figure script** (`code/VMBGCC_poster.Rmd`)
   - Poster figures need to be larger text, higher contrast, fewer panels than manuscript figures
   - Key poster panels:
     - **Panel A**: Cohort flow / demographics summary (compact Table 1) — include counts and response rates directly on diagram (e.g., "109/183 = 60%")
     - **Panel B**: Pre/Post IBS-SSS paired plot — **Gardner-Altman estimation plot** (paired mean difference with bootstrap CI) as primary; spaghetti as supplement. More modern, less p-value focused.
     - **Panel C**: IBS-SSS alluvial severity transitions — **annotate with responder rate by baseline severity band**
     - **Panel D**: Theme prevalence bar chart (horizontal, sorted, grouped by 3 main themes with color blocks, Wilson CIs)
     - **Panel E**: Theme × outcome effect size heatmap (rank-biserial r / Cliff's delta with bootstrap CI markers, NOT p-values; label "exploratory")
     - **Panel F**: Micro-goals / game plan summary (compact)
   - The attached abstract image (Figure 1 — thematic visual with empowerment framework) is a standalone graphic, not code-generated

7. **Poster color palette and theme**
   - Consistent ggplot theme for all poster panels
   - Large axis text (≥14pt), bold titles, minimal gridlines
   - Color-blind friendly palette

8. **Create `run_poster.R`** wrapper — Auto-dependency resolution, generates all poster outputs

### Phase C: Address Methodological Concerns in Analysis

9. **IBS-SSS temporal analysis**
   - **IMPORTANT**: Post-measurement dates do NOT exist in the dataset. Only `classDate` is available. There is no `days_post_minus_pre` or similar variable. This CANNOT be addressed analytically — it is a fundamental data limitation.
   - Sensitivity analysis: stratify by classDate cohort (early vs late enrollment) to check for temporal trends
   - Mixed model with classDate random intercept already exists — verify ICC and report
   - Add explicit limitation comment in poster discussion text

10. **Treatment confounding documentation**
    - Many patients are introduced to treatments (Nerva, pain psychology, Mahana) DURING the class
    - Post scores may reflect both class effect AND subsequent treatment
    - Document as limitation; note that this is inherent to the pragmatic study design
    - Exploratory: compare delta scores for patients with game plan interventions vs without (if N permits)

11. **Micro-goals as treatment component**
    - Micro-goals are part of the intervention, not independent predictors
    - Frame descriptively (what patients chose) rather than as predictors of outcome

### Phase D: Poster Text / Content Outline

12. **Draft poster section text** (concise bullets for each poster section)
    - Background: DGBI prevalence, access gap, virtual group coaching innovation
    - Methods: Single-session virtual group class, qualitative survey analysis, thematic coding methodology
      - **Explicit prevalence methodology**: "Prevalence = % of respondents with theme present (binary per participant), not % of coded segments"
      - **Inter-rater process narrative**: Two independent coders (MA, JB) → consensus review → AI external review. Individual coder data not retained; kappa not computable. Document process rather than metric.
      - **Quote handling SOP**: Quotes edited only for deidentification/grammar; meaning preserved. Max 2-3 exemplars per theme. Selection criteria: typicality + clarity + deidentified.
    - Results: Key numbers from abstract + new theme × outcome findings
    - Conclusions: Virtual coaching empowers patients, increases access, maintains quality
    - Limitations: IBS-SSS timing unknown (no post-measurement dates), treatment confounding, single-site, no control group

### Phase E: Verification

13. **Cross-check abstract numbers** — Independently verify all statistics in the abstract match code output:
    - N=183, mean age 53.1 (SD 16.6), 76.9% female
    - Mean IBS-SSS 228 (SD 119.5)
    - IBS-C 29.0%, functional abdominal pain 16.4%
    - 109 respondents (59.6% response rate)
    - Theme percentages: 53.2%, 86.2%, 73.4%
    - Sub-theme percentages: 66.1%, 37.6%, 42.2%, 36.7%

14. **Re-run full pipeline** to ensure all outputs are current

15. **Review figure quality** — check all poster figures render at appropriate dimensions, readable text

16. **Ensure reproducibility** — `run_figures.R` and `run_poster.R` should regenerate all outputs from clean data

## Relevant Files

- `code/VMBGCC_thematic.Rmd` — add enhanced theme × outcome analysis (Phase A steps 1-5), reference existing `themeByOutcome` section
- `code/VMBGCC_thematic.R` — auto-generated, will be updated
- `code/VMBGCC_figures.Rmd` — existing figure code to adapt for poster panels
- `code/VMBGCC_functions.R` — may need poster theme function, reuse `savePlot()`, `ibsSSSBand()`
- `code/VMBGCC_poster.Rmd` (NEW) — poster-consolidated figures and text
- `code/run_poster.R` (NEW) — wrapper to generate all poster outputs
- `code/VMBGCC_outcomes.Rmd` — existing outcome results to cross-reference
- `code/VMBGCC_descriptives.Rmd` — Table 1 for abstract verification

## Decisions
- The abstract is accepted; poster content must align with abstract claims
- **Lead with thematic results**, clinical outcomes as supporting evidence (aligns with "qualitative study" framing)
- The attached image (thematic framework figure) is a standalone graphic, not code-generated
- IBS-SSS paired N is small (~47) — run both regression AND descriptive, then decide communication based on observed power
- Micro-goals should be framed descriptively, not as independent predictors (they're part of the intervention)
- Theme × outcome is explicitly "exploratory" per the meeting notes and study design
- **This is a pilot study** — the poster should frame limitations as motivating a prospective follow-up with better controls
- Focus is analysis/figures/conclusions/communication, not poster layout (investigator has a draft ePoster)

## Pilot Limitations → Prospective Follow-Up Framing
The poster should clearly articulate what the pilot CAN claim vs what it CANNOT, and how each limitation maps to a design feature in the follow-up:

| Pilot Limitation | What We Can Say | Follow-Up Design Fix |
|---|---|---|
| No control group | Pre/post improvement observed; cannot attribute causally to class alone | Waitlist control or stepped-wedge design |
| IBS-SSS timing unknown (**no post-measurement dates in data**) | Paired improvement exists; temporal relationship to class is unclear | Standardized measurement windows (e.g., 2-week pre, 6-week post) |
| Treatment confounding (Nerva, psychology, etc. introduced in class) | Class is a "gateway" to multimodal care; improvement may reflect package | Separate class effect from downstream treatment uptake with mediator analysis |
| Missing data / selection bias (only ~47 paired IBS-SSS of 183) | Selection bias table shows whether completers differ from non-completers | Standardized data collection at fixed time points; minimize missingness by design |
| Single site | Generalizable template demonstrated; external validity unknown | Multi-site replication |
| No blinding | Inherent to pragmatic QI study | Patient expectations questionnaire at baseline |
| Inter-rater: no individual coder data retained | Consensus process documented narratively (2 coders + AI review) | Retain pre-consensus codes; compute kappa prospectively |
| Micro-goals as treatment | Descriptive patterns of patient goal-setting | Track goal achievement prospectively with standardized follow-up |
| Survey response bias (59.6% response rate) | Respondent demographics similar to non-respondents (selection bias table) | Incentivized or mandatory brief feedback |

## Further Considerations
1. **Sub-theme scope**: Analyze ALL 3 main themes + 12 sub-themes × outcomes. Show abstract-specified themes on the poster, but run the full analysis to surface any unexpected results. Poster sub-theme selection decided after seeing results.
2. **Abstract number verification**: All statistics in the abstract will be independently verified against pipeline output as part of Phase E (step 13).
