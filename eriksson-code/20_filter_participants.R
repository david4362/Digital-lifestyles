library(data.table)

# Use the latest pre-treatment response when an aid occurs more than once.
survey_latest = survey[order(aid, submitdate), .SD[.N], by = aid]

# Device-use battery: q11_1-q11_5 (devices) + q11b_1-q11b_8 (digital
# activities). All 13 items are carried through the pipeline: the index
# item sets below pick which ones build the exposure, 54 tests each item
# separately, and 59's 13-item variant shows what the two e-commerce items
# add back.
q11_cols = grep("^q11(b_[1-8]|_[1-5])$", names(survey_latest), value = TRUE)

# Index item sets (single source of truth for 40/42/45/59/61/65). The main
# index is the pre-registered construction WITHOUT the two e-commerce items
# (q11b_7 e-commerce, q11b_8 online selling): they measure the purchase
# channel itself, so keeping them in the exposure while the outcomes are
# transaction-observed consumption would build part of the outcome into the
# exposure. Calls (q11b_2) stay in the main index and are dropped in a
# second ladder variant (42) and in the variants table (59).
index_main_items = setdiff(q11_cols, c("q11b_7", "q11b_8"))
index_nocalls_items = setdiff(index_main_items, "q11b_2")
index_device_items = index_main_items[startsWith(index_main_items, "q11_")]
index_activity_items = index_main_items[startsWith(index_main_items, "q11b")]

# Battery tolerance from the pre-registration: at least 10 of 13 items
# answered, i.e. at most 3 missing. The same tolerance of 3 missing items is
# kept when the item set shrinks: at least 8 of 11 for the main index, at
# least 7 of 10 without calls.
battery_tol = 3
battery_min_main = length(index_main_items) - battery_tol
battery_min_nocalls = length(index_nocalls_items) - battery_tol

# Battery gate: answered at least battery_min_main of the main index items.
# Replaces the earlier complete-13-item rule (the pre-registration allows up
# to 3 missing).
n_answered_main = rowSums(!is.na(survey_latest[, ..index_main_items]))
answered_survey = survey_latest[n_answered_main >= battery_min_main]

# min valid months from the X months before the survey. The window filter
# below uses 31 * x_months = 372 days, slightly wider than 12 calendar
# months; months are truncated to month starts, so the slack is harmless on
# this static data.
min_months = 3
x_months = 12

# Minimum spending for valid month
min_spend = 3000

## Excluded categories when calculating valid months with spending
excluded_kr = c("da_credit_kr", "savings_kr", "transaction_kr", "exclude_kr")

spending = (monthly_kr[category %notin% excluded_kr]
             [, .(kr = sum(kr, na.rm = TRUE)), by = .(aid, month)]
             [kr > min_spend]
             [aid %in% answered_survey$aid]
             [survey_latest, on = "aid", nomatch = 0]
             [, submitdate := as.Date(submitdate)]
             [submitdate - 31 * x_months < month & month < submitdate]
             [, n := .N, by = aid]
             [n >= min_months])

# Demographics contains duplicate rows for some aids (flagged aid_dup in the
# real data, sequenced by `order`). Keep the first record per aid so every
# join downstream is one row per person. 30/40/45/65 use this table.
demographics_unique = demographics[order(aid, order), .SD[1], by = aid]

keep = unique(spending[, .(aid, month)])

# Person-level coverage of the transaction window: observed valid months
# and the annualised observed spending they imply. Single source for 49
# (coverage check), 57 (month restriction) and 66 (account analyses).
person_coverage = monthly_kr[category %notin% excluded_kr][
  keep, on = .(aid, month), nomatch = 0][
  , .(n_months = uniqueN(month), kr_sum = sum(kr, na.rm = TRUE)), by = aid][
  , observed_annual_spending := (kr_sum / n_months) * 12][
  , .(aid, n_months, observed_annual_spending)]

