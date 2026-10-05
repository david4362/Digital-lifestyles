# Digital lifestyles and consumption-based carbon emissions

Analysis project for the manuscript *"Digital lifestyles and consumption-based carbon emissions: individual-level evidence from linked bank-transaction, survey, and register data"*.

## Research question

Does digitalization lower or raise the greenhouse gas emissions embedded in household consumption? We link a survey-based measure of digital lifestyle intensity — anchored cardinally by a device-assisted screen-time report — to measured consumption-based carbon footprints from bank-transaction data for ~6,000 Swedish adults (the Konsumtionskollen sample).

Three headline results structure the paper:

1. **Net gradient** — association between digital intensity and total consumption-based CO2e per additional daily hour of screen time, controlling for sociodemographics.
2. **Decomposition** — negative gradient in transport (demobilization)? Positive in goods, e-commerce-intensive categories, digital services (rebound/direct effects)? No-channel categories (rent, insurance) as placebos.
3. **Mechanism** — does lower out-of-home leisure frequency among the digitally intensive account for part of the transport gradient?

Pre-specified heterogeneity: age, gender, urbanity.

## Headline results — v2 real-data run (2026-10-05, `TRE_output_v2/`)

Frozen M5 complete-case sample N = 4,250 (survey 12,153 → battery gate 11,172 →
≥ 12 observed months & filters 4,392 → controls 4,251 → M5 complete case 4,250;
E4 anchor sample 2,082). Headline scale: kg CO2e per index SD; per-hour values
are derived (per-SD ÷ 0.338 h/SD) and secondary.

- **Main index (11 items), M5: +203.9 kg CO2e per index SD** (95% CI 140.7–267.2,
  p = 2.9e-10, R² = 0.366). Ladder: M0 +179.7 → M1 +274.2 → M2 +197.8 →
  M3 +197.0 → M4 +202.3 → M5 +203.9, N constant.
- **No-calls variant (10 items), M5: +140.8** (CI 77.4–204.2, p = 1.4e-05).
- **The e-commerce items do not drive the relation**: the 13-item variant
  (q11b_7/q11b_8 back in) gives +214.3 — only ~10 kg/SD (~5%) more than the
  main index. The item that matters is **calls** (+385 kg/item-SD, the largest
  of all 13; dropping it: 203.9 → 140.8).
- **Calibration audited**: bivariate anchor b = 0.3384 h per index SD
  (n = 2,082, R² = 0.018, r = 0.134); derived per-hour M5 = 602.6 kg/h,
  identical to the direct per-hour fit; all internal checks TRUE
  (`calibration_check.csv`).
- **E4 carries no independent gradient**: +27.0 kg per measured hour at M5
  (p = .148); index-vs-E4 difference in the joint model +204.3 (p = .0039) —
  and this holds in every decomposition category (`e4_rq1_robustness.csv`,
  `e4_rq2_robustness.csv`, `e4_index_test.csv`).
- **Item level** (per item SD, BH-adjusted): calls +385***, online selling
  +330*** (excluded), smartphone +216***, e-commerce +222** (excluded),
  information search +181***, social media +175***, TV +107***, computer +51*,
  streaming −87**; gaming −54 (BH p = .061); tablet/console/reading ns.
- **Decomposition** (per index SD): groceries +39.1, e-commerce channel +28.1,
  restaurants +22.4, aviation +26.1, travel +21.5, clothing +10.6,
  uncategorized +16.7, alcohol +7.7; transport total +45.6 (p = .015;
  long-distance +25.3, p = .058; short +20.1, p = .116); digital services +1.7;
  public transport −0.9 and vehicles +0.03 ns; placebo insurance +0.14 ns.
- **Bank-account coverage**: M5 + accounts (linear) −10.7%, + account FE
  −10.8% (both still p ≈ 1e-08). By stratum: 1 account +113.2 (p = .032),
  2 +104.8 (p = .062), 3 +234.2 (p = .0004), 4+ +298.9 (p = .00014) — the
  gradient concentrates among the better-covered (3+ accounts). Spending-
  plausible sample (50–150% of register income): +154.7 (−24.1%). Index →
  observed spending +12,855 SEK/SD (p = 3.3e-05), register income +6,650
  (p = .0006), accounts +0.098 (p = .00014); CO2e/income +221.6 kg per 100k
  SEK (p = .014).
- **Robustness**: DeSO FE +254.6 (n = 3,258); M5 + tenure +187.6; age spline ≈
  linear (+205.5); ≥ 12 observed months +191.6; device-half-only index +145.3 /
  activity-half-only +174.1 / first PC +223.1; α = 0.56 (a formative composite,
  not a reflective scale); heterogeneity margins all positive with ns
  interactions (gender p = .13, city p = .32); e-commerce CO2e share flat
  (~12%) across digital quintiles.

`eriksson-code/verify_export.R` re-checks the copied export after any TRE run
(14 invariants: ladder-N constancy, decomposition ≡ headline, figure ≡
item_level, variants ≡ ladder, per-hour identities, anchor consistency) — all
pass on this run.

## Data

This project **reuses the Konsumtionskollen data** (bank transactions categorized to COICOP and converted to CO2e, baseline survey, register linkage). No data lives in this repo.

- **Local mock data** (realistic structure, partly scrambled real values — treat as non-substantive): `../Konsumtionskollen/default_filter.RData` (5.2 GB, git-ignored there). Contains `survey` (4,353 × 114 — full questionnaire incl. the `q15_*` time-use battery), `users` (225 cols incl. age, sex, education, pop density), `transactions` (3.5M × 166), `monthly_emissions`, `monthly_spending`, `monthly_incomes`.
- **Real data**: in the SCB TRE (Trusted Research Environment). Scripts must run unchanged there; follow the loader pattern from `Konsumtionskollen/10_load_data.R`.

