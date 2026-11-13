# 02_Game/content/scripts/T8.R — Section 4.3.1 and Table 1: Topic 8 (Chapter E)

# Section 4.3.1 and Table 1: the script of Topic 8
T8 <- list(
  id = "T8", name = "Free Play", chapter = "E",
  objective = "all",
  task = "Keep inflation and output on track while shocks arrive at random and every mechanism of the game is at work.",
  summary = "Random shocks and every mechanism at once: here you use together what each chapter taught on its own.",
  path = "optional",
  builds_on = "all",
  stages = 1:6,
  term = 24,
  panels = c("figures", "expectations", "map", "rate", "newspaper", "chat", "forecast"),
  start = list(aim = 0, chi = 0.8, gov = list(party = 1, g_base = 0, standing = 0, tau = 0, to_election = 8)),
  random = list(demand = 0.20, technology = 0.25, costs = 0.25, purchases = 2),
  timeline = list(
    list(q = 3, innovation = "costs", size = 2.0),
    list(q = 12, path = c(-8, -7, -6, -5, -4, -3, -2, -1)),
    list(q = 8, vote = TRUE),
    list(q = 16, vote = TRUE),
    list(q = 24, vote = TRUE)),
  guided = NULL,
  tour = "TOUR-T8",
  briefings = list(chapter_open = "B-E", topic_open = "B-T8"),
  notes = "N-T8",
  debrief = list(covers = 1:24,
                 focus = "The mechanisms of the earlier chapters now act together; the marks show where one of them cost the most.",
                 expected_marks = c("immediate", "deferred")),
  checks = NULL)
