# ui/paper.R — the newspaper drawn from issue_view (scripts appendix §12): the
# masthead with the quarter and the year, two spreads of two pages, the index on
# page 1 beside the lead, the slots S1 to S5 at fixed places, each piece in its
# format (§12.2) with its chart (§12.3), a piece that runs past its page
# continued on the next (§12.7), the staff's selection marking whole pieces
# (scripts appendix §4.5). The folded paper on the desk strip carries the lead's
# headline and standfirst, and while the background worker prints the edition
# the line that it is being printed. Pure functions on the issue.

paper_selection_attr <- function(on) if (isTRUE(on)) "true" else "false"
# The selection's switch on the paper's bar.
ui_paper_switch_html <- function(on) game_tag("button", list(type = "button", class = "paper-switch", `data-paper` = "selection", `aria-pressed` = paper_selection_attr(on)),
                                             game_tag("span", list(class = "paper-switch-knob", `aria-hidden` = "true"), ""), game_esc(ui_s("paper.selection")))
# The masthead's dateline.
ui_paper_dateline <- function(iss) ui_s("paper.dateline", dateline = iss$masthead$dateline)

# The folded paper on the desk strip: the masthead, the dateline, the lead's headline and standfirst, the switch beside it.
ui_paper_folded_html <- function(iss, selection = FALSE) {
  L <- iss$pieces$L$elements
  game_tag("div", list(class = paste(c("paper-folded-wrap", if (isTRUE(selection)) "is-selection"), collapse = " ")),
    game_tag("button", list(type = "button", class = "paper-folded", `data-paper` = "open", `aria-haspopup` = "dialog", `aria-controls` = "paper-overlay", `aria-label` = ui_s("paper.open_label")),
             game_tag("span", list(class = "paper-folded-mast"), game_tag("span", list(class = "paper-name"), game_esc(ui_s("paper.name"))),
                      game_tag("span", list(class = "paper-dateline"), game_esc(ui_paper_dateline(iss)))),
             game_tag("span", list(class = "paper-folded-headline"), game_esc(L$headline %||% "")),
             game_tag("span", list(class = "paper-folded-summary"), game_esc(ui_s("paper.folded_summary", summary = L$standfirst %||% (if (length(L$body)) L$body[[1]] else ""))))),
    ui_paper_switch_html(selection))
}

# The folded paper while the worker prints quarter q's edition: the masthead and the line that it is being printed,
# nothing to open, the switch's room kept (hidden) so that the paper does not move when it arrives; the page script puts the folded
# paper in its place then.
ui_paper_printing_html <- function(q) {
  game_tag("div", list(class = "paper-folded-wrap is-printing", `data-paper-quarter` = q),
    game_tag("div", list(class = "paper-folded", role = "status"),
             game_tag("span", list(class = "paper-folded-mast"), game_tag("span", list(class = "paper-name"), game_esc(ui_s("paper.name")))),
             game_tag("span", list(class = "paper-folded-headline paper-printing"), game_esc(ui_s("paper.printing")))),
    ui_paper_switch_html(FALSE))
}

