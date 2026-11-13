# ui/desk.R — the quarter screen (Section 4.2.1) drawn from desk_view(run)
# (the top bar, the panel's header
# with the task line, the figures with the population and the labour
# force, the charts with the staff forecast's projected points where the topic
# shows them (Topics 5 and 8) and the expectations chart in Topics 3, 4, 5 and
# 8, the decision bar on one line with the word's slots and the guided
# quarter's flag, the chat with its briefings, each one message (Section 4.3.2),
# the debrief in the card's place, the map panel, the folded paper).
# Pure functions returning HTML strings.
#
# `opts`: run_name; role ("player", "developer"); llm (the model on); chat_open; chat_unread (the Chief Economist's messages not yet
# read, counted on the folded chat); typed list(rate, path) (the decision typed last); preview (quarter_preview's
# answer at the typed decision); confirm (the breaches' lines, the confirm step open); map_open with map_view and map (ui_map_html's
# options); paper_open, paper_spread, selection; tour_at (the walk-through's step shown, NULL for none).

ui_opts <- function(opts) {
  d <- list(run_name = NULL, role = "player", llm = TRUE, chat_open = FALSE, chat_unread = 0L, typed = NULL, preview = NULL, confirm = NULL,
            map_open = FALSE, map_view = NULL, map = list(), paper_open = FALSE, paper_spread = 1L, selection = FALSE, tour_at = NULL)
  for (nm in names(opts)) d[[nm]] <- opts[[nm]]
  d
}

# --- the top bar -------------------------------------------------------------------------------------------------------------------
ui_desk_bar <- function(dv, o) {
  tp <- dv$topic; over <- tp$status %in% c("over", "closed")
  title <- if (over) ui_s("panel.all_played", quarters = tp$T) else ui_s("panel.quarter_of", quarter = tp$q, quarters = tp$T)
  game_tag("header", list(class = "desk-bar"),
           game_tag("div", list(class = "desk-bar-text"),
                    game_p("game-kicker", game_esc(ui_s("desk.kicker", topic = sub("^T", "", tp$id), name = tp$name, chapter = tp$chapter, chapter_name = tp$chapter_name))),
                    game_tag("h1", list(id = "desk-title", class = "desk-title", tabindex = "-1", `data-game-focus` = TRUE), game_esc(title))),
           game_tag("nav", list(class = "desk-nav", `aria-label` = ui_s("desk.nav_label")),
                    if (!is.null(o$run_name)) game_tag("span", list(class = "desk-run"), game_esc(ui_s("desk.run_label", name = o$run_name))),
                    game_button(ui_s("desk.map"), "map", "btn-quiet desk-btn desk-map", extra = list(`aria-expanded` = if (isTRUE(o$map_open)) "true" else "false", `aria-controls` = "game_window")),
                    game_button(ui_s("desk.theory"), "theory", "btn-quiet desk-btn desk-theory"),
                    game_button(ui_s("desk.menu"), "menu", "btn-quiet desk-btn desk-menu")))
}

