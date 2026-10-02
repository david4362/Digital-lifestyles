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
    "61_index_weightings.R", "62_rent_stable.R", "63_transport_split.R", "64_tenure_lifestage.R")) {
  message("--- ", f, " ---")
  source(f)
}
message("Done. Outputs in ", file.path(dirname(cache_dir), "output"))
