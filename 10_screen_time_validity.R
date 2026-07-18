# 10_screen_time_validity.R — Step 1: is the device-assisted screen-time
# report (endline item E4) legit?
#
# E4 (endline survey): average DAILY phone screen time in hours:minutes for the
# previous week, read from iOS "Skärmtid" / Android "Digitalt välmående".
#
# Locally the real endline is unavailable -> uses cache/mock_endline.rds
# (generate with gen_mock_endline.R). In the TRE, point DIGITAL_ENDLINE_FILE at
# the real endline extract with columns aid, E4_hours, E4_minutes (or screen_min).
#
# Checks:
#   1. Parsing & range: implausible values (>16 h/day), suspected unit errors
#      (weekly totals entered as daily; hours entered in minutes field)
#   2. Heaping: device-read values should heap at 5-min marks, not only 30/60
#   3. Age gradient (expect negative) and gender gap (expect small)
#   4. Age-group means vs Swedish benchmark bands (heuristic; verify vs
#      Internetstiftelsen "Svenskarna och internet")
#   5. Endline attrition: who is missing E4 (age/sex selectivity)
#
# Outputs (output/): screen_time_validity.csv, screen_time_by_age.csv,
#   screen_time_distribution.png, screen_time_age_benchmark.png

suppressMessages({ library(dplyr); library(tidyr); library(ggplot2) })
source("00_load_data.R")

ENDLINE_FILE <- Sys.getenv("DIGITAL_ENDLINE_FILE",
                           unset = file.path(CACHE_DIR, "mock_endline.rds"))
if (!file.exists(ENDLINE_FILE)) {
  message("Endline file not found - generating mock endline ...")
  source("gen_mock_endline.R")
}
endline <- readRDS(ENDLINE_FILE)
is_mock <- grepl("mock", basename(ENDLINE_FILE))
if (is_mock) message(">>> USING MOCK ENDLINE - results validate the pipeline, not the data. <<<")

d <- endline |>
  { \(x) if ("screen_min" %in% names(x)) x
         else mutate(x, screen_min = E4_hours * 60 + E4_minutes) }() |>
  left_join(dsurvey |> select(aid, age, sex), by = "aid") |>
  filter(!is.na(screen_min))

# --- 1. Range & unit-error screening -----------------------------------------

d <- d |> mutate(
  implausible  = screen_min > MAX_SCREEN_MIN,
  # Weekly-total suspicion: implausible daily value that becomes typical when /7
  weekly_susp  = implausible & (screen_min / 7) >= 60 & (screen_min / 7) <= 480,
  # Hours-in-minutes suspicion: tiny values that are typical if read as hours
  hours_susp   = screen_min > 0 & screen_min <= 16 & (screen_min * 60) >= 60
)

checks <- tibble(
  check = c("N respondents", "% of baseline sample", "median min/day", "mean min/day",
            "% zero", "% implausible (>16h)", "% suspected weekly totals",
            "% suspected hours-in-minutes", "% heaped at 60 min", "% heaped at 30 min",
            "% heaped at 5 min", "r(screen, age)"),
  value = c(nrow(d), round(100 * nrow(d) / nrow(dsurvey), 1),
            median(d$screen_min), round(mean(d$screen_min), 1),
            round(100 * mean(d$screen_min == 0), 2),
            round(100 * mean(d$implausible), 2),
            round(100 * mean(d$weekly_susp), 2),
            round(100 * mean(d$hours_susp), 2),
            round(100 * mean(d$screen_min %% 60 == 0), 1),
            round(100 * mean(d$screen_min %% 30 == 0), 1),
            round(100 * mean(d$screen_min %% 5 == 0), 1),
            round(cor(d$screen_min, d$age, use = "pairwise"), 3))
)
write.csv(checks, file.path(OUTPUT_DIR, "screen_time_validity.csv"), row.names = FALSE)
cat("== E4 validity checks ==\n"); print(as.data.frame(checks), row.names = FALSE)

