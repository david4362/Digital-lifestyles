library(data.table)
library(sandwich)
library(lmtest)

out_dir = file.path(dirname(cache_dir), "output")
dir.create(out_dir, showWarnings = FALSE)

# Person x category annual tables (same recipe as 43/47)
ann <- function(df, val) {
  (df[keep, on = .(aid, month), nomatch = 0]
   [, .(s = sum(get(val)), n_months = uniqueN(month)), by = .(aid, category)]
   [n_months > min_months]
   [, y := (s / n_months) * 12]
   [, .(q99 = quantile(y, .99, na.rm = T), y = y, aid = aid), by = .(category)]
   [, y := pmin(y, q99)]
   [, .(aid, category, y)])
}
ca <- ann(monthly_co2e, "co2e")
ka <- ann(monthly_kr[category %notin% excluded_kr], "kr")

ecom_co2e <- c("clothing_co2e", "electronics_co2e", "books_co2e", "toys_co2e", "sports_co2e",
  "shopping_other_co2e", "home_garden_other_co2e")
ecom_kr <- sub("_co2e$", "_kr", ecom_co2e)

# Wide person table: ecom level, rest (= total - ecom), ecom share
wide <- function(dt, cats, prefix) {
  out <- dt[category %in% cats, .(e = sum(y)), by = aid][dt[, .(t = sum(y)), by = aid], on = "aid"]
  setnames(out, c("e", "t"), paste0(c("ecom_", "tot_"), prefix))
  out[, paste0("rest_", prefix) := get(paste0("tot_", prefix)) - get(paste0("ecom_", prefix))]
  out[, paste0("sh_", prefix) := get(paste0("ecom_", prefix)) / get(paste0("tot_", prefix))]
  out
}
pers <- wide(ca, ecom_co2e, "co2e")[wide(ka, ecom_kr, "kr"), on = "aid"]

base <- unique(control_data[, .(aid, age, gender, income, income_q, density, hours_est, index,
  hh_size, children, education, major_city)])
sd_index <- sd(base$index, na.rm = T)
h_per_sd <- dt_coefs[["index"]] * sd_index
form0 <- sub("^co2e", "y", lm_formula)
d <- base[pers, on = "aid", nomatch = 0]

fit <- function(ycol, extra = NULL) {
  d[, y := get(ycol)]
  f <- if (is.null(extra)) form0 else paste(form0, "+", extra)
  m <- lm(as.formula(f), d)
  ct <- coeftest(m, vcov. = vcovHC(m, type = "HC3"))
  e <- ct["hours_est", ]
  data.table(outcome = ycol, spec = ifelse(is.null(extra), "M5", paste0("M5+", extra)),
    n = nobs(m), mean = mean(d$y),
    per_hour = e[["Estimate"]], se = e[["Std. Error"]], p = e[["Pr(>|t|)"]],
    per_sd = e[["Estimate"]] * h_per_sd)
}

# Level vs rest vs share; then holding rest fixed (descriptive: attenuates if pure level effect)
chk <- rbindlist(list(
  fit("ecom_co2e"), fit("rest_co2e"), fit("sh_co2e"),
  fit("ecom_kr"), fit("rest_kr"), fit("sh_kr"),
  fit("ecom_co2e", "rest_co2e"), fit("ecom_kr", "rest_kr")))
chk[, `:=`(lo = per_hour - 1.96 * se, hi = per_hour + 1.96 * se)]
fwrite(chk, file.path(out_dir, "ecommerce_check.csv"))

