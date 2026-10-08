library(data.table)
library(sandwich)
library(lmtest)

source("05_labels.R")

# Volume vs. composition of the headline gradient: is the +kg CO2e per index
# SD "buys more" (spending volume) or "buys dirtier" (basket composition)?
# CO2e = intensity x spending, so the gradient splits at sample means into
#   volume component      = mean intensity x M5 spending gradient
#   composition component = M5 intensity gradient x mean spending
#   covariance residual   = headline - volume - composition
# (OLS slopes of a product are not exactly additive; the residual is the
# covariance term and is reported, not hidden.) The formal test of the
# composition margin is the intensity model below; the "M5 + spend_goods"
# rows are descriptive equal-spending comparisons, NOT alternative headline
# specifications -- spending is an outcome of the lifestyle and is never a
# control in the headline models.
#
# Emission-relevant spending = non-excluded kr (20) minus rent_kr: rent has
# no emissions factor (20), so it can carry none of the CO2e gradient, and
# keeping it in the denominator would make the intensity margin measure
# housing tenure instead of the basket. spend_total (incl. rent) is reported
# alongside for continuity with 49's observed spending.

# Person x category annual tables: canonical recipe from 20
# (>= min_months, annualized, P99 winsor) -- same rule as the headline total
ca <- annualise(monthly_co2e, "co2e")
ka <- annualise(monthly_kr[category %notin% excluded_kr], "kr")

# Person-level margins. The ca spine is kept in the joins (X[i, on = "aid"]
# keeps i's rows -- see 40), so every analysis participant carries one row.
pers <- ca[, .(co2e = sum(y)), by = aid]
pers <- ka[, .(spend_total = sum(y)), by = aid][pers, on = "aid"]
pers <- ka[category != "rent_kr", .(spend_goods = sum(y)), by = aid][pers, on = "aid"]
pers[, intensity := co2e / spend_goods * 1000]  # kg CO2e per 1,000 SEK spent
pers[, `:=`(log_co2e = log(co2e), log_spend_goods = log(spend_goods))]
# Ratios and logs are defined on positive emission-relevant spending and
# positive CO2e only (the && chain also drops people without goods spending)
pers <- pers[co2e > 0 & spend_goods > 0]

base <- control_data[, .(aid, age, gender, income, income_scb, income_bank, density,
  index, hh_size, children, education, major_city)]
d <- base[pers, on = "aid", nomatch = 0]
form0 <- sub("^co2e", "y", lm_formula)

unitlab <- c(co2e = "kg CO2e/yr", spend_goods = "SEK/yr", spend_total = "SEK/yr",
  intensity = "kg CO2e per 1,000 SEK", log_co2e = "log points",
  log_spend_goods = "log points")

fit <- function(ycol, spec = "M5", extra = NULL) {
  d[, y := get(ycol)]
  f <- if (is.null(extra)) form0 else paste(form0, "+", extra)
  m <- lm(as.formula(f), d)
  ct <- coeftest(m, vcov. = vcovHC(m, type = "HC3"))
  e <- ct["index", ]
  data.table(outcome = ycol, spec = spec,
    n = nobs(m), mean = mean(d$y),
    per_sd = e[["Estimate"]], se = e[["Std. Error"]], p = e[["Pr(>|t|)"]],
    per_hour = e[["Estimate"]] / h_per_sd, se_hour = e[["Std. Error"]] / h_per_sd)
}

# Margins of the gradient. log rows give the scale-free comparison: pct_of_mean
# below turns their slopes into % change per index SD.
marg <- rbindlist(list(
  fit("co2e"), fit("spend_goods"), fit("spend_total"), fit("intensity"),
  fit("log_co2e"), fit("log_spend_goods"),
  fit("co2e", "M5 + spend_goods (descriptive, equal spending)", "spend_goods"),
  fit("log_co2e", "M5 + log_spend_goods (descriptive, equal spending)",
    "log_spend_goods")))
marg[, unit := unitlab[outcome]]
marg[, `:=`(lo = per_sd - 1.96 * se, hi = per_sd + 1.96 * se)]
marg[, pct_of_mean := fifelse(grepl("^log_", outcome), 100 * (exp(per_sd) - 1),
  100 * per_sd / mean)]
fwrite(marg, file.path(out_dir, "volume_margins.csv"))

# The M5 CO2e row must be the headline: same formula, same sample as the 42
# ladder, so the split below decomposes exactly the published gradient.
step <- fread(file.path(out_dir, "stepwise_table.csv"))
stopifnot(abs(marg[outcome == "co2e" & spec == "M5", per_sd] -
  step[model == "M5_city" & index_variant == variantlab[["main"]], per_sd]) < 1e-6)

