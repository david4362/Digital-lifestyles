# Local-only figure regeneration for the results presentation. Reads the
# real-data export CSVs and R/05_labels.R; writes vector PDFs. No TRE data,
# raw transaction files, cache or mock outputs are used.

library(data.table)
library(ggplot2)

source("../R/05_labels.R")

args = commandArgs(trailingOnly = TRUE)
out_dir = if (length(args) >= 1) args[1] else "../output/2026-10-22"
fig_dir = if (length(args) >= 2) args[2] else "figures"
full_dir = file.path(fig_dir, "full")
dir.create(full_dir, recursive = TRUE, showWarnings = FALSE)

csv = function(name) fread(file.path(out_dir, name))

stepwise = csv("stepwise_table.csv")
decomp = csv("decomp_table.csv")
sek = csv("sek_table.csv")
sample_flow = csv("sample_flow.csv")
anchor = csv("anchor_check.csv")
calibration = csv("calibration_check.csv")
coverage_check = csv("coverage_check.csv")
equivalence = csv("equivalence_table.csv")
ecommerce_check = csv("ecommerce_check.csv")
ecommerce_quintile = csv("ecommerce_quintile.csv")
ecommerce_desc = csv("ecommerce_desc.csv")
het_margins = csv("het_margins.csv")
item_level = csv("item_level.csv")
account_coverage = csv("account_coverage.csv")
leisure_index = csv("e1_leisure_index.csv")
leisure_mechanism = csv("e1_leisure_mechanism.csv")
volume_composition = csv("volume_composition.csv")
budget_shares = csv("budget_shares.csv")
quintile_desc = csv("quintile_desc.csv")
quintile_contrast = csv("quintile_contrast.csv")
index_variants = csv("index_variants.csv")
index_alpha = csv("index_alpha.csv")
index_weightings = csv("index_weightings.csv")
age_spline = csv("age_spline_rq1.csv")
deso_fe = csv("deso_fe.csv")
coverage_robustness = csv("coverage_robustness.csv")
representativeness = csv("representativeness_gradients.csv")
calls_stepwise = csv("calls_stepwise.csv")
calls_age = csv("calls_age_specs.csv")
calls_joint = csv("calls_joint_comparison.csv")
calls_e1 = csv("calls_e1_outcomes.csv")
e4_index_test = csv("e4_index_test.csv")
run_info = csv("run_info.csv")
descriptives = csv("descriptives.csv")

main_label = unname(variantlab[["main"]])
nocalls_label = unname(variantlab[["nocalls"]])
main_m5 = stepwise[model == "M5_city" & index_variant == main_label]
h_per_sd = calibration$hours_per_index_sd
alpha_main = index_alpha[scale == "Main index (11 items)", alpha]
calls_sep = calls_joint[specification == "Calls separately, complete 11-item sample", estimate]
calls_cond = calls_joint[specification == "Calls conditional on other 10 items", estimate]
calls_unique_pct = 100 * calls_cond / calls_sep

ink = "#22313F"
blue = "#1F4E79"
teal = "#007C83"
coral = "#C44E52"
grey = "#9AA5B1"
grid = "#E8EDF3"
zero_col = "#B8C2CC"
light = "#F5F8FA"
font = "Fira Sans"

fmt1 = function(x) formatC(x, format = "f", digits = 1, big.mark = ",")
fmt0 = function(x) formatC(x, format = "f", digits = 0, big.mark = ",")
fmt_pct1 = function(x) sprintf("%.1f%%", x)
fmt_p = function(p) if (p < 0.001) "$p<0.001$" else sprintf("$p=%.2f$", p)
tex_pct = function(x, d = 1) sprintf(paste0("%.", d, "f\\%%"), x)
macro = function(name, value) paste0("\\newcommand{\\", name, "}{", value, "}")

theme_pres = function(base_size = 11) {
  theme_minimal(base_size = base_size, base_family = font) +
    theme(
      plot.background = element_rect(fill = "white", color = NA),
      panel.background = element_rect(fill = "white", color = NA),
      panel.grid.major = element_line(color = grid, linewidth = 0.35),
      panel.grid.minor = element_blank(),
      panel.border = element_blank(),
      axis.line = element_blank(),
      axis.ticks = element_blank(),
      axis.text = element_text(color = ink, size = rel(0.88)),
      axis.title = element_text(color = ink, size = rel(0.92)),
      plot.title = element_text(color = ink, size = rel(1.18), face = "bold", hjust = 0),
      plot.subtitle = element_text(color = grey, size = rel(0.88), hjust = 0, margin = margin(b = 8)),
      plot.caption = element_text(color = grey, size = rel(0.75), hjust = 0),
      legend.position = "none",
      strip.background = element_blank(),
      strip.text = element_text(color = ink, face = "bold", hjust = 0),
      plot.title.position = "plot",
      plot.margin = margin(10, 14, 8, 10)
    )
}

