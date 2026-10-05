# Export v2 — Digital lifestyles and consumption-based carbon emissions

This directory is a complete, self-contained export of the analysis pipeline run
(`RUN_TRE.R` from `eriksson-code/`, SCB TRE). It supersedes the v1 export; old
and new results are not mixed. `run_info.csv` records the run date, R version,
item lists, battery rule, filter thresholds and scales; the per-column
documentation of every table is in `export_data_dictionary.csv`.

## Exposure: the digital lifestyle index

**Main index (the headline exposure of every "per_sd" column).**
Pre-registered construction, minus the two e-commerce items:

1. **Items (11):** device-use frequencies `q11_1`–`q11_5` (computer,
   smartphone, TV, game console, tablet; 1–6 scale) and digital-activity
   frequencies `q11b_1`–`q11b_6` (streaming, calls, social media,
   information search, gaming, digital reading; 1–6 scale).
   `q11b_7` (e-commerce) and `q11b_8` (online selling) are **excluded**: they
   measure the purchase channel itself, so keeping them in the exposure while
   the outcomes are transaction-observed consumption would build part of the
   outcome into the exposure.
2. **Every item is z-standardized first** (analysis-sample mean and SD), then
   the index is the unweighted mean of the answered standardized items, then
   re-standardized to mean 0, SD 1 in the analysis sample. Equal effective
   item weights are guaranteed in the estimation sample.
3. **Battery rule:** the pre-registration tolerates up to 3 missing items
   (≥ 10 of 13). The same tolerance is kept as the item set shrinks:
   **≥ 8 of 11** main items answered for sample entry (≥ 7 of 10 for the
   no-calls variant).

**Registered variants** (`index_variants.csv`, `index_weightings.csv`,
`stepwise_table.csv`): also dropping calls `q11b_2` (10 items; the second
M0–M5 ladder in `stepwise_table.csv`); the device-use half (5 items) and the
digital-activity half (6 items); the first principal component; all 13 items
incl. e-commerce & online selling (≥ 10 of 13; what the e-commerce items add
back); items z-scaled on the battery sample instead of the analysis sample
(v1's scaling choice — equalizes item SDs on a different population, so the
effective item weights differ within the analysis sample).

**Cardinal anchor (interpretive only).** E4 (endline `q21`, self-transcribed
from iOS *Skärmtid* / Android *Digitalt välmående*, h:mm/day, 0–18 h/day
plausibility rule) regressed on the standardized index, bivariate, on all
valid E4 reporters with a valid index (`anchor_check.csv`, row
`used_in_pipeline = TRUE`). The anchor slope is **hours per index SD**
(`h_per_sd`).

**Scales.** Headline scale is **kg CO₂e per year per 1 SD of the index**
(`per_sd`). Every `per_hour` column is *derived* (`per_sd / h_per_sd`) and
secondary, because the anchor is weak (bivariate R² ≈ 0.016 in v1; device
screen time correlates only weakly with the self-reported battery —
`e4_diagnostics.csv`, `e4_item_correlations.csv`). All per-SD↔per-hour
conversion ingredients and their consistency checks are in
`calibration_check.csv` (the v1 files did not state which anchor model fed
the conversion — that gap is what made the old per-hour/per-SD ratios look
inconsistent).

## Samples

- **Battery gate:** ≥ 8 of 11 main items answered (latest pre-treatment
  response per person).
- **Valid months:** ≥ 3 months with non-excluded spending > 3,000 SEK within
  12 months before the survey; person-category outcomes annualised
  (sum/months × 12) with a per-category P99 winsor.
- **M5 complete-case sample:** the gate ∩ valid months ∩ register/profile
  controls ∩ emissions, complete cases — fixed across M0–M5 so the ladder
  changes controls, not participants (`sample_flow.csv`,
  `model_missingness.csv`).
- **E4 subsample:** valid E4 reporters with a valid index (anchor,
  `e4_rq1_robustness.csv`, `e4_index_test.csv`).

## Reading the tables

HC3 robust standard errors throughout; 95% CIs = ± 1.96 SE (90% for the TOST
in `equivalence_table.csv`). Column-level documentation of every table is in
`export_data_dictionary.csv`. Key tables: `stepwise_table.csv` (M0–M5 ladders,
main and no-calls index), `decomp_table.csv` / `sek_table.csv`
(decomposition), `calibration_check.csv` (hour-calibration audit),
`account_coverage.csv` + `account_groups_desc.csv` (does bank-account
coverage explain the gradient), `e4_diagnostics.csv` +
`e4_item_correlations.csv` (E4 credibility; no iOS/Android platform variable
exists in the data — see the script headers of `65_e4_diagnostics.R`),
`item_level.csv` + `item_figure_check.csv` (item-level gradients; the figure
audit asserts every axis label sits on its own item's estimate and CI).

## Reproducing

`Rscript RUN_TRE.R` from `eriksson-code/` in the TRE regenerates this whole
directory into `output_v2/` next to the cache (scripts 20–66, sourced in
order; the run copies this README and the data dictionary in and writes
`run_info.csv`).
