library(data.table)
library(sandwich)
library(lmtest)

out_dir = file.path(dirname(cache_dir), "output")
dir.create(out_dir, showWarnings = FALSE)

source("05_labels.R")

# Person x category SEK, canonical recipe from 20 (mirrors 43; drops
# non-consumption flows). Rent is the housing-tenure outcome, not a
# placebo (see 20); insurance is the spending placebo.
kr_annual <- annualise(monthly_kr[category %notin% excluded_kr], "kr")

top10 <- kr_annual[, .(m = mean(y, na.rm = TRUE)), by = category][order(-m)][1:10, category]

targets <- c(
  list(transport = transport_kr, ecom = ecom_kr, digital = digital_kr,
    rent = "rent_kr", placebo_insurance = "insurance_kr",
    vehicles = vehicles_kr, total = unique(kr_annual$category)),
  sapply(top10, function(x) x, simplify = FALSE))
names(targets)[8:(7 + length(top10))] <- paste0("top_", top10)

base <- control_data[, .(aid, age, gender, income, income_scb, income_bank, density,
  hours_est, hh_size, children, education, major_city)]
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
axis(2, y, fulllab(res$cat), las = 1, cex.axis = 0.8)
segments(res$lo, y, res$hi, y, col = "grey40")
abline(v = 0, lty = 2, col = "grey")
dev.off()
