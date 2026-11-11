# 02_Game/content/scripts/T2.R — v6 §6, Topic 2 (Chapter B; Section 4.3, Table 1)

# v6 §6: the script of Topic 2
T2 <- list(
  id = "T2", name = "Cost-Push Shocks", chapter = "B",
  objective = "Trade-off after supply shocks",
  task = "Weigh higher inflation against lost output and jobs while firms' costs first rise and later fall.",
  summary = "When firms' costs rise, inflation goes up while output falls, so one policy rate cannot keep both on track.",
  path = "optional",
  builds_on = c("P4", "P5"),
  stages = c(1, 2, 3, 4),
  term = 12,
  panels = c("figures", "map", "rate", "newspaper", "chat"),
  start = list(),
  timeline = list(
    list(q = 1, innovation = "costs", size = 2.0),
    list(q = 7, innovation = "costs", size = -1.0)),
  guided = list(quarters = 1:3, action = "rate"),
  tour = "TOUR-T2",
  briefings = list(chapter_open = "B-B", topic_open = "B-T2",
                   quarter_start = c("1" = "B-G2-1", "2" = "B-G2-2", "3" = "B-G2-3", "7" = "B-E2-7")),
  notes = "N-T2",
  debrief = list(covers = 4:12,
                 focus = "After a cost-push shock no policy rate keeps both inflation and output on target; the mandate decides how to weigh them, and the loss shows what each choice costs.",
                 expected_marks = "immediate"),
  checks = "the smallest larger part of the loss any constant rate or the rule achieves after the rise in costs")
