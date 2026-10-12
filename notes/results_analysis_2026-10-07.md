# Results analysis — TRE run 2026-10-07 (mechanism 67 + volume/composition 68)

Analyzes the latest copy-out in `TRE_output/` (`run_info.csv`: run_date 2026-10-07,
R 4.3.3, spec unchanged — 11-item main index, ≥ 8/11 battery gate, bivariate
anchor, per-SD headline). Every number below is sourced to its table. This is
the first export containing the 67 (mechanism) and 68 (volume-vs-composition)
outputs; the 2026-10-05 headline numbers reproduce to full precision, so the
run is a clean re-run of the frozen spec plus the two new scripts.

## 0. Integrity

- `eriksson-code/verify_export.R` against `../TRE_output`: **all 16 invariants
  pass**, including the two new volume-split checks (15: `volume_margins.csv`
  M5 CO2e row ≡ ladder M5; 16: volume + composition + residual recomputes to
  the headline). The README caveat that checks 15–16 lacked a real export is
  now resolved.
- `mech_diag.csv` (check this first, per 67's design): `share_code_8_9 = 0`
  for all 12 E1 items — no grid-order miscoding, the 7-point scale is clean.
  **But heavy ceiling effects in the at-home set**: music 84.8% at the maximum,
  tv_series 51.7%, exercised 44.6%, book 21.0%, nature 12.8%. The at-home
  composite (mean 6.8/7 for music) has little variance to carry anything.

## 1. The centerpiece: the gradient is spending VOLUME, not a dirtier basket

`volume_composition.csv`, `volume_margins.csv`, `quintile_contrast.csv`:

| Component | kg CO2e/yr per index SD | share of headline | p |
|---|---|---|---|
| Headline (M5) | +203.9 (SE 32.3) | 100% | 2.9e-10 |
| Volume (mean intensity × spending gradient) | **+196.1** (SE 28.9) | **96.2%** | 1.3e-11 |
| Composition (intensity gradient × mean spending) | +26.9 (SE 19.5) | 13.2% | **.167 (ns)** |
| Covariance residual | −19.1 | −9.4% | — |

- The critique's quick accounting predicted volume ≈ 85–95% of the gradient —
  the proper split lands at **96%**, i.e. even more volume-dominated.
- Formal composition test (M5 intensity, kg CO2e per 1,000 SEK): **+0.105 per
  SD (p = .167)**, = +0.58% of mean intensity (17.92). The "buying dirtier"
  premium is `pct_premium` = **0.27 percentage points** of the mean
  (CO2e +4.53% vs emission-relevant spending +4.26% per SD).
- Scale-free confirmation: log CO2e +0.039 log points/SD (+4.0%) vs log
  spending +0.032 (+3.3%) — nearly the same elasticity.
- Equal-spending descriptive rows (not headline specs): +34.2 kg (p = .088)
  and +0.85% in logs (p = .036) — a small residual composition difference,
  consistent with the ns intensity margin.
- Policy-relevant magnitude (`quintile_contrast.csv`): adjusted **D5–D1 =
  +599 kg CO2e/yr (13.3% of the mean, p = 3.4e-9)**, of which spending
  +31,914 SEK (12.4%) and intensity +0.34 kg/1,000 SEK (1.9%, p = .15).
  Register income rises only 293k → 315k (+7.6%) across quintiles
  (`quintile_desc.csv`) — the volume gradient exceeds the income gradient.
- Engel shares (`budget_shares.csv`, 30 rows, BH re-checked here): only two
  rows survive BH < .05 — **restaurant share of spending +0.29 pp/SD
  (p = .0022)** and **public-transport share of CO2e −0.18 pp/SD
  (p = .0010)**; ecom spending share +0.32 pp is BH .099. Nominal-only
  (do not headline): shopping_other +0.13 pp (p = .042), public-trans
  spending share −0.08 pp (p = .021), groceries CO2e share +0.34 pp
  (p = .050 — grocery basket gets a larger share of the carbon budget even
  as its spending share falls). Everything else ns. **Treat the budget-share
  table as descriptive reshuffling within the goods budget**, on top of a
  volume story.

**Interpretation for RQ2 (decisive):** "buys more", not "buys dirtier". The
category decomposition is largely a budget-share restatement of the volume
gradient. The e-commerce channel and direct digital emissions stay
carbon-trivial. This is the consumption-capacity/lifestyle reading the
critique (§2, §4.1) predicted — and it should now be the paper's RQ2
centerpiece.

## 2. RQ3 mechanism (67): the preregistered demobilization mechanism is refuted — the first leg runs the wrong way

`e1_leisure_index.csv`, `e1_leisure_mechanism.csv` (n = 2,392 E1 responders
with M5 sample membership):

- **The digitally intensive do NOT go out less.** Index → out-of-home leisure
  composite (1–7 scale): **+0.073 points per SD (p = 8.8e-5)** — positive.
  At-home leisure: +0.137 per SD (p = 1e-13). Item level: film +0.217,
  tv_series +0.255, sports events +0.164, audiobook +0.150, dancing +0.144,
  dinner guests +0.137, culture events +0.088 (all p < .003); null:
  library −0.013, exercised −0.028, nature +0.018, book +0.022.
  Both registered sets move UP with digital intensity.
- **Mediation is negligible.** Transport gradient in this subsample +62.7
  (p = .019) → +61.6 with the OOH mediator (**share 1.8%**) → +56.7 with both
  (**share 9.6%**). The mediator→transport coefficients are ns and small:
  OOH +15.4 kg per point (p = .59), at-home +43.0 (p = .21) — an OOH
  composite that barely predicts transport cannot mediate the transport
  gradient. For the total gradient: 4.4% → 10.3% shared; here the mediators
  are positively associated with CO2e (OOH +143 kg/point, p = .0028;
  at-home +125, p = .026) — again the wrong sign for demobilization.
- Subsample sanity: +237.8 kg/SD total and +62.7 transport in the E1
  subsample vs +203.9 / +45.6 in the full M5 sample — similar, so the
  direction flip is not sample selection.
- The critique's fallback "substitution" story ("goes out locally less,
  travels long-distance more") is **also dead**: sports events, culture
  events, dinner guests, and dancing all rise with the index.

**Verdict for RQ3:** the registered mechanism fails at its first leg
(direction) and in mediation (share ≤ 10%, ns). It must be reported as a
preregistered negative/falsification result, not reframed post hoc. What
survives is a coherent positive picture: digital intensity marks a
*sociable, active, high-consumption* lifestyle — more out-of-home leisure,
more at-home media, more spending in almost every category. This dovetails
with the item level (calls +385, social media +175 positive; streaming −87,
gaming −54 negative) and `social_games.csv` (social media → transport +60.9,
restaurant +16.7; gaming null/negative).

## 3. What the 2026-10-07 run settles, in one paragraph for the paper

Digital lifestyle intensity does not dematerialize consumption (RQ1:
+203.9 kg CO2e/SD ≈ +4.5% of mean, all robustness intact), but the gradient
is almost entirely **consumption volume** (96% of it; basket intensity flat,
p = .17) rather than a dirtier basket or an e-commerce/digital channel —
and the preregistered demobilization mechanism is refuted at the category
level (transport +45.6, p = .015), at the item level (streaming/gaming are
the only negative items), and now at the behavioral-mechanism level (more,
not less, out-of-home leisure; ≤ 10% mediation share). Measured screen time
(E4) still carries no independent gradient. The honest headline: *self-
reported digital intensity is a marker of an active, higher-spending
lifestyle with a proportionally higher — not dirtier — carbon footprint.*

## 4. Open items after this run

1. **Prereg deviation table** now needs a fourth entry: RQ3's registered
   mechanism hypothesis is falsified (date, exact wording, this run).
2. **Mechanism caveats to state**: E1 self-report frequencies with severe
   ceiling effects (at-home set, §0); the OOH composite barely predicts
   transport (+15 kg/point, ns) which caps any mediation; the mediators are
   post-treatment outcomes of the lifestyle (do not "control them away" in
   headline specs).
3. Budget-share family: report BH-adjusted (2 of 30 survive) or restrict to
   the pre-specified groups — the nominal restaurant/public-trans rows are
   the only ones worth naming.
4. Still unfixed since the critique: calls deep-dive (4.2), sociable-vs-
   solitary item split as prereg v3 (5.2), pre-window year-by-year gradient
   (5.1), additive mutually-exclusive decomposition display, per-hour CI
   anchor-SE propagation (delta method; SE/b ≈ 17%), equivalence constants
   D_NOCAR/K_GAP, representativeness vs LISA, literature brief.
5. Cosmetic (fixed in code for the next run, this export still shows it):
   `descriptives.csv` E4 row labeled "Valid E4 reporters" but n = 2,082 is
   the anchor sample (E4 ∩ valid index; valid reporters = 2,200 per
   `e4_diagnostics.csv`).

## 5. Checks run for this analysis

- `Rscript verify_export.R` (eriksson-code/): 16/16 pass (2026-10-07).
- BH correction recomputed on all 30 `budget_shares.csv` rows (2 survive at
  .05: public-trans CO2e share, restaurant spending share).
- Cross-checked headline identity across `stepwise_table.csv`,
  `decomp_table.csv`, `volume_margins.csv`, `quintile_contrast.csv`.
