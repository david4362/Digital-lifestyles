# Verify that the checked-in presentation figures are regenerated from the
# real-data export alone. Run from presentation/ after make_figures.R:
#   Rscript verify_local_figures.R ../output/2026-10-22

suppressPackageStartupMessages(library(data.table))
source("../R/05_labels.R")

args = commandArgs(trailingOnly = TRUE)
out_dir = if (length(args) >= 1) args[1] else "../output/2026-10-22"
committed_dir = if (length(args) >= 2) args[2] else "figures"
script = "make_figures.R"
test_dir = file.path(tempdir(), "dl_figure_check")
unlink(test_dir, recursive = TRUE)

expected = c(
  "slide_flow.pdf", "slide_headline.pdf", "slide_calibration.pdf",
  "slide_decomp.pdf", "slide_volume.pdf", "slide_quintiles.pdf",
  "slide_items.pdf", "slide_calls.pdf", "slide_mechanism.pdf",
  "slide_robustness.pdf",
  paste0("full/", c("anchor_plot.pdf", "coverage_accounts.pdf",
    "stepwise_coef.pdf", "pres_stepwise.pdf", "decomp_forest.pdf",
    "pres_decomp.pdf", "waterfall.pdf", "sek_forest.pdf",
    "sample_flow.pdf", "equivalence_plot.pdf", "ecommerce_levels.pdf",
    "ecommerce_quintile.pdf", "ecommerce_desc.pdf", "het_plot.pdf",
    "item_level_forest.pdf", "account_coverage.pdf", "mech_forest.pdf",
    "volume_composition.pdf", "quintile_gradient.pdf",
    "decomp_pct_co2e.pdf", "decomp_pct_sek.pdf")))

run = system2("Rscript", c(script, shQuote(out_dir), shQuote(test_dir)),
  stdout = TRUE, stderr = TRUE)
status = attr(run, "status")
if (is.null(status)) status = 0
if (status != 0) {
  cat("make_figures.R failed in a clean output directory:\n")
  cat(paste(run, collapse = "\n"), "\n")
  quit(status = 1)
}

manifest = fread(file.path(test_dir, "manifest.csv"))
fresh_files = file.path(test_dir, expected)
committed_files = file.path(committed_dir, expected)
ok_files = all(file.exists(fresh_files)) && all(file.exists(committed_files))
ok_manifest_set = setequal(manifest$file, expected) && nrow(manifest) == length(expected)
ok_local = all(manifest$local_only)

sources = trimws(unlist(strsplit(manifest$source_csvs, ";")))
ok_sources = all(file.exists(file.path(out_dir, sources)))

banned = c("chalmers/", "RUN_TRE", "RUN_MOCK", "generate_mock", ".dta",
  ".parquet", ".RData", "readRDS", "arrow::", "haven::", "readxl::")
script_text = paste(unlist(lapply(c(script, "../R/05_labels.R"),
  readLines, warn = FALSE)), collapse = "\n")
ok_clean = !any(vapply(banned, grepl, logical(1), script_text, fixed = TRUE))

md5 = function(path) unname(tools::md5sum(path))
ok_numbers_file = md5(file.path(test_dir, "numbers.tex")) ==
  md5(file.path(committed_dir, "numbers.tex"))
ok_manifest_file = md5(file.path(test_dir, "manifest.csv")) ==
  md5(file.path(committed_dir, "manifest.csv"))

# PDF byte hashes are not stable across Cairo runs; compare extracted text
# so the committed vector figures are checked against a clean regeneration.
pdftotext = Sys.which("pdftotext")
pdf_text_hash = function(pdf) {
  txt = tempfile(fileext = ".txt")
  rc = system2("pdftotext", c(shQuote(pdf), shQuote(txt)),
    stdout = FALSE, stderr = FALSE)
  if (rc != 0 || !file.exists(txt)) return(NA_character_)
  h = md5(txt)
  unlink(txt)
  h
}
ok_text = pdftotext != "" && all(vapply(seq_along(expected), function(i) {
  a = pdf_text_hash(fresh_files[i])
  b = pdf_text_hash(committed_files[i])
  !is.na(a) && !is.na(b) && identical(a, b)
}, logical(1)))

