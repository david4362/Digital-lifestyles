library(data.table)
library(sandwich)
library(lmtest)
library(ggplot2)
library(patchwork)

# Person x category annual tables: canonical recipe from 20
ca = annualise(monthly_co2e, "co2e")
ka = annualise(monthly_kr[category %notin% excluded_kr], "kr")

# Wide person table: ecom level, rest (= total - ecom), ecom share.
# E-commerce groups (ecom_co2e / ecom_kr) are defined in 20.
wide = function(dt, cats, prefix) {
  out = dt[category %in% cats, .(e = sum(y)), by = aid][dt[, .(t = sum(y)), by = aid], on = "aid"]
  setnames(out, c("e", "t"), paste0(c("ecom_", "tot_"), prefix))
  out[, paste0("rest_", prefix) := get(paste0("tot_", prefix)) - get(paste0("ecom_", prefix))]
  out[, paste0("sh_", prefix) := get(paste0("ecom_", prefix)) / get(paste0("tot_", prefix))]
  out
}
pers = wide(ca, ecom_co2e, "co2e")[wide(ka, ecom_kr, "kr"), on = "aid"]

# income_q for the quintile stratification below, index for the digital
# quintile descriptives; neither enters the model formulas
base = control_data[, .(aid, age, gender, income, income_q, income_scb, income_bank, density,
  index, hh_size, children, education, major_city)]
d = base[pers, on = "aid", nomatch = 0]

# Level vs rest vs share; then holding rest fixed (descriptive: attenuates if
# pure level effect). m5_row (from 40) fits the M5 on each outcome column.
chk = rbindlist(list(
  m5_row(d, "ecom_co2e"), m5_row(d, "rest_co2e"), m5_row(d, "sh_co2e"),
  m5_row(d, "ecom_kr"), m5_row(d, "rest_kr"), m5_row(d, "sh_kr"),
  m5_row(d, "ecom_co2e", "M5+rest_co2e", "rest_co2e"),
  m5_row(d, "ecom_kr", "M5+rest_kr", "rest_kr")))
chk[, `:=`(lo = per_sd - 1.96 * se, hi = per_sd + 1.96 * se)]
chk[, `:=`(pct_mean = 100 * per_sd / mean, pct_se = 100 * se / mean)]
fwrite(chk, file.path(out_dir, "ecommerce_check.csv"))

# Separate panels: kg and SEK levels have different scales, shares are proportions
outlab = c(ecom_co2e = "E-commerce (CO2e)", rest_co2e = "Rest of consumption (CO2e)",
  sh_co2e = "E-commerce share (CO2e)", ecom_kr = "E-commerce (SEK)",
  rest_kr = "Rest of consumption (SEK)", sh_kr = "E-commerce share (SEK)")
speclab = c(M5 = "Full controls", "M5+rest_co2e" = "+ Rest of consumption",
  "M5+rest_kr" = "+ Rest of consumption")

# Vertical column-chart panel recipe — first use this script; downstream
# consumer: 68_volume_composition. d carries the display columns
# (label, value).
column_chart = function(d, xlab, ylab, title) {
  d = copy(d)
  d$label = factor(d$label, levels = d$label)
  ggplot(d, aes(x = label, y = value)) +
    geom_col(fill = "steelblue") +
    labs(x = xlab, y = ylab, title = title) +
    theme_minimal()
}

fig_kg = chk[outcome %in% c("ecom_co2e", "rest_co2e"), .(
  label = unname(paste0(outlab[outcome], " [", speclab[spec], "]")),
  est = per_sd, lo = lo, hi = hi, sig = p < 0.05)]
fig_kr = chk[outcome %in% c("ecom_kr", "rest_kr"), .(
  label = unname(paste0(outlab[outcome], " [", speclab[spec], "]")),
  est = per_sd, lo = lo, hi = hi, sig = p < 0.05)]
fig_sh = chk[grepl("^sh_", outcome), .(
  label = unname(paste0(outlab[outcome], " [", speclab[spec], "]")),
  est = per_sd, lo = lo, hi = hi, sig = p < 0.05)]
