library(data.table)
`%notin%` <- Negate(`%in%`)
# Has answered q11
q11_cols <- grep("^q11(b_[1-8]|_[1-5])$", names(survey), value = T)
answered_survey <- survey[complete.cases(survey[, ..q11_cols])]

# min valid months from the X months before the survey
min_months = 3
x_months = 12

# Minimum spending for valid month
min_spend = 3000

## Excluded categories when calculating valid months with spending
excluded_kr <- c("da_credit_kr", "savings_kr", "transaction_kr", "exclude_kr")

spending <- (monthly_kr[category %notin% excluded_kr]
             [, .(kr = sum(kr, na.rm = T)), by = .(aid, month)]
             [kr > min_spend]
             [aid %in% answered_survey$aid]
             [survey[, .(aid, submitdate)], on = "aid", nomatch = 0]
             [, submitdate := as.Date(submitdate)]
             [submitdate - 31*x_months < month & month < submitdate]
             [, n := .N, by = aid]
             [n >= min_months])

keep <- unique(spending[, .(aid, month)])

emissions <- (monthly_co2e[keep, on = .(aid, month), nomatch = 0]
              [, .(co2e = sum(co2e), n_months = uniqueN(month)), by = .(aid, category)]
              [n_months > min_months]
              [, co2e := (co2e / n_months)*12]
              [, .(q99 = quantile(co2e, .99, na.rm = T), co2e = co2e, aid = aid), by = .(category)]
              [, co2e := pmin(co2e, q99)]
              [, .(co2e = sum(co2e, na.rm = T)), by = .(aid)])
