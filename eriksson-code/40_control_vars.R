library(data.table)

# Use the latest user record when an aid occurs more than once.
users_latest <- users[order(aid, date), .SD[.N], by = aid]

# Create a nice and clear df with all control data used from all the different sources. Looks horrible but is basically just a bunch of joins, cases and renaming.
control_data <- (keep
            # Join SCB data and categorize education level
            [scb, on = "aid", nomatch = 0]
            [, density := log(density) - mean(log(density), na.rm = T)]
            [, education := factor(fcase(
              Sun2020Niva < 300, "Grundskola",
              Sun2020Niva < 400, "Gymnasium",
              Sun2020Niva < 500, "Eftergymnasial <2 år",
              Sun2020Niva < 600, "Eftergymnasial >=2 år",
              Sun2020Niva >= 600, "Forskare"
            ))]
            
            # Join demographics data and get relevant variables.
            [demographics_unique, on = "aid", nomatch = 0]
            [, age := age - mean(age, na.rm = T)]
            [, major_city := fifelse(postort %in% c("Stockholm", "Göteborg", "Malmö"), T, F)]
            [users_latest[, .(aid, `income-level`, profile.field_profile_household_adults, profile.field_profile_household_children)], on = "aid", nomatch = 0]

            # Household size and children y/n
            [, hh_size := profile.field_profile_household_adults + profile.field_profile_household_children]
            [, children := factor(profile.field_profile_household_children > 0)]

            # Define income from different sources and quintiles
            [, income := log1p(`income-level`) - mean(log1p(`income-level`), na.rm = T)]
            [, income_q := cut(`income-level`,
              quantile(`income-level`, probs = seq(0, 1, 0.2), na.rm = T),
              labels = paste0("Q", 1:5), include.lowest = T)]
            [, income_scb := log1p(pmax(DispInk04, 0)) - mean(log1p(pmax(DispInk04, 0)), na.rm = T)]

            # Anchored digital measure: join the z-scaled items + index built
            # in 30 (single scaling, one row per aid) and convert to hours/day
            [device_use, on = "aid", nomatch = 0]
            [, hours_est := dt_coefs[["(Intercept)"]] + dt_coefs[["index"]] * index]

            # Keep only needed cols (deso for the fixed-effects robustness
            # in 56). The chain starts from keep (person x month rows), so
            # every person has one row per valid month with identical
            # per-person values; the unique() below collapses them back to
            # one row per person.
            [, c("aid", "age", "gender", "income", "income_q", "income_scb", "density", "hours_est", "index", "hh_size", "children", "education", "major_city", "deso", q11_cols), with = F]) |>
  unique()

# Join KK bank income, keeping every participant. In a data.table join
# X[i, on = "aid"] the rows of i (the right-hand side) are the ones kept, so
# the participants go on the right: people without a bank-income record keep
# their row with income_bank NA and drop out of the complete-case sample
# diagnosed below (visible in model_missingness) instead of being dropped
# silently by the join.
control_data <- person_bank[, .(aid, income_bank_raw)][control_data, on = "aid"]
control_data[, income_bank := log1p(income_bank_raw) - mean(log1p(income_bank_raw), na.rm = T)]
control_data[, income_bank_raw := NULL]

# index kept for the per-SD conversion, income_q only for the quintile
# stratification in 50, deso only for the fixed effects in 56; none in the
# headline formula (collinear with hours_est / income)
lm_formula <- paste("co2e", paste(setdiff(names(control_data)[names(control_data) != "aid"], c("index", "income_q", "deso", q11_cols)), collapse = "+"), sep = "~")
model_vars <- all.vars(as.formula(lm_formula))

lm_data <- control_data[emissions, on = "aid", nomatch = 0]
out_dir <- file.path(dirname(cache_dir), "output")
dir.create(out_dir, showWarnings = FALSE)

# Diagnose the complete-case loss explicitly, then freeze the M5 sample. This
# makes the M0-M5 ladder change controls rather than changing participants.
missingness <- rbindlist(lapply(model_vars, function(v) {
  x <- lm_data[[v]]
  data.table(variable = v, n_missing = sum(is.na(x)))
}))
fwrite(missingness, file.path(out_dir, "model_missingness.csv"))

analysis_data <- lm_data[complete.cases(lm_data[, ..model_vars])]
digital_lifestyle_model <- lm(lm_formula, data = analysis_data)

# Hours per SD of the index in the analysis sample. Single definition: the
# per-SD conversions in 42/43/47/48/50 all use this number.
h_per_sd <- dt_coefs[["index"]] * sd(analysis_data$index)
