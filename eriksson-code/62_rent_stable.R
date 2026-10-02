library(data.table)
library(sandwich)
library(lmtest)

out_dir = file.path(dirname(cache_dir), "output")
dir.create(out_dir, showWarnings = FALSE)

# Rent as a housing outcome, restricted to participants with reliable rent
# data. Rent is a fixed monthly payment: every normal participant should
# pay roughly the same rent every valid month. Rent appearing only in
# some valid months is a fault in the collected data (rent paid outside
# the linked account, miscategorized transactions), not a real margin, so
# the rent analysis is restricted to stable renters and the faults are
# counted as diagnostics.
#
# Window-edge accommodation: rent is typically paid in advance (in Sweden
# often the last weekday of the preceding month), so the FIRST and LAST
# valid month of the transaction window can miss a rent transaction even
# for a perfectly stable renter. Those two months are excluded from the
# stability rule: stable = positive rent in every INTERIOR valid month.

# Interior valid months per person: all valid months except the first and
# the last (keep from 20, ordered by month)
km = keep[order(aid, month)][, .(aid, month, i = seq_len(.N), m = .N), by = aid]
interior = km[i > 1 & i < m]
n_interior = interior[, .(n_interior = uniqueN(month)), by = aid]

# Positive-rent months per person within the interior months
rent_months = monthly_kr[category == "rent_kr" & kr > 0][
  interior, on = .(aid, month), nomatch = 0][, .(n_rent = uniqueN(month)), by = aid]

# One row per M5 participant: all analysis_data columns plus the rent
# observation counts
obs = rent_months[n_interior, on = "aid"]
obs[is.na(n_rent), n_rent := 0]
obs = obs[analysis_data, on = "aid", nomatch = 0]
obs[, share_rent := n_rent / n_interior]
obs[, stable := n_rent == n_interior]

# Data-quality diagnostics: how often rent is observed across the interior
# months, and how stable the monthly rent amounts are among stable renters
mr = monthly_kr[category == "rent_kr" & kr > 0][keep, on = .(aid, month), nomatch = 0][
  obs[stable == TRUE, .(aid)], on = "aid", nomatch = 0]
cv = mr[, .(cv_rent = sd(kr) / mean(kr)), by = aid]

rent_diag = data.table(
  n = nrow(obs),
  n_stable = obs[, sum(stable)],
  share_stable = obs[, mean(stable)],
  median_share_interior_months = obs[, median(share_rent)],
  median_cv_monthly_rent = median(cv$cv_rent))
fwrite(rent_diag, file.path(out_dir, "rent_stability_diag.csv"))

# Rent level among stable renters (canonical annualised, P99-winsorized
# rent from 20's recipe), M5 controls
kr_annual = annualise(monthly_kr[category %notin% excluded_kr], "kr")
rent = kr_annual[category == "rent_kr", .(aid, rent = y)]
d = rent[obs[stable == TRUE], on = "aid"]

m = lm(as.formula(sub("^co2e", "rent", lm_formula)), data = d)
ct = coeftest(m, vcov. = vcovHC(m, type = "HC3"))["hours_est", ]

rent_stable = data.table(
  outcome = "Rent among stable renters (SEK/yr)",
  n = nobs(m), mean = mean(d$rent),
  per_hour = ct[["Estimate"]], se = ct[["Std. Error"]], p = ct[["Pr(>|t|)"]],
  per_sd = ct[["Estimate"]] * h_per_sd)
rent_stable[, `:=`(lo = per_hour - 1.96 * se, hi = per_hour + 1.96 * se)]
fwrite(rent_stable, file.path(out_dir, "rent_stable.csv"))
