# RUN_TRE.R — full pipeline in the TRE. Run from eriksson-code/:
#   Rscript RUN_TRE.R
# Reads the parquet cache when complete, else builds it from raw data (slow,
# writes cache). Outputs go to output_v2/ next to cache/ (defined in
# 20_filter_participants.R; v2 = the pre-registered index construction minus
# e-commerce and online selling as the main analysis — the old output/ holds
# the superseded v1 export and is not written to). The run copies the export
# README and the column-level data dictionary into the export directory and
# writes a run manifest (run_info.csv) so the export documents itself.
cache_dir = file.path("/safe", "data", "studie_konsumtion_och_attityder", "chalmers", "eriksson-code", "cache")
cache_files = c("monthly_kr.parquet", "monthly_co2e.parquet", "demographics.parquet",
  "survey.parquet", "survey_endline.parquet", "users.parquet", "scb.parquet",
  "bank_income.parquet")
# transactions.parquet stays in the cache but is neither required for the
# pipeline to run nor loaded by 11_read_cache (no analysis script uses it).

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
    "64_tenure_lifestage.R", "65_e4_diagnostics.R", "66_account_coverage.R")) {
  message("--- ", f, " ---")
  source(f)
}

# Export self-documentation: README + data dictionary copied in, run
# manifest written out (index definition, battery rule, filter thresholds,
# scales) so the export never has to be interpreted from the scripts alone.
file.copy(c("EXPORT_README.md", "export_data_dictionary.csv"), out_dir, overwrite = TRUE)
run_info <- data.table(
  export_version = "v2",
  run_date = format(Sys.Date()),
  r_version = R.version.string,
  out_dir = out_dir,
  index_items = paste(index_main_items, collapse = " "),
  index_nocalls_items = paste(index_nocalls_items, collapse = " "),
  battery_rule = paste0("at least ", battery_min_main, " of ", length(index_main_items), " main items answered (<= ", battery_tol, " missing)"),
  anchor = "bivariate lm(time ~ index) on valid E4 reporters with a valid index; h_per_sd = b",
  headline_scale = "kg CO2e per index SD; per-hour columns derived via h_per_sd (see calibration_check.csv)",
  min_months = min_months, x_months = x_months, min_spend = min_spend)
fwrite(run_info, file.path(out_dir, "run_info.csv"))
message("Done. Outputs in ", out_dir)
