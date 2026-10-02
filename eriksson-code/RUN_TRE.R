# RUN_TRE.R — full pipeline in the TRE. Run from eriksson-code/:
#   Rscript RUN_TRE.R
# Reads the parquet cache when complete, else builds it from raw data (slow,
# writes cache). Outputs go to output/ next to cache/.
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
    "61_index_weightings.R", "62_rent_stable.R", "63_transport_split.R", "64_tenure_lifestage.R")) {
  message("--- ", f, " ---")
  source(f)
}
message("Done. Outputs in ", file.path(dirname(cache_dir), "output"))