# Person x category annual outcome. This is the canonical recipe: every
# outcome construction downstream (43/47/50/52/54/55) calls it, so the
# headline total and the category-level estimates share the exact same
# sample rule (>= min_months per category), annualization and P99 winsor.
annualise = function(monthly, val) {
  (monthly[keep, on = .(aid, month), nomatch = 0]
   [, .(s = sum(get(val)), n_months = uniqueN(month)), by = .(aid, category)]
   [n_months >= min_months]
   [, y := (s / n_months) * 12]
   [, .(q99 = quantile(y, .99, na.rm = TRUE), y = y, aid = aid), by = category]
   [, y := pmin(y, q99)]
   [, .(aid, category, y)])
}

# Person-level annual outcome for a group of categories: the sum over the
# canonical annualised table above. Every group-outcome construction
# downstream (43/47/52's decomposition rows, 54's contrasts, 55/63/64/67's
# group models) calls this, so the grouping sum cannot drift between
# scripts.
group_annual = function(annual, cats) {
  annual[category %in% cats, .(y = sum(y, na.rm = TRUE)), by = aid]
}

# Decomposition targets (43/47/52): the named hypothesis groups given by
# the caller (category vectors defined above), then the total (all
# categories), then the top-10 categories by mean annual value as
# individual targets named top_<category>.
decomp_targets = function(annual, groups) {
  top10 = annual[, .(m = mean(y, na.rm = TRUE)), by = category][order(-m)][1:10, category]
  c(groups, list(total = unique(annual$category)),
    setNames(as.list(top10), paste0("top_", top10)))
}

# Headline outcome: total annual CO2e (sum of winsorized categories)
emissions = annualise(monthly_co2e, "co2e")[, .(co2e = sum(y, na.rm = TRUE)), by = aid]

# Category groups (leaf names from metadata.md), shared by the decomposition
# scripts so the grouping cannot drift between them.
transport_co2e = c("fuel_co2e", "car_maint_co2e", "car_rent_co2e", "public_trans_co2e",
  "bus_co2e", "taxi_co2e", "train_bus_co2e", "aviation_co2e", "ferry_co2e",
  "escooter_co2e", "transport_other_co2e")
ecom_co2e = c("clothing_co2e", "electronics_co2e", "books_co2e", "toys_co2e",
  "sports_co2e", "shopping_other_co2e", "home_garden_other_co2e")
digital_co2e = "internet_tele_co2e"
# Rent is excluded from the CO2e outcomes: rent_co2e is zero by construction
# (no emissions factor for housing payments). In the SEK decomposition (47)
# rent is a housing-tenure outcome, not a placebo: the SEK rent gradient
# reflects renting vs owning, not a digital consumption channel. The CO2e
# placebo is insurance ("insurance_co2e" in 43/52).
placebo_co2e = "insurance_co2e"
vehicles_co2e = "vehicles_co2e"

# Short- vs long-distance split of the transport composite (63): daily
# ground mobility vs intercity/international travel. car_rent and
# transport_other are ambiguous (vacation vs replacement rental; unknown
# mix) and stay separate. The three buckets exhaust transport_co2e.
short_co2e = c("fuel_co2e", "car_maint_co2e", "public_trans_co2e", "bus_co2e",
  "taxi_co2e", "train_bus_co2e", "escooter_co2e")
long_co2e = c("aviation_co2e", "ferry_co2e")
ambiguous_co2e = c("car_rent_co2e", "transport_other_co2e")

transport_kr = sub("_co2e$", "_kr", transport_co2e)
ecom_kr = sub("_co2e$", "_kr", ecom_co2e)
digital_kr = "internet_tele_kr"
vehicles_kr = "vehicles_kr"

# All pipeline outputs go to ONE directory, defined once here. Every run
# rewrites it wholesale (exploratory phase — no export versioning); the run
# manifest run_info.csv records when the run happened and with which spec.
out_dir = file.path(dirname(cache_dir), "output")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
