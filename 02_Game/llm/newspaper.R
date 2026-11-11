# 02_Game/llm/newspaper.R — Section 4.2.2 and v6 §12, the newspaper's pipeline

# v6 §12.2: the structure of a piece's answer in its slot; the API takes no exact length for a list, so the structure fixes every count itself: a body of one paragraph is one text, and each further paragraph, each question with its answer, each quotation with the role the editor drew for it and each row of the table has a key of its own
format_schema <- function(item) {
  f <- slot_format(item$format, item$slot)
  text <- list(type = "string")
  obj  <- function(props) list(type = "object", properties = props, required = I(names(props)), additionalProperties = FALSE)
  each <- function(name, n, of) obj(setNames(lapply(seq_len(n), of), paste0(name, "_", seq_len(n))))
  body <- if (is.null(f$paragraphs)) NULL else if (f$paragraphs == 1) text else each("paragraph", f$paragraphs, function(i) text)
  switch(item$format,
    "F-LEAD"      = obj(list(headline = text, standfirst = text, body = body)),
    "F-REPORT"    = , "F-CHART" = , "F-BRIEF" = , "F-COMMENT" = obj(list(headline = text, body = body)),
    "F-INTERVIEW" = obj(list(headline = text, intro = text, qa = each("exchange", f$questions, function(i) obj(list(question = text, answer = text))))),
    "F-VOICES"    = obj(list(headline = text, intro = text, quotes = each("quotation", f$quotations, function(i) obj(list(role = list(type = "string", enum = I(item$speakers[i])), text = text))))),
    "F-MARKETS"   = obj(list(headline = text, table = each("row", f$rows, function(i) obj(list(label = text, value = text, compared_with = text))), body = body)),
    stop("unknown format ", item$format))
}

# v6 §12.2: a parsed answer as the piece's elements, the body as its paragraphs, a line break inside a text counting as a new paragraph, and the interview, the quotations and the table as lists in their order, a row's comparison under the name the views keep, change
as_elements <- function(parsed) {
  if (is.character(parsed$body) || is.list(parsed$body)) {
    paragraphs <- trimws(unlist(strsplit(unlist(parsed$body), "\n+")))
    parsed$body <- as.list(unname(paragraphs[nzchar(paragraphs)]))
  }
  for (element in intersect(c("qa", "quotes", "table"), names(parsed))) parsed[[element]] <- unname(parsed[[element]])
  if (!is.null(parsed$table)) parsed$table <- lapply(parsed$table, function(row) list(label = row$label, value = row$value, change = row$compared_with))
  parsed
}

# v6 §12.2: the words of a text
words_in <- function(x) length(strsplit(trimws(paste(x, collapse = " ")), "[[:space:]]+")[[1]])

# v6 §12.2 and §12.7: a parsed answer against its format in its slot, TRUE or the check it failed with the numbers of its retry sentence; a limit counts as kept within a tenth
check_piece <- function(parsed, item) {
  f <- slot_format(item$format, item$slot); b <- f$budgets
  fail  <- function(kind, values = list()) structure(FALSE, kind = kind, values = values)
  texts <- function(x, of = NULL) is.list(x) && length(x) && all(vapply(x, function(e) if (is.null(of)) is.character(e) && length(e) == 1 else is.list(e) && all(vapply(e[of], is.character, logical(1))), logical(1)))
  over  <- function(text, limit) words_in(text) > 1.1 * limit
  if (!is.list(parsed) || !all(setdiff(f$elements, f$game) %in% names(parsed)) || !is.character(parsed$headline)) return(fail("structure"))
  if (!is.null(f$paragraphs)) {
    if (!texts(parsed$body)) return(fail("structure"))
    if (length(parsed$body) != f$paragraphs) return(fail("paragraphs", list(k = if (length(parsed$body) == 1) "1 paragraph" else sprintf("%d paragraphs", length(parsed$body)), n = f$paragraphs)))
  }
  if (!is.null(f$questions) && !(texts(parsed$qa, c("question", "answer")) && length(parsed$qa) == f$questions)) return(fail("structure"))
  if (!is.null(f$quotations) && !(texts(parsed$quotes, c("role", "text")) && identical(vapply(parsed$quotes, function(x) x$role, ""), item$speakers))) return(fail("structure"))
  if (!is.null(f$rows) && !(texts(parsed$table, c("label", "value", "change")) && length(parsed$table) == f$rows)) return(fail("structure"))
  if (over(parsed$headline, b$headline)) return(fail("headline", list(k = words_in(parsed$headline), h = b$headline)))
  if (!is.null(b$standfirst) && (!is.character(parsed$standfirst) || over(parsed$standfirst, b$standfirst))) return(fail("long"))
  for (x in parsed$qa) if (over(x$question, b$question) || over(x$answer, b$answer)) return(fail("long"))
  for (x in parsed$quotes) if (over(x$text, b$quotation)) return(fail("long"))
  if (!is.null(f$paragraphs)) {
    n <- words_in(unlist(parsed$body))
    if (n > 1.1 * b$body[2] || n < 0.9 * b$body[1]) return(fail("body", list(k = n, lo = b$body[1], hi = b$body[2])))
  }
  TRUE
}

