# Results brief — status 2026-10-07 (response to DA, 2026-09-28)

Provenance: two runs of the real-data pipeline in the TRE (2026-10-05 and
2026-10-07) under an unchanged specification; results reproduce to full
precision across runs. All numbers below are from the current export
(`TRE_output/`) and are traceable to the named CSV files. The export passes
all 16 automated invariant checks (`eriksson-code/verify_export.R`).

## 1. Index specification (`stepwise_table.csv`, `index_variants.csv`, `index_weightings.csv`, `index_alpha.csv`)

Work done: the main analysis now uses the preregistered index construction
excluding q11b_7 (e-commerce) and q11b_8 (online selling). The 11 items are
z-standardized on the analysis sample before aggregation (unweighted mean of
answered items, ≥ 8 of 11 required), and the composite is re-standardized.
All models are estimated on a constant sample of 4,250 participants.

Normalization: items are standardized prior to aggregation, so item variance
does not affect item weights. The difference between the two previously
exported estimates (+243 and +180 kg CO2e/SD) is attributable to the
population used for item standardization, not to the aggregation rule; under
the current specification the two scaling choices give +202.7 and +203.9
(`index_variants.csv`), a difference of 0.6 %.

M0–M5 estimates (kg CO2e per index SD; HC3 SE; R²):

| Model | Estimate | SE | 95 % CI | p | R² |
|---|---|---|---|---|---|
| M0 | 179.7 | 38.1 | 105.1–254.3 | 2.4e-06 | .005 |
| M1 | 274.2 | 37.9 | 199.9–348.2 | 5.3e-13 | .108 |
| M2 | 197.8 | 32.6 | 133.9–261.6 | 1.4e-09 | .345 |
| M3 | 197.0 | 32.3 | 133.7–260.4 | 1.2e-09 | .356 |
| M4 | 202.3 | 32.2 | 139.1–265.9 | 3.8e-10 | .365 |
| M5 | 203.9 | 32.3 | 140.7–267.2 | 2.9e-10 | .366 |

Role of the excluded items: re-including q11b_7 and q11b_8 gives +214.3
(CI 150.8–277.8), 5.1 % above the 11-item estimate. The purchase-channel
items therefore do not account for the association. The largest item-level
coefficient in the 13-item set is q11b_2 (telephone/video calls), +385 kg
per item SD; a 10-item index excluding calls gives +140.8 (CI 77.4–204.2,
p = 1.4e-05), 31 % below the 11-item estimate.

Item-set variants: device-use half +145.3, digital-activity half +174.1,
first principal component +223.1. Cronbach's α for the 11-item composite
is 0.56 (device half 0.21, activity half 0.46), consistent with a formative
rather than reflective measurement model; this should be stated explicitly.

Interpretation: the association is not an artifact of including
purchase-channel items in the exposure. The calls item contributes
disproportionately relative to the other items and is nearly uncorrelated
with device-recorded screen time (r = .067); it may proxy for occupational
communication, sociability, or age composition rather than media use.

Proposed further analyses: (i) the calls gradient by employment/occupation
and age band, and its correlations with register income and observed
spending; (ii) a horse race of calls alone against the remaining ten items;
(iii) the item-set variants above as registered sensitivity analyses.

Open decision: 11-item index as main specification with the 10-item
no-calls index as registered sensitivity (both ladders are exported).

## 2. Calibration of the per-hour scale (`calibration_check.csv`, `anchor_check.csv`)

Work done: all per-hour conversions now derive from a single audited
quantity. The previously reported inconsistency (0.369 vs 0.317 hours per
index SD) resulted from mixing index standard deviations and anchor slopes
across samples and scaling choices.

Calibration table (`calibration_check.csv`):

- anchor regression: bivariate lm(screen time ~ index), valid E4 reporters
  with a valid index;
- anchor coefficient: b = 0.3384 h per index SD (SE 0.0577, n = 2,082,
  p = 5.2e-9, R² = .018);
