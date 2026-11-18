# load_common_data.R — the shared raw-read core for the Konsumtionskollen
# (Svalna) study in the SCB TRE, used by all three analysis projects
# (Digital-lifestyles, low-carbon-lifestyles, tax-return-spending).
#
# SYNCED IDENTICAL COPY: this file lives, byte-identical, in every project
# repo — Digital-lifestyles/R/, low-carbon-lifestyles/ and
# tax-return-spending/R/ — so each repo runs and publishes stand-alone.
# The canonical master is <workspace>/scripts/load_common_data.R; when it
# changes, copy it verbatim into all three projects (the same rule as the
# .lintr copies and the synced generate_mock_data.R). Never edit one
# project's copy alone. When syncing scripts into the TRE, copy this file
# alongside them — each project's 10_load_data.R sources it by relative
# name.
#
# It reads the fixed raw TRE files once, canonically: the paths, the column
# renames, the raw tables, the register join and the aviation
# emission-intensity override are defined HERE and nowhere else. Each
# project's 10_load_data.R sources this file and adds only its own view
# construction (dedup rules, monthly aggregates, column subsets) and its
# own parquet cache under chalmers/<project>/. Projects may ignore objects
# they do not consume; only the transactions dta is heavy.
#
# Objects left in memory (category columns use the underscore convention,
# e.g. aviation_kr / aviation_co2e):
#   data_dir, scb_dir   the TRE path constants (the tax project's IoT read
#                       and the endline loader use them)
#   transactions        one row per aid x date, wide per-category columns
#                       (kr_pr2/co2e_pr2 renamed to _kr/_co2e). Each cell is
#                       that day's aggregate for the category: sub-day
#                       transactions are summed before delivery for privacy,
#                       so several columns are typically populated on a row.
#                       With the aviation emission-intensity override applied.
#                       Kept as the raw-shaped view for the two wide-only
#                       consumers (low-carbon's daily-cell P99 winsor, tax's
#                       event-window column math).
#   transactions_long   THE HARMONIZED CORE: one full melt
#                       of the wide table, one row per aid x date x category
#                       (stem) with that day's kr and co2e, plus `month`.
#                       All cells are kept (zeros included) so monthly sums
#                       and daily-cell quantiles match the wide table exactly.
#                       All three projects consume this directly.
#   users               ALL app profile snapshots (`:` renamed to `.`; the
#                       latest-per-aid view is built project-side)
#   survey              ALL pre-treatment survey responses (ef_id renamed
#                       to aid; the latest-per-aid view is built
#                       project-side)
#   demographics        frame records including the duplicate rows some
#                       aids have (efid renamed to aid, gender normalized
#                       to Kvinna/Man)
#   sampling_frame      the FIRST demographics record per aid (the
#                       canonical frame record; randomsample/greensample
#                       live here)
#   linkage             SCB LopNr <-> aid (kept because the tax project
#                       joins it onto the IoT register)
#   scb                 register join, one row per linked participant: DeSO
#                       and density, LISA 2024 (full read: education,
#                       family, labor, mobility) + LISA 2023 (selected:
#                       DispInk04 disposable income in 100-SEK units and
#                       the income/labor columns); register rows for people
#                       outside the study linkage (aid = NA) are dropped
#   daily_income        incoming bank income, ONE ROW PER AID x DATE x
#                       CATEGORY; `income` is that category-day total in SEK
#                       (date coerced to Date). The monthly and person-level
#                       income views are built project-side
#
# Project-specific inputs stay in the projects' own loaders: the endline
# survey (Digital-lifestyles) and the IoT tax register
# (tax-return-spending).

library(data.table)
library(haven)
library(readxl)

## TRE paths, defined once for every project.
data_dir = file.path("/safe", "data", "studie_konsumtion_och_attityder", "data_raw")
scb_dir = file.path(data_dir, "register_data", "scb", "Forskningsstudie om konsumtion och attityder")

## Transactions: ONE ROW PER AID x DATE. Sub-day transactions are summed to
## daily category aggregates before the data reach us (privacy), so each wide
## per-category _kr/_co2e cell is that day's total for the category and a
## typical row carries several populated columns. The dta suffixes
## (kr_pr2/co2e_pr2) rename to the underscore convention every project shares.
transactions = read_dta(file.path(data_dir, "konsumtionskollen", "full_data_norecats_filters_260121.dta"))
setDT(transactions)
names(transactions) = gsub("kr_pr2$", "_kr", names(transactions))
names(transactions) = gsub("co2e_pr2$", "_co2e", names(transactions))

## Aviation emission intensity: 0.08 kg CO2/pkm combustion, a non-CO2
## uplift of 1.5, 20% upstream emissions, and an average ticket price of
## 0.82 SEK/pkm => ~0.166 kg CO2e per SEK. Overwrites the dta's own
## aviation co2e so every project's aviation numbers share one factor
## (see data/common-data.md §6).
aviation_co2e_per_sek = (0.08 * 1.5 + 0.08 * 0.20) / 0.82
transactions[, aviation_co2e := aviation_kr * aviation_co2e_per_sek]

