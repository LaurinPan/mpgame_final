# 02_Game/llm/debrief.R — Section 4.2.2 and v6 §5.4, the debrief from the term's record

# Section 4.2.2: the structure of the debrief, the text on the term and one text per marked quarter, the marked quarters as the only values of a quarter; of the list's length the API takes only that it is not empty
debrief_schema <- function(marks) {
  quarter <- if (length(marks)) list(type = "integer", enum = I(vapply(marks, `[[`, 1L, "q"))) else list(type = "integer")
  list(type = "object",
       properties = list(text_on_the_term = list(type = "string"),
                         marks = list(type = "array", minItems = min(length(marks), 1),
                                      items = list(type = "object", properties = list(quarter = quarter, text = list(type = "string")),
                                                   required = I(c("quarter", "text")), additionalProperties = FALSE))),
       required = I(c("text_on_the_term", "marks")), additionalProperties = FALSE)
}

# Section 4.2.2 and v6 §5.4: the debrief's instruction, composed for this term: its guided quarters, the case of a loss at most the bank's, and its marks
debrief_instruction <- function(record, marks) {
  s <- debrief_sentences; guided <- record$guided; n <- length(marks)
  later <- any(vapply(marks, function(m) m$kind == "deferred", logical(1)))
  text <- fill(model_text("instruction_debrief.md"), list(
    name = record$name, T = record$T,
    guided = if (!length(guided)) "" else fill(if (length(guided) == 1) s$guided_one else s$guided, list(list = word_list(guided))),
    case = if (record$term$player <= record$term$bank) s$case else "",
    marks = if (!n) s$no_marks else paste(c(fill(if (n == 1) s$marks_one else s$marks, list(n = n)), if (later) s$later), collapse = " ")))
  gsub(" +\n", "\n", gsub(" {2,}", " ", text))
}

# v6 §5.4: a distance from a normal level in the record, the player's in full and the bank's short where both lie on the same side
record_level <- function(player, bank, kind, unit, digits) {
  num <- function(x) formatC(round(abs(x), digits) + 0, format = "f", digits = digits)
  zero <- function(x) num(x) == num(0)
  phrase <- function(x) if (zero(x)) record_levels[[kind]][["on"]] else fill(record_levels[[kind]][["off"]], setNames(list(num(x), if (x > 0) "above" else "below"), c(unit, "side")))
  list(player = phrase(player), bank = if (!zero(player) && !zero(bank) && sign(player) == sign(bank)) paste(num(bank), unit) else phrase(bank))
}

