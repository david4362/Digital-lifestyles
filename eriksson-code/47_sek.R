library(data.table)
library(sandwich)
library(lmtest)

out_dir = file.path(dirname(cache_dir), "output")
dir.create(out_dir, showWarnings = FALSE)

# Person x category SEK, annualized + P99 (mirrors 43; drops non-consumption flows)
kr_annual <- (monthly_kr[category %notin% excluded_kr][keep, on = .(aid, month), nomatch = 0]
  [, .(s = sum(kr), n_months = uniqueN(month)), by = .(aid, category)]
  [n_months > min_months]
  [, y := (s / n_months) * 12]
  [, .(q99 = quantile(y, .99, na.rm = T), y = y, aid = aid), by = .(category)]
  [, y := pmin(y, q99)]
  [, .(aid, category, y)])

transport <- sub("_co2e$", "_kr", c("fuel_co2e", "car_maint_co2e", "car_rent_co2e", "public_trans_co2e",
  "bus_co2e", "taxi_co2e", "train_bus_co2e", "aviation_co2e", "ferry_co2e",
  "escooter_co2e", "transport_other_co2e"))
ecom <- sub("_co2e$", "_kr", c("clothing_co2e", "electronics_co2e", "books_co2e", "toys_co2e",
  "sports_co2e", "shopping_other_co2e", "home_garden_other_co2e"))
digital <- "internet_tele_kr"
vehicles <- "vehicles_kr"

top10 <- kr_annual[, .(m = mean(y, na.rm = T)), by = category][order(-m)][1:10, category]

targets <- c(
  list(transport = transport, ecom = ecom, digital = digital,
    placebo_rent = "rent_kr", placebo_insurance = "insurance_kr",
    vehicles = vehicles, total = unique(kr_annual$category)),
  sapply(top10, function(x) x, simplify = FALSE))
names(targets)[8:(7 + length(top10))] <- paste0("top_", top10)

base <- unique(control_data[, .(aid, age, gender, income, density, hours_est, index, hh_size, children, education, major_city)])
sd_index <- sd(base$index, na.rm = T)
h_per_sd <- dt_coefs[["index"]] * sd_index
form0 <- sub("^co2e", "y", lm_formula)

res <- rbindlist(lapply(names(targets), function(nm) {
  cats <- targets[[nm]]
  yy <- kr_annual[category %in% cats, .(y = sum(y, na.rm = T)), by = aid]
  dd <- base[yy, on = "aid", nomatch = 0]
  m <- lm(as.formula(form0), dd)
  ct <- coeftest(m, vcov. = vcovHC(m, type = "HC3"))
  e <- ct["hours_est", ]
  data.table(cat = nm, n = nobs(m), df = df.residual(m), mean = mean(dd$y),
    per_hour = e[["Estimate"]], se = e[["Std. Error"]], p = e[["Pr(>|t|)"]],
    per_sd = e[["Estimate"]] * h_per_sd)
}))
res[, `:=`(lo = per_hour - 1.96 * se, hi = per_hour + 1.96 * se)]
setorder(res, per_hour)
fwrite(res, file.path(out_dir, "sek_table.csv"))

png(file.path(out_dir, "sek_forest.png"), width = 1000, height = 700, res = 120)
par(mar = c(5, 12, 4, 2))
y <- seq_len(nrow(res))
plot(res$per_hour, y, xlim = range(c(res$lo, res$hi)),
  yaxt = "n", pch = 16, col = ifelse(res$p < 0.05, "steelblue", "grey50"),
  xlab = "SEK per extra hour/day (HC3 95% CI, M5 controls)", ylab = "",
  main = "Decomposition in SEK: groups + top-10 (annual spending)")
axis(2, y, res$cat, las = 1, cex.axis = 0.8)
segments(res$lo, y, res$hi, y, col = "grey40")
abline(v = 0, lty = 2, col = "grey")
dev.off()
