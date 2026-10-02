library(data.table)
library(sandwich)
library(lmtest)

out_dir = file.path(dirname(cache_dir), "output")
dir.create(out_dir, showWarnings = FALSE)

# Major city in anchor model (40 already has it in main model)
device_city <- merge(device_time, control_data[, .(aid, major_city, density)], by = "aid")
dt_lm_city <- lm(time ~ index + age + gender + major_city, device_city)

r2_row <- function(m, name) {
  s <- summary(m)
  ct <- coeftest(m, vcov. = vcovHC(m, type = "HC3"))
  data.table(model = name, n = nobs(m), r2 = s$r.squared, adj_r2 = s$adj.r.squared,
    b_index = ct["index", "Estimate"], se = ct["index", "Std. Error"], p = ct["index", "Pr(>|t|)"])
}
anchor_check <- rbind(
  r2_row(dt_lm, "bivariate"),
  r2_row(dt_lm_controls, "+sex+age"),
  r2_row(dt_lm_city, "+major_city"))

fwrite(anchor_check, file.path(out_dir, "anchor_check.csv"))

# Per-hour vs per-SD: 1 SD(index) = b_hat*sd_index hours. The SD is from the
# anchor (E4 reporter) sample here — this is the anchor's own diagnostic;
# the analysis-sample conversion h_per_sd in 40 uses the M5 sample instead.
sd_index <- sd(device_time$index, na.rm = T)
b_hat <- coef(dt_lm)[["index"]]
cat(sprintf("R2 bivariate=%.3f controlled=%.3f +city=%.3f | b=%.3f h/index SD=%.3f => %.2f h/SD\n",
  anchor_check$r2[1], anchor_check$r2[2], anchor_check$r2[3], b_hat, sd_index, b_hat * sd_index))

# Anchor plot: E4 vs index
png(file.path(out_dir, "anchor_plot.png"), width = 900, height = 600, res = 120)
plot(device_time$index, device_time$time, pch = 16, col = rgb(0, 0, 0, 0.25),
  xlab = "Digital index (z)", ylab = "Screen time (hours/day, E4)",
  main = sprintf("Anchor: E4 vs index (R2=%.2f, b=%.2f)", anchor_check$r2[1], b_hat))
abline(dt_lm, col = "red", lwd = 2)
dev.off()