# --- the pieces, by format (scripts appendix §12.2) -------------------------------------------------------------------------------------------------
paper_paras_html <- function(paras) paste(vapply(as.character(unlist(paras)), function(p) game_tag("p", list(), game_esc(p)), ""), collapse = "")
# The lines a text takes in a column of `chars` characters (the layout's count).
paper_lines <- function(text, chars) if (is.null(text) || !length(text) || all(!nzchar(text))) 0L else as.integer(sum(ceiling(nchar(text) / chars)))
# A piece's elements as HTML, in the format's order: the kicker (the section), the headline, the standfirst, the chart with its caption,
# the intro, the author line, the body's paragraphs, the questions and answers, the quotations, the table, the lead's strip of figures.
ui_piece_body_html <- function(p, lead = FALSE) {
  e <- p$elements; f <- p$format; out <- character(0)
  chart <- if (!is.null(p$chart_data) && length(p$chart_data$series)) game_tag("figure", list(class = "paper-art-chart"), game_tag("span", list(class = "paper-tab", `aria-hidden` = "true"), ""),
                                                                                game_tag("figcaption", list(class = "paper-chart-title"), game_esc(p$chart_data$caption)), ui_paper_chart_svg(p$chart_data))
  if (!is.null(e$standfirst) && nzchar(e$standfirst)) out <- c(out, game_tag("p", list(class = "paper-standfirst"), game_esc(e$standfirst)))
  if (!is.null(chart) && f %in% c("F-LEAD", "F-CHART")) out <- c(out, chart)
  if (!is.null(e$intro) && nzchar(e$intro)) out <- c(out, game_tag("p", list(class = "paper-intro"), game_esc(e$intro)))
  if (!is.null(e$author) && nzchar(e$author)) out <- c(out, game_tag("p", list(class = "paper-author"), game_esc(ui_s("paper.author", author = e$author))))
  if (!is.null(e$table) && length(e$table)) out <- c(out, game_tag("table", list(class = "paper-table"),
    game_tag("thead", list(), game_tag("tr", list(), game_tag("th", list(scope = "col"), game_esc(ui_s("paper.table_label"))), game_tag("th", list(scope = "col"), game_esc(ui_s("paper.table_value"))), game_tag("th", list(scope = "col"), game_esc(ui_s("paper.table_change"))))),
    game_tag("tbody", list(), paste(vapply(e$table, function(r) game_tag("tr", list(), game_tag("th", list(scope = "row"), game_esc(r$label)), game_tag("td", list(), game_esc(r$value)), game_tag("td", list(), game_esc(r$change))), ""), collapse = ""))))
  if (!is.null(p$units)) {                                       # a piece cut at its slot's foot: the units that fit (paper_fit_slot)
    out <- c(out, game_tag("div", list(class = paste("paper-body-cols", if (!is.null(e$qa)) "paper-qa" else if (!is.null(e$quotes)) "paper-voices")), paper_units_html(p$units)))
  } else {
    if (!is.null(e$body) && length(e$body)) out <- c(out, game_tag("div", list(class = "paper-body-cols"), paper_paras_html(e$body)))
    if (!is.null(e$qa) && length(e$qa)) out <- c(out, game_tag("div", list(class = "paper-body-cols paper-qa"), paste(vapply(e$qa, function(x) paste0(
      game_tag("p", list(class = "paper-q"), game_tag("strong", list(), game_esc(paste0(ui_s("paper.qa_q"), " "))), game_esc(x$question)), game_tag("p", list(class = "paper-a"), game_esc(x$answer))), ""), collapse = "")))
    if (!is.null(e$quotes) && length(e$quotes)) out <- c(out, game_tag("div", list(class = "paper-body-cols paper-voices"), paste(vapply(e$quotes, function(x)
      game_tag("p", list(class = "paper-quote"), game_esc(paste0("“", x$text, "”")), " ", game_tag("span", list(class = "paper-quote-role"), game_esc(paste0("— ", x$role)))), ""), collapse = "")))
  }
  if (!is.null(p$figures) && length(p$figures)) out <- c(out, game_tag("div", list(class = "paper-figures-strip"), game_tag("span", list(class = "paper-figures-head"), game_esc(ui_s("paper.figures_head"))),
    paste(vapply(p$figures, function(x) game_tag("span", list(class = "paper-figure"), game_esc(game_upper_first(x$text))), ""), collapse = "")))
  paste(out, collapse = "")
}
# A piece's classes (its mark in the selection, its type and format).
paper_piece_classes <- function(p, iss, extra = NULL) paste(c("paper-article", extra, if (p$slot %in% iss$selection) "is-signal", paste0("paper-type-", game_slug(p$type)), paste0("paper-format-", game_slug(p$format))), collapse = " ")
# A piece in its format, with its continuation's head or foot.
ui_piece_html <- function(p, iss, lead = FALSE, cont = NULL) {
  e <- p$elements
  head <- paste0(game_tag("p", list(class = "paper-kicker"), game_esc(p$kicker %||% p$section)),
                 game_tag(if (lead) "h2" else "h3", list(class = if (lead) "paper-headline" else "paper-article-head", id = if (lead) "paper-headline"), game_esc(e$headline %||% "")),
                 if (p$slot %in% iss$selection) game_tag("span", list(class = "paper-margin-mark"), game_tag("span", list(class = "sr-only"), game_esc(ui_s("paper.mark_signal")))))
  note <- if (identical(p$source, "template")) game_tag("p", list(class = "paper-template-note"), game_esc(ui_s("paper.template_note")))
  game_tag("section", list(class = paper_piece_classes(p, iss, if (lead) "paper-lead"), `data-slot` = p$slot, `data-type` = p$type, `data-format` = p$format, `data-tone` = p$tone,
                           `data-precision` = p$precision, `data-source` = p$source, `data-star` = if (isTRUE(p$star)) "true" else "false"),
           head, ui_piece_body_html(p, lead), note, cont)
}

