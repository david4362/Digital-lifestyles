# RUN_MOCK.R — local pipeline test. Run from eriksson-code/:
#   Rscript RUN_MOCK.R
# Builds the mock data in memory (00_mock_data.R), then sources the analysis
# scripts in the same order as RUN_TRE.R. Outputs go to a throwaway tempdir;
# nothing here touches real data or the TRE cache.

source("00_mock_data.R")
cache_dir = file.path(tempdir(), "cache")

for (f in c("20_filter_participants.R", "30_time_estimate.R", "40_control_vars.R",
    "41_model_check.R", "42_stepwise.R", "43_decomposition.R", "44_presentation_figures.R",
    "45_sample_desc.R", "46_heterogeneity.R", "47_sek.R", "48_equivalence.R",
    "49_coverage_check.R", "50_ecommerce.R", "51_descriptives.R",
    "52_e4_robustness.R", "53_age_spline.R", "54_item_analyses.R",
    "55_e1_analyses.R", "56_deso_fe.R", "57_coverage_robustness.R",
    "58_het_interactions.R", "59_index_variants.R", "60_e4_vs_index.R",
    "61_index_weightings.R", "62_rent_stable.R", "63_transport_split.R",
    "64_tenure_lifestage.R", "65_e4_diagnostics.R", "66_account_coverage.R",
    "67_mechanism.R", "68_volume_composition.R")) {
  message("--- ", f, " ---")
  source(f)
}

# Same export self-documentation steps as RUN_TRE, so the local test covers
# the full run file (README/dictionary copy + run manifest).
file.copy(c("EXPORT_README.md", "export_data_dictionary.csv"), out_dir, overwrite = TRUE)
run_info <- data.table(
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