forest = function(d, xlab, title, subtitle = NULL, col = NULL, sig = NULL,
    ref = NULL, base_size = 11, show_values = FALSE, value_fmt = fmt1,
    zero_line = TRUE, xlim = NULL) {
  d = copy(data.table(d))
  d$label = factor(d$label, levels = d$label)
  n = nrow(d)
  if (is.null(col)) {
    col = if (is.null(sig)) rep(blue, n) else ifelse(!is.na(sig) & sig, blue, grey)
  }
  col = rep_len(col, n)
  p = ggplot(d, aes(x = est, y = label)) +
    geom_segment(aes(x = lo, xend = hi, y = label, yend = label), color = col,
      linewidth = 1.35, lineend = "round") +
    geom_point(aes(x = est), color = col, size = 3.1) +
    labs(x = xlab, y = NULL) +
    theme_pres(base_size = base_size) +
    theme(panel.grid.major.y = element_blank())
  if (zero_line) {
    p = p + geom_vline(xintercept = 0, linetype = "dashed", color = zero_col, linewidth = 0.6)
  }
  if (!is.null(ref)) {
    p = p + geom_vline(xintercept = ref, linetype = "dotted", color = teal, linewidth = 0.8)
  }
  right_mult = if (show_values) 0.18 else 0.08
  p = p + scale_x_continuous(limits = xlim,
    expand = expansion(mult = c(0.06, right_mult)), labels = scales::comma)
  if (show_values) {
    p = p + geom_text(aes(x = hi, label = value_fmt(est)), hjust = -0.15,
      color = ink, size = 2.9, family = font)
  }
  p
}

bar_chart = function(d, xlab, title, subtitle = NULL, fill = NULL,
    base_size = 11, show_values = TRUE, value_fmt = fmt1) {
  d = copy(data.table(d))
  d$label = factor(d$label, levels = d$label)
  if (is.null(fill)) fill = rep(blue, nrow(d))
  d$fill = rep_len(fill, nrow(d))
  p = ggplot(d, aes(x = value, y = label)) +
    geom_vline(xintercept = 0, color = zero_col, linewidth = 0.6) +
    geom_col(aes(fill = fill), width = 0.72) +
    scale_fill_identity() +
    labs(x = xlab, y = NULL) +
    theme_pres(base_size = base_size) +
    scale_x_continuous(expand = expansion(mult = c(0.08, 0.16)), labels = scales::comma)
  if (show_values) {
    p = p + geom_text(aes(x = value, label = value_fmt(value),
      hjust = ifelse(value >= 0, -0.15, 1.15)), color = ink, size = 2.9, family = font)
  }
  p
}

column_chart = function(d, xlab, ylab, title, subtitle = NULL, fill = NULL,
    base_size = 11, show_values = TRUE, value_fmt = fmt1) {
  d = copy(data.table(d))
  d$label = factor(d$label, levels = d$label)
  if (is.null(fill)) fill = rep(blue, nrow(d))
  d$fill = rep_len(fill, nrow(d))
  p = ggplot(d, aes(x = label, y = value)) +
    geom_col(aes(fill = fill), width = 0.72) +
    scale_fill_identity() +
    labs(x = xlab, y = ylab) +
    theme_pres(base_size = base_size) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.14)), labels = scales::comma)
  if (show_values) {
    p = p + geom_text(aes(label = value_fmt(value)), vjust = -0.35,
      color = ink, size = 2.9, family = font)
  }
  p
}

save_pdf = function(name, plot, width, height, folder = fig_dir) {
  ggsave(file.path(folder, name), plot = plot, width = width, height = height,
    units = "in", device = grDevices::cairo_pdf, bg = "white")
}

# ---------------------------------------------------------------------------
# Deck figures
# ---------------------------------------------------------------------------

stagelab = c(survey = "Survey respondents",
  battery_gate = "Completed the digital-index questions",
  valid_months = "Enough bank-transaction months", controls = "Background data linked",
  with_emissions = "Carbon-footprint data available",
  m5_complete_case = "Full analysis sample",
  e4_reporters = "Reported device screen time")
model_plain = c(M0_bivariate = "Unadjusted",
  M1_sex_age = "+ Age & gender",
  M2_income_educ = "+ Income & education",
  M3_household = "+ Household",
  M4_density = "+ Population density",
  M5_city = "+ Full model")
sample_bar = function(d, title, subtitle) {
  bar_chart(d, "People", title, subtitle, fill = c(rep(blue, 6), teal),
    show_values = FALSE) +
    geom_text(aes(x = value, label = fmt0(value)), hjust = -0.15,
      color = ink, size = 3, family = font)
}
funnel_order = c("e4_reporters", "m5_complete_case", "with_emissions",
  "controls", "valid_months", "battery_gate", "survey")
flow_fig = sample_flow[match(funnel_order, stage), .(
  label = unname(stagelab[stage]), value = n)]
slide_flow = sample_bar(flow_fig, "From survey to the analysis sample",
  "People, not transaction rows")
save_pdf("slide_flow.pdf", slide_flow, 9.6, 4.2)

step_fig = function(show_values = FALSE, base_size = 10) {
  d = stepwise[index_variant == main_label, .(
    label = unname(model_plain[model]), est = per_sd, lo = lo_sd, hi = hi_sd)]
  xlim = c(min(d$lo) * 0.9, max(d$hi) * 1.18)
  forest(d, "kg CO2e per 1-SD step (95% CI)",
    "The association survives adjustment for background differences",
    sprintf("Same %s people in every model; full model fit = %.3f; one typical step = %.2f h/day of device screen time",
      fmt0(main_m5$n), main_m5$r2, h_per_sd),
    col = ifelse(d$label == unname(model_plain[["M5_city"]]), teal, blue),
    base_size = base_size, show_values = show_values,
    zero_line = FALSE, xlim = xlim)
}
save_pdf("slide_headline.pdf", step_fig(show_values = TRUE, base_size = 10), 9.6, 4.3)
save_pdf("full/stepwise_coef.pdf", step_fig(base_size = 10), 9.6, 4.3)
save_pdf("full/pres_stepwise.pdf", step_fig(base_size = 11), 9.6, 4.3)

