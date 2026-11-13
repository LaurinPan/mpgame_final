# 02_Game/content/scripts/T1.R — Section 4.3.1 and Table 1: Topic 1 (Chapter A)

# Section 4.3.1 and Table 1: the script of Topic 1
T1 <- list(
  id = "T1", name = "Demand Shocks", chapter = "A",
  objective = "Monetary policy with lags",
  task = "Keep inflation close to the 2 percent target and output close to normal while households' and firms' spending rises and falls.",
  summary = "How the policy rate steers spending, and why its effect on prices and jobs arrives only over the following quarters.",
  path = "optional",
  builds_on = c("P3", "P4"),
  stages = c(1, 3, 4),
  term = 12,
  panels = c("figures", "map", "rate", "chat"),
  start = list(),
  timeline = list(
    list(q = 1, innovation = "demand", size = 1.0),
    list(q = 4, innovation = "demand", size = -1.0),
    list(q = 8, innovation = "demand", size = 0.8)),
  guided = list(quarters = 1:6, action = "rate"),
  tour = "TOUR-T1",
  briefings = list(chapter_open = "B-A", topic_open = "B-T1",
                   quarter_start = c("1" = "B-G1-1", "2" = "B-G1-2", "3" = "B-G1-3", "4" = "B-G1-4",
                                     "5" = "B-G1-5", "6" = "B-G1-6", "8" = "B-E1-8")),
  notes = "N-T1",
  debrief = list(covers = 7:12,
                 focus = "A policy rate that moves with a demand shock offsets it fully, but every decision shows in the figures only with a delay, because wages adjust slowly.",
                 expected_marks = "immediate"),
  checks = "the share of a one-point rate rise's effect on inflation that arrives after its quarter")
