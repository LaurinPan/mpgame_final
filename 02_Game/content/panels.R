# 02_Game/content/panels.R — v6 §3: the panels, the topics with the bank's word, the readouts' constants, the charts' scales and the desk's charts

# v6 §3: the dashboard's panels with the stage and the topics each needs
panels <- data.frame(
  id = c("figures", "expectations", "map", "rate", "newspaper", "chat", "forecast"),
  shows = c("output with its trend, growth, inflation, wage inflation, unemployment as a rate and in persons, the population and the labour force, with their charts",
            "the inflation the public expects, as a chart, with the public's view of the aim as a dashed line from Topic 3 on",
            "the boxes, nodes and arrows of the map for the topics reached",
            "the rate control to two decimals, between the floor at zero and the cap of 20 percent, the spell at the floor; with the word, the path editor with its room",
            "the issue on its four pages, with the staff's selection and its fixed boxes",
            "the Chief Economist",
            "the staff forecast at the typed rate and path, as a projected point with its band on the inflation and unemployment charts"),
  stage = c(rep("base", 6), "5"),
  topics = c("all", "T3 T4 T5 T8", "all", "all", "T2 T3 T4 T5 T6 T7 T8", "all", "T5 T8"),
  stringsAsFactors = FALSE)

# v6 §3 and §12.1: the topics with the bank's word, the path editor in the rate control and the paper's box W
word_topics <- c("T4", "T5", "T8")

# Section 4.2.1, v6 §3 and A.8: the readouts' constants, the law's cap on the rate and the reference bank's lambda_i
consts <- list(
  Y0              = 4000,
  population      = 80e6,
  labour_force    = 40e6,
  cap             = 20,
  loss_scale      = 400^2,
  lambda_i        = 0.25,
  forecast_rows   = c("inflation", "output_gap", "unemployment"),
  history_quarters = 8,
  parties         = c("the Expansion Party", "the Balance Party"))

# Section 4.2.1 and v6 §12.3: the charts' fixed scales
scales <- data.frame(
  variable  = c("rate", "inflation", "wage_inflation", "output", "growth", "unemployment", "expected_inflation"),
  lo        = c(0, -2, -2, -6, -8, 0, -2),
  hi        = c(20, 10, 12, 6, 12, 12, 10),
  unit      = c("percent a year", "percent a year", "percent a year", "percent of the trend", "percent a year", "percent", "percent a year"),
  reference = c("floor", "target", "wage_normal", "trend", "trend_growth", "natural_unemployment", "target"),
  stringsAsFactors = FALSE)

# Section 4.2.1: the desk's charts, their panels, series and reference lines
desk_charts <- data.frame(
  id        = c("output", "inflation", "wage_inflation", "unemployment", "rate", "expectations"),
  panel     = c("figures", "figures", "figures", "figures", "rate", "expectations"),
  series    = c("output_level;output_trend", "inflation", "wage_inflation", "unemployment", "rate;announced", "expected_inflation;aim_level"),
  scale     = c("output", "inflation", "wage_inflation", "unemployment", "rate", "expected_inflation"),
  reference = c("trend", "target", "wage_normal", "natural_unemployment", "floor", "target"),
  stringsAsFactors = FALSE)