The 5.2 GB local mock RData was only used by the archived exploratory scripts. The analysis pipeline reads the parquet cache built from the raw TRE data by `eriksson-code/10_load_data.R`; for local pipeline testing without real data, use `eriksson-code/RUN_MOCK.R` (synthetic data from `eriksson-code/00_mock_data.R`).

### Key variables (survey)

**Screen-time anchor = item E4 in the *endline* survey** (confirmed by DA 2026-07-18): device-assisted average *daily* screen time in hours:minutes for the previous week, read from iOS "Skärmtid" / Android "Digitalt välmående". **The endline survey is not in the local mock RData** (baseline only); it exists in the TRE. No endline codebook located yet.

Baseline survey blocks (CONFIRMED against the official codebook, 2026-08-21 — see
`docs/Pre-treatment_survey_codebook.csv` and `notes/continuity.md`):

| Block | Content (codebook) | Role |
|---|---|---|
| `q11_1`–`q11_5+` | Device-use frequency, 1–6 scale (computer, smartphone, TV, console, tablet) | Digital index: device half |
| `q11b_1`–`q11b_8` | Digital-activity frequency, 1–6 scale (streaming, calls, social media, search, gaming, digital reading, e-commerce, online selling) | Digital index: activity half; **`q11b_7` (e-commerce) and `q11b_8` (online selling) are excluded from the main index** (they measure the purchase channel itself; the outcome is transaction-observed consumption), `q11b_2` (calls) is kept in the main index and dropped in a registered variant; `q11b_7` also feeds the e-commerce decomposition channel |
| `q15_1`–`q15_12` | Typical prices paid (SEK) for reference goods | Not in index (quality-of-consumption control at most) |
| Endline `E4` | Device-assisted daily screen time (h:min), with opt-outs | Cardinal anchor (interpretive: per-SD is the headline scale, per-hour is derived via the anchor — the anchor is weak, R² = 0.018 in the v2 real-data run) |
| Endline `E1` | 12-month activity frequencies incl. out-of-home leisure | Mechanism (result 3) |

The main index (v2) follows the pre-registered construction: each item
z-standardized on the analysis sample, unweighted mean of answered items
(≥ 8 of 11, the prereg tolerance of ≤ 3 missing), re-standardized. The
anchor regression and every per-SD↔per-hour conversion ingredient are
audited in `calibration_check.csv`.

Until the endline data/codebook is available locally, development proceeds with a synthetic endline E4 (see `notes/continuity.md`). The real endline (E4 anchor, E1 mechanisms) is read in the TRE by `10_load_data.R`; the v2 numbers above are from the real run.

## Pipeline

The analysis pipeline lives in **`eriksson-code/`** (real data in the SCB TRE;
run with `Rscript RUN_TRE.R` from that directory). Scripts are numbered and
sourced in order:

| Script | Purpose |
|---|---|
| `RUN_TRE.R` | Entry point: reads the parquet cache (or builds it via `10_load_data.R`), sources 20–66 in order, then copies the export README + data dictionary into the export and writes a run manifest |
| `RUN_MOCK.R` | Local end-to-end pipeline test on `00_mock_data.R` (no real data, throwaway output dir) |
| `verify_export.R` | Post-run invariant checks on a copied v2 export (ladder-N constancy, decomposition ≡ headline, figure ≡ item_level, variants ≡ ladder, per-hour identities, anchor consistency) |
| `00_mock_data.R` | Synthetic dataset for local pipeline testing |
| `10_load_data.R` / `11_read_cache.R` | Raw TRE data → parquet cache / cache reader |
| `20_filter_participants.R` | Sample filters; **the index item sets (main = prereg minus e-commerce/online selling)**, the battery gate (≥ 8 of 11 answered, the prereg tolerance of ≤ 3 missing), the shared `annualise()` outcome recipe, category groups, person-level coverage table, and the versioned export dir |
| `30_time_estimate.R` | E4 screen-time parse (raw + 18 h/day rule) and the raw item battery |
| `40_control_vars.R` | Controls; the frozen M5 complete-case sample; **the pre-registered index construction** (items z-scaled on the analysis sample, mean of answered items, re-standardized) + no-calls variant; the cardinal anchor (bivariate, `h_per_sd` = hours per index SD); the M5 formula on `index` |
| `41`–`66` | Model checks + **hour-calibration audit**, stepwise ladder (main + no-calls index), decompositions (CO2e/SEK), heterogeneity, equivalence, coverage checks, e-commerce, E4/item-level robustness, E1 mechanisms, DeSO FE, index variants/weightings, rent among stable renters, transport split, tenure/life-stage confound, **E4 diagnostics (65)**, **bank-account coverage analyses (66)** |

Outputs go to `output_v2/` next to the TRE cache (defined once in 20). After
copying an export out of the TRE, run `verify_export.R` from `eriksson-code/`
against the copied folder (14 invariant checks). The v1 export (13-item
pipeline index, complete-battery rule) is superseded — see
`eriksson-code/EXPORT_README.md` (copied into every export), `TRE_output_v2/`
in the repo root, which holds the real v2 export (run 2026-10-05), and
`TRE_output/`, which holds the archived v1 export.

The old exploratory scripts (pre-codebook screen-time search against the local
mock RData) are archived in `archive/` — do not run them.

## Conventions

Inherited from Konsumtionskollen: numbered scripts sourced in order; `output/` for all generated artifacts; person-level aggregation with P99 winsorization for outliers; HC3 robust SEs for cross-sectional models. See `../Konsumtionskollen/01_utils.R` before re-implementing helpers.

## Continuity

Read [notes/continuity.md](notes/continuity.md) first in every new working session — it records decisions, open questions, and next steps for the paper.