# --- the panel's header: the quarter, the closed line, the task line, the rate in force, the floor and the spell, the election,
# the rate announced for this quarter -----------------------------------------------------------------------------------------------
ui_task_line <- function(dv) {
  tp <- dv$topic
  brief <- Filter(function(m) identical(m$kind, "briefing") && identical(m$briefing_kind, "start"), dv$chat$messages)   # the topic's briefing in the start message (Section 4.3.2)
  text <- if (length(brief)) paste(vapply(brief, `[[`, "", "text"), collapse = " ") else tp$task
  line <- game_tag("button", list(type = "button", class = "task-line", id = "task-line", `data-board` = "toggle", `aria-expanded` = "false", `aria-controls` = "task-drop", `aria-label` = ui_s("task.open_label")),
                   game_tag("span", list(class = "task-marker", `aria-hidden` = "true"), ""),
                   game_tag("span", list(class = "task-quarter"), game_esc(ui_s("task.quarter", quarter = tp$q, quarters = tp$T))),
                   game_tag("span", list(class = "task-sep", `aria-hidden` = "true"), "·"),
                   game_tag("span", list(class = "task-text"), game_esc(tp$task)),
                   game_tag("span", list(class = "chev", `aria-hidden` = "true"), ""))
  drop <- game_tag("div", list(class = "task-drop", id = "task-drop", role = "region", `aria-labelledby` = "task-line", hidden = TRUE),
                   game_p("task-topic", game_esc(ui_s("task.topic", topic = sub("^T", "", tp$id), name = tp$name))),
                   game_tag("div", list(class = "task-current"),
                            game_tag("div", list(class = "task-field"), game_tag("h3", list(class = "task-field-head"), game_esc(ui_s("task.your_task"))), game_p("task-field-text task-full", game_esc(tp$task))),
                            game_tag("div", list(class = "task-field"), game_tag("h3", list(class = "task-field-head"), game_esc(ui_s("task.briefing_head"))), game_p("task-field-text", game_text_html(text)))))
  game_tag("div", list(class = "task-board", `data-board-seq` = "0"), game_tag("div", list(class = "task-box"), line, drop))
}
# The panel header (the quarter, the task line, the rate in force and the target, the floor and its spell, the announced rate, the election's clock).
ui_panel_head <- function(dv) {
  tp <- dv$topic; h <- dv$header; over <- tp$status %in% c("over", "closed")
  quarter <- if (over) ui_s("panel.all_played", quarters = tp$T) else ui_s("panel.quarter_of", quarter = tp$q, quarters = tp$T)
  closed <- if (over) ui_s("panel.closed", quarter = tp$T) else if (tp$q > 1) ui_s("panel.closed", quarter = tp$q - 1) else ui_s("panel.begins_rest")
  clock <- NULL
  if (!is.null(h$election)) {
    e <- h$election; pid <- match(e$party, consts$parties)
    text <- if (isTRUE(e$this_quarter)) ui_s("panel.election_now") else ui_s("panel.election_in", quarters = e$quarters_to)
    clock <- game_tag("span", list(class = "panel-calendar"), game_tag("span", list(class = "panel-clock"), game_esc(text)),
                      game_tag("span", list(class = paste0("party-flag party-", pid), `aria-label` = ui_s("panel.flag_label", party = game_upper_first(e$party))), game_esc(game_upper_first(e$party))))
  }
  game_tag("div", list(class = "panel-head"),
           game_tag("span", list(class = "panel-quarter"), game_esc(quarter)),
           game_tag("span", list(class = "panel-closed"), game_esc(closed)),
           ui_task_line(dv),
           game_tag("span", list(class = "panel-rate"), game_esc(ui_s("panel.rate_in_force")), " ", game_tag("strong", list(), game_esc(fmt_rate(h$rate_in_force))), " · ", game_esc(ui_s("panel.target")), " ", game_tag("strong", list(), game_esc(fmt_pct(h$target, 1)))),
           if (isTRUE(h$at_floor)) game_tag("span", list(class = "panel-floor"), game_esc(ui_s("panel.at_floor"))),
           if (!is.null(h$spell)) game_tag("span", list(class = "panel-spell"), game_esc(ui_s("panel.spell", quarters = fmt_quarters(h$spell)))),
           clock,
           if (!is.null(h$path) && isTRUE(is.finite(h$path$due))) game_tag("span", list(class = "panel-promise is-locked"), game_esc(ui_s("panel.announced_due", rate = fmt_rate(h$path$due)))))
}

# --- the figures block and the staff forecast's points on the charts (Section 4.2.1) -------------------------------------------------------------
ui_row <- function(key, label, value, change = "", sign = 0, note = NULL) { if (!grepl("[1-9]", change)) sign <- 0; paste0(
  game_tag("dt", list(class = "fig-label", `data-row` = key), game_esc(label)),
  game_tag("dd", list(class = "fig-value", `data-row` = key), game_esc(value)),
  game_tag("dd", list(class = paste("fig-change", if (isTRUE(sign < 0)) "is-down" else if (isTRUE(sign > 0)) "is-up"), `data-row` = key, `aria-label` = if (nzchar(change)) ui_s("figures.change_label", change = change)), game_esc(change)),
  if (!is.null(note)) game_tag("dd", list(class = "fig-note", `data-row` = key), game_esc(note))) }
