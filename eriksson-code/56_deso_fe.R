library(data.table)
library(sandwich)
library(lmtest)

out_dir = file.path(dirname(cache_dir), "output")
dir.create(out_dir, showWarnings = FALSE)

# Within-neighborhood comparison: DeSO fixed effects (DeSO areas from the
# SCB register, carried through 40). Density is a DeSO-level attribute, so
# it is absorbed by the fixed effects and dropped from the formula instead
# of left in as a collinear term.
#
# People in singleton desos are excluded: their fixed effect absorbs their
# outcome completely, so they contribute no within-neighborhood variation
# to the slope, and their leverage of exactly 1 makes the HC3 sandwich
# undefined. The exclusion is reported below.
deso_sizes = analysis_data[, .N, by = deso]
fe_data = deso_sizes[N >= 2][analysis_data, on = "deso", nomatch = 0]
m_fe = lm(as.formula(paste(gsub("+density", "", lm_formula, fixed = TRUE),
  "+ factor(deso)")), data = fe_data)
ct = coeftest(m_fe, vcov. = vcovHC(m_fe, type = "HC3"))["hours_est", ]

deso_fe = data.table(
  specification = "M5 + DeSO fixed effects (desos with >= 2 people)",
  n = nobs(m_fe),
  n_deso = nrow(deso_sizes),
  n_deso_used = uniqueN(fe_data$deso),
  median_people_per_deso = median(deso_sizes$N),
  people_in_singleton_deso = deso_sizes[N == 1, sum(N)],
  per_hour = ct[["Estimate"]],
  se = ct[["Std. Error"]],
  p = ct[["Pr(>|t|)"]])
deso_fe[, per_sd := per_hour * h_per_sd]
deso_fe[, `:=`(lo = per_hour - 1.96 * se, hi = per_hour + 1.96 * se)]
fwrite(deso_fe, file.path(out_dir, "deso_fe.csv"))
