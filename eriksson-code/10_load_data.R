library(data.table)
library(readxl)
library(arrow)
library(haven)

## Directories to load data from
data_dir = file.path("/safe", "data", "studie_konsumtion_och_attityder", "data_raw")
cache_dir = file.path("/safe", "data", "studie_konsumtion_och_attityder", "chalmers", "eriksson-code", "cache")
scb_dir = file.path(data_dir, 'register_data', 'scb', 'Forskningsstudie om konsumtion och attityder')

## Loading and summarising transactions
transactions <- read_dta(file.path(data_dir, "konsumtionskollen", "full_data_norecats_filters_260121.dta"))
setDT(transactions)
names(transactions) <- gsub("kr_pr2$", "_kr", names(transactions))
names(transactions) <- gsub("co2e_pr2$", "_co2e", names(transactions))

transactions[, month := trunc.Date(date, "months")]

kr_cols <- grep("_kr", names(transactions))
co2e_cols <- grep("_co2e", names(transactions))
monthly_kr <- melt(transactions,
                   id = c("aid", "month"),
                   measure.vars = kr_cols,
                   variable.name = "category",
                   variable.factor = F,
                   value.name = "kr")
monthly_kr <- monthly_kr[, .(kr = sum(kr, na.rm = T)), by = .(aid, month, category)]

monthly_co2e <- melt(transactions,
             id = c("aid", "month"),
             measure.vars = co2e_cols,
             variable.name = "category",
             variable.factor = F,
             value.name = "co2e")
monthly_co2e <- monthly_co2e[, .(co2e = sum(co2e, na.rm = T)), by = .(aid, month, category)]

write_parquet(monthly_kr, file.path(cache_dir, "monthly_kr.parquet"))
write_parquet(monthly_co2e, file.path(cache_dir, "monthly_co2e.parquet"))
write_parquet(transactions, file.path(cache_dir, "transactions.parquet"))

## Load user data
users <- fread(file.path(data_dir, "konsumtionskollen", "kk-handels-data-dynamic-2024-09-16.csv"))
names(users) <- gsub(":", ".", names(users))
names(users) <- gsub("kr$", "_kr", names(users))
names(users) <- gsub("co2e$", "_co2e", names(users))
write_parquet(users, file.path(cache_dir, "users.parquet"))

## Load survey data
survey <- read_excel(file.path(data_dir, "survey_pre_treatment", "1648_Svalna_Data.xlsx"))
setDT(survey)
names(survey) <- sub("ef_id", "aid", names(survey))
write_parquet(survey, file.path(cache_dir, "survey.parquet"))

## Load survey endline data
survey_endline <- read_excel(file.path(data_dir, "survey_endline", "1648_data_250115.xlsx"))
setDT(survey_endline)
names(survey_endline) <- sub("ef_id", "aid", names(survey_endline))
write_parquet(survey_endline, file.path(cache_dir, "survey_endline.parquet"))

## Load demographics data
demographics <- read_dta(file.path(data_dir, "misc", "efid_demographics.dta"))
setDT(demographics)
names(demographics) <- sub("efid", "aid", names(demographics))
demographics[, gender := fcase(
  gender == "Kvinna", "Kvinna",
  gender == "K", "Kvinna",
  gender == "Man", "Man",
  gender == "M", "Man"
)]
write_parquet(demographics, file.path(cache_dir, "demographics.parquet"))

## Load SCB data
scb <- fread(file.path(scb_dir, 'JE_Lev_KopplingLopNr.txt'))
names(scb) <- c("LopNr", "aid")
deso <- fread(file.path(scb_dir, "JE_Lev_Valdelt_EU_2024.txt"))[, .(LopNr, DeSO)]
names(deso)[2] <- "deso"
deso_density <- fread(file.path(scb_dir, "deso_2018_density.csv"))
edu_level <- fread(file.path(scb_dir, 'JE_Lev_LISA_2024.txt'))
scb <- scb[deso, on = "LopNr"][deso_density, on = "deso"][edu_level, on = "LopNr"]
write_parquet(scb, file.path(cache_dir, "scb.parquet"))

rm(data_dir, kr_cols, scb_dir, co2e_cols, deso, deso_density, edu_level)