# A figure block, its title, its rows and what follows them.
ui_block <- function(id, title, rows_html, after = NULL, extra = NULL) game_tag("section", list(class = paste("fig-block", paste0("fig-", id)), `data-panel` = id, `aria-label` = title),
  game_tag("h3", list(class = "fig-title"), game_esc(title)), if (!is.null(rows_html)) game_tag("dl", list(class = "fig-rows"), rows_html), after, extra)
# The figures of the latest completed quarter with their changes.
ui_figures_block <- function(dv) {
  f <- dv$figures; u <- f$unemployment
  notes <- c(if (isTRUE(f$output$recession)) ui_s("figures.recession") else if (isTRUE(f$output$fell)) ui_s("figures.output_fell"))
  rows <- paste0(ui_row("output", ui_s("figures.output"), fmt_bn(f$output$level), note = paste(ui_s("figures.trend"), fmt_bn(f$output$trend))),
                 ui_row("growth", ui_s("figures.growth"), fmt_pct(f$output$growth)),
                 ui_row("inflation", ui_s("figures.inflation"), fmt_pct(f$inflation$value), fmt_change(f$inflation$change), sign(f$inflation$change %||% 0)),
                 ui_row("wage_inflation", ui_s("figures.wage"), fmt_pct(f$wage_inflation$value), fmt_change(f$wage_inflation$change), sign(f$wage_inflation$change %||% 0)),
                 ui_row("unemployment", ui_s("figures.unemployment"), fmt_pct(u$rate), fmt_change(u$change), sign(u$change %||% 0),
                        note = if (isTRUE(u$quarters_above > 0)) ui_s("figures.quarters_above", quarters = fmt_quarters(u$quarters_above))),
                 ui_row("unemployed", ui_s("figures.persons"), fmt_persons(u$persons)),
                 if (!is.null(f$labour_force)) ui_row("labour_force", ui_s("figures.labour_force"), ui_s("format.million", value = game_num(f$labour_force$value / 1e6, 0))),   # the labour force and the population, the game's round figures
                 if (!is.null(f$population)) ui_row("population", ui_s("figures.population"), ui_s("format.million", value = game_num(f$population$value / 1e6, 0))))
  ui_block("figures", ui_s("figures.title"), rows, after = if (length(notes)) game_p("fig-result", game_esc(notes[1])))
}
# quarter_preview's forecast is staff_forecast's list (mean, band, spell, in_words); the view's is rows of name, mean, lo and hi
# The one shape the renderers read.
ui_forecast_view <- function(fc, at = NULL) {
  if (is.null(fc) || !is.null(fc$rows)) return(fc)
  list(rows = lapply(consts$forecast_rows, function(r) list(name = r, mean = fc$mean[[r]], lo = fc$band$lo[[r]], hi = fc$band$hi[[r]])),
       at = list(rate = at), spell = fc$spell, in_words = fc$in_words)
}
# The forecast's points for the charts, by variable, from the preview or the quarter's forecast.
ui_forecast_points <- function(dv, o) {
  fc <- ui_forecast_view(if (!is.null(o$preview)) o$preview$forecast else dv$forecast, o$typed$rate %||% o$preview_at)
  if (is.null(fc)) return(NULL)
  one <- function(nm) { r <- Filter(function(z) identical(z$name, nm), fc$rows)[[1]]; list(mean = r$mean, lo = r$lo, hi = r$hi) }
  list(inflation = one("inflation"), unemployment = one("unemployment"))   # the output chart's point needs the level
}

