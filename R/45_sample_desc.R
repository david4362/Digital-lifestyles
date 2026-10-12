library(data.table)

# Sample flow: report participant IDs and physical rows separately. The
# regression sample is the fixed M5 complete-case sample from 40, not merely
# the set of IDs with emissions data. The battery stage is the >= 8 of 11
# main-items gate from 20 (the pre-registration tolerance of up to 3 missing
# items; the earlier rule required the complete 13-item battery).
flow = data.table(
  stage = c("survey", "battery_gate", "valid_months", "controls", "with_emissions",
    "m5_complete_case", "e4_reporters"),
  n = c(uniqueN(survey$aid), uniqueN(answered_survey$aid), uniqueN(spending$aid),
    uniqueN(control_data$aid), uniqueN(lm_data$aid), uniqueN(analysis_data$aid),
    uniqueN(device_time$aid)),
  n_rows = c(nrow(survey), nrow(answered_survey), nrow(spending),
    nrow(control_data), nrow(lm_data), nrow(analysis_data), nrow(device_time)))
fwrite(flow, file.path(out_dir, "sample_flow.csv"))

stagelab = c(survey = "Survey respondents",
  battery_gate = "Battery gate (>= 8 of 11 index items)",
  valid_months = "Valid spending months", controls = "Controls joined",
  with_emissions = "With emissions data", m5_complete_case = "M5 complete-case sample",
  e4_reporters = "E4 screen-time reporters")
png(file.path(out_dir, "sample_flow.png"), width = 900, height = 500, res = 120)
par(mar = c(5, 13, 4, 2))
barplot(rev(flow$n), names.arg = rev(stagelab[flow$stage]), horiz = TRUE, las = 1,
  col = "steelblue", xlab = "N", main = "Sample flow")
dev.off()

# Index reliability: Cronbach's alpha per scale (main index + halves), on
# the battery-gate sample, complete cases within each scale's items (the
# gate tolerates missing items, alpha does not).
alpha_row = function(items, scale) {
  x = answered_survey[, ..items]
  x = x[complete.cases(x)]
  k = length(items)
  tot = var(rowSums(x))
  data.table(scale = scale, k = k, n = nrow(x),
    alpha = k / (k - 1) * (1 - sum(sapply(x, var)) / tot))
}
index_alpha = rbind(
  alpha_row(index_main_items, "Main index (11 items)"),
  alpha_row(index_device_items, "Device-use half (5 items)"),
  alpha_row(index_activity_items, "Digital-activity half (6 items)"))
fwrite(index_alpha, file.path(out_dir, "index_alpha.csv"))

# Item-rest correlations for the main index's items (same sample as alpha)
x = answered_survey[, ..index_main_items]
x = x[complete.cases(x)]
ir = sapply(index_main_items, function(cn)
  cor(x[[cn]], rowSums(x[, setdiff(index_main_items, cn), with = F])))
fwrite(data.table(item = index_main_items, sd = sapply(x, sd), item_rest_r = ir),
  file.path(out_dir, "index_alpha_items.csv"))

# Attrition: E4 reporters vs non-reporters in the analysis sample
rep = unique(device_time$aid)
a = control_data[, .(aid, education, major_city)][
  demographics_unique[, .(aid, age, gender)], on = "aid", nomatch = 0]
a[, reporter := aid %in% rep]
attr = a[, .(n = .N, mean_age = mean(age), share_female = mean(gender == "Kvinna"),
  share_city = mean(major_city),
  share_tertiary = mean(education %in% c("Eftergymnasial >=2 år", "Forskare"))), by = reporter]
fwrite(attr, file.path(out_dir, "attrition.csv"))

# Opt-out reasons among contacted non-reporters (latest endline response per aid)
opt = endline_latest[!(aid %in% rep),
  .(n = .N, not_activated = sum(q21_3, na.rm = TRUE), skip = sum(q21_4, na.rm = TRUE))]
fwrite(opt, file.path(out_dir, "optout.csv"))