# Accounting split at sample means
b_total <- marg[outcome == "co2e" & spec == "M5", per_sd]
se_total <- marg[outcome == "co2e" & spec == "M5", se]
p_total <- marg[outcome == "co2e" & spec == "M5", p]
b_spend <- marg[outcome == "spend_goods" & spec == "M5", per_sd]
se_spend <- marg[outcome == "spend_goods" & spec == "M5", se]
p_spend <- marg[outcome == "spend_goods" & spec == "M5", p]
b_int <- marg[outcome == "intensity" & spec == "M5", per_sd]
se_int <- marg[outcome == "intensity" & spec == "M5", se]
p_int <- marg[outcome == "intensity" & spec == "M5", p]
mean_int_kg <- pers[, mean(intensity)] / 1000  # kg CO2e per SEK
mean_spend <- pers[, mean(spend_goods)]

volume_component <- mean_int_kg * b_spend
composition_component <- b_int / 1000 * mean_spend
covariance_residual <- b_total - volume_component - composition_component

vol_comp <- data.table(
  component = c("headline_gradient", "volume_component", "composition_component",
    "covariance_residual", "volume_share", "composition_share", "pct_premium"),
  unit = c(rep("kg CO2e/yr per index SD", 4), "percent of headline",
    "percent of headline", "percentage points of the mean"),
  estimate = c(b_total, volume_component, composition_component, covariance_residual,
    100 * volume_component / b_total, 100 * composition_component / b_total,
    marg[outcome == "co2e" & spec == "M5", pct_of_mean] -
      marg[outcome == "spend_goods" & spec == "M5", pct_of_mean]),
  se = c(se_total, mean_int_kg * se_spend, se_int / 1000 * mean_spend,
    NA, NA, NA, NA),
  p = c(p_total, p_spend, p_int, NA, NA, NA, NA),
  share_of_headline_pct = c(100, 100 * volume_component / b_total,
    100 * composition_component / b_total, 100 * covariance_residual / b_total,
    NA, NA, NA))
fwrite(vol_comp, file.path(out_dir, "volume_composition.csv"))

# Budget shares (Engel margins): does the extra basket tilt toward particular
# categories? Share of emission-relevant spending (denominator spend_goods)
# and of total CO2e, same M5 model, in percentage points per index SD. The
# top-10 leaves are the largest goods categories by mean spending (rent
# excluded -- it is outside the emission-relevant denominator).
top10 <- ka[category != "rent_kr", .(m = mean(y)), by = category][order(-m)][1:10, category]
targets <- c(
  list(transport = transport_kr, ecom = ecom_kr, digital = digital_kr,
    vehicles = vehicles_kr, placebo_insurance = "insurance_kr"),
  sapply(top10, function(x) x, simplify = FALSE))
names(targets)[6:(5 + length(top10))] <- paste0("top_", top10)
targets_co2e <- lapply(targets, function(x) sub("_kr$", "_co2e", x))
goods_total <- ka[category != "rent_kr", .(sg = sum(y)), by = aid]
co2e_total <- ca[, .(sc = sum(y)), by = aid]

share_res <- rbindlist(lapply(names(targets), function(nm) {
  yy <- ka[category %in% targets[[nm]], .(cat_kr = sum(y)), by = aid][
    goods_total, on = "aid"]
  yy <- ca[category %in% targets_co2e[[nm]], .(cat_co2e = sum(y)), by = aid][
    yy, on = "aid"]
  # Non-buyers have a zero share, not a missing one
  yy[is.na(cat_kr), cat_kr := 0]
  yy[is.na(cat_co2e), cat_co2e := 0]
  yy <- co2e_total[yy, on = "aid"]
  rbindlist(lapply(c("kr", "co2e"), function(bs) {
    dd <- base[yy, on = "aid", nomatch = 0]
    dd[, y := if (bs == "kr") 100 * cat_kr / sg else 100 * cat_co2e / sc]
    m <- lm(as.formula(form0), dd)
    ct <- coeftest(m, vcov. = vcovHC(m, type = "HC3"))
    e <- ct["index", ]
    data.table(cat = nm,
      basis = if (bs == "kr") "share of spending" else "share of CO2e",
      n = nobs(m), mean_share_pct = mean(dd$y),
      per_sd_pp = e[["Estimate"]], se_pp = e[["Std. Error"]], p = e[["Pr(>|t|)"]])
  }))
}))
share_res[, `:=`(lo = per_sd_pp - 1.96 * se_pp, hi = per_sd_pp + 1.96 * se_pp)]
fwrite(share_res, file.path(out_dir, "budget_shares.csv"))

