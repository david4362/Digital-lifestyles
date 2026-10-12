library(data.table)
library(sandwich)
library(lmtest)

# Calls (q11b_2) has the largest separate item gradient and its removal changes
# the composite estimate. These diagnostics test two concrete explanations:
# nonlinear age confounding and overlap with the other digital-practice items.
# All item columns are z-standardized in 40, so estimates are kg CO2e per item SD.

calls_linear_formula = as.formula(sub(
  "index", "q11b_2", lm_formula, fixed = TRUE))
calls_spline_formula = update(
  calls_linear_formula,
  . ~ . - age + splines::ns(age_years, df = 4)
)

# Conventional bands are a robustness check, not the preferred adjustment:
# they relax linearity but discard exact within-band age information.
calls_data = copy(analysis_data)
calls_data[, age_band := cut(
  age_years,
  breaks = c(-Inf, 29, 39, 49, 59, 69, Inf),
  labels = c("18-29", "30-39", "40-49", "50-59", "60-69", "70+")
)]
calls_band_formula = update(calls_linear_formula, . ~ . - age + age_band)

calls_models = list(
  "M5 linear age" = lm(calls_linear_formula, data = calls_data),
  "M5 age bands" = lm(calls_band_formula, data = calls_data),
  "M5 natural spline age (4 df)" = lm(calls_spline_formula, data = calls_data)
)

calls_age_specs = rbindlist(lapply(names(calls_models), function(spec) {
  model = calls_models[[spec]]
  ct = coeftest(model, vcov. = vcovHC(model, type = "HC3"))["q11b_2", ]
  data.table(
    specification = spec,
    n = nobs(model),
    r2 = summary(model)$r.squared,
    estimate = ct[["Estimate"]],
    se = ct[["Std. Error"]],
    p = ct[["Pr(>|t|)"]]
  )
}))
calls_age_specs[, `:=`(
  lo = estimate - 1.96 * se,
  hi = estimate + 1.96 * se
)]
fwrite(calls_age_specs, file.path(out_dir, "calls_age_specs.csv"))

# Show the calls profile over age without imposing a model shape.
calls_age_desc = calls_data[, .(
  n = sum(!is.na(q11b_2)),
  mean_calls_z = mean(q11b_2, na.rm = TRUE),
  sd_calls_z = sd(q11b_2, na.rm = TRUE)
), by = age_band]
fwrite(calls_age_desc, file.path(out_dir, "calls_age_desc.csv"))

# Refit the existing M0-M5 ladder with calls as the exposure (specs is
# 42_stepwise.R's ladder specification list). The fixed M5
# sample makes coefficient changes attributable to controls rather than sample
# attrition and shows whether age/sex or socioeconomic controls do the work.
calls_stepwise = rbindlist(lapply(names(specs), function(spec) {
  model = lm(as.formula(sub("index", "q11b_2", specs[[spec]], fixed = TRUE)),
    data = calls_data)
  ct = coeftest(model, vcov. = vcovHC(model, type = "HC3"))["q11b_2", ]
  data.table(
    model = spec,
    n = nobs(model),
    r2 = summary(model)$r.squared,
    estimate = ct[["Estimate"]],
    se = ct[["Std. Error"]],
    p = ct[["Pr(>|t|)"]]
  )
}))
calls_stepwise[, `:=`(
  lo = estimate - 1.96 * se,
  hi = estimate + 1.96 * se
)]
fwrite(calls_stepwise, file.path(out_dir, "calls_stepwise.csv"))

# Joint item model: unlike the separate item forest, this estimates each item's
# association conditional on the other ten revised-index items. It is exploratory
# and uses complete cases on all 11 items so both comparison rows share N.
joint_complete = calls_data[complete.cases(calls_data[, ..index_main_items])]
joint_formula = reformulate(c(index_main_items, covariate_vars), response = "co2e")
joint_model = lm(joint_formula, data = joint_complete)
joint_ct = coeftest(joint_model, vcov. = vcovHC(joint_model, type = "HC3"))

calls_separate_complete = lm(calls_linear_formula, data = joint_complete)
calls_separate_ct = coeftest(
  calls_separate_complete,
  vcov. = vcovHC(calls_separate_complete, type = "HC3")
)["q11b_2", ]

calls_joint_comparison = rbind(
  data.table(
    specification = "Calls separately, complete 11-item sample",
    n = nobs(calls_separate_complete),
    estimate = calls_separate_ct[["Estimate"]],
    se = calls_separate_ct[["Std. Error"]],
    p = calls_separate_ct[["Pr(>|t|)"]]
  ),
  data.table(
    specification = "Calls conditional on other 10 items",
    n = nobs(joint_model),
    estimate = joint_ct["q11b_2", "Estimate"],
    se = joint_ct["q11b_2", "Std. Error"],
    p = joint_ct["q11b_2", "Pr(>|t|)"]
  )
)
calls_joint_comparison[, `:=`(
  lo = estimate - 1.96 * se,
  hi = estimate + 1.96 * se
)]
fwrite(calls_joint_comparison, file.path(out_dir, "calls_joint_comparison.csv"))

