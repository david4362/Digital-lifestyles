# 00_mock_data.R — thin adapter for the SHARED synthetic study data.
#
# The generator is the synced in-repo copy `generate_mock_data.R`
# (byte-identical to the canonical master <workspace>/scripts/
# generate_mock_data.R; the same copy is committed in every project repo so
# each repo's RUN_MOCK works from a stand-alone checkout). It is the single
# source of mock data for every project (see data/common-data.md and
# CODING-GUIDELINES.md §6). This file only locates and sources it — it adds
# nothing. The objects it leaves in memory (survey, survey_endline,
# demographics, users, scb, monthly_kr, monthly_co2e, person_bank,
# transactions_long, plus the tax-side tables this pipeline ignores) match
# the cache shapes the real loaders produce — including the harmonized long
# core built by the same full melt as load_common_data.R and the canonical
# aviation emission-intensity override, which the generator itself applies
# (matching load_common_data.R, so this pipeline's mock and real runs treat
# aviation identically).
mock_candidates = c(
  if (exists("mock_generator_path")) mock_generator_path,
  "generate_mock_data.R")
mock_src = mock_candidates[file.exists(mock_candidates)][1]
if (is.na(mock_src)) stop(
  "Shared mock generator not found: expected generate_mock_data.R next to ",
  "this file (synced in-repo copy; canonical master at the workspace ",
  "scripts/generate_mock_data.R).")
source(mock_src)
