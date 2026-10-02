library(data.table)

# Use the latest pre-treatment response when an aid occurs more than once.
survey_latest <- survey[order(aid, submitdate), .SD[.N], by = aid]

# Device-use battery: q11_1-q11_5 (devices) + q11b_1-q11b_8 (digital activities).
# Shared by 30 (index + anchor), 40 (analysis data) and 54 (item analyses).
q11_cols <- grep("^q11(b_[1-8]|_[1-5])$", names(survey_latest), value = TRUE)

# Has answered q11.
answered_survey <- survey_latest[complete.cases(survey_latest[, ..q11_cols])]

# min valid months from the X months before the survey
min_months <- 3
x_months <- 12

# Minimum spending for valid month
min_spend <- 3000

## Excluded categories when calculating valid months with spending
excluded_kr <- c("da_credit_kr", "savings_kr", "transaction_kr", "exclude_kr")

spending <- (monthly_kr[category %notin% excluded_kr]
             [, .(kr = sum(kr, na.rm = T)), by = .(aid, month)]
             [kr > min_spend]
             [aid %in% answered_survey$aid]
             [survey_latest, on = "aid", nomatch = 0]
             [, submitdate := as.Date(submitdate)]
             [submitdate - 31 * x_months < month & month < submitdate]
             [, n := .N, by = aid]
             [n >= min_months])

# Demographics contains duplicate rows for some aids (flagged aid_dup in the
# real data, sequenced by `order`). Keep the first record per aid so every
# join downstream is one row per person. 30/40/45 use this table.
demographics_unique <- demographics[order(aid, order), .SD[1], by = aid]

keep <- unique(spending[, .(aid, month)])

# Person x category annual outcome. This is the canonical recipe: every
# outcome construction downstream (43/47/50/52/54/55) calls it, so the
# headline total and the category-level estimates share the exact same
# sample rule (>= min_months per category), annualization and P99 winsor.
annualise <- function(monthly, val) {
  (monthly[keep, on = .(aid, month), nomatch = 0]
   [, .(s = sum(get(val)), n_months = uniqueN(month)), by = .(aid, category)]
   [n_months >= min_months]
   [, y := (s / n_months) * 12]
   [, .(q99 = quantile(y, .99, na.rm = TRUE), y = y, aid = aid), by = category]
   [, y := pmin(y, q99)]
   [, .(aid, category, y)])
}

# Headline outcome: total annual CO2e (sum of winsorized categories)
emissions <- annualise(monthly_co2e, "co2e")[, .(co2e = sum(y, na.rm = TRUE)), by = aid]

# Category groups (leaf names from metadata.md), shared by the decomposition
# scripts so the grouping cannot drift between them.
transport_co2e <- c("fuel_co2e", "car_maint_co2e", "car_rent_co2e", "public_trans_co2e",
  "bus_co2e", "taxi_co2e", "train_bus_co2e", "aviation_co2e", "ferry_co2e",
  "escooter_co2e", "transport_other_co2e")
ecom_co2e <- c("clothing_co2e", "electronics_co2e", "books_co2e", "toys_co2e",
  "sports_co2e", "shopping_other_co2e", "home_garden_other_co2e")
digital_co2e <- "internet_tele_co2e"
# Rent is excluded from the CO2e outcomes: rent_co2e is zero by construction
# (no emissions factor for housing payments). In the SEK decomposition (47)
# rent is a housing-tenure outcome, not a placebo: the SEK rent gradient
# reflects renting vs owning, not a digital consumption channel. The CO2e
# placebo is insurance ("insurance_co2e" in 43/52).
placebo_co2e <- "insurance_co2e"
vehicles_co2e <- "vehicles_co2e"

# Short- vs long-distance split of the transport composite (63): daily
# ground mobility vs intercity/international travel. car_rent and
# transport_other are ambiguous (vacation vs replacement rental; unknown
# mix) and stay separate. The three buckets exhaust transport_co2e.
short_co2e <- c("fuel_co2e", "car_maint_co2e", "public_trans_co2e", "bus_co2e",
  "taxi_co2e", "train_bus_co2e", "escooter_co2e")
long_co2e <- c("aviation_co2e", "ferry_co2e")
ambiguous_co2e <- c("car_rent_co2e", "transport_other_co2e")

transport_kr <- sub("_co2e$", "_kr", transport_co2e)
ecom_kr <- sub("_co2e$", "_kr", ecom_co2e)
digital_kr <- "internet_tele_kr"
vehicles_kr <- "vehicles_kr"
