library(data.table)
library(sandwich)
library(lmtest)

source("05_labels.R")

# All specifications use the fixed M5 complete-case sample created in 40.
# This prevents the coefficient ladder from changing its participants as
# controls are added. The exposure is the standardized pre-registered index
# (per index SD is the headline scale); the per-hour column is derived via
# the anchor slope h_per_sd from 40 and reported as a secondary scale.
#
# Two ladders: the main index (pre-registered construction minus e-commerce
# and online selling, 11 items) and the variant that also drops calls
# (q11b_2, 10 items) — the supervisor's query. Both indices are built in 40
# on the same sample with the same construction.
stepwise_n <- data.table(
  sample = "M0-M5 common complete-case sample",
  n_rows = nrow(analysis_data),
  n_aid = uniqueN(analysis_data$aid)
)
fwrite(stepwise_n, file.path(out_dir, "stepwise_sample.csv"))

specs <- list(
  M0_bivariate = "co2e ~ index",
  M1_sex_age = "co2e ~ index + gender + age",
  M2_income_educ = "co2e ~ index + gender + age + income + income_scb + income_bank + education",
  M3_household = "co2e ~ index + gender + age + income + income_scb + income_bank + education + hh_size + children",
  M4_density = "co2e ~ index + gender + age + income + income_scb + income_bank + education + hh_size + children + density",
  M5_city = lm_formula)

ladder <- function(expo, variant) {
  rbindlist(lapply(names(specs), function(nm) {
    m <- lm(as.formula(sub("index", expo, specs[[nm]], fixed = TRUE)), data = analysis_data)
    ct <- coeftest(m, vcov. = vcovHC(m, type = "HC3"))
    e <- ct[expo, ]
    data.table(index_variant = variant, model = nm, n = nobs(m),
      r2 = summary(m)$r.squared,
      per_sd = e[["Estimate"]], se = e[["Std. Error"]], p = e[["Pr(>|t|)"]],
      per_hour = e[["Estimate"]] / h_per_sd, se_hour = e[["Std. Error"]] / h_per_sd)
  }))
}
stepwise <- rbind(
  ladder("index", variantlab[["main"]]),
  ladder("index_nocalls", variantlab[["nocalls"]]))
stepwise[, `:=`(lo_sd = per_sd - 1.96 * se, hi_sd = per_sd + 1.96 * se,
  lo_hour = per_hour - 1.96 * se_hour, hi_hour = per_hour + 1.96 * se_hour)]
setcolorder(stepwise, c("index_variant", "model", "n", "r2", "per_sd", "se", "p",
  "lo_sd", "hi_sd", "per_hour", "se_hour", "lo_hour", "hi_hour"))
fwrite(stepwise, file.path(out_dir, "stepwise_table.csv"))

# Coefficient ladder (main index only; the no-calls variant is in the table)
png(file.path(out_dir, "stepwise_coef.png"), width = 900, height = 600, res = 120)
par(mar = c(5, 11, 4, 4))
s <- stepwise[index_variant == variantlab[["main"]]]
y <- seq_len(nrow(s))
plot(s$per_sd, y, xlim = range(c(s$lo_sd, s$hi_sd)),
  yaxt = "n", pch = 16, col = "steelblue",
  xlab = "kg CO2e per index SD (HC3 95% CI)", ylab = "",
  main = "Main model: stepwise addition of covariates")
axis(2, y, modellab[s$model], las = 1)
segments(s$lo_sd, y, s$hi_sd, y, col = "steelblue")
abline(v = 0, lty = 2, col = "grey")
mtext(sprintf("index SD = %.2f h/day (anchor, see calibration_check.csv)", h_per_sd),
  side = 3, adj = 1, cex = 0.8, col = "grey40")
dev.off()
