# Analysis critique — digital lifestyles paper (2026-10-07)

Based on `TRE_output_v2/` (real run 2026-10-05), `eriksson-code/` as of 2026-10-05
evening (67 implemented but NOT in the export), README, continuity notes,
`latex/preregistration.tex`, `latex/manuscript.tex`. Note: export predates the
current code slightly — mechanism tables (67) and the fixed descriptives label
are not in `TRE_output_v2/`.

## 1. Headline assessment

The pipeline and robustness discipline are genuinely strong (frozen sample,
single-source `annualise()` recipe, invariant checks, calibration audit, BH at
item level, versioned exports). The problem is not execution — it is that **the
data tell a different story than the preregistered/abstract framing**, and a
third of the paper's motivating claims (demobilization; "per hour of screen
time") are contradicted by the current results. The analysis also currently
cannot distinguish "digital lifestyles cause/consume more" from "the index
marks people who spend more money", because the most important decomposition —
spending volume vs. basket composition — has not been run.

## 2. What the current results can support as the paper's story

**The strongest defensible story: "Digital lifestyles do not dematerialize
consumption — and demobilization is absent."**

- **RQ1 (robust, precise):** +203.9 kg CO2e per index SD (95% CI 141–267,
  N = 4,250 constant) ≈ **+4.5% of the mean footprint (4,501 kg/yr)**. Survives
  every robustness: DeSO FE (+254.6), tenure (+187.6), age spline, ≥12 months
  (+191.6), index variants (prereg 13-item +214.3 ≈ main 203.9 — reassuring),
  coverage restrictions (3+ accounts +234/+299; spending-plausible +154.7).
- **RQ2 (the adjudication is the paper's real contribution — but it refutes the
  preregistered H2a):** the transport gradient is **positive** (+45.6 kg/SD,
  p = .015; short +20.1 ns, long +25.3 p = .058). No demobilization anywhere at
  the category level; restaurant (+22.4), travel (+21.5), aviation (+26.1),
  groceries (+39.1), ecom-goods (+28.1) all positive. Digital services are
  carbon-trivial (+1.7 kg) despite a strong spending gradient (+294 SEK/SD) — a
  clean "direct digital emissions don't matter, physical consumption does"
  point. The e-commerce-channel story is also weak: ecom CO2e *share* flat ~12%
  across quintiles, and the two ecom items add only ~10 kg/SD to the index.
- **The result pattern is "broad-based positive"**, including categories with no
  digital channel (insurance SEK +77 ns, services SEK +142 ns, uncategorized
  +16.7 kg). That pattern favors a **consumption-capacity/lifestyle
  interpretation** over any channel-level mechanism — see §4.1, which is the
  single most important missing analysis.
- **Measurement twist worth its own section:** measured screen time (E4) carries
  **no independent gradient** (+27 kg/h, p = .15; joint difference vs index
  +204, p = .0039) and barely correlates with the index (R² = .018, 1 SD ≈ 20
  min/day). The per-hour headline of the abstract ("per additional daily hour of
  screen time", 602 kg/h) is not defensible as anything but a scaling
  convention. The honest statement: *self-reported digital-behavior intensity*
  predicts footprints; *device-measured screen time* does not.
- **Candidate RQ3 reframe (pending 67):** the transport gradient is positive, so
  the preregistered "lower out-of-home leisure explains the transport gradient"
  mediation cannot hold as stated. If 67 confirms lower OOH leisure among the
  digitally intensive, the interesting story becomes **substitution**: "goes out
  locally less, travels long-distance more" (long-distance +25.3 vs short +20.1;
  aviation/travel among the biggest categories). Present the mediation as
  exploratory regardless.

**Framing choices to decide now:**
(a) Lead with per-SD / %-of-mean; demote per-hour to a derived footnote with the
anchor caveat (already mostly done in code, must match text).
(b) Paper title/abstract should not promise "per hour of screen time" effects.
(c) The two-camp adjudication can stay, but the verdict is "neither
dematerialization nor an e-commerce channel effect; digital intensity marks a
higher-consumption lifestyle" — plus the item-level twist (§5.2).

## 3. What is lacking (missing results)

1. **67 mechanism output is not in the export** (next TRE run; read
   `mech_diag.csv` first). Until then RQ3 has zero results in hand.
2. **Volume vs. composition decomposition (the missing centerpiece).**
   Quick accounting from existing tables: index → spending +12,855 SEK/SD
   (+3.85% of mean 333,939 SEK) vs. CO2e +203.9 kg/SD (+4.53% of mean). At the
   sample's average intensity (0.01348 kg/SEK) the spending gradient alone
   implies ~173 kg ≈ **85% of the headline gradient is "buys more"**, only
   ~15% "buys dirtier". Run this properly: model CO2e/spending intensity on the
   index (M5), or a log-log elasticity, or Engel/budget-share regressions per
   category. Without it, the category decomposition is mostly a budget-share
   restatement (groceries leads because groceries are ~23% of the budget).
