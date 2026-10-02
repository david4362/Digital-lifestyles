library(data.table)
library(sandwich)
library(lmtest)

out_dir = file.path(dirname(cache_dir), "output")
dir.create(out_dir, showWarnings = FALSE)

# Observed annual consumption in the valid transaction months.
annual_spending <- (monthly_kr[category %notin% excluded_kr][keep, on = .(aid, month), nomatch = 0]
  [, .(spending = sum(kr, na.rm = T), n_months = uniqueN(month)), by = aid]
  [, observed_annual_spending := (spending / n_months) * 12]
  [, .(aid, observed_annual_spending)])

# Coverage variables from the latest source records selected earlier.
coverage_data <- analysis_data[annual_spending, on = "aid", nomatch = 0]
# SCB DispInk04 is in 100 SEK units (per spec) — convert to SEK so the
# export reads directly in SEK/yr.
coverage_data <- coverage_data[
  scb[, .(aid, register_income = DispInk04 * 100)], on = "aid", nomatch = 0]
coverage_data <- coverage_data[
  users_latest[, .(aid, bank_accounts = `nr-of-bank-accounts`)], on = "aid", nomatch = 0]

# Use the same M5 specification and exposure as the headline models.
coverage_specs <- list(
  observed_annual_spending = as.formula(
    sub("^co2e", "observed_annual_spending", lm_formula)),
  register_income = as.formula(
    sub("^co2e", "register_income", lm_formula)),
  bank_accounts = as.formula(
    sub("^co2e", "bank_accounts", lm_formula))
)

coverage_results <- rbindlist(lapply(names(coverage_specs), function(outcome) {
  m <- lm(coverage_specs[[outcome]], data = coverage_data)
  ct <- coeftest(m, vcov. = vcovHC(m, type = "HC3"))
  e <- ct["hours_est", ]
  data.table(
    outcome = outcome,
    n = nobs(m),
    mean = mean(coverage_data[[outcome]]),
    per_hour = e[["Estimate"]],
    se = e[["Std. Error"]],
    p = e[["Pr(>|t|)"]],
    per_sd = e[["Estimate"]] * h_per_sd
  )
}))
coverage_results[, `:=`(
  lo = per_hour - 1.96 * se,
  hi = per_hour + 1.96 * se
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
