# Archive: exploratory analysis scripts (July–August 2026)

Pre-codebook exploration from before the real pipeline existed. Superseded by
`eriksson-code/` (see `RUN_TRE.R` there); kept only as a record of the
screen-time item search that led to identifying endline item E4.

- `00_constants.R` / `00_load_data.R` — extract from the local mock RData
  (`../Konsumtionskollen/default_filter.RData`); the old `cache/` and `output/`
  at the project root belonged to these.
- `09_baseline_battery_profile.R` — nominated a screen-time anchor from the
  `q15_*` battery by empirical signature (the 2026-08-21 codebook later showed
  `q15_*` are SEK price estimates, not time use).
- `10_screen_time_validity.R` / `gen_mock_endline.R` — validity checks against
  a synthetic endline E4; the real-data equivalents are `eriksson-code/30` and
  the E4 sample diagnostics in `eriksson-code/41/45/52`.

Do not run these; the analysis pipeline is `eriksson-code/` only.
