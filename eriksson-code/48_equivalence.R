library(data.table)
source("05_labels.R")

# Equivalence bounds per advisor doc D8: delta = min(1% of category mean,
# 10% of expected transport gradient). D = no-car everyday-transport
# contrast (kg/yr); VERIFY against published TRE numbers before citing.
# K_GAP is the contrast's implied gap in SDs of the digital index, so the
# expected per-hour transport gradient is D / (K_GAP * h_per_sd) and
# delta2 below is 10% of it. h_per_sd is defined in 40.
D_NOCAR = 90.5
K_GAP = 2

out_dir = file.path(dirname(cache_dir), "output")
dir.create(out_dir, showWarnings = FALSE)

dec = fread(file.path(out_dir, "decomp_table.csv"))
pl = dec[cat %in% c("placebo_insurance")]
pl[, delta1 := 0.01 * mean]
pl[, delta2 := 0.10 * D_NOCAR / (K_GAP * h_per_sd)]
pl[, delta := pmin(delta1, delta2)]
pl[, `:=`(t1 = (per_hour + delta) / se, t2 = (delta - per_hour) / se)]
pl[, p_tost := pmax(1 - pt(t1, df), 1 - pt(t2, df))]
pl[, `:=`(lo90 = per_hour - 1.645 * se, hi90 = per_hour + 1.645 * se)]
pl[, pass := abs(lo90) < delta & abs(hi90) < delta]
pl[, feasible := se < delta / 1.645]
# Minimum detectable effect at 80% power for a two-sided 5% test,
# (z_.95 + z_.80) x SE: what the placebo design could have detected, in
# per-hour and per-index-SD units, alongside the equivalence bound.
pl[, mde80 := (1.96 + 0.84) * se]
pl[, `:=`(mde80_sd = mde80 * h_per_sd, delta_sd = delta * h_per_sd)]
pl[, `:=`(lo90_sd = lo90 * h_per_sd, hi90_sd = hi90 * h_per_sd)]
fwrite(pl, file.path(out_dir, "equivalence_table.csv"))
cat(sprintf("h/SD=%.2f delta2=%.2f\n", h_per_sd, 0.10 * D_NOCAR / (K_GAP * h_per_sd)))
print(pl[, .(cat, mean, per_hour, se, delta, p_tost, pass, feasible)])

png(file.path(out_dir, "equivalence_plot.png"), width = 900, height = 500, res = 120)
par(mar = c(5, 10, 4, 2))
y = seq_len(nrow(pl))
lim = range(c(-pl$delta, pl$delta, pl$lo90, pl$hi90))
plot(pl$per_hour, y, xlim = lim, yaxt = "n", pch = 19, cex = 1.4, col = "#1f4e79",
  xlab = "kg CO2e per extra hour/day (90% CI, shaded = equivalence bounds)", ylab = "",
  main = "Placebo equivalence (TOST)")
axis(2, y, fulllab(pl$cat), las = 1)
segments(pl$lo90, y, pl$hi90, y, lwd = 2, col = "#1f4e79")
segments(-pl$delta, y - 0.15, pl$delta, y - 0.15, col = "grey40", lty = 2)
abline(v = 0, lty = 1, col = "grey")
dev.off()
