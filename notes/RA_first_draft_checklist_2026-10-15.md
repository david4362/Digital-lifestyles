# RA checklist — ERL submission (updated 2026-10-15)

Target: Environmental Research Letters. The manuscript now contains the
sociality-signature section, volume decomposition, registered H2a–H2d tests
with the honest TOST result, telework adjustment, OSF DOI, and an SI document
(latex/SI.tex). Do not add new exploratory analyses beyond the items below.

## TRE runs required

1. **Registered social/cultural group model (H2a).** Estimate the M5 gradient
   for the registered out-of-home social/cultural group (restaurants, bars,
   culture/entertainment, other leisure services) in CO2e and SEK. This is the
   only missing registered decomposition group; the manuscript has a TODO at
   the H2a sentence.
2. **Joint age-group interaction test.** F-test of all index-by-age-band
   interactions added to M5 (het_interactions.csv currently has gender, city,
   and income-quintile terms only). Fills the last manuscript TODO.
3. **Calls–sociality diagnostics.** Run the queued 69_calls_diagnostics.R
   exports (calls_social_activity_associations.csv,
   calls_social_activity_adjustment.csv). These test the sociality-signature
   interpretation directly: how much of the calls gradient is explained by
   F88 social activities.

## Manuscript tasks (no TRE needed)

4. **Publication-quality figures.** Redraw the four main figures (stepwise,
   CO2e decomposition, SEK decomposition, heterogeneity) with plain-language
   labels: no variable codes, no "M5", units in axis titles. Vector PDF
   preferred. The leisure-mechanism plot stays a table.
5. **SI completion.** Fill the two TODO sections in latex/SI.tex: the analysis
   classification table (registered / correction / exploratory, with output
   file per analysis) and the robustness section from stepwise_table.csv,
   index_variants.csv, coverage_robustness.csv, deso_fe.csv, age_spline_rq1.csv.
6. **Representativeness table.** Sample-flow and attrition comparison
   (12,153 → 4,250) from attrition.csv and sample_flow.csv; one SI table plus
   one main-text sentence.
7. **Final results audit.** Check every number in the manuscript against the
   2026-10-13 export (or the rerun that adds items 1–3). No unexplained E4/M5
   labels anywhere.
8. **ERL formatting.** Current main text is ~5,000 words; trim toward ~4,000
   (candidates: compress the Pre-registration section, shorten Data
   subsections now duplicated in SI). ERL class file/template, data-availability
   and ethics statements, ORCIDs, and the Andersson (2020) method citation in
   the carbon-footprint section (currently a placeholder "Cite:").

## Can wait until after coauthor circulation

- Income-quintile presentation.
- Swedish screen-time benchmark comparison (Internetstiftelsen).
- Full-text verification of closed-access references (see
  notes/literature_map_2026-10-15.md).
