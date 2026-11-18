# Digital-lifestyles results presentation

An informal 15-minute Beamer deck built from the frozen real-data export
`output/2026-10-22/`. All numbers and figures are regenerated locally from
that export's CSV tables; no TRE access, TRE rerun, raw transaction data,
parquet cache, or mock output is used.

## Contents

| Path | Purpose |
|---|---|
| `slides.tex` | 15-slide plain-language Beamer source; numbers come from generated `\input{figures/numbers}` macros; sources and speaker context live in `\note{}` blocks |
| `make_figures.R` | Reads `output/<date>/*.csv` plus `R/05_labels.R`; writes polished vector PDFs |
| `verify_local_figures.R` | Clean-room regeneration; checks an independent file list, source CSVs, PDF text, numeric macros, manifest and no TRE/raw/mock dependencies |
| `figures/slide_*.pdf` | Ten deck-specific figures |
| `figures/full/*.pdf` | Local recreations of the 19 output PNG figures (17 exact, 2 aggregate-only replacements) plus 2 CSV-derived redraws of the manuscript percentage-decomposition PDFs |
| `figures/manifest.csv` | Figure-by-figure source CSVs, local-only flag, status, and deck usage |
| `figures/numbers.tex` | LaTeX numeric macros generated from the CSVs |
| `slides_notes.tex` | Wrapper that turns on Beamer notes and inputs `slides.tex` |
| `build/slides.pdf` | Clean presentation deck (build directory is ignored by git) |
| `build/slides_notes.pdf` | Notes-enabled PDF, with one notes page after each slide |

## Rebuild from the export

Run from `presentation/`:

```bash
Rscript make_figures.R ../output/2026-10-22 figures
Rscript verify_local_figures.R ../output/2026-10-22
latexmk -lualatex -outdir=build slides.tex
latexmk -lualatex -outdir=build slides_notes.tex
```

The clean deck is `build/slides.pdf` (15 pages, 16:9); the notes-enabled
build is `build/slides_notes.pdf` (30 pages, one notes page per slide). Source
citations are intentionally in the notes, not visible footers. `make_figures.R`
accepts a different dated output folder and a different figure directory as
its first two arguments. Required local tooling: R with `data.table`,
`ggplot2`, `patchwork` and `scales`, Cairo PDF support, Poppler's
`pdftotext`, and LuaLaTeX with `beamer`, `metropolis`, `fontspec` and Fira
Sans. No packages need installing.

Optionally re-check the export invariants (observed 20/20 pass on
`output/2026-10-22`):

```bash
(cd ../R && Rscript verify_export.R)
```

## Figure provenance

`verify_local_figures.R` regenerates 31 figure PDFs from scratch into a
temporary directory and checks that:

- an independent expected file list matches the generated manifest;
- every manifest entry has a local-only source and every listed source CSV
  exists in the dated export;
- `make_figures.R` and its sourced `R/05_labels.R` contain no TRE paths,
  raw-data readers, cache readers, `RUN_TRE`, `RUN_MOCK`, or mock generator
  references (generator stderr is surfaced on failure);
- `numbers.tex` and `manifest.csv` are byte-identical to the committed copies;
- committed PDF text matches a clean regeneration via `pdftotext` (PDF byte
  hashes are not stable across Cairo runs);
- key `numbers.tex` values recompute from the export CSVs;
- all 31 PDFs are written.

Observed result: 31/31 figures regenerated and matched; 27 exact CSV replots,
2 CSV-derived redraws from the latest export, and 2 aggregate-only
replacements.

Two original diagnostic scatterplots in `output/2026-10-22` —
`anchor_plot.png` and `coverage_accounts.png` — plot person-level points that
are not in the export. Their local replacements (`figures/full/anchor_plot.pdf` and
`figures/full/coverage_accounts.pdf`) use only the published regression tables
and are flagged as aggregate-only in `figures/manifest.csv`. The other 17
output PNG figures are exact numeric replots from exported CSVs. The deck uses
no aggregate-only replacement; no slide depends on an unexported point cloud.
The two older manuscript figures `decomp_pct_co2e.pdf` and
`decomp_pct_sek.pdf` are CSV-derived redraws from the latest
`decomp_table.csv` and `sek_table.csv`, not byte copies of the 2026-10-13
originals.

`figures/numbers.tex` generates the key numeric macros from the CSVs, so the
headline, volume, quintile, item and robustness numbers shown on slides come
from the same export as the figures. Static model labels and check counts
remain in `slides.tex`. For deck figures, `source_csvs` in the manifest also
names any table feeding those numeric macros; `full/` entries name the
figure's own data only.

## Presentation caveats

- The deck reports a cross-sectional association, not a causal effect.
- The main 11-item index is a post-registration correction; the registered
  13-item variant is retained in the results.
- The device screen-time check is weak (model fit 0.018); a 1-SD step in the
  index is the headline scale and per-hour values are derived.
- The preregistered demobilization/leisure mechanism is a negative result.
- `output/2026-10-22` is a frozen real export. It predates the later loader
  harmonization/aviation-intensity override and the ggplot2 pipeline
  migration recorded in `notes/continuity.md`; a future TRE run would refresh
  aviation-containing and checklist outputs. No new TRE run is needed for
  today's figures or slides.
- No mock results are shown.
- Sources and internal-name translations for outsiders are in the Beamer notes.
