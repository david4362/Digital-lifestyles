library(arrow)

## The shared raw-read core (paths, renames, register join, aviation
## override) lives in load_common_data.R — a synced identical copy in every
## project repo; the canonical master is <workspace>/scripts/load_common_data.R.
## This file adds only THIS project's views (monthly aggregates, the endline
## survey, person-level bank income) and its parquet cache.
source("load_common_data.R")

cache_dir = file.path("/safe", "data", "studie_konsumtion_och_attityder", "chalmers", "digital_lifestyles", "cache")

## Monthly aggregates from the harmonized long core built once in
## load_common_data.R (full melt, one row per aid x date x category).
## Category names keep the _kr/_co2e suffix the downstream scripts filter on.
monthly_kr = transactions_long[,
  .(kr = sum(kr, na.rm = TRUE)),
  by = .(aid, month, category = paste0(category, "_kr"))]
monthly_co2e = transactions_long[category != "da_credit",
  .(co2e = sum(co2e, na.rm = TRUE)),
  by = .(aid, month, category = paste0(category, "_co2e"))]

## The transactions cache carries the canonical aviation emission-intensity
## override from load_common_data.R; run_info.csv records aviation_override.
write_parquet(monthly_kr, file.path(cache_dir, "monthly_kr.parquet"))
write_parquet(monthly_co2e, file.path(cache_dir, "monthly_co2e.parquet"))
write_parquet(transactions, file.path(cache_dir, "transactions.parquet"))
write_parquet(transactions_long, file.path(cache_dir, "transactions_long.parquet"))
write_parquet(users, file.path(cache_dir, "users.parquet"))
write_parquet(survey, file.path(cache_dir, "survey.parquet"))
write_parquet(demographics, file.path(cache_dir, "demographics.parquet"))
write_parquet(scb, file.path(cache_dir, "scb.parquet"))

## Endline survey (this project's input; the other pipelines do not use it).
survey_endline = read_excel(file.path(data_dir, "survey_endline", "1648_data_250115.xlsx"))
setDT(survey_endline)
names(survey_endline) = sub("ef_id", "aid", names(survey_endline))
write_parquet(survey_endline, file.path(cache_dir, "survey_endline.parquet"))

## Bank-registered income (raw incoming transactions -> general income
## level, no month-matching with expenses: mean monthly inflow per aid).
monthly_bank = daily_income[, .(income = sum(income, na.rm = TRUE)), by = .(aid, month)]
person_bank = monthly_bank[, .(income_bank_raw = mean(income, na.rm = TRUE), n_bank_months = .N), by = aid]
write_parquet(person_bank, file.path(cache_dir, "bank_income.parquet"))

rm(data_dir, scb_dir, monthly_bank)
# transactions/users/survey/demographics/scb/survey_endline/person_bank and
# the monthly aggregates stay in memory: when RUN_TRE.R builds the cache
# (incomplete at start), the analysis scripts run in this same session and
# consume them; the shared module's remaining objects (sampling_frame,
# linkage, daily_income) are unused here and harmless.
