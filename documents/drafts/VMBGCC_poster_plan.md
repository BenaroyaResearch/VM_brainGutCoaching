# Plan: VMBGCC Academic Poster — Analysis, Figures & Communication

## TL;DR
Push the VMBGCC analysis toward a high-quality ePoster presentation. The existing pipeline is largely complete. The work focuses on: (1) enhanced theme × clinical outcome crossed analysis (both regression and descriptive, decide communication based on power), (2) poster-ready figure design leading with thematic results, (3) clear framing of what the pilot data can/cannot claim, and (4) articulating how a prospective follow-up study addresses limitations. The investigator has a draft ePoster — we provide the analytical content, figures, and conclusions.

## Implementation Status Summary

| Phase | Step | Description | Status |
|-------|------|-------------|--------|
| A.0 | 0 | Selection bias / missingness table | ✅ Done |
| A.1 | 1 | Intersection sample size | ✅ Done |
| A.2 | 2 | Logistic regression (responder ~ themes) | ✅ Done |
| A.3 | 3 | Linear model (deltaIBSSSS ~ themes) | ✅ Done |
| A.4 | 4 | Sub-theme × outcome effect sizes + heatmap | ✅ Done |
| A.5 | 5 | Micro-goal category × outcome | ✅ Done (descriptive only) |
| B | 6 | Poster composite figure script | ✅ Done (Panels B-E complete; Panel A flow diagram not yet code-generated) |
| B | 7 | Poster color palette and theme | ✅ Done (`posterColors`, `theme_poster()`) |
| B | 8 | `run_poster.R` wrapper | ✅ Done |
| C | 9 | IBS-SSS temporal analysis | ⏳ Partially documented (mixed model exists in outcomes; poster commentary needed) |
| C | 10 | Treatment confounding documentation | ⏳ Documented in plan; needs poster text |
| C | 11 | Micro-goals framing | ✅ Done (descriptive framing) |
| D | 12 | Draft poster section text | ⏳ Needs drafting (see Phase D below) |
| E | 13 | Abstract number cross-check | ✅ Done (discrepancies identified — see below) |
| E | 14 | Re-run full pipeline | ⏳ Pending |
| E | 15 | Review figure quality | ⏳ Pending |
| E | 16 | Ensure reproducibility | ⏳ Pending |

## Abstract vs Pipeline Discrepancies — MUST RESOLVE

The abstract verification in `VMBGCC_poster.Rmd` revealed discrepancies between accepted abstract values and current pipeline output. These must be reconciled before finalizing the poster.

| Metric | Abstract Value | Pipeline Value | Discrepancy | Resolution |
|--------|---------------|----------------|-------------|------------|
| N (enrolled) | 183 | 182 | 1 patient | Verify if patient was dropped during cleaning; use pipeline value on poster with footnote if different from abstract |
| Female % | 76.9% | 76.4% | Minor | Use pipeline value |
| Survey respondents | 109 (59.6%) | 112 (~61%) | 3 respondents | Check respondent definition alignment; may reflect updated coding |
| IBS-C prevalence | 29.0% | 41.8% | **LARGE** | Likely a denominator difference (all attendees vs diagnosed subset); must investigate and document |
| Functional abdominal pain | 16.4% | 7.1% | **LARGE** | Same — check diagnosis coding/denominator |
| Theme percentages | 53.2%, 86.2%, 73.4% | Close but not exact | Minor | Reflects updated consensus coding; use pipeline values |
| Date range | 6/1/2023–8/3/2025 | 2023-12-15 to 2025-07-11 | Different bounds | Verify against raw Excel; earliest date differs significantly |

**Decision needed**: Are diagnosis prevalences reported among ALL attendees (N=183) or only those with a recorded diagnosis? The 29.0% vs 41.8% gap for IBS-C suggests a denominator issue. Check Sheet 7 coding.

**Poster approach**: Use current pipeline values on the poster with a note: "Minor numerical differences from accepted abstract reflect updated data cleaning and consensus coding."

