# Digital lifestyles and consumption-based carbon emissions

Analysis project for the manuscript *"Digital lifestyles and consumption-based carbon emissions: individual-level evidence from linked bank-transaction, survey, and register data"*.

## Research question

Does digitalization lower or raise the greenhouse gas emissions embedded in household consumption? We link a survey-based measure of digital lifestyle intensity — anchored cardinally by a device-assisted screen-time report — to measured consumption-based carbon footprints from bank-transaction data for ~6,000 Swedish adults (the Konsumtionskollen sample).

Three headline results structure the paper:

1. **Net gradient** — association between digital intensity and total consumption-based CO2e per additional daily hour of screen time, controlling for sociodemographics.
2. **Decomposition** — negative gradient in transport (demobilization)? Positive in goods, e-commerce-intensive categories, digital services (rebound/direct effects)? No-channel categories (rent, insurance) as placebos.
3. **Mechanism** — does lower out-of-home leisure frequency among the digitally intensive account for part of the transport gradient?

Pre-specified heterogeneity: age, gender, urbanity.

## Headline results — real-data run

Frozen M5 complete-case sample N = 4,250 (survey 12,153 → battery gate 11,172 →
≥ 3 valid spending months (> 3,000 SEK) in the 12-month pre-survey window &
filters 4,392 → controls 4,251 → M5 complete case 4,250;
E4 anchor sample 2,082). Headline scale: kg CO2e per index SD; per-hour values
are derived (per-SD ÷ 0.338 h/SD) and secondary.

- **Main index (11 items), M5: +203.9 kg CO2e per index SD** (95% CI 140.7–267.2,
  p = 2.9e-10, R² = 0.366). Ladder: M0 +179.7 → M1 +274.2 → M2 +197.8 →
  M3 +197.0 → M4 +202.3 → M5 +203.9, N constant.
- **No-calls variant (10 items), M5: +140.8** (CI 77.4–204.2, p = 1.4e-05).
- **The e-commerce items do not drive the relation**: the 13-item variant
  (q11b_7/q11b_8 back in) gives **+237.2** — 33.3 kg/SD (~16%) more than
  the main index. The item that matters is **calls**
  (+345.9 kg/item-SD, the largest of all 13; dropping it: 203.9 → 140.8).
- **Calibration audited**: bivariate anchor b = 0.3384 h per index SD
  (n = 2,082, R² = 0.018, r = 0.134); derived per-hour M5 = 602.6 kg/h,
  identical to the direct per-hour fit; all internal checks TRUE
  (`calibration_check.csv`).
- **E4 carries no independent gradient**: +27.0 kg per measured hour at M5
  (p = .148); index-vs-E4 difference in the joint model +204.3 (p = .0039) —
  and this holds in every decomposition category (`e4_rq1_robustness.csv`,
  `e4_rq2_robustness.csv`, `e4_index_test.csv`).
- **Item level** (per item SD, BH-adjusted):
  calls +345.9***, social media +190.7***, online selling +189.2***
  (excluded), information search +140.9***, smartphone +136.4***,
  TV +126.5***, e-commerce +108.7** (excluded), computer +69.9*,
  console +39.4 ns, digital reading +24.5 ns, tablet +23.0 ns;
  gaming −64.8 (BH p = .061); streaming −80.2* (BH p = .020).
  `item_scaling_check.csv` confirms all items are z-scaled on the analysis
  sample.
- **Calls diagnostics (`calls_*.csv`, `item_level_joint.csv`)**: one item
  carries more than the composite — calls alone at M5 **+345.9 kg per item
  SD** (p = 2.5e-27, n = 4,243), **R² = 0.378 vs 0.366 for the full
  index**; ~90% of its gradient is unique to calls (conditional on the
  other 10 items: +308.8 of +343.3 separate). Joint item model: calls
  +308.8***, streaming −147.1***, TV +91.9**, social media +105.1**;
  smartphone and information search ns. Robust to age functional form
  (345.9 → 346.8 bands → 353.4 spline); calls z is higher at 40–69 than
  18–39. Per calls-item SD the category pattern is broad-based (separate /
  conditional on the other 10 items: transport +114 / +112 = 11.2% of the
  mean, fuel +62 / +72, travel +43 / +35, groceries +35 / +35,
  restaurant +29 / +24, e-commerce +18 / +9) while internet/telecom CO2e is
  economically flat (−1.5 kg on a 41 kg mean) and public transport is
  negative (−2.7 separate, p = .099; −4.1 conditional, p = .021) — not a
  phone-footprint channel. Calls → WFH +0.24 days/SD (p = 1.3e-6) and
  overtime +0.28 (p = 8.3e-11): calls marks a connected, working,
  sociable lifestyle (r with E4 = .067), reinforcing the post-mechanism
  interpretation.
