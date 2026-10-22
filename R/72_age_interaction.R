library(data.table)
library(sandwich)
library(lmtest)

# Joint test of the pre-specified age-group interactions (RA checklist item 2).
# 46 reports the four level slopes and 58 tests gender, city and income
# quintile, but not the age bands jointly. The bands are 46's cuts, so this
# test matches het_margins.csv rather than the finer calls-diagnostic bands.
# The index coefficient is the slope at 18-29; each interaction is the
# difference from that reference. The joint HC3 Wald test of those
# interactions is the F-test that the slopes are equal across bands.

bands = demographics_unique[, .(aid, band = cut(age, c(18, 30, 45, 65, Inf),
  labels = c("18-29", "30-44", "45-64", "65+"), right = FALSE))]
d = analysis_data[bands, on = "aid", nomatch = 0]
d = d[!is.na(band)]
d[, band := factor(band, levels = c("18-29", "30-44", "45-64", "65+"))]

m = lm(update(as.formula(lm_formula), . ~ . + index:band), data = d)
ct = coeftest(m, vcov. = vcovHC(m, type = "HC3"))
V = vcovHC(m, type = "HC3")
b = coef(m)
interact = grep(":", names(b), value = TRUE)
interact = interact[grepl("band", interact)]
q = length(interact)
W = as.numeric(t(b[interact]) %*% solve(V[interact, interact, drop = FALSE]) %*% b[interact])
Fstat = W / q
df2 = df.residual(m)

term_names = c("index", interact)
term_rows = data.table(
  term = c("index (reference: 18-29)", interact),
  n = nobs(m),
  estimate = ct[term_names, "Estimate"],
  se = ct[term_names, "Std. Error"],
  statistic = "t",
  stat = ct[term_names, "t value"],
  df1 = NA_integer_,
  df2 = df2,
  p = ct[term_names, "Pr(>|t|)"]
)
joint = data.table(
  term = "joint index x age band",
  n = nobs(m),
  estimate = Fstat,
  se = NA_real_,
  statistic = "F",
  stat = Fstat,
  df1 = q,
  df2 = df2,
  p = pf(Fstat, q, df2, lower.tail = FALSE)
)
age_band_interaction = rbind(term_rows, joint)
age_band_interaction[, `:=`(
  lo = fifelse(statistic == "t", estimate - 1.96 * se, NA_real_),
  hi = fifelse(statistic == "t", estimate + 1.96 * se, NA_real_),
  n_outside_bands = nrow(analysis_data) - nrow(d)
)]
fwrite(age_band_interaction, file.path(out_dir, "age_band_interaction.csv"))