# Quintile contrast: policy-relevant magnitudes. D1-D5 on the index, raw
# means by quintile and the covariate-adjusted D5-D1 gap (the model replaces
# index with the quintile factor, so the D5 coefficient IS the adjusted
# contrast against D1). index_gap_sd records how many index SDs D5 vs D1
# stand apart, so the contrast is convertible back to a per-SD scale.
d[, dig_q := cut(index, quantile(index, probs = seq(0, 1, 0.2), na.rm = T),
  labels = paste0("D", 1:5), include.lowest = T)]
reg_income <- scb[, .(aid, register_income = DispInk04 * 100)]
qd <- reg_income[d, on = "aid"]

quintile_desc <- qd[, .(n = .N, mean_index = mean(index), mean_co2e = mean(co2e),
  mean_spend_goods = mean(spend_goods), mean_spend_total = mean(spend_total),
  mean_intensity = mean(intensity), mean_register_income = mean(register_income)),
  by = dig_q]
setorder(quintile_desc, dig_q)
fwrite(quintile_desc, file.path(out_dir, "quintile_desc.csv"))

form_q <- sub("^co2e", "y", sub("index", "dig_q", lm_formula))
qc <- rbindlist(lapply(c("co2e", "spend_goods", "spend_total", "intensity",
  "log_co2e", "log_spend_goods"), function(yc) {
  qd[, y := get(yc)]
  m <- lm(as.formula(form_q), qd)
  ct <- coeftest(m, vcov. = vcovHC(m, type = "HC3"))
  e <- ct["dig_qD5", ]
  data.table(outcome = yc, unit = unitlab[[yc]], n = nobs(m), mean = mean(qd$y),
    d5_minus_d1 = e[["Estimate"]], se = e[["Std. Error"]], p = e[["Pr(>|t|)"]])
}))
qc[, `:=`(lo = d5_minus_d1 - 1.96 * se, hi = d5_minus_d1 + 1.96 * se)]
qc[, pct_of_mean := fifelse(grepl("^log_", outcome), 100 * (exp(d5_minus_d1) - 1),
  100 * d5_minus_d1 / mean)]
qc[, index_gap_sd := quintile_desc[dig_q == "D5", mean_index] -
  quintile_desc[dig_q == "D1", mean_index]]
fwrite(qc, file.path(out_dir, "quintile_contrast.csv"))

# Figures: (1) the accounting split next to the spending-share forest,
# (2) the quintile means of the two margins and their ratio.
png(file.path(out_dir, "volume_composition.png"), width = 1500, height = 650, res = 120)
par(mfrow = c(1, 2), mar = c(5, 12, 4, 2))
comp <- vol_comp[component %in% c("headline_gradient", "volume_component",
  "composition_component", "covariance_residual")]
barplot(setNames(comp$estimate, c("Headline gradient", "Volume (spending)",
  "Composition (intensity)", "Covariance residual")),
  horiz = TRUE, las = 1, col = "steelblue",
  xlab = "kg CO2e per index SD", main = "Volume vs. composition (M5)")
abline(v = 0, col = "black")
sh <- share_res[basis == "share of spending"][order(per_sd_pp)]
y <- seq_len(nrow(sh))
plot(sh$per_sd_pp, y, xlim = range(c(sh$lo, sh$hi)),
  yaxt = "n", pch = 16, col = ifelse(sh$p < 0.05, "steelblue", "grey50"),
  xlab = "share of emission-relevant spending, pp per index SD (HC3 95% CI)",
  ylab = "", main = "Budget-share gradients (M5)")
axis(2, y, fulllab(sh$cat), las = 1, cex.axis = 0.8)
segments(sh$lo, y, sh$hi, y, col = "grey40")
abline(v = 0, lty = 2, col = "grey")
dev.off()

png(file.path(out_dir, "quintile_gradient.png"), width = 1500, height = 500, res = 120)
par(mfrow = c(1, 3), mar = c(5, 5, 4, 2))
qnm <- paste("D", 1:5, sep = "")
barplot(setNames(quintile_desc$mean_co2e, qnm), col = "steelblue",
  xlab = "Digital quintile (index)", ylab = "kg CO2e/yr", main = "Footprint by quintile")
barplot(setNames(quintile_desc$mean_spend_goods, qnm), col = "steelblue",
  xlab = "Digital quintile (index)", ylab = "SEK/yr",
  main = "Emission-relevant spending by quintile")
barplot(setNames(quintile_desc$mean_intensity, qnm), col = "steelblue",
  xlab = "Digital quintile (index)", ylab = "kg CO2e per 1,000 SEK",
  main = "Basket intensity by quintile")
dev.off()