- **Decomposition** (per index SD): groceries +39.1, e-commerce channel +28.1,
  restaurants +22.4, aviation +26.1, travel +21.5, clothing +10.6,
  uncategorized +16.7, alcohol +7.7; transport total +45.6 (p = .015;
  long-distance +25.3, p = .058; short +20.1, p = .116); digital services +1.7;
  public transport −0.9 and vehicles +0.03 ns; placebo insurance +0.14 ns.
- **Bank-account coverage**: M5 + accounts (linear) −10.7% (p ≈ 1e-08);
  + account-group FE (1/2/3/4+) −10.8%. By stratum: 1 account +113.2 (p = .032),
  2 +104.8 (p = .062), 3 +234.2 (p = .0004), 4+ +298.9 (p = .00014) — the
  gradient concentrates among the better-covered (3+ accounts). Spending-
  plausible sample (50–150% of register income): +154.7 (−24.1%). Index →
  observed spending +12,855 SEK/SD (p = 3.3e-05), register income +6,650
  (p = .0006), accounts +0.098 (p = .00014); CO2e/income +221.6 kg per 100k
  SEK (p = .014).
- **Volume vs. composition (the RQ2 centerpiece, `volume_composition.csv`)**:
  **96.2% of the headline is spending volume** (+196.1 kg/SD) vs a composition
  component of +26.9 (13.2%, p = .167 ns) and a covariance residual of −19.1
  (−9.4%). Basket-intensity margin +0.105 kg CO2e/1,000 SEK per SD (p = .17);
  the "buying dirtier" premium is 0.27 pp of the mean (CO2e +4.53% vs
  emission-relevant spending +4.26% per SD) — **"buys more", not "buys
  dirtier"**. Adjusted D5–D1 index-quintile gap: +599 kg CO2e (13.3% of the
  mean, p = 3.4e-9), spending +31,914 SEK (12.4%), intensity +1.9% ns;
  register income only +7.6% across quintiles. Engel budget shares
  (`budget_shares.csv`) survive BH in only 2 of 30 rows (restaurant spending
  share +0.29 pp/SD; public-transport CO2e share −0.18 pp/SD) — descriptive.
- **Pre-registered leisure mechanism REFUTED (`e1_leisure_*.csv`)**: the
  digitally intensive report **more**, not less, out-of-home leisure (+0.073
  points/SD on the 1–7 composite, p = 8.8e-5; at-home +0.137, p = 1e-13;
  sports/culture/dinner/dancing up, library/exercised/nature null). Mediation
  share of the transport gradient 1.8% (out-of-home) to 9.6% (both, ns);
  mediator→transport coefficients ns. Report as a registered negative result.
- **Robustness**: DeSO FE +254.6 (n = 3,258); M5 + tenure +187.6; age spline ≈
  linear (+205.5); ≥ 12 observed months +191.6; device-half-only index +151.4 /
  activity-half-only +190.0 / first PC +207.3; α = 0.56 (a formative composite,
  not a reflective scale); heterogeneity margins all positive with ns
  interactions (gender p = .13, city p = .32); e-commerce CO2e share flat
  (~12%) across digital quintiles.

`R/verify_export.R` re-checks the copied export after any TRE run (newest folder under `output/`)
(20 invariants: ladder-N constancy, decomposition ≡ headline, variants ≡
ladder, per-hour identities, anchor consistency, volume-vs-composition ≡
headline, item z-scaling, calls sample identities). All 20 pass on the
real export and on the mock pipeline.

## Data

This project **reuses the Konsumtionskollen data** (bank transactions categorized to COICOP and converted to CO2e, baseline survey, register linkage). No data lives in this repo.

**Delivered grain:** the transactions `.dta` has **one row per `aid × date`**.
All sub-day transactions of a category are summed into that day's wide `_kr` /
`_co2e` cell before delivery, so a row typically has several populated columns
and no single-transaction detail survives. `R/10_load_data.R` therefore melts
the wide columns and sums per `aid × month × category`; no analysis script
treats a dta row as one transaction.

