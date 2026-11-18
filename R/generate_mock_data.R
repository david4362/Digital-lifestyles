# generate_mock_data.R — the shared synthetic study data (canonical master)
#
# SYNCED IDENTICAL COPY: this canonical master lives at the workspace
# level (<workspace>/scripts/generate_mock_data.R); byte-identical copies
# are committed in every project repo (Digital-lifestyles/R/
# generate_mock_data.R, low-carbon-lifestyles/generate_mock_data.R,
# tax-return-spending/R/generate_mock_data.R) so each repo's RUN_MOCK
# works from a stand-alone checkout. When this file changes, copy it
# verbatim into all three projects. Never edit one project's copy alone.
#
# ONE synthetic population of the Konsumtionskollen (Svalna) study, used by
# every project's RUN_MOCK (each project's 00_mock_data.R adapter sources
# its repo-local copy of this file). All pipelines test against the SAME
# synthetic people.
#
# The mock is a logic test, not a results source: planted effects and data
# faults exist so the pipelines must recover them. Do not treat mock output
# as results. Real data never lives in any repo (data/common-data.md).
#
# Object map (cache-level shapes, i.e. what each project's 10/11 loaders
# produce from the raw TRE files; raw shapes and field lists are documented
# in data/common-data.md §4 and data/metadata/metadata.md):
#   linkage         LopNr <-> aid                 (JE_Lev_KopplingLopNr.txt)
#   demographics    frame members, 1+ rows/aid    (efid_demographics.dta)
#   users           app snapshots, 1 row/aid      (kk-handels-data-dynamic)
#   survey          pre-treatment respondents     (1648_Svalna_Data.xlsx)
#   survey_invite   invitation records (respondents + the no-bank frame
#                   members) — the id/date subset the tax loader caches
#   sampling_frame  invited participants + non-linked frame members
#   survey_endline  endline respondents           (1648_data_250115.xlsx)
#   scb             register join, aid-keyed      (LISA/Valdelt/DeSO files)
#   tax_iot         tax register, person x year   (JE_Lev_IoT_<year>.txt)
#   daily_income    one row per aid x date x category (kk-handels-income
#                   CSV); `income` is that day's total for the category, SEK.
#                   Real category values: income_refund, income_other,
#                   income_benefits, income_salary, income_financial,
#                   income_pensions. The mock plants the simplified labels
#                   salary/other (known mock blind spot)
#   transactions    one row per aid x date, wide _kr/_co2e columns whose
#                   cells are DAILY CATEGORY AGGREGATES (sub-day transactions
#                   summed before delivery for privacy; several columns are
#                   typically populated); post-rename dta shape
#                   (full_data_norecats_filters_*.dta), with the canonical
#                   aviation emission-intensity override applied (matching
#                   load_common_data.R). Carries the FULL delivered category
#                   system (data/metadata/metadata.md: 66 _kr and 65 _co2e
#                   leaves); da_credit_kr is the only kr leaf with no co2e
#                   mirror
#   transactions_long  the harmonized long core: one full melt of the wide
#                   table, one row per aid x date x category (stem) with kr,
#                   co2e and month. Identical to load_common_data.R's melt;
#                   every project consumes it directly
#   monthly_kr /    person x month x category     (the DL cache aggregates,
#   monthly_co2e    long views of `transactions`    derived here by the same
#                                                  melt+sum as DL's loader)
#   person_bank     mean monthly bank inflow/aid  (bank_income.parquet)
#   monthly_incomes monthly income long view      (low-carbon's object)
#   mock_plants     what was planted, where (self-documentation)
#
# Consumers (all three wired via 00_mock_data.R adapters + RUN_MOCK.R):
#   - Digital-lifestyles RUN_MOCK (survey, survey_endline, demographics,
#     users, scb, monthly_kr/co2e, person_bank)
#   - tax-return-spending RUN_MOCK (tax_iot, daily_income, transactions,
#     survey_invite)
#   - low-carbon-lifestyles RUN_MOCK (transactions in the canonical
#     underscore schema with the aviation override already applied, ESI
#     survey items array3_8/9/11,
#     users with `user-created`, `profile.field_food_diet` aligned with
#     no_meat and `profile.ncars` = 0 for no_car, monthly_incomes,
#     demographics/sampling_frame, scb; no_flying = aviation co2e sums
#     EXACTLY zero for adopters — the override preserves this because it
#     multiplies aviation kr, which the no_flying plant zeroes exactly;
#     pre-COVID era + COVID hole exercise its
#     window-exclusion and consecutive-window-gap logic).
#
# ---- Planted effects (recovery targets for the pipelines) ----------------
#  DL: digital-intensity latent z -> q11/q11b battery (1-6), E4 screen time
#      (anchor ~1.2 h per index SD), E1 out-of-home leisure falls / at-home
#      rises with z, monthly CO2e gradients per category (transport
#      negative, goods/digital positive, placebos zero), income confound,
#      leisure->transport mediation (~90 kg/SD spread over transport cats),
#      SEK-per-kg basket-composition margin (ratio falls with screen time).
#  Tax: refund scenarios rotated over person x income year, covering all
#      FOUR Skatteverket-scheduled payout months (April, June, August,
#      December) plus relative/suspected drift, an unsearched-October
#      deposit, a deposit hidden in the transactions source (inert under the
#      income-only matcher), informative no_match, register-only kvarskatt,
#      an ambiguous double candidate, and NEAR-ZERO settlements (|refund| <
#      100 SEK, both signs, no deposit and no spending spike — the DiD
#      control group with a planted zero response). The PRIMARY definition
#      (SARB+SKUARB+SKUSOC) - SSLUTEX equals the planted deposit by
#      construction. Outgoing kvarskatt payments are still planted as
#      positive exclude_kr cells (inert: no settlement is searched in the
#      dta). Post-refund spending spikes are planted in [0..7] and [8..30]
#      days after dep_date, moderated by ESI (high ESI shifts from aviation
#      to train_bus/sports) and by payout month (June -> aviation/travel;
#      April/Aug/Oct/Dec -> electronics/clothing/home_garden_other).
#  Low-carbon: environmental-self-identity items (independent latent), and
#      lifestyles no_car / no_flying / no_meat suppressing their focal
#      categories (car spending, aviation, groceries) + users.ncars = 0 for
#      no_car.
#
# ---- Planted data faults (the real-data quirks the code must handle) -----
#  duplicate demographics rows (aid_dup, order, conflicting value) - partial
#  battery answers (the >= 8 of 11 gate keeps them) - E4 opt-out classes -
#  rent faults (never-rent, second-half missing = interior fault, window-
#  edge misses = stable under the relaxed rule) - a low-spend subgroup below
#  the valid-month spending threshold - participants with no bank-income
#  rows - income rows for aids outside the study - frame members with
#  invitations but zero bank data - register-only year-varying columns
#  (2018-only SKUARB/SKUSOC, 2023-only SREDINV/SREDAK) - DispInk04 in
#  100-SEK units - education code 999 (unknown) for a few - uncategorized
#  spending share around the low-carbon filter threshold (a few above it) -
#  the full 66/65 leaf system, with the secondary leaves carrying level only
#  (no planted gradient) and the transfer/donor leaves (savings, transaction,
#  transfer_to_creditcard, charity) at co2e 0 with a kr flow -
#  sub-day transactions summed to daily category aggregates before delivery
#  (privacy: no transaction-level rows reach any project).
#
# ---- The de-collision rule (load-bearing; do not break it) ---------------
#  The tax matcher probes EVERY positive daily_income row in the four
#  Skatteverket-scheduled payout months (04/06/08/12) as a candidate
#  settlement, on a PURE +-5% band: |amount - |refund|| <= 5% of |refund|.
#  The transactions dta is never searched for a settlement; back-tax rows
#  (refund < 0) are classified from the register alone. Categories are NOT
#  assumed to be correctly assigned, so there is no allow-list; one match
#  per user per year, the earliest in-band dep_date wins. The delivered data carry no
#  sub-day detail: for privacy, all transactions of one category on one day
#  are summed before delivery, so each _kr cell is a daily category
#  aggregate and a typical dta row has several populated columns. A
#  settlement is therefore only recoverable when it is the only (net) flow
#  in its category-day cell; the generator plants exactly that condition
#  (the routine exclude transfers are kept off settlement days).
#  False matches are kept impossible by SCALE SEPARATION and by SIGN:
#    planted refunds (primary def)  in [3000, 15000] SEK, integer;
#    every variant-definition refund stays >= 1800 (SSLUTEXHB shift within
#    +/-1200; variants only add preliminary tax <= 3300 and reductions
#    <= ~2400, so the largest variant refund stays <= ~20600);
#    salary rows                    >= ~22,600 SEK (base 23,000-30,000);
#    ordinary daily category cells  <= 1200 SEK (big monthly cells are
#                                    split across distinct days within
#                                    their aid x month x category);
#    ordinary dta cells are positive debits and never pass the credit
#    sign filter; planted refund deposits are the ONLY negative cells in
#    any _kr column; kvarskatt payments are positive exclude_kr cells
#    >= 7000 SEK, clear of the ordinary cells.
#  Near-zero settlements (|refund| < 100 SEK) have NO planted deposit and a
#  band narrower than 5 SEK, so they cannot collide with ordinary cells;
#  they are the DiD control group with a planted zero spending response.
#  The narrowest 5% band on a NORMAL refund is 90 SEK around a refund >= 1800
#  (lower bound 1710), and the nearest ordinary amount is 1200 -> gap >= 510 SEK;
#  salaries clear the largest variant refund by > 500 SEK. Consequence: reduction magnitudes
#  (SRED*) are planted smaller than the real register's (real ROT/RUT reach
#  50k/yr) - acceptable in a mock, and the reason is right here.

