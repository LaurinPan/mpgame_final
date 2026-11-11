# 02_Game/content/scripts/T5.R — v6 §6, Topic 5 (Chapter C; Section 4.3, Table 1)

# v6 §6: the script of Topic 5
T5 <- list(
  id = "T5", name = "Flexibility of Announcements", chapter = "C",
  objective = "Gains from commitment",
  task = "Announce a plan for the policy rate every quarter, and keep it unless new information justifies a change.",
  summary = "A plan the public trusts makes inflation cheaper to control, and breaking it without new information costs trust later.",
  path = "required",
  builds_on = c("P4", "P5"),
  stages = c(1, 3, 4, 5),
  term = 12,
  panels = c("figures", "expectations", "map", "rate", "newspaper", "chat", "forecast"),
  start = list(aim = 1.0, chi = 0.7),
  timeline = list(
    list(q = 5, innovation = "demand", size = 1.0)),
  guided = NULL,
  tour = "TOUR-T5",
  briefings = list(topic_open = "B-T5",
                   quarter_start = c("5" = "B-E5-5", "8" = "B-E5-8")),
  notes = "N-T5",
  debrief = list(covers = 1:12,
                 focus = "A plan the public believes makes the trade-off between inflation and output cheaper; the plan may change with new information, but breaking it without new information costs more trust later than it gains today.",
                 expected_marks = "deferred"),
  checks = "the term loss of breaking the word, quarter 8's rate one point below the rate announced for it, against keeping it")