- **Real data**: in the SCB TRE (Trusted Research Environment). Scripts must run unchanged there. The raw-read core is shared with the other projects: `R/load_common_data.R` (a byte-identical synced copy in all three project repos; canonical master at the workspace `scripts/load_common_data.R` — copy it alongside the scripts when syncing into the TRE) owns the TRE paths, the raw reads, the renames, the SCB join and the **canonical aviation emission-intensity override** (≈ 0.166 kg CO2e/SEK on `aviation_co2e`; see `data/common-data.md` §6). `run_info.csv` records `aviation_override`.
- **Mock data**: for local pipeline testing without real data, use `R/RUN_MOCK.R`, which builds synthetic data from the **shared generator** — committed in this repo as the synced copy `R/generate_mock_data.R`, identical to the canonical master `scripts/generate_mock_data.R` at the workspace level; the single synthetic study population for all projects, sourced via the thin adapter `R/00_mock_data.R` (plants and faults documented in the generator header and `data/common-data.md`).
- **Study metadata**: the survey
  codebooks + questionnaires, SNES codebook, SCB Variabellista, category/field
  lists (`metadata.md`) and the export data dictionary live at the workspace
  level in `data/metadata/`; the cross-projects data knowledge document is
  `data/common-data.md`. This repo carries a **synced copy at `metadata/`**
  (next to `R/`) so it runs and publishes stand-alone — the runners'
  `../metadata` candidate resolves it; sync it from the workspace
  `data/metadata/` when that changes (same rule as `load_common_data.R` and
  `.lintr`). In the TRE keep a copy next to the pipeline at
  `chalmers/digital_lifestyles/metadata/` — `RUN_TRE.R`/`RUN_MOCK.R` fail
  fast if it is missing (70 copies the dictionary into every export).

### Key variables (survey)

**Screen-time anchor = item E4 in the *endline* survey**: device-assisted average *daily* screen time in hours:minutes for the previous week, read from iOS "Skärmtid" / Android "Digitalt välmående". The endline survey exists in the TRE (read by `10_load_data.R`) and is synthesized by `scripts/generate_mock_data.R` for local mock runs. Endline questionnaire and codebook live in `data/metadata/`.

Baseline survey blocks (see `data/metadata/Pre-treatment Survey Codebook.csv`):

| Block | Content (codebook) | Role |
|---|---|---|
| `q11_1`–`q11_5+` | Device-use frequency, 1–6 scale (computer, smartphone, TV, console, tablet) | Digital index: device half |
| `q11b_1`–`q11b_8` | Digital-activity frequency, 1–6 scale (streaming, calls, social media, search, gaming, digital reading, e-commerce, online selling) | Digital index: activity half; **`q11b_7` (e-commerce) and `q11b_8` (online selling) are excluded from the main index** (they measure the purchase channel itself; the outcome is transaction-observed consumption), `q11b_2` (calls) is kept in the main index and dropped in a registered variant; `q11b_7` also feeds the e-commerce decomposition channel |
| `q15_1`–`q15_12` | Typical prices paid (SEK) for reference goods | Not in index (quality-of-consumption control at most) |
| Endline `E4` | Device-assisted daily screen time (h:min), with opt-outs | Cardinal anchor (interpretive: per-SD is the headline scale, per-hour is derived via the anchor — the anchor is weak, R² = 0.018 on the real data) |
| Endline `E1` | 12-month activity frequencies incl. out-of-home leisure | Mechanism (result 3) |

The main index follows the pre-registered construction: each item
z-standardized on the analysis sample, unweighted mean of answered items
(≥ 8 of 11, the prereg tolerance of ≤ 3 missing), re-standardized. The
anchor regression and every per-SD↔per-hour conversion ingredient are
audited in `calibration_check.csv`.

## Pipeline

The analysis pipeline lives in **`R/`** (real data in the SCB TRE;
run with `Rscript RUN_TRE.R` from that directory). Scripts are numbered and
sourced in order:

