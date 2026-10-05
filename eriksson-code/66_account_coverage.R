library(data.table)
library(sandwich)
library(lmtest)

# Does bank-account coverage explain the gradient? Digitally intensive
# participants connect more bank accounts (49: the index slope on the number
# of accounts), so more of their consumption is observed — a measurement
# channel that could act like a digital gradient even with no behavioural
# difference. Tests, all with the main (pre-registered minus e-commerce)
# index on the frozen M5 sample, HC3:
# 1. M5 + number of connected bank accounts (linear control)
# 2. M5 separately within exactly 1 / 2 / 3 / 4+ accounts
# 3. M5 + account fixed effects
# 4. M5 with observed annual spending / register disposable income as the
#    outcome (SEK observed per SEK register income)
# 5. M5 with total CO2e / register income as the outcome (kg CO2e per
#    100,000 SEK register income)
# 6. M5 restricted to participants whose observed annual spending is within
#    a reasonable share of register disposable income (50-150%; wide band
#    25-200%). "Reasonable" is a judgment call, documented here and in the
#    export README; both bands are reported.
# Every row exports the index slope per SD with 95% CI, p, n, the derived
# per-hour slope, and the percent change against the reference estimate of
# the same outcome family (total-CO2e rows against the original M5; the two
# ratio outcomes are their own references, being unrestricted).

# Accounts from the latest users record; register income in SEK
# (SCB DispInk04 is in 100-SEK units); observed spending + observed months
# from person_coverage (20). The participants go on the right of every join
# (X[i, on = "aid"] keeps i's rows — see 40): the frozen M5 sample is kept,
# not the full users/coverage population.
cov_data <- users_latest[, .(aid, bank_accounts = `nr-of-bank-accounts`)][
  analysis_data, on = "aid"]
cov_data <- person_coverage[, .(aid, n_months, observed_annual_spending)][
  cov_data, on = "aid"]
cov_data <- scb[, .(aid, register_income = DispInk04 * 100)][cov_data, on = "aid"]

cov_data[, account_group := fcase(
  bank_accounts == 1, "1", bank_accounts == 2, "2", bank_accounts == 3, "3",
  bank_accounts >= 4, "4+")]
# Ratios need positive register income; DispInk04 <= 0 is treated as no
# usable income (reported in account_groups_desc), not as a zero ratio.
cov_data[, spending_income := fifelse(register_income > 0,
  observed_annual_spending / register_income, NA_real_)]
cov_data[, co2e_income := fifelse(register_income > 0,
  co2e / (register_income / 1e5), NA_real_)]

# Descriptives per account group: who has how many accounts, and how much
# of consumption and income is observed there
account_groups_desc <- cov_data[, .(n = .N, share = .N / nrow(cov_data),
  mean_index = mean(index), mean_n_months = mean(n_months),
  mean_bank_accounts = mean(bank_accounts), mean_co2e = mean(co2e),
  mean_observed_annual_spending = mean(observed_annual_spending),
  mean_register_income = mean(register_income),
  n_income_positive = sum(register_income > 0),
  mean_spending_income = mean(spending_income, na.rm = TRUE)), by = account_group]
setorder(account_groups_desc, account_group)
fwrite(account_groups_desc, file.path(out_dir, "account_groups_desc.csv"))

# One row per analysis: M5 (or M5 variant) on the given data, slope per SD
fit_row <- function(d, form, analysis, outcome, spec, ref) {
  m <- lm(form, data = d)
  ct <- coeftest(m, vcov. = vcovHC(m, type = "HC3"))["index", ]
  est <- ct[["Estimate"]]
  se <- ct[["Std. Error"]]
  data.table(analysis = analysis, outcome = outcome, spec = spec, n = nobs(m),
    per_sd = est, se = se, p = ct[["Pr(>|t|)"]],
    lo = est - 1.96 * se, hi = est + 1.96 * se,
    per_hour = est / h_per_sd, se_hour = se / h_per_sd,
    pct_change_vs_reference = 100 * (est - ref) / ref)
}