# --- the pages (scripts appendix §12.1) ------------------------------------------------------------------------------------------------------
# Continuation (scripts appendix §12.7): a page holds 33 rows of 20 px under its running head (760 - 22 - 26 - 40 px); a continuation at its top takes its
# rows first, and the slots share the rest. A piece's head (the kicker, the headline at 1.3 rows a line, the standfirst, the intro, the
# author line), its chart (7.5 rows) and its table take their rows; its text runs in two columns, counted at the layout's characters a line.
# The text is a list of units: the body's paragraphs, or an interview's questions and answers, or the voices' quotations. What runs past the
# slot is cut at a unit, or within a paragraph at a word, keeping a row for the line "Continued on page n", and continued at the next
# page's top under the piece's headline in small type, every cut piece in the slots' order; a continuation takes at most the rows the
# page's own slots leave (each its head, two rows and the gap) and runs on to the next page past them, one with no room left goes on
# whole, and the line "Continued on page n" names the page where it lands; on page 4 the rest is cut at its last complete sentence.
# The lead that runs past page 1 (paper_front_fit) is continued at page 2's top in the same way.
PAPER_PAGE_ROWS <- 33L
# The page's fit: the rows a piece's head takes.
paper_piece_rows <- function(p, g) {
  e <- p$elements
  0.8 + paper_lines(e$headline, g$chars$headline) * 1.3 + (if (!is.null(e$standfirst)) paper_lines(e$standfirst, g$chars$standfirst) else 0) + 0.6 +
    (if (!is.null(p$chart_data) && length(p$chart_data$series) && p$format %in% c("F-LEAD", "F-CHART")) 7.5 else 0) +
    (if (!is.null(e$table)) length(e$table) + 1.5 else 0) + (if (!is.null(e$intro)) paper_lines(e$intro, g$chars$standfirst) else 0) + (if (!is.null(e$author)) 1 else 0)
}
# A piece's text as units: list(kind, text), kind "p" (a paragraph), "q", "a" (an interview's question and answer) or "v" (a quotation with its role).
paper_units <- function(e) {
  if (!is.null(e$qa)) return(unlist(lapply(e$qa, function(x) list(list(kind = "q", text = x$question), list(kind = "a", text = x$answer))), recursive = FALSE))
  if (!is.null(e$quotes)) return(lapply(e$quotes, function(x) list(kind = "v", text = paste0("\u201c", x$text, "\u201d \u2014 ", x$role))))
  lapply(as.character(unlist(e$body)), function(t) list(kind = "p", text = t))
}
# The page's fit: the rows units take over two columns.
paper_units_rows <- function(units, g) ceiling(sum(vapply(units, function(u) paper_lines(u$text, g$chars$body) + 0.3, 0)) / 2)
# The units that fit `rows` rows over two columns, and the rest; a paragraph cut at a word where its units allow it.
paper_cut_units <- function(units, rows, g) {
  left <- 2 * rows; first <- list()
  for (i in seq_along(units)) {
    u <- units[[i]]; l <- paper_lines(u$text, g$chars$body) + 0.3
    if (l <= left) { first[[length(first) + 1]] <- u; left <- left - l; next }
    if (u$kind == "p" && left >= 2) { ct <- paper_cut(u$text, floor(left), g$chars$body)
      if (length(ct$first)) { first[[length(first) + 1]] <- list(kind = "p", text = ct$first); units[[i]]$text <- paste(ct$rest, collapse = " ") } }
    return(list(first = first, rest = units[i:length(units)]))
  }
  list(first = first, rest = list())
}
# Units drawn as paragraphs, questions and answers, quotations.
paper_units_html <- function(units) paste(vapply(units, function(u) switch(u$kind,
  q = game_tag("p", list(class = "paper-q"), game_tag("strong", list(), game_esc(paste0(ui_s("paper.qa_q"), " "))), game_esc(u$text)),
  a = game_tag("p", list(class = "paper-a"), game_esc(u$text)),
  v = game_tag("p", list(class = "paper-quote"), game_esc(u$text)),
  game_tag("p", list(), game_esc(u$text))), ""), collapse = "")
