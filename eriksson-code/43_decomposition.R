library(data.table)
library(sandwich)
library(lmtest)

out_dir = file.path(dirname(cache_dir), "output")
dir.create(out_dir, showWarnings = FALSE)

source("05_labels.R")

# Person x category, annualized + P99 per category (same as 20_filter)
cat_annual <- (monthly_co2e[keep, on = .(aid, month), nomatch = 0]
  [, .(s = sum(co2e), n_months = uniqueN(month)), by = .(aid, category)]
  [n_months > min_months]
  [, y := (s / n_months) * 12]
  [, .(q99 = quantile(y, .99, na.rm = T), y = y, aid = aid), by = .(category)]
  [, y := pmin(y, q99)]
  [, .(aid, category, y)])

# Hypothesis groups (leaf names from metadata.md)
transport <- c("fuel_co2e", "car_maint_co2e", "car_rent_co2e", "public_trans_co2e", "bus_co2e",
  "taxi_co2e", "train_bus_co2e", "aviation_co2e", "ferry_co2e", "escooter_co2e", "transport_other_co2e")
ecom <- c("clothing_co2e", "electronics_co2e", "books_co2e", "toys_co2e", "sports_co2e",
  "shopping_other_co2e", "home_garden_other_co2e")
digital <- c("internet_tele_co2e")
placebo <- c("rent_co2e", "insurance_co2e")
vehicles <- c("vehicles_co2e")

top10 <- cat_annual[, .(m = mean(y, na.rm = T)), by = category][order(-m)][1:10, category]

targets <- c(
  list(transport = transport, ecom = ecom, digital = digital,
    placebo_rent = "rent_co2e", placebo_insurance = "insurance_co2e",
    vehicles = vehicles, total = unique(cat_annual$category)),
  sapply(top10, function(x) x, simplify = FALSE))
names(targets)[8:(7 + length(top10))] <- paste0("top_", top10)

base <- unique(control_data[, .(aid, age, gender, income, income_scb, income_bank, density, hours_est, index, hh_size, children, education, major_city)])
sd_index <- sd(base$index, na.rm = T)
h_per_sd <- dt_coefs[["index"]] * sd_index
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
wf <- res[cat %in% c("transport", "ecom", "digital", "placebo_rent", "placebo_insurance", "vehicles")]
png(file.path(out_dir, "waterfall.png"), width = 900, height = 600, res = 120)
par(mar = c(5, 10, 4, 2))
barplot(setNames(wf$per_hour, fulllab(wf$cat)), horiz = TRUE, las = 1, col = "steelblue",
  xlab = "kg CO2e per extra hour/day", main = "Contribution per group (M5)")
abline(v = 0, col = "black")
dev.off()