# Reference estimates: the original M5 on total CO2e, and the unrestricted
# ratio-outcome M5s (their own family references)
ref_co2e <- coef(lm(as.formula(lm_formula), data = analysis_data))[["index"]]
ref_spending <- coef(lm(as.formula(sub("^co2e", "spending_income", lm_formula)),
  data = cov_data))[["index"]]
ref_co2e_income <- coef(lm(as.formula(sub("^co2e", "co2e_income", lm_formula)),
  data = cov_data))[["index"]]

account_strata <- rbindlist(lapply(c("1", "2", "3", "4+"), function(g) {
  d <- cov_data[account_group == g]
  if (nrow(d) < 30) {
    message("66: skipping account group ", g, " (n = ", nrow(d), ")")
    return(NULL)
  }
  lab <- if (g == "4+") "M5, 4+ accounts" else paste0("M5, exactly ", g, " account", if (g != "1") "s")
  fit_row(d, lm_formula, "Account strata", "total CO2e", lab, ref_co2e)
}))

# Spending-plausible bands: restricted to participants whose observed annual
# spending is within a reasonable share of register disposable income.
# "Reasonable" is a judgment call (documented here and in the export README);
# both bands are reported. Strata below n = 30 are skipped, as in 64.
band_row <- function(lo, hi) {
  d <- cov_data[!is.na(spending_income) & spending_income >= lo & spending_income <= hi]
  if (nrow(d) < 30) {
    message("66: skipping spending-share band ", lo * 100, "-", hi * 100,
      "% (n = ", nrow(d), ")")
    return(NULL)
  }
  fit_row(d, lm_formula, "Spending-plausible sample", "total CO2e",
    paste0("M5, observed spending ", lo * 100, "-", hi * 100, "% of register income"),
    ref_co2e)
}

account_coverage <- rbind(
  fit_row(analysis_data, lm_formula, "Reference", "total CO2e",
    "M5 (reference)", ref_co2e),
  fit_row(cov_data, update(as.formula(lm_formula), . ~ . + bank_accounts),
    "Account control", "total CO2e", "M5 + bank accounts (linear)", ref_co2e),
  fit_row(cov_data, update(as.formula(lm_formula), . ~ . + factor(bank_accounts)),
    "Account control", "total CO2e", "M5 + account fixed effects", ref_co2e),
  account_strata,
  fit_row(cov_data, sub("^co2e", "spending_income", lm_formula),
    "Income-normalised outcome", "observed spending / register income",
    "M5, income > 0 (reference for ratio outcomes)", ref_spending),
  fit_row(cov_data, sub("^co2e", "co2e_income", lm_formula),
    "Income-normalised outcome", "total CO2e / register income (kg per 100k SEK)",
    "M5, income > 0 (reference for ratio outcomes)", ref_co2e_income),
  band_row(0.5, 1.5),
  band_row(0.25, 2))
fwrite(account_coverage, file.path(out_dir, "account_coverage.csv"))

# Slope by account group (the strata rows of the table above)
png(file.path(out_dir, "account_coverage.png"), width = 900, height = 600, res = 120)
s <- account_coverage[analysis == "Account strata"]
y <- seq_len(nrow(s))
plot(s$per_sd, y, xlim = range(c(s$lo, s$hi)), yaxt = "n", pch = 19, col = "steelblue",
  xlab = "kg CO2e per index SD (HC3 95% CI)", ylab = "", main = "M5 gradient by number of connected accounts")
axis(2, y, paste0(s$spec, " (n=", s$n, ")"), las = 1, cex.axis = 0.8)
segments(s$lo, y, s$hi, y, col = "grey40")
abline(v = account_coverage[spec == "M5 (reference)", per_sd], lty = 2, col = "grey")
abline(v = 0, lty = 3, col = "grey")
dev.off()
