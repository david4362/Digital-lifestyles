library(data.table)
library(sandwich)
library(lmtest)

# Longer-window sensitivity for aviation and travel (RA checklist item 5).
# The headline window is the 12 months before the survey, and an infrequent
# purchase can be annualized from a handful of months. This re-estimates the
# two outcomes on one fixed 24-calendar-month window, among M5 participants
# with at least 18 valid spending months in that window, using the same
# annualization and P99 winsor as annualise(). A second row adds the observed
# month count, so unequal coverage inside the eligible set is modelled rather
# than pooled away. The same people are also fit on the standard 12-month
# outcomes, so the comparison is the window, not the sample.
# The mock extract spans 12 months, so nobody is eligible and the script
# writes the diagnostic plus an empty result table. The TRE extract goes
# back far enough for the window to be populated.

window_months = 24
min_valid = 18
subm = survey_latest[, .(aid, submitdate = as.Date(submitdate))]
subm[, submit_month := as.Date(format(submitdate, "%Y-%m-01"))]
subm[, y := as.integer(format(submit_month, "%Y"))]
subm[, m := as.integer(format(submit_month, "%m")) - window_months]
subm[, y := y + (m - 1) %/% 12]
subm[, m := (m - 1) %% 12 + 1]
subm[, window_start := as.Date(sprintf("%04d-%02d-01", y, m))]

valid = monthly_kr[category %notin% excluded_kr][
  , .(kr = sum(kr, na.rm = TRUE)), by = .(aid, month)][kr > min_spend]
valid = subm[, .(aid, window_start, submit_month)][valid, on = "aid", nomatch = 0]
valid = valid[month >= window_start & month < submit_month]
valid = valid[aid %in% analysis_data$aid]
cov = valid[, .(n_months_long = uniqueN(month)), by = aid]
eligible = cov[n_months_long >= min_valid]

long_window_diag = data.table(
  window_months = window_months,
  min_valid_months = min_valid,
  n_m5 = uniqueN(analysis_data$aid),
  n_with_any_long_month = nrow(cov),
  max_months_in_window = if (nrow(cov)) max(cov$n_months_long) else 0L,
  n_eligible = nrow(eligible),
  median_months_eligible = if (nrow(eligible)) median(eligible$n_months_long) else NA_real_
)
fwrite(long_window_diag, file.path(out_dir, "long_window_diag.csv"))

empty = data.table(outcome = character(), unit = character(), window = character(),
  specification = character(), n = integer(), mean_months = numeric(),
  mean = numeric(), per_sd = numeric(), se = numeric(), p = numeric(),
  lo = numeric(), hi = numeric(), pct_of_mean = numeric())

# M5 has about 20 parameters; below 50 eligible people the fit is not a
# sensitivity analysis. The mock lands here.
if (nrow(eligible) < 50) {
  fwrite(empty, file.path(out_dir, "long_window_travel.csv"))
} else {
  long_keep = unique(valid[aid %in% eligible$aid, .(aid, month)])
  long_annual = function(monthly, val, cats) {
    ann = monthly[category %in% cats][long_keep, on = .(aid, month), nomatch = 0]
    ann = ann[, .(s = sum(get(val)), n_months = uniqueN(month)), by = .(aid, category)]
    ann = ann[n_months >= min_months]
    ann[, y := (s / n_months) * 12]
    ann[, q99 := quantile(y, .99, na.rm = TRUE), by = category]
    ann[, y := pmin(y, q99)]
    ann[, .(aid, category, y)]
  }
  fit_long = function(annual, cats, outcome, unit, window, spec, extra = NULL) {
    yy = group_annual(annual, cats)
    dd = analysis_data[eligible, on = "aid", nomatch = 0][yy, on = "aid", nomatch = 0]
    f = sub("^co2e", "y", lm_formula)
    if (!is.null(extra)) f = paste(f, "+", extra)
    m = lm(as.formula(f), data = dd)
    ct = coeftest(m, vcov. = vcovHC(m, type = "HC3"))["index", ]
    est = ct[["Estimate"]]
    se = ct[["Std. Error"]]
    data.table(outcome = outcome, unit = unit, window = window, specification = spec,
      n = nobs(m), mean_months = mean(dd$n_months_long), mean = mean(dd$y),
      per_sd = est, se = se, p = ct[["Pr(>|t|)"]],
      lo = est - 1.96 * se, hi = est + 1.96 * se,
      pct_of_mean = 100 * est / mean(dd$y))
  }
  co2_long = long_annual(monthly_co2e, "co2e", c("aviation_co2e", "travel_co2e"))
  kr_long = long_annual(monthly_kr, "kr", c("aviation_kr", "travel_kr"))
  co2_12 = annualise(monthly_co2e, "co2e")
  kr_12 = annualise(monthly_kr[category %notin% excluded_kr], "kr")
  # fit_long joins analysis_data[eligible]; the coverage column is on eligible.
  # The 12-month comparison uses the same eligible ids but the standard outcomes,
  # so mean_months still reports long-window coverage.
  rows = rbind(
    fit_long(co2_long, "aviation_co2e", "aviation", "kg CO2e/yr", "24 months", "M5"),
    fit_long(co2_long, "aviation_co2e", "aviation", "kg CO2e/yr", "24 months",
      "M5 + observed months", "n_months_long"),
    fit_long(co2_long, "travel_co2e", "travel", "kg CO2e/yr", "24 months", "M5"),
    fit_long(co2_long, "travel_co2e", "travel", "kg CO2e/yr", "24 months",
      "M5 + observed months", "n_months_long"),
    fit_long(co2_12, "aviation_co2e", "aviation", "kg CO2e/yr", "12 months, same people", "M5"),
    fit_long(co2_12, "travel_co2e", "travel", "kg CO2e/yr", "12 months, same people", "M5"),
    fit_long(kr_long, "aviation_kr", "aviation", "SEK/yr", "24 months", "M5"),
    fit_long(kr_long, "travel_kr", "travel", "SEK/yr", "24 months", "M5"),
    fit_long(kr_12, "aviation_kr", "aviation", "SEK/yr", "12 months, same people", "M5"),
    fit_long(kr_12, "travel_kr", "travel", "SEK/yr", "12 months, same people", "M5"))
  fwrite(rows, file.path(out_dir, "long_window_travel.csv"))
}
