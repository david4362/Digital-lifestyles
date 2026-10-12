library(data.table)

# Latest endline response when an aid occurs more than once (45/55 reuse this).
endline_latest = survey_endline[order(aid, submitdate), .SD[.N], by = aid]

# E4 screen time: q21_1comment/q21_2comment are the hour/minute comment
# fields of the E4 item (device-assisted: the respondent reads the average
# daily screen time of the previous week off their own phone, iOS
# "Skärmtid" / Android "Digitalt välmående", and transcribes it as h:mm).
# Parsed once here, before the 18 h/day plausibility rule, so the E4
# diagnostics in 65 can report what the rule drops.
q21_cols = grep("^q21_(1|2)comment", names(endline_latest), value = TRUE)
screen_raw = endline_latest[, c("aid", ..q21_cols)]
setnames(screen_raw, q21_cols, c("hours", "minutes"))
screen_raw[, hours := as.integer(hours)]
screen_raw[, minutes := as.integer(minutes)]
screen_raw[, time := hours + minutes * (1 / 60)]

# Preregistration rule: average daily screen time above 18 hours/day is
# implausible and dropped. Checked on the combined value, so 18:30 is
# dropped too, not just reports above 18 whole hours. screen_valid is the
# rule applied (65's diagnostics report what it keeps and drops); the
# anchor sample below additionally requires a demographics record (it
# carries the age/gender used by the anchor regressions in 40).
screen_valid = screen_raw[0 <= time & time <= 18]
screen_time = screen_valid[demographics_unique, on = "aid", nomatch = 0]

# Raw battery responses, one row per aid, all 13 items, unscaled. The index
# itself is built in 40: the pre-registered construction z-scales the items
# on the analysis sample, which is only known once the sample is selected
# there. 59 re-uses this table for the battery-sample-scaling variant.
item_battery = survey_latest[, c("aid", q11_cols), with = FALSE]