- index SD: 1 by construction in the M5 sample (raw composite SD 0.4356;
  0.9659 in the anchor sample);
- M5 coefficient per raw index unit: 468.1 kg CO2e; per index SD: 203.9;
- derived coefficient per hour: 602.6 kg CO2e, identical to the direct
  per-hour fit;
- three internal consistency checks: TRUE.

The per-SD scale is used as the primary scale; per-hour values are derived
and reported as secondary, as requested. Remaining qualification: per-hour
confidence intervals treat the anchor coefficient as fixed (SE/b ≈ 17 %).
Proposed further analysis: propagate the anchor uncertainty by the delta
method, or state that per-hour intervals are conditional on the anchor.

## 3. Bank-account coverage (`account_coverage.csv`, `coverage_check.csv`, `account_groups_desc.csv`)

All requested specifications, expressed per index SD with the percentage
change relative to the reference M5 estimate (+203.9):

| Specification | Estimate | 95 % CI | p | Δ vs M5 | n |
|---|---|---|---|---|---|
| M5 + accounts (linear) | 182.1 | 119.9–244.3 | 1.0e-08 | −10.7 % | 4,250 |
| M5 + account fixed effects | 181.9 | — | — | −10.8 % | 4,250 |
| M5, exactly 1 account | 113.2 | 10.0–216.5 | .032 | −44.5 % | 972 |
| M5, exactly 2 accounts | 104.8 | −5.3–214.9 | .062 | −48.6 % | 1,141 |
| M5, exactly 3 accounts | 234.2 | 104.5–363.8 | .0004 | +14.8 % | 920 |
| M5, 4+ accounts | 298.9 | 145.8–452.0 | .00014 | +46.6 % | 1,217 |
| spending / register income | 0.140 | 0.00–0.28 | .050 | — | 4,239 |
| CO2e / register income (kg per 100k SEK) | 221.6 | 45.3–397.9 | .014 | — | 4,239 |
| M5, spending 50–150 % of income | 154.7 | 93.4–216.0 | 7.9e-07 | −24.1 % | 3,253 |
| M5, spending 25–200 % of income | 164.1 | 103.1–225.0 | 1.4e-07 | −19.5 % | 3,891 |

Related gradients (`coverage_check.csv`): +0.098 accounts, +12,855 SEK
observed spending and +6,650 SEK register income per index SD.

Interpretation: account coverage does not account for the association; the
maximum attenuation in any restriction is 24 % and all estimates remain
statistically significant. Two readings of the stratum pattern are
compatible with the data: (i) classical measurement error attenuates the
estimates among thinly covered participants; (ii) participants with more
linked accounts differ systematically in financial complexity and
consumption. Mean index levels are similar across account groups while
income and spending rise with the number of accounts
(`account_groups_desc.csv`).

Proposed further analyses: covariate balance tables across account groups;
an errors-in-variables discussion or bounding statement rather than a
single preferred reading.

## 4. Item-level figure (`item_level.csv`, `item_level_forest.png`, `item_figure_check.csv`)

Work done: the figure is now generated directly from the final table. The
discrepancy reported on 2026-09-25 was caused by independent sorting of
labels and estimates in the plotting code; the CSV values were correct. A
scripted check verifies that each label carries its estimate and interval
from its own row (`item_figure_check.csv`), and `verify_export.R` re-checks
this on every copied export. All checks pass.

## 5. E4 screen-time measure (`e4_diagnostics.csv`, `e4_item_correlations.csv`, `e4_rq1_robustness.csv`, `e4_rq2_robustness.csv`, `e4_index_test.csv`)

Data quality: mean 4.39 h/day, median 3.95, SD 2.41, p95 8.58 among 2,200
valid reports (0–18 h/day rule applied; 51 reports excluded by the rule;
585 opt-outs). Heaping is 5.1 % at exactly :00 and 10.3 % at :00/:30,
consistent with values read from the device display and entered manually.
No distributional anomalies were found.

