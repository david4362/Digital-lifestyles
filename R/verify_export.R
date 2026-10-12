# verify_export.R — invariant checks on the copied export (the newest dated
# folder under output/ in the repo root). Run from R/ after copying the
# export out of the TRE:
#   Rscript verify_export.R
# It checks the newest output/<date>/ automatically (ISO dates sort). In
# the TRE itself the export sits at output/<date>/ next to the cache (the
# out_dir defined in 20_filter_participants.R) — point out_dir there instead.
#
# Each check restates one invariant that the pipeline guarantees structurally,
# so a violation means the copy-out or the run is broken, not just "unexpected":
# what landed in the repo must be what the pipeline wrote and must be
# internally consistent across files.
#
# Checks 14-15 (volume-vs-composition) require an export from a run that
# includes 68_volume_composition.R; checks 16-20 (item scaling, calls
# diagnostics) require 69_calls_diagnostics.R. The frozen 2026-10-07 export
# predates both 69 and the item-scaling fix, so those checks need the next
# TRE rerun; against the 2026-10-07 export this script will fail on the
# missing calls_* files and the old index-variant labels.

library(data.table)
# modellab (the M0-M5 step names) comes from the label script
source("05_labels.R")

runs = sort(list.dirs(file.path("..", "output"), recursive = FALSE))
out_dir = runs[length(runs)]  # newest dated folder (ISO dates sort)

step = fread(file.path(out_dir, "stepwise_table.csv"))
step_sample = fread(file.path(out_dir, "stepwise_sample.csv"))
flow = fread(file.path(out_dir, "sample_flow.csv"))
cal = fread(file.path(out_dir, "calibration_check.csv"))
anchor = fread(file.path(out_dir, "anchor_check.csv"))
decomp = fread(file.path(out_dir, "decomp_table.csv"))
variants = fread(file.path(out_dir, "index_variants.csv"))
coverage = fread(file.path(out_dir, "account_coverage.csv"))
register = fread(file.path(out_dir, "coverage_check.csv"))
e4diag = fread(file.path(out_dir, "e4_diagnostics.csv"))
e4rq1 = fread(file.path(out_dir, "e4_rq1_robustness.csv"))
volmarg = fread(file.path(out_dir, "volume_margins.csv"))
volcomp = fread(file.path(out_dir, "volume_composition.csv"))
run_info = fread(file.path(out_dir, "run_info.csv"))
item_scaling = fread(file.path(out_dir, "item_scaling_check.csv"))
calls_age = fread(file.path(out_dir, "calls_age_specs.csv"))
calls_joint = fread(file.path(out_dir, "calls_joint_comparison.csv"))
joint_items = fread(file.path(out_dir, "item_level_joint.csv"))
calls_step = fread(file.path(out_dir, "calls_stepwise.csv"))
calls_cat = fread(file.path(out_dir, "calls_category.csv"))

main_label = "Revised index: excludes e-commerce & online selling (11 items)"
nocalls_label = "Also minus calls (10 items)"
main_m5 = step[model == "M5_city" & index_variant == main_label]
nocalls_m5 = step[model == "M5_city" & index_variant == nocalls_label]
h_per_sd = cal$hours_per_index_sd

# 1. The M0-M5 ladder is estimated on one frozen sample: N identical across
#    all 12 rows and equal to the frozen M5 complete-case sample.
ok_ladder_n = uniqueN(step$n) == 1L && step$n[1] == step_sample$n_rows

# 2. The frozen M5 sample matches the m5_complete_case stage of sample_flow.
ok_flow_m5 = step_sample$n_rows == flow[stage == "m5_complete_case", n]

# 3. The decomposition's total row is the headline M5 (per_sd and per_hour).
total_row = decomp[cat == "total"]
ok_decomp = abs(total_row$per_sd - main_m5$per_sd) < 1e-6 &&
  abs(total_row$per_hour - main_m5$per_hour) < 1e-6