anchor_figure = function(base_size = 10) {
  e4_rows = e4_index_test[specification %in% c("Separate M5", "Joint M5") &
      exposure %in% c("Index (per SD)", "E4 screen time (per SD)")]
  e4_rows[, label := paste0(
    ifelse(grepl("^E4", exposure), "Device screen time", "Digital index"),
    " (", ifelse(specification == "Separate M5", "separate model", "joint model"), ")")]
  forest(e4_rows[, .(label, est = estimate, lo = lo, hi = hi)],
    "kg CO2e per 1-SD step (screen-time subgroup)",
    NULL, NULL,
    col = ifelse(grepl("^E4", e4_rows$exposure), grey, blue),
    base_size = base_size, show_values = TRUE)
}
save_pdf("slide_calibration.pdf", anchor_figure(base_size = 10), 9.0, 3.2)
save_pdf("full/anchor_plot.pdf", anchor_figure(base_size = 10), 9.0, 3.2)

decomp_pct_figure = function(basis, show_values = FALSE, base_size = 10) {
  d = if (basis == "co2e") copy(decomp) else copy(sek)
  d = d[cat != "total"]
  d[, label := fulllab(cat)]
  d = d[!duplicated(label)]
  d[, `:=`(est = 100 * per_sd / mean, lo_pct = 100 * lo / mean,
    hi_pct = 100 * hi / mean)]
  setorder(d, est)
  xlab = if (basis == "co2e") {
    "Change in annual footprint per 1-SD step (% of category mean)"
  } else {
    "Change in annual spending per 1-SD step (% of category mean)"
  }
  forest(d[, .(label, est, lo = lo_pct, hi = hi_pct)], xlab,
    if (basis == "co2e") "Where does the extra footprint come from?" else "Spending breakdown",
    "Full model, 95% confidence intervals; blue = statistically significant",
    sig = d$p < 0.05, base_size = base_size, show_values = show_values,
    value_fmt = fmt_pct1)
}
save_pdf("slide_decomp.pdf", decomp_pct_figure("co2e", show_values = TRUE, base_size = 9.5), 10.5, 5.0)
save_pdf("full/decomp_pct_co2e.pdf", decomp_pct_figure("co2e", base_size = 9.5), 9.6, 5.4)
save_pdf("full/decomp_pct_sek.pdf", decomp_pct_figure("sek", base_size = 9.5), 9.6, 5.4)

decomp_abs = function(show_values = FALSE, base_size = 10) {
  d = copy(decomp)
  setorder(d, per_sd)
  forest(d[, .(label = fulllab(cat), est = per_sd, lo = lo, hi = hi)],
    "kg CO2e per 1-SD step (95% CI)",
    "Breakdown by broad groups and largest categories",
    "Full model; blue = statistically significant",
    sig = d$p < 0.05, base_size = base_size, show_values = show_values)
}
save_pdf("full/decomp_forest.pdf", decomp_abs(base_size = 9.5), 9.6, 5.8)

group_show = c("total", "transport", "ecom", "digital", "placebo_insurance", "vehicles")
pres_dec = decomp[cat %in% group_show, .(
  label = unname(grouplab[cat]), est = per_sd, lo = lo, hi = hi)]
save_pdf("full/pres_decomp.pdf",
  forest(pres_dec, "kg CO2e per 1-SD step (95% CI)",
    "Breakdown by broad spending groups", "Full model",
    sig = decomp[cat %in% group_show, p < 0.05], base_size = 11,
    show_values = TRUE), 9.6, 4.3)
save_pdf("full/waterfall.pdf",
  bar_chart(decomp[cat %in% setdiff(group_show, "total"), .(
    label = unname(grouplab[cat]), value = per_sd)],
    "kg CO2e per 1-SD step", "Contribution per group (full model)",
    fill = ifelse(decomp[cat %in% setdiff(group_show, "total"), p < 0.05], blue, grey)),
  9.6, 4.3)

sek_sorted = copy(sek)
setorder(sek_sorted, per_sd)
save_pdf("full/sek_forest.pdf",
  forest(sek_sorted[, .(label = fulllab(cat), est = per_sd, lo = lo, hi = hi)],
    "SEK per 1-SD step (95% CI)", "Spending breakdown in SEK",
    "Full model; blue = statistically significant", sig = sek_sorted$p < 0.05,
    base_size = 9.5), 9.6, 5.8)

comp_lab = c(headline_gradient = "Total association", volume_component = "More spending",
  composition_component = "Different basket",
  covariance_residual = "Accounting remainder")
vc = volume_composition[component %in% names(comp_lab), .(
  label = unname(comp_lab[component]), value = estimate)]
