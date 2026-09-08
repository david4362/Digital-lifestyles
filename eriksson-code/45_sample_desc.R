library(data.table)

out_dir = file.path(dirname(cache_dir), "output")
dir.create(out_dir, showWarnings = FALSE)

# Sample flow: N at each filter stage
flow = data.table(
  stage = c("survey", "complete_q11", "valid_months", "analysis", "with_emissions", "e4_reporters"),
  n = c(uniqueN(survey$aid), uniqueN(answered_survey$aid), uniqueN(spending$aid),
    uniqueN(control_data$aid), uniqueN(lm_data$aid), uniqueN(device_time$aid)))
fwrite(flow, file.path(out_dir, "sample_flow.csv"))

stagelab <- c(survey = "Survey respondents", complete_q11 = "Complete device battery (q11)",
  valid_months = "Valid spending months", analysis = "Analysis sample",
  with_emissions = "With emissions data", e4_reporters = "E4 screen-time reporters")
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
a = demographics[unique(control_data[, .(aid)]), on = "aid", nomatch = 0]
a = control_data[, .(aid, education, major_city)][a, on = "aid"]
a[, reporter := aid %in% rep]
attr = a[, .(n = .N, mean_age = mean(age), share_female = mean(gender == "Kvinna"),
  share_city = mean(major_city),
  share_tertiary = mean(education %in% c("Eftergymnasial >=2 år", "Forskare"))), by = reporter]
fwrite(attr, file.path(out_dir, "attrition.csv"))

# Opt-out reasons among contacted non-reporters
opt = survey_endline[!(aid %in% rep),
  .(n = .N, not_activated = sum(q21_3, na.rm = T), skip = sum(q21_4, na.rm = T))]
fwrite(opt, file.path(out_dir, "optout.csv"))
