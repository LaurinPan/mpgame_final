# 02_Game/content/newspaper/charts.R — v6 §12.3: the charts the game draws

# v6 §12.3: each chart's series, reference line and caption
charts <- data.frame(
  id        = c("CH-output", "CH-inflation", "CH-wages", "CH-unemployment", "CH-rate",
                "CH-expectations", "CH-poll", "CH-purchases"),
  series    = c("output_level;output_trend", "inflation", "wage_inflation;inflation", "unemployment",
                "rate;announced", "expected_inflation", "poll", "purchases"),
  reference = c(NA, "target", NA, "natural_unemployment", "zero", "target", "half", "normal"),
  caption   = c("Output and its trend over the last eight quarters.",
                "Inflation in percent a year over the last eight quarters; dashed line: the 2 percent target.",
                "Wage inflation and inflation in percent a year over the last eight quarters.",
                "Unemployment in percent over the last eight quarters; dashed line: its natural rate.",
                "The policy rate in percent over the last eight quarters, and the announced plan.",
                "Expected inflation in percent a year over the last eight quarters; dashed line: the target.",
                "Support for the party in office in percent over the last eight quarters.",
                "Government spending compared with normal over the last eight quarters."),
  stringsAsFactors = FALSE)
