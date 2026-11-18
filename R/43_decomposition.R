library(data.table)
library(sandwich)
library(lmtest)
library(ggplot2)

source("05_labels.R")

# Person x category annual CO2e: the canonical recipe from 20
# (>= min_months, annualized, P99 winsor) — same rule as the headline total
cat_annual = annualise(monthly_co2e, "co2e")

# Hypothesis groups: category vectors defined in 20; the target list
# (groups + total + top-10) is 20's decomp_targets
targets = decomp_targets(cat_annual, list(
  transport = transport_co2e, ecom = ecom_co2e, digital = digital_co2e,
  placebo_insurance = placebo_co2e, vehicles = vehicles_co2e))

base = control_data[, .(aid, age, gender, income, income_scb, income_bank, density,
  index, hh_size, children, education, major_city)]

res = rbindlist(lapply(names(targets), function(nm) {
  cats = targets[[nm]]
  yy = group_annual(cat_annual, cats)
  d = base[yy, on = "aid", nomatch = 0]
  m = lm(form0, d)
  ct = coeftest(m, vcov. = vcovHC(m, type = "HC3"))
  e = ct["index", ]
  data.table(cat = nm, n = nobs(m), df = df.residual(m), mean = mean(d$y),
    per_sd = e[["Estimate"]], pct_of_mean = 100 * e[["Estimate"]] / mean(d$y),
    se = e[["Std. Error"]], p = e[["Pr(>|t|)"]],
    per_hour = e[["Estimate"]] / h_per_sd, se_hour = e[["Std. Error"]] / h_per_sd)
}))
res[, `:=`(lo = per_sd - 1.96 * se, hi = per_sd + 1.96 * se,
  lo_hour = per_hour - 1.96 * se_hour, hi_hour = per_hour + 1.96 * se_hour)]
setorder(res, per_sd)
fwrite(res, file.path(out_dir, "decomp_table.csv"))

# Forest: sorted, hypothesis groups on top
ggsave(file.path(out_dir, "decomp_forest.png"),
  forest_plot(res[, .(label = fulllab(cat), est = per_sd, lo = lo, hi = hi)],
    "kg CO2e per index SD (HC3 95% CI, M5 controls)",
    "Decomposition: groups + top-10 (annual CO2e)",
    point_col = ifelse(res$p < 0.05, "steelblue", "grey50")),
  width = 8.33, height = 5.83, dpi = 120)

# Waterfall: group contributions vs total (not exact sum, top-10 overlap)
# Horizontal bar-chart recipe — first use this script; downstream consumers:
# 45_sample_desc, 68_volume_composition. d carries the display columns
# (label, value).
bar_chart = function(d, xlab, title) {
  d = copy(d)
  d$label = factor(d$label, levels = d$label)
  ggplot(d, aes(x = value, y = label)) +
    geom_col(fill = "steelblue") +
    labs(x = xlab, y = NULL, title = title) +
    theme_minimal()
}

wf = res[cat %in% c("transport", "ecom", "digital", "placebo_insurance", "vehicles")]
ggsave(file.path(out_dir, "waterfall.png"),
  bar_chart(wf[, .(label = fulllab(cat), value = per_sd)],
      "kg CO2e per index SD", "Contribution per group (M5)") +
    geom_vline(xintercept = 0, color = "black"),
  width = 7.5, height = 5, dpi = 120)
