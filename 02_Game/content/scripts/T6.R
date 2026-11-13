# 02_Game/content/scripts/T6.R — Section 4.3.1 and Table 1: Topic 6 (Chapter D)

# Section 4.3.1 and Table 1: the script of Topic 6
T6 <- list(
  id = "T6", name = "Government Spending", chapter = "D",
  objective = "Fiscal policy",
  task = "Keep inflation and output on track while the government spends more than usual for a while.",
  summary = "Extra government spending that people expect to shrink back calls for a higher policy rate to keep output on track.",
  path = "optional",
  builds_on = "P3",
  stages = c(1, 3, 4, 6),
  term = 12,
  panels = c("figures", "map", "rate", "newspaper", "chat"),
  start = list(gov = list(party = 1, g_base = 5, standing = 0, tau = 0, to_election = 99)),
  timeline = list(
    list(q = 1, innovation = "purchases", size = 10)),
  guided = list(quarters = 1:2, action = "rate"),
  tour = "TOUR-T6",
  briefings = list(chapter_open = "B-D", topic_open = "B-T6",
                   quarter_start = c("1" = "B-G6-1", "2" = "B-G6-2")),
  notes = "N-T6",
  debrief = list(covers = 3:12,
                 focus = "When people expect extra government spending to shrink back, the rate the economy needs rises, and a central bank that raises its policy rate with it keeps output at its potential.",
                 expected_marks = "immediate"),
  checks = "the rise of the rate the economy needs in the programme's first quarter")
