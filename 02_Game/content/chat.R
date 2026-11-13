# 02_Game/content/chat.R — Section 4.2.2: what the Chief Economist's call holds by topic beside the facts and the note

# Section 4.2.2: the topic's never sentence, where its note has a rule
chat_never <- c(
  T2 = "In this topic, never say which weighting of inflation against output is right, since the mandate fixes it.",
  T3 = "In this topic, never say exactly how the public works out its view of our aim from the rates we set.",
  T4 = "In this topic, never give the number of quarters to promise.",
  T5 = "In this topic, never say whether to keep or to break the announced plan in a given quarter.",
  T7 = "In this topic, never take sides between the parties.")

# Section 4.2.2: what follows every never sentence
chat_never_holds <- "This holds at every step, the third included."

# Section 4.2.2: the places a topic's desk and newspaper have, one sentence each
chat_places <- list(
  list(topics = paste0("T", 1:8),          place = "The economic figures and their charts, on the desk."),
  list(topics = c("T1", "T2", "T3", "T6", "T7"), place = "The chart of the policy rate."),
  list(topics = c("T4", "T5", "T8"),       place = "The chart of the policy rate, with your announced path."),
  list(topics = paste0("T", 1:8),          place = "The map of the economy, which the Map button opens."),
  list(topics = paste0("T", 2:8),          place = "The newspaper, which reports this quarter's new shocks."),
  list(topics = c("T3", "T4", "T5", "T8"), place = "The chart of expected inflation, with the public's view of our aim as a dashed line."),
  list(topics = c("T4", "T5", "T8"),       place = "The newspaper's box on the bank's word, with the record of kept and broken announcements and trust."),
  list(topics = c("T5", "T8"),             place = "The projected points with their bands on the inflation and unemployment charts, which show the staff forecast."),
  list(topics = c("T6", "T7", "T8"),       place = "The newspaper's box on the government, with government spending against its normal level."),
  list(topics = c("T7", "T8"),             place = "The same box, with the party in office, the poll and the next election, and the bar at the top of the desk that counts down to the vote."))

# Section 4.2.2: the staff forecast at the typed decision as sentences, and how the conversation's lines begin
chat_sentences <- list(
  forecast      = "At the decision you have typed, a policy rate of {rate} percent and the announced path {path}, the staff forecasts for this quarter inflation of {inflation} percent a year, an output gap of {gap} percent and unemployment of {unemployment} percent.",
  forecast_rate = "At the decision you have typed, a policy rate of {rate} percent, the staff forecasts for this quarter inflation of {inflation} percent a year, an output gap of {gap} percent and unemployment of {unemployment} percent.",
  exact         = "The forecast is exact, since every shock of this quarter was reported exactly.",
  quiet         = "The forecast is exact, since no new shock arrived this quarter.",
  band          = "Given what the newspaper reported, inflation may lie between {inflation_lo} and {inflation_hi} percent a year, and unemployment between {unemployment_lo} and {unemployment_hi} percent.",
  briefing      = "Chief Economist, briefing: {text}",
  question      = "Question {n}, quarter {q}: {text}",
  answer        = "Chief Economist: {text}")

# Section 4.2.2: the Chief Economist's answer without a model
chat_fallback_text <- "I cannot answer in words this quarter, but everything you need is on your desk: last quarter's figures and charts, my briefings in this chat, and from Topic 2 on the newspaper with the staff's selection."
