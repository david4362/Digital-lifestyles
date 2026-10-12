# Code review — `eriksson-code/` pipeline

Date: 2026-10-12. Scope: all 40 R scripts (~3,050 lines) plus `RUN_TRE.R`,
`RUN_MOCK.R`, `verify_export.R`, `00_mock_data.R`, `05_labels.R`.

Review criteria (per author):
1. Clarity above all — a non-programmer reviewer must be able to follow the analysis; minimize conditionals and abstractions.
2. No defensive coding — the input is static and fully controlled.
3. Consistent style — data.table + native R, no tidyverse.
4. Minimally verbose, comments included.

## Verification performed

- Read every script in full.
- `Rscript RUN_MOCK.R` — full pipeline runs end-to-end, no errors; planted
  effects recovered sensibly (anchor b = 1.198 vs planted 1.2; mechanism
  share 61% planted; volume/composition stopifnots TRUE).
- `Rscript verify_export.R` on the frozen `TRE_output/` — all 16 invariant
  checks pass.

## Overall verdict

The codebase is in good shape against all four criteria. No tidyverse
anywhere; every model is the same HC3-on-`lm` pattern; the numbered-script
pipeline order plus the "why" comments (preregistration provenance,
sample-freezing rationale, join-direction semantics, category definitions
centralized in 20) are exactly what lets a non-programmer follow it. The
findings below are one genuine defect, a handful of defensive structures to
remove, and consistency cleanups.

## Criterion 1 — Clarity

Strong overall. Ranked offenders:

1. **`46_heterogeneity.R`, the margins block** — the densest code in the
   repo: nested `rbindlist(lapply(...))`, coefficient-name string surgery
   (`lvl_of`, `gsub("index|:", "")`), `if (length(hit) == 0)` fallback,
   `hit[1]`. The extraction logic is *correct* (I traced it: level slope =
   `index` + `index:level` coef, delta-method SE from the HC3 block), but no
   non-programmer can follow it, and no programmer should have to. There are
   only three variables (band, gender, major_city) and one interaction
   coefficient per level — write the slope/SE for the reference level and the
   non-reference case as an explicit two-branch `if` with a comment showing
   what an interaction coefficient name looks like (`genderMan:index`), or
   compute the three variables in separate plain blocks.
2. **`05_labels.R`, `fulllab()`** — vectorized NA-masked lookup over stems,
   used only to build axis labels. A plain loop with one if/else would be
   trivially followable.
3. **`40_control_vars.R`, the `control_data` chain** — self-described as
   "Looks horrible". It is just four joins with column definitions between
   them; split it into named steps (join SCB + education, join demographics +
   city, join users + household, select columns). Also the single stray `|>`
   in the codebase appears here mid-chain.
4. **`68_volume_composition.R`, `vol_comp` assembly** — a 7-row table mixing
   units (kg, percent, percentage points) built from positionally-matched
   `c()` vectors with `rep()` and `NA` padding. Readers must count positions
   to know which number is which component. Splitting the shares into their
   own columns (or a second one-row table) removes the positional matching.
5. Minor: `67_mechanism.R` `fit_spec`'s NA-row padding; `50_ecommerce.R`
   `wide()`'s `paste0`/`get()` column naming; `59`'s battery-scaling block.

## Criterion 2 — Defensive coding

Structures to remove (input is static; none of these fire on the real data
or the mock):

1. **`54_item_analyses.R`: the `stopifnot` figure audit** — five
   `identical()` checks plus `item_figure_check.csv` written on every run,
   guarding against a past label/point mismatch bug. It duplicates
   `verify_export.R` check 7 exactly. Remove from the pipeline (keep the
   verify_export check); this also removes an output file that is not an
   analysis result.
2. **`64_tenure_lifestage.R` / `66_account_coverage.R`: the four
   `if (nrow(d) < 30) { message(...); return(NULL) }` branches** — never
   triggered on real or mock data, and a *silently missing* stratum row is
   easy to miss in a table. Delete; if a stratum ever were thin, `lm` will
   say so.
3. **`68`: the one-line `stopifnot`** — same argument (verify_export check
   15 covers it); lowest priority but same principle.

Everything else that looks conditional is substantive and commented as
such: NA-fills after left joins (62, 68), PC sign orientation (61 — the sign
is genuinely arbitrary), non-buyer zero shares (68), the 13-item gate in 59
(real: a person can answer ≥ 8 of 11 main items yet < 10 of 13), up-front
complete-case drops so model comparisons don't change samples (55, 63, 64,
67). These are correct, not defensive.

## Criterion 3 — Consistency (data.table + native R)

Good: zero tidyverse; base graphics throughout; `arrow`/`readxl`/`haven`
only in the loader; `sandwich`/`lmtest` only for HC3; one canonical outcome
recipe (`annualise`) and one canonical formula (`lm_formula`).

