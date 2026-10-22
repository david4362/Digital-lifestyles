library(data.table)
library(sandwich)
library(lmtest)

# Calls-sociality diagnostics (RA checklist item 3). Calls carries the item
# gradient, and the sociality reading says that is because calls marks a
# socially active life. Two exports test that directly. Associations: the
# calls item against each endline social-activity item and the out-of-home
# composite from 67. Adjustment: the calls gradient on total, transport and
# restaurant emissions with and without that composite, on one shared sample,
# so the change in the calls coefficient is the share the activities account
# for. q11b_2 is the analysis-sample z-score from 40.

ooh_items = c("library", "sports_event", "culture_event", "dinner_guests",
  "dancing", "exercised", "nature")
calls_e1 = analysis_data[endline_latest[, .(
  aid,
  library = F88_4, sports_event = F88_5, culture_event = F88_6,
  dinner_guests = F88_7, dancing = F88_8, exercised = F88_18, nature = F88_21
)], on = "aid", nomatch = 0]
calls_e1 = calls_e1[!is.na(q11b_2)]
calls_e1[, ooh_leisure := rowMeans(.SD, na.rm = TRUE), .SDcols = ooh_items]

calls_social_activity_associations = rbindlist(lapply(c(ooh_items, "ooh_leisure"),
  function(outcome) {
    m = lm(as.formula(sub("^co2e", outcome, sub("index", "q11b_2", lm_formula,
      fixed = TRUE))), data = calls_e1)
    ct = coeftest(m, vcov. = vcovHC(m, type = "HC3"))["q11b_2", ]
    data.table(outcome = outcome, n = nobs(m),
      estimate = ct[["Estimate"]], se = ct[["Std. Error"]], p = ct[["Pr(>|t|)"]],
      lo = ct[["Estimate"]] - 1.96 * ct[["Std. Error"]],
      hi = ct[["Estimate"]] + 1.96 * ct[["Std. Error"]])
  }))
fwrite(calls_social_activity_associations,
  file.path(out_dir, "calls_social_activity_associations.csv"))

# One sample for the with/without comparison: calls observed and the
# composite defined (67's rule).
adj = calls_e1[!is.na(ooh_leisure)]
transport_annual = group_annual(annualise(monthly_co2e, "co2e"), transport_co2e)
setnames(transport_annual, "y", "transport_co2e")
restaurant_annual = group_annual(annualise(monthly_co2e, "co2e"), "restaurant_co2e")
setnames(restaurant_annual, "y", "restaurant_co2e")
adj = transport_annual[adj, on = "aid"]
adj = restaurant_annual[adj, on = "aid"]

fit_calls = function(outcome, specification, extra = NULL) {
  f = sub("^co2e", outcome, sub("index", "q11b_2", lm_formula, fixed = TRUE))
  form = as.formula(f)
  if (!is.null(extra)) form = update(form, as.formula(paste(". ~ . +", extra)))
  m = lm(form, data = adj)
  ct = coeftest(m, vcov. = vcovHC(m, type = "HC3"))
  med = if ("ooh_leisure" %in% rownames(ct)) ct["ooh_leisure", ] else
    c(Estimate = NA_real_, `Std. Error` = NA_real_, `Pr(>|t|)` = NA_real_)
  data.table(outcome = outcome, specification = specification, n = nobs(m),
    per_sd = ct["q11b_2", "Estimate"], se = ct["q11b_2", "Std. Error"],
    p = ct["q11b_2", "Pr(>|t|)"],
    lo = ct["q11b_2", "Estimate"] - 1.96 * ct["q11b_2", "Std. Error"],
    hi = ct["q11b_2", "Estimate"] + 1.96 * ct["q11b_2", "Std. Error"],
    ooh_coef = med[["Estimate"]], ooh_se = med[["Std. Error"]],
    ooh_p = med[["Pr(>|t|)"]])
}

calls_social_activity_adjustment = rbindlist(lapply(
  c("co2e", "transport_co2e", "restaurant_co2e"), function(outcome) {
    rbind(
      fit_calls(outcome, "M5, calls only"),
      fit_calls(outcome, "M5, calls + out-of-home leisure", "ooh_leisure"))
  }))
ref = calls_social_activity_adjustment[specification == "M5, calls only",
  .(outcome, ref_per_sd = per_sd)]
calls_social_activity_adjustment[ref, pct_gradient_shared :=
  (ref_per_sd - per_sd) / ref_per_sd * 100, on = "outcome"]
fwrite(calls_social_activity_adjustment,
  file.path(out_dir, "calls_social_activity_adjustment.csv"))