# --- the word's editor under the rate chart (the data for the script) -------------------------------------
ui_word_editor_data <- function(dv, o) {
  w <- dv$word; q <- dv$topic$q; H <- dv$decision$H
  h <- function(nm) sprintf("⦃%s⦄", nm); tpl <- function(x) gsub("⦃([a-z_]+)⦄", "{\\1}", x)
  strings <- lapply(list(switch = ui_s("word.switch"), add = ui_s("word.add", quarter = h("quarter")), add_label = ui_s("word.add_label", quarter = h("quarter")),
                         back = ui_s("word.back"), new = ui_s("word.new"), field_band = ui_s("word.field_band", band = h("band")), field_room = ui_s("word.field_room", room = h("room")),
                         field_label = ui_s("word.field_label", quarter = h("quarter")), field_invalid = ui_s("word.field_invalid"),
                         point_label = ui_s("word.point_label", quarter = h("quarter"), rate = h("rate")),
                         note_band = ui_s("word.note_band", rate = h("rate"), announced = h("announced"), band = h("band")),
                         note_room = ui_s("word.note_room", room = h("room"), rate = h("rate"), announced = h("announced"), band = h("band")),
                         path_none = ui_s("word.path_none"), path_through = ui_s("word.path_through", quarter = h("quarter")),
                         remove_one = ui_s("word.remove_one", quarter = h("quarter")), remove_from = ui_s("word.remove_from", quarter = h("quarter")),
                         error_every = ui_s("word.error_path_every"),
                         path_breaks_one = ui_s("word.path_breaks_one", quarter = h("quarter")), path_breaks_many = ui_s("word.path_breaks_many", quarter = h("quarter"), n = h("n")),
                         band = ui_s("word.band", rate = h("rate"), band = h("band")), band_room = ui_s("word.band_room", rate = h("rate"), room = h("room"))), tpl)
  ahead <- if (isTRUE(w$has_path) && !is.null(w$standing)) w$standing[w$standing$q > q, , drop = FALSE] else NULL
  standing <- if (!is.null(ahead) && nrow(ahead)) ahead$rate else numeric(0)
  due <- if (isTRUE(w$has_path) && isTRUE(is.finite(w$due))) w$due else NULL
  list(t = q, H = H, T = dv$topic$T, mode = if (isTRUE(dv$decision$path_required)) "every" else "path", locked = length(standing) > 0L,
       standing = I(standing), room = if (isTRUE(w$new_shock)) I(standing + w$room[seq_along(standing)]) else NULL, news = isTRUE(w$new_shock), cone = I(w$cone), floor = dv$decision$floor,
       due = due, due_room = if (!is.null(due) && isTRUE(w$new_shock)) due + w$room_due else NULL,
       draft = if (!is.null(o$typed$path)) I(o$typed$path) else NULL,
       decimals = ui_params$decimals$rate, step = ui_params$word$step, strings = strings)
}
# The path's editor under the rate chart (the switch, the fields, the news line) and its data for the script.
ui_word_editor_html <- function(dv, o) {
  w <- dv$word; every <- isTRUE(dv$decision$path_required); on <- every || isTRUE(w$has_path) || !is.null(o$typed$path)
  data <- as.character(jsonlite::toJSON(ui_word_editor_data(dv, o), auto_unbox = TRUE, null = "null", na = "null", digits = NA))
  game_tag("div", list(class = "word-editor rate-path", `data-word` = data),
    game_tag("div", list(class = "path-controls"),
      game_tag("button", list(type = "button", class = "path-switch", role = "switch", `aria-checked` = if (on) "true" else "false", `data-path` = "switch", disabled = if (every) TRUE,
                              `aria-describedby` = if (every) "path-switch-every"),
               game_tag("span", list(class = "path-switch-track", `aria-hidden` = "true"), ""), game_esc(ui_s("word.switch"))),
      if (every) game_tag("span", list(class = "path-switch-every", id = "path-switch-every"), game_esc(ui_s("word.switch_every"))),
      game_tag("button", list(type = "button", class = "btn-link path-back", `data-path` = "back", hidden = TRUE), game_esc(ui_s("word.back")))),
    game_tag("div", list(class = "path-fields", role = "group", `aria-label` = ui_s("word.fields_label")), ""),
    if (isTRUE(w$new_shock)) game_tag("p", list(class = "path-news", role = "note"), game_esc(ui_s("word.news_note"))))
}

