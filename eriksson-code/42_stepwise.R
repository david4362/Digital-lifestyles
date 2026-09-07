library(data.table)
library(sandwich)
library(lmtest)

out_dir = file.path(dirname(cache_dir), "output")
dir.create(out_dir, showWarnings = FALSE)

# Both scales equally: hours_est and index_sd are linear rescalings
sd_index <- sd(lm_data$index, na.rm = T)
b_hat <- dt_coefs[["index"]]
h_per_sd <- b_hat * sd_index
lm_data[, index_sd := index / sd_index]

specs <- list(
  M0_bivariate = "co2e ~ hours_est",
  M1_sex_age = "co2e ~ hours_est + gender + age",
  M2_income_educ = "co2e ~ hours_est + gender + age + income + education",
  M3_household = "co2e ~ hours_est + gender + age + income + education + hh_size + children",
  M4_density = "co2e ~ hours_est + gender + age + income + education + hh_size + children + density",
  M5_city = lm_formula)

rows <- lapply(names(specs), function(nm) {
  m <- lm(as.formula(specs[[nm]]), lm_data)
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
par(mar = c(5, 9, 4, 4))
y <- seq_len(nrow(stepwise))
plot(stepwise$per_hour, y, xlim = range(c(stepwise$lo_hour, stepwise$hi_hour)),
  yaxt = "n", pch = 16, col = "steelblue",
  xlab = "kg CO2e per extra hour/day (HC3 95% CI)", ylab = "",
  main = "Main model: stepwise addition of covariates")
axis(2, y, stepwise$model, las = 1)
segments(stepwise$lo_hour, y, stepwise$hi_hour, y, col = "steelblue")
abline(v = 0, lty = 2, col = "grey")
mtext(sprintf("%.2f h per SD", h_per_sd), side = 3, adj = 1, cex = 0.8, col = "grey40")
dev.off()
