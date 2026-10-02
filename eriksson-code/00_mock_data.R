library(data.table)

# Mock data for pipeline test. Planted gradients (kg/yr per h/day):
# transport negative, ecom/digital positive, placebos zero.
set.seed(42)
n = 800
aid = 1:n
age = sample(18:80, n, replace = TRUE)
gender = sample(c("Man", "Kvinna"), n, replace = TRUE, prob = c(0.49, 0.51))
postort = sample(c("Stockholm", "Göteborg", "Malmö", "Uppsala", "Umeå", "Växjö"),
  n, replace = TRUE, prob = c(0.2, 0.1, 0.1, 0.2, 0.2, 0.2))
major = postort %in% c("Stockholm", "Göteborg", "Malmö")

z = -0.03 * (age - 40) + 0.5 * major + rnorm(n)
z = as.vector(scale(z))

# q11 battery (1-6) correlated with z
q11_names = c(paste0("q11_", 1:5), paste0("q11b_", 1:8))
q = lapply(q11_names, function(nm) pmin(6, pmax(1, round(3.5 + 0.8 * z + rnorm(n)))))
names(q) = q11_names
survey = data.table(aid = aid, submitdate = "2024-06-15")
survey[, (q11_names) := q]

# Partial battery: 20 people answer 12 of 13 items. The pipeline rule
# (complete battery) excludes them; the preregistration rule (>= 10 of 13,
# exercised by the index-variant robustness in 59) includes them.
survey[sample(aid, 20), (q11_names[1]) := NA]

# E4 screen time from z (b ~ 1.2 h per index unit), with opt-out reasons
time = 2.5 + 1.2 * z - 0.02 * (age - 45) + 0.15 * (gender == "Kvinna") + rnorm(n, sd = 0.7)
time = pmin(15, pmax(0.2, time))
h = floor(time)
mnt = round((time %% 1) * 60)
ov = mnt == 60
h[ov] = h[ov] + 1
mnt[ov] = 0
p = runif(n)
status = fcase(p < 0.72, "reporter", p < 0.82, "not_activated", p < 0.88, "skip", default = "nocontact")
survey_endline = data.table(aid = aid, status = status,
  submitdate = as.Date("2024-06-20"),
  q21_1comment = fifelse(status == "reporter", h, NA_integer_),
  q21_2comment = fifelse(status == "reporter", mnt, NA_integer_),
  q21_3 = as.integer(status == "not_activated"),
  q21_4 = as.integer(status == "skip"),
  F88_2 = sample(1:7, n, replace = TRUE),
  F88_3 = sample(1:7, n, replace = TRUE),
  F88_10 = sample(1:7, n, replace = TRUE),
  F88_19 = sample(1:7, n, replace = TRUE))
survey_endline = survey_endline[status != "nocontact"][, status := NULL][]

demographics = data.table(aid = aid, order = 1L, age = age, gender = gender, postort = postort)
# Duplicate demographics rows for a few aids (as flagged by aid_dup in the
# real data), with a conflicting value on the second record.
dup_aid = sample(aid, 20)
demographics = rbind(demographics,
  data.table(aid = dup_aid, order = 2L, age = age[match(dup_aid, aid)] + 1L,
    gender = gender[match(dup_aid, aid)], postort = postort[match(dup_aid, aid)]))
# Income mildly correlated with digital intensity (confounding like real data)
income_level = round(exp(rnorm(n, 12.6 + 0.15 * z, 0.5)))
scb = data.table(aid = aid, density = rlnorm(n, 7),
  deso = paste0("d", sample(1:100, n, replace = TRUE)),
  Sun2020Niva = sample(c(100, 200, 310, 410, 520, 620), n, replace = TRUE),
  DispInk04 = round(income_level * exp(rnorm(n, 0, 0.2))),
  FoDelt = as.integer(runif(n) < 0.06),
  HSDelt = as.integer(runif(n) < 0.10 + 0.25 * (age < 30)),
  StudDelt = as.integer(runif(n) < 0.08 + 0.20 * (age < 30)),
  BostBidrFam = rbinom(n, 1, 0.10) * round(rlnorm(n, 10, 0.5)),
  ArbSokNov = rbinom(n, 1, 0.05),
  Civil = sample(c("Single", "Married", "Divorced"), n, replace = TRUE),
  FamTypF = sample(c("Single", "Cohab_no_kids", "Cohab_kids", "Single_parent"), n, replace = TRUE))
# Mock labels for Civil/FamTypF/hometype are arbitrary — the real register
# and profile codes differ; 64 treats all three generically (shares by
# observed level, factor controls), so the mock only exercises the code.
users = data.table(aid = aid, date = as.Date("2024-06-15"),
  `income-level` = income_level,
  `nr-of-bank-accounts` = sample(1:4, n, replace = TRUE),
  profile.hometype = {u = runif(n); fifelse(u < 0.3 + 0.3 * major, "Lägenhet",
    fifelse(u < 0.8 + 0.05 * major, "Villa", "Radhus"))},
  profile.ncars = {v = runif(n); fifelse(v < 0.25 + 0.2 * major, 0L,
    fifelse(v < 0.70 + 0.2 * major, 1L, 2L))},
  profile.field_profile_household_adults = sample(1:2, n, replace = TRUE),
  profile.field_profile_household_children = sample(0:3, n, replace = TRUE, prob = c(0.5, 0.25, 0.15, 0.1)),
  profile.field_profile_commute_distance = {cd = round(rlnorm(n, 2.4 - 0.5 * major, 0.7), 1); cd[sample(n, 40)] = NA; cd},
  profile.field_profile_commute_public = as.integer(runif(n) < 0.25 + 0.25 * major),
  profile.field_profile_commute_bike = as.integer(runif(n) < 0.15),
  profile.field_profile_commute_car = as.integer(runif(n) < 0.55 - 0.25 * major))