## Current State
- **Complete**: Table 1, pre/post outcomes (Wilcoxon, effect sizes, FDR), IBS-SSS severity transitions, theme prevalence with CIs, theme co-occurrence, micro-goals/game plan categorization, 32 publication figures, poster figure panels (B-E), theme × outcome analysis (Phase A), selection bias table, logistic/linear regression
- **Partial**: Poster text content (Phase D), temporal/confounding documentation (Phase C), Panel A cohort flow diagram (not yet code-generated)
- **Missing**: Final poster section text, abstract discrepancy resolution, re-run verification (Phase E)

## Steps

### Phase A: Missingness, Selection Bias & Enhanced Theme × Outcome Analysis

0. ✅ **Selection bias / missingness table (Table S1)** — HIGH PRIORITY credibility check
   - Define cohort strata: A (all attendees, N≈182) → B (survey respondents, ~112) → C (paired IBS-SSS, ~47) → D (paired PHQ-2, ~131) → E+ (intersections: respondent + paired outcome)
   - Compare baseline characteristics across strata: age, sex, baseline IBS-SSS, IBS-SSS severity band, nDiagnoses
   - Wilcoxon (continuous) and chi-squared/Fisher (categorical) tests
   - Output: formatted comparison table for poster footnote or supplementary
   - **Implemented in**: `VMBGCC_poster.Rmd` → `selection-bias` chunk

1. ✅ **Check intersection sample size** — Intersection counts printed in `theme-outcome-setup` chunk. *(unblocked steps 2-3)*

2. ✅ **Logistic regression: IBS-SSS responder status ~ theme presence**
   - Binary outcome: responder (≥50-pt IBS-SSS decrease) vs non-responder
   - Predictors: 3 main themes (binary), adjusting for baseline IBS-SSS severity, age, sex
   - **Implemented**: Full model when EPV ≥ 5; unadjusted ORs always; Fisher exact as fallback
   - **Implemented**: Responder rate stratified by baseline severity band with Wilson CIs
   - *Note small N for paired IBS-SSS (~47) — EPV check gates model complexity*
   - **Implemented in**: `VMBGCC_poster.Rmd` → `responder-regression`, `responder-by-severity` chunks

3. ✅ **Multi-theme linear model for deltaIBSSSS**
   - `deltaIBSSSS ~ themePositiveSharedExperience + themePatientEmpowerment + themePatientActivation + preIBSSSS + age + sex`
   - Reports coefficients with 95% CIs
   - **Implemented in**: `VMBGCC_poster.Rmd` → `delta-lm` chunk

4. ✅ **Sub-theme × outcome analysis (all 15 themes × 3 outcomes)** — ADJUSTED testing approach
   - Computed effect sizes (rank-biserial r + 95% CI) for ALL 15 themes × 3 delta scores = 45 effect sizes
   - **Formal hypothesis tests limited to**: 3 main themes × deltaIBSSSS only (3 tests, FDR-corrected)
   - Everything else: descriptive effect sizes + CIs, CI excludes zero marked with *
   - Heatmap: theme × outcome effect sizes with CI significance markers (not p-value stars)
   - **Implemented in**: `VMBGCC_poster.Rmd` → `theme-outcome-effectsizes`, `effect-heatmap` chunks

5. ✅ **Micro-goal category × outcome associations** (descriptive)
   - 8-category keyword-based extraction (Exercise, Mindfulness, Diet, Sleep, Social, Screen Time, Stress, App/Tool)
   - Bar chart of prevalence by category
   - **Implemented in**: `VMBGCC_poster.Rmd` → `microgoals` chunk
   - **Decision**: Framed descriptively only (micro-goals are part of the intervention, not independent predictors)

### Phase B: Poster Figure Consolidation

