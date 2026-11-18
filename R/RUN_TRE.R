# RUN_TRE.R — full pipeline in the TRE. Run from R/:
#   Rscript RUN_TRE.R
# Reads the parquet cache when complete, else builds it from raw data (slow,
# writes cache). Outputs go to output/<run date>/ next to cache/ (defined in
# 20_filter_participants.R); each run writes its own dated folder, so runs
# never overwrite each other. The run copies the export
# README and the column-level data dictionary into the export directory and
# writes a run manifest (run_info.csv) so the export documents itself
# (70_run_info.R, the last sourced script).
# Scripts 20-75, sourced in order.
cache_dir = file.path("/safe", "data", "studie_konsumtion_och_attityder", "chalmers", "digital_lifestyles", "cache")
cache_files = c("monthly_kr.parquet", "monthly_co2e.parquet", "transactions_long.parquet",
  "demographics.parquet", "survey.parquet", "survey_endline.parquet", "users.parquet",
  "scb.parquet", "bank_income.parquet")
# transactions.parquet and transactions_long.parquet stay in the cache; the
# long core is consumed by 10_load_data.R, not by any analysis script, so
# 11_read_cache deliberately loads neither (both are large).
# The study metadata (codebooks, Variabellista, category lists, the export
# data dictionary) has its canonical home at the workspace level in
# data/metadata/; the repo carries a synced copy at metadata/, which the
# ../metadata candidate below resolves; in the TRE keep a copy next to the
# pipeline at chalmers/digital_lifestyles/metadata/ — copy it over when
# syncing the scripts. Fail fast: 70 copies the dictionary into the export,
# so a missing metadata copy must stop the run here, not after the models.
metadata_candidates = file.path(c("../metadata", "../../../data/metadata"), "export_data_dictionary.csv")
metadata_dir = dirname(metadata_candidates[file.exists(metadata_candidates)][1])
if (is.na(metadata_dir)) stop(
  "Study metadata not found: expected a copy next to the pipeline (../metadata/) or the workspace original (../../../data/metadata/). ",
  "Copy <workspace>/data/metadata/ to chalmers/digital_lifestyles/metadata/ in the TRE before running.")

if (all(file.exists(file.path(cache_dir, cache_files)))) {
  message("Cache complete — reading parquet")
  source("11_read_cache.R")
} else {
  message("Cache incomplete — loading raw data (slow, writes cache)")
  source("10_load_data.R")
}

for (f in c("20_filter_participants.R", "30_time_estimate.R", "40_control_vars.R",
    "41_model_check.R", "42_stepwise.R", "43_decomposition.R", "44_presentation_figures.R",
    "45_sample_desc.R", "46_heterogeneity.R", "47_sek.R", "48_equivalence.R",
    "49_coverage_check.R", "50_ecommerce.R", "51_descriptives.R",
    "52_e4_robustness.R", "53_age_spline.R", "54_item_analyses.R",
    "55_e1_analyses.R", "56_deso_fe.R", "57_coverage_robustness.R",
    "58_het_interactions.R", "59_index_variants.R", "60_e4_vs_index.R",
    "61_index_weightings.R", "62_rent_stable.R", "63_transport_split.R",
    "64_tenure_lifestage.R", "65_e4_diagnostics.R", "66_account_coverage.R",
    "67_mechanism.R", "68_volume_composition.R", "69_calls_diagnostics.R",
    "69_sample_representativeness.R", "71_social_cultural.R",
    "72_age_interaction.R", "73_calls_sociality.R", "74_social_spending.R",
    "75_long_window.R", "76_publication_figures.R", "70_run_info.R")) {
  message("--- ", f, " ---")
  source(f)
}
