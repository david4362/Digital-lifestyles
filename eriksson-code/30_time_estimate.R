library(data.table)

# Valid endline surveys, has answered E4
q21_cols <- grep("^q21_(1|2)comment", names(survey_endline))
screen_time <- (survey_endline[, c(1, ..q21_cols)])
names(screen_time)[2:3] <- c("hours", "minutes")
screen_time[, hours := as.integer(hours)]
screen_time[, minutes := as.integer(minutes)]
screen_time <- screen_time[0 <= hours & hours <= 18]
screen_time <- screen_time[0 <= minutes & minutes < 60]
screen_time[, time := hours + minutes*(1/60)]
screen_time <- screen_time[demographics, on = "aid", nomatch = 0]

# Valid pre-surveys, has answered D3/D4
# Answers for VR glasses are removed
q11_cols <- grep("^q11(b_[1-8]|_[1-5])$", names(survey), value = T)
device_use <- survey[, c("aid", q11_cols), with = F]
device_use <- device_use[complete.cases(device_use)]
device_use <- cbind(device_use[, .(aid)], device_use[, aid := NULL] |> scale())
device_use[, index := rowMeans(.SD), .SDcols = q11_cols]

# Fit hours to index
device_time <- merge(screen_time, device_use, by = "aid")[, .(aid, time, index, age, gender)]
dt_lm <- lm(time ~ index, device_time)
dt_lm_controls <- lm(time ~ index + age + gender, device_time)
dt_coefs <- coef(dt_lm)
