library(data.table)
library(sandwich)
library(lmtest)

out_dir = file.path(dirname(cache_dir), "output")
dir.create(out_dir, showWarnings = FALSE)

# Registered alternative weightings of the index. The preregistration
# names three: the device-use half (q11_1-q11_5: computer, smartphone, TV,
# game console, tablet), the digital-activity half (q11b_1-q11b_8:
# streaming, calls, social media, information search, gaming, digital
# reading, e-commerce, online selling) and the first principal component.
# All are M5 slopes per index SD (z-scored in the analysis sample, HC3),
# the same scale as the stepwise per_sd column; run_variant comes from 59.

d = copy(analysis_data)
d[, index_device := rowMeans(.SD), .SDcols = paste0("q11_", 1:5)]
d[, index_activity := rowMeans(.SD), .SDcols = paste0("q11b_", 1:8)]

# First principal component of the 13 z-scaled items. The sign of a PC is
# arbitrary, so it is oriented to correlate positively with the index.
pc = prcomp(as.matrix(d[, ..q11_cols]), center = FALSE, scale. = FALSE)
d[, index_pc1 := pc$x[, 1]]
if (cor(d$index_pc1, d$index) < 0) d[, index_pc1 := -index_pc1]

index_weightings = rbind(
  run_variant(d, d$index_device, "Device-use half (q11_1-q11_5)"),
  run_variant(d, d$index_activity, "Digital-activity half (q11b_1-q11b_8)"),
  run_variant(d, d$index_pc1, "First principal component")
)
fwrite(index_weightings, file.path(out_dir, "index_weightings.csv"))