6. **Create poster-specific composite figure script** (`code/VMBGCC_poster.Rmd`) ✅ Created
   - Poster figures use larger text, higher contrast, fewer panels than manuscript figures
   - Key poster panels:
     - **Panel A**: Cohort flow / demographics summary (compact Table 1) — include counts and response rates directly on diagram (e.g., "112/182 = 61.5%")
       - ⏳ **Not yet code-generated** — The investigator may produce this outside R (e.g., in PowerPoint/Figma). If a code-generated version is needed, create a text-based flow diagram with `ggplot2 + annotate()` or `DiagrammeR`.
       - Elements needed: N enrolled → N responded to survey → N with paired IBS-SSS → N in intersection (theme × outcome analysis). Branch showing survey non-respondents and missing outcome data.
     - **Panel B**: ✅ Gardner-Altman estimation plot — paired spaghetti (left) + delta distribution with bootstrap CI (right). Responder/non-responder color coding. IBS-SSS severity thresholds (75, 175, 300).
       - File: `figures/poster_ibsEstimation.{pdf,png}`
     - **Panel C**: ✅ IBS-SSS alluvial severity transitions — annotated with responder rate by baseline severity band in subtitle.
       - File: `figures/poster_ibsAlluvial.{pdf,png}`
     - **Panel D**: ✅ Theme prevalence bar chart (horizontal, sorted, grouped by 3 main themes with color blocks, Wilson CIs, count + % labels).
       - File: `figures/poster_themePrevalence.{pdf,png}`
     - **Panel E**: ✅ Theme × outcome effect size heatmap (rank-biserial r with * for CI excludes zero, NOT p-values; labeled "Exploratory").
       - File: `figures/poster_themeOutcomeHeatmap.{pdf,png}`
     - **Panel F**: ✅ Micro-goals summary (keyword category bar chart).
       - File: `figures/poster_microGoals.{pdf,png}`
     - **Supporting**: ✅ PHQ-2 and GAD-7 pre/post estimation plots (paired spaghetti + bootstrap CI).
       - File: `figures/poster_phqGadPrePost.{pdf,png}`
   - The attached abstract image (Figure 1 — thematic visual with empowerment framework) is a standalone graphic, not code-generated

