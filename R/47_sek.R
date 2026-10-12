library(data.table)
library(sandwich)
library(lmtest)

source("05_labels.R")

# Person x category SEK, canonical recipe from 20 (mirrors 43; drops
# non-consumption flows). Rent is the housing-tenure outcome, not a
# placebo (see 20); insurance is the spending placebo.
kr_annual = annualise(monthly_kr[category %notin% excluded_kr], "kr")

# Hypothesis groups: category vectors defined in 20; the target list
# (groups + total + top-10) is 20's decomp_targets
targets = decomp_targets(kr_annual, list(
  transport = transport_kr, ecom = ecom_kr, digital = digital_kr,
  rent = "rent_kr", placebo_insurance = "insurance_kr", vehicles = vehicles_kr))

base = control_data[, .(aid, age, gender, income, income_scb, income_bank, density,
  index, hh_size, children, education, major_city)]

res = rbindlist(lapply(names(targets), function(nm) {
  cats = targets[[nm]]
  yy = group_annual(kr_annual, cats)
  dd = base[yy, on = "aid", nomatch = 0]
  m = lm(form0, dd)
  ct = coeftest(m, vcov. = vcovHC(m, type = "HC3"))
  e = ct["index", ]
  data.table(cat = nm, n = nobs(m), df = df.residual(m), mean = mean(dd$y),
    per_sd = e[["Estimate"]], se = e[["Std. Error"]], p = e[["Pr(>|t|)"]],
    per_hour = e[["Estimate"]] / h_per_sd, se_hour = e[["Std. Error"]] / h_per_sd)
}))
res[, `:=`(lo = per_sd - 1.96 * se, hi = per_sd + 1.96 * se,
  lo_hour = per_hour - 1.96 * se_hour, hi_hour = per_hour + 1.96 * se_hour)]
setorder(res, per_sd)
fwrite(res, file.path(out_dir, "sek_table.csv"))

png(file.path(out_dir, "sek_forest.png"), width = 1000, height = 700, res = 120)
par(mar = c(5, 12, 4, 2))
y = seq_len(nrow(res))
plot(res$per_sd, y, xlim = range(c(res$lo, res$hi)),
  yaxt = "n", pch = 16, col = ifelse(res$p < 0.05, "steelblue", "grey50"),
  xlab = "SEK per index SD (HC3 95% CI, M5 controls)", ylab = "",
  main = "Decomposition in SEK: groups + top-10 (annual spending)")
axis(2, y, fulllab(res$cat), las = 1, cex.axis = 0.8)
segments(res$lo, y, res$hi, y, col = "grey40")
abline(v = 0, lty = 2, col = "grey")
dev.off()