# Separate panels: kg and SEK levels have different scales, shares are proportions
panel <- function(s, unit, ttl) {
  y <- seq_len(nrow(s))
  plot(s$per_hour, y, xlim = range(c(s$lo, s$hi)),
    yaxt = "n", pch = 16, col = ifelse(s$p < 0.05, "steelblue", "grey50"),
    xlab = paste(unit, "per extra hour/day (HC3 95% CI)"), ylab = "", main = ttl)
  axis(2, y, paste0(s$outcome, " [", s$spec, "]"), las = 1, cex.axis = 0.8)
  segments(s$lo, y, s$hi, y, col = "grey40")
  abline(v = 0, lty = 2, col = "grey")
}
png(file.path(out_dir, "ecommerce_levels.png"), width = 1500, height = 500, res = 120)
par(mfrow = c(1, 3), mar = c(5, 11, 4, 2))
panel(chk[outcome %in% c("ecom_co2e", "rest_co2e")], "kg CO2e", "Levels, CO2e")
panel(chk[outcome %in% c("ecom_kr", "rest_kr")], "SEK", "Levels, SEK")
panel(chk[grepl("^sh_", outcome)], "share", "E-com share of total")
dev.off()

# Within income quintile (stratified, M5 minus income): survives if not just income
f_noinc <- sub("+income", "", form0, fixed = TRUE)
qr <- rbindlist(lapply(levels(d$income_q), function(q) {
  rbindlist(lapply(c("ecom_co2e", "ecom_kr"), function(yc) {
    dd <- d[income_q == q]
    dd[, y := get(yc)]
    m <- lm(as.formula(f_noinc), dd)
    ct <- coeftest(m, vcov. = vcovHC(m, type = "HC3"))
    e <- ct["hours_est", ]
    data.table(income_q = q, outcome = yc, n = nobs(m), mean = mean(dd$y),
      per_hour = e[["Estimate"]], se = e[["Std. Error"]], p = e[["Pr(>|t|)"]])
  }))
}))
qr[, `:=`(lo = per_hour - 1.96 * se, hi = per_hour + 1.96 * se)]
fwrite(qr, file.path(out_dir, "ecommerce_quintile.csv"))

png(file.path(out_dir, "ecommerce_quintile.png"), width = 1000, height = 500, res = 120)
par(mfrow = c(1, 2), mar = c(5, 6, 4, 2))
for (yc in c("ecom_co2e", "ecom_kr")) {
  s <- qr[outcome == yc]
  yy <- seq_len(nrow(s))
  unit <- ifelse(yc == "ecom_co2e", "kg CO2e", "SEK")
  plot(s$per_hour, yy, xlim = range(c(s$lo, s$hi)),
    yaxt = "n", pch = 16, col = ifelse(s$p < 0.05, "steelblue", "grey50"),
    xlab = paste(unit, "per extra hour/day (HC3 95% CI)"), ylab = "",
    main = paste0(yc, " within income quintile"))
  axis(2, yy, s$income_q, las = 1)
  segments(s$lo, yy, s$hi, yy, col = "grey40")
  abline(v = 0, lty = 2, col = "grey")
}
dev.off()

# Descriptives: do high-digital households just earn and spend more?
d[, dig_q := cut(index, quantile(index, probs = seq(0, 1, 0.2), na.rm = T),
  labels = paste0("D", 1:5), include.lowest = T)]
inc0 <- unique(users[, .(aid, `income-level`)])
desc <- d[inc0, on = "aid", nomatch = 0][, .(n = .N, income = mean(`income-level`),
  tot_kr = mean(tot_kr), tot_co2e = mean(tot_co2e),
  sh_kr = mean(sh_kr), sh_co2e = mean(sh_co2e)), by = dig_q]
setorder(desc, dig_q)
fwrite(desc, file.path(out_dir, "ecommerce_desc.csv"))

png(file.path(out_dir, "ecommerce_desc.png"), width = 1000, height = 500, res = 120)
par(mfrow = c(1, 2), mar = c(5, 5, 4, 2))
barplot(setNames(desc$income, desc$dig_q), col = "steelblue",
  xlab = "digital quintile", ylab = "mean disposable income",
  main = "Income by digital quintile")
barplot(setNames(desc$tot_kr, desc$dig_q), col = "steelblue",
  xlab = "digital quintile", ylab = "mean total spending (SEK/yr)",
  main = "Consumption by digital quintile")
dev.off()
