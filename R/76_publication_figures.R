# Publication figures built from disclosure-cleared TRE exports.
# Standalone use from the repository root:
#   Rscript R/76_publication_figures.R [output/YYYY-MM-DD]

args = commandArgs(trailingOnly = TRUE)
if (!exists("out_dir")) {
  out_dir = if (length(args)) args[[1]] else file.path("output", "2026-10-22")
}

read_export = function(name) {
  path = file.path(out_dir, name)
  if (!file.exists(path)) stop("Missing export: ", path)
  read.csv(path, check.names = FALSE, stringsAsFactors = FALSE)
}

teal = "#007C91"
orange = "#D55E00"
ink = "#252525"
mid_grey = "#777777"
light_grey = "#D9D9D9"

draw_ci = function(x, lo, hi, y, colour, pch = 16, cex = 1.15) {
  segments(lo, y, hi, y, col = colour, lwd = 2)
  segments(lo, y - 0.07, lo, y + 0.07, col = colour, lwd = 1.3)
  segments(hi, y - 0.07, hi, y + 0.07, col = colour, lwd = 1.3)
  points(x, y, pch = pch, cex = cex, col = colour, bg = colour)
}

volume = read_export("volume_margins.csv")
headline = volume[volume$spec == "M5" &
  volume$outcome %in% c("spend_total", "co2e", "intensity"), ]
headline = headline[match(c("spend_total", "co2e", "intensity"), headline$outcome), ]
headline$pct = 100 * headline$per_sd / headline$mean
headline$lo_pct = 100 * headline$lo / headline$mean
headline$hi_pct = 100 * headline$hi / headline$mean
headline$label = c(
  sprintf("+%s SEK/year", format(round(headline$per_sd[1]), big.mark = ",")),
  sprintf("+%d kg CO2e/year", round(headline$per_sd[2])),
  sprintf("%+.2f kg CO2e/1,000 SEK", headline$per_sd[3]))

pdf(file.path(out_dir, "publication_headline.pdf"), width = 7.2, height = 3.5,
  family = "Helvetica", useDingbats = FALSE)
par(mar = c(4.4, 10.8, 0.7, 2.2), las = 1, xaxs = "i")
y = 3:1
plot(headline$pct, y, type = "n", xaxt = "n", yaxt = "n", ylab = "", xlab = "",
  xlim = c(-1.1, 10.3), ylim = c(0.5, 3.5), bty = "n")
abline(v = 0, col = light_grey, lwd = 1.2)
axis(1, at = seq(0, 6, 2), labels = paste0(seq(0, 6, 2), "%"),
  col = NA, col.axis = ink)
axis(2, at = y,
  labels = c("Total observed spending", "Carbon footprint",
    "Emissions intensity"), tick = FALSE, col.axis = ink)
cols = c(teal, orange, mid_grey)
for (i in seq_len(nrow(headline))) {
  draw_ci(headline$pct[i], headline$lo_pct[i], headline$hi_pct[i], y[i], cols[i])
  text(headline$hi_pct[i] + 0.18, y[i], headline$label[i], adj = 0,
    cex = 0.82, col = ink)
}
mtext("Adjusted change per 1-SD higher digital-practice composite",
  side = 1, line = 2.7, col = ink)
dev.off()

sek = read_export("sek_table.csv")
social = read_export("social_cultural_group.csv")
social_sek = social[social$outcome == "social_cultural" & social$unit == "SEK/yr", ]
plot_fields = c("mean", "per_sd", "se", "p", "lo", "hi")

spend_keys = c("social_cultural", "ecom", "transport", "digital",
  "placebo_insurance", "top_travel_kr", "top_restaurant_kr",
  "top_shopping_other_kr", "top_clothing_kr", "top_groceries_kr", "rent")
spend = rbind(
  data.frame(key = "social_cultural", social_sek[, plot_fields], check.names = FALSE),
  data.frame(key = sek$cat, sek[, plot_fields], check.names = FALSE))
spend = spend[match(spend_keys, spend$key), ]
spend$label = c("Social and cultural", "E-commerce-intensive goods", "Transport",
  "Digital services", "Insurance (placebo)", "Travel", "Restaurants",
  "Other shopping", "Clothing", "Groceries", "Rent")
spend$pct_of_mean = 100 * spend$per_sd / spend$mean
spend$lo_pct = 100 * spend$lo / spend$mean
spend$hi_pct = 100 * spend$hi / spend$mean
spend$significant = spend$p < 0.05

pdf(file.path(out_dir, "publication_spending_decomposition.pdf"),
  width = 7.2, height = 6.1, family = "Helvetica", useDingbats = FALSE)
