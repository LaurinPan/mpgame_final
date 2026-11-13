# 02_Game/llm/chat.R — Section 4.2.2, the Chief Economist's answers, one call per message

# Section 4.2.2: the structure of an answer, the kind of the message, the step answered at and the answer
chat_schema <- list(type = "object",
                    properties = list(kind = list(type = "string", enum = I(c("fact", "mechanism", "advice"))),
                                      step = list(type = "integer", enum = I(1:3)), answer = list(type = "string")),
                    required = I(c("kind", "step", "answer")), additionalProperties = FALSE)

# Section 4.2.2: the facts the chat holds in a topic, what its desk and its newspaper show and nothing else, with exact figures and each new shock as it was reported
chat_facts <- function(run, sheet) {
  parts <- fact_parts(sheet); word <- word_on(run$script); votes <- length(run$votes) > 0
  say <- function(names, precision = "exact") unlist(lapply(names, fact_sentence, parts = parts, precision = precision), use.names = FALSE)
  c(say(c("inflation", "inflation_change", "wage_inflation", "growth", "output", "output_fell", "unemployment", "persons", "quarters_above",
          "population", "labour_force", "rate", "spell")),
    unlist(lapply(sheet$shocks$shocks, function(s) say(paste0("shock_", s$type), if (identical(s$reported, "exact")) "exact" else "words")), use.names = FALSE),
    say(c("no_shock", "slump", "driver_output", "driver_inflation")),
    if ("expectations" %in% run$script$panels) say(c("expected_inflation", "aim", "aim_change")),
    if (word) say(c("path", "judgement", "room", "trust")),
    if (6 %in% run$config$on) say("spending"),
    if (votes) say(c("office", "next_election", "last_vote")),
    say(c("target", "natural_unemployment", "trend_growth", "floor", "cap", if (word) "reach", if (votes) "election_interval")))
}

# Sections 4.2.1 and 4.2.2: the staff forecast at the typed decision as sentences, with its band where a shock was reported in words
chat_forecast <- function(fc, typed, sheet) {
  if (is.null(fc)) return(NULL)
  s <- chat_sentences
  c(fill(if (is.null(typed$path)) s$forecast_rate else s$forecast,
         list(rate = n2(typed$rate), path = paste(word_list(n2(typed$path)), "percent"), inflation = n2(fc$mean[["inflation"]]),
              gap = n2(fc$mean[["output_gap"]]), unemployment = n2(fc$mean[["unemployment"]]))),
    if (length(fc$in_words)) fill(s$band, list(inflation_lo = n2(fc$band$lo[["inflation"]]), inflation_hi = n2(fc$band$hi[["inflation"]]),
                                               unemployment_lo = n2(fc$band$lo[["unemployment"]]), unemployment_hi = n2(fc$band$hi[["unemployment"]])))
    else if (length(sheet$shocks$shocks)) s$exact else s$quiet)
}

# Section 4.2.2: the conversation as lines, this quarter's briefings, every question of the term with its number and quarter, and the last three answers
chat_conversation <- function(chat, q) {
  recent <- tail(which(vapply(chat, function(m) m$kind == "answer", logical(1))), 3)
  n <- 0; lines <- character(0); s <- chat_sentences
  for (i in seq_along(chat)) {
    m <- chat[[i]]
    if (m$kind == "briefing" && m$q == q) lines <- c(lines, fill(s$briefing, list(text = m$text)))
    if (m$kind == "question") { n <- n + 1; lines <- c(lines, fill(s$question, list(n = n, q = m$q, text = m$text))) }
    if (m$kind == "answer" && i %in% recent) lines <- c(lines, fill(s$answer, list(text = m$text)))
  }
  lines
}

# Section 4.2.2: the request of an answer, the chat's fixed part, the instruction with the topic's never sentence and the material in its tags; typed is the decision on the page, the desk's starting decision where none is passed, and a decision the checks refuse has no forecast
chat_request <- function(run, question, typed = NULL) {
  q <- run$t + 1; id <- run$topic
  if (q > length(run$sheets)) stop("quarter ", q, " has no sheet yet")
  sheet <- run$sheets[[q]]
  if (is.null(typed)) typed <- run$quarter$start
  fc <- quarter_preview(run, typed$rate, typed$path)$forecast
  never <- if (id %in% names(chat_never)) paste(chat_never[[id]], chat_never_holds) else ""
  instruction <- gsub("\n{3,}", "\n\n", fill(model_text("instruction_chat.md"), list(never = never)))
  facts    <- chat_facts(run, sheet)
  forecast <- chat_forecast(fc, typed, sheet)
  topic    <- readLines(file.path("02_Game/content/notes", paste0(id, ".md")), warn = FALSE, encoding = "UTF-8")
  places   <- unlist(lapply(chat_places, function(p) if (id %in% p$topics) p$place))
  material <- c(tagged("facts", facts), tagged("forecast", forecast), tagged("topic", topic), tagged("places", places),
                tagged("terms", terms_of(c(facts, forecast, topic, question))), tagged("conversation", chat_conversation(run$chat, q)),
                tagged("question", question))
  llm_request("chat", model_text("fixed_chat.md"), instruction, paste(material, collapse = "\n"), chat_schema,
              models$chat, models$effort$chat, models$max_tokens$chat, models$timeout_seconds$chat, about = list(q = q))
}

# Section 4.2.2: one message of the governor as one call, the question and the answer appended to the chat, the step stored with the answer
chat_answer <- function(run, question, typed = NULL) {
  q <- run$t + 1
  if (q > length(run$sheets)) stop("quarter ", q, " has no sheet yet")
  req <- if (model_on(run)) chat_request(run, question, typed)
  n_questions <- sum(vapply(run$chat, function(x) x$kind == "question", logical(1)))
  run$chat[[length(run$chat) + 1]] <- list(q = q, kind = "question", id = n_questions + 1, text = question)
  answer <- list(q = q, kind = "answer", class = NA, rung = 1, text = chat_fallback_text, source = "fallback")
  if (!is.null(req)) {
    for (attempt in seq_len(models$retries + 1)) {
      r <- llm_call(req); run$calls[[length(run$calls) + 1]] <- r
      p <- r$parsed
      ok <- r$ok && is.character(p$answer) && isTRUE(p$kind %in% c("fact", "mechanism", "advice")) && isTRUE(p$step %in% 1:3)
      if (ok) { answer <- list(q = q, kind = "answer", class = p$kind, rung = as.integer(p$step), text = p$answer, source = "model"); break }
    }
  }
  run$chat[[length(run$chat) + 1]] <- answer
  run
}
