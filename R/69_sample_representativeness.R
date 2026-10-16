library(data.table)
library(lmtest)
library(sandwich)

# The recruitment frame contains two invitation streams: a register-based
# random frame and a non-random green-area oversample. The headline analysis
# currently pools them. This script documents that composition and tests
# whether the spending and emissions gradients persist in the random stream
# and after reweighting its respondents to the invited random frame.
required_frame_vars = c("aid", "age", "gender", "postort", "randomsample", "greensample")
missing_frame_vars = setdiff(required_frame_vars, names(demographics))

if (length(missing_frame_vars)) {
  message("Skipping representativeness exports: demographics lacks ",
    paste(missing_frame_vars, collapse = ", "), " (expected in TRE data).")
} else {
  frame = demographics[order(aid, order), .SD[1], by = aid]
  frame[, randomsample := as.integer(randomsample == 1)]
  frame[, greensample := as.integer(greensample == 1)]
  frame[, major_city_frame := postort %in% c("Stockholm", "Göteborg", "Malmö")]
  frame[, age_group_frame := cut(age, c(18, 30, 45, 65, Inf), right = FALSE,
    labels = c("18-29", "30-44", "45-64", "65+"))]
  frame[, stream := fcase(
    randomsample == 1, "Random frame",
    greensample == 1, "Green-area oversample",
    default = "Other/unknown"
  )]

  recruitment = frame[, .(aid, randomsample, greensample, stream)][
    analysis_data[, .(aid)], on = "aid", nomatch = 0]

  count_stage = function(ids, stage_label) {
    frame[data.table(aid = unique(ids)), on = "aid", nomatch = 0][
      , .(stage = stage_label, n = uniqueN(aid)), by = stream]
  }
  frame_flow = rbindlist(list(
    frame[, .(stage = "Invited frame", n = uniqueN(aid)), by = stream],
    count_stage(survey$aid, "Baseline survey"),
    count_stage(answered_survey$aid, "Battery gate"),
    count_stage(spending$aid, "Valid transaction months"),
    count_stage(control_data$aid, "Controls linked"),
    count_stage(analysis_data$aid, "Main analysis sample")
  ), use.names = TRUE)
  frame_flow[, stage := factor(stage, levels = c(
    "Invited frame", "Baseline survey", "Battery gate",
    "Valid transaction months", "Controls linked", "Main analysis sample"
  ))]
  setorder(frame_flow, stage, stream)
  frame_flow[, stage := as.character(stage)]
  fwrite(frame_flow, file.path(out_dir, "recruitment_stream_flow.csv"))

  analysis_recruitment = frame[, .(aid, randomsample, greensample, stream)][
    analysis_data, on = "aid", nomatch = 0]

  benchmark_source = rbind(
    frame[randomsample == 1, .(
      population = "Invited random frame", age, gender,
      major_city = major_city_frame, age_group = age_group_frame
    )],
    frame[analysis_data[, .(aid)], on = "aid", nomatch = 0][
      randomsample == 1, .(
        population = "Analytical random-frame subset", age, gender,
        major_city = major_city_frame, age_group = age_group_frame
      )],
    frame[analysis_data[, .(aid)], on = "aid", nomatch = 0][, .(
      population = "Full pooled analytical sample", age, gender,
      major_city = major_city_frame, age_group = age_group_frame
    )]
  )
  benchmark = benchmark_source[, .(
    n = .N,
    mean_age = mean(age, na.rm = TRUE),
    share_female = mean(gender == "Kvinna", na.rm = TRUE),
    share_major_city = mean(major_city, na.rm = TRUE),
    share_age_18_29 = mean(age_group == "18-29", na.rm = TRUE),
    share_age_30_44 = mean(age_group == "30-44", na.rm = TRUE),
    share_age_45_64 = mean(age_group == "45-64", na.rm = TRUE),
    share_age_65_plus = mean(age_group == "65+", na.rm = TRUE)
  ), by = population]
  fwrite(benchmark, file.path(out_dir, "random_frame_benchmark.csv"))

  random_frame = frame[randomsample == 1 & !is.na(age_group_frame) &
      !is.na(gender) & !is.na(major_city_frame)]
  random_frame[, analyzed := as.integer(aid %in% analysis_recruitment[
    randomsample == 1, aid])]
  selection_model = glm(analyzed ~ age_group_frame + gender + major_city_frame,
    data = random_frame, family = binomial())
  random_frame[, selection_probability := predict(selection_model, type = "response")]

  cell_balance = random_frame[, .(
    n_frame = .N,
    n_analyzed = sum(analyzed),
    raw_participation_rate = mean(analyzed),
    mean_model_probability = mean(selection_probability)
  ), by = .(age_group_frame, gender, major_city_frame)]
  fwrite(cell_balance, file.path(out_dir, "sampling_ipw_cell_balance.csv"))

  weights = random_frame[analyzed == 1, .(
    aid, selection_probability,
    weight_raw = 1 / selection_probability
  )]
  trim_point = quantile(weights$weight_raw, 0.99, na.rm = TRUE)
  weights[, weight := pmin(weight_raw, trim_point)]
  weights[, weight := weight / mean(weight)]
  fwrite(weights, file.path(out_dir, "sampling_ipw_weights.csv"))
  weight_diagnostics = weights[, .(
    n = .N,
    selection_probability_min = min(selection_probability),
    selection_probability_median = median(selection_probability),
    selection_probability_max = max(selection_probability),
    raw_weight_trim_point = as.numeric(trim_point),
    weight_min = min(weight),
    weight_median = median(weight),
    weight_max = max(weight),
    effective_sample_size = sum(weight)^2 / sum(weight^2)
  )]
  fwrite(weight_diagnostics,
    file.path(out_dir, "sampling_ipw_diagnostics.csv"))

  total_spending = group_annual(kr_annual, unique(kr_annual$category))
  setnames(total_spending, "y", "spending")
  model_data = total_spending[analysis_recruitment, on = "aid", nomatch = 0]

  fit_gradient = function(data, outcome, sample, weight_col = NULL) {
    formula = reformulate(c("index", covariate_vars), response = outcome)
    model = if (is.null(weight_col)) {
      lm(formula, data = data)
    } else {
      lm(formula, data = data, weights = data[[weight_col]])
    }
    estimate = coeftest(model, vcov. = vcovHC(model, type = "HC3"))["index", ]
    data.table(
      sample = sample,
      outcome = outcome,
      n = nobs(model),
      mean = weighted.mean(data[[outcome]],
        if (is.null(weight_col)) rep(1, nrow(data)) else data[[weight_col]],
        na.rm = TRUE),
      per_sd = estimate[["Estimate"]],
      se = estimate[["Std. Error"]],
      p = estimate[["Pr(>|t|)"]]
    )
  }

  samples = list(
    "Pooled sample" = model_data,
    "Random-frame subset" = model_data[randomsample == 1],
    "Green-area oversample" = model_data[greensample == 1]
  )
  gradients = rbindlist(lapply(names(samples), function(sample_name) {
    data = samples[[sample_name]]
    rbind(
      fit_gradient(data, "spending", sample_name),
      fit_gradient(data, "co2e", sample_name)
    )
  }))

  weighted_data = weights[model_data[randomsample == 1], on = "aid", nomatch = 0]
  gradients = rbind(
    gradients,
    fit_gradient(weighted_data, "spending", "Random frame, sampling-IPW", "weight"),
    fit_gradient(weighted_data, "co2e", "Random frame, sampling-IPW", "weight")
  )
  gradients[, `:=`(
    lo = per_sd - 1.96 * se,
    hi = per_sd + 1.96 * se,
    pct_of_mean = 100 * per_sd / mean
  )]
  fwrite(gradients, file.path(out_dir, "representativeness_gradients.csv"))
}