# Cleaned variable: drop implausible; rescale suspected weekly totals.
d <- d |> mutate(
  screen_min_clean = case_when(weekly_susp ~ screen_min / 7,
                               implausible ~ NA_real_,
                               TRUE        ~ screen_min))

# --- 2. Distribution ----------------------------------------------------------

p1 <- ggplot(filter(d, !is.na(screen_min_clean), screen_min_clean <= 720),
             aes(screen_min_clean)) +
  geom_histogram(binwidth = 15, boundary = 0, fill = "steelblue", colour = "white") +
  labs(title = "E4: device-assisted daily screen time",
       subtitle = if (is_mock) "MOCK ENDLINE - pipeline validation only" else NULL,
       x = "minutes/day (cleaned)", y = "respondents") +
  theme_minimal(base_size = 12)
ggsave(file.path(OUTPUT_DIR, "screen_time_distribution.png"), p1,
       width = 7, height = 4.5, dpi = 150)

# --- 3. Age gradient vs benchmarks ---------------------------------------------

by_age <- d |>
  filter(!is.na(screen_min_clean), !is.na(age)) |>
  mutate(age_group = cut(age, c(17, 29, 44, 64, Inf),
                         labels = c("18-29", "30-44", "45-64", "65+"))) |>
  group_by(age_group) |>
  summarise(n = n(), mean_min = round(mean(screen_min_clean), 1),
            median_min = median(screen_min_clean), .groups = "drop") |>
  left_join(SE_SCREEN_BENCH, by = "age_group") |>
  mutate(within_benchmark = mean_min >= lo_min & mean_min <= hi_min)
write.csv(by_age, file.path(OUTPUT_DIR, "screen_time_by_age.csv"), row.names = FALSE)
cat("\n== Age-group means vs Swedish benchmark bands (heuristic) ==\n")
print(as.data.frame(by_age), row.names = FALSE)

p2 <- ggplot(by_age, aes(age_group)) +
  geom_errorbar(aes(ymin = lo_min, ymax = hi_min), width = 0.35,
                colour = "grey55", linewidth = 4, alpha = 0.4) +
  geom_point(aes(y = mean_min), size = 3, colour = "firebrick") +
  geom_point(aes(y = median_min), size = 3, shape = 1, colour = "firebrick") +
  labs(title = "E4 screen time: sample vs Swedish benchmark bands",
       subtitle = paste0("Filled = mean, hollow = median; grey = heuristic benchmark",
                         if (is_mock) " | MOCK ENDLINE" else ""),
       x = "age group", y = "minutes/day") +
  theme_minimal(base_size = 12)
ggsave(file.path(OUTPUT_DIR, "screen_time_age_benchmark.png"), p2,
       width = 7, height = 5, dpi = 150)

# --- 4. Gender gap & regression -------------------------------------------------

cat("\n== Gender means ==\n")
print(d |> filter(!is.na(screen_min_clean), !is.na(sex)) |> group_by(sex) |>
        summarise(n = n(), mean_min = round(mean(screen_min_clean), 1),
                  .groups = "drop") |> as.data.frame(), row.names = FALSE)
fit <- lm(screen_min_clean ~ age + sex, data = d)
cat(sprintf("\nOLS: age slope = %.2f min/year (expect negative)\n", coef(fit)[["age"]]))

# --- 5. Endline attrition selectivity -------------------------------------------

att <- dsurvey |>
  mutate(answered_E4 = aid %in% d$aid) |>
  filter(!is.na(age)) |>
  group_by(answered_E4) |>
  summarise(n = n(), mean_age = round(mean(age), 1),
            pct_female = round(100 * mean(sex == "female", na.rm = TRUE), 1),
            .groups = "drop")
cat("\n== Endline attrition (E4 answered vs not) ==\n")
print(as.data.frame(att), row.names = FALSE)

cat("\nDone. See output/ for figures and CSVs.\n")
