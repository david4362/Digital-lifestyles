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

- **No export versioning (2026-10-07).** The exploratory phase makes small
  iterative changes, so major version tags are dropped: the pipeline writes
  to `output/` (rewritten wholesale by every run; `run_info.csv` run_date is
  the only provenance tag), the repo keeps the latest copy-out in
  `TRE_output/`, and the superseded first-pass export is archived in
  `archive/TRE_output_2026-09-25/`. Historical "v1" mentions in old session
  entries refer to that first-pass pipeline era.
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

1. Report the run-2026-10-07 results to the supervisor — concise academic
   brief in `notes/brief_supervisor_2026-10-07.md` (answers all six points
   of the 2026-09-28 email + the new volume/mechanism results, with
   interpretations and proposed further analyses) and a Swedish email draft
   in `notes/email_draft_2026-10-07.md`.
   Substance: volume split 96% ("buys more, not dirtier"; composition
   premium 0.27 pp, p = .17) and the RQ3 mechanism not supported (index →
   out-of-home leisure is positive, +0.07 points/SD, mediation share ≤ 10%
   ns). Headline unchanged (+203.9 kg/SD).
2. Prereg deviation table — add the RQ3 falsification as a fourth dated entry;
   report the mechanism as a registered negative result, no post-hoc reframe.
3. Decide the manuscript treatment of calls (q11b_2): main 11-item estimate
   with the 10-item no-calls ladder as the registered sensitivity (both in
   `stepwise_table.csv`).
4. Start paper-side work on the real numbers (figures from `TRE_output/`);
   RQ2 section builds on `volume_composition.csv` + `quintile_contrast.csv`
   (D5–D1 = +599 kg, +13.3%), budget shares as BH-adjusted descriptive.
5. Critique backlog (unchanged priorities): calls deep-dive (§4.2),
   sociable-vs-solitary item split as prereg v3 (§5.2), pre-window
   year-by-year gradient (§5.1), additive decomposition display + per-hour
   CI anchor-SE propagation (§6), equivalence constants, representativeness
   vs LISA, literature brief for the "first individual-level evidence" claim.
6. Push the local commits when ready.

## Session log

- **2026-10-12 (later) — repo cleanup & reorganization (user request).**
  `eriksson-code/` renamed to **`R/`**; all output now lives under **`output/`**
  with dated folders — `output/2026-09-25/` (former
  `archive/TRE_output_2026-09-25/`) and `output/2026-10-07/` (former
  `TRE_output/`); the rest of `archive/` (old exploratory code + its README)
  deleted, retrievable from git history. Code touched: cache path →
  `/safe/…/chalmers/R/cache` in RUN_TRE/10/11; `out_dir` in 20 is now dated
  (`output/<yyyy-mm-dd>/`, runs never overwrite each other);
  `verify_export.R` auto-detects the newest folder under `output/`; README,
  the source `R/EXPORT_README.md` and `.gitignore` (`output/` no longer
  ignored — dated export snapshots are tracked) updated. The snapshot
  copies *inside* `output/<date>/` (their EXPORT_README, run_info.csv) still
  mention old paths by design — they document what those runs used.
  Verified after the move: RUN_MOCK 20–70 clean (writes
  `tempdir/output/2026-10-12`) and verify_export 16/16 on
  `output/2026-10-07/`. **TRE-side action for the next real run:** place the
  scripts at `/safe/…/chalmers/R/` and move the cache
  (`mv …/chalmers/eriksson-code/cache …/chalmers/R/cache`); the run then
  writes `…/chalmers/R/output/<date>/`. Heads-up: David's calls-diagnostics
  branch (still unpushed) is based on the old layout, so its diff review
  will show these renames as noise.

