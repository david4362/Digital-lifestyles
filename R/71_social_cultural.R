library(data.table)
library(sandwich)
library(lmtest)

# Registered out-of-home social/cultural group (RA checklist item 1): the
# fully adjusted gradient for restaurants, bars, culture/entertainment and
# other leisure services, in CO2e and SEK. This is the decomposition group
# named in the pre-registration and missing from 43/47, which report the
# restaurant leaf only. Category vectors are social_co2e / social_kr in 20.
# Leaves are exported beside the group so the total is not a black box.
# A leaf absent from this extract (the mock has restaurants only) is skipped;
# the TRE extract has all four.

group_rows = function(annual, cats, unit) {
  present = intersect(cats, unique(annual$category))
  targets = c(list(social_cultural = present), setNames(as.list(present), present))
  base = analysis_data[, .(aid, age, gender, income, income_scb, income_bank, density,
    index, hh_size, children, education, major_city)]
  rbindlist(lapply(names(targets), function(nm) {
    d = base[group_annual(annual, targets[[nm]]), on = "aid", nomatch = 0]
    row = fit_row(d, nm, "M5")
    row[, `:=`(unit = unit, lo = per_sd - 1.96 * se, hi = per_sd + 1.96 * se,
      pct_of_mean = 100 * per_sd / mean)]
    row
  }))
}

social_cultural = rbind(
  group_rows(annualise(monthly_co2e, "co2e"), social_co2e, "kg CO2e/yr"),
  group_rows(annualise(monthly_kr[category %notin% excluded_kr], "kr"), social_kr, "SEK/yr"))
fwrite(social_cultural, file.path(out_dir, "social_cultural_group.csv"))