3. **No causal-inference strategy beyond covariates + DeSO FE.** At minimum:
   Oster/Altonji-style coefficient-stability bounds; occupation/employment
   controls (HuvInkKallaAlt is already wired into `10_load_data.R` for 64);
   marital status. Panel data back to 2019 exists but is unused for
   falsification (see §5.1).
4. **No literature/frontier brief for this project** (`briefs/` has only the
   electricity brief). The "first individual-level evidence, to our knowledge"
   claim needs the evidence-protocol search (contradictory results, replications,
   terminology variants) before it goes in an Introduction.
5. **Equivalence testing is effectively absent**: the single TOST row
   (placebo_insurance) reports pass = FALSE, feasible = FALSE — the design is
   underpowered at the chosen bounds (delta = min(1% of category mean, 10% of
   expected transport gradient) with **unverified D_NOCAR = 90.5 / K_GAP = 2**,
   still flagged in code). Either verify those constants against published TRE
   numbers, widen bounds defensibly, add placebos with real variance, or drop
   the "placebo passed" language and report the CI honestly.
6. **Representativeness analysis.** Sample: mean age ~31, ~35% students, 73%
   carless, ~93% apartment (D1), 60–69% tertiary among reporters, mean footprint
   4.5 t (well below Swedish averages). You have full register linkage — a
   comparison table vs the LISA population (and optionally post-stratified
   estimates) would pre-empt the obvious external-validity attack, especially
   since the abstract promises conclusions "where digitalization is most
   plausibly emission-reducing" in the population. Heterogeneity is currently
   underpowered (65+ cell: 560 ± 563).
7. **Pre-registration deviations table.** Deviations already made: (i) ecom/
   online-selling items removed from the index (well motivated — outcome built
   into exposure; show both: 214.3 vs 203.9), (ii) battery gate 13→11 items,
   (iii) headline scale changed from "per daily hour of screen time" (prereg
   RQ1 wording) to per-SD, (iv) rent placebo → housing-tenure outcome. These are
   defensible but must appear in the paper as deviations with dates/rationale.

## 4. Results that need additional analysis

4.1 **The broad-based positive gradient (all categories up).** Formalize the
volume-vs-composition split (§3.2). Also report the D5–D1 index-quintile
contrast in kg and % (policy-relevant magnitude; per-SD is abstract). Check
whether marginal basket intensity (CO2e/spending) rises with the index at all;
the CO2e/income +221.6 kg per 100k SEK (p = .014) suggests a small composition
effect but the spending-normalized version is missing.

4.2 **Calls (q11b_2, +385 kg/item-SD — the largest item; no-calls variant drops
the headline 31% to 140.8).** Calls is nearly invisible in measured screen time
(r = .067 with E4). What is it proxying for — occupational communication,
sociability, age? Needed: calls gradient by occupation/employment/WFH and by age
band; calls vs income/spending correlations; calls gradient within index-SD
strata; a "calls-only vs rest-of-index" horse race. If calls is a work/lifestyle
marker, say so; the exposure construct's interpretation depends on it.

4.3 **E4 vs. index divergence.** Already documented (e4_rq1/rq2/index_test), but
needs a validity section: convergent validity of the index against E1 items (WFH
+0.44 d/SD, BNPL +0.23, etc.), against E4, and against behavior (spending).
Consider framing E4 as a fallible indicator and the index as a formative
composite (α = 0.56 is fine for formative, but state the measurement model
explicitly — reviewers will ask). Note the E4 subsample's index slope is larger
(238 vs 204 kg/SD; derived per-hour 732 vs 603) — check and report scale
consistency across samples.

4.4 **Transport result (positive) and the transport split.** Short +20.1 ns /
long +25.3 p = .058: both directions positive but individually fragile; the
preregistered demobilization test is a category-level falsification and should
be presented as such with the CI ([-0.9, 51.4] for long includes small negative).
Exploratory: transport × car ownership (car owners −0.6 ns vs carless +41.3
p = .012) — demobilization cannot reduce what isn't there; label exploratory
(car ownership is endogenous).

4.5 **Coverage story (gradient concentrated in 3+ accounts; −24% in the
spending-plausible band).** Two readings not yet separated: (i) measurement
error attenuates the 1–2 account estimates (favorable), (ii) multi-account users
are financially more complex/high-consuming (unfavorable). Compare covariate and
spending distributions across account groups (account_groups_desc shows similar
mean index but rising income/spending) and consider an errors-in-variables
discussion or a bounding statement rather than picking the favorable reading.

4.6 **Fragile category rows in the decomposition.** aviation p = .048, alcohol
p = .0001 (check: plausible? alcohol +7.7 kg/SD — could be a social-lifestyle
marker), uncategorized +16.7 (437 kg mean — a big data-quality bucket with a
significant gradient; needs a "what's in it" diagnostic). Apply FDR across the
category family or restrict formal inference to the pre-specified groups
(transport/ecom/digital/placebo/vehicles).

