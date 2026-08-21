# Continuity notes — Digital lifestyles paper

Read this first each session. Keep it updated: decisions, open questions, next steps.
(Newest entries at top within each section.)

## Status

- **2026-08-21 — MAJOR UNBLOCK.** David supplied the questionnaires + baseline
  codebook (now in `docs/`): `Pre-treatment_survey.pdf` + `_codebook.csv`
  (baseline), `Endline_survey.pdf`, `WP1_digital_lifestyles_plan_abstract_OSF.docx`
  (extended abstract; canonical text in `notes/extended_abstract.md`).
  All July mysteries resolved:
  - **q11_1–q11_5+** = device-use frequency battery, 1–6 scale ("Ej använt" …
    "Flera gånger i timmen"): stationär/bärbar dator, mobiltelefon/smartphone,
    TV, spelkonsol, surfplatta. → the *device-use* half of the digital index.
  - **q11b_1–q11b_8** = digital-activity frequency battery, same scale:
    film/serier/YouTube, telefon-/videosamtal, sociala medier, informationssökning,
    dataspel/tv-spel, digital läsning, **e-handel (q11b_7)**, sålt online (q11b_8).
    → the *digital-activity* half of the index; q11b_7 also feeds the
    e-commerce decomposition channel.
  - **q15_1–q15_12** = typical-price battery (SEK for haircut, sneakers, wine,
    hotel night, phone, sofa, …) — confirms July's inference: spending estimates,
    NOT time use. Not part of the digital index (candidate quality-of-consumption
    control at most).
  - **Endline E4** = screen-time anchor exactly as remembered: device-assisted
    (iOS Skärmtid / Android Digitalt välmående), average daily h:min previous
    week, with "not activated" and "skip" opt-outs (expect missingness; the
    mock endline generator's opt-out share should be calibrated).
  - **Endline E1** = 12-month activity-frequency battery (7-point) incl.
    out-of-home leisure (bibliotek, idrottsevenemang, kulturevenemang, middag,
    dansat, motionerat, naturen) and at-home digital leisure (ljudbok, musik,
    bok, film, tv-serie) → the *mechanism* variables for result 3, plus BNPL item.
  - Endline also has: policy-attitude batteries (B1–B6), WTP for CO2 reduction
    (K1–K2), app-experience battery (L1–L3), attention check (C11).
- **Team/venue (2026-08-21):** Mathias Lehner (decided), Göran Finnveden (maybe),
  Anna Furberg (possibly). Venue undecided, aim high. **Pre-registration on OSF
  required before touching real data in the TRE** — the abstract already commits
  to a "pre-registered index".
- **2026-07-18 (evening)** Screen-time item IDENTIFIED by David: **E4 in the ENDLINE
  survey** — device-assisted ("Skärmtid"/iOS, "Digitalt välmående"/Android), average
  DAILY screen time in hours:minutes for the previous week. Confirmed the endline
  survey is NOT in the local mock RData (survey object = baseline only, no E* cols).
  No endline codebook found either. => For local development, generate a synthetic
  endline E4; real validity check runs in the TRE.
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

1. **Endline survey data + codebook.** E4 (screen time) identified, but the endline
   survey is absent from the local mock and no endline codebook exists locally.
   Needed: (a) endline data extract in the TRE (or a mock thereof), (b) codebook for
   the remaining endline items (device-use / digital-activity frequencies for the
   index; out-of-home leisure frequency for the mechanism). Also unclear how E4 is
   stored (single minutes field vs separate hours+minutes fields) — loader must parse
   h:mm robustly.
2. Endline timing caveat for the paper: screen time measured at ENDLINE, consumption
   observed 2019–2024 — note reverse-causality/stability argument in design section.
2. Swedish screen-time benchmarks in `10_screen_time_validity.R` are heuristic bands;
   verify against Internetstiftelsen *Svenskarna och internet* (latest edition) and any
   device-measured Swedish studies before using in the paper.
3. Mock data caveat: values in `default_filter.RData` are synthetic — validity *checks
   logic* here; substantive conclusions wait for the TRE run.
4. Category mapping for the decomposition (which leaf categories count as
   e-commerce-intensive / digital services / placebo) — draft lives in `00_constants.R`,
   needs a documented justification for the paper.

## Next steps

1. Generate synthetic endline (`gen_mock_endline.R`): E4 minutes/day with realistic
   age gradient + h:mm heaping, so the validity + index pipeline can be developed.
2. Locate the real endline data in the TRE (object/file name unknown) and its codebook.
3. Re-point `10_screen_time_validity.R` at endline E4; verify benchmark bands against
   Internetstiftelsen *Svenskarna och internet*.
4. Build digital intensity index (`20_digital_index.R`): device-use + digital-activity
   frequencies, anchored cardinally by screen time; report reliability (alpha).
5. Net gradient models, then decomposition, then mechanism (see README pipeline table).
6. Set up TRE export checklist (mirror `Konsumtionskollen/RUN_TRE` pattern).

## Session log

- **2026-07-18** Scaffolded project; wrote loader + screen-time validity script.
  Explored `default_filter.RData`: survey 4353×114, users 4353×225,
  transactions 3,493,172×166. Candidate digital items: q15_1–q15_12 (minutes),
  q11/q11b (1–6 Likert), q12 (1–4) + q12b (0–10), q13/q14 (0–7), array6 (1–7).
  Only labels recoverable from archived Rmd reports: q3 political orientation,
  q5 political assertiveness, q13 trust in people, q11b_2 social activity.