# --- the decision bar ------------------------------------------------------------
# The breaches of a typed decision against the standing word, for the breach marks and the slots (the engine's cone and the room, as
# the script applies them while the player types; the preview call does not return the judgement).
ui_word_broken <- function(x, a, d, band) { I <- round(100 * x); A <- round(100 * a); D <- round(100 * d); abs(I - pmin(pmax(I, pmin(A, D)), pmax(A, D))) >= round(100 * band) }
# A typed decision's breaches of the standing word, quarter by quarter, with their notes.
ui_word_breaches <- function(dv, typed) {
  w <- dv$word; q <- dv$topic$q; out <- list(); if (is.null(w) || !isTRUE(w$has_path) || is.null(typed)) return(out)
  st <- w$standing; room_of <- function(h) if (h == 0) w$room_due else w$room[h]
  for (i in seq_len(nrow(st))) {
    qi <- st$q[i]; h <- qi - q; a <- st$rate[i]; b <- w$cone[max(1, h)]; d <- a + (if (isTRUE(w$new_shock)) room_of(h) else 0)
    x <- if (h == 0) typed$rate else if (!is.null(typed$path) && h <= length(typed$path)) typed$path[h] else NA
    if (!isTRUE(is.finite(x)) || abs(x - a) <= 1e-9) next
    if (ui_word_broken(x, a, d, b)) out[[length(out) + 1]] <- list(quarter = qi, note = if (abs(d - a) > 1e-9) ui_s("word.note_room", room = game_num(d, 2), rate = game_num(x, 2), announced = game_num(a, 2), band = game_num(b, 2))
                                                                                     else ui_s("word.note_band", rate = game_num(x, 2), announced = game_num(a, 2), band = game_num(b, 2)))
  }
  out
}
# A guided quarter's flag, the rate to select and, in Topic 4, the plan to announce.
ui_guided_flag <- function(g) {
  r <- ui_s("decision.guided", rate = fmt_rate(g$rate))
  if (!identical(g$action, "announce")) return(r)
  p <- g$plan
  paste(r, if (all(abs(p - g$rate) < 0.005)) ui_s("decision.guided_plan_flat", n = length(p)) else ui_s("decision.guided_plan", rates = paste(formatC(p, format = "f", digits = 2), collapse = ", ")))
}
# Whether the quarter's paper is still printed, in a topic with the newspaper (from Topic 2 on).
ui_paper_printing <- function(dv) is.null(dv$issue) && "newspaper" %in% dv$panels && !(dv$topic$status %in% c("over", "closed"))
# The decision bar on one line (the rate with its unit, a guided quarter's flag, the floor, the word's slots, the record line,
# the message, Publish, which waits disabled while the quarter's paper is printed, since the paper brings the quarter's shocks).
# A guided quarter starts at the rate in force and can be typed in; its flag turns red when Publish is pressed with another rate or plan,
# and the page then sends nothing. The fields take five characters, at most 20.00; a decision beyond the cap is refused by the backend.
# A refused decision's line. A reason the backend writes as a sentence of its own (a capital first, a full stop last), as
# the cap's, shows as it stands; a reason written as a clause follows "Refused:".
ui_refused <- function(reason) if (grepl("^[[:upper:]].*[.]$", reason)) reason else ui_s("desk.refused", reason = reason)
ui_decision_html <- function(dv, o) {
  d <- dv$decision; tp <- dv$topic; q <- tp$q; w <- dv$word; g <- d$guided; h <- dv$header
  if (tp$status %in% c("over", "closed")) return(game_tag("div", list(class = "dec-block dec-wait"), game_tag("span", list(), game_esc(ui_s("desk.term_over"))), game_button(ui_s("desk.continue"), "continue", "btn-main")))
  start <- if (!is.null(o$typed$rate)) o$typed$rate else if (!is.null(g)) h$rate_in_force else d$rate_start
  plan <- if (!is.null(g) && identical(g$action, "announce")) g$plan
  rate <- game_tag("div", list(class = "dec-rate"),
    game_tag("label", list(`for` = "desk-rate"), game_esc(ui_s("decision.rate_label", quarter = q))),
    game_void("input", list(id = "desk-rate", name = "rate", type = "text", inputmode = "decimal", maxlength = 5L, value = formatC(start, format = "f", digits = 2), `aria-describedby` = "desk-rate-help", autocomplete = "off",
                            `data-guided-rate` = if (!is.null(g)) formatC(g$rate, format = "f", digits = 2), `data-guided-plan` = if (!is.null(plan)) paste(formatC(plan, format = "f", digits = 2), collapse = " "))),
    game_tag("span", list(class = "dec-help", id = "desk-rate-help"), game_esc(ui_s("decision.rate_unit"))),
    if (!is.null(g)) game_tag("span", list(class = "dec-chip", id = "desk-chip"), game_esc(ui_guided_flag(g))))
  floor <- paste0(game_tag("button", list(type = "button", class = "btn-quiet dec-floor", `data-desk` = "floor", `data-value` = format(d$floor)), game_esc(ui_s("word.floor_button"))),
                  if (!is.null(h$spell)) game_tag("span", list(class = "dec-floor-expected"), game_esc(if (h$spell == 1) ui_s("word.floor_expected_one") else ui_s("word.floor_expected_many", n = h$spell))))
  slot <- function(id, html = NULL, breach = FALSE) game_tag("span", list(class = paste("dec-slot", if (breach) "is-breach"), `data-slot` = id, `aria-hidden` = if (is.null(html) || !nzchar(html)) "true", `aria-live` = if (!is.null(html) && id %in% c("band", "path")) "polite"), html %||% "")
  wb <- list(); breaches <- ui_word_breaches(dv, o$typed)
  if (!is.null(w)) {
    due <- if (isTRUE(w$has_path) && isTRUE(is.finite(w$due))) w$due
    wb$band <- if (is.null(due)) "" else if (isTRUE(w$new_shock) && abs(w$room_due) > 1e-9) ui_s("word.band_room", rate = game_num(due, 2), room = game_num(due + w$room_due, 2)) else ui_s("word.band", rate = game_num(due, 2), band = game_num(w$cone[1], 2))
    ahead <- if (isTRUE(w$has_path)) sum(w$standing$q > q) else 0
    n <- sum(vapply(breaches, function(b) b$quarter > q, logical(1)))
    wb$path <- if (!is.null(o$typed$path)) { last <- min(q + length(o$typed$path), tp$T); if (n == 0) ui_s("word.path_through", quarter = last) else if (n == 1) ui_s("word.path_breaks_one", quarter = last) else ui_s("word.path_breaks_many", quarter = last, n = n) }
               else if (ahead > 0) ui_s("word.path_through", quarter = min(q + ahead, tp$T)) else ui_s("word.path_none")
  }
  rate_breach <- any(vapply(breaches, function(b) b$quarter == q, logical(1)))
  message <- if (identical(tp$status, "refused")) ui_refused(tp$message) else if (!is.null(o$preview$refused)) ui_refused(o$preview$refused) else ""
  compact <- !is.null(w)
  game_tag("form", list(class = paste(c("dec-block", if (compact) "is-compact has-word", if (!is.null(g)) "is-guided"), collapse = " "), id = "desk-decision", `aria-label` = ui_s("decision.title"), novalidate = TRUE),
    game_tag("div", list(class = "dec-title"), game_esc(ui_s("decision.title"))), rate,
    game_tag("span", list(class = "dec-floor-box"), floor),
    if (!is.null(w)) paste0(slot("band", if (nzchar(wb$band)) game_esc(wb$band), rate_breach), slot("path", game_esc(wb$path))),
    if (ui_paper_printing(dv)) game_tag("button", list(type = "submit", class = "btn-main dec-publish", `data-desk` = "publish", `data-paper-wait` = "true", disabled = TRUE), game_esc(ui_s("decision.waiting_paper")))
    else game_tag("button", list(type = "submit", class = "btn-main dec-publish", `data-desk` = "publish"), game_esc(ui_s("decision.publish"))),
    game_tag("p", list(class = "dec-message", id = "desk-message", role = "status", `aria-live` = "polite"), game_esc(message)))
}

