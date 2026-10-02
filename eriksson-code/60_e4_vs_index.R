library(data.table)
library(sandwich)
library(lmtest)

out_dir = file.path(dirname(cache_dir), "output")
dir.create(out_dir, showWarnings = FALSE)

# Formal test of the paper's pivot: on the same people, the self-reported
# index carries a total-emissions gradient while device-measured E4 screen
# time does not (52 shows the per-hour slopes; this script tests their
# difference). Both exposures are z-scored in the E4 subsample, so all slopes
# are per own-SD and directly comparable.
#
# The difference is tested in the joint model (both exposures in one M5):
# they are weakly correlated (anchor R2 is ~0.015, see anchor_check.csv), so
# the model is well-conditioned, and the HC3 covariance between the two
# slopes gives the variance of their difference:
#   Var(b_index - b_e4) = V11 + V22 - 2 V12.
# (The p-value for the difference uses a normal approximation; the
# individual slopes use t.)

e4_data = analysis_data[device_time[, .(aid, time)], on = "aid", nomatch = 0]
e4_data[, z_index := as.vector(scale(hours_est))]
e4_data[, z_time := as.vector(scale(time))]

# Separate M5 models, per-SD slopes (the per-SD version of 52's per-hour rows)
m_index = lm(sub("hours_est", "z_index", lm_formula), data = e4_data)
m_time = lm(sub("hours_est", "z_time", lm_formula), data = e4_data)
ct_index = coeftest(m_index, vcov. = vcovHC(m_index, type = "HC3"))["z_index", ]
ct_time = coeftest(m_time, vcov. = vcovHC(m_time, type = "HC3"))["z_time", ]

# Joint model with both exposures
m_joint = lm(sub("hours_est", "z_index + z_time", lm_formula), data = e4_data)
ct_joint = coeftest(m_joint, vcov. = vcovHC(m_joint, type = "HC3"))
V = vcovHC(m_joint, type = "HC3")[c("z_index", "z_time"), c("z_index", "z_time")]
b = coef(m_joint)[c("z_index", "z_time")]
diff = unname(b["z_index"] - b["z_time"])
se_diff = unname(sqrt(V[1, 1] + V[2, 2] - 2 * V[1, 2]))
p_diff = 2 * pnorm(-abs(diff / se_diff))

e4_index_test = rbind(
  data.table(specification = "Separate M5", exposure = "Index (per SD)",
    estimate = ct_index[["Estimate"]], se = ct_index[["Std. Error"]],
    p = ct_index[["Pr(>|t|)"]]),
  data.table(specification = "Separate M5", exposure = "E4 screen time (per SD)",
    estimate = ct_time[["Estimate"]], se = ct_time[["Std. Error"]],
    p = ct_time[["Pr(>|t|)"]]),
  data.table(specification = "Joint M5", exposure = "Index (per SD)",
    estimate = ct_joint["z_index", "Estimate"], se = ct_joint["z_index", "Std. Error"],
    p = ct_joint["z_index", "Pr(>|t|)"]),
  data.table(specification = "Joint M5", exposure = "E4 screen time (per SD)",
    estimate = ct_joint["z_time", "Estimate"], se = ct_joint["z_time", "Std. Error"],
    p = ct_joint["z_time", "Pr(>|t|)"]),
  data.table(specification = "Joint M5", exposure = "Difference (index - E4)",
    estimate = diff, se = se_diff, p = p_diff)
)
e4_index_test[, n := nobs(m_joint)]
e4_index_test[, `:=`(lo = estimate - 1.96 * se, hi = estimate + 1.96 * se)]
fwrite(e4_index_test, file.path(out_dir, "e4_index_test.csv"))