vc_text = vc[, .(label = factor(label, levels = vc$label), value)]
slide_volume = bar_chart(vc, "kg CO2e per 1-SD step",
  "Most of the extra footprint is simply more spending",
  sprintf("Over %s%% comes from higher spending; the basket-composition difference is not significant (p = %.2f)",
    fmt1(volume_composition[component == "volume_share", estimate]),
    volume_composition[component == "composition_component", p]),
  fill = c(blue, teal, grey, coral), show_values = FALSE) +
  geom_errorbar(data = volume_composition[component %in% names(comp_lab) & !is.na(se),
    .(label = factor(unname(comp_lab[component]), levels = vc$label),
      estimate, se)],
    aes(x = estimate, y = label, xmin = estimate - 1.96 * se,
      xmax = estimate + 1.96 * se), inherit.aes = FALSE,
    color = ink, linewidth = 0.7, width = 0.18) +
  geom_text(data = vc_text,
    aes(x = ifelse(value >= 0, 285, value), y = label, label = fmt1(value)),
    hjust = ifelse(vc_text$value >= 0, 0, 1.15),
    color = ink, size = 3, family = font)
save_pdf("slide_volume.pdf", slide_volume, 9.6, 4.1)

vol_full_left = bar_chart(vc, "kg CO2e per 1-SD step", "More spending vs dirtier basket (full model)",
  fill = c(blue, teal, grey, coral))
sh = budget_shares[basis == "share of spending"][order(per_sd_pp)]
vol_full_right = forest(sh[, .(label = fulllab(cat), est = per_sd_pp, lo = lo, hi = hi)],
  "Budget-share change, percentage points per 1-SD step", "Budget shares (full model)",
  "Blue = p < 0.05", sig = sh$p < 0.05, base_size = 9)
save_pdf("full/volume_composition.pdf",
  patchwork::wrap_plots(list(vol_full_left, vol_full_right), nrow = 1), 12.5, 5.2)

quintile_panel = function(ycol, ylab, title, fill, value_fmt = fmt0) {
  d = quintile_desc[, .(dig_q, value = get(ycol))]
  ggplot(d, aes(x = dig_q, y = value, group = 1)) +
    geom_hline(yintercept = d[1, value], linetype = "dotted", color = zero_col, linewidth = 0.6) +
    geom_line(color = fill, linewidth = 1.2) +
    geom_point(color = fill, size = 3.1) +
    geom_text(aes(label = value_fmt(value)), vjust = -0.8, color = ink,
      size = 2.8, family = font) +
    scale_y_continuous(expand = expansion(mult = c(0.08, 0.18)), labels = scales::comma) +
    labs(x = "Digital-index group (lowest to highest)", y = ylab) +
    theme_pres(base_size = 9.5)
}
quintile_panels = list(
  quintile_panel("mean_co2e", "kg CO2e/year", "Annual footprint", blue),
  quintile_panel("mean_spend_goods", "SEK/year", "Spending on goods (excluding rent)", teal),
  quintile_panel("mean_intensity", "kg CO2e per 1,000 SEK", "Carbon per 1,000 SEK spent", coral,
    value_fmt = function(x) sprintf("%.1f", x)))
slide_quintiles = patchwork::wrap_plots(quintile_panels, nrow = 1)
save_pdf("slide_quintiles.pdf", slide_quintiles, 11.0, 3.6)
save_pdf("full/quintile_gradient.pdf",
  patchwork::wrap_plots(lapply(list(
    list("mean_co2e", "kg CO2e/year", "Footprint by digital-index group", blue, fmt0),
    list("mean_spend_goods", "SEK/year", "Spending by digital-index group", teal, fmt0),
    list("mean_intensity", "kg CO2e per 1,000 SEK", "Carbon per 1,000 SEK by digital-index group", coral,
      function(x) sprintf("%.1f", x))), function(z)
      quintile_panel(z[[1]], z[[2]], z[[3]], z[[4]], z[[5]])), nrow = 1),
  12.0, 3.8)

item_fig = function(show_values = FALSE, base_size = 9.5) {
  d = copy(item_level)
  d[, label := paste0(label, ifelse(in_main_index, "", " (excluded)"))]
  setorder(d, estimate)
  forest(d[, .(label, est = estimate, lo = lo, hi = hi)],
    "kg CO2e per 1-SD step in each activity (95% CI)",
    "Which digital activities track a larger footprint?",
    "Blue = significant after multiple-testing correction; calls stands out",
    col = ifelse(d$significant_bh, blue, grey), base_size = base_size,
    show_values = show_values)
}
save_pdf("slide_items.pdf", item_fig(show_values = TRUE, base_size = 9.5), 9.6, 5.2)
save_pdf("full/item_level_forest.pdf", item_fig(base_size = 9.5), 9.6, 5.8)