Correlation with self-reported digital behavior: neither survey contains a
separate self-reported screen-time item, so the frequency battery is the
only self-report reference. E4 correlates with the index at r = 0.134
(p = 5.2e-9; b = 0.338 h per index SD). Item-level correlations are at
most r = .176 (social media), with smartphone .127, streaming .080, and
calls .067.

Platform (iOS/Android): no platform variable is present in the current
extract, so the proposed split cannot be estimated. Whether such a variable
exists in the endline codebook or in app-side data remains to be
established.

Association with outcomes: in separate M5 models on the E4 subsample
(n = 1,969), the index is associated with +238.0 kg CO2e per SD (p = 8.6e-07)
and E4 with +65.6 kg per E4 SD (p = .148; +27.0 kg per hour). In the joint
model the index is +233.4 (p = 1.8e-06) and E4 +29.1 (p = .52); the slope
difference is +204.3 (p = .0039). The E4 null result holds in every
decomposition category (`e4_rq2_robustness.csv`). Two category-level
associations reach significance: digital services +0.97 kg/h (p = .001)
and clothing +3.5 kg/h (p = .032).

Interpretation: E4 behaves as a valid measure of device-recorded screen
time, and its weak positive correlation with the behavioral battery is in
the expected direction. The two instruments appear to capture different
constructs: device-recorded screen time (one SD ≈ 20 min/day) shows no
independent association with consumption-based emissions in this sample,
while self-reported behavioral intensity does. The index is accordingly
treated as a formative composite and E4 as a fallible indicator of a
single dimension.

Proposed further analyses: restrict the anchor sample to respondents
passing the attention check (C11) and re-estimate; a platform split if the
variable can be obtained; report convergent validity of the index against
the E1 battery alongside E4.

## 6. Reproducible package (in `TRE_output/`)

- scripts 20–68 that generated the export, executed in order by
  `RUN_TRE.R` (with a mock-data twin, `RUN_MOCK.R`, for local testing);
- `EXPORT_README.md`: index definitions and sample rules;
- `export_data_dictionary.csv`: definitions for every reported column,
  checked to match the export's files exactly;
- `run_info.csv`: run manifest (date and full specification);
- `verify_export.R`: 16 invariant checks, all passing on the current export;
- no mixing of result generations: each run rewrites the output directory
  wholesale; the superseded first-pass export is archived at
  `archive/TRE_output_2026-09-25/`.

## 7. Additional results since 2026-09-28

7.1 Volume versus composition of the gradient (`volume_composition.csv`,
`volume_margins.csv`, `quintile_contrast.csv`, `budget_shares.csv`).
Of the M5 gradient of +203.9 kg CO2e/SD, the volume component (mean basket
intensity × spending gradient) is +196.1, or 96.2 %; the composition
component (intensity gradient × mean spending) is +26.9, or 13.2 %
(p = .17); the accounting residual is −19.1. The basket-intensity margin
is +0.105 kg CO2e per 1,000 SEK per SD (p = .17), i.e. a composition
premium of 0.27 percentage points of the mean (CO2e +4.53 % vs
emission-relevant spending +4.26 % per SD). In log terms, +0.039 log points
per SD for CO2e against +0.032 for spending. The adjusted D5–D1 quintile
contrast is +599 kg CO2e (13.3 % of the mean, p = 3.4e-9) on +31,914 SEK
spending (12.4 %); register income rises 7.6 % across quintiles. Of 30
budget-share margins, two survive Benjamini–Hochberg adjustment at 5 %
(restaurant spending share +0.29 pp/SD; public-transport CO2e share
−0.18 pp/SD).

Interpretation: the association operates predominantly through the volume
of consumption rather than through basket composition or the
e-commerce/digital channels. The spending gradient exceeding the income
gradient is consistent with a consumption-capacity or lifestyle
association, though the cross-sectional design does not identify a causal
direction. The budget-share shifts are small and should be presented as
descriptive.