library(data.table)

# Names that existed before this script was sourced (the adapter or a
# sandbox may have defined paths/tables first): the final cleanup wipes
# only THIS generator's intermediates and keeps these, plus the keep-list
# of emitted objects at the bottom.
preexisting = ls()

set.seed(42)

# ---------------------------------------------------------------------------
# 1. Population, identity, latents
# ---------------------------------------------------------------------------
n = 800L
aid = paste0("efid", sprintf("%04d", seq_len(n)))

# Four invitation groups (the tax filter's sent/startdate cases; DL's
# frame-vs-respondent attrition) crossed with observation windows (the
# person's bank-data span; the tax matrix's years-of-data axis).
inv_group = rep(c("invite_2024", "invite_2023", "invite_2023_nosent", "no_invite"), length.out = n)
obs_group = rep(c("y2022_2024", "y2023_2024", "y2024", "y2022_2023"), length.out = n)
obs = data.table(aid, inv_group, obs_group)
obs[, obs_start := as.Date(fcase(
  obs_group == "y2022_2024", "2022-01-01",
  obs_group == "y2023_2024", "2023-01-01",
  obs_group == "y2024", "2024-01-01",
  default = "2022-01-01"))]
obs[, obs_end := as.Date(fifelse(obs_group == "y2022_2023", "2023-12-31", "2024-12-31"))]
# Every participant additionally has a pre-COVID history: 2019-01 through
# 2020-02, then a hole over the COVID window (2020-03 .. 2021-03, the
# low-carbon filter's exclusion months), then the 2022-2024 window above.
# The hole is what exercises low-carbon's consecutive-window logic —
# windows cannot cross a gap in the monthly data — and its COVID-month
# exclusion; the deferred-consumption robustness (all post-COVID months)
# runs on the 2022+ era. DL and tax windows (pre-survey 12 months, payout
# years 2022-24) are unaffected by the early era.
era1_start = as.Date("2019-01-01")
era1_end = as.Date("2020-02-01")
# no_invite members downloaded the app (they have bank data) but never took
# the survey; everyone else's download coincides with the invitation.
obs[, invite_date := as.Date(fcase(
  inv_group == "invite_2024", "2024-07-01",
  inv_group == "invite_2023", "2023-07-01",
  inv_group == "invite_2023_nosent", "2023-07-02",
  default = "2024-07-15"))]
obs[, user_created := invite_date]

age = sample(18:80, n, replace = TRUE)
gender = sample(c("Man", "Kvinna"), n, replace = TRUE, prob = c(0.49, 0.51))
postort = sample(c("Stockholm", "Göteborg", "Malmö", "Uppsala", "Umeå", "Växjö"),
  n, replace = TRUE, prob = c(0.2, 0.1, 0.1, 0.2, 0.2, 0.2))
major = postort %in% c("Stockholm", "Göteborg", "Malmö")

# Digital-lifestyle latent (DL's exposure) and an independent ESI latent
# (low-carbon's moderator): z is correlated with age and city like the real
# thing, but z and esi are independent of each other.
z = as.numeric(scale(-0.03 * (age - 40) + 0.5 * major + rnorm(n)))
esi_latent = as.numeric(scale(rnorm(n)))

# Lifestyles (low-carbon): independent of z and of each other. The three
# indicators are redrawn until their chance correlation with z is
# negligible (< 0.01): each lifestyle suppresses large-base categories
# (fuel 600, vehicles 300, groceries 800 kg/yr), so even a small seed
# correlation would swamp the planted screen-time gradients. The thresholds
# and shares below are unaffected — this only removes seed luck from the
# independence the plants claim.
# no_flying zeroes aviation EXACTLY (multiplier 0, not a small residue):
# low-carbon derives no_flying as sum(aviation co2e) == 0 over the window,
# so a residue would make the derivation never fire.
draw_independent_of_z = function(p) {
  repeat {
    x = as.integer(runif(n) < p)
    if (abs(cor(z, x)) < 0.01) return(x)
  }
}
no_car = draw_independent_of_z(0.15)
no_flying = draw_independent_of_z(0.10)
no_meat = draw_independent_of_z(0.10)
# Diet label on the users profile (a real column in the kk-handels export):
# low-carbon derives no_meat as profile.field_food_diet != "mixed" and its
# diet-definition robustness step splits non-meat into vegetarian, vegfish
# and vegan. Split "vegetarian" into vegetarian/vegfish deterministically
# after the 2-way draw so R's rejection sampler consumes the exact same
# number of uniform draws (k = 2 has 0 rejections; k = 3 rejects 25% and
# shifts the downstream RNG stream for all projects).
diet = rep("mixed", n)
diet[no_meat == 1] = sample(c("vegetarian", "vegan"), sum(no_meat), replace = TRUE)
diet[which(diet == "vegetarian")[c(TRUE, FALSE)]] = "vegfish"

# Income (annual SEK, app-reported level): mildly correlated with z (the
# confound DL's M2+ controls remove). Register disposable income (DispInk04,
# 100-SEK units) derives from it below; the salary base does not (see the
# de-collision rule).
income_level = round(exp(rnorm(n, 12.6 + 0.15 * z, 0.5)))

# ---------------------------------------------------------------------------
# 2. Surveys
# ---------------------------------------------------------------------------
# Pre-treatment respondents: everyone except no_invite. `sent` carries a
# LimeSurvey-style timestamp; the nosent group has sent = NA so the tax
# filter exercises its startdate fallback (both paths exist in the real
# delivery question — see data/common-data.md §9.5).
respondent = inv_group != "no_invite"
survey = data.table(
  aid = aid[respondent],
  response_type = "complete",
  sent = fifelse(inv_group[respondent] == "invite_2023_nosent", NA_character_,
    paste0(format(obs$invite_date[respondent]), " 09:15:02")),
  remindersent = paste0(format(obs$invite_date[respondent] + 7), " 09:15:02"),
  startdate = format(obs$invite_date[respondent] + 2),
  submitdate = format(obs$invite_date[respondent] + 5))

# q11 battery (1-6) correlated with z; 20 people miss q11_1 (partial battery
# — the >= 8 of 11 gate keeps them, the pipeline must not drop them).
q11_names = c(paste0("q11_", 1:5), paste0("q11b_", 1:8))
zr = z[respondent]
q = lapply(q11_names, function(nm) pmin(6, pmax(1, round(3.5 + 0.8 * zr + rnorm(length(zr))))))
names(q) = q11_names
survey[, (q11_names) := q]
survey[sample(.N, 20), q11_1 := NA]

# ESI items (1-5 Likert) from the independent latent.
esi_std = as.numeric(esi_latent[respondent])
survey[, array3_8 := pmax(1, pmin(5, round(3 + 0.8 * esi_std)))]
survey[, array3_9 := pmax(1, pmin(5, round(3 + 0.8 * esi_std + rnorm(.N, 0, 0.5))))]
survey[, array3_11 := pmax(1, pmin(5, round(3 + 0.8 * esi_std + rnorm(.N, 0, 0.5))))]