# 4. The export's own calibration internal checks are all TRUE.
ok_calibration_checks = cal$check_hours_per_sd && cal$check_m5_per_sd &&
  cal$check_per_hour

# 5. calibration_check's m5_per_index_sd is the ladder M5 per_sd.
ok_cal_m5 = abs(cal$m5_per_index_sd - main_m5$per_sd) < 1e-6

# 6. Every per_hour in the ladder is per_sd / h_per_sd (per-hour is derived,
#    per-SD is the headline scale).
ok_per_hour_identity = all(abs(step$per_hour - step$per_sd / h_per_sd) < 1e-6)

# 7. The main and no-calls rows of index_variants equal the corresponding
#    M5 rows of the ladder (same model, same sample, must be the same number).
ok_variants = abs(variants[variant == main_label, per_sd] - main_m5$per_sd) < 1e-6 &&
  abs(variants[variant == nocalls_label, per_sd] - nocalls_m5$per_sd) < 1e-6

# 8. account_coverage's reference row is the headline M5, pct_change 0.
ref_row = coverage[analysis == "Reference"]
ok_coverage_ref = abs(ref_row$per_sd - main_m5$per_sd) < 1e-6 &&
  ref_row$pct_change_vs_reference == 0

# 9. pct_change_vs_reference recomputes as (per_sd - reference) / reference
#     * 100 on every total-CO2e row. The two income-ratio rows are their own
#     reference (see their spec column) and are 0 by design.
tot_rows = coverage[outcome == "total CO2e"]
ratio_rows = coverage[spec == "M5, income > 0 (reference for ratio outcomes)"]
ok_coverage_pct = all(abs(tot_rows$pct_change_vs_reference -
    (tot_rows$per_sd - main_m5$per_sd) / main_m5$per_sd * 100) < 1e-6) &&
  all(ratio_rows$pct_change_vs_reference == 0)

# 10. The register-outcome rows of coverage_check obey the same per-hour identity.
ok_register_identity = all(abs(register$per_hour - register$per_sd / h_per_sd) < 1e-6)

# 11. The anchor feeding the pipeline is the bivariate one: it is the only row
#     marked used_in_pipeline, and its b equals h_per_sd and the anchor slope
#     recorded in e4_diagnostics. (Earlier gap: three anchor rows, none marked.)
used = anchor[used_in_pipeline == TRUE, model]
ok_anchor = length(used) == 1L && used == "bivariate" &&
  abs(anchor[model == "bivariate", b_index] - h_per_sd) < 1e-10 &&
  abs(e4diag[check == "E4 vs main index: anchor slope b (hours per index SD)", value] -
      h_per_sd) < 1e-10

# 12. The E4-vs-total M5 slope is identical in e4_rq1_robustness and e4_diagnostics.
ok_e4_m5 = abs(e4rq1[model == "E4_M5_city", per_hour] -
  e4diag[check == "E4 vs total CO2e, M5 slope (kg per measured hour)", value]) < 1e-10

# 13. run_info records the index spec: main index without q11b_7/q11b_8
#     (e-commerce/online selling), no-calls additionally without q11b_2.
ok_run_info = !grepl("q11b_7", run_info$index_items) && !grepl("q11b_8", run_info$index_items) &&
  grepl("q11_1", run_info$index_items) && !grepl("q11b_2", run_info$index_nocalls_items)

# 14. volume_margins' M5 CO2e row is the headline M5: 68 decomposes exactly
#     the published gradient (asserted in 68 against 42's ladder at run time,
#     re-checked here against the copied export).
ok_volume_headline = abs(volmarg[outcome == "co2e" & spec == "M5", per_sd] -
  main_m5$per_sd) < 1e-6