# v6 §12.7: the sentence a failed answer is asked for again with; an element over its limit counts as the structure
retry_sentence <- function(check) {
  kind <- attr(check, "kind")
  fill(retry_sentences[[if (kind == "long") "structure" else kind]], attr(check, "values"))
}

# v6 §12.7: a text cut at its last complete sentence within a budget
cut_sentences <- function(text, max_words) {
  sentences <- trimws(strsplit(text, "(?<=[.!?])[[:space:]]+", perl = TRUE)[[1]])
  sentences <- sentences[nzchar(sentences)]
  if (!length(sentences)) return(text)
  kept <- sentences[1]; n <- words_in(kept)
  for (s in sentences[-1]) { if (n + words_in(s) > max_words) break; kept <- c(kept, s); n <- n + words_in(s) }
  paste(kept, collapse = " ")
}

# v6 §12.7: a piece's texts shortened within its slot's budgets, each at its last complete sentence
shorten_piece <- function(parsed, item) {
  b <- slot_format(item$format, item$slot)$budgets
  if (!is.null(b$body) && words_in(unlist(parsed$body)) > b$body[2]) {
    left <- b$body[2]; body <- list()
    for (p in parsed$body) {
      if (left <= 0) break
      n <- words_in(p)
      if (n <= left) { body[[length(body) + 1]] <- p; left <- left - n }
      else { body[[length(body) + 1]] <- cut_sentences(p, left); break }
    }
    parsed$body <- body
  }
  if (!is.null(parsed$qa)) parsed$qa <- lapply(parsed$qa, function(x) { if (words_in(x$answer) > b$answer) x$answer <- cut_sentences(x$answer, b$answer); x })
  if (!is.null(parsed$quotes)) parsed$quotes <- lapply(parsed$quotes, function(x) { if (words_in(x$text) > b$quotation) x$text <- cut_sentences(x$text, b$quotation); x })
  if (!is.null(b$standfirst) && words_in(parsed$standfirst) > b$standfirst) parsed$standfirst <- cut_sentences(parsed$standfirst, b$standfirst)
  parsed
}

# v6 §12.7: a piece without a model, its type's headline and body filled from the sheet
template_piece <- function(item, sheet, reason = "no key") {
  lines <- readLines(file.path("02_Game/content/newspaper/templates", paste0(item$type, ".md")), warn = FALSE, encoding = "UTF-8")
  text  <- function(label) cap1(fill_placeholders(sub(paste0("^", label, ": "), "", grep(paste0("^", label, ": "), lines, value = TRUE)[1]), sheet))
  list(slot = item$slot, section = item$section, type = item$type, star = item$star, tone = item$tone,
       precision = "words", format = "F-BRIEF", chart = NA, source = "template", reason = reason,
       elements = list(headline = text("Headline"), body = list(text("Body"))))
}

# Section 4.2.2 and v6 §12: the instruction of a piece, composed for this call alone: its page, its assignment, its voice, its speakers, its format, its precision, its facts and, for the lead, the other pages
piece_instruction <- function(item, sheet, may) {
  f <- slot_format(item$format, item$slot); lead <- item$slot == "L"
  assignment <- types$assignment[types$id == item$type]
  if (item$type == "A-analysis") assignment <- if (is.na(sheet$pressing$variable)) analysis_quiet else fill(assignment, list(figure = variable_words[[sheet$pressing$variable]]))
  paste(c(if (lead) page_sentences[["lead"]] else fill(page_sentences[["piece"]], list(section = sub("^The ", "", item$section))),
          assignment, voices[[item$tone]],
          fill(speakers$sentences[[if (item$format %in% names(speakers$sentences)) item$format else "other"]], list(roles = word_list(item$speakers))),
          fill(f$sentence, list(n = paragraph_words[f$paragraphs], lo = f$budgets$body[1], hi = f$budgets$body[2], k = c(f$questions, f$quotations), sentences = f$sentences)),
          precision_sentences[[item$precision]], facts_sentences[[if (may) "use_may" else "use"]],
          if (lead) facts_sentences[["other_pages"]]), collapse = " ")
}