# Endline: respondents only. E4 (q21) = device-assisted daily screen time in
# h:mm with the opt-out flags; ~28% opt out, nocontact rows are absent. E1
# (F88) = 12-month activity battery: work/filler items random, the
# out-of-home set falls and the at-home set rises with z (the pre-registered
# mechanism DL's 67 must find).
time = 2.5 + 1.2 * z - 0.02 * (age - 45) + 0.15 * (gender == "Kvinna") + rnorm(n, sd = 0.7)
time = pmin(15, pmax(0.2, time))
h = floor(time)
mnt = round((time %% 1) * 60)
ov = mnt == 60
h[ov] = h[ov] + 1
mnt[ov] = 0
p = runif(n)
status = fcase(p < 0.72, "reporter", p < 0.82, "not_activated", p < 0.88, "skip", default = "nocontact")
ooh_plant = pmax(1, pmin(7, round(4.2 - 0.45 * z + rnorm(n, 0, 0.9))))
home_plant = pmax(1, pmin(7, round(4.2 + 0.3 * z + rnorm(n, 0, 0.9))))
status_r = status[respondent]
survey_endline = data.table(
  aid = aid[respondent],
  response_type = "complete",
  submitdate = format(obs$invite_date[respondent] + 10),
  q21_1comment = fifelse(status_r == "reporter", h[respondent], NA_integer_),
  q21_2comment = fifelse(status_r == "reporter", mnt[respondent], NA_integer_),
  q21_3 = as.integer(status_r == "not_activated"),
  q21_4 = as.integer(status_r == "skip"),
  F88_2 = sample(1:7, sum(respondent), replace = TRUE),
  F88_3 = sample(1:7, sum(respondent), replace = TRUE),
  F88_10 = sample(1:7, sum(respondent), replace = TRUE),
  F88_19 = sample(1:7, sum(respondent), replace = TRUE),
  F88_4 = ooh_plant[respondent], F88_5 = ooh_plant[respondent], F88_6 = ooh_plant[respondent],
  F88_7 = ooh_plant[respondent], F88_8 = ooh_plant[respondent], F88_18 = ooh_plant[respondent],
  F88_21 = ooh_plant[respondent],
  F88_11 = home_plant[respondent], F88_12 = home_plant[respondent], F88_13 = home_plant[respondent],
  F88_14 = home_plant[respondent], F88_16 = home_plant[respondent])

# Invitation records (the tax cache object): respondents plus the no-bank
# frame members (invited, never responded, no bank rows) so the tax filter's
# sent/startdate paths and the observed-data filter are both exercised.
no_bank_aid = paste0("efid_nobank_", 1:20)
nb_age = sample(18:80, 20, replace = TRUE)
survey_invite = rbind(
  survey[, .(aid, sent, remindersent, startdate, submitdate)],
  data.table(aid = no_bank_aid,
    sent = "2024-07-01 09:15:02", remindersent = "2024-07-08 09:15:02",
    startdate = "2024-07-03", submitdate = "2024-07-06"))

# ---------------------------------------------------------------------------
# 3. Register-side tables (demographics, users, scb, linkage)
# ---------------------------------------------------------------------------
# Demographics covers the whole invited frame (app users + the no-bank
# members); DL's representativeness script reads the stream flags here
# (randomsample / greensample — the real location, per the DL loader).
randomsample = as.integer(runif(n) < 0.75)
greensample = as.integer(!randomsample & runif(n) < 0.8)
demographics = data.table(
  aid = c(aid, no_bank_aid),
  order = 1L,
  age = c(age, nb_age),
  gender = c(gender, sample(c("Man", "Kvinna"), 20, replace = TRUE)),
  postort = c(postort, sample(c("Stockholm", "Göteborg", "Malmö", "Uppsala", "Umeå", "Växjö"), 20, replace = TRUE)),
  postnr = sample(10000:98999, n + 20, replace = TRUE),
  randomsample = c(randomsample, rep(1L, 20)),
  greensample = c(greensample, rep(0L, 20)))
demographics[, female := gender == "Kvinna"]
# The duplicate-row fault: a second record for 20 aids with a conflicting
# age (flagged aid_dup, sequenced by `order` in the real data).
dup_aid = sample(aid, 20)
demographics = rbind(demographics,
  copy(demographics[aid %chin% dup_aid])[
    , `:=`(order = 2L, age = age + 1L, postnr = postnr + 1L)])
demographics[, aid_dup := as.integer(aid %chin% dup_aid)]

# Users: app users only (the 800; no-bank members never linked a bank).
# ncars = 0 for the no_car lifestyle (64's carless stratum and low-carbon's
# no_car definition must agree with the planted spending).
users = data.table(
  aid = aid,
  date = as.Date("2024-06-15"),
  `user-created` = obs$user_created,
  `income-level` = income_level,
  `nr-of-bank-accounts` = sample(1:4, n, replace = TRUE),
  profile.kommun = postort,
  profile.hometype = {u = runif(n); fifelse(u < 0.3 + 0.3 * major, "Lägenhet",
    fifelse(u < 0.8 + 0.05 * major, "Villa", "Radhus"))},
  profile.ncars = fifelse(no_car == 1, 0L, {v = runif(n); fifelse(v < 0.25 + 0.2 * major, 0L,
    fifelse(v < 0.70 + 0.2 * major, 1L, 2L))}),
  profile.field_profile_household_adults = sample(1:2, n, replace = TRUE, prob = c(0.75, 0.25)),
  profile.field_profile_household_children = sample(0:3, n, replace = TRUE, prob = c(0.5, 0.25, 0.15, 0.1)),
  profile.field_profile_commute_distance = {cd = round(rlnorm(n, 2.4 - 0.5 * major, 0.7), 1); cd[sample(n, 40)] = NA; cd},
  profile.field_profile_commute_public = as.integer(runif(n) < 0.25 + 0.25 * major),
  profile.field_profile_commute_bike = as.integer(runif(n) < 0.15),
  profile.field_profile_commute_car = as.integer(runif(n) < 0.55 - 0.25 * major),
  profile.field_food_diet = diet)

# SCB register join (aid-keyed, app users + no-bank frame members).
# DispInk04 is planted in 100-SEK units (the real trap: register income =
# DispInk04 x 100). A few education codes are 999 (unknown) — the low-carbon
# filter drops them; DL's education factor maps them to its top level.
scb = data.table(
  aid = c(aid, no_bank_aid),
  deso = paste0("d", sample(1:100, n + 20, replace = TRUE)),
  density = rlnorm(n + 20, 7),
  Sun2020Niva = c(sample(c(100, 200, 310, 410, 520, 620), n, replace = TRUE),
    sample(c(100, 200, 310, 410, 520, 620), 20, replace = TRUE)))
scb[runif(.N) < 0.03, Sun2020Niva := 999]
scb[, DispInk04 := round(c(income_level, round(exp(rnorm(20, 12.6, 0.5)))) / 100 *
    exp(rnorm(.N, 0, 0.2)))]
scb[, FoDelt := as.integer(runif(.N) < 0.06)]
scb[, HSDelt := as.integer(runif(.N) < 0.10 + 0.25 * (c(age, nb_age) < 30))]
scb[, StudDelt := as.integer(runif(.N) < 0.08 + 0.20 * (c(age, nb_age) < 30))]
scb[, BostBidrFam := rbinom(.N, 1, 0.10) * round(rlnorm(.N, 10, 0.5))]
scb[, ArbSokNov := rbinom(.N, 1, 0.05)]
scb[, Civil := sample(c("Single", "Married", "Divorced"), .N, replace = TRUE)]
scb[, FamTypF := sample(c("Single", "Cohab_no_kids", "Cohab_kids", "Single_parent"), .N, replace = TRUE)]

linkage = data.table(LopNr = c(sample(100001:999999, n), sample(100001:999999, 20)),
  aid = c(aid, no_bank_aid))

# The invited random frame (with non-linked frame members; low-carbon's
# 10_load_data.R and 00_mock_data.R derive `sampling_frame` directly from
# `demographics`, as DL's representativeness script does, while keeping these
# draws here preserves the RNG stream for §§4–7).
frame_n = 2800L
sampling_frame = data.table(
  aid = c(aid, sprintf("frame_%06d", seq_len(frame_n))),
  postort = c(postort, sample(c("Stockholm", "Göteborg", "Malmö", "Uppsala", "Umeå", "Växjö"), frame_n, replace = TRUE)),
  age = c(age, sample(18:80, frame_n, replace = TRUE)),
  gender = c(gender, sample(c("Man", "Kvinna"), frame_n, replace = TRUE)),
  randomsample = c(randomsample, rep(1L, frame_n)),
  efid = c(aid, sprintf("frame_%06d", seq_len(frame_n))))