Issues, ranked:

1. **`67_mechanism.R` uses `transport_annual` defined in
   `55_e1_analyses.R`** — undocumented implicit cross-script dependency;
   nothing in 67's comments mentions it. Running 67 alone fails. This is the
   one finding I'd call a defect. Build it locally from `annualise` (two
   lines, as 63/64 do) or state the dependency in a comment.
2. **`T`/`F` vs `TRUE`/`FALSE`** — 56 vs 28 `na.rm` occurrences alone.
   Earlier scripts (10, 20, 40, 43, 45, 47, 50–55, 63, 68) use `T`; later
   ones (59–62, 64) use `TRUE`. Standardize on `TRUE`.
3. **Duplicated logic across scripts** — the repo itself argues for
   centralization ("so the grouping cannot drift", 20); the same logic
   applies to these:
   - the `top10`/`targets` block is copied verbatim in 43, 47, 52 (variant
     in 68);
   - `bucket()` defined in both 63 and 64;
   - `fit()` near-identical in 50 and 68;
   - `fit_row()` in 63 and 66 with *different* signatures;
   - `e4_data` built identically in 52 and 65;
   - the 0–18 h/day E4 rule appears in 30 and is re-derived in 65 (and the
     65 copy is subtly different — no demographics join — so the two can
     drift);
   - the `run_info` block is duplicated verbatim in `RUN_TRE.R` and
     `RUN_MOCK.R`;
   - the lm → coeftest → extract `"index"` → data.table-row boilerplate
     appears ~20 times with four local helper styles.
   Suggestion: put shared helpers next to `annualise` in 20 (or a small
   `15_helpers.R`): one HC3-slope function (the existing `fit_row` pattern),
   one targets builder, one `bucket`. Same tradeoff as `annualise` itself —
   a single-recipe function, which the codebase already treats as its
   clarity pattern.
4. **`sapply(top10, function(x) x, simplify = FALSE)`** (43, 47, 52, 68) —
   obscure idiom for `as.list(top10)`.
5. **`=` vs `<-`** mixed across scripts (e.g. 42 uses `<-`, 46 uses `=`).
   Pick one.

## Criterion 4 — Verbosity

The comments are long but almost all load-bearing: they encode
preregistration provenance, why rent leaves the CO2e outcomes, why the
bivariate anchor feeds the pipeline, join-direction semantics. For the
criterion-1 audience they are the main reason the code is followable — keep
nearly all. Specific trims:

- `66`: "'Reasonable' is a judgment call … both bands are reported" appears
  twice (header item 6 and again above `band_row`).
- `48`: "h_per_sd … is defined in 40" repeats within the same comment block.
- `65`'s platform-split impossibility note is a research note more than code
  documentation — candidate for `notes/` or `metadata.md` (harmless in place).
- The result-row boilerplate (criterion 3 item 3) is where most repeated
  verbosity lives; the shared helper removes it.
- `41`: `hours_per_index_sd = (b_z / sd_raw) * sd_raw` is a deliberate
  tautology (auditing the arithmetic that once failed to add up) — add the
  words "identity by construction" so readers don't hunt for content in it.

## Correctness spot-checks (no action unless noted)

- `48` TOST arithmetic: correct (both one-sided p's; the `t2` form relies on
  t-symmetry, valid).
- `46` level-slope extraction and delta-method SE: traced, correct.
- `40` index construction (z on analysis sample, mean of answered items,
  re-standardize) matches the documented recipe; the anchor standardization
  identity (slope = h per SD) holds as documented.
- `62` interior-month rent rule: consistent with its window-edge rationale;
  with `min_months = 3` every participant has ≥ 1 interior month.
- `20`: `submitdate - 31 * x_months` is 372 days for "12 months" — a
  ~6-day-wider window. Months are truncated to month starts so it is mostly
  harmless on static data, but it deserves the one-line comment it lacks
  (or exact calendar-month arithmetic).
- Mock design: planted gradients, partial batteries, duplicate demographics
  rows, opt-outs, rent faults, and out-of-study bank records all exercise
  the real code paths — the mock run is a genuine test, not a smoke test.

## Action list

Must fix:
1. `67`: remove the undocumented dependency on 55's `transport_annual`.

Should fix (criteria 2/3):
2. `54`: delete the in-pipeline `stopifnot` audit + `item_figure_check.csv`
   (covered by verify_export check 7).
3. `64`/`66`: delete the four `n < 30` silent-skip branches.
4. Standardize `TRUE`/`FALSE`.
5. Consolidate the duplicated blocks/helpers listed under criterion 3.3.

Nice to have (criteria 1/4):
6. Rewrite `46`'s margins block; simplify `05_labels.R` `fulllab`; split
   `40`'s chain into named steps; restructure `68`'s `vol_comp` table.