joint_items = data.table(
  item = index_main_items,
  estimate = joint_ct[index_main_items, "Estimate"],
  se = joint_ct[index_main_items, "Std. Error"],
  p = joint_ct[index_main_items, "Pr(>|t|)"]
)
joint_items[, `:=`(
  n = nobs(joint_model),
  lo = estimate - 1.96 * se,
  hi = estimate + 1.96 * se,
  p_bh = p.adjust(p, method = "BH")
)]
fwrite(joint_items, file.path(out_dir, "item_level_joint.csv"))

# Is the calls gradient broad or concentrated? Estimate the calls coefficient
# for the hypothesis groups and every leaf emissions category. Separate and
# joint-item models use the same complete 11-item sample within each outcome,
# so attenuation reflects adjustment for other digital practices, not sample N.
# Person x category annual CO2e, canonical recipe from 20 (cat_annual is
# defined here rather than reused from an earlier script's local table)
cat_annual = annualise(monthly_co2e, "co2e")
leaf_categories = sort(unique(cat_annual$category))
calls_category_targets = c(
  list(
    total = leaf_categories,
    transport = transport_co2e,
    ecom = ecom_co2e,
    digital = digital_co2e,
    restaurant = "restaurant_co2e"
  ),
  setNames(
    as.list(leaf_categories),
    paste0("leaf_", leaf_categories)
  )
)

# Wide form supplies explicit zeroes for categories with no observed purchase.
# Every category model therefore uses the same people and the mutually exclusive
# leaf coefficients add exactly to the total coefficient in a linear model.
cat_wide = dcast(cat_annual, aid ~ category, value.var = "y", fill = 0)

calls_category = rbindlist(lapply(names(calls_category_targets), function(outcome) {
  categories = calls_category_targets[[outcome]]
  yy = cat_wide[, .(
    aid,
    y = rowSums(.SD)
  ), .SDcols = categories]
  d = joint_complete[yy, on = "aid", nomatch = 0]

  separate_model = lm(update(calls_linear_formula, y ~ .), data = d)
  separate_ct = coeftest(
    separate_model,
    vcov. = vcovHC(separate_model, type = "HC3")
  )["q11b_2", ]

  conditional_model = lm(update(joint_formula, y ~ .), data = d)
  conditional_ct = coeftest(
    conditional_model,
    vcov. = vcovHC(conditional_model, type = "HC3")
  )["q11b_2", ]

  rbind(
    data.table(
      outcome = outcome,
      specification = "Calls separately",
      n = nobs(separate_model),
      mean = mean(d$y),
      estimate = separate_ct[["Estimate"]],
      se = separate_ct[["Std. Error"]],
      p = separate_ct[["Pr(>|t|)"]]
    ),
    data.table(
      outcome = outcome,
      specification = "Calls conditional on other 10 items",
      n = nobs(conditional_model),
      mean = mean(d$y),
      estimate = conditional_ct[["Estimate"]],
      se = conditional_ct[["Std. Error"]],
      p = conditional_ct[["Pr(>|t|)"]]
    )
  )
}))
calls_category[, scope := fcase(
  outcome == "total", "total",
  startsWith(outcome, "leaf_"), "leaf",
  default = "group"
)]
calls_category[, `:=`(
  lo = estimate - 1.96 * se,
  hi = estimate + 1.96 * se,
  pct_of_mean = 100 * estimate / mean,
  p_bh = p.adjust(p, method = "BH")
), by = .(specification, scope)]
calls_category = calls_category[
  calls_category[outcome == "total", .(
    specification,
    total_estimate = estimate
  )],
  on = "specification"
]
calls_category[, share_of_total_pct := 100 * estimate / total_estimate]
calls_category[, total_estimate := NULL]

# The leaf coefficients add exactly to the total by the dcast construction
# above; verify_export check 20 asserts the additivity on the export.
setorder(calls_category, scope, specification, estimate)
fwrite(calls_category, file.path(out_dir, "calls_category.csv"))

# The mixed phone/video-call item cannot identify work meetings. These endline
# associations only test whether frequent calls co-vary with homeworking or
# overtime after M5 controls; they are not treated as mediators or causal tests.
calls_e1 = joint_complete[endline_latest[, .(
  aid, work_home = F88_2, overtime = F88_3
)], on = "aid", nomatch = 0]
calls_e1_outcomes = rbindlist(lapply(c("work_home", "overtime"), function(outcome) {
  model = lm(reformulate(c("q11b_2", covariate_vars), response = outcome),
    data = calls_e1)
  ct = coeftest(model, vcov. = vcovHC(model, type = "HC3"))["q11b_2", ]
  data.table(
    outcome = outcome,
    n = nobs(model),
    estimate = ct[["Estimate"]],
    se = ct[["Std. Error"]],
    p = ct[["Pr(>|t|)"]],
    lo = ct[["Estimate"]] - 1.96 * ct[["Std. Error"]],
    hi = ct[["Estimate"]] + 1.96 * ct[["Std. Error"]]
  )
}))
fwrite(calls_e1_outcomes, file.path(out_dir, "calls_e1_outcomes.csv"))