# ---------------------------------------------------------------------------
# 4. Tax register (IoT): refund scenarios per person x income year
# ---------------------------------------------------------------------------
# Scenarios rotate over person x income year (2021-2023) so every (scenario,
# year) combination occurs; the primary definition equals the planted
# deposit by construction. Two extra scenarios (April deposits and near-zero
# settlements) are layered on below by RELABELLING a deterministic subset of
# rows: no RNG draws and no change to any downstream .N, so DL's and
# low-carbon's planted values keep their original stream. Year-varying column
# sets and the odd/even NA count trick exercise the audit's group-type
# consistency. SRED magnitudes are deliberately small — see the de-collision
# rule in the header.
tax_years = 2021:2023
tax_iot = CJ(aid = c(aid, no_bank_aid), tax_year = tax_years)
tax_iot[, scenario := rep(c("clean_june", "late_aug", "late_oct", "late_dec",
  "drift_relative", "drift_suspected", "in_transactions", "no_match", "kvarskatt",
  "ambiguous"), length.out = .N)]
tax_iot[, SARB := as.integer(round(rlnorm(.N, 11.2, 0.4)))]
tax_iot[, SKUARB := NA_integer_]
tax_iot[, SKUSOC := NA_integer_]
tax_iot[, SAVPE := 0L]
tax_iot[1, SAVPE := NA_integer_]
# Refunds: the de-collision rule needs [3000, 15000] (redraw until inside);
# kvarskatt stays negative (a pay-in settlement, no deposit expected).
tax_iot[, true_refund := 0L]
tax_iot[scenario != "kvarskatt", true_refund := {
  v = as.integer(round(rnorm(.N, 7000, 3500)))
  bad = v < 3000 | v > 15000
  while (any(bad)) {
    v[bad] = as.integer(round(rnorm(sum(bad), 7000, 3500)))
    bad = v < 3000 | v > 15000
  }
  v
}]
tax_iot[scenario == "kvarskatt", true_refund := -as.integer(round(runif(.N, 7000, 15000)))]
tax_iot[, SSLUTEX := SARB - true_refund]
tax_iot[, SSLUTEXHB := SSLUTEX + as.integer(round(runif(.N, -1200, 1200)))]

# --- Two extra tax scenarios, layered on WITHOUT disturbing the stream ---
# Relabel a deterministic subset of existing rows and adjust only register
# columns. No new RNG draws and no change to any downstream .N, so the RNG
# stream of §§1-8 (and DL's monthly_kr / monthly_co2e) is untouched.
# April deposits: relabel every 4th June row (the 10-scenario period and the
# 3-year CJ order would align a %% 3 rule with a single tax year; %% 4 cycles
# through all three years).
tax_iot[, seq_i := seq_len(.N), by = scenario]
tax_iot[scenario == "clean_june" & seq_i %% 4L == 0L, scenario := "early_april"]
# Near-zero settlements: a deterministic hash of (aid index, tax_year) over
# ALL scenarios, so controls span every tax year AND every invitation group.
# Selecting rows from one scenario only correlates aid index, tax_year and
# invite group (the 10-scenario x 3-year lattice), leaving whole payout years
# without controls and therefore whole seasons without DiD placebo dates.
aid_index = match(tax_iot$aid, aid)
tax_iot[, aid_idx := aid_index]
tax_iot[!is.na(aid_idx) & (aid_idx * 7L + tax_year * 13L) %% 11L == 0L,
  scenario := "near_zero"]
# Near-zero settlement = Skatteverket's <100 SEK payout limit: no payout, so
# the DiD control group has NO deposit and NO post-refund spending spike.
# Both signs exercise the no_match and register-only kvarskatt control paths.
tax_iot[scenario == "near_zero",
  true_refund := as.integer((seq_i * 37L + aid_idx * 17L) %% 199L) - 99L]
tax_iot[scenario == "near_zero", SSLUTEX := SARB - true_refund]
tax_iot[scenario == "near_zero", SSLUTEXHB := SSLUTEX]
tax_iot[, c("seq_i", "aid_idx") := NULL]

tax_iot[, SKUBANK := as.integer(round(runif(.N, 0, 2500)))]
tax_iot[, SKUVP := as.integer(round(runif(.N, 0, 800)))]
tax_iot[, SREDHUSA := as.integer(round(runif(.N, 0, 200)))]
tax_iot[, SREDHUSF := as.integer(round(runif(.N, 0, 200)))]
tax_iot[, SREDGRONF := as.integer(round(runif(.N, 0, 200)))]
tax_iot[, SREDROT := as.integer(round(runif(.N, 0, 150)))]
tax_iot[, SREDHUA := as.integer(round(runif(.N, 0, 150)))]
tax_iot[, SREDHUS := SREDROT + SREDHUA]
tax_iot[, SREDGRON := as.integer(round(runif(.N, 0, 200)))]
tax_iot[, SREDEL := as.integer(round(runif(.N, 0, 200)))]
tax_iot[, SREDFA := as.integer(round(runif(.N, 0, 200)))]
tax_iot[, SREDFVI := as.integer(round(runif(.N, 0, 200)))]
tax_iot[, SREDGAVA := as.integer(round(runif(.N, 0, 200)))]
tax_iot[, SREDINV := fifelse(tax_year == 2023L, 0L, NA_integer_)]
tax_iot[, SREDREG := 0L]
tax_iot[, SREDSJO := 0L]
tax_iot[, SREDAK := fifelse(tax_year == 2023L, 0L, NA_integer_)]
tax_iot[, SREDKAP := as.integer(round(runif(.N, 0, 200)))]
tax_iot[, SREDPEN := as.integer(round(runif(.N, 0, 200)))]

# ---------------------------------------------------------------------------
# 5. Monthly spending/emissions grid (the single source of planted values)
# ---------------------------------------------------------------------------
# Person x month x category for every month inside the person's observation
# window. Base levels, the screen-time gradients (DL), the income confound,
# the leisure->transport mediation, the lifestyle suppressions (low-carbon)
# and the rent faults are planted HERE; the sub-day long tables and the
# monthly cache views below are pure derivations, so every consumer sees the
# same planted numbers. Categories carry their co2e names ("fuel_co2e"); the
# kr mirror ("fuel_kr") is constructed at the row stage.
base = c(fuel_co2e = 600, car_maint_co2e = 150, public_trans_co2e = 100, taxi_co2e = 30,
  ferry_co2e = 40, aviation_co2e = 500, travel_co2e = 300, clothing_co2e = 150, electronics_co2e = 80,
  books_co2e = 20, toys_co2e = 15, sports_co2e = 20, shopping_other_co2e = 120,
  home_garden_other_co2e = 60, internet_tele_co2e = 30, rent_co2e = 700, insurance_co2e = 20,
  vehicles_co2e = 300, groceries_co2e = 800, restaurant_co2e = 200, electricity_co2e = 400,
  train_bus_co2e = 60, bus_co2e = 40, car_rent_co2e = 50, transport_other_co2e = 40, escooter_co2e = 5,
  # Remaining leaves of the delivered category system (data/metadata/
  # metadata.md: 65 co2e / 66 kr). No planted gradient: they carry level only,
  # so the documented per-category gradients above stay the recovery targets.
  # `exclude` and `uncategorized` are planted separately below, not here.
  alcohol_co2e = 60, bar_co2e = 40, tobacco_co2e = 20, snacks_co2e = 35,
  food_other_co2e = 45, agriculture_co2e = 20, appliances_co2e = 50,
  furniture_co2e = 70, repair_build_co2e = 35, repair_home_co2e = 40,
  repair_rent_co2e = 25, beauty_co2e = 25, culture_co2e = 35,
  financial_service_co2e = 15, services_co2e = 55, pharmacy_co2e = 30,
  glasses_lenses_co2e = 12, health_co2e = 25, health_care_co2e = 35,
  health_other_co2e = 18, housing_other_co2e = 35, gas_co2e = 30,
  liquid_fuels_co2e = 15, solid_fuels_co2e = 12, district_heating_co2e = 140,
  utilities_heating_other_co2e = 20, jewelry_co2e = 18, leisure_other_co2e = 35,
  pets_co2e = 28, sport_equip_co2e = 22, cash_co2e = 25, outlay_co2e = 25,
  other_other_co2e = 15,
  # kr flows without an emission factor (forced to co2e = 0 after the grid,
  # like rent): savings, ordinary transfers, credit-card payments, donations.
  savings_co2e = 40, transaction_co2e = 45, transfer_to_creditcard_co2e = 60,
  charity_co2e = 20)
