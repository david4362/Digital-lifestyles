library(data.table)
library(sandwich)
library(lmtest)

source("05_labels.R")

# Index-construction robustness, all with the M5 specification on the frozen
# analysis sample from 40: only index availability changes n, never the
# sample itself. The main row reproduces the M5 per-SD estimate of the
# stepwise table by construction (the variant is z-scored in the same
# sample). Axes:
# - scaling sample: the earlier pipeline z-scaled the items on the whole
#   battery sample, so
#   within the analysis sample the items' SDs differed and the effective
#   item weights were unequal; the main construction scales on the analysis
#   sample, where every item has SD 1. The battery-sample row isolates that
#   choice.
# - item content: the 13-item row puts the two e-commerce items
#   (q11b_7/q11b_8, excluded from the main index because they measure the
#   purchase channel) back in, with the pre-registered >= 10 of 13 rule.
# - calls: the 10-item row also drops calls (q11b_2) — the second ladder in
#   42.

# M5 on a z-scored index variant column: one row for the variants table.
run_variant = function(d, index_variant, label) {
  d = copy(d)
  d[, index_variant := as.vector(scale(index_variant))]
  m = lm(sub("index", "index_variant", lm_formula, fixed = TRUE), data = d)
  ct = coeftest(m, vcov. = vcovHC(m, type = "HC3"))["index_variant", ]
  data.table(variant = label, n = nobs(m),
    per_sd = ct[["Estimate"]], se = ct[["Std. Error"]], p = ct[["Pr(>|t|)"]])
}

# Baseline: the main index (pre-registered construction minus e-commerce
# and online selling, built in 40), z-scored in the analysis sample.
base_row = run_variant(analysis_data, analysis_data$index, variantlab[["main"]])

# Items z-scaled on the battery (gate) sample instead of the analysis
# sample: the earlier scaling choice, applied to the main item set.
mu_gate = unlist(answered_survey[, lapply(.SD, mean, na.rm = TRUE), .SDcols = index_main_items])
sd_gate = unlist(answered_survey[, lapply(.SD, sd, na.rm = TRUE), .SDcols = index_main_items])
batt = item_battery[aid %in% analysis_data$aid]
zb = copy(batt)
zb[, (index_main_items) := Map(function(x, m, s) (x - m) / s,
  .SD, mu_gate, sd_gate), .SDcols = index_main_items]
zb[, index_b := rowMeans(.SD, na.rm = TRUE), .SDcols = index_main_items]
d_b = zb[, .(aid, index_b)][analysis_data, on = "aid"]
b_row = run_variant(d_b, d_b$index_b,
  "Items z-scaled on the battery sample")

# All 13 items incl. e-commerce & online selling, pre-registered >= 10 of 13
# rule, analysis-sample scaling (the q11 columns of analysis_data are the
# z-scaled items from 40) — the full pre-registration index as originally run.
n13 = rowSums(!is.na(analysis_data[, ..q11_cols]))
d13 = copy(analysis_data)
d13[, index_13 := fifelse(n13 >= length(q11_cols) - battery_tol,
  rowMeans(.SD, na.rm = TRUE), NA_real_), .SDcols = q11_cols]
row_13 = run_variant(d13, d13$index_13,
  "All 13 items incl. e-commerce & online selling (>= 10 of 13)")

# Also dropping calls (q11b_2): built in 40; the second ladder in 42.
nocalls_row = run_variant(analysis_data, analysis_data$index_nocalls, variantlab[["nocalls"]])

index_variants = rbind(base_row, b_row, row_13, nocalls_row)
index_variants[, `:=`(lo = per_sd - 1.96 * se, hi = per_sd + 1.96 * se)]
fwrite(index_variants, file.path(out_dir, "index_variants.csv"))
