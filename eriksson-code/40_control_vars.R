library(data.table)

# Use the latest user record when an aid occurs more than once.
users_latest = users[order(aid, date), .SD[.N], by = aid]

# All control variables, joined and derived in four plain steps (SCB
# register, demographics, users profile, survey battery). The construction
# starts from keep (person x month rows), so every person has one row per
# valid month with identical per-person values; the unique() at the end
# collapses them back to one row per person. Each centering mean is
# computed within its step, i.e. on exactly the rows the earlier
# one-piece chain used.

# 1. SCB register: density (log, centered) and education level
control_data = keep[scb, on = "aid", nomatch = 0]
control_data[, density := log(density) - mean(log(density), na.rm = TRUE)]
control_data[, education := factor(fcase(
  Sun2020Niva < 300, "Grundskola",
  Sun2020Niva < 400, "Gymnasium",
  Sun2020Niva < 500, "Eftergymnasial <2 år",
  Sun2020Niva < 600, "Eftergymnasial >=2 år",
  Sun2020Niva >= 600, "Forskare"
))]

# 2. Demographics: age (centered) and major-city indicator
control_data = control_data[demographics_unique, on = "aid", nomatch = 0]
control_data[, age := age - mean(age, na.rm = TRUE)]
control_data[, major_city := fifelse(postort %in% c("Stockholm", "Göteborg", "Malmö"), TRUE, FALSE)]

# 3. Users profile: household size and children, app income (log,
# centered) with its quintiles, and register income (log, centered)
control_data = control_data[
  users_latest[, .(aid, `income-level`, profile.field_profile_household_adults, profile.field_profile_household_children)],
  on = "aid", nomatch = 0]
control_data[, hh_size := profile.field_profile_household_adults + profile.field_profile_household_children]
control_data[, children := factor(profile.field_profile_household_children > 0)]
control_data[, income := log1p(`income-level`) - mean(log1p(`income-level`), na.rm = TRUE)]
control_data[, income_q := cut(`income-level`,
  quantile(`income-level`, probs = seq(0, 1, 0.2), na.rm = TRUE),
  labels = paste0("Q", 1:5), include.lowest = TRUE)]
control_data[, income_scb := log1p(pmax(DispInk04, 0)) - mean(log1p(pmax(DispInk04, 0)), na.rm = TRUE)]

# 4. Raw battery responses (30; the index built below replaces the role
# the scaled battery played in the earlier pipeline), then keep only the
# needed columns (deso for 56's fixed effects, income_q for 50's quintile
# stratification, items for 54/59/61) and collapse to one row per person.
control_data = control_data[item_battery, on = "aid", nomatch = 0]
control_data = unique(control_data[, c("aid", "age", "gender", "income", "income_q", "income_scb",
  "density", "hh_size", "children", "education", "major_city", "deso", q11_cols), with = FALSE])

# Join KK bank income, keeping every participant. In a data.table join
# X[i, on = "aid"] the rows of i (the right-hand side) are the ones kept, so
# the participants go on the right: people without a bank-income record keep
# their row with income_bank NA and drop out of the complete-case sample
# diagnosed below (visible in model_missingness) instead of being dropped
# silently by the join.
control_data = person_bank[, .(aid, income_bank_raw)][control_data, on = "aid"]
control_data[, income_bank := log1p(income_bank_raw) - mean(log1p(income_bank_raw), na.rm = TRUE)]
control_data[, income_bank_raw := NULL]

# M5 formula. The exposure is the standardized pre-registered index built
# below, so the headline scale is kg CO2e per index SD; the per-hour scale is
# derived from the anchor (calibration_check.csv in 41) and exported as a
# secondary column, not the main result. income_q (quintile stratification in
# 50), deso (fixed effects in 56) and the item columns (index ingredients,
# used separately in 54/61) stay out of the formula.
lm_formula = paste("co2e", paste(c("age", "gender", "income", "income_scb",
  "income_bank", "density", "index", "hh_size", "children", "education",
  "major_city"), collapse = "+"), sep = "~")
covariate_vars = setdiff(all.vars(as.formula(lm_formula)), c("co2e", "index"))

lm_data = control_data[emissions, on = "aid", nomatch = 0]

# Diagnose the complete-case loss explicitly, then freeze the M5 sample. This
# makes the M0-M5 ladder change controls rather than changing participants.
# Everyone in the sample passed the battery gate in 20, so all get a valid
# index below and "index" needs no missingness row of its own.
missingness = rbindlist(lapply(covariate_vars, function(v) {
  x = lm_data[[v]]
  data.table(variable = v, n_missing = sum(is.na(x)))
}))
fwrite(missingness, file.path(out_dir, "model_missingness.csv"))

analysis_data = lm_data[complete.cases(lm_data[, ..covariate_vars])]

