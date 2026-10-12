library(data.table)
library(sandwich)
library(lmtest)

# Mechanism analysis (pre-registered result 3): whether lower out-of-home
# leisure frequency among the digitally intensive accounts for part of the
# transport gradient. E1 = the endline frequency battery "Hur ofta har du
# under de senaste 12 manderna gjort foljande?" (1 = "Ingen gang" ...
# 7 = "Flera ganger i veckan"). Item codes follow the questionnaire grid;
# the first four are validated by 55's use (F88_2 = worked from home,
# F88_3 = overtime, F88_10 = "kopt nagon gang", F88_19 = delayed payment).
# mech_diag.csv flags any miscoding before the models lean on the rest.

# Latest endline response per aid (endline_latest from 30).
e1_all = analysis_data[endline_latest[, .(
  aid,
  work_home = F88_2, overtime = F88_3, unaffordable = F88_10, bnpl = F88_19,
  library = F88_4, sports_event = F88_5, culture_event = F88_6,
  dinner_guests = F88_7, dancing = F88_8, exercised = F88_18, nature = F88_21,
  audiobook = F88_11, music = F88_12, book = F88_13, film = F88_14,
  tv_series = F88_16
)], on = "aid", nomatch = 0]

ooh_items = c("library", "sports_event", "culture_event", "dinner_guests",
  "dancing", "exercised", "nature")
home_items = c("audiobook", "music", "book", "film", "tv_series")

# Frequency diagnostic: item means/SDs and share at the scale top, plus the
# share at 8-9 (the "Vet ej"/"Vagar" codes above the 7-point scale, if the
# real questionnaire recorded them) — the check for grid-order miscoding.
mech_diag = rbindlist(lapply(c(ooh_items, home_items), function(it) {
  x = e1_all[[it]]
  data.table(item = it, n_endline = sum(!is.na(x)),
    mean = mean(x, na.rm = TRUE), sd = sd(x, na.rm = TRUE),
    share_max = mean(x == 7, na.rm = TRUE), share_code_8_9 = mean(x >= 8, na.rm = TRUE))
}))
fwrite(mech_diag, file.path(out_dir, "mech_diag.csv"))

# Composites: unweighted mean of the answered items. All E1 items share the
# 1-7 scale, so the raw mean needs no standardization; like the index,
# partial missingness is tolerated (all-missing rows become NaN and drop).
e1_all[, ooh_leisure := rowMeans(.SD, na.rm = TRUE), .SDcols = ooh_items]
e1_all[, home_leisure := rowMeans(.SD, na.rm = TRUE), .SDcols = home_items]

# Index vs each item and both composites, M5 covariates. Outcomes are on the
# 1-7 scale (points per index SD), so no per_hour column — derived per-hour
# values are reserved for CO2e outcomes.
e1_leisure_index = rbindlist(lapply(c(ooh_items, home_items,
    "ooh_leisure", "home_leisure"), function(outcome) {
  m = lm(as.formula(sub("^co2e", outcome, lm_formula)), data = e1_all)
  ct = coeftest(m, vcov. = vcovHC(m, type = "HC3"))["index", ]
  data.table(outcome = outcome, n = nobs(m),
    per_sd = ct[["Estimate"]], se = ct[["Std. Error"]], p = ct[["Pr(>|t|)"]],
    lo = ct[["Estimate"]] - 1.96 * ct[["Std. Error"]],
    hi = ct[["Estimate"]] + 1.96 * ct[["Std. Error"]])
}))
fwrite(e1_leisure_index, file.path(out_dir, "e1_leisure_index.csv"))

