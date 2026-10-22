# RA checklist — ERL submission (updated 2026-10-16)

Target: Environmental Research Letters. The manuscript now contains the
sociality-signature section, volume decomposition, spending-first placebo
result, telework adjustment, OSF DOI, ethics statement, and an SI document
(latex/SI.tex). Do not add new exploratory analyses beyond the items below.

Status 2026-10-22: scripts for items 1–5 are written and sourced
(`71`–`75`; `RUN_MOCK` passes, including the long-window empty path on the
12-month mock). They have not been run on the TRE extract, so no results
exist yet. Manuscript and SI are untouched.

## TRE runs required

1. **Registered social/cultural group model.** Estimate the fully adjusted gradient
   for the registered out-of-home social/cultural group (restaurants, bars,
   culture/entertainment, other leisure services) in CO2e and SEK. This is the
   only missing registered decomposition group; the manuscript has a TODO at
   the corresponding sentence.
2. **Joint age-group interaction test.** F-test of all index-by-age-band
   interactions added to the fully adjusted model (het_interactions.csv currently has gender, city,
   and income-quintile terms only). Fills the last manuscript TODO.
3. **Calls–sociality diagnostics.** Run the queued 69_calls_diagnostics.R
   exports (calls_social_activity_associations.csv,
   calls_social_activity_adjustment.csv). These test the sociality-signature
   interpretation directly: how much of the calls gradient is explained by
   F88 social activities.
4. **Social-media and gaming spending patterns.** For each exposure separately,
   estimate fully adjusted SEK gradients for restaurants, transport,
   e-commerce-intensive goods, and digital services. Export coefficients,
   95% CIs, p-values, category means, and percentage changes. Replace the
   manuscript TODO; do not reuse the existing CO2e models as spending results.
5. **Longer-window aviation and travel sensitivity.** Re-estimate aviation and
   travel outcomes over one fixed, longer transaction window among participants
   with sufficient coverage. Apply documented annualization and outlier rules;
   do not pool unequal available-month counts without modelling coverage.

## Manuscript tasks (no TRE needed)

6. **Publication-quality figures.** Redraw the three main figures (stepwise,
   CO2e decomposition, SEK decomposition) with plain-language labels: no
   variable codes, units in axis titles. Vector PDF preferred. Heterogeneity
   and the detailed leisure table stay in the SI.
7. **SI completion.** Fill the two TODO sections in latex/SI.tex: the analysis
   classification table (registered / correction / exploratory, with output
   file per analysis) and the robustness section from stepwise_table.csv,
   index_variants.csv, coverage_robustness.csv, deso_fe.csv, age_spline_rq1.csv.
8. **Sample reliability and representativeness.** Run
   `R/69_sample_representativeness.R` in the TRE and review all six exports.
   Reconcile invitation and analytical counts by random frame and green-area
   oversample; do not use the existing `attrition.csv`, which only compares E4
   screen-time reporters with non-reporters. Benchmark the analytical
   random-frame subset against the invited random frame on age, gender, and
   major-city residence. Report pooled, random-frame, green-area, and
   sampling-IPW random-frame gradients for both spending and emissions, plus
   the weight distribution and effective sample size. Add the final stream
   flow, benchmark, and model-comparison tables to the SI and replace the
   representativeness TODO in the main text. Describe the pooled sample as
   selected even if the weighted estimate is similar.
9. **Final results audit.** Check every number in the manuscript against the
   2026-10-13 export (or the rerun that adds items 1–3). No unexplained E4/M5
   labels anywhere.
10. **ERL formatting.** The draft is now just under 4,000 words by `detex`, but
   recheck using the journal's counting convention after replacing TODOs.
   Complete the ERL template, data-availability statement, ORCIDs, and final
   reference-format check.

## Can wait until after coauthor circulation

- Income-quintile presentation.
- Swedish screen-time benchmark comparison (Internetstiftelsen).
- Full-text verification of closed-access references (see
  notes/literature_map_2026-10-15.md).
