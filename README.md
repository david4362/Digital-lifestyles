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
| `q11b_1`–`q11b_8` | Digital-activity frequency, 1–6 scale (streaming, calls, social media, search, gaming, digital reading, e-commerce, online selling) | Digital index: activity half; `q11b_7` = e-commerce channel |
| `q15_1`–`q15_12` | Typical prices paid (SEK) for reference goods | Not in index (quality-of-consumption control at most) |
| Endline `E4` | Device-assisted daily screen time (h:min), with opt-outs | Cardinal anchor |
| Endline `E1` | 12-month activity frequencies incl. out-of-home leisure | Mechanism (result 3) |

Until the endline data/codebook is available locally, development proceeds with a synthetic endline E4 (see `notes/continuity.md`).

## Pipeline

The analysis pipeline lives in **`eriksson-code/`** (real data in the SCB TRE;
run with `Rscript RUN_TRE.R` from that directory). Scripts are numbered and
sourced in order:

| Script | Purpose |
|---|---|
| `RUN_TRE.R` | Entry point: reads the parquet cache (or builds it via `10_load_data.R`), then sources 20–63 in order |
| `RUN_MOCK.R` | Local end-to-end pipeline test on `00_mock_data.R` (no real data, throwaway output dir) |
| `00_mock_data.R` | Synthetic dataset for local pipeline testing |
| `10_load_data.R` / `11_read_cache.R` | Raw TRE data → parquet cache / cache reader |
| `20_filter_participants.R` | Sample filters; the shared `annualise()` outcome recipe and the category groups used by all decomposition scripts |
| `30_time_estimate.R` | E4 screen-time anchor; the (single) z-scaled device-use index and `endline_latest` |
| `40_control_vars.R` | Controls, anchored `hours_est`, the fixed M5 complete-case sample, `h_per_sd` |
| `41`–`64` | Model checks, stepwise ladder, decompositions (CO2e/SEK), heterogeneity, equivalence, coverage, e-commerce, E4/item-level robustness, E1 mechanisms, DeSO FE, index variants/weightings, rent among stable renters, short/long transport split, tenure/life-stage confound |

Outputs go to `output/` next to the TRE cache.

The old exploratory scripts (pre-codebook screen-time search against the local
mock RData) are archived in `archive/` — do not run them.

## Conventions

Inherited from Konsumtionskollen: numbered scripts sourced in order; `output/` for all generated artifacts; person-level aggregation with P99 winsorization for outliers; HC3 robust SEs for cross-sectional models. See `../Konsumtionskollen/01_utils.R` before re-implementing helpers.

## Continuity

Read [notes/continuity.md](notes/continuity.md) first in every new working session — it records decisions, open questions, and next steps for the paper.
