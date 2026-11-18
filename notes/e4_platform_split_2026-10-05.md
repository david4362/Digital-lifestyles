# E4 platform split (iOS vs Android) — feasibility note

Finding from the 2026-10-05 TRE read-out, from the E4 diagnostics script
(`65_e4_diagnostics.R`, then in `eriksson-code/`). The note lived in that
script's header until the 2026-10-12 code review moved it into
`metadata.md`; it was relocated here on 2026-11-08. It is analysis
commentary about what the data cannot support, not study metadata:
`data/metadata/metadata.md` (and this repo's synced `metadata/metadata.md`)
holds verbatim category lists, table field lists and the headline model
formula.

## Finding

**NOT POSSIBLE with the current data.** The E4 item instructs the respondent
to read either OS's built-in tool (iOS "Skärmtid" / Android "Digitalt
välmående"), but neither the endline survey nor any cached table
(`survey_endline`, `users`, `demographics`, `scb`) records the respondent's
platform — there is no device/OS field in the kk-handels users export
either (checked against the endline questionnaire and the metadata field
lists, 2026-10-05). A split would require new data from the app side.

## Where the finding is used

- `R/65_e4_diagnostics.R`: one-line pointer in the script header; 65 is the
  script this note came from.
- `data/common-data.md` §4 (endline/E4 data facts) and §12 trap 12:
  cross-project summary of the same data limitation; §13 source map points
  here.
- `notes/brief_supervisor_2026-10-07.md` §5 and
  `notes/email_draft_2026-10-07.md`: the correspondence that proposed the
  split and asked whether a platform variable exists in the endline
  codebook or app-side data (this note settles that open question).
- `notes/continuity.md`: the 2026-10-05 results entry records "No platform
  variable — iOS/Android split needs app-side data".