# Paragraphs cut so that the first part takes at most `lines` lines of `chars` characters, at a word: list(first, rest).
paper_cut <- function(paras, lines, chars) {
  first <- character(0); left <- lines
  for (i in seq_along(paras)) {
    l <- paper_lines(paras[i], chars)
    if (l <= left) { first <- c(first, paras[i]); left <- left - l; next }
    if (left > 0) { words <- strsplit(paras[i], " ", fixed = TRUE)[[1]]; take <- 0L; budget <- left * chars
      while (take < length(words) && nchar(paste(words[seq_len(take + 1L)], collapse = " ")) <= budget) take <- take + 1L
      if (take > 0) { first <- c(first, paste(words[seq_len(take)], collapse = " ")); paras[i] <- paste(words[-seq_len(take)], collapse = " ") } }
    return(list(first = first, rest = paras[i:length(paras)]))
  }
  list(first = first, rest = character(0))
}
# A text cut after its last complete sentence (scripts appendix §12.7, page 4): the sentences kept up to `max_chars` characters, the first always.
paper_last_sentences <- function(text, max_chars) {
  sentences <- trimws(strsplit(text, "(?<=[.!?])[[:space:]]+", perl = TRUE)[[1]]); sentences <- sentences[nzchar(sentences)]
  if (!length(sentences)) return(text)
  if (!grepl("[.!?]$", sentences[length(sentences)])) sentences <- sentences[-length(sentences)]   # a sentence cut at a word: dropped
  if (!length(sentences)) return(text)
  kept <- sentences[1]; n <- nchar(kept)
  for (x in sentences[-1]) { if (n + nchar(x) > max_chars) break; kept <- c(kept, x); n <- n + nchar(x) }
  paste(kept, collapse = " ")
}
# A piece within `rows`: the piece with its units cut (its body, interview or voices replaced by what fits, in whole rows, a row kept
# for the line "Continued on page n") and the rest.
paper_fit_slot <- function(p, g, rows) {
  units <- paper_units(p$elements); if (!length(units)) return(list(piece = p, rest = list()))
  left <- max(2, rows - paper_piece_rows(p, g))
  if (paper_units_rows(units, g) <= left) return(list(piece = p, rest = list()))
  ct <- paper_cut_units(units, max(1, floor(left - 1)), g)
  p$units <- ct$first
  list(piece = p, rest = ct$rest)
}
# A page with its running head and number.
ui_paper_page_html <- function(number, iss, body, cls = NULL) {
  game_tag("article", list(class = paste(c("paper-page", if (number %% 2L == 1L) "is-left" else "is-right", cls), collapse = " "), `data-page` = number),
           if (number > 1) game_tag("header", list(class = "paper-running"), game_tag("span", list(class = "paper-running-name"), game_esc(ui_s("paper.running", name = ui_s("paper.name"), dateline = iss$masthead$dateline))),
                                    game_tag("span", list(class = "paper-running-page"), game_esc(ui_s("paper.page", page = number)))),
           body)
}
# Page 1: the masthead (the name, the quarter and the year), the index beside the lead.
ui_paper_index_html <- function(iss) {
  lines <- vapply(seq_len(nrow(iss$index)), function(i) { r <- iss$index[i, ]
    game_tag("a", list(href = "#", class = paste(c("paper-index-line", if (r$slot %in% iss$selection) "is-signal"), collapse = " "), `data-paper-goto` = r$page, `data-slot` = r$slot),
             game_tag("span", list(class = "paper-index-col"), game_esc(r$section)),
             game_tag("span", list(class = "paper-index-head"), game_esc(r$headline)),
             game_tag("span", list(class = "paper-index-leader", `aria-hidden` = "true"), ""),
             game_tag("span", list(class = "paper-index-page"), game_esc(if (r$page == 1) ui_s("paper.front_page") else ui_s("paper.index_page", page = r$page)))) }, "")
  game_tag("nav", list(class = "paper-index", `aria-label` = ui_s("paper.index_title")), game_tag("h3", list(class = "paper-index-title"), game_esc(ui_s("paper.index_title"))), paste(lines, collapse = ""))
}
# Page 1 (scripts appendix §12.1, F-LEAD): the masthead; under it the index (its lines one line each) beside the lead's head (kicker, headline,
# standfirst); then the lead's body across the page in two columns, its chart at the top of the right column (the F-LEAD budget
# with its chart and its strip needs the page's full width), and the strip of three figures.
# The lead's paragraphs split over two columns, the chart's room counted in the right one.
paper_split_columns <- function(paras, chart_chars, chars = 42L) {
  total <- sum(nchar(paras)); target <- (total + chart_chars) / 2; left <- character(0); used <- 0
  for (i in seq_along(paras)) {
    n <- nchar(paras[i])
    if (used + n <= target) { left <- c(left, paras[i]); used <- used + n; next }
    words <- strsplit(paras[i], " ", fixed = TRUE)[[1]]; take <- 0L
    while (take < length(words) && used + nchar(paste(words[seq_len(take + 1L)], collapse = " ")) <= target) take <- take + 1L
    if (take > 0) left <- c(left, paste(words[seq_len(take)], collapse = " "))
    rest <- c(if (take < length(words)) paste(words[-seq_len(take)], collapse = " "), if (i < length(paras)) paras[(i + 1):length(paras)])
    return(list(left = left, right = rest, cut = take > 0 && take < length(words)))
  }
  list(left = left, right = character(0), cut = FALSE)
}
# Scripts appendix §12.7: the lead within page 1. The body's rows under the masthead, the index and the lead's head, less the strip of
# figures and the template's note; in two columns, the chart and, when the body runs past, the line "Continued on page n" counted in the
# right one (under balanced columns without a chart, a row of their own; ui_params$paper$lead). What runs past is cut at a word and
# continued on page 2: list(paras, rest).
paper_front_fit <- function(iss) {
  L <- iss$pieces$L; e <- L$elements; P <- ui_params$paper$lead; G <- ui_params$paper$grid
  paras <- as.character(unlist(e$body)); chart <- !is.null(L$chart_data) && length(L$chart_data$series)
  head <- P$head + P$headline_line * paper_lines(e$headline, P$chars$headline) + P$standfirst_line * paper_lines(e$standfirst, P$chars$standfirst)
  strip <- if (length(L$figures)) P$strip + P$strip_line * max(1, ceiling(sum(nchar(vapply(L$figures, function(x) x$text, "")) + 3) / P$chars$strip)) else 0
  room <- G$height - G$pad_bottom - P$body_top - max(0, head - P$index) - P$frame - strip - (if (identical(L$source, "template")) P$note else 0)
  R <- floor(room / G$row)
  fits <- function(p, foot) if (chart) { sp <- paper_split_columns(p, 8L * 42L); max(paper_lines(sp$left, P$chars$body), paper_lines(sp$right, P$chars$body) + P$chart / G$row + foot) <= R }
                            else ceiling(paper_lines(p, P$chars$body) / 2) + 1 + foot <= R   # balanced columns: a row more
  if (fits(paras, 0)) return(list(paras = paras, rest = list()))
  lines <- 2 * R - (if (chart) ceiling(P$chart / G$row) + 1 else 4)
  repeat { ct <- paper_cut(paras, lines, P$chars$body); if (fits(ct$first, 1) || lines <= 1) break; lines <- lines - 1 }
  list(paras = ct$first, rest = lapply(ct$rest[nzchar(ct$rest)], function(t) list(kind = "p", text = t)))
}
# Page 1, its lead's body as page 1 holds it (`paras`) with its line "Continued on page n" (`cont`).
ui_paper_front_html <- function(iss, paras = as.character(unlist(iss$pieces$L$elements$body)), cont = NULL) {
  L <- iss$pieces$L; e <- L$elements
  head <- game_tag("section", list(class = paper_piece_classes(L, iss, "paper-lead"), `data-slot` = "L", `data-type` = L$type, `data-format` = L$format, `data-tone` = L$tone,
                                   `data-precision` = L$precision, `data-source` = L$source, `data-star` = "true"),
                   game_tag("p", list(class = "paper-kicker"), game_esc(L$kicker %||% L$section)),
                   game_tag("h2", list(class = "paper-headline", id = "paper-headline"), game_esc(e$headline %||% "")),
                   game_tag("span", list(class = "paper-margin-mark"), game_tag("span", list(class = "sr-only"), game_esc(ui_s("paper.mark_signal")))),
                   if (!is.null(e$standfirst) && nzchar(e$standfirst)) game_tag("p", list(class = "paper-standfirst"), game_esc(e$standfirst)))
  chart <-if (!is.null(L$chart_data) && length(L$chart_data$series)) game_tag("figure", list(class = "paper-art-chart"), game_tag("span", list(class = "paper-tab", `aria-hidden` = "true"), ""),
                                                                               game_tag("figcaption", list(class = "paper-chart-title"), game_esc(L$chart_data$caption)), ui_paper_chart_svg(L$chart_data))
  body <- if (is.null(chart)) paste0(game_tag("div", list(class = "paper-body-cols"), paper_paras_html(paras)), cont) else {
    sp <- paper_split_columns(paras, 8L * 42L)
    game_tag("div", list(class = "paper-lead-split"),
             game_tag("div", list(class = "paper-lead-col"), paper_paras_html(sp$left)),
             game_tag("div", list(class = paste("paper-lead-col", if (isTRUE(sp$cut)) "is-cut")), chart, paper_paras_html(sp$right), cont))
  }
  strip <- if (!is.null(L$figures) && length(L$figures)) game_tag("div", list(class = "paper-figures-strip"), game_tag("span", list(class = "paper-figures-head"), game_esc(ui_s("paper.figures_head"))),
    paste(vapply(L$figures, function(x) game_tag("span", list(class = "paper-figure"), game_esc(game_upper_first(x$text))), ""), collapse = ""))
  note <- if (identical(L$source, "template")) game_tag("p", list(class = "paper-template-note"), game_esc(ui_s("paper.template_note")))
  ui_paper_page_html(1L, iss, paste0(
    game_tag("header", list(class = "paper-mast-front"), game_tag("div", list(class = "paper-name paper-name-big"), game_esc(ui_s("paper.name"))),
             game_tag("div", list(class = "paper-dateline"), game_esc(paste0(ui_paper_dateline(iss), " \u00b7 ", ui_s("paper.page", page = 1))))),
    game_tag("div", list(class = "paper-front-top"), ui_paper_index_html(iss), head),
    game_tag("section", list(class = paper_piece_classes(L, iss, "paper-lead-body"), `data-slot` = "L"), body, strip, note)), "paper-front")
}
# Scripts appendix §12.1: the two fixed boxes at the foot of page 4, drawn from issue_view's boxes and never written by a model,
# box W (the bank's word) in Topics 4, 5 and 8 and box G (government and politics) in Topics 6, 7 and 8; with their height in rows
# (side by side, or one across the page), so that S5 fits the room they leave.
ui_paper_boxes <- function(iss) {
  W <- iss$boxes$W; G <- iss$boxes$G
  if (is.null(W) && is.null(G)) return(list(html = "", rows = 0))
  lw <- if (!is.null(W)) {
    rec <- W$record; kept <- if (!is.null(rec)) sum(rec$entry %in% "kept") else 0L; broken <- if (!is.null(rec)) sum(rec$entry %in% "broken") else 0L
    c(if (!is.null(W$path) && nrow(W$path)) ui_s("paper.box_w_path", path = paste(sprintf("Q%d %s", W$path$q, fmt_rate(W$path$rate)), collapse = " · ")) else ui_s("paper.box_w_no_path"),
      if (isTRUE(W$last$kept)) ui_s("paper.box_w_last_kept", set = fmt_rate(W$last$set), announced = fmt_rate(W$last$announced))
      else if (isFALSE(W$last$kept)) ui_s("paper.box_w_last_broken", set = fmt_rate(W$last$set), announced = fmt_rate(W$last$announced)) else ui_s("paper.box_w_last_none"),
      ui_s("paper.box_w_record", kept = kept, broken = broken), ui_s("paper.box_w_trust", trust = fmt_pct(W$trust, 0)),
      if (isTRUE(W$room$new_shock)) ui_s("paper.box_w_room", room = game_num(W$room$due, 2)))
  }
  lg <- if (!is.null(G)) { pg <- G$politics
    c(ui_s(if (isTRUE(G$purchases < 0)) "paper.box_g_below" else "paper.box_g_above", level = game_num(abs(G$purchases), 1), change = game_signed(G$change, 1)),
      if (!is.null(pg)) c(ui_s("paper.box_g_party", party = game_upper_first(pg$party)), ui_s("paper.box_g_poll", poll = fmt_pct(pg$poll, 1)),
                          if (isTRUE(pg$next_election <= 1)) ui_s("paper.box_g_vote_now") else ui_s("paper.box_g_next", n = pg$next_election),
                          if (!is.null(pg$last_vote)) ui_s("paper.box_g_last_vote", quarter = pg$last_vote$q, winner = game_upper_first(pg$last_vote$winner), share = fmt_pct(pg$last_vote$share, 1))))
  }
  one <- function(id, title, lines) if (length(lines)) game_tag("section", list(class = paste("paper-box", paste0("paper-box-", id)), `data-box` = id),
    game_tag("h3", list(class = "paper-box-title"), game_esc(title)), game_tag("ul", list(class = "paper-box-lines"), paste(vapply(lines, function(l) game_tag("li", list(), game_esc(l)), ""), collapse = "")))
  two <- !is.null(W) && !is.null(G); chars <- if (two) 46L else 96L
  rows_of <- function(lines) if (!length(lines)) 0 else 2.2 + sum(ceiling(nchar(lines) / chars))
  list(html = game_tag("div", list(class = paste("paper-boxes", if (two) "is-two")), one("W", ui_s("paper.box_w_title"), lw), one("G", ui_s("paper.box_g_title"), lg)),
       rows = max(rows_of(lw), rows_of(lg)) + 1)
}
# The four pages: page 1 with the lead (its rest continued at page 2's top), then the slots in their places, every piece that runs past
# its slot continued at the top of the next page with room for it (scripts appendix §12.7), in the slots' order; its line "Continued on page n" names
# the page where it lands; page 4 ends with the fixed boxes. What page 3 continues on page 4 takes at most the room page 4 leaves after
# its boxes, its note and S5's head with two rows; a piece page 4 has no row left for ends on page 3 at its last complete sentence.
ui_paper_pages_html <- function(iss) {
  g <- ui_params$paper$grid; pages <- list(`2` = c("S1", "S2"), `3` = c("S3", "S4"), `4` = "S5")
  carries <- list(); out <- character(0); lands <- integer(0)
  carry <- function(piece, rest, from) { lands <<- c(lands, NA_integer_); list(piece = piece, rest = rest, from = from, k = length(lands)) }
  foot <- function(k) game_tag("p", list(class = "paper-cont-foot"), game_esc(ui_s("paper.continued_on", page = sprintf("@@%d@@", k))))
  last_sentence <- function(u) { if (length(u) && u[[length(u)]]$kind == "p") u[[length(u)]]$text <- paper_last_sentences(u[[length(u)]]$text, 10000L); u }
  s5 <- iss$pieces$S5; claim4 <- 0
  room4 <- PAPER_PAGE_ROWS - ui_paper_boxes(iss)$rows - (if ("S5" %in% iss$selection) 0 else 1) - (if (is.null(s5)) 0 else paper_piece_rows(s5, g) + 2.7)
  to4 <- function(rest) { r <- min(6, floor(room4 - claim4 - 1.5)); if (r < 1) return(FALSE); claim4 <<- claim4 + 1.5 + min(r, paper_units_rows(rest, g)); TRUE }
  fr <- paper_front_fit(iss)
  if (length(fr$rest)) carries <- list(carry(iss$pieces$L, fr$rest, 1L))
  out <- ui_paper_front_html(iss, fr$paras, if (length(fr$rest)) foot(1L))
  for (pg in names(pages)) {
    n <- as.integer(pg); blocks <- character(0); used <- 0; nxt <- list(); held <- FALSE
    slots <- pages[[pg]][pages[[pg]] %in% names(iss$pieces)]
    quiet <- !any(pages[[pg]] %in% iss$selection)
    bx <- if (n == 4L) ui_paper_boxes(iss) else list(html = "", rows = 0)                     # page 4's fixed boxes take their rows first
    room <- PAPER_PAGE_ROWS - bx$rows - (if (quiet) 1 else 0) - sum(vapply(slots, function(s) paper_piece_rows(iss$pieces[[s]], g) + 2.7, 0))
    for (cy in carries) {
      rest <- cy$rest; more <- NULL; fits <- 1.5 + paper_units_rows(rest, g) <= room - used
      hold <- n < 4L && (held || (!fits && room - used < 3.5))
      if (hold && (n < 3L || to4(rest))) { held <- TRUE; nxt[[length(nxt) + 1L]] <- cy; next }   # no room left here: the next page
      if (n == 4L || hold) { ct <- paper_cut_units(rest, max(1, min(6, floor(room - used - 1.5))), g); rest <- ct$first; if (length(ct$rest)) rest <- last_sentence(rest) }
      else if (!fits) { ct <- paper_cut_units(rest, max(1, floor(room - used - 2.5)), g); rest <- ct$first
        if (n < 3L || to4(ct$rest)) { more <- carry(cy$piece, ct$rest, n); nxt[[length(nxt) + 1L]] <- more } else rest <- last_sentence(rest) }
      lands[cy$k] <- n
      used <- used + 1.5 + paper_units_rows(rest, g) + (if (!is.null(more)) 1 else 0)
      blocks <- c(blocks, game_tag("section", list(class = paper_piece_classes(cy$piece, iss, "is-continued"), `data-slot` = cy$piece$slot),
                                   game_tag("p", list(class = "paper-cont-head"), game_tag("span", list(class = "paper-cont-title"), game_esc(cy$piece$elements$headline)), game_esc(paste0(" · ", ui_s("paper.continued_from", page = cy$from)))),
                                   game_tag("div", list(class = paste("paper-body-cols", if (!is.null(cy$piece$elements$qa)) "paper-qa" else if (!is.null(cy$piece$elements$quotes)) "paper-voices")), paper_units_html(rest)),
                                   if (!is.null(more)) foot(more$k)))
    }
    left <- PAPER_PAGE_ROWS - bx$rows - used - (if (quiet) 1 else 0)
    sections <- character(0)
    for (j in seq_along(slots)) {
      slot <- slots[j]; p <- iss$pieces[[slot]]
      later <- if (j < length(slots)) sum(vapply(slots[(j + 1):length(slots)], function(s2) paper_piece_rows(iss$pieces[[s2]], g) + 4.7, 0)) else 0
      rows <- max(paper_piece_rows(p, g) + 2, left - later)
      ft <- paper_fit_slot(p, g, rows)
      left <- left - 0.7 - (if (length(ft$rest)) rows else paper_piece_rows(p, g) + paper_units_rows(paper_units(p$elements), g))
      if (length(ft$rest) && (n == 4L || (n == 3L && !to4(ft$rest)))) { ft$piece$units <- last_sentence(ft$piece$units); ft$rest <- list() }   # cut at its last complete sentence (scripts appendix §12.7)
      cont <- NULL
      if (length(ft$rest)) { cy <- carry(p, ft$rest, n); nxt[[length(nxt) + 1L]] <- cy; cont <- foot(cy$k) }
      sections <- c(sections, game_tag("div", list(class = "paper-slot-box", `data-slot` = slot), ui_piece_html(ft$piece, iss, cont = cont)))
    }
    note <- if (quiet) game_tag("p", list(class = "paper-none-note", role = "note"), game_esc(ui_s("paper.none_note")))
    out <- c(out, ui_paper_page_html(n, iss, paste0(note, paste(blocks, collapse = ""), paste(sections, collapse = ""), bx$html), "paper-slot-page"))
    carries <- nxt
  }
  html <- paste(out, collapse = "")
  for (k in seq_along(lands)) html <- sub(sprintf("@@%d@@", k), lands[k], html, fixed = TRUE)
  html
}

