library(data.table)
library(sandwich)
library(lmtest)

# Same M5 complete-case sample as the headline analysis, restricted to
# valid E4 reporters (e4_data from 40). This is also the sample used for
# the index comparison in 60.

# RQ1: total emissions, first with E4 screen time and then with the anchored
# index measure on exactly the same E4 sample. This table is deliberately in
# per-hour units: measured hours/day (E4) vs anchored hours/day (hours_est)
# is the like-for-like comparison. The headline scale of the paper is per
# index SD (42/59); the per-own-SD comparison of the two exposures and the
# formal difference test live in 60.
e4_specs = list(
  E4_M0_bivariate = "co2e ~ time",
  E4_M1_sex_age = "co2e ~ time + gender + age",
  E4_M2_income_educ = "co2e ~ time + gender + age + income + income_scb + income_bank + education",
  E4_M3_household = "co2e ~ time + gender + age + income + income_scb + income_bank + education + hh_size + children",
  E4_M4_density = "co2e ~ time + gender + age + income + income_scb + income_bank + education + hh_size + children + density",
  E4_M5_city = sub("index", "time", lm_formula, fixed = TRUE),
  Index_same_E4_M0_bivariate = "co2e ~ hours_est",
  Index_same_E4_M1_sex_age = "co2e ~ hours_est + gender + age",
  Index_same_E4_M2_income_educ = "co2e ~ hours_est + gender + age + income + income_scb + income_bank + education",
  Index_same_E4_M3_household = "co2e ~ hours_est + gender + age + income + income_scb + income_bank + education + hh_size + children",
  Index_same_E4_M4_density = "co2e ~ hours_est + gender + age + income + income_scb + income_bank + education + hh_size + children + density",
  Index_same_E4_M5_city = sub("index", "hours_est", lm_formula, fixed = TRUE)
)

rq1_e4 = rbindlist(lapply(names(e4_specs), function(nm) {
  m = lm(as.formula(e4_specs[[nm]]), data = e4_data)
  ct = coeftest(m, vcov. = vcovHC(m, type = "HC3"))
  exposure = if (grepl("^E4_", nm)) "E4 screen time" else "Index, same E4 sample"
  variable = if (grepl("^E4_", nm)) "time" else "hours_est"
  e = ct[variable, ]
  data.table(
    model = nm,
    exposure = exposure,
    n = nobs(m),
    r2 = summary(m)$r.squared,
    per_hour = e[["Estimate"]],
    se = e[["Std. Error"]],
    p = e[["Pr(>|t|)"]]
  )
}))
rq1_e4[, `:=`(lo = per_hour - 1.96 * se, hi = per_hour + 1.96 * se)]
fwrite(rq1_e4, file.path(out_dir, "e4_rq1_robustness.csv"))

# Person x category annual emissions, canonical recipe from 20 (same rule
# as the headline total and the RQ2 decomposition)
cat_annual = annualise(monthly_co2e, "co2e")

# Hypothesis groups: category vectors defined in 20; the target list
# (groups + total + top-10) is 20's decomp_targets
targets = decomp_targets(cat_annual, list(
  transport = transport_co2e, ecom = ecom_co2e, digital = digital_co2e,
  placebo_insurance = placebo_co2e, vehicles = vehicles_co2e))

base = e4_data[, .(aid, age, gender, income, income_scb, income_bank,
  density, time, hours_est, hh_size, children, education, major_city)]
form_e4 = sub("^co2e", "y", sub("index", "time", lm_formula, fixed = TRUE))
form_index = sub("^co2e", "y", sub("index", "hours_est", lm_formula, fixed = TRUE))

rq2_e4 = rbindlist(lapply(names(targets), function(nm) {
  cats = targets[[nm]]
  yy = group_annual(cat_annual, cats)
  d = base[yy, on = "aid", nomatch = 0]

  e4_model = lm(as.formula(form_e4), data = d)
  e4_ct = coeftest(e4_model, vcov. = vcovHC(e4_model, type = "HC3"))["time", ]
  index_model = lm(as.formula(form_index), data = d)
  index_ct = coeftest(index_model, vcov. = vcovHC(index_model, type = "HC3"))["hours_est", ]

  data.table(
    cat = nm,
    n_e4 = nobs(e4_model),
    per_hour_e4 = e4_ct[["Estimate"]],
    se_e4 = e4_ct[["Std. Error"]],
    p_e4 = e4_ct[["Pr(>|t|)"]],
    n_index_same_e4 = nobs(index_model),
    per_hour_index_same_e4 = index_ct[["Estimate"]],
    se_index_same_e4 = index_ct[["Std. Error"]],
    p_index_same_e4 = index_ct[["Pr(>|t|)"]]
  )
}))
rq2_e4[, `:=`(
  lo_e4 = per_hour_e4 - 1.96 * se_e4,
  hi_e4 = per_hour_e4 + 1.96 * se_e4,
  lo_index_same_e4 = per_hour_index_same_e4 - 1.96 * se_index_same_e4,
  hi_index_same_e4 = per_hour_index_same_e4 + 1.96 * se_index_same_e4
)]
fwrite(rq2_e4, file.path(out_dir, "e4_rq2_robustness.csv"))