# Section 4.2.2: the request of a piece or of the lead, the newspaper's fixed part, the instruction and the material in its tags, the facts, the terms of the call's texts that a general reader would not know and for the lead the other pages; a retry adds its sentence after the material
piece_request <- function(item, sheet, fct, other = NULL, retry = NULL) {
  lead <- item$slot == "L"
  fixed <- model_text("fixed_newspaper.md")
  if (lead) { stopifnot(grepl(lead_tags[["piece"]], fixed, fixed = TRUE)); fixed <- sub(lead_tags[["piece"]], lead_tags[["lead"]], fixed, fixed = TRUE) }
  instruction <- piece_instruction(item, sheet, length(fct$may_use) > 0)
  material <- c(tagged("use", fct$use), tagged("may_use", fct$may_use),
                tagged("terms", terms_of(c(instruction, fct$use, fct$may_use, other), reader = TRUE)), tagged("other_pages", other), retry)
  llm_request(if (lead) "lead" else "piece", fixed, instruction, paste(material, collapse = "\n"), format_schema(item),
              models$pieces, models$effort$pieces, models$max_tokens$pieces, models$timeout_seconds$pieces,
              about = c(list(q = sheet$q), item[c("slot", "type", "tone", "precision", "format")], list(retry = !is.null(retry))))
}

# v6 §12.2: a piece as the issue holds it, a comment with the author line the game prints
model_piece <- function(item, record, elements = record$parsed, retried = FALSE, shortened = FALSE, kept = NULL) {
  if (item$format == "F-COMMENT") elements$author <- speakers$author
  list(slot = item$slot, section = item$section, type = item$type, star = item$star, tone = item$tone,
       precision = item$precision, format = item$format, chart = item$chart, source = "model",
       model = record$model_served, elements = elements, retried = retried, shortened = shortened, kept = kept)
}

# Section 4.2.2 and v6 §12.7: the answer taken, the first that passed its check; else the last, shortened where a text ran over its budget and kept as it is otherwise, or the template where no answer was parsed
settle_piece <- function(item, answers, sheet) {
  parsed <- Filter(function(a) a$record$ok, answers)
  if (!length(parsed)) return(template_piece(item, sheet, reason = "no answer parsed"))
  passed <- Filter(function(a) isTRUE(a$check), parsed)
  if (length(passed)) return(model_piece(item, passed[[1]]$record, retried = length(answers) > 1))
  last <- parsed[[length(parsed)]]; kind <- attr(last$check, "kind")
  short <- shorten_piece(last$record$parsed, item)
  if (kind %in% c("long", "body") && !identical(short, last$record$parsed)) model_piece(item, last$record, short, retried = TRUE, shortened = TRUE)
  else model_piece(item, last$record, retried = TRUE, kept = kind)
}

# Section 4.2.2, "one call per piece": pieces written at once, each answer read as the piece's elements and checked, and a failed one asked for again with the sentence of its check
write_slots <- function(items, sheet, facts_by, other = NULL, on = llm_available()) {
  if (!on) return(list(pieces = lapply(items, template_piece, sheet = sheet), records = list()))
  answers <- setNames(vector("list", length(items)), names(items)); retry <- list(); records <- list(); pending <- names(items)
  for (attempt in seq_len(models$retries + 1)) {
    if (!length(pending)) break
    recs <- llm_calls(lapply(items[pending], function(it) piece_request(it, sheet, facts_by[[it$slot]], other, retry[[it$slot]])))
    recs <- lapply(recs, function(r) { if (r$ok) r$parsed <- as_elements(r$parsed); r })
    records <- c(records, unname(recs))
    for (slot in pending) {
      r <- recs[[slot]]; chk <- if (r$ok) check_piece(r$parsed, items[[slot]]) else FALSE
      answers[[slot]][[length(answers[[slot]]) + 1]] <- list(record = r, check = chk)
      retry[slot] <- list(if (r$ok && !isTRUE(chk)) retry_sentence(chk))
    }
    pending <- pending[!vapply(pending, function(slot) isTRUE(answers[[slot]][[length(answers[[slot]])]]$check), logical(1))]
  }
  list(pieces = lapply(items, function(it) settle_piece(it, answers[[it$slot]], sheet)), records = records)
}

