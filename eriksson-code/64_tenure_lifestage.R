library(data.table)
library(sandwich)
library(lmtest)

out_dir = file.path(dirname(cache_dir), "output")
dir.create(out_dir, showWarnings = FALSE)

# Housing-tenure / life-stage confound. The digitally intensive may be
# disproportionately students, singles, apartment-dwellers, and carless —
# each with its own consumption footprint — so part of the headline
# gradient could be life-stage rather than lifestyle. Register fields from
# the LISA row cached in 10 ( FoDelt/HSDelt = university enrollment,
# StudDelt = other study participation, BostBidrFam = housing allowance,
# FamTypF/Civil = family type/marital status); dwelling type and car
# count from the users profile. hometype/FamTypF/Civil levels are never
# assumed (real codes unknown) — shares by observed level, factor
# controls — so the only coded assumptions are the three binaries below.
tenure_data = analysis_data[
  users_latest[, .(`aid`, hometype = `profile.hometype`, ncars = `profile.ncars`)],
  on = "aid", nomatch = 0][
  scb[, .(aid, FoDelt, HSDelt, StudDelt, BostBidrFam, FamTypF, Civil)],
  on = "aid", nomatch = 0]

tenure_data[, student := as.integer(
  rowSums(cbind(FoDelt == 1, HSDelt == 1, StudDelt > 0), na.rm = TRUE) > 0)]
# Housing allowance is only recorded when paid: NA means no benefit.
tenure_data[, bostbidr := as.integer(!is.na(BostBidrFam) & BostBidrFam > 0)]
tenure_data[, carless := as.integer(ncars == 0)]
tenure_data[, FamTypF := factor(FamTypF)]
tenure_data[, hometype := factor(hometype)]

# Complete cases on the tenure fields up front, so the M5 vs M5+tenure
# comparison below reflects the added controls and not a changing sample.
tenure_data = tenure_data[complete.cases(tenure_data[, .(hometype, ncars, FoDelt, HSDelt, FamTypF)])]

# Descriptives by digital quintile: who are the digitally intensive?
# Long format (quintile, variable, level, value) so unlisted factor
# levels need no hard-coding.
tenure_data[, dig_q := cut(index, quantile(index, probs = seq(0, 1, 0.2), na.rm = TRUE),
  labels = paste0("D", 1:5), include.lowest = TRUE)]

tenure_desc = rbindlist(lapply(paste0("D", 1:5), function(q) {
  d = tenure_data[dig_q == q]
  rbind(
    data.table(quintile = q, variable = "n", level = "", value = nrow(d)),
    data.table(quintile = q, variable = "share_student", level = "", value = mean(d$student)),
    data.table(quintile = q, variable = "share_bostbidr", level = "", value = mean(d$bostbidr)),
    data.table(quintile = q, variable = "mean_ncars", level = "", value = mean(d$ncars)),
    data.table(quintile = q, variable = "share_carless", level = "", value = mean(d$carless)),
    d[, .(value = .N / nrow(d)), by = .(level = as.character(hometype))][, `:=`(quintile = q, variable = "hometype")],
    d[, .(value = .N / nrow(d)), by = .(level = as.character(FamTypF))][, `:=`(quintile = q, variable = "famtyp")],
    d[, .(value = .N / nrow(d)), by = .(level = as.character(Civil))][, `:=`(quintile = q, variable = "civil")]
  )
}))
setcolorder(tenure_desc, c("quintile", "variable", "level", "value"))
fwrite(tenure_desc, file.path(out_dir, "tenure_desc.csv"))

# Sensitivity: headline outcomes with tenure/life-stage controls added.
cat_annual = annualise(monthly_co2e, "co2e")
bucket = function(cats) {
  cat_annual[category %in% cats, .(y = sum(y, na.rm = TRUE)), by = aid]
}
outcomes = list(total = NULL, transport = transport_co2e, ecom = ecom_co2e,
  restaurant = "restaurant_co2e")

form_m5 = as.formula(sub("^co2e", "y", lm_formula))
form_plus = update(form_m5, . ~ . + student + FamTypF + hometype + ncars + bostbidr)

fit_row = function(d, outcome, spec, form) {
  m = lm(form, d)
  ct = coeftest(m, vcov. = vcovHC(m, type = "HC3"))["hours_est", ]
  data.table(outcome = outcome, spec = spec, n = nobs(m), mean = mean(d$y),
    per_hour = ct[["Estimate"]], se = ct[["Std. Error"]], p = ct[["Pr(>|t|)"]],
    per_sd = ct[["Estimate"]] * h_per_sd)
}

tenure_sens = rbindlist(lapply(names(outcomes), function(outcome) {
  d = tenure_data[, .(aid, age, gender, income, income_scb, income_bank, density,
    hours_est, hh_size, children, education, major_city,
    student, FamTypF, hometype, ncars, bostbidr)]
  if (is.null(outcomes[[outcome]])) {
    d = d[emissions, on = "aid", nomatch = 0][, y := co2e]
  } else {
    d = d[bucket(outcomes[[outcome]]), on = "aid", nomatch = 0]
  }
  rbind(fit_row(d, outcome, "M5", form_m5),
    fit_row(d, outcome, "M5+tenure", form_plus))
}))
tenure_sens[, `:=`(lo = per_hour - 1.96 * se, hi = per_hour + 1.96 * se)]
fwrite(tenure_sens, file.path(out_dir, "tenure_sensitivity.csv"))

# Stratification (the falsification): the gradient within students vs
# non-students, housing-allowance recipients vs not (the register renter
# proxy), carless vs car owners. Survival within non-student villa-owner
# strata kills the life-stage alternative; collapse there reframes the
# headline. Strata below n = 30 are skipped (too thin to estimate).
strata = list(student = c("non-student", "student"),
  bostbidr = c("no housing allowance", "housing allowance"),
  carless = c("car owners", "carless"))
strat_outcomes = list(total = NULL, transport = transport_co2e, ecom = ecom_co2e)

tenure_strat = rbindlist(lapply(names(strata), function(s) {
  rbindlist(lapply(names(strat_outcomes), function(outcome) {
    rbindlist(lapply(0:1, function(v) {
      d = tenure_data[get(s) == v]
      if (nrow(d) < 30) {
        message("64: skipping ", s, " = ", v, " (n = ", nrow(d), ")")
        return(NULL)
      }
      d = d[, .(aid, age, gender, income, income_scb, income_bank, density,
        hours_est, hh_size, children, education, major_city)]
      if (is.null(strat_outcomes[[outcome]])) {
        d = d[emissions, on = "aid", nomatch = 0][, y := co2e]
      } else {
        d = d[bucket(strat_outcomes[[outcome]]), on = "aid", nomatch = 0]
      }
      m = lm(as.formula(sub("^co2e", "y", lm_formula)), d)
      ct = coeftest(m, vcov. = vcovHC(m, type = "HC3"))["hours_est", ]
      data.table(group = s, level = strata[[s]][v + 1], outcome = outcome,
        n = nobs(m), mean = mean(d$y),
        per_hour = ct[["Estimate"]], se = ct[["Std. Error"]], p = ct[["Pr(>|t|)"]],
        per_sd = ct[["Estimate"]] * h_per_sd)
    }))
  }))
}))
tenure_strat[, `:=`(lo = per_hour - 1.96 * se, hi = per_hour + 1.96 * se)]
fwrite(tenure_strat, file.path(out_dir, "tenure_strat.csv"))