# Mediation table: transport and total CO2e gradients without / with the
# leisure composites, identical participants per outcome (both composites
# non-missing, dropped up front, as in 55). The mediator coefficients are
# exported alongside; pct_gradient_shared restates the index-coefficient
# change as each outcome's M5 gradient share accounted for by the composites.
fit_spec = function(m, outcome, specification) {
  ct = coeftest(m, vcov. = vcovHC(m, type = "HC3"))
  # NA row for mediator cells not in this specification
  not_in_model = c(Estimate = NA_real_, `Std. Error` = NA_real_, `Pr(>|t|)` = NA_real_)
  ooh = if ("ooh_leisure" %in% rownames(ct)) ct["ooh_leisure", ] else not_in_model
  home = if ("home_leisure" %in% rownames(ct)) ct["home_leisure", ] else not_in_model
  data.table(outcome = outcome, specification = specification, n = nobs(m),
    per_sd = ct["index", "Estimate"], se = ct["index", "Std. Error"],
    p = ct["index", "Pr(>|t|)"], per_hour = ct["index", "Estimate"] / h_per_sd,
    ooh_coef = ooh[["Estimate"]], ooh_se = ooh[["Std. Error"]],
    ooh_p = ooh[["Pr(>|t|)"]],
    home_coef = home[["Estimate"]], home_se = home[["Std. Error"]],
    home_p = home[["Pr(>|t|)"]])
}
mech_fit = function(outcome, formula_m5, d) {
  rbind(
    fit_spec(lm(formula_m5, data = d), outcome, "M5"),
    fit_spec(lm(update(formula_m5, . ~ . + ooh_leisure), data = d),
      outcome, "M5 + out-of-home leisure"),
    fit_spec(lm(update(formula_m5, . ~ . + ooh_leisure + home_leisure), data = d),
      outcome, "M5 + out-of-home + at-home leisure"))
}

mech_data = e1_all[!is.na(ooh_leisure) & !is.na(home_leisure)]

# Transport CO2e: the pre-registered mechanism outcome. Canonical recipe
# from 20 (group_annual over the annualised table), transport categories
# from 20.
transport_annual = group_annual(annualise(monthly_co2e, "co2e"), transport_co2e)
setnames(transport_annual, "y", "transport_co2e")
d_tr = mech_data[transport_annual[, .(aid, transport_co2e)], on = "aid", nomatch = 0]
mech_tr = mech_fit("transport_co2e",
  as.formula(sub("^co2e", "transport_co2e", lm_formula)), d_tr)

# Total CO2e (the headline gradient).
mech_tot = mech_fit("co2e", as.formula(lm_formula), mech_data[!is.na(co2e)])

e1_leisure_mechanism = rbind(mech_tr, mech_tot)
e1_leisure_mechanism[, `:=`(lo = per_sd - 1.96 * se, hi = per_sd + 1.96 * se)]
ref = e1_leisure_mechanism[specification == "M5", .(outcome, ref_per_sd = per_sd)]
e1_leisure_mechanism[ref, pct_gradient_shared :=
  (ref_per_sd - per_sd) / ref_per_sd * 100, on = "outcome"]
fwrite(e1_leisure_mechanism, file.path(out_dir, "e1_leisure_mechanism.csv"))

# Figure: index slope on each leisure item / composite (out-of-home blue,
# at-home grey), sorted by estimate.
fig = e1_leisure_index[order(per_sd)]
y = seq_len(nrow(fig))
fig_colour = ifelse(fig$outcome %in% c(ooh_items, "ooh_leisure"), "steelblue", "grey60")
png(file.path(out_dir, "mech_forest.png"), width = 900, height = 700, res = 120)
plot(fig$per_sd, y, pch = 16, xlim = range(c(fig$lo, fig$hi)), yaxt = "n",
  xlab = "E1 frequency change per index SD (1-7 scale)",
  ylab = "", main = "Digital index vs E1 leisure frequency (HC3 95% CI)",
  col = fig_colour)
arrows(fig$lo, y, fig$hi, y, length = 0.02, angle = 90, code = 2, col = fig_colour)
abline(v = 0, lty = 2, col = "grey40")
axis(2, y, fig$outcome, las = 1, cex.axis = 0.8)
dev.off()

cat(sprintf(
  "Mechanism: transport %.1f -> %.1f kg/SD with out-of-home leisure (share %.0f%%) | total %.1f -> %.1f\n",
  e1_leisure_mechanism[outcome == "transport_co2e" & specification == "M5", per_sd],
  e1_leisure_mechanism[outcome == "transport_co2e" & specification == "M5 + out-of-home leisure", per_sd],
  e1_leisure_mechanism[outcome == "transport_co2e" & specification == "M5 + out-of-home leisure", pct_gradient_shared],
  e1_leisure_mechanism[outcome == "co2e" & specification == "M5", per_sd],
  e1_leisure_mechanism[outcome == "co2e" & specification == "M5 + out-of-home leisure", per_sd]))