calls_figure = function() {
  age_plain = c("M5 linear age" = "Linear age adjustment",
    "M5 age bands" = "Age-band adjustment",
    "M5 natural spline age (4 df)" = "Flexible age adjustment")
  joint_plain = c(
    "Calls separately, complete 11-item sample" = "Calls alone",
    "Calls conditional on other 10 items" = "Calls, accounting for other activities")
  left_rows = calls_stepwise[, .(label = unname(model_plain[model]),
    est = estimate, lo = lo, hi = hi)]
  right_rows = rbind(
    calls_age[, .(label = unname(age_plain[specification]),
      est = estimate, lo = lo, hi = hi)],
    calls_joint[, .(label = unname(joint_plain[specification]),
      est = estimate, lo = lo, hi = hi)])
  left_xlim = c(min(left_rows$lo) * 0.9, max(left_rows$hi) * 1.18)
  right_xlim = c(min(right_rows$lo) * 0.9, max(right_rows$hi) * 1.18)
  left = forest(left_rows, "kg CO2e per 1-SD step in calls (95% CI)",
    "Calls alone, with adjustments added",
    sprintf("Full model fit: %.3f vs %.3f for the full index",
      calls_stepwise[model == "M5_city", r2], main_m5$r2),
    col = ifelse(calls_stepwise$model == "M5_city", teal, blue),
    base_size = 9.5, show_values = TRUE,
    zero_line = FALSE, xlim = left_xlim)
  right = forest(right_rows, "kg CO2e per 1-SD step in calls (95% CI)",
    "Robust to age adjustment and other activities",
    sprintf("About %s%% remains after accounting for other activities",
      fmt0(calls_unique_pct)),
    col = c(rep(blue, 3), grey, coral), base_size = 9.5, show_values = TRUE,
    zero_line = FALSE, xlim = right_xlim)
  patchwork::wrap_plots(list(left, right), nrow = 1)
}
save_pdf("slide_calls.pdf", calls_figure(), 11.0, 4.6)

leisure_lab = c(library = "Library", sports_event = "Sports events",
  culture_event = "Culture events", dinner_guests = "Dinner guests",
  dancing = "Dancing", exercised = "Exercise", nature = "Nature",
  audiobook = "Audiobooks", music = "Music", book = "Books", film = "Film",
  tv_series = "TV series", ooh_leisure = "Out-of-home activities (average)",
  home_leisure = "At-home activities (average)")
ooh_items = c("library", "sports_event", "culture_event", "dinner_guests",
  "dancing", "exercised", "nature")
mechanism_figure = function() {
  d = copy(leisure_index)
  d[, label := unname(leisure_lab[outcome])]
  setorder(d, per_sd)
  left = forest(d[, .(label, est = per_sd, lo = lo, hi = hi)],
    "Change in activity frequency per 1-SD step (1-7 scale)",
    "More, not less, out-of-home and at-home activity",
    "Teal = out-of-home activities; grey = at-home activities",
    col = ifelse(d$outcome %in% c(ooh_items, "ooh_leisure"), teal, grey),
    base_size = 9.5)
  m = leisure_mechanism[outcome == "transport_co2e" & specification != "M5"]
  m[, label := paste0("Transport: ",
    ifelse(specification == "M5 + out-of-home leisure",
      "+ out-of-home activities", "+ both leisure measures"))]
  right = bar_chart(m[, .(label, value = pct_gradient_shared)],
    "Share of transport association explained (%)",
    "Little of the transport association is explained",
    sprintf("At most %s%%; leisure coefficients not significant",
      fmt1(max(m$pct_gradient_shared))),
    fill = teal,
    show_values = TRUE, value_fmt = fmt_pct1)
  patchwork::wrap_plots(list(left, right), nrow = 1)
}
save_pdf("slide_mechanism.pdf", mechanism_figure(), 11.0, 5.0)

mech_sorted = copy(leisure_index)
setorder(mech_sorted, per_sd)
save_pdf("full/mech_forest.pdf",
  forest(mech_sorted[, .(label = outcome, est = per_sd, lo = lo, hi = hi)],
    "Change in activity frequency per 1-SD step (1-7 scale)",
    "Digital index vs leisure frequency (95% CI)",
    col = ifelse(mech_sorted$outcome %in% c(ooh_items, "ooh_leisure"), teal, grey),
    base_size = 9.5), 9.6, 5.8)

rob = rbind(
  data.table(label = "Main result", est = main_m5$per_sd,
    lo = main_m5$lo_sd, hi = main_m5$hi_sd),
  index_variants[variant != main_label, .(
    label = c("Alternate question scaling", "Registered 13-question index",
      "Without calls")[match(variant,
      c("Items z-scaled on the battery sample",
        "All 13 items incl. e-commerce & online selling (>= 10 of 13)",
        nocalls_label))], est = per_sd, lo = lo, hi = hi)],
  index_weightings[, .(label = c("Device questions only",
    "Online-activity questions only", "Statistical composite")[
    match(variant, c("Device-use half (5 items)",
      "Digital-activity half (6 items)",
      "First principal component (complete items)"))],
    est = per_sd, lo = lo, hi = hi)],
  age_spline[model == "M5 natural spline age (4 df)", .(
    label = "Flexible age adjustment", est = per_sd, lo = lo, hi = hi)],
  deso_fe[, .(label = "Neighbourhood fixed effects", est = per_sd, lo = lo, hi = hi)],
  coverage_robustness[restriction == ">= 12 observed months", .(
    label = "At least 12 months of data", est = per_sd, lo = lo, hi = hi)],
  account_coverage[spec %in% c("M5 + bank accounts (linear)",
    "M5, observed spending 50-150% of register income"), .(
    label = c("Adjusted for linked accounts", "Plausible spending/income range")[
    match(spec, c("M5 + bank accounts (linear)",
      "M5, observed spending 50-150% of register income"))],
    est = per_sd, lo = lo, hi = hi)],
  representativeness[outcome == "co2e" & sample %in% c("Random-frame subset",
    "Random frame, sampling-IPW"), .(
    label = c("Random-frame subgroup", "Sampling-weighted subgroup")[
      match(sample, c("Random-frame subset", "Random frame, sampling-IPW"))],
    est = per_sd, lo = lo, hi = hi)])