# v6 §12.3: a chart's data from the sheet's history
chart_data <- function(id, sheet) {
  ch <- charts[charts$id == id, ]; h <- sheet$history; law <- sheet$law
  series <- strsplit(ch$series, ";")[[1]]
  data <- lapply(series, function(sname) switch(sname,
    announced = if (isTRUE(sheet$word$has_path)) sheet$word$path else NULL,
    if (sname %in% names(h)) data.frame(t = h$t, value = h[[sname]]) else NULL))
  names(data) <- series
  reference <- if (is.na(ch$reference)) NA else switch(ch$reference, target = law$target, natural_unemployment = law$natural_unemployment,
                                                      zero = 0, half = 50, normal = 0, NA)
  list(id = id, series = data, reference = reference, caption = ch$caption)
}

# v6 §12.2: the lead's strip of key figures, its first three must facts with exact figures
key_figures <- function(item, sheet) {
  parts <- fact_parts(sheet)
  strip <- lapply(facts_of(item$must, sheet), function(f) list(label = f, text = fact_sentence(f, parts, "exact")))
  head(Filter(function(x) !is.null(x$text), strip), 3)
}

# v6 §12.1: the issue assembled, its masthead, index, pages and pieces
assemble_issue <- function(plan, pieces, lead, sheet) {
  q <- sheet$q
  all <- c(list(L = lead), pieces)
  for (slot in names(all)) {
    it <- plan$items[[slot]]; p <- all[[slot]]
    if (!is.na(p$chart)) p$chart_data <- chart_data(p$chart, sheet)
    if (slot == "L" && p$precision == "exact") { p$chart_data <- chart_data(types$chart[types$id == it$type], sheet); p$figures <- key_figures(it, sheet) }
    p$kicker <- it$section
    all[[slot]] <- p
  }
  pages <- list("1" = c("masthead", "index", "L"), "2" = c("S1", "S2"), "3" = c("S3", "S4"), "4" = "S5")
  page_of <- function(slot) as.integer(names(pages)[vapply(pages, function(s) slot %in% s, logical(1))])
  index <- data.frame(slot = names(all), section = vapply(all, `[[`, "", "section"),
                      headline = vapply(all, function(p) p$elements$headline, ""), page = vapply(names(all), page_of, 1L),
                      stringsAsFactors = FALSE)
  list(masthead = list(name = "The Ledger", quarter = q, year = 1 + (q - 1) %/% 4, quarter_of_year = (q - 1) %% 4 + 1,
                       dateline = sprintf("Quarter %d of year %d", (q - 1) %% 4 + 1, 1 + (q - 1) %/% 4)),
       index = index, pages = pages, pieces = all, selection = plan$selection, reported = plan$reported)
}

# Section 4.2.2: the issue planned, the editor's plan with its precision draws and the sheet's second step with the shocks reported
plan_issue <- function(run, q, sheet1) {
  plan <- edit_issue(sheet1, run$script)
  list(plan = plan, sheet = fact_sheet(run, q, step = 2, reported = plan$reported))
}

# Section 4.2.2 and the interface: the paper of quarter q written from its plan and its sheet into run$issues[[q]], the five inside pieces at once and then the lead with their headlines, and each piece's facts into run$masks[[q]]
paper_write <- function(run, q) {
  plan <- run$plans[[q]]; sheet <- run$sheets[[q]]
  if (is.null(plan)) return(run)
  on <- model_on(run)
  facts_by <- lapply(plan$items, piece_facts, sheet = sheet)
  inside <- write_slots(plan$items[setdiff(names(plan$items), "L")], sheet, facts_by, on = on)
  other  <- sprintf("%s: %s", vapply(inside$pieces, `[[`, "", "section"), vapply(inside$pieces, function(p) p$elements$headline, ""))
  lead   <- write_slots(plan$items["L"], sheet, facts_by, other, on)
  run$issues[[q]] <- assemble_issue(plan, inside$pieces, lead$pieces$L, sheet)
  run$masks[[q]]  <- facts_by
  run$calls <- c(run$calls, inside$records, lead$records)
  run
}
