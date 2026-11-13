# 02_Game/content/scripts/T4.R — Section 4.3.1 and Table 1: Topic 4 (Chapter C)

# Section 4.3.1 and Table 1: the script of Topic 4
T4 <- list(
  id = "T4", name = "Promise at the Floor", chapter = "C",
  objective = "Forward guidance at the floor",
  task = "Soften a long, foreseen slump while the policy rate stands at zero, with what you announce about future rates.",
  summary = "When the policy rate cannot fall any further, a believed promise to keep it at zero for longer still helps today.",
  path = "optional",
  builds_on = c("P4", "P5"),
  stages = c(1, 3, 4, 5),
  term = 12,
  panels = c("figures", "expectations", "map", "rate", "newspaper", "chat"),
  start = list(aim = 0, chi = 0.8),
  timeline = list(
    list(q = 2, path = c(-8, -7, -6, -5, -4, -3, -2, -1))),
  guided = list(quarters = 1, action = "announce"),
  tour = "TOUR-T4",
  briefings = list(topic_open = "B-T4",
                   quarter_start = c("1" = "B-G4-1", "2" = "B-E4-2", "4" = "B-E4-4")),
  notes = "N-T4",
  debrief = list(covers = 2:12,
                 focus = "When the policy rate is at zero, a promise helps only if it reaches beyond what the public already expects, and only as far as the public believes it and the bank keeps it.",
                 expected_marks = c("immediate", "deferred")),
  checks = "the term loss the reference bank saves with its word, against the same bank without announcements")