rob_xlim = c(min(rob$lo) * 0.9, max(rob$hi) * 1.18)
slide_robustness = forest(rob, "kg CO2e per 1-SD step (95% CI)",
  "The positive association survives checks",
  "Dotted line = main estimate; all estimates positive",
  col = c(teal, rep(blue, nrow(rob) - 1)), ref = main_m5$per_sd,
  base_size = 9.5, show_values = TRUE,
  zero_line = FALSE, xlim = rob_xlim)
save_pdf("slide_robustness.pdf", slide_robustness, 10.0, 5.4)

# ---------------------------------------------------------------------------
# Recreated output figures
# ---------------------------------------------------------------------------

sample_full = sample_flow[match(funnel_order, stage), .(
  label = unname(stagelab[stage]), value = n)]
save_pdf("full/sample_flow.pdf",
  sample_bar(sample_full, "From survey to the analysis sample",
    "People, not transaction rows"), 9.0, 4.2)

eq = equivalence[, .(label = fulllab(cat), est = per_hour, lo = lo90, hi = hi90,
  delta = delta)]
eq_plot = forest(eq, "kg CO2e per extra screen-time hour/day (90% CI)",
  "Insurance check (no association expected)",
  "Dashed segment = equivalence bounds; dashed zero line",
  col = blue, base_size = 10) +
  geom_segment(data = eq, aes(x = -delta, xend = delta, y = label, yend = label),
    inherit.aes = FALSE, color = grey, linetype = "dashed", linewidth = 0.9)
save_pdf("full/equivalence_plot.pdf", eq_plot, 9.0, 4.0)

outlab = c(ecom_co2e = "E-commerce footprint", rest_co2e = "Rest of consumption footprint",
  sh_co2e = "E-commerce share of footprint", ecom_kr = "E-commerce spending",
  rest_kr = "Rest of consumption spending", sh_kr = "E-commerce share of spending")
speclab = c(M5 = "Full model", "M5+rest_co2e" = "+ Rest",
  "M5+rest_kr" = "+ Rest")
ecom_panel = function(outcomes, xlab, title) {
  d = ecommerce_check[outcome %in% outcomes]
  d[, label := paste0(unname(outlab[outcome]), " [", unname(speclab[spec]), "]")]
  forest(d[, .(label, est = per_sd, lo = lo, hi = hi)], xlab, title,
    sig = d$p < 0.05, base_size = 9)
}
ecom_levels = patchwork::wrap_plots(list(
  ecom_panel(c("ecom_co2e", "rest_co2e"), "kg CO2e per 1-SD step", "Levels, footprint"),
  ecom_panel(c("ecom_kr", "rest_kr"), "SEK per 1-SD step", "Levels, spending"),
  ecom_panel(c("sh_co2e", "sh_kr"), "share per 1-SD step", "E-commerce share")), nrow = 1)
save_pdf("full/ecommerce_levels.pdf", ecom_levels, 12.5, 4.1)

q_panels = lapply(c("ecom_co2e", "ecom_kr"), function(yc) {
  s = ecommerce_quintile[outcome == yc]
  forest(s[, .(label = paste("Income group", sub("^Q", "", income_q)),
    est = per_sd, lo = lo, hi = hi)],
    paste(ifelse(yc == "ecom_co2e", "kg CO2e", "SEK"), "per 1-SD step"),
    ifelse(yc == "ecom_co2e", "E-commerce footprint by income",
      "E-commerce spending by income"),
    sig = s$p < 0.05, base_size = 9)
})
save_pdf("full/ecommerce_quintile.pdf", patchwork::wrap_plots(q_panels, nrow = 1), 11.0, 4.1)

dignm = paste("Quintile", sub("^D", "", ecommerce_desc$dig_q))
ecom_desc_panels = list(
  column_chart(ecommerce_desc[, .(label = dignm, value = income)],
    "Digital-index group", "Mean disposable income", "Income by digital-index group",
    fill = blue),
  column_chart(ecommerce_desc[, .(label = dignm, value = tot_kr)],
    "Digital-index group", "Mean total spending (SEK/year)",
    "Spending by digital-index group", fill = teal))
save_pdf("full/ecommerce_desc.pdf", patchwork::wrap_plots(ecom_desc_panels, nrow = 1), 9.0, 4.0)

het_panel = function(mod_name, title) {
  s = het_margins[mod == mod_name]
  lvl = s$level
  lvl[lvl == "Man"] = "Men"
  lvl[lvl == "Kvinna"] = "Women"
  lvl[lvl == "TRUE"] = "Large-city residence"
  lvl[lvl == "FALSE"] = "Outside large cities"
  forest(s[, .(label = lvl, est = est, lo = lo, hi = hi)],
    "kg CO2e per 1-SD step", title, col = blue, base_size = 9)
}
save_pdf("full/het_plot.pdf", patchwork::wrap_plots(list(
  het_panel("band", "Age group"), het_panel("gender", "Gender"),
  het_panel("major_city", "Large-city residence")), nrow = 1), 10.5, 4.0)

account_strata = account_coverage[analysis == "Account strata"]
account_full = forest(account_strata[, .(
  label = paste0(spec, " (n=", n, ")"), est = per_sd, lo = lo, hi = hi)],
  "kg CO2e per 1-SD step (95% CI)", "Association by number of linked accounts",
  "Dotted line = total-sample estimate", col = blue, ref = main_m5$per_sd,
  base_size = 9.5, show_values = TRUE)