grad = c(fuel_co2e = -15, car_maint_co2e = -8, public_trans_co2e = -7, taxi_co2e = -2,
  ferry_co2e = 2, aviation_co2e = 10, travel_co2e = 8, clothing_co2e = 5, electronics_co2e = 4,
  books_co2e = 1, toys_co2e = 1, sports_co2e = 1, shopping_other_co2e = 3,
  home_garden_other_co2e = 1, internet_tele_co2e = 5, rent_co2e = 0, insurance_co2e = 0,
  vehicles_co2e = 0, groceries_co2e = -5, restaurant_co2e = -8, electricity_co2e = 0,
  train_bus_co2e = -3, bus_co2e = -2, car_rent_co2e = -1, transport_other_co2e = -1, escooter_co2e = 0,
  # Level-only leaves: no planted screen-time gradient.
  alcohol_co2e = 0, bar_co2e = 0, tobacco_co2e = 0, snacks_co2e = 0,
  food_other_co2e = 0, agriculture_co2e = 0, appliances_co2e = 0,
  furniture_co2e = 0, repair_build_co2e = 0, repair_home_co2e = 0,
  repair_rent_co2e = 0, beauty_co2e = 0, culture_co2e = 0,
  financial_service_co2e = 0, services_co2e = 0, pharmacy_co2e = 0,
  glasses_lenses_co2e = 0, health_co2e = 0, health_care_co2e = 0,
  health_other_co2e = 0, housing_other_co2e = 0, gas_co2e = 0,
  liquid_fuels_co2e = 0, solid_fuels_co2e = 0, district_heating_co2e = 0,
  utilities_heating_other_co2e = 0, jewelry_co2e = 0, leisure_other_co2e = 0,
  pets_co2e = 0, sport_equip_co2e = 0, cash_co2e = 0, outlay_co2e = 0,
  other_other_co2e = 0, savings_co2e = 0, transaction_co2e = 0,
  transfer_to_creditcard_co2e = 0, charity_co2e = 0)
transport_cats = c("fuel_co2e", "car_maint_co2e", "car_rent_co2e", "public_trans_co2e",
  "bus_co2e", "taxi_co2e", "train_bus_co2e", "aviation_co2e", "ferry_co2e",
  "escooter_co2e", "transport_other_co2e")
# Lifestyle focal multipliers (1 = unaffected): composed per person below.
mult = rep(1, length(base)); names(mult) = names(base)
mult_no_car = mult; mult_no_car[c("fuel_co2e", "car_maint_co2e", "car_rent_co2e", "vehicles_co2e", "taxi_co2e")] = 0.03
mult_no_flying = mult; mult_no_flying[c("aviation_co2e", "ferry_co2e")] = c(0, 0.30)
mult_no_meat = mult; mult_no_meat["groceries_co2e"] = 0.75

# Low-spend factor: the subgroup must fail DL's > 3000 SEK valid-month gate
# with the FULL metadata leaf set, so the scale is derived from the baseline
# basket (target ~2000 SEK/month of consumption) instead of a fixed 0.1 that
# would drift whenever a category is added. savings/transaction are left out of
# the basket because every project's spending gate excludes them.
low_spend_factor = 2000 / (sum(base[!names(base) %chin%
  c("savings_co2e", "transaction_co2e")]) / 12 * 75)

# Rent faults, chosen among respondents (the three cases of DL's 62 rule):
# never-rent; second-half rent missing (an interior fault under the relaxed
# rule); window-edge misses (first and last observed month only — stable
# under the relaxed rule, rent is paid in advance and straddles the edges).
never_rent = sample(aid[respondent], 64)
interior_rent = sample(setdiff(aid[respondent], never_rent), 10)
edge_rent = sample(setdiff(aid[respondent], c(never_rent, interior_rent)), 10)
# The low-spend subgroup (fails DL's > 3000 SEK valid-month gate) — drawn
# among respondents, likewise balanced against z (it scales EVERY category by
# low_spend_factor, so a seed correlation would tilt the whole outcome vector)
# — and the uncategorized share (low-carbon's gate is <= 10% over 12-month
# windows; five people sit above it).
repeat {
  low_spend = sample(aid[respondent], 40)
  if (abs(cor(z[respondent], aid[respondent] %chin% low_spend)) < 0.01) break
}
uncat_share = runif(n, 0.02, 0.08); names(uncat_share) = aid
uncat_share[sample(aid, 5)] = 0.15

# The no-bank-income fault: 15 respondents whose income arrives at an
# unlinked account — no salary AND no deposit rows (defined here so the
# transactions-hidden deposits in §6 can exclude them too).
no_income = sample(setdiff(aid[respondent], low_spend), 15)

# SEK per kg CO2e: ~75 for the average basket, but aviation is priced at
# its own ~10 SEK/kg (real ticket intensity ~0.1 kg CO2e/SEK). Without
# this, the aviation override below (aviation co2e := kr x 0.1366) would
# turn the average-basket aviation kr into a ~5-tonne/person blob; with it
# the override lands on realistic aviation footprints (~500-700 kg). The
# composition margin (the ratio falls with screen time) applies to all.
price_per_kg = rep(75, length(base)); names(price_per_kg) = names(base)
price_per_kg["aviation_co2e"] = 10
ooh_effect = (90 * (ooh_plant - mean(ooh_plant)) + rnorm(n, 0, 40)) / length(transport_cats)
inc_eff = (log1p(income_level) - mean(log1p(income_level))) * 150

grid = rbindlist(lapply(seq_len(n), function(i) {
  ms = c(seq(era1_start, era1_end, by = "month"),
    seq(obs$obs_start[i], obs$obs_end[i], by = "month"))
  g = CJ(month = ms, category = names(base))
  g[, aid := obs$aid[i]]
  hh = time[i]
  g[, y := base[category] + grad[category] * hh +
    inc_eff[i] * (category != "rent_co2e") * 0.3 +
    fifelse(category %chin% transport_cats, ooh_effect[i], 0)]
  g[, y := pmax(1, y + rnorm(.N, sd = 15))]
  g[, m_co2e := pmax(0, y / 12 * (1 + rnorm(.N, sd = 0.1)))]
  # SEK at ~75 SEK per kg CO2e, with the planted basket-composition
  # margin: the ratio falls with screen time, so at equal spending the
  # high-digital basket is slightly dirtier (DL 68 must recover it).
  g[, m_kr := pmax(50, m_co2e * price_per_kg[category] * (1 - 0.006 * (hh - 4)) + rnorm(.N, sd = 50))]
  # Lifestyle suppressions, composed as products of the focal multipliers.
  m = mult
  if (no_car[i] == 1) m = m * mult_no_car
  if (no_flying[i] == 1) m = m * mult_no_flying
  if (no_meat[i] == 1) m = m * mult_no_meat
  g[, m_co2e := m_co2e * m[category]]
  g[, m_kr := m_kr * m[category]]
  g
}))
setorder(grid, aid, month, category)

# Rent: no emissions factor (rent_co2e is all zeros in the real data); the
# kr value rides in the same row and takes the rent faults. month_i indexes
# each person's observed months (1 = first, k = last) for the fault rules.
grid[category == "rent_co2e", m_co2e := 0]
grid[, month_i := match(month, sort(unique(month))), by = aid]
grid[, last_i := max(month_i), by = aid]
grid[, is_rent := category == "rent_co2e"]
grid[, rent_kr := fifelse(is_rent, m_kr, 0)]
grid[is_rent == TRUE, m_kr := 0]
grid[is_rent == TRUE & aid %chin% never_rent, rent_kr := 0]
grid[is_rent == TRUE & aid %chin% interior_rent & month_i > ceiling(last_i / 2), rent_kr := 0]
grid[is_rent == TRUE & aid %chin% edge_rent & (month_i == 1 | month_i == last_i), rent_kr := 0]

# Transfers and donations carry a kr flow but no emission factor — the same
# convention load_common_data.R and low-carbon's 20_filter_data.R apply (rent
# is zero for the same reason). Their kr levels survive, so the projects'
# exclusion lists have something to exclude.
grid[category %chin% c("savings_co2e", "transaction_co2e",
  "transfer_to_creditcard_co2e", "charity_co2e"), m_co2e := 0]

# The low-spend subgroup: low_spend_factor of everything (rent and kr
# included — DL's valid-month gate is on KR, so scaling only the co2e side
# left the group passing it), fails the valid-month spending gate.
grid[aid %chin% low_spend, `:=`(m_co2e = m_co2e * low_spend_factor,
  m_kr = m_kr * low_spend_factor, rent_kr = rent_kr * low_spend_factor)]

