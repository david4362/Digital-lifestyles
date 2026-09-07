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
  q21_1comment = fifelse(status == "reporter", h, NA_integer_),
  q21_2comment = fifelse(status == "reporter", mnt, NA_integer_),
  q21_3 = as.integer(status == "not_activated"),
  q21_4 = as.integer(status == "skip"))
survey_endline = survey_endline[status != "nocontact"][, status := NULL][]

demographics = data.table(aid = aid, age = age, gender = gender, postort = postort)
scb = data.table(aid = aid, density = rlnorm(n, 7),
  Sun2020Niva = sample(c(100, 200, 310, 410, 520, 620), n, replace = TRUE))
income_level = round(exp(rnorm(n, 12.6, 0.5)))
users = data.table(aid = aid, `income-level` = income_level,
  profile.field_profile_household_adults = sample(1:2, n, replace = TRUE),
  profile.field_profile_household_children = sample(0:3, n, replace = TRUE, prob = c(0.5, 0.25, 0.15, 0.1)))

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

# Low-spend subgroup (5%) fails the spending filter, exercises keep
low = sample(aid, 40)
monthly_co2e[aid %in% low, co2e := co2e * 0.1]
monthly_kr[aid %in% low, kr := kr * 0.1]

rm(grid, q, base, grad, inc_eff, major, p, status, h, mnt, ov, low, time, z, income_level, age, gender, postort, months, n, aid, q11_names)
