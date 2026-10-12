library(data.table)
library(sandwich)
library(lmtest)

# Heterogeneity on the fixed M5 complete-case sample (same principle as the
# stepwise ladder in 42). Age bands need raw age (analysis_data$age is
# centered); demographics_unique is the one-row-per-aid table from 20 — the
# raw demographics table has duplicate rows for some aids, which would
# double-count those people here.
bands = demographics_unique[, .(aid, band = cut(age, c(18, 30, 45, 65, Inf),
  labels = c("18-29", "30-44", "45-64", "65+"), right = FALSE))]
d = analysis_data[bands, on = "aid", nomatch = 0]
# gender arrives as a character vector (fcase in 10); make the factor
# explicit so levels() works and the reference level (Kvinna, alphabetical
# first) is visible here rather than implicit in lm.
d[, gender := factor(gender)]

# Level-specific slopes from one interaction model per variable (M5 +
# index x group). The index coefficient is the slope in the reference level
# (the first level: 18-29, Kvinna, outside major cities); every other
# level's slope is the index coefficient plus its interaction coefficient,
# and the SE combines the two coefficients' variances and their covariance
# (delta method). The interaction tests behind these margins are in 58.
level_rows = function(m, v, lv) {
  V = vcovHC(m, type = "HC3")
  cf = coef(m)
  rbindlist(lapply(lv, function(l) {
    if (l == lv[1]) {
      est = cf[["index"]]
      se = sqrt(V["index", "index"])
    } else {
      # R orders the two variables in the interaction coefficient's name
      # by their first appearance in the formula (genderMan:index here,
      # index:major_cityTRUE), so take whichever of the two names the
      # model used.
      nm = intersect(names(cf), c(paste0(v, l, ":index"), paste0("index:", v, l)))[1]
      est = cf[["index"]] + cf[[nm]]
      se = sqrt(V["index", "index"] + V[nm, nm] + 2 * V["index", nm])
    }
    data.table(mod = v, level = l, n = nobs(m), est = est, se = se,
      p = 2 * pt(-abs(est / se), df = df.residual(m)), per_sd = est,
      per_hour = est / h_per_sd)
  }))
}

margins = rbind(
  level_rows(lm(update(as.formula(lm_formula), ". ~ . + index:band"), d),
    "band", levels(d$band)),
  level_rows(lm(update(as.formula(lm_formula), ". ~ . + index:gender"), d),
    "gender", levels(d$gender)),
  level_rows(lm(update(as.formula(lm_formula), ". ~ . + index:major_city"), d),
    "major_city", c("FALSE", "TRUE")))
margins[, `:=`(lo = est - 1.96 * se, hi = est + 1.96 * se)]
fwrite(margins, file.path(out_dir, "het_margins.csv"))

modttl = c(band = "Age group", gender = "Gender", major_city = "Major city")
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
    xlab = "kg CO2e per index SD", ylab = "", main = modttl[[v]])
  axis(2, y, lvl, las = 1)
  segments(s$lo, y, s$hi, y, lwd = 2, col = "#1f4e79")
  abline(v = 0, lty = 2)
}
dev.off()
