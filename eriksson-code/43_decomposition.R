library(data.table)
library(sandwich)
library(lmtest)

out_dir = file.path(dirname(cache_dir), "output")
dir.create(out_dir, showWarnings = FALSE)

source("05_labels.R")

# Person x category annual CO2e: the canonical recipe from 20
# (>= min_months, annualized, P99 winsor) — same rule as the headline total
cat_annual <- annualise(monthly_co2e, "co2e")

# Hypothesis groups: category vectors defined in 20
top10 <- cat_annual[, .(m = mean(y, na.rm = TRUE)), by = category][order(-m)][1:10, category]

targets <- c(
  list(transport = transport_co2e, ecom = ecom_co2e, digital = digital_co2e,
    placebo_insurance = placebo_co2e,
    vehicles = vehicles_co2e, total = unique(cat_annual$category)),
  sapply(top10, function(x) x, simplify = FALSE))
names(targets)[7:(6 + length(top10))] <- paste0("top_", top10)

base <- control_data[, .(aid, age, gender, income, income_scb, income_bank, density,
  hours_est, hh_size, children, education, major_city)]
form0 <- sub("^co2e", "y", lm_formula)

res <- rbindlist(lapply(names(targets), function(nm) {
  cats <- targets[[nm]]
  yy <- cat_annual[category %in% cats, .(y = sum(y, na.rm = T)), by = aid]
  d <- base[yy, on = "aid", nomatch = 0]
  m <- lm(as.formula(form0), d)
  ct <- coeftest(m, vcov. = vcovHC(m, type = "HC3"))
  e <- ct["hours_est", ]
  data.table(cat = nm, n = nobs(m), df = df.residual(m), mean = mean(d$y),
    per_hour = e[["Estimate"]], se = e[["Std. Error"]], p = e[["Pr(>|t|)"]],
    per_sd = e[["Estimate"]] * h_per_sd)
}))
res[, `:=`(lo = per_hour - 1.96 * se, hi = per_hour + 1.96 * se)]
setorder(res, per_hour)
fwrite(res, file.path(out_dir, "decomp_table.csv"))

# Forest: sorted, hypothesis groups on top
png(file.path(out_dir, "decomp_forest.png"), width = 1000, height = 700, res = 120)
par(mar = c(5, 12, 4, 2))
y <- seq_len(nrow(res))
plot(res$per_hour, y, xlim = range(c(res$lo, res$hi)),
  yaxt = "n", pch = 16, col = ifelse(res$p < 0.05, "steelblue", "grey50"),
  xlab = "kg CO2e per extra hour/day (HC3 95% CI, M5 controls)", ylab = "",
  main = "Decomposition: groups + top-10 (annual CO2e)")
axis(2, y, fulllab(res$cat), las = 1, cex.axis = 0.8)
segments(res$lo, y, res$hi, y, col = "grey40")
abline(v = 0, lty = 2, col = "grey")
dev.off()

# Waterfall: group contributions vs total (not exact sum, top-10 overlap)
wf <- res[cat %in% c("transport", "ecom", "digital", "placebo_insurance", "vehicles")]
png(file.path(out_dir, "waterfall.png"), width = 900, height = 600, res = 120)
par(mar = c(5, 10, 4, 2))
barplot(setNames(wf$per_hour, fulllab(wf$cat)), horiz = TRUE, las = 1, col = "steelblue",
  xlab = "kg CO2e per extra hour/day", main = "Contribution per group (M5)")
abline(v = 0, col = "black")
dev.off()
