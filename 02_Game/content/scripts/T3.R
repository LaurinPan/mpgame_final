# 02_Game/content/scripts/T3.R — v6 §6, Topic 3 (Chapter C; Section 4.3, Table 1)

# v6 §6: the script of Topic 3
T3 <- list(
  id = "T3", name = "Learning the Aim", chapter = "C",
  objective = "Expectations",
  task = "Bring the inflation rate the public believes we are aiming at back to the 2 percent target.",
  summary = "The public reads the bank's aim from the policy rates it sets, and that view shapes the inflation it expects.",
  path = "optional",
  builds_on = c("P4", "P5"),
  stages = c(1, 3, 4, 5),
  term = 12,
  panels = c("figures", "expectations", "map", "rate", "newspaper", "chat"),
  start = list(aim = 2.0, chi = 0.8),
  timeline = list(),
  guided = list(quarters = 1:2, action = "rate"),
  tour = "TOUR-T3",
  briefings = list(chapter_open = "B-C", topic_open = "B-T3",
                   quarter_start = c("1" = "B-G3-1", "2" = "B-G3-2", "6" = "B-E3-6")),
  notes = "N-T3",
  debrief = list(covers = 3:12,
                 focus = "The public reads the central bank's aim from every policy rate it sets, and bringing the public's view back to the target can cost output while the view moves.",
                 expected_marks = c("immediate", "deferred")),
  checks = "the fall of the public's view of the aim under the reference bank")
