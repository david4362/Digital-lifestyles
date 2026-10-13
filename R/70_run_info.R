# 70_run_info.R — export self-documentation, sourced at the end of both
# RUN_TRE.R and RUN_MOCK.R (the last entry of their script lists). Copies
# the export README and the column-level data dictionary into the export
# directory and writes the run manifest (run_info.csv) so the export
# documents itself: index definition, battery rule, filter thresholds,
# scales.
file.copy(c("EXPORT_README.md", "metadata/export_data_dictionary.csv"), out_dir, overwrite = TRUE)
run_info = data.table(
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
