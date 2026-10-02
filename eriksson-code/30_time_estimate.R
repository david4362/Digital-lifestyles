library(data.table)

# Latest endline response when an aid occurs more than once (55 reuses this).
endline_latest <- survey_endline[order(aid, submitdate), .SD[.N], by = aid]

# Valid endline surveys, has answered E4
q21_cols <- grep("^q21_(1|2)comment", names(endline_latest), value = TRUE)
screen_time <- endline_latest[, c("aid", ..q21_cols)]
setnames(screen_time, q21_cols, c("hours", "minutes"))
screen_time[, hours := as.integer(hours)]
screen_time[, minutes := as.integer(minutes)]
screen_time[, time := hours + minutes * (1 / 60)]
# Preregistration rule: average daily screen time above 18 hours/day is
# implausible and dropped. Checked on the combined value, so 18:30 is
# dropped too, not just reports above 18 whole hours.
screen_time <- screen_time[0 <= time & time <= 18]
screen_time <- screen_time[demographics_unique, on = "aid", nomatch = 0]

# Device-use items (q11_cols from 20) from the latest pre-treatment response,
# complete battery, z-scaled. This is the ONLY place the items and the index
# are scaled: 40 joins this table for the analysis sample, 54 uses the scaled
# items, and the anchor regression below is fit on exactly this index.
device_use <- survey_latest[, c("aid", q11_cols), with = FALSE]
device_use <- device_use[complete.cases(device_use)]
device_use[, (q11_cols) := lapply(.SD, function(x) as.vector(scale(x))), .SDcols = q11_cols]
device_use[, index := rowMeans(.SD), .SDcols = q11_cols]

# Fit hours to index
device_time <- merge(screen_time, device_use, by = "aid")[, .(aid, time, index, age, gender)]
dt_lm <- lm(time ~ index, device_time)
dt_lm_controls <- lm(time ~ index + age + gender, device_time)
dt_coefs <- coef(dt_lm)
