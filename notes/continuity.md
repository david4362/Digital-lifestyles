# Continuity notes — Digital lifestyles paper

Read this first each session. Keep it updated: decisions, open questions, next steps.
(Newest entries at top within each section.)

## Status

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

- Project lives in `Digital-lifestyles/` inside the outer manuscript folder; own git repo.
- Reuse Konsumtionskollen data by path, never copy the 5.2 GB file into this repo.
- Light extract cached to `cache/digital_cache.RData` so sessions don't pay the 5-GB load.
- Follow Konsumtionskollen conventions (numbered scripts, P99 winsorization, HC3 SEs).

## Open questions / blockers

1. **CODEBOOK NEEDED — now the hard blocker.** Empirical identification failed:
   q15_* = spending estimates (SEK/month), q12b = % follow-up. The screen-time anchor,
   the digital-activity frequency items (candidates: q11/q11b Likert 1–6), and the
   out-of-home leisure item must come from the LimeSurvey questionnaire /
   pre-registration. David to supply.
2. Swedish screen-time benchmarks in `10_screen_time_validity.R` are heuristic bands;
   verify against Internetstiftelsen *Svenskarna och internet* (latest edition) and any
   device-measured Swedish studies before using in the paper.
3. Mock data caveat: values in `default_filter.RData` are synthetic — validity *checks
   logic* here; substantive conclusions wait for the TRE run.
4. Category mapping for the decomposition (which leaf categories count as
   e-commerce-intensive / digital services / placebo) — draft lives in `00_constants.R`,
   needs a documented justification for the paper.

## Next steps

1. Run `00_load_data.R` + `10_screen_time_validity.R`; review `output/`.
2. Obtain codebook; fix the q15 mapping; update `00_constants.R` (`SCREEN_TIME_ITEM`).
3. Build digital intensity index (`20_digital_index.R`): device-use + digital-activity
   frequencies, anchored cardinally by screen time; report reliability (alpha).
4. Net gradient models, then decomposition, then mechanism (see README pipeline table).
5. Set up TRE export checklist (mirror `Konsumtionskollen/RUN_TRE` pattern).

## Session log

- **2026-07-18** Scaffolded project; wrote loader + screen-time validity script.
  Explored `default_filter.RData`: survey 4353×114, users 4353×225,
  transactions 3,493,172×166. Candidate digital items: q15_1–q15_12 (minutes),
  q11/q11b (1–6 Likert), q12 (1–4) + q12b (0–10), q13/q14 (0–7), array6 (1–7).
  Only labels recoverable from archived Rmd reports: q3 political orientation,
  q5 political assertiveness, q13 trust in people, q11b_2 social activity.
