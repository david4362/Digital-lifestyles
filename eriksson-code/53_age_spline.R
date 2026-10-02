library(data.table)
library(sandwich)
library(lmtest)

out_dir = file.path(dirname(cache_dir), "output")
dir.create(out_dir, showWarnings = FALSE)

linear_model <- lm(as.formula(lm_formula), data = analysis_data)
age_spline_formula <- update(
  as.formula(lm_formula),
  . ~ . - age + splines::ns(age, df = 4)
)
spline_model <- lm(age_spline_formula, data = analysis_data)

linear_ct <- coeftest(linear_model, vcov. = vcovHC(linear_model, type = "HC3"))["hours_est", ]
spline_ct <- coeftest(spline_model, vcov. = vcovHC(spline_model, type = "HC3"))["hours_est", ]

age_spline_results <- rbind(
  data.table(
    model = "M5 linear age",
    n = nobs(linear_model),
    r2 = summary(linear_model)$r.squared,
    per_hour = linear_ct[["Estimate"]],
    se = linear_ct[["Std. Error"]],
    p = linear_ct[["Pr(>|t|)"]],
    per_sd = linear_ct[["Estimate"]] * h_per_sd
  ),
  data.table(
    model = "M5 natural spline age (4 df)",
    n = nobs(spline_model),
    r2 = summary(spline_model)$r.squared,
    per_hour = spline_ct[["Estimate"]],
    se = spline_ct[["Std. Error"]],
    p = spline_ct[["Pr(>|t|)"]],
    per_sd = spline_ct[["Estimate"]] * h_per_sd
  )
)
age_spline_results[, `:=`(
  lo = per_hour - 1.96 * se,
  hi = per_hour + 1.96 * se
)]
fwrite(age_spline_results, file.path(out_dir, "age_spline_rq1.csv"))