ggsave(file.path(out_dir, "ecommerce_levels.png"),
  wrap_plots(list(
    forest_plot(fig_kg, "kg CO2e per index SD (HC3 95% CI)", "Levels, CO2e",
      point_col = ifelse(fig_kg$sig, "steelblue", "grey50")),
    forest_plot(fig_kr, "SEK per index SD (HC3 95% CI)", "Levels, SEK",
      point_col = ifelse(fig_kr$sig, "steelblue", "grey50")),
    forest_plot(fig_sh, "share per index SD (HC3 95% CI)",
      "E-com share of total",
      point_col = ifelse(fig_sh$sig, "steelblue", "grey50"))),
    nrow = 1),
  width = 15, height = 4.17, dpi = 120)

# Within income quintile (stratified, M5 minus income): survives if not just income
f_noinc = update(form0, . ~ . - income - income_scb - income_bank)
qr = rbindlist(lapply(levels(d$income_q), function(q) {
  rbindlist(lapply(c("ecom_co2e", "ecom_kr"), function(yc) {
    dd = d[income_q == q]
    dd[, y := get(yc)]
    m = lm(f_noinc, dd)
    ct = coeftest(m, vcov. = vcovHC(m, type = "HC3"))
    e = ct["index", ]
    data.table(income_q = q, outcome = yc, n = nobs(m), mean = mean(dd$y),
      per_sd = e[["Estimate"]], se = e[["Std. Error"]], p = e[["Pr(>|t|)"]],
      per_hour = e[["Estimate"]] / h_per_sd, se_hour = e[["Std. Error"]] / h_per_sd)
  }))
}))
qr[, `:=`(lo = per_sd - 1.96 * se, hi = per_sd + 1.96 * se)]
fwrite(qr, file.path(out_dir, "ecommerce_quintile.csv"))

q_panels = lapply(c("ecom_co2e", "ecom_kr"), function(yc) {
  s = qr[outcome == yc]
  fig = s[, .(label = paste("Income quintile", sub("^Q", "", income_q)),
    est = per_sd, lo = lo, hi = hi)]
  unit = ifelse(yc == "ecom_co2e", "kg CO2e", "SEK")
  ttl = ifelse(yc == "ecom_co2e", "E-commerce CO2e by income",
    "E-commerce SEK by income")
  forest_plot(fig, paste(unit, "per index SD (HC3 95% CI)"), ttl,
    point_col = ifelse(s$p < 0.05, "steelblue", "grey50"))
})
ggsave(file.path(out_dir, "ecommerce_quintile.png"), wrap_plots(q_panels, nrow = 1),
  width = 11.67, height = 4.17, dpi = 120)

# Descriptives: do high-digital households just earn and spend more?
d[, dig_q := cut(index, quantile(index, probs = seq(0, 1, 0.2), na.rm = TRUE),
  labels = paste0("D", 1:5), include.lowest = TRUE)]
# Latest user record per aid (as in 40), not every historical record
inc0 = users_latest[, .(aid, `income-level`)]
desc = d[inc0, on = "aid", nomatch = 0][, .(n = .N, income = mean(`income-level`),
  tot_kr = mean(tot_kr), tot_co2e = mean(tot_co2e),
  sh_kr = mean(sh_kr), sh_co2e = mean(sh_co2e)), by = dig_q]
setorder(desc, dig_q)
fwrite(desc, file.path(out_dir, "ecommerce_desc.csv"))

dignm = paste("Quintile", sub("^D", "", desc$dig_q))
ggsave(file.path(out_dir, "ecommerce_desc.png"),
  wrap_plots(list(
    column_chart(desc[, .(label = dignm, value = income)],
      "Digital quintile (index)", "mean disposable income",
      "Income by digital quintile"),
    column_chart(desc[, .(label = dignm, value = tot_kr)],
      "Digital quintile (index)", "mean total spending (SEK/yr)",
      "Consumption by digital quintile")),
    nrow = 1),
  width = 8.33, height = 4.17, dpi = 120)
