library(data.table)

control_data <- (keep
            [scb, on = "aid", nomatch = 0]
            [, density := log(density) - mean(log(density), na.rm = T)]
            [, education := factor(fcase(
              Sun2020Niva < 300, "Grundskola",
              Sun2020Niva < 400, "Gymnasium",
              Sun2020Niva < 500, "Eftergymnasial <2 år",
              Sun2020Niva < 600, "Eftergymnasial >=2 år",
              Sun2020Niva >= 600, "Forskare"
            ))]
            [demographics, on = "aid", nomatch = 0]
            [, age := age - mean(age, na.rm = T)]
            [, major_city := fifelse(postort %in% c("Stockholm", "Göteborg", "Malmö"), T, F)]
            [unique(users[,.(aid, `income-level`, profile.field_profile_household_adults, profile.field_profile_household_children)]), on = "aid", nomatch = 0]
            [person_bank, on = "aid"]
            [, hh_size := profile.field_profile_household_adults + profile.field_profile_household_children]
            [, children := factor(profile.field_profile_household_children > 0)]
            [, income := log1p(`income-level`) - mean(log1p(`income-level`), na.rm = T)]
            [, income_q := cut(`income-level`,
              quantile(`income-level`, probs = seq(0, 1, 0.2), na.rm = T),
              labels = paste0("Q", 1:5), include.lowest = T)]
            [, income_scb := log1p(pmax(DispInk04, 0)) - mean(log1p(pmax(DispInk04, 0)), na.rm = T)]
            [, income_bank := log1p(income_bank_raw) - mean(log1p(income_bank_raw), na.rm = T)]
            [answered_survey, on = "aid", nomatch = 0]
            [, (q11_cols) := lapply(.SD, function(x) 
              as.vector(scale(x))), .SDcols = q11_cols]
            [, index := rowMeans(.SD), .SDcols = q11_cols]
            [, hours_est := dt_coefs[1] + dt_coefs[2] * index]
            [, .(aid, age, gender, income, income_q, income_scb, income_bank, density, hours_est, index, hh_size, children, education, major_city)]) |>
  unique()

lm_data <- control_data[emissions, on = "aid", nomatch = 0]

# index kept only for SD scaling, income_q only for robustness (49);
# neither in headline formula (collinear with hours_est / income)
lm_formula <- paste("co2e", paste(setdiff(names(control_data)[names(control_data) != "aid"], c("index", "income_q")), collapse = "+"), sep = "~")
digital_lifestyle_model <- lm(lm_formula, lm_data)
