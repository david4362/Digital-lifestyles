# 10_screen_time_validity.R — Step 1: is the self-reported (device-assisted)
# screen-time item legit?
#
# The codebook is pending, so this script does two jobs:
#   A. Nominate which q15_* item is the screen-time anchor, from empirical
#      signatures: minutes-scale, plausible median (1-7 h/day), negative age
#      gradient, heaping at round values (device reports heap less).
#   B. Validity checks for the nominated item(s): distribution, implausible
#      values, heaping, age-group means vs. Swedish benchmark bands
#      (SE_SCREEN_BENCH in 00_constants.R — heuristic until verified).
#
# Outputs (output/):
#   screen_time_item_profile.csv     per-item diagnostics for all candidates
#   screen_time_by_age.csv           age-group stats vs benchmark bands
#   screen_time_distributions.png    histograms of all q15 items
#   screen_time_age_benchmark.png    nominated item vs benchmark bands

suppressMessages({ library(dplyr); library(tidyr); library(ggplot2) })
source("00_load_data.R")

# ---------------------------------------------------------------------------
# A. Profile all candidate items
# ---------------------------------------------------------------------------

q15 <- intersect(Q15_ITEMS, names(dsurvey))

profile_item <- function(v, age) {
  vv <- v[!is.na(v)]
  pos <- vv[vv > 0]
  tibble(
    n            = length(vv),
    pct_missing  = round(mean(is.na(v)) * 100, 1),
    pct_zero     = round(mean(vv == 0) * 100, 1),
    mean         = round(mean(vv), 1),
    median       = median(vv),
    p90          = quantile(vv, .9),
    p99          = quantile(vv, .99),
    max          = max(vv),
    pct_gt_16h   = round(mean(vv > MAX_SCREEN_MIN) * 100, 2),
    # Heaping: share of positive answers at multiples of 30 / 60 minutes.
    heap30       = round(mean(pos %% 30 == 0) * 100, 1),
    heap60       = round(mean(pos %% 60 == 0) * 100, 1),
    r_age        = round(cor(v, age, use = "pairwise"), 3)
  )
}

prof <- bind_rows(lapply(q15, function(nm) {
  profile_item(dsurvey[[nm]], dsurvey$age) |> mutate(item = nm, .before = 1)
}))

# Screen-time signature score: plausible median, negative age slope.
prof <- prof |>
  mutate(
    plausible_median = median >= 60 & median <= 420,
    neg_age_gradient = r_age < -0.05,
    candidate_score  = plausible_median + neg_age_gradient + (pct_zero < 20)
  ) |>
  arrange(desc(candidate_score), desc(abs(r_age)))

write.csv(prof, file.path(OUTPUT_DIR, "screen_time_item_profile.csv"), row.names = FALSE)
cat("== Candidate profile (sorted; top row = best screen-time candidate) ==\n")
print(as.data.frame(prof), row.names = FALSE)

nominated <- if (!is.na(SCREEN_TIME_ITEM)) SCREEN_TIME_ITEM else prof$item[1]
cat(sprintf("\nNominated screen-time item: %s %s\n\n", nominated,
            ifelse(is.na(SCREEN_TIME_ITEM), "(EMPIRICAL GUESS - confirm with codebook)",
                   "(from 00_constants.R)")))

# Small-multiples histogram of the whole battery (helps eyeball the anchor).
long <- dsurvey |> select(all_of(q15)) |>
  pivot_longer(everything(), names_to = "item", values_to = "minutes") |>
  filter(!is.na(minutes), minutes <= 720)
p1 <- ggplot(long, aes(minutes)) +
  geom_histogram(binwidth = 30, boundary = 0, fill = "steelblue", colour = "white") +
  facet_wrap(~ factor(item, levels = q15), scales = "free_y") +
  labs(title = "q15 time-use battery: distributions (minutes/day, truncated at 12 h)",
       x = "minutes/day", y = "respondents") +
  theme_minimal(base_size = 10)
ggsave(file.path(OUTPUT_DIR, "screen_time_distributions.png"), p1,
       width = 11, height = 7, dpi = 150)

# ---------------------------------------------------------------------------
# B. Validity checks for the nominated item
# ---------------------------------------------------------------------------

d <- dsurvey |>
  transmute(aid, age, sex, minutes = .data[[nominated]]) |>
  filter(!is.na(minutes), !is.na(age)) |>
  mutate(
    implausible = minutes > MAX_SCREEN_MIN,
    age_group = cut(age, c(17, 29, 44, 64, Inf),
                    labels = c("18-29", "30-44", "45-64", "65+"))
  )

cat(sprintf("Implausible (>16 h/day): %d of %d (%.2f%%)\n",
            sum(d$implausible), nrow(d), 100 * mean(d$implausible)))

by_age <- d |>
  filter(!implausible) |>
  group_by(age_group) |>
  summarise(n = n(), mean_min = round(mean(minutes), 1),
            median_min = median(minutes), sd_min = round(sd(minutes), 1),
            .groups = "drop") |>
  left_join(SE_SCREEN_BENCH, by = c("age_group" = "age_group")) |>
  mutate(within_benchmark = mean_min >= lo_min & mean_min <= hi_min)

write.csv(by_age, file.path(OUTPUT_DIR, "screen_time_by_age.csv"), row.names = FALSE)
cat("\n== Age-group means vs Swedish benchmark bands (heuristic) ==\n")
print(as.data.frame(by_age), row.names = FALSE)

p2 <- ggplot(by_age, aes(age_group)) +
  geom_errorbar(aes(ymin = lo_min, ymax = hi_min), width = 0.35,
                colour = "grey55", linewidth = 4, alpha = 0.4) +
  geom_point(aes(y = mean_min), size = 3, colour = "firebrick") +
  geom_point(aes(y = median_min), size = 3, shape = 1, colour = "firebrick") +
  labs(title = sprintf("Screen time (%s): sample vs Swedish benchmark bands", nominated),
       subtitle = "Filled = mean, hollow = median; grey band = heuristic benchmark (verify!)",
       x = "age group", y = "minutes/day") +
  theme_minimal(base_size = 12)
ggsave(file.path(OUTPUT_DIR, "screen_time_age_benchmark.png"), p2,
       width = 7, height = 5, dpi = 150)

# Sex difference + simple age regression (published: small gender gap, clear age decline)
cat("\n== Auxiliary checks ==\n")
print(d |> filter(!implausible) |> group_by(sex) |>
        summarise(n = n(), mean_min = round(mean(minutes), 1), .groups = "drop") |>
        as.data.frame(), row.names = FALSE)
fit <- lm(minutes ~ age + sex, data = filter(d, !implausible))
cat(sprintf("\nOLS minutes ~ age + sex: age slope = %.2f min per year (expect negative)\n",
            coef(fit)[["age"]]))

cat("\nDone. See output/ for figures and CSVs.\n")