# --- the open paper: the bar and the spreads ---------------------------------------------------------------------
ui_paper_overlay_html <- function(iss, selection = FALSE, open = FALSE, spread = 1L) {
  n <- 4L; spreads <- 2L
  counts <- vapply(seq_len(spreads), function(k) game_tag("span", list(class = "paper-count", `data-spread` = k, hidden = if (k != spread) TRUE), game_esc(ui_s("paper.count", first = 2 * k - 1, second = min(n, 2 * k), pages = n))), "")
  bar <- game_tag("div", list(class = "paper-bar"),
    game_tag("span", list(class = "paper-name"), game_esc(ui_s("paper.name"))),
    game_tag("span", list(class = "paper-bar-dateline"), game_esc(ui_paper_dateline(iss))),
    game_tag("span", list(class = "paper-bar-gap"), ""),
    game_tag("span", list(class = "paper-counts", `aria-live` = "polite"), paste(counts, collapse = "")),
    ui_paper_switch_html(selection),
    game_tag("button", list(type = "button", class = "paper-fold", `data-paper` = "fold"), game_esc(ui_s("paper.fold"))))
  pages <- ui_paper_pages_html(iss)
  turn <- function(dir) game_tag("button", list(type = "button", class = paste("paper-turn", paste0("paper-", dir)), `data-paper` = dir, `aria-label` = ui_s(if (identical(dir, "prev")) "paper.previous" else "paper.next")), "")
  game_tag("div", list(class = paste(c("paper-overlay", if (isTRUE(selection)) "is-selection"), collapse = " "), id = "paper-overlay", role = "dialog", `aria-modal` = "true",
                       `aria-labelledby` = "paper-headline", hidden = !isTRUE(open), `data-pages` = n, `data-open-spread` = spread),
           bar, game_tag("div", list(class = "paper-stage", `data-paper` = "stage"),
                         game_tag("div", list(class = "paper-spread", `data-spread` = spread, style = sprintf("--page-w:%dpx;--page-h:%dpx", ui_params$paper$grid$width, ui_params$paper$grid$height)),
                                  turn("prev"), pages, turn("next"))),
           game_tag("p", list(class = "paper-hint"), game_esc(ui_s("paper.hint"))))
}