# Uncategorized (kr plus a co2e mirror at average basket intensity, 75
# SEK/kg): a per-person share of the month's consumption kr, straddling
# the low-carbon filter threshold for a few.
consumption_kr = grid[is_rent == FALSE &
  !category %chin% c("savings_co2e", "transaction_co2e"),
  .(cons_kr = sum(m_kr)), by = .(aid, month)]
grid[consumption_kr, on = .(aid, month), cons_kr := i.cons_kr]
grid[, uncat_kr := fifelse(is_rent, 0, cons_kr * uncat_share[aid])]
grid[, uncat_co2e := uncat_kr / 75]

# ---------------------------------------------------------------------------
# 6. Transactions (wide, one row per aid x date, daily category aggregates)
# ---------------------------------------------------------------------------
# The delivered dta has NO sub-day detail: for privacy, all transactions of
# one category on one day are summed before delivery. Plants start as sub-day
# rows (so the monthly cells and the split cap are unchanged), then the
# privacy transform sums them into (aid, date, category) cells before the
# dcast, so each wide _kr/_co2e column is a daily category total and a
# typical row has several populated columns. Big monthly cells are split
# across distinct days within their (aid, month, category), so a daily
# category cell stays <= 1200 SEK — the de-collision rule. Zero cells
# (rent faults, suppressed lifestyles) produce no row; the monthly
# melt-then-sum treats absent zeros identically to zero rows.
cells = rbindlist(list(
  grid[is_rent == FALSE & m_kr > 0, .(aid, month, stem = sub("_co2e$", "", category), kr = m_kr, co2e = m_co2e)],
  grid[is_rent == TRUE & rent_kr > 0, .(aid, month, stem = "rent", kr = rent_kr, co2e = 0)],
  # uncategorized is planted per person-month (one value shared by the
  # category rows), so collapse to one cell per (aid, month) before splitting
  grid[is_rent == FALSE & uncat_kr > 0,
    .(stem = "uncategorized", kr = max(uncat_kr), co2e = max(uncat_co2e)),
    by = .(aid, month)],
  # da_credit: the ONLY kr leaf without a co2e mirror in the delivered data
  # (data/common-data.md §9.19). Planted kr-only at a fixed 2% of the
  # person-month's consumption — deterministic, so it adds no RNG draws of its
  # own; the dcast's da_credit_co2e column is dropped below.
  grid[is_rent == FALSE & cons_kr > 0,
    .(stem = "da_credit", kr = 0.02 * max(cons_kr), co2e = 0),
    by = .(aid, month)]))
cells[, k := pmax(1L, ceiling(kr / 1200))]
cells = cells[rep(seq_len(.N), k)]
cells[, row_i := rowid(aid, month, stem)]
cells[, day := sample(1:28, .N), by = .(aid, month, stem)]
cells[, w := kr / k]
cells[row_i == k, w := kr - (k - 1) * kr / k]
tx_long = cells[, .(aid, date = as.Date(format(month)) + day,
  category = stem, kr = w, co2e = co2e * w / kr)]

# Tax deposits hidden in the transactions source (the in_transactions
# scenario): negative exclude_kr daily cells. Now INERT: the matcher searches
# only daily_income, so these person-years are informative non-matches that
# exercise the income-only rule. Still planted inside the observation window.
dep_tx = tax_iot[scenario == "in_transactions"][
  , .(aid, date = as.Date(paste0(tax_year + 1, "-06-", sample(8:20, .N, replace = TRUE))),
      category = "exclude", kr = -as.numeric(true_refund), co2e = 0)]
dep_tx = dep_tx[obs, on = "aid"][date >= obs_start & date <= obs_end,
  .(aid, date, category, kr, co2e)]
dep_tx = dep_tx[!aid %chin% no_income]
tx_long = rbind(tx_long, dep_tx)

# Privacy transform, then one wide row per aid x date.
tx_daily_long = tx_long[, .(kr = sum(kr), co2e = sum(co2e)),
  by = .(aid, date, category)]
tx_kr = dcast(tx_daily_long[, .(aid, date, category, kr)],
  aid + date ~ category, value.var = "kr", fill = 0)
tx_co2e = dcast(tx_daily_long[, .(aid, date, category, co2e)],
  aid + date ~ category, value.var = "co2e", fill = 0)
# da_credit is kr-only in the delivered dta: drop the co2e column the dcast
# creates, so the mock carries exactly 66 _kr and 65 _co2e columns.
tx_co2e[, da_credit := NULL]
kr_names = setdiff(names(tx_kr), c("aid", "date"))
co2e_names = setdiff(names(tx_co2e), c("aid", "date"))
setnames(tx_kr, kr_names, paste0(kr_names, "_kr"))
setnames(tx_co2e, co2e_names, paste0(co2e_names, "_co2e"))
transactions = tx_kr[tx_co2e, on = c("aid", "date")]
setorder(transactions, aid, date)

# The canonical aviation emission-intensity override: the real-data loader
# load_common_data.R applies this to the dta's aviation co2e — 0.08 kg
# CO2/pkm combustion, 1.5 non-CO2 uplift, 20% upstream, 0.82 SEK/pkm ticket
# price => aviation co2e := aviation kr * ~0.166 — and the mock applies the
# IDENTICAL adjustment here so every pipeline's mock matches its real
# loader. The factor is computed in the same two-step form as the loader
# (assigned before multiplying). Deterministic post-processing: no RNG draws,
# so every other planted value is unchanged. no_flying zeroes aviation kr
# exactly, so adopters' aviation co2e stays EXACTLY zero — the derivation in
# low-carbon's 30_stat_vars depends on it.
aviation_co2e_per_sek = (0.08 * 1.5 + 0.08 * 0.20) / 0.82
transactions[, aviation_co2e := aviation_kr * aviation_co2e_per_sek]

# ---------------------------------------------------------------------------
# 7. Daily income (incoming transactions) and derived income views
# ---------------------------------------------------------------------------
# Salary: one row per person-month inside the observation window, base
# 23,000-30,000 SEK with small monthly noise (the de-collision rule), a
# fractional part for realism. 15 respondents have no income rows at all
# (income paid to an unlinked account; DL's income_bank control carries NA
# for them and model_missingness shows it).
salary_base = 23000 + 7000 * runif(n)
sal_base = data.table(aid, salary_base)
sal = CJ(aid = aid, month = seq(era1_start, as.Date("2024-12-01"), by = "month"))[
  obs, on = "aid", nomatch = 0][month >= obs_start & month <= obs_end]
sal = sal[!aid %chin% no_income]
sal[, date := month + sample(0:25, .N, replace = TRUE)]
sal[sal_base, on = "aid", sb := i.salary_base]
sal[, income := round(sb * (1 + 0.015 * rnorm(.N))) + 0.37]
sal[, category := "salary"]

# Deposits (the tax plants): one month per scenario, covering all four
# Skatteverket-scheduled payout months 04/06/08/12. `late_oct` deliberately
# plants an October deposit that month-10 removal makes UNSEARCHED (an
# informative non-match). Deposits only inside the observation window; amounts
# follow the drift/ambiguous tier ladder. `near_zero` has NO deposit.
dep = tax_iot[scenario %chin% c("early_april", "clean_june", "late_aug", "late_oct", "late_dec",
  "drift_relative", "drift_suspected", "ambiguous")]
dep[, month_n := fcase(
  scenario == "early_april", 4L,
  scenario %chin% c("clean_june", "drift_relative", "drift_suspected", "ambiguous"), 6L,
  scenario == "late_aug", 8L,
  scenario == "late_oct", 10L,
  default = 12L)]
dep[, date := as.Date(paste0(tax_year + 1, "-", month_n, "-", sample(5:25, .N, replace = TRUE)))]
dep[, amount := as.numeric(true_refund)]
dep[scenario == "drift_relative", amount := round(true_refund * 1.004, 2)]
dep[scenario == "drift_suspected", amount := round(true_refund * 1.03, 2)]
dep = dep[obs, on = "aid"][date >= obs_start & date <= obs_end]
refund_rows = dep[, .(aid, date, category = "other", income = amount)]
# The ambiguous people also get a second, worse candidate in August (+2%)
# so the best-match rule has a double candidate to resolve.
amb_rows = dep[scenario == "ambiguous"][
  , .(aid, date = as.Date(paste0(tax_year + 1, "-08-", sample(5:25, .N, replace = TRUE))),
      category = "other", income = round(true_refund * 1.02, 2))]
amb_rows = amb_rows[obs, on = "aid"][date >= obs_start & date <= obs_end,
  .(aid, date, category, income)]
