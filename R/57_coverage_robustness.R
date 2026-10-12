library(data.table)
library(sandwich)
library(lmtest)

# Observed bank months per person: the valid months behind the
# annualisation (person_coverage from 20; a month counts as observed when it
# has spending above the min_spend threshold). Restricting to people with
# more observed months re-runs the headline on outcomes that rely on less
# extrapolation.
cov_data = person_coverage[, .(aid, n_months)][analysis_data, on = "aid"]

coverage_robustness = rbindlist(lapply(c(6, 12), function(min_obs) {
  d = cov_data[n_months >= min_obs]
  m = lm(lm_formula, data = d)
  ct = coeftest(m, vcov. = vcovHC(m, type = "HC3"))["index", ]
  data.table(
    restriction = paste0(">= ", min_obs, " observed months"),
    n = nobs(m),
    mean_months = mean(d$n_months),
    per_sd = ct[["Estimate"]],
    se = ct[["Std. Error"]],
    p = ct[["Pr(>|t|)"]],
    per_hour = ct[["Estimate"]] / h_per_sd)
}))
coverage_robustness[, se_hour := se / h_per_sd]
coverage_robustness[, `:=`(lo = per_sd - 1.96 * se, hi = per_sd + 1.96 * se,
  lo_hour = per_hour - 1.96 * se_hour, hi_hour = per_hour + 1.96 * se_hour)]
fwrite(coverage_robustness, file.path(out_dir, "coverage_robustness.csv"))