# Section 4.2.2 and v6 §5.4: the term's record in words, the material of the debrief's call in its tags: the term, each quarter with the columns the topic shows, the new shocks as the player met them, the marks and the terms
debrief_material <- function(record, marks, instruction) {
  p <- record$player; b <- record$bank; s <- record_sentences; shows <- record$shows; th <- classes$thresholds
  rates <- function(text) paste(word_list(n2(as.numeric(strsplit(text, " ")[[1]]))), "percent")
  quarter <- function(k) {
    guided <- k %in% record$guided
    reading <- record_readings[[c("as", if (record$v[k] > 0) c("higher", "clearly_higher") else c("lower", "clearly_lower"))[findInterval(abs(record$v[k]), th$reading) + 1]]]
    aim <- if (shows$aim) record_level(p$aim[k], b$aim[k], "aim", "points", 2)
    spending <- if (shows$spending) record_level(p$G[k] / shows$share, b$G[k] / shows$share, "spending", "percent", 1)
    paste(c(
      fill(if (guided) s$rates_guided else s$rates, list(q = k, rate = n2(p$rate[k]), bank_rate = n2(b$rate[k]))),
      fill(s$figures, list(inflation = n2(p$pi_p[k]), bank_inflation = n2(b$pi_p[k]), gap = n2(p$x[k]), bank_gap = n2(b$x[k]),
                           unemployment = n2(p$U[k]), bank_unemployment = n2(b$U[k]))),
      if (shows$aim) c(fill(if (guided) s$reading_guided else s$reading, list(reading = reading)), fill(s$aim, list(aim = aim$player, bank_aim = aim$bank))),
      if (shows$word) c(fill(s$trust, list(trust = formatC(100 * p$chi[k], format = "f", digits = 0), bank_trust = formatC(100 * b$chi[k], format = "f", digits = 0))),
                        if (nzchar(p$word[k])) fill(s$path, list(path = rates(p$word[k])))),
      if (shows$spending) fill(s$spending, list(spending = spending$player, bank_spending = spending$bank)),
      if (shows$votes) c(fill(s$poll, list(poll = n1(100 * p$poll[k]), bank_poll = n1(100 * b$poll[k]))),
                         if (!is.na(p$election[k])) fill(if (identical(p$election[k], b$election[k])) s$vote_same else s$vote_other,
                                                         list(party = consts$parties[p$election[k]], bank_party = consts$parties[b$election[k]])))),
      collapse = " ")
  }
  event <- function(e) {
    if (e$type == "vote") return(fill(s$vote, list(q = e$q)))
    if (e$type == "slump") return(fill(s$slump, list(q = e$q, slump = e$words, n = e$length)))
    sh <- record_shocks
    fill(s$shock, list(q = e$q, words = fill(sh$words[[e$type]][[e$sign]], list(size = sh$sizes[[e$type]][[e$class]])), kind = sh$kinds[[e$type]],
                       source = sh$sources[[if (shows$paper) "newspaper" else "briefing"]], how = sh$how[[e$reported]]))
  }
  mark <- function(m) fill(if (m$kind == "deferred") s$mark_later else s$mark,
                           list(q = m$q, rate = n2(m$player_rate), bank_rate = n2(m$bank_rate), miss = n2(m$equivalent),
                                quarters = paste(if (length(m$shaded) == 1) "quarter" else "quarters", word_list(m$shaded))))
  eq <- record$term$equivalent
  parts <- list(term = fill(s$term, list(T = record$T, player = n2(eq$player), bank = n2(eq$bank))),
                quarters = vapply(seq_len(record$T), quarter, ""),
                events = vapply(record$events, event, ""), marks = vapply(marks, mark, ""))
  terms <- terms_of(c(instruction, unlist(parts)), always = "reference bank")
  paste(c(unlist(Map(tagged, names(parts), parts)), tagged("terms", terms)), collapse = "\n")
}

# Section 4.2.2: the debrief's request, its fixed part, its instruction and the record in words
debrief_request <- function(record, marks) {
  instruction <- debrief_instruction(record, marks)
  llm_request("debrief", model_text("fixed_debrief.md"), instruction, debrief_material(record, marks, instruction), debrief_schema(marks),
              models$debrief, models$effort$debrief, models$max_tokens$debrief, models$timeout_seconds$debrief, about = list(topic = record$topic))
}

# Section 4.2.2 and v6 §5.4: the debrief without a model, the losses as equivalent misses
debrief_fallback <- function(record, marks) {
  s <- debrief_fallback_texts; eq <- record$term$equivalent
  list(loss_text = fill(if (record$term$player <= record$term$bank) s$term_at_most else s$term, list(equivalent = n2(eq$player), bank_equivalent = n2(eq$bank))),
       marks = lapply(marks, function(m) list(q = m$q, text = fill(s$mark, list(q = m$q, player_rate = n2(m$player_rate), bank_rate = n2(m$bank_rate),
                                                                                equivalent = n2(m$equivalent), kind_words = s$kinds[[m$kind]])))),
       source = "fallback")
}

# Section 4.2.2: the debrief's texts, by the model or without it, the text on the term and one text per marked quarter; an answer counts where it holds exactly the marked quarters and no text falls short of the fewest words asked for by more than a tenth
write_debrief <- function(record, marks, on = llm_available()) {
  records <- list()
  if (on) {
    req <- debrief_request(record, marks)
    for (attempt in seq_len(models$retries + 1)) {
      r <- llm_call(req); records[[length(records) + 1]] <- r
      p <- r$parsed
      ok <- r$ok && is.character(p$text_on_the_term) && is.list(p$marks) && setequal(vapply(p$marks, function(m) as.integer(m$quarter), 1L), vapply(marks, `[[`, 1L, "q")) &&
            words_in(p$text_on_the_term) >= 0.9 * debrief_words[["term"]] && all(vapply(p$marks, function(m) words_in(m$text) >= 0.9 * debrief_words[["mark"]], logical(1)))
      if (ok) return(list(loss_text = p$text_on_the_term, marks = lapply(p$marks, function(m) list(q = as.integer(m$quarter), text = m$text)),
                          source = "model", model = r$model_served, records = records))
      if (!is.null(r$error) && r$status %in% c(400, 403, 404)) break
    }
  }
  c(debrief_fallback(record, marks), list(records = records))
}