- **2026-10-12 — full code review applied + item-scaling bug FIXED locally
  (supersedes the "do not patch 59 locally" note below).** Complete style
  review of eriksson-code (criteria: non-programmer clarity, no defensive
  coding, data.table + native R only, minimal verbosity) — findings and
  verification trail in `notes/code_review_2026-10-12.md`; two commits on
  main (style remediation + this fix). Style round: 67's hidden dependency
  on 55, defensive structures removed (54's stopifnot audit +
  item_figure_check.csv, four n<30 silent skips, 68's stopifnot), TRUE/FALSE,
  duplicated logic consolidated (group_annual/decomp_targets in 20; form0,
  m5_row, fit_row, e4_data in 40; screen_valid in 30; 70_run_info.R), 46
  margins rewritten, 40 chain split, vol_comp row-wise, assignments on `=`
  (.lintr updated). All 73 mock outputs byte-identical throughout.
  **Substance fix (user decision, overriding the Oct-07 "do not patch"
  note):** the analysis_data q11 columns were RAW (item_battery rode along
  via control_data; z-scaling lived only in z_items), so 54's item-level
  slopes were per raw scale point and 59's 13-item row / 61's halves+PC1
  were raw-item-weighted, while comments/labels claimed z-scaled. Fixed in
  40: control_data no longer carries the items; the final join brings the
  **z-scaled items** from z_items into analysis_data (mu/sd now computed
  from item_battery joined to the frozen sample — identical parameters);
  54/59/61 needed no edits, their comments are now true. Mock-verified: the
  changed item_level numbers follow the exact identity z-slope = raw-slope
  × item SD (se likewise, p identical — pure reparametrization); main,
  no-calls and battery-scaled variants unchanged; only the 13-item row,
  index_weightings and social_games moved; all other outputs byte-identical.
  **Consequences:** README item-level + 13-item numbers marked ⚠ pending
  TRE rerun (they were per raw point, mislabelled per item SD); brief /
  critique notes of 2026-10-07 are dated records — left as-is. When David's
  calls-diagnostics branch lands, it must REBASE onto this (its 59 fix and
  any item-level tables assume the old raw-item lineage); verify_export
  15/15 still passes on the frozen 2026-10-07 export.

- **2026-10-07 (night) — pre-branch commit + calls-diagnostics groundwork.**
  Committed the Oct-07 export + notes to main *before* David's
  calls-diagnostics branch lands (his Claude's side repo
  `Digital-lifestyles-calls-diagnostics` is not on the remote yet — only
  `main`). Verified his Claude's +214 claim against our code: **real bug** —
  `59_index_variants.R` builds the 13-item row from the RAW q11 columns of
  `analysis_data` while its comment claims they are z-scaled (z-scaling lives
  in `z_items`; only the composites are joined back), so +214.3 is not the
  registered construction and the 11-vs-13 comparison ("e-commerce adds
  ~10 kg/SD") is contaminated; corrected number pending David's branch +
  TRE rerun. **Do not patch 59 locally — his branch supersedes.** David's task
  list (full pipeline run, verify_export output, wholly new output dir +
  run_info, corrected 11-vs-13, five calls tables, SSYK check) is blocked on
  his push. SSYK check prepared: `JE_Lev_LISA_2024.txt` is loaded in full into
  `scb.parquet` (no `select`), so occupation columns may already be cached —
  one grep in TRE + `ls` of the raw register dir settles it.
  User instruction: no drafting or sending of replies to David unless
  explicitly requested.

- **2026-10-07 (evening, later) — `decomp_table.csv` gains `pct_of_mean`**
  (relative gradient = 100 × per_sd / mean — percent of the category mean per
  index SD; the %-of-mean view from the 7.3 analysis now lives in the table
  itself instead of being derived by hand). `43_decomposition.R` computes it,
  dictionary row added (both `eriksson-code/` and `TRE_output/` copies), and
  the local `TRE_output/decomp_table.csv` copy back-filled (pure arithmetic on
  the existing mean/per_sd columns; TRE-side regeneration at the next run).
  Values confirm the analysis note's table (aviation 10.3 %, travel 9.0 %,
  alcohol 8.1 %, restaurant 7.0 %, ecom 5.4 %, groceries 5.4 %, transport
  4.6 %, total 4.5 %, digital 4.1 %, public trans −0.7 %). RUN_MOCK 20–68
  clean with the new column. `sek_table.csv` unchanged — same column can be
  added there on request.

- **2026-10-07 (evening) — TRE re-run with 67 + 68 landed in `TRE_output/`;
  full analysis in `notes/results_analysis_2026-10-07.md`. All 16
  verify_export checks pass** (incl. the two new volume-split checks — first
  real export including 68). Headline reproduces to full precision
  (+203.91556801758 kg/SD) → clean re-run of the frozen spec.
  - **Volume vs. composition (the centerpiece): 96.2% of the headline is
    spending VOLUME** (+196.1 kg/SD) vs composition +26.9 (13.2%, p = .167 ns),
    covariance residual −19.1 (−9.4%). Intensity margin +0.105 kg/1,000 SEK
    per SD (p = .17); `pct_premium` = 0.27 pp of the mean (CO2e +4.53% vs
    emission-relevant spending +4.26%). The critique's ~85–95% prediction is
    confirmed at the top of the range → **"buys more", not "buys dirtier"**;
    the category decomposition becomes a budget-share restatement of the
    volume story. Policy magnitude: adjusted D5–D1 = +599 kg CO2e (13.3% of
    mean, p = 3.4e-9), spending +31,914 SEK (12.4%), intensity +1.9% ns;
    register income only +7.6% across quintiles. Engel shares: only 2 of 30
    rows survive BH (restaurant spending share +0.29 pp/SD; public-trans CO2e
    share −0.18 pp/SD) — budget_shares.csv is descriptive.
  - **RQ3 mechanism REFUTED, first leg reversed (67):** index → out-of-home
    leisure composite +0.073 points/SD (p = 8.8e-5) and at-home +0.137
    (p = 1e-13) — the digitally intensive go out MORE, not less (film,
    tv-series, sports events, dancing, dinner guests, culture events all up;
    library/exercised/nature/book null). Mediation negligible: transport
    +62.7 → +61.6 (share 1.8%) → +56.7 with both mediators (share 9.6%);
    mediator→transport coefficients ns (+15.4 OOH, p = .59). Mediators
    positively predict total CO2e (OOH +143 kg/point, p = .0028). The
    critique's substitution fallback is also dead. → Report as a registered
    negative result; the surviving story is "sociable, active,
    high-consumption lifestyle" (matches item level + social_games.csv).
  - `mech_diag.csv` clean (share_code_8_9 = 0 everywhere) but severe ceiling
    effects in the at-home E1 set (music 85% at max, tv_series 52%, exercised
    45%) — state as a caveat. E1 subsample gradients similar to full sample
    (+237.8 total / +62.7 transport, n = 2,392) → direction flip is not
    selection.
  - Cosmetic fix landed in code for the next run: `51_descriptives.R` E4 row
    label now "E4 anchor sample (valid E4 report and valid index)" (this
    export still shows the old label with n = 2,082).

- **2026-10-07 (later) — De-versioned the outputs (user decision).** Exploratory
  phase = constant small iterative changes, so no major version tags:
  `out_dir` is `output/` again (rewritten wholesale by every run; only
  `run_info.csv` run_date + spec provenance), `export_version` dropped from
  the run manifest (and from the dictionary and verify check 14 — the index
  spec greps stay), repo folders: `TRE_output_v2/` → `TRE_output/` and the
  old `TRE_output/` (first-pass export) → `archive/TRE_output_2026-09-25/`.
  In-code "v1" fix notes reworded to "the earlier pipeline"; exported variant
  label "Items z-scaled on the battery sample (v1 scaling)" → "Items z-scaled
  on the battery sample" (59). verify_export now checks `../TRE_output`.
  RUN_MOCK (20–68) still clean.

- **2026-10-07 — 68_volume_composition.R: the volume-vs-composition split of
  the headline gradient ("buys more" vs. "buys dirtier").** Implements item 2
  of `notes/analysis_critique_2026-10-07.md` (the missing centerpiece: index →
  spending +3.85% of mean vs. CO2e +4.53% of mean implies most of the gradient
  is spending volume at average basket intensity).
  - **Design:** the split follows CO2e = intensity × spending at sample means.
    **Emission-relevant spending = non-excluded kr (20) minus `rent_kr`** —
    rent has no emissions factor (20), so it can carry none of the CO2e
    gradient, and keeping it in the denominator would make the intensity
    margin measure housing tenure instead of the basket. `volume_component =
    mean intensity × spending gradient`; `composition_component = intensity
    gradient × mean spending`; `covariance_residual = headline − volume −
    composition` (OLS slopes of a product are not exactly additive — the
    residual is reported, not hidden). Formal composition test = the M5
    intensity model (kg CO2e per 1,000 SEK ~ index); the "M5 + spend_goods"
    rows are descriptive equal-spending comparisons (50's precedent), never
    headline specs — spending is an outcome of the lifestyle, not a control.
  - **Outputs (5 tables + 2 figures):** `volume_margins.csv` (M5 margins:
    co2e, spend_goods, spend_total, intensity, log × 2 + the two descriptive
    equal-spending rows; stopifnot asserts the CO2e row ≡ 42's ladder M5),
    `volume_composition.csv` (the accounting + shares + pct_premium),
    `budget_shares.csv` (Engel margins: share of emission-relevant spending
    and of CO2e per group + top-10 goods leaves, pp per index SD, non-buyers
    = 0 share), `quintile_desc.csv` + `quintile_contrast.csv` (D1–D5 means
    incl. register income; adjusted D5–D1 gaps from the quintile-factor model
    with `index_gap_sd` for back-conversion), `volume_composition.png`
    (components bar + spending-share forest), `quintile_gradient.png`.
  - **Mock verification:** 00_mock_data now plants a composition margin — the
    SEK-per-kg ratio falls with screen time (`1 - 0.006*(h - 4)`; the first
    attempt at 0.03 was far too strong — flipped the mock spending gradient,
    intensity p ≈ 1e-126). Full RUN_MOCK (now 20–68) clean; recovered as
    planted: intensity +0.066 kg/1,000 SEK per SD (p < 1e-69), accounting
    residual 0.36 of a −42.6 headline, headline ≡ ladder M5. All 16
    verify_export checks pass on the mock export.
  - **verify_export.R extended to 16 invariants** (15: volume_margins M5 CO2e
    row = headline; 16: volume + composition + residual = headline, shares
    recompute). Checks 15–16 need an export from a run including 68 — the
    2026-10-05 export predates it (same situation as 67's tables). Dictionary
    (+35 rows), EXPORT_README and README updated (pipeline now 20–68).
  - NEXT TRE RUN: read volume_composition.csv's `volume_share` — if it lands
    near the critique's ~85–95% prediction, the paper's RQ2 interpretation is
    "broad-based spending volume, small basket-composition premium" and the
    category decomposition should be presented on top of the volume story;
    if composition is large, the Engel tables (`budget_shares.csv`) identify
    which categories carry the dirtier basket.

- **2026-10-05 (evening) — 67_mechanism.R: the pre-registered leisure
  mechanism (result 3) implemented and mock-verified; awaiting TRE run.**
  - **Design:** E1 endline frequency battery (1 = "Ingen gång" … 7 = "Flera
    gånger i veckan"), grid-order codes anchored by 55's validated four
    (F88_2 = arbetat hemifrån, F88_3 = övertid, F88_10 = köpt utan råd,
    F88_19 = BNPL). Pre-registered out-of-home set (7 items): F88_4/5/6/7/8/
    18/21 = bibliotek, idrottsevenemang, kulturevenemang, bjudit hem på
    middag, dansat, motionerat, naturen. At-home half (5): F88_11/12/13/14/
    16 = ljudbok, musik, bok, film, tv-serie. Composites = unweighted mean of
    answered items (no re-standardization — the 1-7 scale is common; rows
    missing everything drop).
  - **Outputs:** `mech_diag.csv` (item-level answer distributions +
    share_code_8_9 — CHECK THIS FIRST on real data: it flags grid-order
    miscoding or "Vet ej" codes above the 7-point scale before the models
    are trusted), `e1_leisure_index.csv` (index vs each item + both
    composites, M5 covariates, points per index SD), `e1_leisure_mechanism.csv`
    (transport & total CO2e gradient M5 → M5+ooh → M5+ooh+home, identical
    participants, mediator coefficients + pct_gradient_shared),
    `mech_forest.png`.
  - **Mock verification:** RUN_MOCK (now 20–67) clean; 00_mock_data plants
    the mechanism (ooh items −0.45/SD of z, transport +90 kg per SD of ooh
    spread over the transport categories) — recovered exactly: ooh composite
    −0.48/SD, transport gradient −59.4 → −23.8 with ooh control (share 60%),
    at-home mediator correctly null (p = .89). Dictionary + EXPORT_README +
    README updated for the new tables; RUN_TRE/RUN_MOCK source lists
    extended to 67. verify_export.R still targets the 2026-10-05 v2 export
    (mechanism tables enter the export only at the NEXT TRE run).
  - NEXT TRE RUN: run `Rscript RUN_TRE.R` (now also writes the mechanism
    tables), inspect mech_diag.csv FIRST, then read `e1_leisure_mechanism.csv`:
    the preregistered question is how much of the transport gradient
    (+45.6 kg/SD) is accounted for by lower out-of-home leisure — note the
    observed transport gradient is POSITIVE, so a negative/zero share is a
    real possibility (the mechanism would then not explain the gradient).

- **2026-10-05 (afternoon) — v2 real-data TRE run landed and verified
  (`TRE_output_v2/`). All 14 post-run invariant checks pass** — now saved as
  `eriksson-code/verify_export.R` (flat checks in pipeline conventions: fread,
  abs-diff tolerances like 41, stopifnot like 54; run from eriksson-code/,
  reads `../TRE_output_v2`). run_info confirms the v2 spec on the real run
  (R 4.3.3, 11-item list, ≥ 8/11 gate, bivariate anchor, per-SD headline).
  Dictionary matches the export's 46 CSVs exactly; EXPORT_README + dictionary
  re-copied into the repo folder (the copy-out had dropped them — RUN_TRE
  does place them in the TRE-side output_v2); Windows Thumbs.db deleted.
  - **HEADLINE: main 11-item index M5 = +203.9 kg CO2e/SD** (CI 140.7–267.2,
    p = 2.9e-10, R² = .366, N = 4,250 constant across M0–M5). Ladder:
    M0 +179.7, M1 +274.2, M2 +197.8, M3 +197.0, M4 +202.3.
  - **Supervisor's guess refuted**: the 13-item variant (incl. q11b_7/q11b_8)
    = +214.3 vs main +203.9 — the two purchase-channel items add only ~10
    kg/SD (~5%). The item that matters is CALLS: no-calls variant +140.8
    (CI 77.4–204.2, p = 1.4e-05, −31%) and item-level calls +385 kg/item-SD
    (largest of all 13).
  - Calibration: anchor b = 0.3384 h/SD (n = 2,082, R² = .018, r = .134,
    p = 5.2e-9); derived per-hour M5 = 602.6 kg/h = direct fit; all three
    calibration_check internals TRUE.
  - E4: mean 4.39 h/day (n = 2,200 valid reports; 51 dropped by the >18 h
    rule; 585 endline opt-outs); heaping 5.1% at :00, 10.3% at :00/:30;
    E4-vs-total M5 +27.0 kg/h (p = .148) vs index +732 kg/h on the same
    sample (n = 1,969); joint difference +204.3 (p = .0039); item r with E4
    ≤ .176 (social media highest; calls .067 — the biggest-emissions item is
    nearly invisible in self-reported screen time); holds per category in
    e4_rq2. No platform variable — iOS/Android split needs app-side data.
  - Item level (BH): calls +385***, online selling +330*** (excl), e-commerce
    +222** (excl), smartphone +216***, info search +181***, social media
    +175***, TV +107***, computer +51*, streaming −87**, gaming −54
    (BH p = .061), console/tablet/reading ns. Figure audit ≡ table
    (stopifnot + item_figure_check).
  - Coverage (66): M5 + accounts linear −10.7% (182.1, p = 1.0e-08), account
    FE −10.8%; strata: 1 acct +113.2 (p = .032), 2 +104.8 (p = .062),
    3 +234.2 (p = .0004), 4+ +298.9 (p = .00014) — gradient concentrated
    among the better-covered (3+ accounts); spending-plausible 50–150%:
    +154.7 (−24.1%); 25–200%: +164.1; spending/income +0.140 (p = .050);
    CO2e/income +221.6 kg per 100k SEK (p = .014). coverage_check: spending
    +12,855 SEK/SD (p = 3.3e-05), register income +6,650 (p = .0006),
    accounts +0.098 (p = .00014).
  - Robustness: DeSO FE +254.6 (n = 3,258); M5+tenure +187.6; age spline
    +205.5 ≈ linear; ≥ 12 months +191.6; halves device +145.3 / activity
    +174.1 / PC1 +223.1; α = .559 (device half .206, activity half .463 —
    formative, not reflective); rent placebo −1,259 SEK (p = .11); all het
    margins positive, interactions ns (gender p = .13, city p = .32);
    e-commerce CO2e share flat ~12% across digital quintiles; E1: WFH days
    +0.44/SD (p = 6e-19), transport gradient survives the WFH control
    (+62.5 without vs +58.9 with, p ≈ .02).
  - Sample: 12,153 → battery 11,172 → months 4,392 → controls 4,251 → M5
    4,250; anchor sample 2,082; model missingness ≈ 0 (income_bank 1);
    attrition reporters vs non similar (age 31.4 vs 31.7; tertiary 69% vs 61%).
  - COSMETIC (fix at next TRE re-run): `descriptives.csv` labels the E4 row
    "Valid E4 reporters" but its n = 2,082 is the anchor sample (E4 ∩ valid
    index); e4_diagnostics documents both n's correctly.
  - Committed locally (not pushed): TRE_output_v2/ + verify_export.R +
    README/continuity updates.

- **2026-10-05 — v2: preregistered index (minus e-commerce/online selling) as
  the main analysis; supervisor email implemented.** Full restructure of the
  exposure line after the supervisor's email (pre-registration mistakenly
  included e-commerce/online-selling in the index — they measure the
  purchase channel itself, so part of the outcome was built into the
  exposure). Six tasks, all implemented and mock-verified (full RUN_MOCK
  20–66 clean; 12 post-run invariant checks pass):
  - **Main index (v2) = preregistration construction minus q11b_7/q11b_8**
    (11 items): items z-scaled with ANALYSIS-sample mean/SD, unweighted mean
    of answered items, re-standardized (SD 1 in the analysis sample → equal
    effective item weights in-sample). Item sets defined once in 20
    (`index_main_items`, `index_nocalls_items`, halves). Battery gate = ≥ 8
    of 11 answered (prereg tolerance of ≤ 3 missing kept as the set
    shrank; v1 required the complete 13-item battery). Calls (q11b_2) kept
    in the main index; 10-item no-calls variant runs as the SECOND M0–M5
    ladder in stepwise_table (plus variants rows in 59). Supervisor's
    normalization question answered: items were always z-scaled first;
    what moved v1's numbers was the SCALING POPULATION (battery sample vs
    analysis sample → unequal in-sample item SDs) — quantified in
    index_variants (v1: 243 vs 185 kg/SD).
  - **Per index SD is the headline scale everywhere.** Models run on
    `index` (z); every `per_hour` column is derived (per_sd / h_per_sd) and
    secondary — the anchor is weak (v1 bivariate R² = 0.016) and E4 carries
    no gradient of its own (v1: +29 kg/h, p=.11 vs index +243 kg/SD;
    difference p=.0026 in 60). hours_est stays for 52's like-for-like
    E4-vs-index comparison in hours only.
  - **Hour calibration audited (task 2).** The v1 "inconsistency"
    (0.943·0.391 = 0.369 vs the tables' 0.317) was a readability gap, not
    arithmetic: the pipeline always used the BIVARIATE anchor (b = 0.8109
    h per raw index unit; 0.8109 × 0.39065 = 0.3168 = the tables' ratio
    exactly) but anchor_check.csv listed three models without marking which
    one feeds the pipeline. Now: anchor_check has `used_in_pipeline` (only
    bivariate), and 41 writes **calibration_check.csv** — anchor b per
    index SD, index SDs (analysis = 1 by construction, anchor sample, raw
    composite), per-raw-unit slopes, derived AND directly-fit per-hour
    slopes, plus three internal consistency checks (all TRUE).
  - **New 66_account_coverage.R (task 3):** M5 + bank accounts (linear) /
    account FE; M5 within exactly 1/2/3/4+ accounts (strata n<30 skipped,
    64 convention); spending/income and CO2e/income ratio outcomes; M5
    restricted to observed spending 50–150% (and 25–200%) of register
    income; every row exports per_sd, SE, CI, p, n, per_hour and
    pct_change_vs_reference vs the same-outcome-family reference.
    account_groups_desc.csv adds per-group descriptives. Motivated by v1
    coverage_check (index → +0.29 accounts/h, p=.0004).
  - **Item-level forest fixed (task 4).** v1 bug: axis labels were built
    from `rev()`ed factor levels while points were plotted in table order,
    so every label sat on another item's estimate ("Social media" showed
    Streaming's −86; CSV said +206). Now the figure is built directly from
    the final table rows (`fig <- item_level[match(rev(item_names), item)]`),
    labels come from those same rows, stopifnot asserts the
    label↔estimate↔CI mapping, and **item_figure_check.csv** exports the
    audit (y position ↔ item ↔ estimate/lo/hi). item_level gained
    `in_main_index`.
  - **New 65_e4_diagnostics.R (task 5):** distribution + h:mm heaping + 18h
    rule drops; anchor b/SE/R²/p per index SD; Pearson r E4-vs-index and
    E4-vs-age; **e4_item_correlations.csv** (E4 vs each of the 13 items,
    smartphone closest); E4-vs-total-CO2e M5 row. **No iOS/Android platform
    variable exists** (checked the endline questionnaire — E4 instructs
    both OS paths but records only h:mm — and all cached tables' field
    lists); a split needs app-side data. No second (non-device-assisted)
    self-reported screen-time item exists in either wave — the battery IS
    the self-report side.
  - **Reproducibility (task 6):** all outputs go to a fresh versioned dir
    **`output_v2/`** (defined once in 20; per-script out_dir definitions
    removed) so old (v1) and new results cannot mix; RUN_TRE/RUN_MOCK copy
    **EXPORT_README.md** (index definitions + samples + scales) and
    **export_data_dictionary.csv** (every reported column of all 50 CSVs
    documented) into the export and write **run_info.csv** (date, R
    version, item lists, battery rule, thresholds). Repo: TRE_output/ stays
    as the archived v1 export; next TRE run copies out output_v2 →
    TRE_output_v2.
  - **Mock fixes found by the v2 RUN_MOCK:** 40's formula paste needed a
    VECTOR + collapse (scalar args ignore collapse — 42 crashed on
    "co2e~age gender"); 54's item_level must model `co2e` (no `y` in
    analysis_data); 66/49/57 joins had participants on the wrong side
    (X[i] keeps i's rows — non-analysis users leaked in); mock
    recalibrated to the real spec (SEK ≈ 75 per kg CO2e → observed spending
    ≈ 330k/yr; DispInk04 planted in 100-SEK units) so the coverage/band
    analyses are exercised; band strata n<30 skipped.
  - NEXT TRE RUN: expect the headline per_sd on the 11-item index to be the
    new main number (v1 full-prereg 13-item was +180 kg/SD; the 11-item
    value will differ — watch index_variants for the ecom-item
    contribution), anchor b (h/index SD) to stay weak, all calibration
    checks TRUE, and the account-coverage rows to show how much of the
    gradient survives.

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