save_pdf("full/account_coverage.pdf", account_full, 9.6, 4.5)

cov_outlab = c(observed_annual_spending = "Observed spending",
  register_income = "Register income", bank_accounts = "Connected accounts")
cov = coverage_check[, .(
  label = unname(cov_outlab[outcome]),
  est = 100 * per_sd / mean, lo = 100 * lo / mean, hi = 100 * hi / mean)]
save_pdf("full/coverage_accounts.pdf",
  forest(cov, "% change in outcome per 1-SD step (full model)",
    "Coverage and the digital association",
    "Summary replacement: person-level scatter is not in the export",
    col = blue, base_size = 10, show_values = TRUE, value_fmt = fmt_pct1),
  9.6, 4.1)

# ---------------------------------------------------------------------------
# Numeric macros for slides.tex
# ---------------------------------------------------------------------------

run_date = as.character(run_info$run_date)
headline_pct = decomp[cat == "total", pct_of_mean]
vol_share = volume_composition[component == "volume_share", estimate]
vol_est = volume_composition[component == "volume_component", estimate]
comp_est = volume_composition[component == "composition_component", estimate]
comp_p = volume_composition[component == "composition_component", p]
premium = volume_composition[component == "pct_premium", estimate]
q_gap = quintile_contrast[outcome == "co2e", d5_minus_d1]
q_pct = quintile_contrast[outcome == "co2e", pct_of_mean]
q_spend = quintile_contrast[outcome == "spend_goods", d5_minus_d1]
q_spend_pct = quintile_contrast[outcome == "spend_goods", pct_of_mean]
q_income_pct = 100 * (quintile_desc[dig_q == "D5", mean_register_income] /
  quintile_desc[dig_q == "D1", mean_register_income] - 1)
transport_est = decomp[cat == "transport", per_sd]
ecom_est = decomp[cat == "ecom", per_sd]
digital_est = decomp[cat == "digital", per_sd]
placebo_est = decomp[cat == "placebo_insurance", per_sd]
calls_est = item_level[item == "q11b_2", estimate]
calls_r2 = calls_stepwise[model == "M5_city", r2]
nocalls_est = index_variants[variant == nocalls_label, per_sd]
thirteen_est = index_variants[variant ==
  "All 13 items incl. e-commerce & online selling (>= 10 of 13)", per_sd]
ooh_est = leisure_index[outcome == "ooh_leisure", per_sd]
home_est = leisure_index[outcome == "home_leisure", per_sd]
med_max = max(leisure_mechanism[outcome == "transport_co2e", pct_gradient_shared])
deso_est = deso_fe$per_sd
spline_est = age_spline[model == "M5 natural spline age (4 df)", per_sd]
account_att = abs(account_coverage[spec == "M5 + bank accounts (linear)",
  pct_change_vs_reference])
spending_plausible = account_coverage[
  grepl("50-150", spec, fixed = TRUE), per_sd]
survey_n = sample_flow[stage == "survey", n]
index_questions_n = sample_flow[stage == "battery_gate", n]
valid_months_n = sample_flow[stage == "valid_months", n]
screen_time_n = sample_flow[stage == "e4_reporters", n]
index_items_n = length(strsplit(run_info$index_items, " ")[[1]])
index_desc = descriptives[measure == "Digital index (standardized, main)"]
index_mean = sprintf("%.0f", index_desc$mean)
index_sd = fmt0(index_desc$sd)
volume_margins = csv("volume_margins.csv")
co2_pct = volume_margins[outcome == "co2e" & spec == "M5", pct_of_mean]
spend_pct = volume_margins[outcome == "spend_goods" & spec == "M5", pct_of_mean]

