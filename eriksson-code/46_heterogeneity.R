library(data.table)
library(sandwich)
library(lmtest)

out_dir = file.path(dirname(cache_dir), "output")
dir.create(out_dir, showWarnings = FALSE)

# Heterogeneity on the fixed M5 complete-case sample (same principle as the
# stepwise ladder in 42). Age bands need raw age (analysis_data$age is
# centered); demographics_unique is the one-row-per-aid table from 20 — the
# raw demographics table has duplicate rows for some aids, which would
# double-count those people here.
bands = demographics_unique[, .(aid, band = cut(age, c(18, 30, 45, 65, Inf),
  labels = c("18-29", "30-44", "45-64", "65+"), right = FALSE))]
d = analysis_data[bands, on = "aid", nomatch = 0]

margins = rbindlist(lapply(c("band", "gender", "major_city"), function(v) {
  m = lm(update(as.formula(lm_formula), paste(". ~ . + hours_est:", v)), d)
  V = vcovHC(m, type = "HC3")
  cf = coef(m)
  lv = if (is.factor(d[[v]])) levels(d[[v]]) else sort(unique(d[[v]]))
  inms = setdiff(grep("hours_est", names(cf), value = TRUE), "hours_est")
  lvl_of = function(nm) sub(paste0("^", v), "", gsub("hours_est|:", "", nm))
  rbindlist(lapply(seq_along(lv), function(i) {
    hit = inms[sapply(inms, lvl_of) == as.character(lv[i])]
    if (length(hit) == 0) {
      e = cf[["hours_est"]]
      s = sqrt(V["hours_est", "hours_est"])
    } else {
      nm = hit[1]
      e = cf[["hours_est"]] + cf[[nm]]
      s = sqrt(V["hours_est", "hours_est"] + V[nm, nm] + 2 * V["hours_est", nm])
    }
    data.table(mod = v, level = as.character(lv[i]), n = nobs(m), est = e, se = s,
      p = 2 * pt(-abs(e / s), df = df.residual(m)), per_sd = e * h_per_sd)
  }))
}))
margins[, `:=`(lo = est - 1.96 * se, hi = est + 1.96 * se)]
fwrite(margins, file.path(out_dir, "het_margins.csv"))

modttl <- c(band = "Age group", gender = "Gender", major_city = "Major city")
png(file.path(out_dir, "het_plot.png"), width = 1200, height = 500, res = 120)
par(mfrow = c(1, 3), mar = c(5, 8, 4, 1))
for (v in c("band", "gender", "major_city")) {
  s = margins[mod == v]
  lvl = s$level
  lvl[lvl == "Man"] <- "Men"
  lvl[lvl == "Kvinna"] <- "Women"
  lvl[lvl == "TRUE"] <- "Major city"
  lvl[lvl == "FALSE"] <- "Outside major cities"
  y = seq_len(nrow(s))
  plot(s$est, y, xlim = range(c(s$lo, s$hi)), yaxt = "n", pch = 19, col = "#1f4e79",
    xlab = "kg CO2e per extra hour/day", ylab = "", main = modttl[[v]])
  axis(2, y, lvl, las = 1)
  segments(s$lo, y, s$hi, y, lwd = 2, col = "#1f4e79")
  abline(v = 0, lty = 2)
}
dev.off()
