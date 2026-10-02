# 00_load_data.R — Digital lifestyles paper
#
# Loads the Konsumtionskollen data (5.2 GB RData) ONCE and caches a light
# extract for this project. All later scripts source this file and get:
#
#   dsurvey        survey with digital candidate items + demographics joined
#   users_light    selected user/demographic columns
#   person_cat_co2e / person_cat_kr   person x category totals (whole window)
#   monthly_incomes
#
# Delete cache/digital_cache.RData to force a re-extract.

suppressMessages({ library(dplyr); library(tidyr) })
source("00_constants.R")

if (file.exists(CACHE_FILE)) {
  message("Loading cached extract: ", CACHE_FILE)
  load(CACHE_FILE)
} else {
  stopifnot(file.exists(KK_DATA_FILE))
  message("Loading full Konsumtionskollen RData (slow, ~5 GB): ", KK_DATA_FILE)
  kk <- new.env()
  load(KK_DATA_FILE, envir = kk)
  message("Objects: ", paste(ls(kk), collapse = ", "))

  # --- Users: keep a light demographic slice --------------------------------
  u <- kk$users
  keep_users <- intersect(
    c("aid", "age", "sex", "Sun2020Niva", "randomsample", "pop_density",
      "profile.kommun", "profile.hometype", "profile.ncars",
      "profile.field_profile_household_adults",
      "profile.field_profile_household_children",
      "profile.field_food_diet"),
    names(u))
  users_light <- u |> select(all_of(keep_users))

  # --- Survey: all candidate digital items + join demographics --------------
  s <- kk$survey
  keep_survey <- intersect(
    c("aid", "response_type", "startdate", "submitdate",
      DIGITAL_CANDIDATES, paste0("array6_", 1:13),
      "array3_8", "array3_9", "array3_11"),   # ESI items for later controls
    names(s))
  dsurvey <- s |> select(all_of(keep_survey)) |> left_join(users_light, by = "aid")

  # --- Person x category totals over the observation window -----------------
  # monthly_emissions / monthly_spending are long tables (aid, date, category, value).
  # Column names are detected defensively; verify the printed structure once.
  .aggregate_long <- function(df, value_name) {
    cat_col <- names(df)[vapply(df, is.character, TRUE) & names(df) != "aid"][1]
    num_cols <- names(df)[vapply(df, is.numeric, TRUE)]
    val_col <- num_cols[length(num_cols)]
    message(sprintf("  aggregating: category col = '%s', value col = '%s'", cat_col, val_col))
    df |>
      group_by(aid, category = .data[[cat_col]]) |>
      summarise("{value_name}" := sum(.data[[val_col]], na.rm = TRUE), .groups = "drop")
  }
  message("Aggregating monthly_emissions -> person_cat_co2e ...")
  person_cat_co2e <- .aggregate_long(kk$monthly_emissions, "co2e")
  message("Aggregating monthly_spending -> person_cat_kr ...")
  person_cat_kr <- .aggregate_long(kk$monthly_spending, "kr")

  monthly_incomes <- kk$monthly_incomes
  selected_aids   <- kk$selected_aids   # analytical sample from Konsumtionskollen filter

  rm(kk); invisible(gc())

  save(dsurvey, users_light, person_cat_co2e, person_cat_kr,
       monthly_incomes, selected_aids, file = CACHE_FILE)
  message("Cached extract written: ", CACHE_FILE)
}

message(sprintf("dsurvey: %d x %d | person_cat_co2e: %d rows | selected_aids: %d",
                nrow(dsurvey), ncol(dsurvey), nrow(person_cat_co2e), length(selected_aids)))
