library(data.table)
library(ggplot2)
source("05_labels.R")

stepwise = fread(file.path(out_dir, "stepwise_table.csv"))
res = fread(file.path(out_dir, "decomp_table.csv"))
main = stepwise[index_variant == variantlab[["main"]]]
ggsave(file.path(out_dir, "pres_stepwise.png"),
  forest_plot(main[, .(label = unname(modellab[model]), est = per_sd, lo = lo_sd,
      hi = hi_sd)],
    "kg CO2e per index SD", "How does the digital measure respond to covariates?",
    point_col = "#1f4e79", ci_col = "#1f4e79", ci_lwd = 1.6, point_size = 3,
    base_size = 14),
  width = 8, height = 4.67, dpi = 150)

# Pres 2: decomp, groups + total only
show = c("total", "transport", "ecom", "digital", "placebo_insurance", "vehicles")
d = res[cat %in% show]
ggsave(file.path(out_dir, "pres_decomp.png"),
  forest_plot(d[, .(label = unname(grouplab[cat]), est = per_sd, lo = lo, hi = hi)],
    "kg CO2e per index SD", "Decomposition: where is the gradient?",
    point_col = ifelse(d$p < 0.05, "#1f4e79", "grey60"), ci_col = "grey40",
    ci_lwd = 1.6, point_size = 3, base_size = 14),
  width = 8, height = 4.67, dpi = 150)
