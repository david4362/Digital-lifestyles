library(data.table)
library(sandwich)
library(lmtest)

out_dir = file.path(dirname(cache_dir), "output")
dir.create(out_dir, showWarnings = FALSE)

# Formal interaction tests behind the heterogeneity claims in 46. The
# margins in het_margins.csv have heavily overlapping confidence intervals,
# so the level differences need explicit tests: each model adds the
# exposure-by-group interaction to the M5 specification, and the interaction
# coefficient is the slope difference against the reference level
# (Kvinna / non-major-city / income quintile Q1). The margins themselves
# stay in 46. Rows with a colon in the coefficient name are the interaction
# terms (R orders the names, e.g. genderMan:hours_est).

# Gender
m_gender = lm(paste0(lm_formula, " + hours_est:gender"), data = analysis_data)
ct = coeftest(m_gender, vcov. = vcovHC(m_gender, type = "HC3"))
i = grep(":", rownames(ct))
gender_rows = data.table(specification = "co2e, M5 + hours x gender",
  term = rownames(ct)[i], n = nobs(m_gender),
  estimate = ct[i, "Estimate"], se = ct[i, "Std. Error"], p = ct[i, "Pr(>|t|)"],
  per_sd = ct[i, "Estimate"] * h_per_sd)

# Major city
m_city = lm(paste0(lm_formula, " + hours_est:major_city"), data = analysis_data)
ct = coeftest(m_city, vcov. = vcovHC(m_city, type = "HC3"))
i = grep(":", rownames(ct))
city_rows = data.table(specification = "co2e, M5 + hours x major city",
  term = rownames(ct)[i], n = nobs(m_city),
  estimate = ct[i, "Estimate"], se = ct[i, "Std. Error"], p = ct[i, "Pr(>|t|)"],
  per_sd = ct[i, "Estimate"] * h_per_sd)

# Income quintile, on the e-commerce outcome where the Q1 gradient looked
# flat against Q2-Q5 (50). The interaction coefficients are the slope
# differences of Q2-Q5 against Q1.
ecom_annual = annualise(monthly_co2e, "co2e")[category %in% ecom_co2e, .(ecom = sum(y)), by = aid]
ecom_data = ecom_annual[analysis_data, on = "aid", nomatch = 0]
m_q = lm(sub("co2e", "ecom", paste0(lm_formula, " + hours_est:income_q")), data = ecom_data)
ct = coeftest(m_q, vcov. = vcovHC(m_q, type = "HC3"))
i = grep(":", rownames(ct))
q_rows = data.table(specification = "ecom co2e, M5 + hours x income quintile",
  term = rownames(ct)[i], n = nobs(m_q),
  estimate = ct[i, "Estimate"], se = ct[i, "Std. Error"], p = ct[i, "Pr(>|t|)"],
  per_sd = ct[i, "Estimate"] * h_per_sd)

het_interactions = rbind(gender_rows, city_rows, q_rows)
fwrite(het_interactions, file.path(out_dir, "het_interactions.csv"))
