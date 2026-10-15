# Percentage-change decomposition figures (CO2e and SEK) for the ERL draft.
# Reads the 2026-10-13 TRE export; writes PDFs next to the PNG originals.
# Run from the repository root: Rscript latex/fig_pct_decomp.R

co2 <- read.csv("output/2026-10-13/decomp_table.csv")
sek <- read.csv("output/2026-10-13/sek_table.csv")

labels <- c(
  transport = "Transport (group)", ecom = "E-commerce goods (group)",
  digital = "Internet & telecom (group)", placebo_insurance = "Insurance (placebo)",
  vehicles = "Vehicle purchases", top_groceries_co2e = "Groceries",
  top_aviation_co2e = "Aviation", top_restaurant_co2e = "Restaurants",
  top_travel_co2e = "Travel", top_uncategorized_co2e = "Uncategorized",
  top_clothing_co2e = "Clothing", top_shopping_other_co2e = "Other shopping",
  top_alcohol_co2e = "Alcohol", top_fuel_co2e = "Fuel",
  top_public_trans_co2e = "Public transport",
  top_groceries_kr = "Groceries", top_restaurant_kr = "Restaurants",
  top_travel_kr = "Travel", top_uncategorized_kr = "Uncategorized",
  top_clothing_kr = "Clothing", top_shopping_other_kr = "Other shopping",
  top_internet_tele_kr = "Internet & telecom (group)",
  top_financial_service_kr = "Financial services", top_services_kr = "Services",
  top_rent_kr = "Rent", rent = "Rent")

pct_plot <- function(d, file, xlab) {
  d <- d[d$cat != "total" & d$cat %in% names(labels), ]
  d <- d[!duplicated(labels[d$cat]), ]
  d$pct <- 100 * d$per_sd / d$mean
  d$pct_lo <- 100 * d$lo / d$mean
  d$pct_hi <- 100 * d$hi / d$mean
  d <- d[order(d$pct), ]
  pdf(file, width = 7.2, height = 0.42 * nrow(d) + 1.4, pointsize = 10)
  par(mar = c(4, 14, 0.6, 1.2), mgp = c(2.4, 0.7, 0))
  y <- seq_len(nrow(d))
  plot(d$pct, y, xlim = range(c(d$pct_lo, d$pct_hi, 0)), ylim = c(0.5, nrow(d) + 0.5),
    yaxt = "n", pch = 16, col = ifelse(d$p < 0.05, "#1f5fa8", "grey55"),
    xlab = xlab, ylab = "", bty = "l")
  axis(2, y, labels[d$cat], las = 1, cex.axis = 0.9)
  segments(d$pct_lo, y, d$pct_hi, y, col = "grey40")
  abline(v = 0, lty = 2, col = "grey60")
  dev.off()
}

pct_plot(co2, "output/2026-10-13/decomp_pct_co2e.pdf",
  "Change in annual emissions per index SD (% of category mean)")
pct_plot(sek, "output/2026-10-13/decomp_pct_sek.pdf",
  "Change in annual spending per index SD (% of category mean)")
cat("written\n")
