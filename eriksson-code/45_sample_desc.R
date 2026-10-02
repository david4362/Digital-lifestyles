library(data.table)

out_dir = file.path(dirname(cache_dir), "output")
dir.create(out_dir, showWarnings = FALSE)

# Sample flow: report participant IDs and physical rows separately. The
# regression sample is the fixed M5 complete-case sample from 40, not merely
# the set of IDs with emissions data.
flow = data.table(
  stage = c("survey", "complete_q11", "valid_months", "controls", "with_emissions",
    "m5_complete_case", "e4_reporters"),
  n = c(uniqueN(survey$aid), uniqueN(answered_survey$aid), uniqueN(spending$aid),
    uniqueN(control_data$aid), uniqueN(lm_data$aid), uniqueN(analysis_data$aid),
    uniqueN(device_time$aid)),
  n_rows = c(nrow(survey), nrow(answered_survey), nrow(spending),
    nrow(control_data), nrow(lm_data), nrow(analysis_data), nrow(device_time)))
fwrite(flow, file.path(out_dir, "sample_flow.csv"))

stagelab <- c(survey = "Survey respondents", complete_q11 = "Complete device battery (q11)",
  valid_months = "Valid spending months", controls = "Controls joined",
  with_emissions = "With emissions data", m5_complete_case = "M5 complete-case sample",
  e4_reporters = "E4 screen-time reporters")
png(file.path(out_dir, "sample_flow.png"), width = 900, height = 500, res = 120)
par(mar = c(5, 13, 4, 2))
barplot(rev(flow$n), names.arg = rev(stagelab[flow$stage]), horiz = TRUE, las = 1,
  col = "steelblue", xlab = "N", main = "Sample flow")
dev.off()

# Index reliability: Cronbach's alpha + item-rest correlations (vanilla R)
items = answered_survey[, ..q11_cols]
k = length(q11_cols)
tot = var(rowSums(items))
alpha = k / (k - 1) * (1 - sum(sapply(items, var)) / tot)
ir = sapply(q11_cols, function(cn) cor(items[[cn]], rowSums(items[, setdiff(q11_cols, cn), with = F])))
fwrite(data.table(k = k, n = nrow(items), alpha = alpha), file.path(out_dir, "index_alpha.csv"))
fwrite(data.table(item = q11_cols, sd = sapply(items, sd), item_rest_r = ir),
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
  .(n = .N, not_activated = sum(q21_3, na.rm = T), skip = sum(q21_4, na.rm = T))]
fwrite(opt, file.path(out_dir, "optout.csv"))
