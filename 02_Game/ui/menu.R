# ui/menu.R — the run's Menu drawn from menu_view (the table of contents as a
# card per chapter (variant 2), a mark per topic, the rows' statuses from the view
# (played out, in play, next, locked; no scores), the selected topic's card with
# its task and summary and the Related Theory box, the topic's map under it
# (Section 4.2.1), the debrief over the Menu from the card's link, and a new
# run's first steps).
#
# `opts`: run_name; role; runs (the runs the UI holds, by topic: list(id, status, q, T, played)); window (a debrief view over the
# Menu); llm; map (ui_map_html's options).

ui_menu_status_text <- function(t) switch(t$status, played_out = if (t$played > 1) ui_s("menu.played_times", n = t$played) else ui_s("menu.status_played_out"),
                                          in_play = ui_s("menu.status_in_play"), `next` = ui_s("menu.status_next"), locked = ui_s("menu.status_locked"), t$status)
# A topic's row in the table of contents, with its status.
ui_menu_row_html <- function(t, selected, role) {
  num <- sub("^T", "", t$id)
  inner <- paste0(game_tag("span", list(class = "game-row-num"), game_esc(num)), game_tag("span", list(class = "game-row-title"), game_esc(t$name)),
                  game_tag("span", list(class = "game-row-status"), game_esc(ui_menu_status_text(t))))
  current <- identical(t$id, selected)
  if (t$status == "locked" && !identical(role, "developer")) return(game_tag("div", list(class = paste(c("game-row is-locked", if (current) "is-current"), collapse = " "), `aria-disabled` = "true"), inner))
  game_tag("button", list(type = "button", class = paste(c("game-row", if (t$status == "locked") "is-locked is-dev-open", if (current) "is-current"), collapse = " "), `data-game` = "open", `data-topic` = t$id, `aria-current` = if (current) "true"), inner)
}
# The table of contents by chapter.
ui_menu_toc_html <- function(mv, role) {
  sel <- mv$selected$id; open_ch <- mv$selected$chapter
  chs <- vapply(mv$chapters, function(ch) {
    rows <- vapply(ch$topics, function(t) game_tag("li", list(class = paste("game-topic", paste0("st-", t$status))), ui_menu_row_html(t, sel, role)), "")
    marks <- vapply(ch$topics, function(t) game_tag("span", list(class = paste0("game-chapter-mark st-", t$status)), ""), "")
    is_open <- identical(ch$id, open_ch); list_id <- paste0("game-topics-", ch$id)
    head <- game_tag("h2", list(class = "game-chapter-title"),
                     game_tag("button", list(type = "button", class = "game-chapter-row", `data-toc` = ch$id, `aria-expanded` = if (is_open) "true" else "false", `aria-controls` = list_id),
                              game_tag("span", list(class = "game-chapter-id"), game_esc(ch$id)), game_tag("span", list(class = "game-chapter-name"), game_esc(ch$name)),
                              game_tag("span", list(class = "game-chapter-marks", `aria-hidden` = "true"), paste(marks, collapse = ""))))
    game_tag("li", list(class = paste("game-chapter", if (is_open) "is-open")), head, game_tag("ol", list(class = "game-topics", id = list_id, hidden = !is_open), paste(rows, collapse = "")))
  }, "")
  game_tag("nav", list(class = paste0("game-toc toc-v", ui_params$menu$toc_variant), `aria-label` = ui_s("menu.toc_label")), game_tag("ol", list(class = "game-chapters"), paste(chs, collapse = "")))
}
# The box "Related Theory:" (Section 4.3.2; builds_on per topic).
ui_menu_related_html <- function(builds_on) {
  ids <- if (identical(builds_on, "all")) names(ui_params$theory_titles) else intersect(unlist(builds_on), names(ui_params$theory_titles))
  if (!length(ids)) return(NULL)
  items <- vapply(ids, function(id) game_tag("li", list(), game_tag("button", list(type = "button", class = "game-related-btn", `data-game` = "theory", `data-chap` = id), game_esc(ui_params$theory_titles[[id]]))), "")
  game_tag("section", list(class = "game-related", `aria-labelledby` = "game-related-head"),
           game_tag("h3", list(class = "game-related-head", id = "game-related-head"), game_esc(ui_s("menu.related_head"))),
           game_tag("ul", list(class = "game-related-list"), paste(items, collapse = "")))
}
# The selected topic's card.
ui_menu_card_html <- function(mv, o) {
  sel <- mv$selected; num <- sub("^T", "", sel$id)
  title <- game_tag("h2", list(id = "game-card-title", class = "game-card-title"), game_esc(ui_s("menu.card_title", n = num, name = sel$name)))
  kicker <- game_p("game-kicker game-card-kicker", game_esc(ui_s("menu.chapter_kicker", id = sel$chapter, name = chapters[[sel$chapter]]$name)))
  about <- game_p("game-card-about", game_esc(sel$summary))
  task <- game_tag("div", list(class = "card-task"), game_tag("h3", list(class = "card-task-head"), game_esc(ui_s("menu.task_head"))), game_p("card-task-text", game_esc(sel$task)))
  state <- switch(sel$status,
    in_play = ui_s("menu.quarter_state", played = sel$open$q %||% 0L, quarters = sel$T),
    played_out = if (!is.null(sel$open)) ui_s("menu.quarter_state", played = sel$open$q, quarters = sel$T) else paste(if ((sel$played %||% 1L) > 1) ui_s("menu.played_times", n = sel$played) else ui_s("menu.played_once"), ui_s("menu.quarters", quarters = sel$T), sep = " · "),
    ui_s("menu.quarter_state", played = 0L, quarters = sel$T))
  action <- switch(sel$action, begin = game_button(ui_s("menu.begin"), "play", "btn-main game-card-start", topic = sel$id),
                   continue = game_button(ui_s("menu.continue"), "resume", "btn-main game-card-start", topic = sel$id),
                   play_again = game_button(ui_s("menu.play_again"), "play", "btn-main game-card-start", topic = sel$id),
                   game_tag("button", list(type = "button", class = "btn-main game-card-start", disabled = TRUE), game_esc(ui_s("menu.begin"))))
  reset <- if (!is.null(sel$open)) game_tag("button", list(type = "button", class = "game-card-reset", `data-game` = "reset_topic", `data-topic` = sel$id, `data-confirm` = ui_s("menu.reset_confirm"), `aria-label` = ui_s("menu.reset_label"), title = ui_s("menu.reset_label")),
                                                                 game_tag("span", list(class = "game-card-reset-icon", `aria-hidden` = "true"), "↻"))
  order <- unlist(lapply(mv$chapters, `[[`, "topics"), recursive = FALSE); at <- match(sel$id, vapply(order, `[[`, "", "id"))
  nxt <- if (!is.na(at) && at < length(order)) order[[at + 1L]]
  move_on <- if (sel$status == "played_out" && !is.null(nxt) && nxt$status != "locked") game_tag("button", list(type = "button", class = "btn-quiet game-card-move", `data-game` = "open", `data-topic` = nxt$id), game_esc(ui_s("menu.move_on")))
  links <- if (sel$status == "played_out") game_tag("ul", list(class = "game-card-links"), game_tag("li", list(), game_link(ui_s("menu.link_report"), "report", sel$id)))
  note <- if (sel$status == "locked") game_p("game-briefing", game_esc(ui_s("menu.locked_note")))
  game_tag("article", list(class = paste("game-card", paste0("st-", sel$status)), `aria-labelledby` = "game-card-title"),
           game_tag("div", list(class = "game-card-main"), kicker, title, about, task, game_p("game-outcome game-quarter-state", game_esc(state)), note, links),
           game_tag("div", list(class = "game-card-side"), game_tag("div", list(class = "game-card-actions"), action, move_on, reset), ui_menu_related_html(sel$builds_on)))
}
# The Menu screen.
ui_menu_html <- function(mv, opts = list()) {
  o <- list(run_name = NULL, role = "player", runs = list(), window = NULL, llm = TRUE, map = list(), notice = NULL, first_steps = FALSE)
  for (nm in names(opts)) o[[nm]] <- opts[[nm]]
  head <- game_tag("header", list(class = "game-menu-head"),
                   if (!is.null(o$run_name)) game_p("game-kicker", game_esc(ui_s("menu.kicker", run = o$run_name))),
                   game_tag("h1", list(id = "game-title", class = "game-title", tabindex = "-1", `data-game-focus` = TRUE), game_esc(ui_s("menu.title"))),
                   game_tag("div", list(class = "game-menu-actions"), game_button(ui_s("menu.save_return"), "save_return", "btn-quiet game-save-return")))
  window <- if (!is.null(o$window)) game_tag("div", list(id = "game_window", class = "game-window-slot menu-window-slot"), ui_debrief_window_html(o$window, where = "menu"))
  game_tag("section", list(class = "game-menu", `aria-labelledby` = "game-title", `data-view` = "menu", `data-role` = o$role),
           if (!is.null(o$notice)) game_p("game-notice", game_esc(o$notice)), head,
           game_tag("div", list(class = "game-menu-body"), ui_menu_toc_html(mv, o$role),
                    game_tag("div", list(class = "game-menu-main"), game_tag("div", list(class = "game-card-area"), ui_menu_card_html(mv, o)), ui_map_menu_html(mv$map, o$map))),
           window, if (isTRUE(o$first_steps)) ui_first_steps_html())
}
