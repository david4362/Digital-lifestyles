library(data.table)
library(sandwich)
library(lmtest)

# Registered alternative weightings of the index, on the main item set
# (items and halves defined in 20). The pre-registration names three: the
# device-use half (computer, smartphone, TV, game console, tablet), the
# digital-activity half (streaming, calls, social media, information
# search, gaming, digital reading — the main index's activity items), and
# the first principal component. All are M5 slopes per index SD (z-scored
# in the analysis sample, HC3), the same scale as the stepwise per_sd
# column; run_variant comes from 59.

d = copy(analysis_data)
d[, index_device := rowMeans(.SD, na.rm = TRUE), .SDcols = index_device_items]
d[, index_activity := rowMeans(.SD, na.rm = TRUE), .SDcols = index_activity_items]

# First principal component of the main index's z-scaled items, fitted on
# the complete-item rows (prcomp cannot handle missing items; the battery
# tolerance in 20 admits up to 3 missing). The sign of a PC is arbitrary,
# so it is oriented to correlate positively with the index.
pc_items = as.matrix(d[, ..index_main_items])
pc_ok = complete.cases(pc_items)
pc = prcomp(pc_items[pc_ok, ], center = FALSE, scale. = FALSE)
d[, index_pc1 := NA_real_]
d[pc_ok, index_pc1 := pc$x[, 1]]
if (cor(d$index_pc1, d$index, use = "complete.obs") < 0) d[, index_pc1 := -index_pc1]

index_weightings = rbind(
  run_variant(d, d$index_device, "Device-use half (5 items)"),
  run_variant(d, d$index_activity, "Digital-activity half (6 items)"),
  run_variant(d, d$index_pc1, "First principal component (complete items)")
)
index_weightings[, `:=`(lo = per_sd - 1.96 * se, hi = per_sd + 1.96 * se)]
fwrite(index_weightings, file.path(out_dir, "index_weightings.csv"))