# --- the chat (Section 4.3.2) ----------------------------------------------------------------------------------------------------
# Every message shown, each briefing one message; the chat opens by itself when the Chief Economist writes (the server), and the folded
# chat shows only its name, the count of messages not yet read and the button that unfolds it.
# The messages in their quarters' order, each quarter's in the order they came.
ui_chat_messages <- function(dv) {
  msgs <- dv$chat$messages %||% list()
  if (!length(msgs)) return(list())
  msgs[order(vapply(msgs, function(m) as.numeric(m$q), 0))]
}
# The Chief Economist's messages of a run, every one but the player's questions (the count the unread number is taken from).
ui_chat_count <- function(run) sum(vapply(run$chat %||% list(), function(m) !identical(m$kind, "question"), logical(1)))
# The chat (the messages, the questions and answers, the input); `o$chat_unread` the Chief Economist's messages not yet read.
ui_chat_html <- function(dv, o) {
  msgs <- ui_chat_messages(dv)
  n_new <- if (isTRUE(o$chat_open)) 0L else as.integer(o$chat_unread %||% 0L)
  bar <- game_tag("div", list(class = "chat-bar"),
    game_tag("span", list(class = "chat-name"), game_esc(ui_s("chat.name")), if (n_new > 0) game_tag("span", list(class = "chat-badge", `aria-label` = ui_s("chat.new", n = n_new)), n_new)),
    game_tag("button", list(type = "button", class = "chat-toggle", `data-chat` = "toggle", `aria-expanded` = if (isTRUE(o$chat_open)) "true" else "false", `aria-controls` = "chat-pane", `aria-label` = ui_s("chat.toggle_label")),
             game_tag("span", list(class = "chev", `aria-hidden` = "true"), "")))
  ce <- which(vapply(msgs, function(m) !identical(m$kind, "question"), logical(1))); fresh <- if (n_new > 0) utils::tail(ce, n_new) else integer(0)
  items <- vapply(seq_along(msgs), function(k) {
    m <- msgs[[k]]; kind <- m$kind %||% "note"
    who <- if (identical(kind, "question")) ui_s("chat.when_you", quarter = m$q) else ui_s("chat.when_economist", quarter = m$q)
    tag <- if (identical(kind, "briefing")) game_tag("span", list(class = "chat-tag"), game_esc(ui_s(paste0("chat.kind_", m$briefing_kind))))   # an answer shows no step tag, only its text
    game_tag("li", list(class = paste("chat-msg", paste0("kind-", kind), if (k %in% fresh) "is-new"), `data-q` = m$q),
             game_tag("div", list(class = "chat-when"), game_esc(who), tag), game_tag("div", list(class = "chat-text"), game_text_html(m$text)))
  }, "")
  over <- dv$topic$status %in% c("over", "closed"); on <- isTRUE(o$llm) && !over
  input <- game_tag("form", list(class = paste("chat-input", if (!on) "is-off"), id = "chat-form", `aria-label` = ui_s("chat.form_label"), novalidate = TRUE),
                    game_tag("label", list(`for` = "chat-question", class = "sr-only"), game_esc(ui_s("chat.placeholder"))),
                    game_tag("textarea", list(id = "chat-question", name = "question", rows = "2", maxlength = ui_params$llm$question_max, placeholder = ui_s("chat.placeholder"), disabled = !on, `aria-describedby` = "chat-note", `data-thinking` = ui_s("chat.thinking")), ""),
                    game_tag("button", list(type = "submit", class = "btn-main chat-ask", `data-chat` = "ask", disabled = !on), game_esc(ui_s("chat.ask"))),
                    game_tag("p", list(class = "chat-note", id = "chat-note"), game_esc(if (over) ui_s("chat.over") else if (on) ui_s("chat.logged") else ui_s("chat.off"))))
  pane <- game_tag("aside", list(class = "chat-pane", id = "chat-pane", `aria-label` = ui_s("chat.pane_label"), hidden = !isTRUE(o$chat_open)),
    game_tag("header", list(class = "chat-head"), game_tag("h2", list(class = "chat-title"), game_esc(ui_s("chat.name"))),
             game_tag("button", list(type = "button", class = "chat-close", `data-chat` = "close"), game_esc(ui_s("chat.close")))),
    game_tag("ol", list(class = "chat-list", `aria-live` = "polite"), paste(items, collapse = "")), input)
  list(bar = bar, pane = pane)
}