# The no-income fault must stay pure: people with no salary rows get no
# deposit rows either, so their person_bank is absent entirely (DL's
# income_bank NA path) instead of being carried by one refund. Their
# person-years simply read as informative no_match.
refund_rows = refund_rows[!aid %chin% no_income]
amb_rows = amb_rows[!aid %chin% no_income]
# Income rows for aids outside the study linkage, as in the real export.
outside_rows = data.table(aid = paste0("efid_out_", 1:12),
  date = as.Date("2023-06-15"), category = "other", income = 4321.21)

daily_income = rbind(sal[, .(aid, date, category, income)], refund_rows, amb_rows, outside_rows)

# Derived income views (derivations, not new plants): the monthly long view
# (low-carbon's monthly_incomes) and the person-level bank income (DL's
# bank_income.parquet: mean monthly inflow and month count — deposits
# count as inflows, as in the real kk-income export).
monthly_incomes = daily_income[, .(income = sum(income, na.rm = TRUE)),
  by = .(aid, date = as.Date(format(date, "%Y-%m-01")), category)]
person_bank = monthly_incomes[, .(income_bank_raw = mean(income, na.rm = TRUE),
  n_bank_months = .N), by = aid]

# ---------------------------------------------------------------------------
# 8. Monthly cache views of the transactions table (DL's loader recipe)
# ---------------------------------------------------------------------------
kr_cols = grep("_kr$", names(transactions), value = TRUE)
co2e_cols = grep("_co2e$", names(transactions), value = TRUE)
transactions[, month := as.Date(format(date, "%Y-%m-01"))]
monthly_kr = melt(transactions, id = c("aid", "month"), measure.vars = kr_cols,
  variable.name = "category", value.name = "kr", variable.factor = FALSE)
monthly_kr = monthly_kr[, .(kr = sum(kr, na.rm = TRUE)), by = .(aid, month, category)]
monthly_co2e = melt(transactions, id = c("aid", "month"), measure.vars = co2e_cols,
  variable.name = "category", value.name = "co2e", variable.factor = FALSE)
monthly_co2e = monthly_co2e[, .(co2e = sum(co2e, na.rm = TRUE)), by = .(aid, month, category)]
transactions[, month := NULL]

# ---------------------------------------------------------------------------
# 8b. Tax-return spending & kvarskatt payment plants (appended after §8 so
#     the RNG stream of §§1-8 and DL's monthly_kr/monthly_co2e are untouched)
# ---------------------------------------------------------------------------
# 1. Outgoing kvarskatt payments in transactions (positive exclude_kr daily cells):
#    75% of kvarskatt person-years pay in a single lump sum in May/June/Sep/Oct
#    inside their observation window. Now INERT for identification: back-tax
#    person-years are classified from the register alone, so these cells only
#    exercise the "no settlement is searched in the dta" path. True kvarskatt
#    is in [-15000, -7000], so it stays negative on all 6 refund definitions
#    and outside the <= 1200 SEK ordinary-transaction range.
kvar_plan = tax_iot[scenario == "kvarskatt" & !aid %chin% c(no_income, no_bank_aid)]
kvar_plan[, kvar_idx := seq_len(.N)]
kvar_plan = kvar_plan[kvar_idx %% 4L != 0L]
kvar_plan[, month_n := rep(c(5L, 6L, 9L, 10L), length.out = .N)]
kvar_plan[, day_n := rep(8:19, length.out = .N)]
kvar_plan[, date := as.Date(sprintf("%d-%02d-%02d", tax_year + 1L, month_n, day_n))]
kvar_plan = kvar_plan[obs, on = "aid", nomatch = 0][date >= obs_start & date <= obs_end]
kvar_tx_long = kvar_plan[, .(aid, date, category = "exclude",
  kr = as.numeric(abs(true_refund)), co2e = 0)]

# 2. Post-refund spending spike in [0..7] and [8..30] days after dep_date,
#    moderated by ESI (esi_latent) and by payout month (June -> summer
#    travel/aviation; Aug/Oct/Dec -> electronics/clothing/home durables).
#    Every planted sub-day row stays <= 1150 SEK (below the 1200 SEK
#    de-collision cap) and respects no_flying (aviation == 0 for adopters).
person_meta = data.table(aid = aid, esi_l = esi_latent, nf = no_flying, nc = no_car)
dep_events = rbind(
  dep[!aid %chin% no_income, .(aid, tax_year, dep_date = date,
    refund_amt = amount, month_n = as.integer(month_n))],
  dep_tx[, .(aid, tax_year = as.integer(format(date, "%Y")) - 1L,
    dep_date = date, refund_amt = -kr, month_n = 6L)]
)
dep_events = dep_events[obs, on = "aid", nomatch = 0][
  dep_date >= obs_start & dep_date <= obs_end & dep_date < invite_date]
dep_events = person_meta[dep_events, on = "aid"]
dep_events[, scale_ref := pmin(1.25, pmax(0.75, 0.70 + 0.30 * (refund_amt / 10000)))]

# Build planted post-refund purchase rows per event (all rows <= 1150 SEK).
post_rows_list = lapply(seq_len(nrow(dep_events)), function(idx) {
  ev = dep_events[idx]
  s = ev$scale_ref
  e = ev$esi_l
  is_june = ev$month_n == 6L

  if (is_june) {
    # June refund: summer travel/charter spike; high ESI shifts from aviation to train/sports
    av_amt = if (ev$nf == 1L) 0 else pmin(1150, round(pmax(30, (340 - 145 * e) * s), 2))
    tr_amt = pmin(1150, round(pmax(50, (290 - 45 * e) * s), 2))
    tb_amt = pmin(1150, round(pmax(30, (160 + 100 * e) * s), 2))
    re_amt = pmin(1150, round(pmax(40, 180 * s), 2))
    sp_amt = pmin(1150, round(pmax(30, (130 + 75 * e) * s), 2))
    el_amt = pmin(1150, round(pmax(25, (80 - 15 * e) * s), 2))
    cl_amt = pmin(1150, round(pmax(25, 85 * s), 2))
    hg_amt = pmin(1150, round(pmax(20, 65 * s), 2))
    sv_amt = pmin(1150, round(pmax(80, (320 + 60 * e) * s), 2))
  } else {
    # Aug/Oct/Dec refund: autumn retail/durables/home spike instead of summer charter trips
    av_amt = if (ev$nf == 1L) 0 else pmin(1150, round(pmax(0, (40 - 25 * e) * s), 2))
    tr_amt = pmin(1150, round(pmax(15, 50 * s), 2))
    tb_amt = pmin(1150, round(pmax(20, (80 + 55 * e) * s), 2))
    re_amt = pmin(1150, round(pmax(40, 165 * s), 2))
    sp_amt = pmin(1150, round(pmax(30, (135 + 75 * e) * s), 2))
    el_amt = pmin(1150, round(pmax(80, (330 - 70 * e) * s), 2))
    cl_amt = pmin(1150, round(pmax(70, (280 - 45 * e) * s), 2))
    hg_amt = pmin(1150, round(pmax(60, 260 * s), 2))
    sv_amt = pmin(1150, round(pmax(90, (360 + 70 * e) * s), 2))
  }

  # Spread rows across [0..7] days (offsets 1..6) and [8..30] days (offsets 10..24),
  # plus small baseline/pre/post financial-transfer rows in exclude_kr (offsets -35, -18, -4, 3, 14, 42).
  b_sv1 = round(pmax(40, 120 * s + 18 * e), 2)
  b_sv2 = round(pmax(40, 140 * s - 12 * e), 2)
  b_sv3 = round(pmax(20, 45 * s + 8 * e), 2)
  b_sv4 = round(pmax(30, 80 * s + 10 * e), 2)
  rows = data.table(
    aid = ev$aid,
    date = ev$dep_date + c(1L, 2L, 4L, 11L, 18L,
                           1L, 3L, 12L, 20L,
                           2L, 5L, 14L,
                           3L, 6L, 15L,
                           4L, 16L,
                           2L, 5L, 13L, 21L,
                           3L, 17L,
                           6L, 19L,
                           7L, 22L,
                           -35L, -18L, -4L, 3L, 14L, 42L),
    category = c(rep("aviation", 5),
                 rep("travel", 4),
                 rep("train_bus", 3),
                 rep("restaurant", 3),
                 rep("sports", 2),
                 rep("electronics", 4),
                 rep("clothing", 2),
                 rep("home_garden_other", 2),
                 rep("shopping_other", 2),
                 rep("exclude", 6)),
    kr = c(rep(av_amt, 5),
           rep(tr_amt, 4),
           rep(tb_amt, 3),
           rep(re_amt, 3),
           rep(sp_amt, 2),
           rep(el_amt, 4),
           rep(cl_amt, 2),
           rep(hg_amt, 2),
           rep(hg_amt, 2),
           b_sv1, b_sv2, b_sv3, sv_amt, sv_amt, b_sv4)
  )
  rows = rows[kr > 0 & date >= ev$obs_start & date <= ev$obs_end & date < ev$invite_date]
  rows[, co2e := fifelse(category == "exclude", 0,
    fifelse(category == "aviation",
      kr * aviation_co2e_per_sek,
      kr / price_per_kg[paste0(category, "_co2e")]))]
  rows
})
post_tx_long = rbindlist(post_rows_list)

