library(data.table)
library(sandwich)
library(lmtest)

out_dir = file.path(dirname(cache_dir), "output")
dir.create(out_dir, showWarnings = FALSE)

# Preregistration adherence. The pipeline index requires the complete
# 13-item battery, z-scales the items on all battery respondents and does
# not re-standardize after averaging. The preregistration allows >= 10 of 13
# answered. All variants are reported as the M5 slope per index SD, which is
# the same scale as the per_sd column of the stepwise table (per_hour x
# h_per_sd equals the slope on the z-scored index, since hours_est is a
# linear transform of the index).
#
# The baseline row (pipeline index, z-scored in the analysis sample)
# therefore reproduces the headline per_sd by construction; the interesting
# rows are the variants.

items = survey_latest[, c("aid", q11_cols), with = FALSE]
m_items = as.matrix(items[, ..q11_cols])

# Run the M5 specification on a z-scored index variant: one row for the
# variant table.
run_variant = function(d, index_variant, label) {
  d = copy(d)
  d[, index_variant := as.vector(scale(index_variant))]
  m = lm(sub("hours_est", "index_variant", lm_formula, fixed = TRUE), data = d)
  ct = coeftest(m, vcov. = vcovHC(m, type = "HC3"))["index_variant", ]
  data.table(variant = label, n = nobs(m),
    per_sd = ct[["Estimate"]], se = ct[["Std. Error"]], p = ct[["Pr(>|t|)"]])
}

# Baseline: the pipeline index (items z-scaled on all battery respondents,
# complete battery), z-scored in the analysis sample.
base_row = run_variant(analysis_data, analysis_data$index,
  "Baseline: pipeline index, z-scored")

# Variant B: items z-scaled on the analysis sample instead of on all
# battery respondents.
mu_b = unlist(items[aid %in% analysis_data$aid, lapply(.SD, mean, na.rm = TRUE), .SDcols = q11_cols])
sd_b = unlist(items[aid %in% analysis_data$aid, lapply(.SD, sd, na.rm = TRUE), .SDcols = q11_cols])
index_b = rowMeans((m_items - mu_b) / sd_b)
d_b = items[, .(aid)][, index_b := index_b][analysis_data, on = "aid", nomatch = 0]
b_row = run_variant(d_b, d_b$index_b, "Items z-scaled on the analysis sample")

# Variant A: the preregistration battery rule. Rebuilds the 20/30/40 sample
# flow with the complete-battery requirement replaced by >= 10 answered,
# everything else identical. Items are z-scaled on the complete-battery
# sample exactly as in 30; the index averages the answered items.
n_answered = rowSums(!is.na(m_items))
battery = items[complete.cases(items)]
mu_a = unlist(battery[, lapply(.SD, mean, na.rm = TRUE), .SDcols = q11_cols])
sd_a = unlist(battery[, lapply(.SD, sd, na.rm = TRUE), .SDcols = q11_cols])
index_a = fifelse(n_answered >= 10, rowMeans((m_items - mu_a) / sd_a, na.rm = TRUE), NA_real_)
device_use_a = data.table(aid = items$aid, index_a = index_a)[!is.na(index_a)]

# Spending filter, mirroring 20 with answered_survey replaced by the
# relaxed battery rule.
spending_a = (monthly_kr[category %notin% excluded_kr]
  [, .(kr = sum(kr, na.rm = T)), by = .(aid, month)]
  [kr > min_spend]
  [aid %in% device_use_a$aid]
  [survey_latest, on = "aid", nomatch = 0]
  [, submitdate := as.Date(submitdate)]
  [submitdate - 31 * x_months < month & month < submitdate]
  [, n := .N, by = aid]
  [n >= min_months])
keep_a = unique(spending_a[, .(aid, month)])

# Outcome, mirroring the annualise() recipe with keep_a.
emissions_a = (monthly_co2e[keep_a, on = .(aid, month), nomatch = 0]
  [, .(s = sum(co2e), n_months = uniqueN(month)), by = .(aid, category)]
  [n_months >= min_months]
  [, y := (s / n_months) * 12]
  [, .(q99 = quantile(y, .99, na.rm = TRUE), y = y, aid = aid), by = category]
  [, y := pmin(y, q99)]
  [, .(co2e = sum(y)), by = aid])

# Controls, mirroring 40 (only the M5 variables; income_q and deso are not
# part of the formula).
control_a = (keep_a
  [scb, on = "aid", nomatch = 0]
  [, density := log(density) - mean(log(density), na.rm = T)]
  [, education := factor(fcase(
    Sun2020Niva < 300, "Grundskola",
    Sun2020Niva < 400, "Gymnasium",
    Sun2020Niva < 500, "Eftergymnasial <2 år",
    Sun2020Niva < 600, "Eftergymnasial >=2 år",
    Sun2020Niva >= 600, "Forskare"
  ))]
  [demographics_unique, on = "aid", nomatch = 0]
  [, age := age - mean(age, na.rm = T)]
  [, major_city := fifelse(postort %in% c("Stockholm", "Göteborg", "Malmö"), T, F)]
  [users_latest[, .(aid, `income-level`, profile.field_profile_household_adults, profile.field_profile_household_children)], on = "aid", nomatch = 0]
  [, hh_size := profile.field_profile_household_adults + profile.field_profile_household_children]
  [, children := factor(profile.field_profile_household_children > 0)]
  [, income := log1p(`income-level`) - mean(log1p(`income-level`), na.rm = T)]
  [, income_scb := log1p(pmax(DispInk04, 0)) - mean(log1p(pmax(DispInk04, 0)), na.rm = T)]
  [device_use_a, on = "aid", nomatch = 0]
  [, .(aid, index_a, age, gender, income, income_scb, density, hh_size, children, education, major_city)]) |>
  unique()
control_a = person_bank[, .(aid, income_bank_raw)][control_a, on = "aid"]
control_a[, income_bank := log1p(income_bank_raw) - mean(log1p(income_bank_raw), na.rm = T)]
control_a[, income_bank_raw := NULL]
# Complete-case sample on the variant-A variables, mirroring 40.
formula_a = sub("hours_est", "index_a", lm_formula, fixed = TRUE)
vars_a = all.vars(as.formula(formula_a))
lm_data_a = control_a[emissions_a, on = "aid", nomatch = 0]
d_a = lm_data_a[complete.cases(lm_data_a[, ..vars_a])]
a_row = run_variant(d_a, d_a$index_a,
  "Preregistration rule: >= 10 of 13 answered")

# Full preregistration index: >= 10 of 13 answered AND items z-scaled on the
# analysis sample (the variant-B scaling) AND re-standardized after
# averaging (which the z-scoring in run_variant does). Same sample as variant
# A, since the scaling does not change who qualifies.
device_use_full = data.table(aid = items$aid,
  index_full = fifelse(n_answered >= 10, rowMeans((m_items - mu_b) / sd_b, na.rm = TRUE), NA_real_))[
  !is.na(index_full)]
d_a = d_a[device_use_full[, .(aid, index_full)], on = "aid", nomatch = 0]
full_row = run_variant(d_a, d_a$index_full,
  "Full preregistration index (>= 10 of 13, analysis-sample scaling)")

index_variants = rbind(base_row, b_row, a_row, full_row)
index_variants[, `:=`(lo = per_sd - 1.96 * se, hi = per_sd + 1.96 * se)]
fwrite(index_variants, file.path(out_dir, "index_variants.csv"))
