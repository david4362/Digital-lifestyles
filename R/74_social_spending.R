library(data.table)
library(sandwich)
library(lmtest)

# Social-media and gaming spending gradients (RA checklist item 4). The
# sociality comparison in social_games.csv is CO2e, and the manuscript must
# not reuse those models as spending results. Each exposure is entered
# separately, fully adjusted, for the four spending categories named in the
# checklist. Social media and gaming are the analysis-sample item z-scores.
# gaming_plus_console is the sum of the gaming and console z-scores,
# re-standardized, so that row is per SD of the sum rather than the
# unstandardized sum used in social_games.csv.

d = copy(analysis_data)
d[, gaming_plus_console := as.vector(scale(q11b_5 + q11_4))]
exposures = c(social_media = "q11b_3", gaming = "q11b_5",
  gaming_plus_console = "gaming_plus_console")

kr_annual = annualise(monthly_kr[category %notin% excluded_kr], "kr")
outcomes = list(
  restaurants = "restaurant_kr",
  transport = transport_kr,
  ecom_goods = ecom_kr,
  digital_services = digital_kr)

social_spending_sek = rbindlist(lapply(names(exposures), function(expo_name) {
  expo = exposures[[expo_name]]
  rbindlist(lapply(names(outcomes), function(outcome) {
    yy = group_annual(kr_annual, outcomes[[outcome]])
    dd = d[yy, on = "aid", nomatch = 0]
    # Drop incomplete rows up front so n, the category mean and the model
    # describe the same people (item missingness differs by exposure).
    dd = dd[complete.cases(dd[, c(expo, "y", covariate_vars), with = FALSE])]
    f = sub("^co2e", "y", sub("index", expo, lm_formula, fixed = TRUE))
    m = lm(as.formula(f), data = dd)
    ct = coeftest(m, vcov. = vcovHC(m, type = "HC3"))[expo, ]
    est = ct[["Estimate"]]
    se = ct[["Std. Error"]]
    data.table(exposure = expo_name, outcome = outcome, unit = "SEK/yr",
      n = nobs(m), mean = mean(dd$y),
      per_sd = est, se = se, p = ct[["Pr(>|t|)"]],
      lo = est - 1.96 * se, hi = est + 1.96 * se,
      pct_of_mean = 100 * est / mean(dd$y))
  }))
}))
fwrite(social_spending_sek, file.path(out_dir, "social_spending_sek.csv"))