# Small routine financial-transfer rows around kvarskatt dates (all <= 300 SEK,
# well below the >= 7000 SEK kvarskatt match band) so Financial_flows has
# non-zero variance in kvarskatt windows too.
kvar_fin_list = lapply(seq_len(nrow(kvar_plan)), function(idx) {
  kv = kvar_plan[idx]
  s_kv = as.numeric(abs(kv$true_refund)) / 10000
  d_kv = data.table(
    aid = kv$aid,
    date = kv$date + c(-30L, -15L, -3L, 4L, 16L, 40L),
    category = "exclude",
    kr = round(c(110, 130, 35, 95, 105, 85) * (0.75 + 0.25 * s_kv), 2),
    co2e = 0
  )
  d_kv[date >= kv$obs_start & date <= kv$obs_end & date < kv$invite_date]
})
kvar_fin_long = rbindlist(kvar_fin_list)

# A planted settlement must be the only (net) flow in its category-day cell:
# the delivered data cannot separate it from other same-day flows in the same
# category. Keep the small routine exclude transfers off settlement dates.
settlement_dates = unique(rbind(dep_tx[, .(aid, date)], kvar_tx_long[, .(aid, date)]))
settlement_keys = paste(settlement_dates$aid, settlement_dates$date)
kvar_fin_long = kvar_fin_long[!paste(aid, date) %chin% settlement_keys]
post_tx_long = post_tx_long[!(category == "exclude" &
  paste(aid, date) %chin% settlement_keys)]
extra_tx_long = rbind(kvar_tx_long, kvar_fin_long, post_tx_long)

# Same privacy transform for the appended plants: one wide row per aid x
# date. These rows share (aid, date) keys with the §6 daily table, so their
# cells are ADDED, not stacked as extra rows.
extra_daily_long = extra_tx_long[, .(kr = sum(kr), co2e = sum(co2e)),
  by = .(aid, date, category)]
extra_kr = dcast(extra_daily_long[, .(aid, date, category, kr)],
  aid + date ~ category, value.var = "kr", fill = 0)
extra_co2e = dcast(extra_daily_long[, .(aid, date, category, co2e)],
  aid + date ~ category, value.var = "co2e", fill = 0)
extra_kr_names = setdiff(names(extra_kr), c("aid", "date"))
extra_co2e_names = setdiff(names(extra_co2e), c("aid", "date"))
setnames(extra_kr, extra_kr_names, paste0(extra_kr_names, "_kr"))
setnames(extra_co2e, extra_co2e_names, paste0(extra_co2e_names, "_co2e"))
extra_wide = extra_kr[extra_co2e, on = c("aid", "date")]
for (col in setdiff(names(transactions), names(extra_wide))) {
  extra_wide[, (col) := 0]
}
setcolorder(extra_wide, names(transactions))
transactions = rbind(transactions, extra_wide)
day_cols = setdiff(names(transactions), c("aid", "date"))
transactions = transactions[, lapply(.SD, sum, na.rm = TRUE),
  by = .(aid, date), .SDcols = day_cols]
setorder(transactions, aid, date)

# ---------------------------------------------------------------------------
# 8c. Harmonized long core (identical full melt to load_common_data.R)
# ---------------------------------------------------------------------------
# The generator must emit the SAME objects the real loader leaves behind:
# one row per aid x date x category (stem), kr + co2e, plus month. Attach
# month to the wide table first (CODING-GUIDELINES §4), then melt once.
transactions[, month := trunc.Date(date, "months")]
gen_kr_cols = grep("_kr$", names(transactions), value = TRUE)
gen_co2e_cols = grep("_co2e$", names(transactions), value = TRUE)
gen_kr_long = melt(transactions[, c("aid", "date", "month", gen_kr_cols), with = FALSE],
  id.vars = c("aid", "date", "month"), measure.vars = gen_kr_cols,
  variable.name = "category", value.name = "kr", variable.factor = FALSE)
gen_co2e_long = melt(transactions[, c("aid", "date", "month", gen_co2e_cols), with = FALSE],
  id.vars = c("aid", "date", "month"), measure.vars = gen_co2e_cols,
  variable.name = "category", value.name = "co2e", variable.factor = FALSE)
gen_kr_long[, category := sub("_kr$", "", category)]
gen_co2e_long[, category := sub("_co2e$", "", category)]
transactions_long = merge(gen_kr_long, gen_co2e_long,
  by = c("aid", "date", "month", "category"), all = TRUE)
setcolorder(transactions_long, c("aid", "date", "month", "category", "kr", "co2e"))
setorder(transactions_long, aid, date, category)
transactions[, month := NULL]

# ---------------------------------------------------------------------------
# 9. Self-documentation
# ---------------------------------------------------------------------------
mock_plants = data.table(
  object = c("survey", "survey", "survey_endline", "survey_endline",
    "monthly_*", "monthly_*", "monthly_*", "monthly_*", "transactions",
    "users/scb", "tax_iot", "tax_iot", "daily_income", "users",
    "sampling_frame", "transactions", "transactions", "transactions", "transactions", "transactions"),
  plant = c("q11 battery rises with z; 20 partial batteries",
    "ESI items from an independent latent",
    "E4 screen time ~ 1.2 h per index SD; opt-out classes",
    "E1 out-of-home falls / at-home rises with z",
    "screen-time gradients per category (transport negative, goods positive, placebos zero)",
    "income confound (log income x 150, 0.3 on non-rent)",
    "leisure->transport mediation (90 kg/SD spread over transport cats)",
    "SEK-per-kg ratio falls with screen time (composition margin)",
    "lifestyle focal suppression (no_car/no_flying/no_meat); rent faults; low-spend subgroup; aviation co2e overridden to kr x ~0.166",
    "DispInk04 in 100-SEK units; education 999 for a few; demographics duplicates",
    "refund scenarios x person-year: April/June/Aug/December scheduled deposits, unsearched-October deposit, transactions-hidden deposit, no_match, ambiguous double candidate, near-zero settlements (<100 SEK, both signs, NO deposit), kvarskatt in [-15000, -7000]",
    "year-varying register columns; SRED magnitudes reduced for de-collision",
    "deposits in the four scheduled months; salaries >= 22.6k; out-of-study aids; 15 without income rows",
    "diet label aligned with no_meat; aviation exactly zero for no_flying",
    "invited participants + non-linked frame members",
    "pre-COVID era 2019-01..2020-02 with a hole over 2020-03..2021-03",
    "outgoing kvarskatt payments in exclude_kr (inert: income-only matcher; exercises the no-settlement-searched path)",
    "post-refund spending spikes in [0..7] and [8..30] days moderated by ESI and payout month (June travel vs April/Aug/Oct/Dec retail)",
    "sub-day transactions summed to daily category aggregates (one row per aid x date, several populated columns)",
    "DiD: treated spikes vs near-zero controls with NO planted spike (zero control response), all-dates placebo dates across all 3 seasons"))
message("Shared mock built: ", n, " participants (", sum(respondent),
  " survey respondents), ", nrow(tax_iot), " tax-register rows, ",
  nrow(transactions), " daily transaction rows, ", nrow(daily_income),
  " income rows, ", nrow(sampling_frame), " frame rows. Planted effects: see mock_plants. De-collision cap check: ",
  "max ordinary daily category cell ",
  round(max(tx_daily_long[category != "exclude", kr])), " SEK (cap 1200).")

rm(list = setdiff(ls(), c(preexisting, "linkage", "demographics", "users", "survey", "survey_invite",
  "sampling_frame",
  "survey_endline", "scb", "tax_iot", "daily_income", "transactions", "transactions_long", "monthly_kr",
  "monthly_co2e", "person_bank", "monthly_incomes", "mock_plants")))