7. `as.list(top10)`; one assignment operator; `|>` consistency in 40.
8. Comment trims (66, 48), the identity note in 41, the 372-day note in 20,
   and relocating 65's platform note.

## Addendum 2026-10-12 — items applied

Must fix (1) and should fix (2-5) applied in one pass, net -80 lines:

1. `67` builds `transport_annual` locally via `group_annual` (see 5 below).
2. `54`: in-pipeline `stopifnot` audit + `item_figure_check.csv` removed;
   figure labels/points now come from the same table rows by construction.
   `verify_export.R` check 7 dropped (its subject file no longer exists),
   checks renumbered 1-15; export README + data dictionary updated.
3. `64`/`66`: all four `n < 30` silent-skip branches removed.
   `68`'s one-line `stopifnot` removed (verify_export check 14 covers it).
4. `T`/`F` standardized to `TRUE`/`FALSE` everywhere (13 scripts).
5. Duplicated logic consolidated, each defined once:
   - `20`: `group_annual()` (the bucket/yy sum; 43/47/52/54/55/63/64/67) and
     `decomp_targets()` (the targets block; 43/47/52). 68's variant keeps
     its local block but uses `setNames(as.list(top10), ...)` instead of the
     `sapply` idiom and the positional `names(targets)[...]` indexing.
   - `40`: `form0` (was defined locally in 43/47/50/63/68), `m5_row()`
     (was `fit()` in 50 and 68), `fit_row()` (was local to 63 and 64 with
     drifting signatures), and `e4_data` (was defined identically in 52, 60
     and 65). 60 works on a `copy(e4_data)` so the shared table is never
     modified.
   - `30`: `screen_valid` (the 0-18 h/day rule, pre-demographics-join);
     `screen_time` is now defined as the joined subset. `65` reuses
     `screen_valid` instead of re-deriving the rule.
   - `70_run_info.R`: the run manifest block shared by `RUN_TRE.R` and
     `RUN_MOCK.R` (both now source scripts 20-70).

Verification: `RUN_MOCK.R` end-to-end; all 73 analysis outputs byte-identical
to the pre-change baseline (only `item_figure_check.csv` absent, export docs
updated, `run_info.csv` differing in its tempdir path). `verify_export.R`
on the frozen `TRE_output/`: all 15 checks pass.

## Addendum 2026-10-12 — nice-to-have items applied

Item 6 (clarity):
- `46`: the margins block rewritten as an explicit `level_rows(m, v, lv)`
  helper — reference level = index coefficient, other levels = index +
  interaction coefficient with delta-method SE, one rbind of the three
  variables. The coefficient-name matching handles either variable order
  (R orders interaction names by first appearance in the formula:
  `genderMan:index` but `index:major_cityTRUE` — the first rewrite attempt
  assumed one order and failed loudly in the mock run, which is how the
  ordering was pinned down). `gender` is now an explicit factor (it arrives
  as character from 10's fcase), making the reference level visible.
- `05_labels`: `fulllab` rewritten as a plain per-name lookup (group via
  grouplab, top-10 leaf via stemlab, fallback = spaced stem) instead of the
  NA-masked vectorized lookup.
- `40`: the control_data chain split into four named steps (SCB, demo-
  graphics, users profile, battery + column select), same operations in the
  same order so each centering mean hits the same rows; the stray `|>` and
  a leftover `with = F` are gone with it.
- `68`: `vol_comp` built row by row via `comp_row()` (component, unit,
  estimate, se, p, share as named fields) instead of positionally matched
  `c()` vectors; CSV schema unchanged.

Item 7 (style):
- Assignment operators standardized on `=` (bare-identifier assignments;
  `<-` remains only where R requires it: `names(x) <-` in 10, `x[i] <-` in
  46's figure labels). `.lintr` updated: `assignment_linter = NULL`.
- `as.list` idiom already applied in the previous round.

Item 8 (comments):
- `66`: the twice-stated "reasonable is a judgment call" sentence now only
  in the header; `48`: h_per_sd cross-reference de-duplicated; `41`:
  `hours_per_index_sd` marked "identity by construction"; `20`: the window
  filter's 372-vs-365-day approximation documented at `x_months`.
- `65`: the 20-line platform-split note moved to `metadata.md` ("E4
  platform split") with a one-line pointer in the script header.

Verification: `RUN_MOCK.R` end-to-end, all 73 analysis outputs byte-identical
to the pre-change baseline (run_info.csv differs only in its tempdir path);
`verify_export.R` on the frozen TRE_output: all 15 checks pass; every R
file parses.

Remaining known non-issues (documented, not changed): `TRE_output/` still
contains the frozen `item_figure_check.csv` from the 2026-10-07 run — the
next real-data run will simply not write it.
