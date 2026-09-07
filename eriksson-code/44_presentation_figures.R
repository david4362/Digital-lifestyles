library(data.table)

out_dir = file.path(dirname(cache_dir), "output")
stepwise <- fread(file.path(out_dir, "stepwise_table.csv"))
res <- fread(file.path(out_dir, "decomp_table.csv"))

# Pres 1: stepwise, english labels
en <- c(M0_bivariate = "Bivariate", M1_sex_age = "+ sex & age",
  M2_income_educ = "+ income & education", M3_household = "+ household/children",
  M4_density = "+ log density", M5_city = "+ major city (full)")
png(file.path(out_dir, "pres_stepwise.png"), width = 1200, height = 700, res = 150)
par(mar = c(5, 14, 4, 2), cex.axis = 1.1, cex.lab = 1.2)
y <- seq_len(nrow(stepwise))
plot(stepwise$per_hour, y, xlim = range(c(stepwise$lo_hour, stepwise$hi_hour)),
  yaxt = "n", pch = 19, cex = 1.4, col = "#1f4e79",
  xlab = "kg CO2e per extra hour screen time/day", ylab = "",
  main = "How does the digital measure respond to covariates?")
axis(2, y, en[stepwise$model], las = 1)
segments(stepwise$lo_hour, y, stepwise$hi_hour, y, lwd = 2, col = "#1f4e79")
abline(v = 0, lty = 2)
dev.off()

# Pres 2: decomp, groups + total only
show <- c("total", "transport", "ecom", "digital", "placebo_rent", "placebo_insurance", "vehicles")
d <- res[cat %in% show]
lab <- c(total = "Total", transport = "Transport", ecom = "E-commerce intensive",
  digital = "Digital services", placebo_rent = "Rent (placebo)",
  placebo_insurance = "Insurance (placebo)", vehicles = "Vehicles (capital good)")
png(file.path(out_dir, "pres_decomp.png"), width = 1200, height = 700, res = 150)
par(mar = c(5, 14, 4, 2), cex.axis = 1.1, cex.lab = 1.2)
y <- seq_len(nrow(d))
plot(d$per_hour, y, xlim = range(c(d$lo, d$hi)),
  yaxt = "n", pch = 19, cex = 1.4, col = ifelse(d$p < 0.05, "#1f4e79", "grey60"),
  xlab = "kg CO2e per extra hour screen time/day", ylab = "",
  main = "Decomposition: where is the gradient?")
axis(2, y, lab[d$cat], las = 1)
segments(d$lo, y, d$hi, y, lwd = 2, col = "grey40")
abline(v = 0, lty = 2)
dev.off()
