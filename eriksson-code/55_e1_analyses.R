library(data.table)
library(sandwich)
library(lmtest)

out_dir = file.path(dirname(cache_dir), "output")
dir.create(out_dir, showWarnings = FALSE)

# E1 outcomes: latest endline response per aid (endline_latest from 30)
e1_data <- analysis_data[endline_latest[, .(
  aid,
  work_home = F88_2,
  overtime = F88_3,
  unaffordable = F88_10,
  bnpl = F88_19
)], on = "aid", nomatch = 0]

e1_data[, `:=`(
  work_home_ever = as.integer(work_home > 1),
  overtime_ever = as.integer(overtime > 1),
  unaffordable_ever = as.integer(unaffordable > 1),
  bnpl_ever = as.integer(bnpl > 1)
)]

# E1 outcomes against the anchored digital measure, using the M5 covariates.
e1_outcomes <- c(
  "work_home", "overtime", "unaffordable", "bnpl",
  "work_home_ever", "overtime_ever", "unaffordable_ever", "bnpl_ever"
)

e1_index <- rbindlist(lapply(e1_outcomes, function(outcome) {
  m <- lm(as.formula(sub("^co2e", outcome, lm_formula)), data = e1_data)
  ct <- coeftest(m, vcov. = vcovHC(m, type = "HC3"))["hours_est", ]
  data.table(
    outcome = outcome,
    n = nobs(m),
    estimate = ct[["Estimate"]],
    se = ct[["Std. Error"]],
    p = ct[["Pr(>|t|)"]],
    per_sd = ct[["Estimate"]] * h_per_sd
  )
}))
e1_index[, `:=`(lo = estimate - 1.96 * se, hi = estimate + 1.96 * se)]
fwrite(e1_index, file.path(out_dir, "e1_index_outcomes.csv"))

# Category annual emissions, canonical recipe from 20
cat_annual <- annualise(monthly_co2e, "co2e")

transport_annual <- cat_annual[category %in% transport_co2e, .(transport_co2e = sum(y, na.rm = T)), by = aid]
transport_data <- e1_data[transport_annual, on = "aid", nomatch = 0]
# Both specifications use the same participants: rows missing work_home are
# dropped up front, so the coefficient comparison reflects the added control
# and not a changing sample.
transport_data <- transport_data[!is.na(work_home)]

transport_formula <- as.formula(sub("^co2e", "transport_co2e", lm_formula))
transport_without_work <- lm(transport_formula, data = transport_data)
transport_with_work <- lm(update(transport_formula, . ~ . + work_home), data = transport_data)

# HC3 hours_est estimate for each specification (coeftest computed once)
ct_without <- coeftest(transport_without_work, vcov. = vcovHC(transport_without_work, type = "HC3"))["hours_est", ]
ct_with <- coeftest(transport_with_work, vcov. = vcovHC(transport_with_work, type = "HC3"))["hours_est", ]

transport_results <- rbind(
  data.table(
    specification = "Without work from home",
    n = nobs(transport_without_work),
    estimate = ct_without[["Estimate"]],
    se = ct_without[["Std. Error"]],
    p = ct_without[["Pr(>|t|)"]],
    per_sd = ct_without[["Estimate"]] * h_per_sd
  ),
  data.table(
    specification = "With work from home",
    n = nobs(transport_with_work),
    estimate = ct_with[["Estimate"]],
    se = ct_with[["Std. Error"]],
    p = ct_with[["Pr(>|t|)"]],
    per_sd = ct_with[["Estimate"]] * h_per_sd
  )
)
transport_results[, `:=`(lo = estimate - 1.96 * se, hi = estimate + 1.96 * se)]
fwrite(transport_results, file.path(out_dir, "e1_transport_work_home.csv"))

# E-commerce shares in CO2e and SEK, with and without affordability/BNPL
# controls. These follow the level/share construction in 50_ecommerce.R;
# ecom groups are defined in 20.
co2e_wide <- cat_annual[category %in% ecom_co2e, .(ecom = sum(y, na.rm = T)), by = aid][
  cat_annual[, .(total = sum(y, na.rm = T)), by = aid], on = "aid"]
co2e_wide[, share_co2e := ecom / total]

kr_annual <- annualise(monthly_kr[category %notin% excluded_kr], "kr")
kr_wide <- kr_annual[category %in% ecom_kr, .(ecom = sum(y, na.rm = T)), by = aid][
  kr_annual[, .(total = sum(y, na.rm = T)), by = aid], on = "aid"]
kr_wide[, share_kr := ecom / total]

share_data <- e1_data[co2e_wide[, .(aid, share_co2e)], on = "aid", nomatch = 0]
share_data <- share_data[kr_wide[, .(aid, share_kr)], on = "aid", nomatch = 0]
# Same idea as the transport comparison: drop rows missing the
# affordability/BNPL items up front so both specifications share participants.
share_data <- share_data[!is.na(unaffordable) & !is.na(bnpl)]

share_results <- rbindlist(lapply(c("share_co2e", "share_kr"), function(outcome) {
  formula_without <- as.formula(sub("^co2e", outcome, lm_formula))
  formula_with <- update(formula_without, . ~ . + unaffordable + bnpl)
  model_without <- lm(formula_without, data = share_data)
  model_with <- lm(formula_with, data = share_data)
  ct_without <- coeftest(model_without, vcov. = vcovHC(model_without, type = "HC3"))["hours_est", ]
  ct_with <- coeftest(model_with, vcov. = vcovHC(model_with, type = "HC3"))["hours_est", ]

  rbind(
    data.table(
      outcome = outcome,
      specification = "Without affordability/BNPL controls",
      n = nobs(model_without),
      estimate = ct_without[["Estimate"]],
      se = ct_without[["Std. Error"]],
      p = ct_without[["Pr(>|t|)"]],
      per_sd = ct_without[["Estimate"]] * h_per_sd
    ),
    data.table(
      outcome = outcome,
      specification = "With affordability/BNPL controls",
      n = nobs(model_with),
      estimate = ct_with[["Estimate"]],
      se = ct_with[["Std. Error"]],
      p = ct_with[["Pr(>|t|)"]],
      per_sd = ct_with[["Estimate"]] * h_per_sd
    )
  )
}))
share_results[, `:=`(lo = estimate - 1.96 * se, hi = estimate + 1.96 * se)]
fwrite(share_results, file.path(out_dir, "e1_ecommerce_share_controls.csv"))