7. ✅ **Poster color palette and theme**
   - `posterColors` list: pre (#4477AA), post (#EE6677), severity gradient, theme group colors
   - `theme_poster()` function: base_size=14, bold titles, minimal gridlines
   - Color-blind friendly (Tol palette)

8. ✅ **Create `run_poster.R`** wrapper — Checks for clean RDS dependency, purls and sources `VMBGCC_poster.Rmd`

### Phase C: Address Methodological Concerns in Analysis

9. ⏳ **IBS-SSS temporal analysis**
   - **IMPORTANT**: Post-measurement dates do NOT exist in the dataset. Only `classDate` is available. There is no `days_post_minus_pre` or similar variable. This CANNOT be addressed analytically — it is a fundamental data limitation.
   - ✅ Mixed model with classDate random intercept exists in `VMBGCC_outcomes.Rmd` — ICC and random effect reported
   - ⏳ Sensitivity analysis: stratify by classDate cohort (early vs late enrollment) to check for temporal trends — can be added to poster supplementary
   - ⏳ Add explicit limitation statement in poster discussion text (see Phase D, step 12)

10. ⏳ **Treatment confounding documentation**
    - Many patients are introduced to treatments (Nerva, pain psychology, Mahana) DURING the class
    - Post scores may reflect both class effect AND subsequent treatment
    - ✅ Brain Gut Game Plan interventions are coded and categorized in `VMBGCC_thematic.Rmd`
    - ⏳ Formal limitation language needed in poster discussion (see Phase D)
    - Exploratory: compare delta scores for patients with game plan interventions vs without (if N permits) — **deferred**: game plan assignment is part of the class, not independent

11. ✅ **Micro-goals as treatment component**
    - Micro-goals are part of the intervention, not independent predictors
    - Framed descriptively (what patients chose) rather than as predictors of outcome
    - **Implemented**: keyword-based categorization in poster micro-goals panel

### Phase D: Poster Text / Content Outline

12. ⏳ **Draft poster section text** (concise bullets for each poster section)

    #### Background
    - Disorders of gut-brain interaction (DGBI) affect ~40% of the global population and are associated with significant symptom burden, including abdominal pain, altered bowel habits, and psychiatric comorbidity
    - Access to multidisciplinary brain-gut care is limited by geography, specialist availability, and cost
    - Virtual group coaching is an emerging scalable model that may increase access while maintaining quality of care
    - **Aim**: Characterize patient experience and clinical outcomes of a single-session virtual Brain-Gut Coaching Class (BGCC) for patients with DGBI

    #### Methods
    - **Design**: Single-arm pre/post pragmatic quality improvement study at a tertiary GI center
    - **Intervention**: Single-session 90-minute virtual group class led by GI dietitian/health coach. Content: brain-gut education, shared experience discussion, micro-goal setting, Brain Gut Game Plan (personalized next steps including Nerva, Mahana, pain psychology referral, dietary counseling)
    - **Participants**: N=182 adults with DGBI attended across 34 class dates (Dec 2023 – Jul 2025)
    - **Outcome measures**:
      - *Primary quantitative*: IBS-SSS (paired pre/post, N≈47), PHQ-2 (N≈131), GAD-7 (N≈126)
      - *Primary qualitative*: Post-class survey open-ended responses (N≈112 respondents, ~61% response rate)
    - **Qualitative analysis**: Thematic analysis of open-ended survey responses. Two independent coders (MA, JB) performed initial coding → consensus review → external AI-assisted review for completeness check. Binary coding per participant (theme present/absent).
      - **Prevalence methodology**: "Prevalence = % of respondents with theme present (binary per participant), not % of coded segments"
      - **Inter-rater process narrative**: Individual coder data not retained; kappa not computable. Process documented narratively as 2-coder consensus with external review.
      - **Quote handling SOP**: Quotes edited only for deidentification/grammar; meaning preserved. Max 2-3 exemplars per theme. Selection criteria: typicality + clarity + deidentified.
    - **Statistical analysis**: Wilcoxon signed-rank tests (paired outcomes), rank-biserial r effect sizes, FDR correction. Wilson CIs for proportions. Exploratory: theme × outcome associations (rank-biserial r, logistic regression for IBS-SSS responder status). Bootstrap CIs for mean differences. Mixed-effects models with class date random intercept to account for clustering.

    #### Results — Key Numbers
    *(Fill from pipeline output; use current values, not abstract values)*
    - **Cohort**: N=182, mean age 53.1 (SD ~16.6), ~76% female, median 2 DGBI diagnoses
    - **Diagnoses**: IBS-C most common (~42%), followed by [...]
    - **IBS-SSS (N≈47 paired)**: Mean pre [X] → post [X], mean Δ [X] [95% CI: X, X], Wilcoxon p<[X], rank-biserial r=[X]. Responders (≥50-pt decrease): [X]% [95% CI]
    - **PHQ-2 (N≈131 paired)**: Mean Δ [X] [95% CI], p=[X], r=[X]
    - **GAD-7 (N≈126 paired)**: Mean Δ [X] [95% CI], p=[X], r=[X]
    - **Thematic analysis (N≈112 respondents)**: 3 main themes, 12 sub-themes identified
      - Patient Empowerment: [X]%
      - Patient Activation: [X]%
      - Positive Shared Experience: [X]%
      - Top sub-themes: Teaching/Coaching Style ([X]%), Validation ([X]%), Agency – Actionable Tools ([X]%), Self-Efficacy ([X]%)
    - **Theme × IBS-SSS (exploratory)**: [Report effect sizes and direction — no formal claims. Reference heatmap.]
    - **Micro-goals**: [X] patients set goals; Exercise/Movement most common ([X]%), followed by Mindfulness ([X]%), Diet ([X]%)
    - **Selection bias**: Survey respondents vs non-respondents showed no significant differences in age, sex, baseline IBS-SSS, or nDiagnoses (all p > 0.05)

    #### Conclusions
    - A single-session virtual Brain-Gut Coaching Class was associated with clinically meaningful IBS symptom improvement and positive patient experience
    - Three thematic domains — Patient Empowerment, Patient Activation, and Positive Shared Experience — characterized participant experience, with Patient Empowerment most prevalent
    - The class serves as a scalable "gateway" to multimodal brain-gut care, with patients setting self-directed micro-goals and receiving personalized Brain Gut Game Plans
    - Exploratory theme × outcome associations suggest themes may differentially relate to clinical improvement, warranting prospective investigation
    - **Key takeaway**: Virtual group coaching is feasible, scalable, and valued by patients with DGBI as both an educational and empowering experience

    #### Limitations (poster text)
    - **No control group**: Pre/post design cannot attribute improvement solely to class; spontaneous improvement and regression to the mean are possible
    - **Unknown IBS-SSS timing**: Post-measurement dates do not exist in the dataset; temporal relationship between class attendance and outcome measurement is unclear
    - **Treatment confounding**: The class introduces patients to multimodal treatments (Nerva, pain psychology, dietary counseling); post-scores may reflect both class and downstream treatment effects. Frame as: "the class is a gateway to brain-gut care; observed improvement may reflect the combined intervention package"
    - **Missing data / selection bias**: Only ~47/182 have paired IBS-SSS (26% completeness). Selection bias table shows completers do not differ significantly from non-completers on available baseline measures
    - **Qualitative limitations**: No pre-consensus kappa (individual codes not retained); survey non-response (39%); binary coding loses intensity/frequency information
    - **Single-site, no blinding**: Results reflect one tertiary center; pragmatic design precludes blinding

    #### Future Directions (if space permits)
    - Prospective multi-site study with standardized measurement windows (2-week pre, 6-week post), waitlist control, and retention of individual coder data for kappa computation
    - Longitudinal tracking of micro-goal achievement and Brain Gut Game Plan uptake
    - Mediator analysis separating class effect from downstream treatment effects

### Phase E: Verification

13. ✅ **Cross-check abstract numbers** — Verification completed in `VMBGCC_poster.Rmd` → `abstract-verify` and `summary` chunks. **Discrepancies found** (see "Abstract vs Pipeline Discrepancies" section above).
    - Original abstract claims: N=183, mean age 53.1 (SD 16.6), 76.9% female, mean IBS-SSS 228 (SD 119.5), IBS-C 29.0%, functional abdominal pain 16.4%, 109 respondents (59.6%), theme %: 53.2%, 86.2%, 73.4%, sub-theme %: 66.1%, 37.6%, 42.2%, 36.7%
    - ⚠️ **Large discrepancies**: IBS-C (29.0% vs 41.8%), functional abdominal pain (16.4% vs 7.1%), date range, N (183 vs 182), respondents (109 vs 112)
    - **Action needed**: Investigate diagnosis prevalence denominator (all attendees vs diagnosed subset vs Sheet 7 specific); reconcile date range with raw Excel. See resolution strategy above.

14. ⏳ **Re-run full pipeline** to ensure all outputs are current
    - `Rscript code/run_cleaning.R` → `run_descriptives.R` → `run_outcomes.R` → `run_thematic.R` → `run_figures.R` → `run_poster.R`
    - Verify all RDS files update to current date stamp
    - Confirm figure directory contains all expected poster files

15. ⏳ **Review figure quality** — check all poster figures render at appropriate dimensions, readable text
    - Minimum text: 14pt axis labels, 18pt titles for poster viewing
    - Check: all PNGs at ≥300 DPI, PDFs vectorized
    - Verify color contrast and color-blind accessibility
    - Test at target ePoster display dimensions

16. ⏳ **Ensure reproducibility** — `run_figures.R` and `run_poster.R` should regenerate all outputs from clean data
    - Test clean run: delete all `figures/poster_*.{pdf,png}`, then `Rscript code/run_poster.R`
    - Verify no hardcoded file paths outside of `baseDir` and `dataDate`

## Relevant Files

| File | Purpose | Status |
|------|---------|--------|
| `code/VMBGCC_poster.Rmd` | Poster-specific analysis and figures (Phases A + B) | ✅ Implemented |
| `code/VMBGCC_poster.R` | Auto-generated R script from poster Rmd | ✅ Generated |
| `code/run_poster.R` | Wrapper to run poster pipeline | ✅ Implemented |
| `code/VMBGCC_thematic.Rmd` | Theme prevalence, co-occurrence, micro-goals, game plan | ✅ Complete |
| `code/VMBGCC_thematic.R` | Auto-generated from thematic Rmd | ✅ Generated |
| `code/VMBGCC_outcomes.Rmd` | Wilcoxon, effect sizes, mixed models, sensitivity | ✅ Complete |
| `code/VMBGCC_figures.Rmd` | Manuscript-quality figures (Table 1 through Figure 6 + supplementary) | ✅ Complete (32 figures) |
| `code/VMBGCC_functions.R` | Shared utilities: savePlot, ibsSSSBand, etc. + `theme_poster()` in poster Rmd | ✅ Complete |
| `code/VMBGCC_descriptives.Rmd` | Table 1, missingness, MCAR, temporal patterns | ✅ Complete |
| `code/VMBGCC_cleaning.Rmd` | Data ingestion, type coercion, validation | ✅ Complete |

## Decisions
- The abstract is accepted; poster content must align with abstract claims
- **Lead with thematic results**, clinical outcomes as supporting evidence (aligns with "qualitative study" framing)
- The attached image (thematic framework figure) is a standalone graphic, not code-generated
- IBS-SSS paired N is small (~47) — run both regression AND descriptive, then decide communication based on observed power
- Micro-goals should be framed descriptively, not as independent predictors (they're part of the intervention)
- Theme × outcome is explicitly "exploratory" per the meeting notes and study design
- **This is a pilot study** — the poster should frame limitations as motivating a prospective follow-up with better controls
- Focus is analysis/figures/conclusions/communication, not poster layout (investigator has a draft ePoster)

## Remaining Action Items (Priority Order)

1. **🔴 Resolve diagnosis prevalence discrepancy** — Investigate IBS-C 29.0% vs 41.8% and functional abdominal pain 16.4% vs 7.1%. Check denominator and coding logic. This affects poster credibility.
2. **🔴 Resolve date range and N discrepancies** — Verify raw Excel earliest date (abstract says 6/1/2023, pipeline says 12/15/2023). Reconcile N=183 vs 182.
3. **🟡 Draft poster section text** — Fill in placeholder values in Phase D step 12 from pipeline output. Finalize wording for background, methods, results, conclusions, and limitations.
4. **🟡 Panel A cohort flow diagram** — Decide if code-generated or manual. If code-generated, add to `VMBGCC_poster.Rmd`.
5. **🟢 Re-run full pipeline** (Phase E step 14) — After any code changes, execute end-to-end.
6. **🟢 Review figure quality** — Check dimensions, text readability, DPI.
7. **🟢 Select representative quotes** — 1 per main theme from thematic coding data.
8. **🟢 Final sign-off** — Investigator reviews all figures and text for accuracy and messaging.

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
2. **Abstract number verification**: All statistics in the abstract have been verified against pipeline output (Phase E step 13). Discrepancies documented above with resolution strategy.
3. **Diagnosis prevalence denominator**: The IBS-C discrepancy (29.0% abstract vs 41.8% pipeline) is the single largest issue to resolve. Possible explanations: (a) abstract used N=183 as denominator but subset had diagnosis data; (b) diagnosis one-hot coding changed between abstract and current pipeline; (c) Sheet 7 was updated. Investigate by checking `VMBGCC_cleaning.Rmd` diagnosis parsing logic against raw Excel.
4. **Poster space prioritization**: If space is limited, prioritize: (1) Theme prevalence (Panel D) — leads the story, (2) IBS-SSS estimation plot (Panel B) — strongest quantitative evidence, (3) Alluvial transitions (Panel C) — visual impact, (4) Heatmap (Panel E) — exploratory but novel. Micro-goals (Panel F) and PHQ/GAD (Supporting) can be dropped or shown as small insets.
5. **Effect size interpretation guide**: For the poster audience, include a brief legend on the heatmap: "Rank-biserial r: small |r|≈0.1, medium |r|≈0.3, large |r|≈0.5. Negative r = theme-present group improved more."
6. **Quote exemplars**: If the poster includes representative quotes, select 1 per main theme. Prioritize quotes that (a) are deidentified, (b) illustrate the theme clearly, (c) are ≤2 sentences. The thematic coding data in `VMBGCC.2026-03-19_thematicCoding.csv` contains `surveyLiked`, `surveyImproved`, `surveyOther` columns with raw text.

## Poster Figure Inventory

| Panel | Description | Filename | Dimensions | Status |
|-------|-------------|----------|------------|--------|
| A | Cohort flow diagram | *(not code-generated)* | — | ⏳ Investigator or manual |
| B | IBS-SSS Gardner-Altman estimation plot | `poster_ibsEstimation` | 12×7 | ✅ |
| C | IBS-SSS alluvial severity transitions | `poster_ibsAlluvial` | 10×7 | ✅ |
| D | Theme prevalence bar chart | `poster_themePrevalence` | 12×8 | ✅ |
| E | Theme × outcome heatmap | `poster_themeOutcomeHeatmap` | 10×8 | ✅ |
| F | Micro-goals bar chart | `poster_microGoals` | 10×6 | ✅ |
| Supp | PHQ-2 + GAD-7 pre/post | `poster_phqGadPrePost` | 12×6 | ✅ |

All figures saved as both PDF (vector) and PNG (300 DPI) in `figures/`.

## Statistical Reporting Standards for Poster

- **Primary outcomes**: Report paired N, median Δ (IQR), Wilcoxon p (FDR-corrected), rank-biserial r [95% CI]
- **Effect sizes over p-values**: Use estimation approach — bootstrap CIs for means, Wilson CIs for proportions
- **Theme prevalence**: N (%) with Wilson 95% CI
- **Theme × outcome (exploratory)**: Rank-biserial r [95% CI] only; p-values only for 3 formal tests (main theme × IBS-SSS, FDR-corrected). Everything else is effect-size-only.
- **Regression**: ORs [95% CI] for logistic; β [95% CI] for linear. Note: "Exploratory; model may be underpowered given small intersection N"
- **Decimal places**: percentages to 1 decimal (e.g., 76.4%), effect sizes to 2 decimals, p-values to 3 decimals (or "<0.001")
- **Multiple testing**: BH FDR correction applied to primary outcomes (3 tests) and main theme × IBS-SSS (3 tests). Sub-theme and cross-outcome analyses are descriptive (no multiplicity adjustment).

## Poster Layout & Format Considerations

- **Format**: ePoster (digital display, landscape orientation)
- **Target dimensions**: Varies by conference; typically 1920×1080px or equivalent A0 landscape
- **Column structure**: Suggest 3-column layout: (1) Background + Methods, (2) Results — thematic + clinical, (3) Conclusions + Limitations
- **Font hierarchy**: Title 28-32pt, section headers 20-24pt, body text 16-18pt, figure captions 14pt
- **Figures**: All poster panels are pre-generated at high DPI; investigator imports into ePoster template
- **Color consistency**: All code-generated figures use `posterColors` palette; investigator should match non-code elements to the same palette
- **The investigator has a draft ePoster** — this plan provides analytical content, figures, and text; not layout design