## Harmonized long core: ONE full melt, built here rather than in each
## project. `month` is attached to the wide table first (CODING-GUIDELINES
## §4: formatting dates after a melt multiplies the work by the number of
## category columns). The two melts are joined by (aid, date, month, category);
## da_credit has no co2e mirror, so its co2e is NA (consumers use na.rm = TRUE).
## All cells are kept so the long core is a lossless representation.
transactions[, date := as.Date(date)]
transactions[, month := trunc.Date(date, "months")]
kr_cols = grep("_kr$", names(transactions), value = TRUE)
co2e_cols = grep("_co2e$", names(transactions), value = TRUE)
kr_long = melt(transactions[, c("aid", "date", "month", kr_cols), with = FALSE],
  id.vars = c("aid", "date", "month"), measure.vars = kr_cols,
  variable.name = "category", value.name = "kr", variable.factor = FALSE)
co2e_long = melt(transactions[, c("aid", "date", "month", co2e_cols), with = FALSE],
  id.vars = c("aid", "date", "month"), measure.vars = co2e_cols,
  variable.name = "category", value.name = "co2e", variable.factor = FALSE)
kr_long[, category := sub("_kr$", "", category)]
co2e_long[, category := sub("_co2e$", "", category)]
transactions_long = merge(kr_long, co2e_long,
  by = c("aid", "date", "month", "category"), all = TRUE)
setcolorder(transactions_long, c("aid", "date", "month", "category", "kr", "co2e"))
setorder(transactions_long, aid, date, category)
rm(kr_cols, co2e_cols, kr_long, co2e_long)

## App users: per-aid dynamic snapshots (the users export is keyed by
## date). ALL snapshots are kept here; any join downstream picks the
## latest per aid. `:` in names renames to `.`, and the export's
## per-category lifetime totals get the shared _kr/_co2e suffix
## convention.
users = fread(file.path(data_dir, "konsumtionskollen", "kk-handels-data-dynamic-2024-09-16.csv"))
names(users) = gsub(":", ".", names(users))
names(users) = gsub("kr$", "_kr", names(users))
names(users) = gsub("co2e$", "_co2e", names(users))

## Pre-treatment survey: ALL responses (the latest-per-aid and
## invitation-date views are built project-side).
survey = read_excel(file.path(data_dir, "survey_pre_treatment", "1648_Svalna_Data.xlsx"))
setDT(survey)
names(survey) = sub("ef_id", "aid", names(survey))

## Demographics: covers the whole invitation frame, including people
## without app or bank records; some aids have duplicate rows (flagged
## aid_dup, sequenced by `order` in the real data, with conflicting values
## possible). The FIRST record per aid is the canonical frame record.
demographics = read_dta(file.path(data_dir, "misc", "efid_demographics.dta"))
setDT(demographics)
names(demographics) = sub("efid", "aid", names(demographics))
demographics[, gender := fcase(
  gender == "Kvinna", "Kvinna",
  gender == "K", "Kvinna",
  gender == "Man", "Man",
  gender == "M", "Man"
)]
sampling_frame = demographics[order(aid, order), .SD[1], by = aid]

## SCB registers: the LopNr <-> aid linkage, the DeSO of the selection,
## DeSO population density, and LISA (2024 full read; 2023 selected income
## columns — DispInk04 is in 100-SEK units, the known unit trap). The
## register joins keep every register row, so records for people outside
## the study linkage get aid = NA; drop them so the table is participants
## only (downstream joins are on aid, so this changes nothing analytically).
linkage = fread(file.path(scb_dir, "JE_Lev_KopplingLopNr.txt"))
names(linkage) = c("LopNr", "aid")
deso = fread(file.path(scb_dir, "JE_Lev_Valdelt_EU_2024.txt"))[, .(LopNr, DeSO)]
names(deso)[2] = "deso"
deso_density = fread(file.path(scb_dir, "deso_2018_density.csv"))
edu_level = fread(file.path(scb_dir, "JE_Lev_LISA_2024.txt"))
inc_2023 = fread(file.path(scb_dir, "JE_Lev_LISA_2023.txt"), select = c("LopNr", "DispInk04",
  "HuvInkKallaAlt", "StudDelt", "StudDeltTyp", "BostBidrFam", "ArbSokNov", "ArbLos", "ALosDag"))
scb = linkage[deso, on = "LopNr"][deso_density, on = "deso"][edu_level, on = "LopNr"][inc_2023, on = "LopNr"]
scb = scb[!is.na(aid)]

## Daily bank income: ONE ROW PER AID x DATE x CATEGORY; `income` is that
## day's total for the category in SEK (sub-day transactions summed before
## delivery). Records for aids outside the study linkage exist in the export
## and are kept here; consumers drop or ignore them as their joins
## require.
daily_income = fread(file.path(data_dir, "konsumtionskollen", "handels-export-2025-01-13",
  "handels-export-2025-01-13", "kk-handels-income-data-2025-01-10.csv"))
daily_income[, date := as.Date(date)]

rm(deso, deso_density, edu_level, inc_2023)