4.7 **Equivalence/placebo** — see §3.5. Additionally: the rent SEK gradient is
significantly negative (−1,255 SEK/SD, p = .036 full sample; −1,259, p = .111
among stable renters) — consistent with the tenure story (renters = students =
lower footprints), which supports the confounding reading of the headline and
should be discussed in the same breath as tenure_sensitivity (+187.6 vs +203.9).

4.8 **M1 suppression pattern (M0 179.7 → M1 274.2 → M2 197.8).** Explain in
text: age/sex suppress (older = higher footprints, lower index), income/education
absorb part. Reviewers will read the ladder; give it one paragraph.

## 5. Areas warranting further exploration

5.1 **Pre-window falsification / timing.** Transactions extend back to 2019 but
the analysis window is the 12 months before the baseline survey. Estimate the
index gradient by calendar year (2019 → 2024): (a) if the gradient predates the
survey window equally, it is a stable-trait association (supports "lifestyle
marker", weakens any contemporaneous-causation reading); (b) gradient growth
over time would support a diffusion/rebound reading. Cheap, high value.

5.2 **"Sociable vs. solitary" digital lifestyles.** The only demobilization-type
signals in the data are at item level: streaming −87** and gaming −54 (BH .061)
negative, while calls +385, social media +175, search +181 are positive; and
`social_games.csv` already shows social media → transport +60.9, restaurant
+16.7, while gaming is null/negative. A "which digital lifestyle" split
(sociable/out-and-about vs. solitary/stay-at-home) could rescue the
demobilization hypothesis at the *item* level and is a genuinely novel
contribution. Preregister as v3 before running.

5.3 **Seasonality/annualization robustness.** `annualise()` accepts ≥3 valid
months per category and scales ×12 on months with >3,000 SEK spending; mean
spending/income ratios 1.11–1.45 suggest upward bias, and travel/aviation
annualized from 3 summer months will be seasonally skewed. Robustness: ≥6/≥12
months (partially done for the total), and a calendar-window-fixed variant.
Also: individuals' transactions only — couples' payer assignment can produce
the gender gap (men +253 vs women +157) as a payer artifact; note it.

5.4 **CO2e-factor sensitivity.** Category factors (aviation, food) carry real
uncertainty; a re-run with alternative factor sets or dropping the most
uncertain categories would strengthen the "total" claim.

5.5 **DeSO FE *increases* the estimate (+254.6).** Worth a paragraph: sorting
into low-emission neighborhoods suppresses the raw gradient. Nice descriptive
point.

5.6 **E4's own (small) positive patterns** — digital services +0.97 kg/h
(p = .001), clothing +3.5 kg/h (p = .032) in e4_rq2: measured screen time links
to digital-services spending — the one direct-effect nugget the rebound camp
would want. Small but honest; include.

## 6. Technical/measurement critiques

- **Derived per-hour CIs treat the anchor b = 0.338 as fixed** (SE/b ≈ 17%).
  Per-hour CIs in stepwise_table etc. understate uncertainty by ~17% relative.
  Propagate the anchor SE (delta method) or state CIs are conditional on the
  anchor. `calibration_check.csv` audits identities but not this.
- **Decomposition display is non-additive**: `decomp_table.csv` mixes top-10
  leaves (e.g., `top_clothing_co2e`) with group composites that contain those
  same leaves (ecom includes clothing/electronics/books/toys/sports/
  shopping_other/home_garden). The pres waterfall shows only 5 groups that do
  not sum to the +203.9 total. The paper needs one mutually exclusive set of
  blocks summing exactly to the headline (verify_export checks the total
  internally, but the reader can't see it).
- **"Ecom" naming**: the group is "e-commerce-intensive goods", not observed
  online purchases (unless transaction channel data exists — confirm). The
  category mapping justification remains an open item (continuity open question
  4).
- **Equivalence constants** D_NOCAR/K_GAP still unverified (code comment says so).
- **Housekeeping:** descriptives.csv E4 row label bug (known); optout.csv counts
  don't obviously reconcile (n = 754 vs 292 + 124 vs the 585 opt-outs in
  e4_diagnostics) — clarify what n means; age-band 65+ cell is tiny.

## 7. Prioritized next actions

1. Run TRE (67) → `mech_diag.csv` first, then the mechanism tables; decide the
   RQ3 reframe.
2. New script: volume-vs-composition analysis (intensity outcome + budget
   shares + D5–D1 contrast). This determines the paper's interpretation.
   **[implemented 2026-10-07 as `eriksson-code/68_volume_composition.R` —
   mock-verified, awaiting the TRE run]**
3. Calls deep-dive (4.2) + sociable-vs-solitary item split (5.2, exploratory or
   prereg v3).
4. Pre-window year-by-year gradient (5.1).
5. Document prereg deviations (§3.7); write the representativeness table (§3.6).
6. Fix the additive decomposition presentation + per-hour CI propagation.
7. Literature brief for the "first individual-level evidence" claim.
8. Then start the manuscript in earnest; abstract must be rewritten to match
   (no "per hour of screen time" effects; demobilization verdict = refuted at
   category level).