| Script | Purpose |
|---|---|
| `RUN_TRE.R` | Entry point: reads the parquet cache (or builds it via `10_load_data.R`), sources 20–75 and `70_run_info.R` in order, then copies the export README + data dictionary into the export and writes a run manifest |
| `RUN_MOCK.R` | Local end-to-end pipeline test on the shared generator (no real data, throwaway output dir) |
| `verify_export.R` | Post-run invariant checks on a copied export, 20 checks (ladder-N constancy, decomposition ≡ headline, variants ≡ ladder, per-hour identities, anchor consistency, volume-split identity, item z-scaling, calls sample identities) |
| `00_mock_data.R` | Thin adapter: sources the repo-local synced copy `R/generate_mock_data.R` of the shared generator (canonical master at the workspace `scripts/generate_mock_data.R`; committed in every project repo so this one runs stand-alone) — the single synthetic population for all projects, aviation override included (DL plants: battery/E4/E1/mediation/gradients; faults: duplicates, partial batteries, opt-outs, rent faults, low-spend, no-bank-income) |
| `load_common_data.R` / `generate_mock_data.R` | Synced identical copies of the shared raw-read core and the shared mock generator (canonical masters at the workspace `scripts/`; sync rule in the file headers) |
| `10_load_data.R` / `11_read_cache.R` | Project views + parquet cache on top of the shared core (monthly aggregates, endline survey, bank income) / cache reader |
| `20_filter_participants.R` | Sample filters; **the index item sets (main = prereg minus e-commerce/online selling)**, the battery gate (≥ 8 of 11 answered, the prereg tolerance of ≤ 3 missing), the shared `annualise()` outcome recipe, category groups, person-level coverage table, and the versioned export dir |
| `30_time_estimate.R` | E4 screen-time parse (raw + 18 h/day rule) and the raw item battery |
| `40_control_vars.R` | Controls; the frozen M5 complete-case sample; **the pre-registered index construction** (items z-scaled on the analysis sample, mean of answered items, re-standardized) + no-calls variant; the cardinal anchor (bivariate, `h_per_sd` = hours per index SD); the M5 formula on `index` |
| `41`–`66` | Model checks + **hour-calibration audit**, stepwise ladder (main + no-calls index), decompositions (CO2e/SEK), heterogeneity, equivalence, coverage checks, e-commerce, E4/item-level robustness, E1 mechanisms, DeSO FE, index variants/weightings, rent among stable renters, transport split, tenure/life-stage confound, **E4 diagnostics (65)**, **bank-account coverage analyses (66)** |
| `67_mechanism.R` | **Pre-registered leisure mechanism (result 3)**: E1 out-of-home / at-home leisure composites, index-vs-leisure gradients, transport & total gradient without/with the mediators (`mech_diag.csv` validates the E1 item codes on the data first) |
| `68_volume_composition.R` | **Volume vs. composition of the headline gradient** ("buys more" vs. "buys dirtier"): M5 margins in CO2e, emission-relevant spending (kr minus rent) and basket intensity (kg CO2e per 1,000 SEK), the accounting split at sample means (volume component + composition component + covariance residual = headline), budget-share (Engel) gradients per category, and the adjusted D5–D1 index-quintile contrasts (`volume_margins.csv`, `volume_composition.csv`, `budget_shares.csv`, `quintile_desc.csv`, `quintile_contrast.csv`) |
| `69_calls_diagnostics.R` | **Calls (q11b_2) deep-dive**: calls M0–M5 ladder, separate-vs-conditional item comparison + joint item model (`item_level_joint.csv`), category decomposition (groups + leaves, separate and conditional), age descriptives/specifications, and E1 work outcomes (`calls_*.csv`) |
| `69_sample_representativeness.R` | Recruitment-stream composition, random-frame benchmark, inverse-probability sampling weights, and stream-specific / IPW gradients |
| `71`–`75` | Registered out-of-home social/cultural group (`71`), joint age-band interaction test (`72`), calls-sociality diagnostics (`73`), social-media and gaming SEK spending (`74`), and 24-month window travel sensitivity (`75`) |
| `70_run_info.R` | Run manifest (`run_info.csv`) + copies the export data dictionary (from the central study metadata resolved by the runners into `metadata_dir`) into the export |

Outputs go to a dated folder `output/<run date>/` next to the TRE cache
(defined once in 20; runs never overwrite each other — `run_info.csv`
records the run date and spec). After copying an export out of the TRE,
run `verify_export.R` from `R/` — it checks the newest folder under
`output/` automatically (20 invariant checks). See `R/EXPORT_README.md`
(copied into every export). Real exports are stored in the repo as
dated folders under `output/`.

## Conventions

Canonical coding guidelines: [`CODING-GUIDELINES.md`](../../CODING-GUIDELINES.md)
at the workspace root (clarity for non-programmer reviewers; no defensive
programming; data.table + native R; `=` assignments; HC3 robust SEs; frozen
samples; dated outputs; mock-first verification). The specifics below are
this project's application of it.

Inherited from Konsumtionskollen (now `../low-carbon-lifestyles/`): numbered
scripts sourced in order; `output/` for all generated artifacts; person-level
aggregation with P99 winsorization for outliers.

## Continuity

Read [notes/continuity.md](notes/continuity.md) first in every new working session — it records decisions, open questions, and next steps for the paper.
