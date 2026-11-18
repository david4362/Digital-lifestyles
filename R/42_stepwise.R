library(data.table)
library(sandwich)
library(lmtest)
library(ggplot2)

source("05_labels.R")

# All specifications use the fixed M5 complete-case sample created in 40.
# This prevents the coefficient ladder from changing its participants as
# controls are added. The exposure is the standardized pre-registered index
# (per index SD is the headline scale); the per-hour column is derived via
# the anchor slope h_per_sd from 40 and reported as a secondary scale.
#
# Two ladders: the main index (pre-registered construction minus e-commerce
# and online selling, 11 items) and the variant that also drops calls
# (q11b_2, 10 items). Both indices are built in 40
# on the same sample with the same construction.
stepwise_n = data.table(
  sample = "M0-M5 common complete-case sample",
  n_rows = nrow(analysis_data),
  n_aid = uniqueN(analysis_data$aid)
)
fwrite(stepwise_n, file.path(out_dir, "stepwise_sample.csv"))

specs = list(
  M0_bivariate = "co2e ~ index",
  M1_sex_age = "co2e ~ index + gender + age",
  M2_income_educ = "co2e ~ index + gender + age + income + income_scb + income_bank + education",
  M3_household = "co2e ~ index + gender + age + income + income_scb + income_bank + education + hh_size + children",
  M4_density = "co2e ~ index + gender + age + income + income_scb + income_bank + education + hh_size + children + density",
  M5_city = lm_formula)

ladder = function(expo, variant) {
  rbindlist(lapply(names(specs), function(nm) {
    m = lm(as.formula(sub("index", expo, specs[[nm]], fixed = TRUE)), data = analysis_data)
    ct = coeftest(m, vcov. = vcovHC(m, type = "HC3"))
    e = ct[expo, ]
    data.table(index_variant = variant, model = nm, n = nobs(m),
      r2 = summary(m)$r.squared,
      per_sd = e[["Estimate"]], se = e[["Std. Error"]], p = e[["Pr(>|t|)"]],
      per_hour = e[["Estimate"]] / h_per_sd, se_hour = e[["Std. Error"]] / h_per_sd)
  }))
}
stepwise = rbind(
  ladder("index", variantlab[["main"]]),
  ladder("index_nocalls", variantlab[["nocalls"]]))
stepwise[, `:=`(lo_sd = per_sd - 1.96 * se, hi_sd = per_sd + 1.96 * se,
  lo_hour = per_hour - 1.96 * se_hour, hi_hour = per_hour + 1.96 * se_hour)]
setcolorder(stepwise, c("index_variant", "model", "n", "r2", "per_sd", "se", "p",
  "lo_sd", "hi_sd", "per_hour", "se_hour", "lo_hour", "hi_hour"))
fwrite(stepwise, file.path(out_dir, "stepwise_table.csv"))

# Forest-plot recipe: one row per entry with a point estimate and its 95% CI
# against a dashed zero line, entry labels bottom-to-top on the y axis.
# First use is this script's ladder figure; downstream consumers (sourced
# after 42 by the runners): 43_decomposition, 44_presentation_figures,
# 46_heterogeneity, 47_sek, 48_equivalence, 50_ecommerce, 54_item_analyses,
# 66_account_coverage, 67_mechanism, 68_volume_composition. d carries the
# display columns (est, lo, hi, label); point_col/ci_col take a scalar or
# one color per row; extra layers (reference lines, captions) attach with +.
forest_plot = function(d, xlab, title, point_col = "steelblue", ci_col = "grey40",
    ci_lwd = 0.7, point_size = 2.2, base_size = 11, zero_linetype = "dashed") {
  d = copy(d)
  d$label = factor(d$label, levels = d$label)
  ggplot(d, aes(x = est, y = label)) +
    geom_segment(aes(x = lo, xend = hi), color = rep_len(ci_col, nrow(d)),
      linewidth = ci_lwd) +
    geom_point(color = rep_len(point_col, nrow(d)), size = point_size) +
    geom_vline(xintercept = 0, linetype = zero_linetype, color = "grey") +
    labs(x = xlab, y = NULL, title = title) +
    theme_minimal(base_size = base_size)
}

# Coefficient ladder (main index only; the no-calls variant is in the table)
s = stepwise[index_variant == variantlab[["main"]]]
ggsave(file.path(out_dir, "stepwise_coef.png"),
  forest_plot(s[, .(label = unname(modellab[model]), est = per_sd, lo = lo_sd,
      hi = hi_sd)],
    "kg CO2e per index SD (HC3 95% CI)",
    "Main model: stepwise addition of covariates") +
    labs(caption = sprintf("index SD = %.2f h/day (anchor, see calibration_check.csv)",
      h_per_sd)),
  width = 7.5, height = 5, dpi = 120)
