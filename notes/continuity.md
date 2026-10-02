# Continuity notes — Digital lifestyles paper

Read this first each session. Keep it updated: decisions, open questions, next steps.
(Newest entries at top within each section.)

## Status

- **2026-08-21 — MAJOR UNBLOCK.** David supplied the questionnaires + baseline
  codebook (now in `docs/`): `Pre-treatment_survey.pdf` + `_codebook.csv`
  (baseline), `Endline_survey.pdf`, `WP1_digital_lifestyles_plan_abstract_OSF.docx`
  (extended abstract; canonical text in `notes/extended_abstract.md`).
  All July mysteries resolved:
  - **q11_1–q11_5+** = device-use frequency battery, 1–6 scale ("Ej använt" …
    "Flera gånger i timmen"): stationär/bärbar dator, mobiltelefon/smartphone,
    TV, spelkonsol, surfplatta. → the *device-use* half of the digital index.
  - **q11b_1–q11b_8** = digital-activity frequency battery, same scale:
    film/serier/YouTube, telefon-/videosamtal, sociala medier, informationssökning,
    dataspel/tv-spel, digital läsning, **e-handel (q11b_7)**, sålt online (q11b_8).
    → the *digital-activity* half of the index; q11b_7 also feeds the
    e-commerce decomposition channel.
  - **q15_1–q15_12** = typical-price battery (SEK for haircut, sneakers, wine,
    hotel night, phone, sofa, …) — confirms July's inference: spending estimates,
    NOT time use. Not part of the digital index (candidate quality-of-consumption
    control at most).
  - **Endline E4** = screen-time anchor exactly as remembered: device-assisted
    (iOS Skärmtid / Android Digitalt välmående), average daily h:min previous
    week, with "not activated" and "skip" opt-outs (expect missingness; the
    mock endline generator's opt-out share should be calibrated).
  - **Endline E1** = 12-month activity-frequency battery (7-point) incl.
    out-of-home leisure (bibliotek, idrottsevenemang, kulturevenemang, middag,
    dansat, motionerat, naturen) and at-home digital leisure (ljudbok, musik,
    bok, film, tv-serie) → the *mechanism* variables for result 3, plus BNPL item.
  - Endline also has: policy-attitude batteries (B1–B6), WTP for CO2 reduction
    (K1–K2), app-experience battery (L1–L3), attention check (C11).
- **Team/venue (2026-08-21):** Mathias Lehner (decided), Göran Finnveden (maybe),
  Anna Furberg (possibly). Venue undecided, aim high. **Pre-registration on OSF
  required before touching real data in the TRE** — the abstract already commits
  to a "pre-registered index".
- **2026-07-18 (evening)** Screen-time item IDENTIFIED by David: **E4 in the ENDLINE
  survey** — device-assisted ("Skärmtid"/iOS, "Digitalt välmående"/Android), average
  DAILY screen time in hours:minutes for the previous week. Confirmed the endline
  survey is NOT in the local mock RData (survey object = baseline only, no E* cols).
  No endline codebook found either. => For local development, generate a synthetic
  endline E4; real validity check runs in the TRE.
- **2026-07-18 (later)** First validity run DONE — with a twist. The q15_* battery is
  almost certainly NOT time use: medians 1,000–7,000, maxima up to 200,000, ~60–90%
  of answers above 16 h/day if read as minutes. Signature = **SEK/month spending
  estimates** (consistent with archived Rmd deriving `health_spending`/`saving_exp`
  from the survey). `q12b` also ruled out: 0–100 with heaping at 25/50/75 and answered
  only when q12 ∈ {2,4} ⇒ a percentage follow-up. `q13`/`q14` are 0–7 counts with ~no
  age gradient. **Conclusion: the screen-time anchor cannot be identified from the mock
  data empirically — blocked on the questionnaire/codebook.** Also note: mock values may
  be scrambled/synthetic, so distributional signatures are suggestive, not proof.
- **2026-07-18** Project scaffolded. First analysis = screen-time validity check
  (`10_screen_time_validity.R`). Data source confirmed: the *local mock*
  `../Konsumtionskollen/default_filter.RData` (5.2 GB) has the full 114-column survey
  incl. the `q15_*` minutes battery — unlike the small synthetic generator
  (`generate_synthetic_data.R`), which only has the 3 ESI items and is NOT sufficient
  for this paper.

## Key decisions

- Project lives in `Digital-lifestyles/` inside the outer manuscript folder; own git repo.
- Reuse Konsumtionskollen data by path, never copy the 5.2 GB file into this repo.
- Light extract cached to `cache/digital_cache.RData` so sessions don't pay the 5-GB load.
- Follow Konsumtionskollen conventions (numbered scripts, P99 winsorization, HC3 SEs).

## Parked ideas

- **2026-08-21 — COVID-recovery event study (digital use × re-socialization).**
  Candidate second paper (do NOT fold into the carbon paper): does digital
  intensity predict slower recovery of out-of-home social spending
  (café/restaurant/bar transactions) after the pandemic shock? Design: person
  fixed effects absorb stable traits (incl. "sad people end up alone with their
  phone" selection); shared shock forces re-optimization; identifying variation
  is within-person recovery speed 2022–2024. Validity check: gradient in
  *pre-COVID* social spending should be ~flat. Triangulate transaction-based
  social spending against endline E1 self-reported social activities and
  wellbeing items (kills common-method-variance critique). Caveat: café spend
  conflates social and solo consumption — bound with E1. Pre-registrable as a
  separate exploratory analysis. Open thought (DA): use the event study to
  "understand something relevant" beyond the gradient — e.g., whether digital
  substitution is a persistent lifestyle shift vs. transitory habit.

## Open questions / blockers

1. **Endline survey data + codebook.** E4 (screen time) identified, but the endline
   survey is absent from the local mock and no endline codebook exists locally.
   Needed: (a) endline data extract in the TRE (or a mock thereof), (b) codebook for
   the remaining endline items (device-use / digital-activity frequencies for the
   index; out-of-home leisure frequency for the mechanism). Also unclear how E4 is
   stored (single minutes field vs separate hours+minutes fields) — loader must parse
   h:mm robustly.
2. Endline timing caveat for the paper: screen time measured at ENDLINE, consumption
   observed 2019–2024 — note reverse-causality/stability argument in design section.
2. Swedish screen-time benchmarks in `10_screen_time_validity.R` are heuristic bands;
   verify against Internetstiftelsen *Svenskarna och internet* (latest edition) and any
   device-measured Swedish studies before using in the paper.
3. Mock data caveat: values in `default_filter.RData` are **partly scrambled real
   values** (confirmed by DA 2026-08-24, resolving the July uncertainty) — validity
   *checks logic* here; substantive conclusions wait for the TRE run. Prereg
   disclosure worded accordingly ("de-identified development extract, partly
   scrambled").
4. Category mapping for the decomposition (which leaf categories count as
   e-commerce-intensive / digital services / placebo) — draft lives in `00_constants.R`,
   needs a documented justification for the paper.

## Next steps

1. Generate synthetic endline (`gen_mock_endline.R`): E4 minutes/day with realistic
   age gradient + h:mm heaping, so the validity + index pipeline can be developed.
2. Locate the real endline data in the TRE (object/file name unknown) and its codebook.
3. Re-point `10_screen_time_validity.R` at endline E4; verify benchmark bands against
   Internetstiftelsen *Svenskarna och internet*.
4. Build digital intensity index (`20_digital_index.R`): device-use + digital-activity
   frequencies, anchored cardinally by screen time; report reliability (alpha).
5. Net gradient models, then decomposition, then mechanism (see README pipeline table).
6. Set up TRE export checklist (mirror `Konsumtionskollen/RUN_TRE` pattern).

## Session log

- **2026-09-25 — New 64_tenure_lifestage.R (tenure/life-stage confound).**
  Student/apartment/carless composition as alternative explanation for the
  headline: descriptives by digital quintile (tenure_desc.csv, long format
  so unlisted hometype/FamTypF/Civil codes need no assumptions), M5 vs
  M5+tenure sensitivity on total/transport/ecom/restaurant
  (tenure_sensitivity.csv, shared complete-case sample), and
  stratification falsification student/BostBidr-recipient/carless on
  total/transport/ecom (tenure_strat.csv, strata n < 30 skipped).
  Register inputs (HuvInkKallaAlt/StudDelt/BostBidrFam/ArbSok*) wired in
  10_load_data.R from JE_Lev_LISA_2023.txt (SCB rebuild is cheap);
  hometype+ncars from users_latest. Mock plants all fields + tilts
  (young study, city apartments/carless); full RUN_MOCK (now 20–64)
  clean, outputs behave as planted. Apartment-vs-villa split deferred:
  64 never assumes hometype levels — the desc table from the first TRE
  run reveals the real labels, then the split can be added. README
  ranges updated (20–64).

- **2026-09-24 — Full-range review (20–61) + fixes.** Reviewed the whole
  pipeline end-to-end against the guidelines. All fixes mock-verified via the
  extended RUN_MOCK (now mirrors RUN_TRE through 62):
  - **46:** age bands were built from the raw `demographics` table,
    which has duplicate rows for some aids — every `aid_dup` person in the M5
    sample was double-counted in the heterogeneity models (mock: 745 vs 726
    rows). Now uses `demographics_unique` (raw age preserved). The 46
    estimates in het_margins.csv will shift slightly at the next TRE run;
    het_margins.csv gained an n column so the fix is verifiable in TRE
    output (n must equal the M5 n, 4,195).
  - **RUN_MOCK stopped at 55** — 56–61 never locally tested; extended to 61
    (all run clean on mock).
  - **44:** removed stale `placebo_rent` from the pres-decomp `show` vector
    (43 no longer emits that category).
  - **Rent relabeled per the 2026-09-24 tenure decision:** target renamed
    `placebo_rent` → `rent` in 47, label now "Rent (housing tenure)"
    (05_labels); 20's comment updated; `placebo_co2e` (20) is now actually
    used by 43/52 instead of a hardcoded string.
  - **56:** no longer mutates `analysis_data` (deso sizes computed in a
    separate table and joined); reporting values unchanged.
  - **52:** removed dead `index` column from the category-model `base`.
  - **per-SD columns everywhere (user request 2026-09-25):** `per_sd`
    (= estimate × `h_per_sd`, the single M5-sample definition from 40) added
    to het_margins (46), coverage_check (49), ecommerce_quintile (50),
    age_spline_rq1 (53), the three E1 tables (55), het_interactions (58).
    Full RUN_MOCK pass clean. Deliberately skipped: 52 (E4 rows; exposure
    is measured hours, so per-index-SD is undefined — the SD-scaled
    comparison lives in 60 with its own documented per-own-SD convention)
    and 54 (exposures are already item-SDs). 42/43/47/50-main/56/57/62
    and the 48/59/60/61 SD versions already had it. Regenerates in TRE.
    2026-09-25 pm: backfilled per_sd into the 8 TRE-export CSVs locally
    (/tmp/add_per_sd.R, since deleted) by rescaling the exported estimates
    with the run's own h_per_sd = 0.3168007 — values verified, column order
    matches script output.
  - **New 63_transport_split.R** (short- vs long-distance transport):
    buckets defined in 20 (single-source-of-truth rule) — short = fuel,
    car_maint, public_trans, bus, taxi, train_bus, escooter; long =
    aviation, ferry; ambiguous = car_rent, transport_other (exhausts the
    transport composite). M5 gradients for all three buckets plus the WFH
    with/without mediation on short (should attenuate) and long (should
    not — specificity check), same shared-sample design as 55 →
    transport_split.csv. Mock-verified in the full RUN_MOCK pass (short
    negative, long positive, as planted). README ranges updated (20–63).
    Rides the next TRE run.
  - **Commute-field diagnostic in 63 (user-approved 2026-09-25):**
    users-table profile fields (commute_distance/public/bike/car) are
    candidates for testing demobilization-via-commute on the full M5
    sample — but as mechanism/descriptive, NOT as M5 controls
    (downstream of the lifestyle → over-control risk). First step is
    coverage: commute_diag.csv reports n/share non-missing + means in M5.
    Mock plants the four fields (city-tilted distance with 5% NA, mode
    dummies); mock M5 shows distance 95% observed, modes complete.
    If TRE coverage is decent, index→commute gradients are the follow-up.
  - **54:** forest plot `item_level_forest.png` had its y-labels cut off
    (default left margin). Now uses the pipeline-standard wide left margin
    (`par(mar = c(5, 12, 4, 2))`, `cex.axis = 0.8`), visually verified on
    mock output 2026-09-25. CSV unchanged; the real figure regenerates on
    the next TRE run.
  - **Comments:** 40's load-bearing `unique()` (collapses the person-month
    rows) and 41's anchor-sample SD vs 40's analysis-sample `h_per_sd`
    documented.
  - **11/RUN_TRE:** `transactions.parquet` no longer loaded/read-checked
    (unused by analysis; the file stays in the cache).
  - Open from review: 48's `D_NOCAR = 90.5` / `K_GAP = 2` still flagged
    "VERIFY against published TRE numbers before citing".
  - **New 62_rent_stable.R** (rent as housing outcome): rent is a fixed
    monthly payment — every normal participant pays roughly the same rent
    every valid month — so rent appearing only in some months is a data
    fault, not a margin (user decision 2026-09-25). The extensive/intensive
    margin design was dropped. STABLE renters = positive rent in every
    INTERIOR valid month: the first and last valid month are excluded from
    the rule because rent is paid in advance, so a perfectly stable renter
    can miss a rent transaction exactly at the window edges (user decision
    2026-09-25 after the first TRE read-out showed median share 11/12 —
    a one-missing-month pattern consistent with the edge artifact; strict
    every-month rule gave share_stable = 0.361, n_stable = 1,514).
    Faults are counted, not assumed: rent_stability_diag.csv reports
    n_stable, share_stable, median interior share, median month-to-month
    CV; rent_stable.csv holds the M5 rent gradient among stable renters
    (strict-rule TRE result: −4,403 SEK/h, p = .132, n = 1,514).
    Mock plants three patterns: 64 never-rent people, 10 half-year-rent
    people (interior miss → unstable), and 10 edge-miss people (relaxed
    rule → stable, verified). → rent_stable.csv, rent_stability_diag.csv;
    README script ranges updated (20–62). NEXT TRE RUN: only 62 changed —
    expect share_stable to rise well above 0.361.

- **2026-09-23 — Pipeline consistency review (eriksson-code).** Full review of
  20-55 against the coding guidelines (no defensive coding; clarity for
  reviewers). Fixes:
  - **Month-threshold drift:** 20 built the headline total with
    `n_months >= min_months` but 43/47/50/52/55 had copy-pasted the recipe with
    `> min_months`. The recipe is now a single shared function `annualise()`
    defined in 20; category groups (transport/ecom/digital/placebo/vehicles,
    kr mirrors) are also defined once in 20.
  - **Index double-scaling:** 30 scaled the q11 battery once and fit the anchor
    on it, but 40 re-scaled the items inside the aid-month-duplicated control
    sample and rebuilt `index`, so `hours_est` mixed scales (and every
    `h_per_sd` multiplied a coefficient from one scale by an SD from another).
    Now 30's `device_use` (scaled items + index) is joined directly in 40;
    `h_per_sd` is defined once in 40 and reused in 42/43/47/48/50.
  - **Latest-response consistency:** 30/45 now use `survey_latest` /
    `endline_latest` (30 defines it; 55 reuses), matching 20/40/55.
  - 46 heterogeneity now runs on the frozen M5 complete-case sample (was
    `lm_data`) with t-based p-values, matching the stated design in 42/52.
  - 50: `inc0` from `users_latest` (was all historical `users` rows);
    `f_noinc` via `update(. ~ . - income - ...)` instead of string surgery.
  - Guideline cleanup: removed `stopifnot` (10_load_data), dead `index_sd`
    (42), positional `c(1, ..q21_cols)` aid selection (30 -> named), unused
    `placebo` vector (52), triple `coeftest` calls (55); documented the
    intentional person_bank left join and K_GAP units (index SDs) in 48;
    fixed comment references (quintiles not quartiles; income_q used in 50).
  - New `RUN_MOCK.R`: local end-to-end pipeline test on 00_mock_data.R
    (verified: hours_est == intercept + b*index exactly; 43-total == headline
    emissions exactly; decomp total n == M5 n; all scripts parse).
  - DECISION (2026-09-23): eriksson-code is THE pipeline; the root-level
    00/09/10 exploratory scripts are archived in archive/ (with a README
    explaining what they were). README pipeline section rewritten to
    describe eriksson-code (RUN_TRE / RUN_MOCK).

- **2026-07-18** Scaffolded project; wrote loader + screen-time validity script.
  Explored `default_filter.RData`: survey 4353×114, users 4353×225,
  transactions 3,493,172×166. Candidate digital items: q15_1–q15_12 (minutes),
  q11/q11b (1–6 Likert), q12 (1–4) + q12b (0–10), q13/q14 (0–7), array6 (1–7).
  Only labels recoverable from archived Rmd reports: q3 political orientation,
  q5 political assertiveness, q13 trust in people, q11b_2 social activity.