macros = c(
  macro("RunDate", run_date),
  macro("SourceRun", paste0("\\texttt{output/", run_date, "}")),
  macro("MfiveN", fmt0(main_m5$n)),
  macro("SurveyN", fmt0(survey_n)),
  macro("IndexQuestionsN", fmt0(index_questions_n)),
  macro("ValidMonthsN", fmt0(valid_months_n)),
  macro("ScreenTimeN", fmt0(screen_time_n)),
  macro("IndexItems", fmt0(index_items_n)),
  macro("IndexMean", index_mean),
  macro("IndexSd", index_sd),
  macro("MainEstimate", fmt1(main_m5$per_sd)),
  macro("MainCI", sprintf("%.1f--%.1f", main_m5$lo_sd, main_m5$hi_sd)),
  macro("MainP", fmt_p(main_m5$p)),
  macro("MainPct", tex_pct(headline_pct)),
  macro("MainRtwo", sprintf("%.3f", main_m5$r2)),
  macro("AnchorB", sprintf("%.3f", calibration$hours_per_index_sd)),
  macro("AnchorRtwo", sprintf("%.3f", anchor[model == "bivariate", r2])),
  macro("AnchorN", fmt0(anchor[model == "bivariate", n])),
  macro("PerHour", fmt1(calibration$m5_per_hour_derived)),
  macro("VolumeShare", tex_pct(vol_share)),
  macro("VolumeKg", fmt1(vol_est)),
  macro("CompositionKg", fmt1(comp_est)),
  macro("CompositionP", fmt_p(comp_p)),
  macro("Premium", sprintf("%.2f", premium)),
  macro("FootprintPct", tex_pct(co2_pct, 2)),
  macro("SpendPct", tex_pct(spend_pct, 2)),
  macro("QuintileGap", fmt0(q_gap)),
  macro("QuintilePct", tex_pct(q_pct)),
  macro("QuintileSpend", fmt0(q_spend)),
  macro("QuintileSpendPct", tex_pct(q_spend_pct)),
  macro("QuintileIncomeRawPct", tex_pct(q_income_pct)),
  macro("TransportEst", fmt1(transport_est)),
  macro("EcomEst", fmt1(ecom_est)),
  macro("DigitalEst", fmt1(digital_est)),
  macro("PlaceboEst", fmt1(placebo_est)),
  macro("CallsEst", fmt1(calls_est)),
  macro("CallsRtwo", sprintf("%.3f", calls_r2)),
  macro("CallsUniquePct", tex_pct(calls_unique_pct, 0)),
  macro("IndexRtwo", sprintf("%.3f", main_m5$r2)),
  macro("AlphaMain", sprintf("%.2f", alpha_main)),
  macro("NocallsEst", fmt1(nocalls_est)),
  macro("ThirteenEst", fmt1(thirteen_est)),
  macro("OohEst", sprintf("%.3f", ooh_est)),
  macro("HomeEst", sprintf("%.3f", home_est)),
  macro("MediationMax", tex_pct(med_max)),
  macro("DesoEst", fmt1(deso_est)),
  macro("SplineEst", fmt1(spline_est)),
  macro("AccountAtt", tex_pct(account_att)),
  macro("SpendingPlausible", fmt1(spending_plausible)))
writeLines(macros, file.path(fig_dir, "numbers.tex"))

# ---------------------------------------------------------------------------
# Provenance manifest
# ---------------------------------------------------------------------------

slide_files = c("slide_flow.pdf", "slide_headline.pdf", "slide_calibration.pdf",
  "slide_decomp.pdf", "slide_volume.pdf", "slide_quintiles.pdf",
  "slide_items.pdf", "slide_calls.pdf", "slide_mechanism.pdf",
  "slide_robustness.pdf")
slide_sources = c(
  "sample_flow.csv",
  "stepwise_table.csv; calibration_check.csv",
  "calibration_check.csv; e4_index_test.csv",
  "decomp_table.csv",
  "volume_composition.csv; volume_margins.csv",
  "quintile_desc.csv; quintile_contrast.csv",
  "item_level.csv; index_variants.csv; index_alpha.csv",
  "calls_stepwise.csv; calls_age_specs.csv; calls_joint_comparison.csv; calls_e1_outcomes.csv",
  "e1_leisure_index.csv; e1_leisure_mechanism.csv",
  "stepwise_table.csv; index_variants.csv; index_weightings.csv; age_spline_rq1.csv; deso_fe.csv; coverage_robustness.csv; account_coverage.csv; representativeness_gradients.csv")

full_files = c("anchor_plot.pdf", "coverage_accounts.pdf", "stepwise_coef.pdf",
  "pres_stepwise.pdf", "decomp_forest.pdf", "pres_decomp.pdf", "waterfall.pdf",
  "sek_forest.pdf", "sample_flow.pdf", "equivalence_plot.pdf",
  "ecommerce_levels.pdf", "ecommerce_quintile.pdf", "ecommerce_desc.pdf",
  "het_plot.pdf", "item_level_forest.pdf", "account_coverage.pdf",
  "mech_forest.pdf", "volume_composition.pdf", "quintile_gradient.pdf",
  "decomp_pct_co2e.pdf", "decomp_pct_sek.pdf")
full_sources = c(
  "e4_index_test.csv",
  "coverage_check.csv",
  "stepwise_table.csv; calibration_check.csv",
  "stepwise_table.csv; calibration_check.csv",
  "decomp_table.csv",
  "decomp_table.csv",
  "decomp_table.csv",
  "sek_table.csv",
  "sample_flow.csv",
  "equivalence_table.csv",
  "ecommerce_check.csv",
  "ecommerce_quintile.csv",
  "ecommerce_desc.csv",
  "het_margins.csv",
  "item_level.csv",
  "account_coverage.csv",
  "e1_leisure_index.csv",
  "volume_composition.csv; budget_shares.csv",
  "quintile_desc.csv",
  "decomp_table.csv",
  "sek_table.csv")
full_status = rep("exact CSV replot", length(full_files))
full_status[1] = "aggregate-only replacement: person-level anchor scatter not exported"
full_status[2] = "aggregate-only replacement: person-level accounts scatter not exported"
full_status[20:21] = "CSV-derived redraw from latest export"

slide_status = rep("exact CSV replot", length(slide_files))

manifest = rbind(
  data.table(file = slide_files, source_csvs = slide_sources, local_only = TRUE,
    status = slide_status, deck = TRUE),
  data.table(file = paste0("full/", full_files), source_csvs = full_sources,
    local_only = TRUE, status = full_status, deck = FALSE))
fwrite(manifest, file.path(fig_dir, "manifest.csv"))

cat(sprintf("Wrote %d figure PDFs and %s from %s\n",
  nrow(manifest), file.path(fig_dir, "manifest.csv"), out_dir))
