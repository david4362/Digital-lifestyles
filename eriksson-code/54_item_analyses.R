library(data.table)
library(sandwich)
library(lmtest)

# Person x category annual emissions, canonical recipe from 20
cat_annual <- annualise(monthly_co2e, "co2e")

# Category vectors defined in 20; restaurant added as an out-of-home contrast
category_targets <- list(
  transport = transport_co2e,
  ecom = ecom_co2e,
  digital = digital_co2e,
  restaurant = "restaurant_co2e"
)

# The q11 columns in analysis_data are the z-scaled items from 40 (scaled on
# the analysis sample, per the pre-registered construction). Gaming is
# the sum of the two gaming-frequency z-scores (game console use q11_4 +
# digital gaming q11b_5), so both exposures are in units of item SDs.
item_data <- copy(analysis_data)
item_data[, social_media := q11b_3]
item_data[, gaming := q11b_5 + q11_4]

# social_games: category outcomes y joined per category group
form_y <- sub("^co2e", "y", lm_formula)

social_games <- rbindlist(lapply(names(category_targets), function(outcome) {
  yy <- cat_annual[category %in% category_targets[[outcome]], .(y = sum(y, na.rm = T)), by = aid]
  d <- item_data[yy, on = "aid", nomatch = 0]

  social_model <- lm(as.formula(sub("index", "social_media", form_y, fixed = TRUE)), data = d)
  social_ct <- coeftest(social_model, vcov. = vcovHC(social_model, type = "HC3"))["social_media", ]
  gaming_model <- lm(as.formula(sub("index", "gaming", form_y, fixed = TRUE)), data = d)
  gaming_ct <- coeftest(gaming_model, vcov. = vcovHC(gaming_model, type = "HC3"))["gaming", ]

  rbind(
    data.table(
      outcome = outcome,
      exposure = "Social media q11b_3",
      n = nobs(social_model),
      estimate = social_ct[["Estimate"]],
      se = social_ct[["Std. Error"]],
      p = social_ct[["Pr(>|t|)"]]
    ),
    data.table(
      outcome = outcome,
      exposure = "Gaming q11b_5 + q11_4",
      n = nobs(gaming_model),
      estimate = gaming_ct[["Estimate"]],
      se = gaming_ct[["Std. Error"]],
      p = gaming_ct[["Pr(>|t|)"]]
    )
  )
}))
social_games[, `:=`(lo = estimate - 1.96 * se, hi = estimate + 1.96 * se)]
fwrite(social_games, file.path(out_dir, "social_games.csv"))

# Item-level total-emissions gradients. The p-value adjustment is across the
# 13 item tests. Item texts from the codebook: device-use frequencies
# q11_1-q11_5 (computer, smartphone, TV, game console, tablet) and
# digital-activity frequencies q11b_1-q11b_8 (streaming, calls, social
# media, information search, gaming, digital reading, e-commerce, online
# selling). The two e-commerce items are NOT part of the main index (see
# 20) but are kept here so their item-level gradients stay visible;
# in_main_index records which items the main index contains.
item_names <- c(paste0("q11_", 1:5), paste0("q11b_", 1:8))
item_labels <- c(
  q11_1 = "Computer", q11_2 = "Smartphone", q11_3 = "TV",
  q11_4 = "Game console", q11_5 = "Tablet",
  q11b_1 = "Streaming", q11b_2 = "Calls", q11b_3 = "Social media",
  q11b_4 = "Information search", q11b_5 = "Gaming",
  q11b_6 = "Digital reading", q11b_7 = "E-commerce", q11b_8 = "Online selling")
item_level <- rbindlist(lapply(item_names, function(item) {
  m <- lm(as.formula(sub("index", item, lm_formula, fixed = TRUE)), data = analysis_data)
  ct <- coeftest(m, vcov. = vcovHC(m, type = "HC3"))[item, ]
  data.table(
    item = item,
    n = nobs(m),
    estimate = ct[["Estimate"]],
    se = ct[["Std. Error"]],
    p = ct[["Pr(>|t|)"]]
  )
}))
item_level[, label := item_labels[item]]
item_level[, in_main_index := item %in% index_main_items]
item_level[, p_bh := p.adjust(p, method = "BH")]
item_level[, significant_bh := p_bh < 0.05]
item_level[, `:=`(lo = estimate - 1.96 * se, hi = estimate + 1.96 * se)]
fwrite(item_level, file.path(out_dir, "item_level.csv"))

# Forest figure, built directly from the final table: one row per item in
# reversed battery order (Computer at the top of the plot), and the label
# vector comes from those same rows. Earlier runs had the axis labels built from
# reversed factor levels while the points were plotted in table order, so
# every label sat on another item's estimate (e.g. "Social media" showed
# Streaming's negative value while the CSV said +206 kg). The audit below
# (item_figure_check.csv + stopifnot) makes that failure mode impossible to
# reintroduce silently: every y position's label, estimate and CI in the
# figure must equal the final table row for that item.
fig <- item_level[match(rev(item_names), item)]
y <- seq_len(nrow(fig))
stopifnot(
  identical(fig$item, rev(item_names)),
  identical(unname(item_labels[fig$item]), fig$label),
  identical(fig$estimate, item_level[match(fig$item, item), estimate]),
  identical(fig$lo, item_level[match(fig$item, item), lo]),
  identical(fig$hi, item_level[match(fig$item, item), hi]))
item_figure_check <- data.table(
  item = fig$item, label = item_labels[fig$item], y_position = y,
  estimate = fig$estimate, lo = fig$lo, hi = fig$hi,
  in_main_index = fig$in_main_index)
fwrite(item_figure_check, file.path(out_dir, "item_figure_check.csv"))

png(file.path(out_dir, "item_level_forest.png"), width = 1000, height = 700, res = 120)
par(mar = c(5, 12, 4, 2))
plot(fig$estimate, y,
  xlim = range(c(fig$lo, fig$hi)),
  yaxt = "n", pch = 19,
  col = ifelse(fig$significant_bh, "steelblue", "grey50"),
  xlab = "kg CO2e per one-SD item increase (HC3 95% CI)", ylab = "",
  main = "Item-level digital gradients")
axis(2, y, item_labels[fig$item], las = 1, cex.axis = 0.8)
segments(fig$lo, y, fig$hi, y, col = "grey40")
abline(v = 0, lty = 2, col = "grey")
dev.off()
