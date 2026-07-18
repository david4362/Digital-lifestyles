# gen_mock_endline.R — synthetic ENDLINE survey for local development
#
# The real endline survey (with item E4, device-assisted average daily screen
# time) lives only in the TRE. This generates a stand-in with the properties
# the validity check must be able to detect:
#   - h:mm entry => strong heaping at 5/15/30/60-minute marks
#   - negative age gradient, small gender gap
#   - right skew; a few implausible entries (unit confusion: weekly totals,
#     or hours entered in the minutes field)
#   - partial response (endline attrition)
#
# Output: cache/mock_endline.rds  (data frame: aid, E4_hours, E4_minutes,
#         screen_min = parsed minutes/day)

suppressMessages(library(dplyr))
source("00_constants.R")

set.seed(20260718)
message("Generating mock endline survey ...")

# Use baseline respondents; ~65% answer the endline.
if (!file.exists(CACHE_FILE)) stop("Run 00_load_data.R first (cache missing).")
load(CACHE_FILE)  # dsurvey etc.

base <- dsurvey |> select(aid, age, sex) |> filter(!is.na(age))
n <- nrow(base)
respond <- runif(n) < plogis(1.2 - 0.015 * (base$age - 40))  # younger respond a bit more

end <- base[respond, ]
m <- nrow(end)

# True latent daily screen minutes: declines with age, ~210 min at age 40.
mu <- 330 - 3.0 * end$age + ifelse(end$sex == "female", 8, 0)
lat <- pmax(15, rnorm(m, mu, 90)) * exp(rnorm(m, 0, 0.25))

# Device-assisted reading => heap to 5-minute marks mostly, some to 15/30.
heap <- sample(c(1, 5, 15, 30), m, replace = TRUE, prob = c(.25, .45, .20, .10))
screen_min <- round(lat / heap) * heap

# Error modes: ~1.5% report the WEEKLY total (x7); ~0.5% put hours in minutes field.
weekly_err <- runif(m) < 0.015
screen_min[weekly_err] <- screen_min[weekly_err] * 7
hours_err <- !weekly_err & runif(m) < 0.005
screen_min[hours_err] <- round(screen_min[hours_err] / 60)

endline <- end |>
  transmute(aid,
            E4_hours   = screen_min %/% 60,
            E4_minutes = screen_min %% 60,
            screen_min = E4_hours * 60 + E4_minutes)

saveRDS(endline, file.path(CACHE_DIR, "mock_endline.rds"))
message(sprintf("Wrote cache/mock_endline.rds: %d respondents (%.0f%% of baseline)",
                m, 100 * m / n))
