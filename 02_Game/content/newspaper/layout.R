# 02_Game/content/newspaper/layout.R — v6 §12.1 and §12.2: pages, slots, formats and budgets

# v6 §12.1: the pages and slots
slots <- data.frame(
  page    = c(1, 1, 1, 2, 2, 3, 3, 4),
  slot    = c("masthead", "index", "L", "S1", "S2", "S3", "S4", "S5"),
  size    = c("", "narrow", "large", "medium", "medium", "medium", "medium", "long"),
  section = c("the paper's name, the quarter and the year", "In this edition", "Front page",
              "The Economy", "Prices and Wages", "Jobs", "Markets and the Bank", "Politics or Analysis"),
  stringsAsFactors = FALSE)

# v6 §12.2: the eight formats with their elements in order, the elements the game fills, their counts in slot S5 and in every other slot, their word budgets and their sentence
formats <- list(
  "F-LEAD" = list(
    elements = c("kicker", "headline", "standfirst", "chart", "body", "figures"), game = c("kicker", "chart", "figures"),
    paragraphs = c(other = 3),
    budgets  = list(headline = 10, standfirst = 25, body = c(150, 190)),
    sentence = "Write a headline of at most 10 words, a standfirst of one sentence and at most 25 words, and a body of three paragraphs with 150 to 190 words in all."),
  "F-REPORT" = list(
    elements = c("headline", "body"), game = character(0),
    paragraphs = c(other = 2, S5 = 3),
    budgets  = list(headline = 9, body = c(110, 160)),
    sentence = "Write a headline of at most 9 words and a body of {n} with {lo} to {hi} words in all."),
  "F-CHART" = list(
    elements = c("headline", "chart", "caption", "body"), game = c("chart", "caption"),
    paragraphs = c(other = 1, S5 = 2),
    budgets  = list(headline = 9, body = c(80, 110)),
    sentence = "Write a headline of at most 9 words and a body of {n} with {lo} to {hi} words in all."),
  "F-INTERVIEW" = list(
    elements = c("headline", "intro", "qa"), game = character(0),
    questions = c(other = 4, S5 = 6),
    budgets  = list(headline = 8, question = 15, answer = 40),
    sentence = "Write a headline of at most 8 words that quotes one of the economist's answers, one sentence that introduces the economist by role, and {k} questions of at most 15 words, each followed by the economist's answer of at most 40 words."),
  "F-VOICES" = list(
    elements = c("headline", "intro", "quotes"), game = character(0),
    quotations = c(other = 4, S5 = 6),
    budgets  = list(headline = 9, quotation = 30),
    sentence = "Write a headline of at most 9 words, one sentence that introduces the people quoted, and {k} quotations of at most 30 words, each in that person's everyday words."),
  "F-COMMENT" = list(
    elements = c("headline", "author", "body"), game = "author",
    paragraphs = c(other = 2, S5 = 3),
    budgets  = list(headline = 9, body = c(120, 160)),
    sentence = "Write a headline of at most 9 words and a comment of {n} with {lo} to {hi} words in all."),
  "F-MARKETS" = list(
    elements = c("headline", "table", "body"), game = character(0),
    rows = 3, paragraphs = c(other = 1),
    budgets  = list(headline = 9, body = c(80, 110)),
    sentence = "Write a headline of at most 9 words, a table of three figures from your facts, each with its label, its value and what it is compared with, and a body of one paragraph with 80 to 110 words."),
  "F-BRIEF" = list(
    elements = c("headline", "body"), game = character(0),
    paragraphs = c(other = 1, S5 = 1), sentences = c(other = "one or two", S5 = "two to four"),
    budgets  = list(headline = 6, body = c(25, 45)),
    sentence = "Write a headline of at most 6 words and a body of one paragraph of {sentences} sentences with {lo} to {hi} words in all."))

# v6 §12.2: a number of paragraphs in words
paragraph_words <- c("one paragraph", "two paragraphs", "three paragraphs")

# v6 §12.1: a format in its slot, slot S5 with twice the body's budget and its own counts
slot_format <- function(format, slot = NULL) {
  f <- formats[[format]]; s5 <- identical(slot, "S5")
  for (count in intersect(c("paragraphs", "questions", "quotations", "sentences"), names(f)))
    f[[count]] <- unname(if (s5) f[[count]][["S5"]] else f[[count]][["other"]])
  if (s5 && !is.null(f$budgets$body)) f$budgets$body <- 2 * f$budgets$body
  f
}

# v6 §12.2: how the format follows from the type, the tone and the precision, first match
format_rule <- data.frame(
  role   = c("lead", "brief", "brief", "piece", "piece", "piece", "piece", "piece", "piece", "piece", "piece"),
  tone   = c(NA, NA, NA, "reporter", "reporter", "economist", "household", "business", "critic", "markets", "markets"),
  exact  = c(NA, TRUE, NA, TRUE, NA, NA, NA, NA, NA, TRUE, NA),
  chart  = c(NA, TRUE, NA, TRUE, NA, NA, NA, NA, NA, NA, NA),
  format = c("F-LEAD", "F-CHART", "F-BRIEF", "F-CHART", "F-REPORT", "F-INTERVIEW", "F-VOICES", "F-VOICES",
             "F-COMMENT", "F-MARKETS", "F-REPORT"),
  stringsAsFactors = FALSE)
