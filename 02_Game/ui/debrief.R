# ui/debrief.R — the debrief as a document on the desk (Section 4.2.2) drawn
# from debrief_view (one chart of the player's rates beside the reference bank's
# with the marks and under it both losses quarter by quarter, the text on the term's loss, each mark's text, the
# chat box; every loss as its equivalent miss, no closing lesson, no colon or semicolon in the UI's own words; no score, no tabs, no turning
# points). On the desk it stands in the card's place with Continue; over the Menu
# with Close.

ui_debrief_marks_html <- function(d) {
  if (!length(d$marks)) return(game_p("debrief-point-none", game_esc(ui_s("debrief.marks_none"))))
  items <- vapply(seq_along(d$marks), function(k) { m <- d$marks[[k]]; col <- GAME_MARK_COL[(k - 1) %% length(GAME_MARK_COL) + 1]
    game_tag("li", list(class = "debrief-point", `data-mark` = k, `data-q` = m$q),
             game_tag("span", list(class = "debrief-point-num", style = sprintf("background:%s", col), `aria-hidden` = "true"), as.character(k)),
             game_tag("div", list(class = "debrief-point-body"),
                      game_tag("h4", list(class = "debrief-point-title"), game_esc(ui_s("debrief.mark_kicker", quarter = m$q, kind = ui_s(paste0("debrief.kind_", m$kind)), miss = game_num(m$equivalent, 1)))),
                      game_p("debrief-point-text", game_esc(m$text %||% "")))) }, "")
  game_tag("ol", list(class = "debrief-points"), paste(items, collapse = ""))
}
# The legend under the debrief's rates chart.
ui_debrief_legend_html <- function(d) {
  key <- function(col, width, dash = NULL) sprintf('<svg class="legend-line" viewBox="0 0 26 10" width="26" height="10" aria-hidden="true" focusable="false"><line x1="1" y1="5" x2="25" y2="5" stroke="%s" stroke-width="%s"%s></line></svg>', col, width, if (is.null(dash)) "" else sprintf(' stroke-dasharray="%s"', dash))
  game_tag("ul", list(class = "chart-legend debrief-legend"),
           game_tag("li", list(class = "legend-player"), key(GAME_COL$action, 2.5), game_esc(ui_s("debrief.legend_player"))),
           game_tag("li", list(class = "legend-best"), key(GAME_COL$ink, 1.8), game_esc(ui_s("debrief.legend_bank"))),
           if (any(d$chart$guided)) game_tag("li", list(class = "legend-guided"), '<span class="legend-swatch" aria-hidden="true"></span>', game_esc(ui_s("debrief.legend_guided"))),
           if (length(d$marks)) game_tag("li", list(class = "legend-mark"), '<span class="legend-mark-dot" aria-hidden="true">1</span>', game_esc(ui_s("debrief.legend_mark"))),
           if (any(vapply(d$marks, function(m) length(m$shaded) > 0, logical(1)))) game_tag("li", list(class = "legend-shaded"), '<span class="legend-swatch is-shaded" aria-hidden="true"></span>', game_esc(ui_s("debrief.legend_shaded"))))
}
# The window. `where` "desk" (Continue) or "menu" (Close); `waiting`
# TRUE for the one line while the reference bank still computes.
ui_debrief_window_html <- function(d, where = c("desk", "menu"), waiting = FALSE) {
  where <- match.arg(where)
  act <- if (identical(where, "desk")) game_button(ui_s("debrief.continue"), "continue", "btn-main card-continue debrief-continue")
         else game_tag("button", list(type = "button", class = "window-close", `data-game` = "window_close", `aria-label` = ui_s("window.close_label")), game_esc(ui_s("window.close")))
  if (isTRUE(waiting) || is.null(d)) body <- game_tag("div", list(class = "window-body debrief-waiting"), game_p("card-text", game_esc(ui_s("debrief.waiting"))))
  else {
    text <- game_tag("div", list(class = "debrief-text"),
      game_tag("section", list(class = "debrief-score"), game_tag("h3", list(class = "debrief-head"), game_esc(ui_s("debrief.loss_head"))),
               game_p("debrief-bank", game_esc(ui_s("debrief.loss_line", quarters = d$T, player = game_num(d$term$equivalent$player, 1), bank = game_num(d$term$equivalent$bank, 1)))),
               game_p("debrief-made", game_esc(d$loss_text)),
               if (identical(d$source, "fallback")) game_p("debrief-note", game_esc(ui_s("debrief.source_fallback")))),
      game_tag("section", list(class = "debrief-turning"), game_tag("h3", list(class = "debrief-head"), game_esc(ui_s("debrief.marks_head"))), ui_debrief_marks_html(d)))
    body <- game_tag("div", list(class = "window-body debrief-body debrief-page-1"), text, game_tag("div", list(class = "debrief-paths"), ui_debrief_legend_html(d), ui_debrief_chart_svg(d), ui_debrief_loss_svg(d)))
  }
  game_tag("div", list(class = paste("game-window debrief-window", paste0("debrief-", where)), role = "dialog", `aria-labelledby` = "debrief-title", `data-debrief` = d$topic %||% ""),
           game_tag("header", list(class = "window-head debrief-head-bar"),
                    game_tag("div", list(class = "window-kicker"), game_esc(ui_s("debrief.kicker"))),
                    game_tag("h2", list(class = "window-title", id = "debrief-title", tabindex = "-1", `data-card-focus` = TRUE), game_esc(ui_s("debrief.title", topic = sub("^T", "", d$topic %||% ""), name = d$name %||% ""))),
                    game_tag("div", list(class = "debrief-actions"), act)),
           body)
}
