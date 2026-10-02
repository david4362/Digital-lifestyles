library(data.table)

out_dir = file.path(dirname(cache_dir), "output")
dir.create(out_dir, showWarnings = FALSE)

summary_row <- function(x, measure, sample) {
  q = quantile(x, probs = c(0, .05, .25, .50, .75, .95, 1), na.rm = T)
  data.table(
    measure = measure,
    sample = sample,
    n = sum(!is.na(x)),
    min = unname(q[1]),
    p5 = unname(q[2]),
    p25 = unname(q[3]),
    median = unname(q[4]),
    p75 = unname(q[5]),
    p95 = unname(q[6]),
    max = unname(q[7]),
    mean = mean(x, na.rm = T),
    sd = sd(x, na.rm = T)
  )
}

descriptives = rbind(
  summary_row(analysis_data$index, "Digital index", "M5 complete-case sample"),
  summary_row(device_time$time, "E4 screen time (hours/day)", "Valid E4 reporters")
)
fwrite(descriptives, file.path(out_dir, "descriptives.csv"))
