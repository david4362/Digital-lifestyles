library(data.table)
library(sandwich)
library(lmtest)

# Anchor regressions. Which one feeds the pipeline is explicit now: the
# bivariate model (used_in_pipeline = TRUE) provides dt_coefs and h_per_sd
# in 40; the controlled rows are diagnostics only. (The earlier pipeline printed three anchor
# rows without marking the used one, which read as an inconsistency: the
# +major_city slope 0.94 h per raw index unit does not reproduce the
# per-hour/per-SD ratios in the tables — the bivariate one does.)
device_city <- merge(device_time, control_data[, .(aid, major_city, density)], by = "aid")
dt_lm_city <- lm(time ~ index + age + gender + major_city, data = device_city)

r2_row <- function(m, name, used) {
  s <- summary(m)
  ct <- coeftest(m, vcov. = vcovHC(m, type = "HC3"))
  data.table(model = name, used_in_pipeline = used, n = nobs(m), r2 = s$r.squared,
    adj_r2 = s$adj.r.squared, b_index = ct["index", "Estimate"],
    se = ct["index", "Std. Error"], p = ct["index", "Pr(>|t|)"])
}
anchor_check <- rbind(
  r2_row(dt_lm, "bivariate", TRUE),
  r2_row(dt_lm_controls, "+sex+age", FALSE),
  r2_row(dt_lm_city, "+major_city", FALSE))
fwrite(anchor_check, file.path(out_dir, "anchor_check.csv"))

# Hour-calibration control table: every ingredient of the per-SD <-> per-hour
# conversion in one audited place. The index is standardized (SD 1 in the
# analysis sample), so the anchor slope is hours per index SD directly; the
# raw-composite chain (slope per raw unit x raw SD) is reported alongside and
# must reproduce it. per_hour_direct fits the M5 on the anchored hours scale;
# per_hour_derived divides the per-SD slope by h_per_sd — the two must agree,
# which is exactly the arithmetic that failed to add up across the earlier files.
m5 <- lm(as.formula(lm_formula), data = analysis_data)
ct5 <- coeftest(m5, vcov. = vcovHC(m5, type = "HC3"))["index", ]
m5_hours <- lm(as.formula(sub("index", "hours_est", lm_formula, fixed = TRUE)),
  data = analysis_data)
ct5h <- coeftest(m5_hours, vcov. = vcovHC(m5_hours, type = "HC3"))["hours_est", ]
sd_raw <- sd(analysis_data$index_raw)
b_z <- dt_coefs[["index"]]
per_sd <- ct5[["Estimate"]]
calibration_check <- data.table(
  anchor_model = "bivariate lm(time ~ index), valid E4 reporters with a valid index (see anchor_check.csv)",
  anchor_n = nobs(dt_lm),
  anchor_b_per_index_sd = b_z,
  anchor_se = anchor_check[model == "bivariate", se],
  anchor_r2 = anchor_check[model == "bivariate", r2],
  index_sd_analysis = sd(analysis_data$index),
  index_sd_anchor_sample = sd(device_time$index),
  index_raw_sd_analysis = sd_raw,
  anchor_b_per_raw_unit = b_z / sd_raw,
  hours_per_index_sd = (b_z / sd_raw) * sd_raw,
  m5_per_raw_unit = per_sd / sd_raw,
  m5_per_index_sd = per_sd,
  m5_per_hour_derived = per_sd / h_per_sd,
  m5_per_hour_direct = ct5h[["Estimate"]])
calibration_check[, check_hours_per_sd :=
  abs(hours_per_index_sd - anchor_b_per_index_sd) < 1e-10]
calibration_check[, check_m5_per_sd :=
  abs(m5_per_raw_unit * index_raw_sd_analysis - m5_per_index_sd) < 1e-10]
calibration_check[, check_per_hour :=
  abs(m5_per_hour_derived - m5_per_hour_direct) < 1e-8]
fwrite(calibration_check, file.path(out_dir, "calibration_check.csv"))
cat(sprintf("anchor b=%.3f h/index SD (n=%d, R2=%.3f) | M5=%.1f kg/SD, %.1f kg/h (derived) vs %.1f (direct)\n",
  b_z, nobs(dt_lm), anchor_check[model == "bivariate", r2],
  per_sd, calibration_check$m5_per_hour_derived, calibration_check$m5_per_hour_direct))

# Anchor plot: E4 vs index
png(file.path(out_dir, "anchor_plot.png"), width = 900, height = 600, res = 120)
plot(device_time$index, device_time$time, pch = 16, col = rgb(0, 0, 0, 0.25),
  xlab = "Digital index (z, pre-registered minus e-commerce items)",
  ylab = "Screen time (hours/day, E4)",
  main = sprintf("Anchor: E4 vs index (R2=%.2f, b=%.2f h per index SD)",
    anchor_check$r2[1], b_z))
abline(dt_lm, col = "red", lwd = 2)
dev.off()
