# ui/runs.R — the login and the Runs screen (the accounts of
# 02_Game/ui/users.yaml in two roles, each password from the variable its account names; three
# slots per account, each run's name, when it was last played, how far it has got
# (Topic n of 8, the topics played out, Chapter E open, a term open), Continue,
# Rename, Delete, the run's toggle for the model, Replay the walk-through).

GAME_ROLES <- c("developer", "player")
# The six accounts of 02_Game/ui/users.yaml.
ui_users_load <- function(path = "02_Game/ui/users.yaml") {
  y <- yaml::read_yaml(path)$users
  users <- lapply(y, function(u) { if (!grepl("^[a-z0-9_]{1,40}$", u$id)) stop("a user's id is lower-case letters, digits and '_': ", u$id)
    if (!u$role %in% GAME_ROLES) stop("the user ", u$id, "'s role is developer or player")
    if (!is.character(u$secret) || !grepl("^MPGAME_PASSWORD_[A-Z0-9_]+_FINAL$", u$secret)) stop("the user ", u$id, "'s secret is a variable MPGAME_PASSWORD_..._FINAL")
    list(id = u$id, name = u$name, role = u$role, secret = u$secret) })
  setNames(users, vapply(users, `[[`, "", "id"))
}
# An account's password variable, as 02_Game/ui/users.yaml names it (MPGAME_PASSWORD_DEV_1_FINAL and so on).
ui_login_var <- function(u) u$secret
# An account's password from the server's secrets, trimmed.
ui_login_secret <- function(u) gsub("^[ \t\r\n]+|[ \t\r\n]+$", "", Sys.getenv(ui_login_var(u), unset = ""))
# An entry against a user's variable, compared over the whole of both strings' bytes: list(ok, reason, user).
ui_login_check <- function(users, id, entry) {
  u <- if (is.character(id) && length(id) == 1 && !is.na(id)) users[[id]] else NULL
  if (is.null(u)) return(list(ok = FALSE, reason = "unknown", user = NULL))
  pw <- ui_login_secret(u); if (!nzchar(pw)) return(list(ok = FALSE, reason = "not_set_up", user = NULL))
  if (!is.character(entry) || length(entry) != 1L || is.na(entry)) return(list(ok = FALSE, reason = "wrong", user = NULL))
  a <- as.integer(charToRaw(enc2utf8(entry))); b <- as.integer(charToRaw(pw)); n <- max(length(a), length(b))
  same <- isTRUE(length(a) == length(b) && sum(bitwXor(c(a, integer(n - length(a))), c(b, integer(n - length(b))))) == 0L)
  if (same) list(ok = TRUE, reason = "ok", user = u) else list(ok = FALSE, reason = "wrong", user = NULL)
}
# The login screen; `message` the line under the button (wrong, wait, not set up), `held` the fields held after a wrong entry.
ui_login_html <- function(users, message = NULL, held = FALSE, selected = NULL) {
  opts <- paste(vapply(users, function(u) game_tag("option", list(value = u$id, selected = if (identical(u$id, selected)) TRUE), game_esc(u$name)), ""), collapse = "")
  game_tag("section", list(class = "game-login", `aria-labelledby` = "login-title", `data-view` = "login"),
    game_tag("div", list(class = "login-card"),
      game_tag("h1", list(id = "login-title", class = "login-title", tabindex = "-1", `data-game-focus` = TRUE), game_esc(ui_s("login.title"))),
      game_p("login-lede", game_esc(ui_s("login.lede"))),
      game_tag("form", list(id = "login-form", class = "login-form", novalidate = TRUE, autocomplete = "off"),
        game_tag("label", list(`for` = "login-user", class = "login-label"), game_esc(ui_s("login.user_label"))),
        game_tag("select", list(id = "login-user", name = "user", class = "login-input", autocomplete = "off", disabled = held), opts),
        game_tag("label", list(`for` = "login-password", class = "login-label"), game_esc(ui_s("login.password_label"))),
        game_void("input", list(id = "login-password", class = "login-input", type = "password", name = "password", autocomplete = "off", spellcheck = "false", `aria-describedby` = "login-message", disabled = held)),
        game_tag("button", list(type = "submit", class = "btn-main login-submit", `data-login` = "submit", disabled = held), game_esc(ui_s("login.sign_in"))),
        game_tag("p", list(id = "login-message", class = "login-message", role = "status", `aria-live` = "polite"), game_esc(message %||% "")))))
}