# --- the whole desk -------------------------------------------------------------------------------------------------------------------
ui_desk_html <- function(dv, opts = list()) {
  o <- ui_opts(opts); tp <- dv$topic; panels <- dv$panels; over <- tp$status %in% c("over", "closed"); q <- tp$q
  decision_open <- !over
  fc_points <- if ("forecast" %in% panels && decision_open) ui_forecast_points(dv, o)
  word_layer <- if (!is.null(dv$word) && decision_open) ui_word_layer(dv$word, q, dv$decision$H)
  word_editor <- if (!is.null(dv$word) && decision_open) ui_word_editor_html(dv, o)
  blocks <- ui_figures_block(dv)                                                          # the figures block alone (Section 4.2.1)
  charts_main <- game_tag("div", list(class = "charts-main"), ui_desk_chart("rate", dv, list(forecast = fc_points, word_layer = word_layer, word_editor = word_editor)))
  charts_four <- game_tag("div", list(class = "charts-four"), paste(vapply(c("inflation", "output", "wage_inflation", "unemployment"), function(id) ui_desk_chart(id, dv, list(forecast = fc_points)), ""), collapse = ""))
  charts_small <- if ("expectations" %in% panels) game_tag("div", list(class = "charts-small"), ui_desk_chart("expectations", dv))   # Topics 3, 4, 5 and 8
  panel <- game_tag("div", list(class = "panel", id = "desk-panel", tabindex = "0", `aria-label` = ui_s("panel.label"), `data-forecast` = if (!is.null(fc_points)) "true"),
                    game_tag("div", list(class = "fig-blocks desk-blocks"), blocks), charts_main, charts_four, charts_small)
  chat <- ui_chat_html(dv, o)
  bottom <- game_tag("div", list(class = "desk-bottom"), ui_decision_html(dv, o), chat$bar)
  debrief <- if (!is.null(dv$debrief)) game_tag("div", list(class = "interim-slot debrief-slot"), ui_debrief_window_html(dv$debrief, where = "desk"))
             else if (identical(tp$status, "closed")) game_tag("div", list(class = "interim-slot debrief-slot"), ui_debrief_window_html(list(topic = tp$id, name = tp$name), where = "desk", waiting = TRUE))
  window <- game_tag("div", list(id = "game_window", class = "game-window-slot"), if (isTRUE(o$map_open) && !is.null(o$map_view)) ui_map_panel_html(o$map_view, o$map))
  screen <- game_tag("div", list(class = paste("pc-screen", if (!is.null(debrief)) "has-card")), ui_panel_head(dv), panel, bottom, chat$pane, debrief, window)
  issue <- dv$issue
  strip <- game_tag("div", list(class = "desk-strip"), if (!is.null(issue)) ui_paper_folded_html(issue, o$selection) else if (ui_paper_printing(dv)) ui_paper_printing_html(q))
  game_tag("section", list(class = "game-desk", `aria-labelledby` = "desk-title", `data-stage` = if (over) "over" else "term", `data-view` = paste0("desk:", tp$id)),
           ui_desk_bar(dv, o), game_tag("div", list(class = "desk-room"), game_tag("div", list(class = "pc"), screen), strip),
           if (!is.null(issue)) ui_paper_overlay_html(issue, o$selection, open = isTRUE(o$paper_open), spread = o$paper_spread),
           if (!is.null(dv$tour) && !is.null(o$tour_at)) ui_tour_html(dv$tour, at = o$tour_at))
}
