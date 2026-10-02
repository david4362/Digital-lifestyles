library(data.table)
library(sandwich)
library(lmtest)

out_dir = file.path(dirname(cache_dir), "output")
dir.create(out_dir, showWarnings = FALSE)

source("05_labels.R")

# All specifications use the fixed M5 complete-case sample created in 40.
# This prevents the coefficient ladder from changing its participants as
# controls are added. The per-SD conversion h_per_sd (hours per SD of the
# index in this same sample) is defined in 40.
stepwise_n <- data.table(
  sample = "M0-M5 common complete-case sample",
  n_rows = nrow(analysis_data),
  n_aid = uniqueN(analysis_data$aid)
)
fwrite(stepwise_n, file.path(out_dir, "stepwise_sample.csv"))

specs <- list(
  M0_bivariate = "co2e ~ hours_est",
  M1_sex_age = "co2e ~ hours_est + gender + age",
  M2_income_educ = "co2e ~ hours_est + gender + age + income + income_scb + income_bank + education",
  M3_household = "co2e ~ hours_est + gender + age + income + income_scb + income_bank + education + hh_size + children",
  M4_density = "co2e ~ hours_est + gender + age + income + income_scb + income_bank + education + hh_size + children + density",
  M5_city = lm_formula)

rows <- lapply(names(specs), function(nm) {
  m <- lm(as.formula(specs[[nm]]), data = analysis_data)
  ct <- coeftest(m, vcov. = vcovHC(m, type = "HC3"))
  e <- ct["hours_est", ]
  data.table(model = nm, n = nobs(m), r2 = summary(m)$r.squared,
    per_hour = e[["Estimate"]], se_hour = e[["Std. Error"]], p = e[["Pr(>|t|)"]],
    per_sd = e[["Estimate"]] * h_per_sd, se_sd = e[["Std. Error"]] * h_per_sd)
})
stepwise <- rbindlist(rows)
stepwise[, `:=`(lo_hour = per_hour - 1.96 * se_hour, hi_hour = per_hour + 1.96 * se_hour)]
fwrite(stepwise, file.path(out_dir, "stepwise_table.csv"))

# Coefficient ladder: per hour (per-SD axis = * h_per_sd)
png(file.path(out_dir, "stepwise_coef.png"), width = 900, height = 600, res = 120)
par(mar = c(5, 11, 4, 4))
y <- seq_len(nrow(stepwise))
plot(stepwise$per_hour, y, xlim = range(c(stepwise$lo_hour, stepwise$hi_hour)),
  yaxt = "n", pch = 16, col = "steelblue",
  xlab = "kg CO2e per extra hour/day (HC3 95% CI)", ylab = "",
  main = "Main model: stepwise addition of covariates")
axis(2, y, modellab[stepwise$model], las = 1)
segments(stepwise$lo_hour, y, stepwise$hi_hour, y, col = "steelblue")
abline(v = 0, lty = 2, col = "grey")
mtext(sprintf("%.2f h per SD", h_per_sd), side = 3, adj = 1, cex = 0.8, col = "grey40")
dev.off()