# 15. The accounting split recomputes in the export: volume + composition +
#     covariance residual = headline, and the volume share is the volume
#     component over the headline.
ok_volume_accounting = abs(
    volcomp[component == "volume_component", estimate] +
    volcomp[component == "composition_component", estimate] +
    volcomp[component == "covariance_residual", estimate] -
    volcomp[component == "headline_gradient", estimate]) < 1e-6 &&
  abs(volcomp[component == "headline_gradient", share_of_headline_pct] - 100) < 1e-9 &&
  abs(volcomp[component == "volume_component", share_of_headline_pct] -
    100 * volcomp[component == "volume_component", estimate] /
      volcomp[component == "headline_gradient", estimate]) < 1e-6

# 16. Item-level and weighting analyses consume z-standardized item columns.
#     This catches the earlier join bug that left raw 1-6 values in analysis_data.
ok_item_scaling = nrow(item_scaling) == 13L &&
  all(abs(item_scaling$mean) < 1e-10) &&
  all(abs(item_scaling$sd - 1) < 1e-10)

# 17-20. Calls diagnostics (David's branch): age specifications share one
#     sample and export all three functional forms; the separate/joint item
#     comparison shares one sample; the calls M0-M5 ladder shares one sample;
#     the category output has both specifications and an exactly additive
#     leaf decomposition.
ok_calls_age = setequal(calls_age$specification, c(
  "M5 linear age", "M5 age bands", "M5 natural spline age (4 df)")) &&
  uniqueN(calls_age$n) == 1L
ok_calls_joint = nrow(calls_joint) == 2L && uniqueN(calls_joint$n) == 1L &&
  nrow(joint_items) == 11L && uniqueN(joint_items$n) == 1L &&
  joint_items$n[1] == calls_joint$n[1]
ok_calls_step = nrow(calls_step) == 6L && uniqueN(calls_step$n) == 1L &&
  setequal(calls_step$model, names(modellab))
ok_calls_category = setequal(calls_cat$specification, c(
  "Calls separately", "Calls conditional on other 10 items")) &&
  all(c("total", "group", "leaf") %in% calls_cat$scope) &&
  !anyDuplicated(calls_cat[, .(outcome, specification)]) &&
  uniqueN(calls_cat$n) == 1L &&
  all(abs(calls_cat[scope == "leaf", sum(estimate), by = specification]$V1 -
    calls_cat[outcome == "total", estimate]) < 1e-6) &&
  all(abs(calls_cat[scope == "leaf", sum(share_of_total_pct),
    by = specification]$V1 - 100) < 1e-6)

checks = data.table(
  check = c("ladder N constant and = frozen M5 sample",
            "frozen M5 sample = sample_flow m5_complete_case",
            "decomposition total = headline M5",
            "calibration internal checks all TRUE",
            "calibration m5_per_index_sd = ladder M5 per_sd",
            "per_hour = per_sd / h_per_sd on every ladder row",
            "index_variants = ladder M5 rows (main, no-calls)",
            "account_coverage reference = headline M5",
            "pct_change_vs_reference recomputes (total CO2e rows)",
            "coverage_check per_hour = per_sd / h_per_sd",
            "bivariate anchor feeds the pipeline (b = h_per_sd)",
            "E4 M5 slope identical in e4_rq1_robustness and e4_diagnostics",
            "run_info records the index spec",
            "volume_margins M5 CO2e row = headline M5",
            "volume/composition split recomputes to the headline",
            "item predictors are analysis-sample z scores",
            "calls age specifications share one sample",
            "calls separate/joint item models share one sample",
            "calls M0-M5 ladder shares one sample",
            "calls category output has separate and conditional models"),
  pass = c(ok_ladder_n, ok_flow_m5, ok_decomp, ok_calibration_checks, ok_cal_m5,
           ok_per_hour_identity, ok_variants, ok_coverage_ref,
           ok_coverage_pct, ok_register_identity, ok_anchor, ok_e4_m5, ok_run_info,
           ok_volume_headline, ok_volume_accounting, ok_item_scaling,
           ok_calls_age, ok_calls_joint, ok_calls_step, ok_calls_category))

print(checks)
stopifnot(all(checks$pass))
cat("All checks pass\n")
