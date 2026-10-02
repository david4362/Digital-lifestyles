library(data.table)
library(sandwich)
library(lmtest)

out_dir = file.path(dirname(cache_dir), "output")
dir.create(out_dir, showWarnings = FALSE)

# Observed bank months per person: the valid months behind the
# annualisation. Restricting to people with more observed months re-runs
# the headline on outcomes that rely on less extrapolation (a month counts
# as observed when it has spending above the min_spend threshold in 20).
months_person = monthly_kr[category %notin% excluded_kr][keep, on = .(aid, month), nomatch = 0][
  , .(n_months = uniqueN(month)), by = aid]
cov_data = analysis_data[months_person, on = "aid", nomatch = 0]

coverage_robustness = rbindlist(lapply(c(6, 12), function(min_obs) {
  d = cov_data[n_months >= min_obs]
  m = lm(lm_formula, data = d)
  ct = coeftest(m, vcov. = vcovHC(m, type = "HC3"))["hours_est", ]
  data.table(
    restriction = paste0(">= ", min_obs, " observed months"),
    n = nobs(m),
    mean_months = mean(d$n_months),
    per_hour = ct[["Estimate"]],
    se = ct[["Std. Error"]],
    p = ct[["Pr(>|t|)"]])
}))
coverage_robustness[, per_sd := per_hour * h_per_sd]
coverage_robustness[, `:=`(lo = per_hour - 1.96 * se, hi = per_hour + 1.96 * se)]
fwrite(coverage_robustness, file.path(out_dir, "coverage_robustness.csv"))