Proposed further analyses: estimate the gradient by calendar year in the
2019–2024 transaction panel to assess its stability over time;
coefficient-stability (Oster/Altonji) bounds; sensitivity to alternative
emission-factor sets.

7.2 Leisure-frequency mechanism (`e1_leisure_index.csv`,
`e1_leisure_mechanism.csv`, `mech_diag.csv`). The registered hypothesis was
that lower out-of-home leisure frequency among the digitally intensive
accounts for part of the transport gradient. The first-stage association is
positive rather than negative: +0.073 points per index SD on the 1–7
out-of-home composite (p = 8.8e-5) and +0.137 for at-home leisure
(p = 1e-13); sports events, culture events, dinner guests and dancing all
rise with the index, while library, exercise, nature and books show no
association. Mediation is limited: the transport gradient in this
subsample (+62.7, p = .019) changes to +61.6 with the out-of-home mediator
(1.8 % shared) and +56.7 with both mediators (9.6 %); mediator coefficients
on transport are not significant. The item-code check (`mech_diag.csv`)
finds no miscoding, although at-home items show substantial ceiling effects
(music 85 % at the maximum).

Interpretation: the registered mechanism is not supported; the observed
direction is opposite to the hypothesis, and the share of the gradient
associated with leisure frequency is small. The pattern is consistent with
digital intensity marking a more active, socially engaged and
higher-spending lifestyle rather than substitution toward home-based
activity.

Proposed further analyses: report the registered hypothesis as a negative
result with a dated preregistration-deviation entry; a pre-specified
"sociable versus solitary" item split (candidates for a v3 preregistration),
motivated by the item-level pattern (calls +385 and social media +175
against streaming −87 and gaming −54).

7.3 Decomposition and transport (`decomp_table.csv`). Per index SD:
groceries +39.1, e-commerce-intensive goods +28.1, aviation +26.1,
restaurants +22.4, travel +21.5, uncategorized +16.7, clothing +10.6,
alcohol +7.7; transport total +45.6 (p = .015; long-distance +25.3,
p = .058; short-distance +20.1, p = .116); digital services +1.7; public
transport −0.9 and vehicles +0.03 (ns); insurance (placebo) +0.14 (ns).
A demobilization pattern is not present at category level. The e-commerce
CO2e share is approximately constant at 12 % across index quintiles.

Proposed further analyses: present one mutually exclusive category set
summing to the headline estimate; apply FDR within the category family or
restrict inference to the pre-specified groups; a diagnostic on the
uncategorized bucket.

7.4 Robustness summary. DeSO fixed effects +254.6 (n = 3,258); tenure
controls +187.6; ≥ 12 observed months +191.6; natural cubic spline for age
+205.5, close to the linear-age estimate (this resolves the earlier
age-band question: the simpler linear specification is adequate). All
heterogeneity margins are positive with non-significant interactions
(gender p = .13; city p = .32).

## 8. Points for discussion

1. Calls (q11b_2) in or out of the main index; recommendation: 11-item
   main specification with the 10-item variant as registered sensitivity.
2. Treatment of RQ3: report as a registered negative result, with a
   preregistration-deviation table covering (i) exclusion of the two
   purchase-channel items, (ii) the battery rule 13 → 11 items,
   (iii) the per-SD headline scale, (iv) the RQ3 outcome.
3. Abstract wording: the per-hour scale is not defensible as a headline
   claim given the anchor R² of .018; the demobilization hypothesis is not
   supported at category, item, or mechanism level.
4. Availability of a platform variable (iOS/Android) in the endline
   codebook or app-side data.
5. Whether to implement the attention-check (C11) restriction for E4.
6. Framing for the target venue: the volume–composition result and the
   registered mechanism test appear to be the two contributions that the
   current data support most directly.