# Pre-registered index construction (minus e-commerce and online selling),
# in three steps, all parameters from the frozen analysis sample:
#
# 1. z-scale every battery item with the analysis-sample mean and SD
#    (answers may be missing up to the battery tolerance; means and SDs use
#    the answered values). The parameters are then applied to every battery
#    respondent who passed the gate, so the index is also defined for E4
#    reporters outside the analysis sample (the anchor below needs them).
mu_items = unlist(analysis_data[, lapply(.SD, mean, na.rm = TRUE), .SDcols = q11_cols])
sd_items = unlist(analysis_data[, lapply(.SD, sd, na.rm = TRUE), .SDcols = q11_cols])
z_items = copy(item_battery)
z_items[, (q11_cols) := Map(function(x, m, s) (x - m) / s,
  .SD, mu_items, sd_items), .SDcols = q11_cols]
z_items = z_items[aid %in% answered_survey$aid]

# 2. raw composite: unweighted mean of the answered standardized items
#    (everyone here answered at least battery_min_main of the 11 main
#    items in 20), for the main index and the no-calls variant.
z_items[, index_raw := rowMeans(.SD, na.rm = TRUE), .SDcols = index_main_items]
z_items[, index_nocalls_raw := rowMeans(.SD, na.rm = TRUE), .SDcols = index_nocalls_items]

# 3. re-standardize the composites to mean 0, SD 1 in the analysis sample.
an_join = z_items[, .(aid, index_raw, index_nocalls_raw)][analysis_data, on = "aid"]
z_items[, index := (index_raw - mean(an_join$index_raw)) / sd(an_join$index_raw)]
z_items[, index_nocalls := (index_nocalls_raw - mean(an_join$index_nocalls_raw)) /
  sd(an_join$index_nocalls_raw)]

# Cardinal anchor: E4 hours/day on the standardized index, fit on all valid
# E4 reporters with a valid index (battery-gate members, not just the
# analysis sample — as pre-registered). Because the index is standardized,
# the anchor slope IS hours per index SD: h_per_sd needs no extra SD
# multiplication, and every per-hour column downstream is per_sd / h_per_sd.
device_time = screen_time[z_items, on = "aid", nomatch = 0][
  , .(aid, time, index, age, gender)]
dt_lm = lm(time ~ index, data = device_time)
dt_lm_controls = lm(time ~ index + age + gender, data = device_time)
dt_coefs = coef(dt_lm)
h_per_sd = dt_coefs[["index"]]

# Anchored hours/day (interpretive scale only — the headline scale is per
# index SD; see calibration_check.csv for the full conversion audit).
z_items[, hours_est := dt_coefs[["(Intercept)"]] + dt_coefs[["index"]] * index]

# Join the exposure (+ variants and anchored hours) into the frozen analysis
# sample and the control table (43/47/50/63 build their category models from
# control_data; 52 uses hours_est for the same-unit E4 comparison).
analysis_data = z_items[, .(aid, index, index_nocalls, index_raw, hours_est)][
  analysis_data, on = "aid"]
control_data = z_items[, .(aid, index, hours_est)][control_data, on = "aid"]

# ---- Shared model objects and helpers (used by the analysis scripts) ----

# The E4 subsample of the frozen analysis sample (valid E4 reporters with a
# valid index and controls): the comparison sample for 52 (E4 vs index),
# 60 (the formal difference test) and 65 (diagnostics).
e4_data = analysis_data[device_time[, .(aid, time)], on = "aid", nomatch = 0]

# Category-outcome version of the M5 formula: the category-group joins in
# 43/47/63/68 name the outcome column y.
form0 = as.formula(sub("^co2e", "y", lm_formula))

# One result row for an M5-style model of outcome column `ycol` on `d`
# (50/68): slope of the index per index SD with the derived per-hour
# scale, optionally with extra terms appended to the formula.
m5_row = function(d, ycol, spec = "M5", extra = NULL) {
  f = sub("^co2e", ycol, lm_formula)
  if (!is.null(extra)) f = paste(f, "+", extra)
  m = lm(as.formula(f), d)
  ct = coeftest(m, vcov. = vcovHC(m, type = "HC3"))["index", ]
  data.table(outcome = ycol, spec = spec, n = nobs(m), mean = mean(d[[ycol]]),
    per_sd = ct[["Estimate"]], se = ct[["Std. Error"]], p = ct[["Pr(>|t|)"]],
    per_hour = ct[["Estimate"]] / h_per_sd, se_hour = ct[["Std. Error"]] / h_per_sd)
}

# One result row for a category-group outcome (63/64): `d` carries the
# group sum in a y column; `form` defaults to the M5 formula (form0).
fit_row = function(d, outcome, spec, form = form0) {
  m = lm(form, d)
  ct = coeftest(m, vcov. = vcovHC(m, type = "HC3"))["index", ]
  data.table(outcome = outcome, spec = spec, n = nobs(m), mean = mean(d$y),
    per_sd = ct[["Estimate"]], se = ct[["Std. Error"]], p = ct[["Pr(>|t|)"]],
    per_hour = ct[["Estimate"]] / h_per_sd)
}
