# 02_Game/content/scripts/T7.R — v6 §6, Topic 7 (Chapter D; Section 4.3, Table 1)

# v6 §6: the script of Topic 7
T7 <- list(
  id = "T7", name = "Elections", chapter = "D",
  objective = "Electoral pressure",
  task = "Keep inflation and output on track through two elections, whatever the party in office spends before a vote.",
  summary = "Before an election the party in office may spend more, and the policy rate decides whether that wins it votes.",
  path = "optional",
  builds_on = c("P3", "P5"),
  stages = c(1, 3, 4, 6),
  term = 16,
  panels = c("figures", "map", "rate", "newspaper", "chat"),
  start = list(gov = list(party = 1, g_base = 0, standing = 0, tau = 0, to_election = 8)),
  timeline = list(
    list(q = 8, vote = TRUE),
    list(q = 16, vote = TRUE)),
  guided = NULL,
  tour = "TOUR-T7",
  briefings = list(topic_open = "B-T7",
                   quarter_start = c("6" = "B-E7-6", "9" = "B-E7-9", "14" = "B-E7-14")),
  notes = "N-T7",
  debrief = list(covers = 1:16,
                 focus = "Extra spending before an election helps the party in office only if the central bank lets it work, and voters who have seen it before treat it with caution.",
                 expected_marks = c("immediate", "deferred")),
  checks = "the boosting party's chance at its first re-election under a bank that holds the rate in the window, against the believed rule")
