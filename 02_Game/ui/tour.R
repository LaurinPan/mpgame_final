# ui/tour.R — the walk-through window at a topic's start (scripts appendix §9)
# drawn from run$tour (the steps and their texts are the content's,
# content/tours; each step points at a panel; the walk-through shows only what is
# new in the topic and ends on the chat, which the page then opens), and the same
# window for the first steps on the Menu (scripts appendix §4), whose steps are
# the UI's; 02_Game/web/game.js greys the screen, frames the element and runs Previous,
# Next, Skip and the count; the steps whose element is absent are left out by
# the script.

UI_TOUR_TARGETS <- c(figures = ".fig-figures", expectations = "figure[data-chart=\"expectations\"]", rate = "#desk-decision",
                     newspaper = ".paper-folded-wrap", chat = ".chat-bar", forecast = ".charts-four")
UI_TOUR_PLACES <- c(rate = "above", chat = "above", newspaper = "above", forecast = "above")
# Scripts appendix §4: the first steps on the Menu, each step's element and the side its box takes; Unfold a Node frames one box (the Central Bank,
# in every topic) and Investigate Relations one line (the first the script draws), so that neither frames the whole map again.
UI_FIRST_STEPS <- data.frame(id = c("chapters", "preview", "theory", "start", "map", "unfold", "relations", "personalise", "reset"),
                             selector = c(".game-toc", ".game-card-main", ".game-related", ".game-card-actions", ".game-map-area", ".map-box[data-box=\"central_bank\"]",
                                          ".map-lines .map-line:first-child", ".game-map-area .map-canvas", ".map-reset"),
                             place = c("right", "below", "left", "left", "above", "right", "right", "above", "left"), stringsAsFactors = FALSE)
# The window. `steps` each with `target` (a panel of UI_TOUR_TARGETS) or its own `selector`, `title`, `place`, and `text`; `at` the step
# shown when the page is drawn (the script starts there); `points` the map's parts and arrows a step lights; `kicker` and `end` the box's
# words; `skip` a Skip button for the first steps.
ui_tour_html <- function(steps, at = 1L, kicker = ui_s("tour.kicker"), end = ui_s("tour.end"), skip = FALSE) {
  if (!length(steps)) return("")
  items <- vapply(seq_along(steps), function(i) { st <- steps[[i]]; id <- paste0("tour-", i); tid <- paste0("tour-title-", i)
    sel <- st$selector %||% unname(UI_TOUR_TARGETS[st$target %||% ""]); if (is.na(sel)) sel <- ".pc-screen"
    place <- st$place %||% unname(UI_TOUR_PLACES[st$target %||% ""]); if (is.na(place)) place <- "below"
    title <- st$title %||% (if (ui_has_string(paste0("tour.target_", st$target))) ui_s(paste0("tour.target_", st$target)) else st$target)
    game_tag("article", list(class = "tour-step", `data-step` = id, `data-target` = sel, `data-place` = place,
                             `data-points` = if (length(st$points)) paste(st$points, collapse = " "), `aria-labelledby` = tid, hidden = TRUE),
             game_p("tour-kicker", game_esc(kicker)),
             game_tag("h2", list(class = "tour-title", id = tid, tabindex = "-1"), game_esc(title)),
             game_p("tour-text", game_esc(st$text))) }, "")
  game_tag("div", list(class = "tour", id = "tour", hidden = TRUE, `data-tour-auto` = "true", `data-tour-start` = as.integer(at)),
    game_tag("div", list(class = "tour-frame", `aria-hidden` = "true"), ""),
    game_tag("section", list(class = "tour-box", role = "dialog", `aria-modal` = "true", `aria-label` = ui_s("tour.label"), `data-arrow` = "top"),
      game_tag("span", list(class = "tour-arrow", `aria-hidden` = "true"), ""),
      game_tag("div", list(class = "tour-steps"), paste(items, collapse = "")),
      game_tag("footer", list(class = "tour-foot"),
               game_tag("button", list(type = "button", class = "btn-quiet tour-prev", `data-tour` = "prev"), game_esc(ui_s("tour.previous"))),
               if (isTRUE(skip)) game_tag("button", list(type = "button", class = "btn-quiet tour-skip", `data-tour` = "skip"), game_esc(ui_s("first_steps.skip"))),
               game_tag("span", list(class = "tour-count", `data-template` = ui_s("tour.count", step = "%1", steps = "%2")), ""),
               game_tag("button", list(type = "button", class = "btn-main tour-next", `data-tour` = "next", `data-next` = ui_s("tour.next"), `data-end` = end), game_esc(ui_s("tour.next"))))))
}
# Scripts appendix §4: the first steps on the Menu, when a player enters a new run for the first time.
ui_first_steps_html <- function() {
  steps <- lapply(seq_len(nrow(UI_FIRST_STEPS)), function(i) { s <- UI_FIRST_STEPS[i, ]
    list(selector = s$selector, place = s$place, title = ui_s(paste0("first_steps.", s$id, "_title")), text = ui_s(paste0("first_steps.", s$id, "_text"))) })
  ui_tour_html(steps, at = 1L, kicker = ui_s("first_steps.kicker"), end = ui_s("first_steps.end"), skip = TRUE)
}