# --- the Runs screen ----------------------------------------------------------------------------------------------------------------
ui_runs_slot_states <- function(runs, n = ui_params$runs$slots) {
  used <- vapply(seq_len(n), function(k) !is.null(ui_runs_of(runs, k)), TRUE)
  vapply(seq_len(n), function(k) if (used[k]) "created" else if (k == 1L || used[k - 1L]) "empty_active" else "empty_inactive", "")
}
# The run in a slot.
ui_runs_of <- function(runs, slot) { for (r in runs) if (identical(as.integer(r$slot), as.integer(slot))) return(r); NULL }
# Last played, today with the time, else the date.
ui_runs_when <- function(t, now = Sys.time()) {
  if (is.null(t) || !length(t) || is.na(t)) return(NULL)
  tz <- ui_params$time_zone; f <- function(x, fmt) format(x, fmt, tz = tz)
  if (identical(f(t, "%Y-%m-%d"), f(now, "%Y-%m-%d"))) return(ui_s("runs.when_today", time = f(t, "%H:%M")))
  months <- strsplit(ui_s("runs.months"), " ")[[1]]
  ui_s("runs.when_date", day = as.integer(f(t, "%d")), month = months[as.integer(f(t, "%m"))])
}
# How far a run has got, from the progress the UI keeps with it: topic (the next or open topic's number), topics (8), played_out, chapter_e,
# open_term, quarter, term_T.
ui_runs_progress_text <- function(p) {
  p <- p %||% list()
  if (isTRUE(p$chapter_e)) return(ui_s("runs.chapter_e"))
  k <- as.integer(p$played_out %||% 0L)
  played <- if (k == 0L) ui_s("runs.played_none") else if (k == 1L) ui_s("runs.played_one") else ui_s("runs.played_many", n = k)
  ui_s("runs.progress", topic = as.integer(p$topic %||% 1L), topics = as.integer(p$topics %||% 8L), played = played)
}
# A slot's row of buttons.
ui_runs_buttons <- function(...) game_tag("div", list(class = "run-buttons"), ...)
# A slot's button.
ui_runs_button <- function(label, action, k, class = "btn-quiet", extra = list()) game_tag("button", c(list(type = "button", class = class, `data-runs` = action, `data-slot` = k), extra), game_esc(label))
# An inline form (the name, Rename, Delete's confirm).
ui_runs_confirm <- function(k, name, text, button, action, danger = FALSE, open = FALSE)
  game_tag("div", list(class = "run-confirm", `data-confirm` = name, `data-slot` = k, hidden = !open, role = "alertdialog", `aria-label` = text),
           game_p("run-confirm-text", game_esc(text)),
           ui_runs_buttons(ui_runs_button(button, action, k, paste("btn-main", if (danger) "btn-danger")), ui_runs_button(ui_s("runs.cancel"), "confirm-cancel", k, extra = list(`data-confirm-close` = name))))
