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

- **Local mock data** (realistic structure, synthetic values): `../Konsumtionskollen/default_filter.RData` (5.2 GB, git-ignored there). Contains `survey` (4,353 × 114 — full questionnaire incl. the `q15_*` time-use battery), `users` (225 cols incl. age, sex, education, pop density), `transactions` (3.5M × 166), `monthly_emissions`, `monthly_spending`, `monthly_incomes`.
- **Real data**: in the SCB TRE (Trusted Research Environment). Scripts must run unchanged there; follow the loader pattern from `Konsumtionskollen/10_load_data.R`.

Because the RData is 5.2 GB, `00_load_data.R` extracts only what this project needs and caches it in `cache/digital_cache.RData` (git-ignored). Delete the cache to force a re-extract.

### Key variables (survey)

**IMPORTANT — codebook not yet confirmed.** The survey columns are unlabeled. Working hypotheses (to be verified against the LimeSurvey questionnaire):

| Block | Format | Hypothesis |
|---|---|---|
| `q15_1`–`q15_12` | minutes/day (0–400+) | Time-use battery; one item is the device-assisted **screen-time anchor** |
| `q11_1`–`q11_7`, `q11b_1`–`q11b_8` | 1–6 Likert | Activity-frequency items (digital activities among them?) |
| `q12`, `q12b` | 1–4 / 0–10 | Possibly screen-time category + follow-up |
| `q13`, `q14` | 0–7 | Frequency counts; `q14` candidate for **out-of-home leisure** |

`10_screen_time_validity.R` profiles all candidates empirically (distribution, heaping, age gradient) to narrow this down; final mapping requires the questionnaire. **Get the codebook before building the pre-registered index.**

## Pipeline

| Script | Purpose |
|---|---|
| `00_constants.R` | Paths, category groupings (transport / e-commerce-intensive / digital services / placebo), plot theme |
| `00_load_data.R` | Loads Konsumtionskollen RData (or cache), extracts survey + users + person-level annual CO2e/SEK by category |
| `10_screen_time_validity.R` | **Step 1 (current):** validity check of self-reported/device-assisted screen time vs. Swedish benchmarks |
| *(planned)* `20_digital_index.R` | Digital lifestyle intensity index, anchored by screen time |
| *(planned)* `30_gradient.R` | Net gradient models (total CO2e ~ screen-time hours + controls) |
| *(planned)* `40_decomposition.R` | Category-level gradients incl. placebos |
| *(planned)* `50_mechanism.R` | Out-of-home leisure mediation of the transport gradient |

Run scripts in numeric order from the project root:

```r
source("00_load_data.R")      # slow first time (~minutes), fast after cache exists
source("10_screen_time_validity.R")
```

Outputs go to `output/` (figures, CSV tables).

## Conventions

Inherited from Konsumtionskollen: numbered scripts sourced in order; `output/` for all generated artifacts; person-level aggregation with P99 winsorization for outliers; HC3 robust SEs for cross-sectional models. See `../Konsumtionskollen/01_utils.R` before re-implementing helpers.

## Continuity

Read [notes/continuity.md](notes/continuity.md) first in every new working session — it records decisions, open questions, and next steps for the paper.
