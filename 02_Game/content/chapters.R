# 02_Game/content/chapters.R — Section 4.3, Table 1: the five chapters

# Table 1: each chapter with its name, stages, topics and briefing
chapters <- list(
  A = list(id = "A", name = "Taking Office",  stages = c(1, 3, 4),    topics = "T1",                briefing = "B-A"),
  B = list(id = "B", name = "The Trade-Off",  stages = c(1, 2, 3, 4), topics = "T2",                briefing = "B-B"),
  C = list(id = "C", name = "Public Beliefs", stages = c(1, 3, 4, 5), topics = c("T3", "T4", "T5"), briefing = "B-C"),
  D = list(id = "D", name = "Government",     stages = c(1, 3, 4, 6), topics = c("T6", "T7"),       briefing = "B-D"),
  E = list(id = "E", name = "Full Game",      stages = 1:6,           topics = "T8",                briefing = "B-E"))