# A slot in its state.
ui_runs_slot_html <- function(k, state, run, user, key = TRUE, show = NULL) {
  label <- ui_s("runs.slot_label", n = k)
  if (state == "empty_inactive")
    return(game_tag("article", list(class = "run-slot is-empty is-inactive", `data-slot` = k, `aria-disabled` = "true", `aria-label` = label),
                    game_tag("div", list(class = "run-new"), game_tag("span", list(class = "run-plus", `aria-hidden` = "true"), "+"), game_tag("span", list(class = "run-new-label"), game_esc(ui_s("runs.create")))),
                    game_p("run-note", game_esc(ui_s("runs.inactive_note", n = k - 1L)))))
  if (state == "empty_active") {
    creating <- identical(show, "create")
    return(game_tag("article", list(class = "run-slot is-empty is-active", `data-slot` = k, `aria-label` = label),
      game_tag("button", list(type = "button", class = "run-new", `data-runs` = "new", `data-slot` = k, `aria-expanded` = if (creating) "true" else "false", `aria-controls` = sprintf("run-create-%d", k), hidden = creating),
               game_tag("span", list(class = "run-plus", `aria-hidden` = "true"), "+"), game_tag("span", list(class = "run-new-label"), game_esc(ui_s("runs.create")))),
      game_tag("form", list(id = sprintf("run-create-%d", k), class = "run-form run-create", `data-slot` = k, hidden = !creating, novalidate = TRUE),
               game_tag("label", list(`for` = sprintf("run-create-name-%d", k), class = "run-label"), game_esc(ui_s("runs.name_label"))),
               game_void("input", list(id = sprintf("run-create-name-%d", k), class = "run-input", type = "text", maxlength = ui_params$runs$name_max, value = ui_s("runs.default_name", n = k), autocomplete = "off", spellcheck = "false")),
               ui_runs_buttons(game_tag("button", list(type = "submit", class = "btn-main", `data-slot` = k), game_esc(ui_s("runs.create_button"))), ui_runs_button(ui_s("runs.cancel"), "create-cancel", k)))))
  }
  p <- run$progress %||% list(); unreadable <- isTRUE(run$unreadable)
  name <- if (is.null(run$name) || !nzchar(run$name)) ui_s("runs.default_name", n = k) else run$name
  when <- ui_runs_when(run$updated)
  setting <- game_tag("div", list(class = paste("run-settings", if (!key) "is-off")),
    game_tag("label", list(class = "run-setting"),
             game_void("input", list(type = "checkbox", class = "run-setting-box", `data-runs` = "setting", `data-key` = "llm", `data-slot` = k, checked = isTRUE(run$settings$llm) && key, disabled = !key || unreadable)),
             game_tag("span", list(class = "run-setting-text"), game_esc(ui_s("runs.setting_llm")))),
    if (!key) game_tag("span", list(class = "run-setting-note"), game_esc(ui_s("runs.no_key"))),
    if (!unreadable) game_tag("div", list(class = "run-tour"),
      ui_runs_button(ui_s("runs.tour_replay"), "tour_replay", k, extra = list(`aria-pressed` = if (isTRUE(run$settings$tour_replay)) "true" else "false")),
      if (isTRUE(run$settings$tour_replay)) game_tag("span", list(class = "run-tour-note"), game_esc(ui_s("runs.tour_armed")))))
  renaming <- identical(show, "rename")
  game_tag("article", list(class = "run-slot is-created", `data-slot` = k, `aria-labelledby` = sprintf("run-name-%d", k)),
    game_tag("h2", list(class = "run-name", id = sprintf("run-name-%d", k), hidden = renaming), game_esc(name)),
    game_tag("form", list(class = "run-form run-rename", `data-slot` = k, hidden = !renaming, novalidate = TRUE),
             game_tag("label", list(`for` = sprintf("run-rename-%d", k), class = "run-label"), game_esc(ui_s("runs.rename_label"))),
             game_void("input", list(id = sprintf("run-rename-%d", k), class = "run-input", type = "text", maxlength = ui_params$runs$name_max, value = name, autocomplete = "off", spellcheck = "false")),
             ui_runs_buttons(game_tag("button", list(type = "submit", class = "btn-main", `data-slot` = k), game_esc(ui_s("runs.rename_save"))), ui_runs_button(ui_s("runs.cancel"), "rename-cancel", k))),
    if (unreadable) game_p("run-progress", game_esc(ui_s("runs.unreadable")))
    else paste0(if (!is.null(when)) game_p("run-when", game_esc(ui_s("runs.last_played", when = when))), game_p("run-progress", game_esc(ui_runs_progress_text(p))),
                if (isTRUE(p$open_term)) game_p("run-open", game_esc(ui_s("runs.open_term", quarter = as.integer(p$quarter %||% 0L), quarters = as.integer(p$term_T %||% 0L))))),
    game_tag("div", list(class = "run-buttons run-actions"),
             ui_runs_button(ui_s("runs.continue"), "continue", k, "btn-main run-continue"),
             if (!unreadable) ui_runs_button(ui_s("runs.rename"), "rename", k, extra = list(`aria-expanded` = if (renaming) "true" else "false")),
             ui_runs_button(ui_s("runs.delete"), "delete", k, extra = list(`data-confirm-open` = "delete", `aria-expanded` = if (identical(show, "delete")) "true" else "false"))),
    ui_runs_confirm(k, "delete", ui_s("runs.delete_confirm"), ui_s("runs.delete_button"), "delete-confirm", danger = TRUE, open = identical(show, "delete")),
    setting)
}
# The whole screen. `state` connecting, ready or error; `show` an inline form or confirm open in a slot (list(slot, kind)).
ui_runs_html <- function(user, runs, key = TRUE, state = "ready", notice = NULL, show = NULL) {
  head <- game_tag("header", list(class = "runs-head"),
    game_tag("div", list(class = "runs-head-text"), game_p("game-kicker", game_esc(ui_s("runs.kicker", name = user$name))),
             game_tag("h1", list(id = "runs-title", class = "game-title", tabindex = "-1", `data-game-focus` = TRUE), game_esc(ui_s("runs.title")))),
    game_tag("nav", list(class = "runs-nav", `aria-label` = ui_s("runs.nav_label")),
             game_tag("button", list(type = "button", class = "btn-quiet", `data-runs` = "theory"), game_esc(ui_s("runs.theory"))),
             game_tag("button", list(type = "button", class = "btn-quiet", `data-runs` = "sign_out"), game_esc(ui_s("runs.sign_out")))))
  body <- switch(state,
    connecting = game_tag("p", list(class = "runs-status", role = "status", `aria-live` = "polite"), game_esc(ui_s("runs.connecting"))),
    error = game_tag("div", list(class = "runs-status is-error", role = "alert"), game_p("runs-status-text", game_esc(ui_s("runs.error"))), game_tag("button", list(type = "button", class = "btn-main", `data-runs` = "retry"), game_esc(ui_s("runs.retry")))),
    { st <- ui_runs_slot_states(runs)
      game_tag("div", list(class = "runs-slots"), paste(vapply(seq_along(st), function(k) ui_runs_slot_html(k, st[k], ui_runs_of(runs, k), user, key, if (!is.null(show) && show$slot == k) show$kind), ""), collapse = "")) })
  game_tag("section", list(class = "game-runs", `aria-labelledby` = "runs-title", `data-state` = state, `data-view` = "runs"), head, if (!is.null(notice)) game_p("game-notice", game_esc(notice)), body)
}