# Re-check a few generated slide numbers directly against the export CSVs.
csv = function(name) fread(file.path(out_dir, name))
num = readLines(file.path(test_dir, "numbers.tex"), warn = FALSE)
main_label = unname(variantlab[["main"]])
main_est = csv("stepwise_table.csv")[model == "M5_city" & index_variant == main_label, per_sd]
vol_share = csv("volume_composition.csv")[component == "volume_share", estimate]
q_gap = csv("quintile_contrast.csv")[outcome == "co2e", d5_minus_d1]
flow = csv("sample_flow.csv")
survey_n = flow[stage == "survey", n]
run = csv("run_info.csv")
index_items_n = length(strsplit(run$index_items, " ")[[1]])
desc = csv("descriptives.csv")
idx = desc[measure == "Digital index (standardized, main)"]
fmt1 = function(x) formatC(x, format = "f", digits = 1, big.mark = ",")
fmt0 = function(x) formatC(x, format = "f", digits = 0, big.mark = ",")
index_mean = sprintf("%.0f", idx$mean)
index_sd = fmt0(idx$sd)
volmarg = csv("volume_margins.csv")
co2_pct = volmarg[outcome == "co2e" & spec == "M5", pct_of_mean]
spend_pct = volmarg[outcome == "spend_goods" & spec == "M5", pct_of_mean]
fmt2 = function(x) sprintf("%.2f", x)
ok_numbers_values =
  any(grepl(paste0("\\newcommand{\\MainEstimate}{", fmt1(main_est), "}"),
    num, fixed = TRUE)) &&
  any(grepl(paste0("\\newcommand{\\VolumeShare}{", fmt1(vol_share), "\\%}"),
    num, fixed = TRUE)) &&
  any(grepl(paste0("\\newcommand{\\QuintileGap}{", fmt0(q_gap), "}"),
    num, fixed = TRUE)) &&
  any(grepl(paste0("\\newcommand{\\SurveyN}{", fmt0(survey_n), "}"),
    num, fixed = TRUE)) &&
  any(grepl(paste0("\\newcommand{\\IndexItems}{", fmt0(index_items_n), "}"),
    num, fixed = TRUE)) &&
  any(grepl(paste0("\\newcommand{\\IndexMean}{", index_mean, "}"),
    num, fixed = TRUE)) &&
  any(grepl(paste0("\\newcommand{\\IndexSd}{", index_sd, "}"),
    num, fixed = TRUE)) &&
  any(grepl(paste0("\\newcommand{\\FootprintPct}{", fmt2(co2_pct), "\\%}"),
    num, fixed = TRUE)) &&
  any(grepl(paste0("\\newcommand{\\SpendPct}{", fmt2(spend_pct), "\\%}"),
    num, fixed = TRUE))

exact = sum(manifest$status == "exact CSV replot")
redraw = sum(manifest$status == "CSV-derived redraw from latest export")
replacements = sum(grepl("^aggregate-only", manifest$status))

cat(sprintf("Export: %s\n", out_dir))
cat(sprintf("Figures regenerated and matched: %d/%d\n",
  sum(file.exists(fresh_files)), length(expected)))
cat(sprintf("Exact CSV replots: %d; CSV-derived redraws: %d; aggregate-only replacements: %d\n",
  exact, redraw, replacements))
cat(sprintf("Independent file list matches manifest: %s\n", ok_manifest_set))
cat(sprintf("All source CSVs present: %s\n", ok_sources))
cat(sprintf("No TRE/raw/mock dependencies in generator or sourced labels: %s\n", ok_clean))
cat(sprintf("numbers.tex and manifest.csv match committed copies: %s\n",
  ok_numbers_file && ok_manifest_file))
cat(sprintf("Committed PDF text matches clean regeneration: %s\n", ok_text))
cat(sprintf("Key numbers.tex values recompute from CSVs: %s\n", ok_numbers_values))

pass = ok_files && ok_manifest_set && ok_local && ok_sources && ok_clean &&
  ok_numbers_file && ok_manifest_file && ok_text && ok_numbers_values
if (!pass) {
  cat("Local figure verification FAILED\n")
  quit(status = 1)
}
cat("All checks pass\n")
