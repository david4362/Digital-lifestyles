library(data.table)
library(sandwich)
library(lmtest)

out_dir = file.path(dirname(cache_dir), "output")
dir.create(out_dir, showWarnings = FALSE)

# Short- vs long-distance transport. The transport composite tested in C3
# mixes daily ground mobility (the margin work-from-home should act on)
# with long-distance leisure travel (aviation, ferry — which it should
# not), so testing the WFH mediation on their sum dilutes any
# daily-mobility signal. The split buckets (short/long/ambiguous) are
# defined in 20 and exhaust the transport composite.
#
# The WFH mediation is run where it should bite (short) and where it
# should not (long): attenuation in short but not in long is the
# specificity check that the mechanism is commuting, not travel in
# general.

# Person x category annual emissions, canonical recipe from 20
cat_annual = annualise(monthly_co2e, "co2e")

bucket = function(cats) {
  cat_annual[category %in% cats, .(y = sum(y, na.rm = T)), by = aid]
}

form0 = sub("^co2e", "y", lm_formula)
base = control_data[, .(aid, age, gender, income, income_scb, income_bank, density,
  hours_est, hh_size, children, education, major_city)]

fit_row = function(d, outcome, spec) {
  m = lm(as.formula(form0), d)
  ct = coeftest(m, vcov. = vcovHC(m, type = "HC3"))["hours_est", ]
  data.table(outcome = outcome, spec = spec, n = nobs(m), mean = mean(d$y),
    per_hour = ct[["Estimate"]], se = ct[["Std. Error"]], p = ct[["Pr(>|t|)"]],
    per_sd = ct[["Estimate"]] * h_per_sd)
}

# The three buckets on the full M5 sample (44/47-style: lm drops the
# complete-case rows, so these match the headline sample rule)
split_m5 = rbind(
  fit_row(base[bucket(short_co2e), on = "aid", nomatch = 0], "short", "M5"),
  fit_row(base[bucket(long_co2e), on = "aid", nomatch = 0], "long", "M5"),
  fit_row(base[bucket(ambiguous_co2e), on = "aid", nomatch = 0], "ambiguous", "M5"))

# Work-from-home mediation on the endline sample. Same design as 55: rows
# missing work_home are dropped up front, so the with/without comparison
# reflects the added control and not a changing sample.
e1 = analysis_data[endline_latest[, .(aid, work_home = F88_2)], on = "aid", nomatch = 0]
e1 = e1[!is.na(work_home)]

fit_wfh = function(cats, outcome) {
  d = e1[bucket(cats), on = "aid", nomatch = 0]
  m0 = lm(as.formula(form0), d)
  m1 = lm(update(as.formula(form0), . ~ . + work_home), d)
  ct0 = coeftest(m0, vcov. = vcovHC(m0, type = "HC3"))["hours_est", ]
  ct1 = coeftest(m1, vcov. = vcovHC(m1, type = "HC3"))["hours_est", ]
  rbind(
    data.table(outcome = outcome, spec = "M5 endline, without WFH", n = nobs(m0),
      mean = mean(d$y), per_hour = ct0[["Estimate"]], se = ct0[["Std. Error"]],
      p = ct0[["Pr(>|t|)"]], per_sd = ct0[["Estimate"]] * h_per_sd),
    data.table(outcome = outcome, spec = "M5 endline, with WFH", n = nobs(m1),
      mean = mean(d$y), per_hour = ct1[["Estimate"]], se = ct1[["Std. Error"]],
      p = ct1[["Pr(>|t|)"]], per_sd = ct1[["Estimate"]] * h_per_sd))
}

split_wfh = rbind(fit_wfh(short_co2e, "short"), fit_wfh(long_co2e, "long"))

transport_split = rbind(split_m5, split_wfh)
transport_split[, `:=`(lo = per_hour - 1.96 * se, hi = per_hour + 1.96 * se)]
fwrite(transport_split, file.path(out_dir, "transport_split.csv"))

# Commute-field usability diagnostic (users-table profile fields,
# baseline). These are candidates for testing the demobilization-via-
# commute channel on the full M5 sample — regressing commute distance or
# mode on the index would complement the E1 work-from-home test at
# n = 4,195 instead of n = 2,359. But they are one-time self-reported
# profile fields and may be stale or sparse, so the first step is
# coverage: report non-missingness and means before any analysis uses
# them. (Mode fields are 0/1, so their mean is the user share.)
commute_cols = c("profile.field_profile_commute_distance",
  "profile.field_profile_commute_public", "profile.field_profile_commute_bike",
  "profile.field_profile_commute_car")
commute = users_latest[, c("aid", commute_cols), with = FALSE][
  analysis_data[, .(aid)], on = "aid", nomatch = 0]
commute_diag = rbindlist(lapply(commute_cols, function(cn) {
  x = commute[[cn]]
  data.table(field = cn, n = sum(!is.na(x)), share = mean(!is.na(x)),
    mean = mean(x, na.rm = TRUE))
}))
fwrite(commute_diag, file.path(out_dir, "commute_diag.csv"))
