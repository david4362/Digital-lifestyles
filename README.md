# Digital lifestyles and consumption-based carbon emissions

Analysis project for the manuscript *"Digital lifestyles and consumption-based carbon emissions: individual-level evidence from linked bank-transaction, survey, and register data"*.

## Research question

Does digitalization lower or raise the greenhouse gas emissions embedded in household consumption? We link a survey-based measure of digital lifestyle intensity — anchored cardinally by a device-assisted screen-time report — to measured consumption-based carbon footprints from bank-transaction data for ~6,000 Swedish adults (the Konsumtionskollen sample).

Three headline results structure the paper:

1. **Net gradient** — association between digital intensity and total consumption-based CO2e per additional daily hour of screen time, controlling for sociodemographics.
2. **Decomposition** — negative gradient in transport (demobilization)? Positive in goods, e-commerce-intensive categories, digital services (rebound/direct effects)? No-channel categories (rent, insurance) as placebos.
3. **Mechanism** — does lower out-of-home leisure frequency among the digitally intensive account for part of the transport gradient?

Pre-specified heterogeneity: age, gender, urbanity.

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
| Endline `E4` | Device-assisted daily screen time (h:min), with opt-outs | Cardinal anchor (interpretive: per-SD is the headline scale, per-hour is derived via the anchor — the anchor is weak, R² ≈ 0.016 in v1) |
| Endline `E1` | 12-month activity frequencies incl. out-of-home leisure | Mechanism (result 3) |

The main index (v2) follows the pre-registered construction: each item
z-standardized on the analysis sample, unweighted mean of answered items
(≥ 8 of 11, the prereg tolerance of ≤ 3 missing), re-standardized. The
anchor regression and every per-SD↔per-hour conversion ingredient are
audited in `calibration_check.csv`.

Until the endline data/codebook is available locally, development proceeds with a synthetic endline E4 (see `notes/continuity.md`).

## Pipeline

The analysis pipeline lives in **`eriksson-code/`** (real data in the SCB TRE;
run with `Rscript RUN_TRE.R` from that directory). Scripts are numbered and
sourced in order:

| Script | Purpose |
|---|---|
| `RUN_TRE.R` | Entry point: reads the parquet cache (or builds it via `10_load_data.R`), sources 20–66 in order, then copies the export README + data dictionary into the export and writes a run manifest |
| `RUN_MOCK.R` | Local end-to-end pipeline test on `00_mock_data.R` (no real data, throwaway output dir) |
| `00_mock_data.R` | Synthetic dataset for local pipeline testing |
| `10_load_data.R` / `11_read_cache.R` | Raw TRE data → parquet cache / cache reader |
| `20_filter_participants.R` | Sample filters; **the index item sets (main = prereg minus e-commerce/online selling)**, the battery gate (≥ 8 of 11 answered, the prereg tolerance of ≤ 3 missing), the shared `annualise()` outcome recipe, category groups, person-level coverage table, and the versioned export dir |
| `30_time_estimate.R` | E4 screen-time parse (raw + 18 h/day rule) and the raw item battery |
| `40_control_vars.R` | Controls; the frozen M5 complete-case sample; **the pre-registered index construction** (items z-scaled on the analysis sample, mean of answered items, re-standardized) + no-calls variant; the cardinal anchor (bivariate, `h_per_sd` = hours per index SD); the M5 formula on `index` |
| `41`–`66` | Model checks + **hour-calibration audit**, stepwise ladder (main + no-calls index), decompositions (CO2e/SEK), heterogeneity, equivalence, coverage checks, e-commerce, E4/item-level robustness, E1 mechanisms, DeSO FE, index variants/weightings, rent among stable renters, transport split, tenure/life-stage confound, **E4 diagnostics (65)**, **bank-account coverage analyses (66)** |

Outputs go to `output_v2/` next to the TRE cache (defined once in 20). The
v1 export (13-item pipeline index, complete-battery rule) is superseded —
see `eriksson-code/EXPORT_README.md` (copied into every export) and
`TRE_output/` in the repo root, which holds the archived v1 export.

The old exploratory scripts (pre-codebook screen-time search against the local
mock RData) are archived in `archive/` — do not run them.

## Conventions

Inherited from Konsumtionskollen: numbered scripts sourced in order; `output/` for all generated artifacts; person-level aggregation with P99 winsorization for outliers; HC3 robust SEs for cross-sectional models. See `../Konsumtionskollen/01_utils.R` before re-implementing helpers.

## Continuity

Read [notes/continuity.md](notes/continuity.md) first in every new working session — it records decisions, open questions, and next steps for the paper.
