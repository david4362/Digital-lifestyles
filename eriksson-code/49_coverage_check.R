library(data.table)
library(sandwich)
library(lmtest)

# Observed annual consumption in the valid transaction months
# (person_coverage from 20: months above the min_spend threshold, window
# per the spending filter, annualised). The participants go on the right of
# every join (X[i, on = "aid"] keeps i's rows — see 40): the frozen M5
# sample is kept, not the full coverage population.
# Coverage variables from the latest source records selected earlier.
coverage_data = person_coverage[, .(aid, observed_annual_spending)][
  analysis_data, on = "aid"]
# SCB DispInk04 is in 100 SEK units (per spec) — convert to SEK so the
# export reads directly in SEK/yr.
coverage_data = scb[, .(aid, register_income = DispInk04 * 100)][
  coverage_data, on = "aid"]
coverage_data = users_latest[, .(aid, bank_accounts = `nr-of-bank-accounts`)][
  coverage_data, on = "aid"]

# Use the same M5 specification and exposure as the headline models. The
# bank_accounts row is the motivation for the account analyses in 66:
# digitally intensive participants connect more bank accounts, so more of
# their consumption is observed.
coverage_specs = list(
  observed_annual_spending = as.formula(
    sub("^co2e", "observed_annual_spending", lm_formula)),
  register_income = as.formula(
    sub("^co2e", "register_income", lm_formula)),
  bank_accounts = as.formula(
    sub("^co2e", "bank_accounts", lm_formula))
)

coverage_results = rbindlist(lapply(names(coverage_specs), function(outcome) {
  m = lm(coverage_specs[[outcome]], data = coverage_data)
  ct = coeftest(m, vcov. = vcovHC(m, type = "HC3"))
  e = ct["index", ]
  data.table(
    outcome = outcome,
    n = nobs(m),
    mean = mean(coverage_data[[outcome]]),
    per_sd = e[["Estimate"]],
    se = e[["Std. Error"]],
    p = e[["Pr(>|t|)"]],
    per_hour = e[["Estimate"]] / h_per_sd
  )
}))
coverage_results[, se_hour := se / h_per_sd]
coverage_results[, `:=`(
  lo = per_sd - 1.96 * se,
  hi = per_sd + 1.96 * se,
  lo_hour = per_hour - 1.96 * se_hour,
  hi_hour = per_hour + 1.96 * se_hour
)]
fwrite(coverage_results, file.path(out_dir, "coverage_check.csv"))

# Unadjusted visualization of connected accounts against the anchored digital
# measure. The regression table contains the M5-adjusted estimate.
png(file.path(out_dir, "coverage_accounts.png"), width = 900, height = 600, res = 120)
plot(coverage_data$hours_est, coverage_data$bank_accounts,
  pch = 16, col = rgb(0, 0, 0, 0.25),
  xlab = "Anchored digital measure (hours/day)",
  ylab = "Number of connected bank accounts",
  main = "Connected bank accounts and digital intensity")
abline(lm(bank_accounts ~ hours_est, data = coverage_data), col = "red", lwd = 2)
dev.off()