par(mar = c(4.5, 12.2, 1.4, 2.2), las = 1, xaxs = "i")
y = c(12:8, 6:1)
plot(spend$pct_of_mean, y, type = "n", xaxt = "n", yaxt = "n", ylab = "", xlab = "",
  xlim = c(-5.5, 17), ylim = c(0.4, 13.1), bty = "n")
abline(v = 0, col = light_grey, lwd = 1.2)
axis(1, at = seq(-4, 16, 4), labels = paste0(seq(-4, 16, 4), "%"),
  col = NA, col.axis = ink)
axis(2, at = y, labels = spend$label, tick = FALSE, col.axis = ink)
text(-5.5, 12.85, "Preregistered grouped outcomes", adj = 0,
  font = 2, cex = 0.84, col = ink, xpd = NA)
text(-5.5, 6.85, "Selected spending categories", adj = 0,
  font = 2, cex = 0.84, col = ink, xpd = NA)
for (i in seq_len(nrow(spend))) {
  col = if (spend$significant[i]) teal else mid_grey
  draw_ci(spend$pct_of_mean[i], spend$lo_pct[i], spend$hi_pct[i], y[i], col)
  text(spend$hi_pct[i] + 0.25, y[i], sprintf("%+.1f%%", spend$pct_of_mean[i]),
    adj = 0, cex = 0.78, col = ink)
}
mtext("Adjusted spending gradient per composite SD (% of category mean)",
  side = 1, line = 2.8, col = ink)
dev.off()

co2 = read_export("decomp_table.csv")
social_co2 = social[social$outcome == "social_cultural" &
  social$unit == "kg CO2e/yr", ]
co2_keys = c("social_cultural", "ecom", "transport", "digital",
  "placebo_insurance", "top_travel_co2e", "top_restaurant_co2e",
  "top_shopping_other_co2e", "top_clothing_co2e", "top_groceries_co2e",
  "top_fuel_co2e")
carbon = rbind(
  data.frame(key = "social_cultural", social_co2[, plot_fields], check.names = FALSE),
  data.frame(key = co2$cat, co2[, plot_fields], check.names = FALSE))
carbon = carbon[match(co2_keys, carbon$key), ]
carbon$label = c("Social and cultural", "E-commerce-intensive goods", "Transport",
  "Digital services", "Insurance (placebo)", "Travel", "Restaurants",
  "Other shopping", "Clothing", "Groceries", "Fuel")
carbon$pct_of_mean = 100 * carbon$per_sd / carbon$mean
carbon$lo_pct = 100 * carbon$lo / carbon$mean
carbon$hi_pct = 100 * carbon$hi / carbon$mean
carbon$significant = carbon$p < 0.05

pdf(file.path(out_dir, "publication_co2_decomposition.pdf"),
  width = 7.2, height = 6.1, family = "Helvetica", useDingbats = FALSE)
par(mar = c(4.5, 12.2, 1.4, 2.2), las = 1, xaxs = "i")
plot(carbon$pct_of_mean, y, type = "n", xaxt = "n", yaxt = "n", ylab = "", xlab = "",
  xlim = c(-7, 17), ylim = c(0.4, 13.1), bty = "n")
abline(v = 0, col = light_grey, lwd = 1.2)
axis(1, at = seq(-5, 15, 5), labels = paste0(seq(-5, 15, 5), "%"),
  col = NA, col.axis = ink)
axis(2, at = y, labels = carbon$label, tick = FALSE, col.axis = ink)
text(-7, 12.85, "Preregistered grouped outcomes", adj = 0,
  font = 2, cex = 0.84, col = ink, xpd = NA)
text(-7, 6.85, "Selected emissions categories", adj = 0,
  font = 2, cex = 0.84, col = ink, xpd = NA)
for (i in seq_len(nrow(carbon))) {
  col = if (carbon$significant[i]) orange else mid_grey
  draw_ci(carbon$pct_of_mean[i], carbon$lo_pct[i], carbon$hi_pct[i], y[i], col)
  text(carbon$hi_pct[i] + 0.35, y[i], sprintf("%+.1f%%", carbon$pct_of_mean[i]),
    adj = 0, cex = 0.78, col = ink)
}
mtext("Adjusted emissions gradient per composite SD (% of category mean)",
  side = 1, line = 2.8, col = ink)
dev.off()

items = read_export("item_level_joint.csv")
item_labels = c(q11_1 = "Computer", q11_2 = "Smartphone", q11_3 = "Television",
  q11_4 = "Game console", q11_5 = "Tablet", q11b_1 = "Streaming",
  q11b_2 = "Calls", q11b_3 = "Social media", q11b_4 = "Information search",
  q11b_5 = "Gaming", q11b_6 = "Digital reading")
items$label = unname(item_labels[items$item])
items = items[order(items$estimate), ]
items$colour = ifelse(items$item %in% c("q11b_2", "q11b_3"), orange,
  ifelse(items$item %in% c("q11b_1", "q11b_5"), teal, mid_grey))