# Annual CO2e per category: base + gradient*hours + income effect + noise
base = c(fuel_co2e = 600, car_maint_co2e = 150, public_trans_co2e = 100, taxi_co2e = 30,
  ferry_co2e = 40, aviation_co2e = 500, clothing_co2e = 150, electronics_co2e = 80,
  books_co2e = 20, toys_co2e = 15, sports_co2e = 20, shopping_other_co2e = 120,
  home_garden_other_co2e = 60, internet_tele_co2e = 30, rent_co2e = 700, insurance_co2e = 20,
  vehicles_co2e = 300, groceries_co2e = 800, restaurant_co2e = 200, electricity_co2e = 400,
  train_bus_co2e = 60, bus_co2e = 40, car_rent_co2e = 50, transport_other_co2e = 40, escooter_co2e = 5)
grad = c(fuel_co2e = -15, car_maint_co2e = -8, public_trans_co2e = -7, taxi_co2e = -2,
  ferry_co2e = 2, aviation_co2e = 10, clothing_co2e = 5, electronics_co2e = 4,
  books_co2e = 1, toys_co2e = 1, sports_co2e = 1, shopping_other_co2e = 3,
  home_garden_other_co2e = 1, internet_tele_co2e = 5, rent_co2e = 0, insurance_co2e = 0,
  vehicles_co2e = 0, groceries_co2e = -5, restaurant_co2e = -8, electricity_co2e = 0,
  train_bus_co2e = -3, bus_co2e = -2, car_rent_co2e = -1, transport_other_co2e = -1, escooter_co2e = 0)

months = seq(as.Date("2023-07-01"), by = "month", length.out = 12)
inc_eff = (log1p(income_level) - mean(log1p(income_level))) * 150
grid = CJ(aid = aid, month = months, category = names(base))
grid[, h := time[aid]]
grid[, y := base[category] + grad[category] * h + inc_eff[aid] * (category != "rent_co2e") * 0.3]
grid[, y := pmax(1, y + rnorm(.N, sd = 15))]
grid[, monthly := y / 12 * (1 + rnorm(.N, sd = 0.1))]
monthly_co2e = grid[, .(aid, month, category, co2e = pmax(0, monthly))]
monthly_kr = grid[, .(aid, month, category = sub("_co2e$", "_kr", category), kr = pmax(50, monthly * 15 + rnorm(.N, sd = 50)))]

# Bank-registered income (mirrors kk-handels-income CSV: aid, date, category, income)
bank_cat = c("salary", "benefits", "other")
kk_income = CJ(aid = aid, month = months, category = bank_cat)
kk_income[, income := income_level[aid]/12/length(bank_cat) * exp(rnorm(.N, 0, 0.3))]
monthly_bank = kk_income[, .(income = sum(income)), by = .(aid, month)]
person_bank = monthly_bank[, .(income_bank_raw = mean(income), n_bank_months = .N), by = aid]
# A few participants have no bank-income record, and the file contains
# records for aids outside the study, as in the real data.
person_bank = person_bank[!aid %in% sample(aid, 15)]
person_bank = rbind(person_bank, data.table(aid = max(aid) + 1:10,
  income_bank_raw = 20000, n_bank_months = 12))

# Low-spend subgroup (5%) fails the spending filter, exercises keep
low = sample(aid, 40)
monthly_co2e[aid %in% low, co2e := co2e * 0.1]
monthly_kr[aid %in% low, kr := kr * 0.1]

# Rent carries no CO2e factor in the real data (rent_co2e is all zeros), so
# zero it in the mock too.
monthly_co2e[category == "rent_co2e", co2e := 0]
# ~92% of real participants pay auto-categorized rent (rent_kr > 0); plant
# non-payers (no rent at all, n_rent = 0) so 62's stability filter has
# the two fault kinds to catch.
monthly_kr[category == "rent_kr" & aid %in% sample(aid, 64), kr := 0]
# Rent appearing only in some months (data fault per the stability rule in
# 62): 10 people with positive rent in only the first half of the year —
# an interior miss, still a fault under the relaxed rule.
monthly_kr[category == "rent_kr" & aid %in% sample(aid, 10) &
  month %in% months[7:12], kr := 0]
# The real-data window-edge pattern: rent missing only in the FIRST and
# LAST valid month (rent paid in advance straddles the window edges).
# These are stable renters under 62's interior rule.
monthly_kr[category == "rent_kr" & aid %in% sample(aid, 10) &
  month %in% months[c(1, 12)], kr := 0]

rm(grid, q, base, grad, inc_eff, major, p, status, h, mnt, ov, low, time, z, income_level, age, gender, postort, months, n, aid, q11_names, bank_cat, kk_income, monthly_bank, dup_aid, cd, u, v)
