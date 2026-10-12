library(data.table)
library(sandwich)
library(lmtest)

# E4 diagnostics: is the device-assisted screen-time report credible, how
# does it relate to the self-reported frequency battery, and does it carry
# an emissions gradient of its own?
#
# A platform split (iOS vs Android) is not possible with the current data:
# no cached table records the respondent's device/OS (details in
# metadata.md, "E4 platform split"). There is also no second, purely
# self-estimated screen-time item: E4 (q21) is the only screen-time
# question in either survey wave, so the "self-report" side of the
# validity check is the q11/q11b frequency battery — the anchor regression
# (E4 ~ index) IS that correlation, reported per index SD here, and
# e4_item_correlations.csv gives it item by item. The emissions side of the
# question (E4 carries no gradient of its own while the index does) lives
# in e4_rq1_robustness.csv / e4_index_test.csv from 52/60; the headline row
# is repeated here for a self-contained table.

# Distribution and plausibility of the valid reports (screen_valid from 30:
# the 0-18 h/day rule, before the demographics join), and what the rule
# dropped (screen_raw; parsed = every report with readable h:mm). e4_data
# (the E4 subsample of the analysis sample) comes from 40.
parsed = screen_raw[!is.na(time)]
m_e4 = lm(sub("index", "time", lm_formula, fixed = TRUE), data = e4_data)
ct_e4 = coeftest(m_e4, vcov. = vcovHC(m_e4, type = "HC3"))["time", ]
b_z = dt_coefs[["index"]]

e4_diagnostics = rbind(
  data.table(check = "E4 mean (hours/day, valid reports)", value = mean(screen_valid$time),
    n = nrow(screen_valid), note = "screen_time: parsed h:mm, 0-18 h/day rule applied"),
  data.table(check = "E4 median (hours/day)", value = median(screen_valid$time),
    n = nrow(screen_valid), note = ""),
  data.table(check = "E4 SD (hours/day)", value = sd(screen_valid$time),
    n = nrow(screen_valid), note = ""),
  data.table(check = "E4 95th percentile (hours/day)", value = unname(quantile(screen_valid$time, .95)),
    n = nrow(screen_valid), note = ""),
  data.table(check = "E4 vs main index: anchor slope b (hours per index SD)",
    value = b_z, n = nobs(dt_lm),
    note = "bivariate lm(time ~ index) on valid E4 reporters with a valid index; see anchor_check.csv / calibration_check.csv"),
  data.table(check = "E4 vs main index: HC3 SE of b", value = anchor_check[model == "bivariate", se],
    n = nobs(dt_lm), note = ""),
  data.table(check = "E4 vs main index: anchor R2", value = anchor_check[model == "bivariate", r2],
    n = nobs(dt_lm), note = "weak anchor: per-SD is the headline scale, per-hour is derived"),
  data.table(check = "E4 vs main index: anchor p", value = anchor_check[model == "bivariate", p],
    n = nobs(dt_lm), note = ""),
  data.table(check = "Pearson r, E4 vs main index", value = cor(device_time$time, device_time$index),
    n = nrow(device_time), note = "sqrt of the bivariate anchor R2"),
  data.table(check = "Pearson r, E4 vs age", value = cor(device_time$time, device_time$age, use = "complete.obs"),
    n = sum(!is.na(device_time$time) & !is.na(device_time$age)), note = "younger report more screen time if negative"),
  data.table(check = "Share of reports with minutes == 0 (h:mm heaping)",
    value = mean(screen_valid$minutes == 0), n = nrow(screen_valid), note = "transcription heaping at whole hours"),
  data.table(check = "Share of reports with minutes in {0, 30}",
    value = mean(screen_valid$minutes %in% c(0, 30)), n = nrow(screen_valid), note = ""),
  data.table(check = "Share of reports with minutes in {15, 30, 45}",
    value = mean(screen_valid$minutes %in% c(15, 30, 45)), n = nrow(screen_valid), note = ""),
  data.table(check = "Share reporting exactly 18:00",
    value = mean(screen_valid$hours == 18 & screen_valid$minutes == 0), n = nrow(screen_valid),
    note = "reports at the plausibility cap"),
  data.table(check = "N reports dropped by the > 18 h/day rule",
    value = parsed[, sum(time > 18 | time < 0, na.rm = TRUE)], n = nrow(parsed), note = ""),
  data.table(check = "N endline respondents with parsed h:mm",
    value = nrow(parsed), n = nrow(screen_raw), note = "opt-outs (not activated / skipped) have no h:mm text"),
  data.table(check = "E4 vs total CO2e, M5 slope (kg per measured hour)",
    value = ct_e4[["Estimate"]], n = nobs(m_e4),
    note = "same model as the E4_M5_city row of e4_rq1_robustness.csv; difference vs the index tested in e4_index_test.csv")
)
fwrite(e4_diagnostics, file.path(out_dir, "e4_diagnostics.csv"))

# Item-level correlations: E4 vs each self-reported frequency item
# (raw 1-6 answers; Pearson r is invariant to the z-scaling in 40). The
# smartphone-use item (q11_2) is the closest single self-report to E4.
e4_batt = screen_time[item_battery, on = "aid", nomatch = 0]
e4_item_correlations = rbindlist(lapply(q11_cols, function(cn) {
  data.table(item = cn, r = cor(e4_batt$time, e4_batt[[cn]], use = "complete.obs"),
    n = sum(!is.na(e4_batt$time) & !is.na(e4_batt[[cn]])))
}))
e4_item_correlations[, in_main_index := item %in% index_main_items]
setorder(e4_item_correlations, -r)
fwrite(e4_item_correlations, file.path(out_dir, "e4_item_correlations.csv"))