profiles = read_export("social_spending_sek.csv")
profiles = profiles[profiles$exposure %in% c("social_media", "gaming"), ]
profiles$lo_pct = 100 * profiles$lo / profiles$mean
profiles$hi_pct = 100 * profiles$hi / profiles$mean
profile_labels = c(restaurants = "Restaurants", transport = "Transport",
  ecom_goods = "E-commerce-intensive goods", digital_services = "Digital services")

pdf(file.path(out_dir, "publication_practice_signature.pdf"),
  width = 10.5, height = 6.4, family = "Helvetica", useDingbats = FALSE)
layout(matrix(c(1, 2), nrow = 1), widths = c(1.15, 1))
par(mar = c(4.6, 9.5, 2.4, 1.2), las = 1, xaxs = "i")
yi = seq_len(nrow(items))
plot(items$estimate, yi, type = "n", xaxt = "n", yaxt = "n", ylab = "", xlab = "",
  xlim = c(-245, 430), ylim = c(0.5, nrow(items) + 0.5), bty = "n")
abline(v = 0, col = light_grey, lwd = 1.2)
axis(1, at = seq(-200, 400, 200), col = NA, col.axis = ink)
axis(2, at = yi, labels = items$label, tick = FALSE, col.axis = ink)
for (i in seq_len(nrow(items))) {
  draw_ci(items$estimate[i], items$lo[i], items$hi[i], yi[i], items$colour[i])
}
mtext("A  Mutually adjusted practice gradients", side = 3, line = 0.6,
  adj = 0, font = 2, col = ink)
mtext("Emissions gradient (kg CO2e/year per SD)", side = 1, line = 2.8, col = ink)

par(mar = c(4.6, 12.5, 2.4, 1.2), las = 1, xaxs = "i")
outcome_order = c("restaurants", "transport", "ecom_goods", "digital_services")
yp = 4:1
plot(NA, xlim = c(-8, 11), ylim = c(0.5, 4.8), xaxt = "n", yaxt = "n",
  ylab = "", xlab = "", bty = "n")
abline(v = 0, col = light_grey, lwd = 1.2)
axis(1, at = seq(-5, 10, 5), labels = paste0(seq(-5, 10, 5), "%"),
  col = NA, col.axis = ink)
axis(2, at = yp, labels = unname(profile_labels[outcome_order]),
  tick = FALSE, col.axis = ink)
for (j in seq_along(outcome_order)) {
  for (expo in c("social_media", "gaming")) {
    row = profiles[profiles$outcome == outcome_order[j] & profiles$exposure == expo, ]
    offset = if (expo == "social_media") 0.11 else -0.11
    col = if (expo == "social_media") orange else teal
    draw_ci(row$pct_of_mean, row$lo_pct, row$hi_pct, yp[j] + offset, col,
      pch = if (expo == "social_media") 16 else 17, cex = 1.05)
  }
}
legend("topright", inset = c(0, -0.02), bty = "n", horiz = TRUE,
  legend = c("Social media", "Gaming"), col = c(orange, teal),
  pch = c(16, 17), pt.cex = 1.05, cex = 0.82)
mtext("B  Spending profiles", side = 3, line = 0.6, adj = 0,
  font = 2, col = ink)
mtext("Spending gradient (% of mean)",
  side = 1, line = 2.8, col = ink)
dev.off()

stepwise = read_export("stepwise_table.csv")
main_variant = unique(stepwise$index_variant)[1]
steps = stepwise[stepwise$index_variant == main_variant, ]
step_labels = c("Bivariate", "+ Age and gender", "+ Income and education",
  "+ Household composition", "+ Population density", "+ Major-city residence")

pdf(file.path(out_dir, "publication_stepwise.pdf"), width = 7.2, height = 4.4,
  family = "Helvetica", useDingbats = FALSE)
par(mar = c(4.5, 12.2, 0.8, 2), las = 1, xaxs = "i")
ys = 6:1
plot(steps$per_sd, ys, type = "n", xaxt = "n", yaxt = "n", ylab = "", xlab = "",
  xlim = c(0, 380), ylim = c(0.5, 6.5), bty = "n")
abline(v = 0, col = light_grey, lwd = 1.2)
axis(1, at = seq(0, 300, 100), col = NA, col.axis = ink)
axis(2, at = ys, labels = step_labels, tick = FALSE, col.axis = ink)
for (i in seq_len(nrow(steps))) {
  draw_ci(steps$per_sd[i], steps$lo_sd[i], steps$hi_sd[i], ys[i], orange)
}
mtext("kg CO2e/year per composite SD", side = 1, line = 2.8, col = ink)
dev.off()