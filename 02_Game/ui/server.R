# ui/server.R — the app's page and server: every action of the browser mapped to one of
# the five calls or the chat, every screen drawn again as one HTML string by the renderers of 02_Game/ui/. The state: the user signed
# in, the open run (one slot of the store with its terms), the screen, the theory when open, and the desk's passing state (the chat
# open, the map panel, the walk-through, the chat read). Definitions only: app.R runs shinyApp(ui_app_ui(), ui_server).

# the fonts link of the page's head
UI_FONTS <- "https://fonts.googleapis.com/css2?family=Public+Sans:wght@400;500;600&family=Source+Serif+4:opsz,wght@8..60,400;8..60,600&display=swap"

# The app's page: the head with the fonts, the stylesheets and the scripts of 02_Game/web/, the game's screen and the theory's.
ui_app_ui <- function() {
  head <- paste0(game_void("meta", list(name = "viewport", content = "width=device-width, initial-scale=1")),
                 game_void("link", list(rel = "stylesheet", href = UI_FONTS)),
                 paste(vapply(c("base.css", "game.css", "theory.css"), function(f) game_void("link", list(rel = "stylesheet", href = paste0("web/", f))), ""), collapse = ""),
                 paste(vapply(c("game.js", "theory.js"), function(f) game_tag("script", list(src = paste0("web/", f)), ""), ""), collapse = ""))
  htmltools::tagList(htmltools::tags$head(htmltools::tags$title(ui_s("app.title")), htmltools::HTML(head)),
                     htmltools::div(id = "game", class = "game", shiny::uiOutput("game_screen")),
                     htmltools::div(id = "theory", class = "theory-pane", shiny::uiOutput("theory_screen")),
                     htmltools::tags$script(htmltools::HTML("document.body.classList.add('is-game');")))
}

# The topics in their order.
ui_topic_order <- function() unname(unlist(lapply(chapters, `[[`, "topics")))

# A term filed once its debrief is read, with what menu_view and debrief_view read and nothing else.
ui_term_file <- function(run) list(topic = run$topic, status = "over", name = run$script$name, T = run$T, record = run$record,
                                   debrief = run$debrief, filed = TRUE, ended = Sys.time())

# Whether a term is the backend's run object (open, or over and not yet filed).
ui_term_live <- function(x) is.null(x$filed)

# A run's progress on the Runs screen (the next or open topic, the topics played out, the open term's quarters played).
ui_run_progress <- function(rec) {
  terms <- rec$game$terms; ord <- ui_topic_order()
  played <- unique(vapply(Filter(function(x) identical(x$status, "over"), terms), `[[`, "", "topic"))
  open <- Filter(function(x) ui_term_live(x) && !identical(x$status, "over"), terms)
  nxt <- if (length(open)) open[[1]]$topic else { left <- setdiff(ord, played); if (length(left)) left[1] else ord[length(ord)] }
  o <- menu_view(terms, nxt, "developer")$selected$open
  list(topic = match(nxt, ord), topics = length(ord), played_out = length(played),
       chapter_e = !length(open) && identical(nxt, ord[length(ord)]) && length(played) == length(ord) - 1L,
       open_term = !is.null(o), quarter = o$q, term_T = o$T)
}

# A typed rate as a number, a comma read as the decimal point, a percent sign and spaces ignored; NA when it is none.
ui_parse_rate <- function(x) {
  if (is.null(x) || !length(x)) return(NA_real_)
  suppressWarnings(as.numeric(sub(",", ".", gsub("[%[:space:]]", "", as.character(x[[1]])), fixed = TRUE)))
}

# A typed path as numbers (NULL when none is sent).
ui_parse_path <- function(p) if (is.null(p) || !length(p)) NULL else vapply(p, ui_parse_rate, 0)
# The decision on the page as the chat's call takes it, the same list the forecast's request gives quarter_preview;
# a page that sends none gives NULL (the decision the desk starts from), and one whose rate or path does not parse a rate that is no
# number, which the checks refuse, so that the call carries no forecast.
ui_typed <- function(rate, path) {
  if (is.null(rate)) return(NULL)
  r <- ui_parse_rate(rate); p <- ui_parse_path(path)
  if (is.na(r) || (!is.null(p) && anyNA(p))) list(rate = NA_real_, path = NULL) else list(rate = r, path = p)
}

# Whether the next quarter's paper and the reference bank run in a background worker (the flag
# ui_params$bank$background, mirai's daemons set by app.R).
ui_bank_background <- function() isTRUE(ui_params$bank$background) && requireNamespace("mirai", quietly = TRUE) && isTRUE(mirai::daemons_set())

# Whether the open quarter's paper is still to be written (its slot NULL until paper_write fills it), in a topic with the
# newspaper (from Topic 2 on).
ui_paper_due <- function(run) { q <- as.integer(run$t) + 1L; identical(run$status, "open") && "newspaper" %in% run$script$panels && (length(run$issues) < q || is.null(run$issues[[q]])) }

# A paper paper_write wrote, `p` = list(q, issue, masks, calls), put into its quarter's slots while they are empty, the
# calls' records appended (the interface: the two slots from the run it returns, the records beyond the count before the call).
ui_paper_merge <- function(run, p) {
  if (!ui_paper_due(run) || !identical(as.integer(run$t) + 1L, as.integer(p$q))) return(run)
  run$issues[p$q] <- list(p$issue); run$masks[p$q] <- list(p$masks); run$calls <- c(run$calls, p$calls)
  run
}

# What paper_write added to a run sent with `n` calls, as ui_paper_merge takes it.
ui_paper_part <- function(r, q, n) list(q = q, issue = r$issues[[q]], masks = r$masks[[q]], calls = r$calls[seq_len(length(r$calls) - n) + n])

# Without the worker, what a term lacks runs inside the close: every quarter played and not yet advanced (a run
# saved while a worker ran), the open quarter's paper not yet written, then the term's end once its last quarter is closed.
ui_bank_inline <- function(run) {
  n <- length(run$bank$decisions)
  if (n < run$t) for (q in seq.int(n + 1L, run$t)) run <- bank_run(run, q)
  if (ui_paper_due(run)) run <- paper_write(run, as.integer(run$t) + 1L)
  if (identical(run$status, "closed")) run <- topic_end(run)
  run
}

# A new run's record in a slot.
ui_run_new <- function(slot, name) {
  now <- Sys.time()
  list(slot = as.integer(slot), uid = paste0(format(now, "%Y%m%d%H%M%S"), "-", paste(sample(c(letters, 0:9), 6, TRUE), collapse = "")),
       name = name, created = now, updated = now, settings = list(llm = llm_available(), tour_replay = FALSE, tour_menu = TRUE), ui = list(), game = list(terms = list()))
}

# The server.
ui_server <- function(input, output, session) {
  users <- ui_users_load("02_Game/ui/users.yaml")
  rv <- shiny::reactiveValues(screen = "login", user = NULL, login = list(), runs = list(), runs_state = "connecting", notice = NULL,
                              rec = NULL, selected = "T1", topic = NULL, window = NULL, theory = NULL, map_open = FALSE, menu_notice = NULL, stamp = 0L)
  S <- new.env(parent = emptyenv())       # the passing state that redraws nothing
  S$selection <- FALSE; S$map <- NULL; S$chat <- NULL; S$chat_open <- FALSE; S$tour_at <- NULL; S$tour <- NULL; S$first_steps <- FALSE
  S$banks <- list(); S$bank_job <- NULL                     # the reference bank's latest run per topic, the job in the worker
  S$papers <- list()                                        # the paper the worker wrote per topic, until the run takes it in
  login_until <- 0

  # --- the run, its terms and the store ------------------------------------------------------------------------------------------
  live_index <- function(rec, topic) {
    i <- which(vapply(rec$game$terms, function(x) identical(x$topic, topic) && ui_term_live(x), logical(1)))
    if (length(i)) i[1] else NA_integer_
  }
  open_run <- function() { rec <- rv$rec; i <- if (is.null(rec) || is.null(rv$topic)) NA else live_index(rec, rv$topic); if (is.na(i)) NULL else with_paper(rec$game$terms[[i]]) }
  set_run <- function(run) {
    rec <- shiny::isolate(rv$rec); i <- live_index(rec, run$topic)
    if (is.na(i)) rec$game$terms[[length(rec$game$terms) + 1L]] <- run else rec$game$terms[[i]] <- run
    rv$rec <- rec
  }
  save_run <- function() {
    rec <- shiny::isolate(rv$rec); u <- shiny::isolate(rv$user)
    if (is.null(rec) || is.null(u)) return(invisible(FALSE))
    rec$ui <- list(selection = isTRUE(S$selection), map = S$map, chat = S$chat); rec <- with_banks(with_papers(rec))
    ok <- tryCatch({ ui_store_put(u$id, rec); TRUE }, error = function(e) { message("MPGAME the run could not be saved: ", ui_store_redact(conditionMessage(e))); FALSE })
    invisible(ok)
  }
  log_calls <- function(before, run) {
    n <- length(run$calls); u <- shiny::isolate(rv$user); rec <- shiny::isolate(rv$rec)
    if (n > before && !is.null(u)) tryCatch(ui_store_log(u$id, rec$uid, run$topic, run$calls[(before + 1L):n]),
                                            error = function(e) message("MPGAME the log could not be written: ", ui_store_redact(conditionMessage(e))))
  }
  runs_load <- function() {
    u <- shiny::isolate(rv$user)
    r <- tryCatch(ui_store_list(u$id), error = function(e) { message("MPGAME the runs could not be listed: ", ui_store_redact(conditionMessage(e))); NULL })
    if (is.null(r)) rv$runs_state <- "error" else { rv$runs <- r; rv$runs_state <- "ready" }
  }
  runs_rows <- function() lapply(rv$runs, function(r) list(slot = r$slot, name = r$name, updated = r$updated, settings = r$settings, progress = ui_run_progress(r), unreadable = isTRUE(r$unreadable)))
  run_of_slot <- function(slot) { for (r in shiny::isolate(rv$runs)) if (identical(as.integer(r$slot), as.integer(slot))) return(r); NULL }
  run_open <- function(rec) {
    rv$rec <- rec; S$selection <- isTRUE(rec$ui$selection); S$map <- rec$ui$map; S$chat <- rec$ui$chat
    p <- ui_run_progress(rec); rv$selected <- ui_topic_order()[p$topic]; rv$window <- NULL; rv$menu_notice <- NULL; rv$screen <- "menu"
    S$banks <- list(); S$papers <- list(); bank_pump()
    if (isTRUE(rec$settings$tour_menu)) { S$first_steps <- TRUE; rec$settings$tour_menu <- FALSE; rv$rec <- rec; save_run() }   # a new run's first opening: the first steps on the Menu
  }
  run_close <- function() { save_run(); rv$rec <- NULL; rv$topic <- NULL; rv$window <- NULL; rv$map_open <- FALSE; S$chat <- NULL; S$chat_open <- FALSE }

  # --- the desk's passing state ----------------------------------------------------------------------------------------------
  # Section 4.3.2: the chat opens by itself when the Chief Economist has written what the player has not read, except under the
  # walk-through (it ends on the chat, which the page then opens) and after the term; S$chat holds the count read, kept with the run.
  chat_seen <- function(run) if (identical(S$chat$topic, run$topic)) as.integer(S$chat$seen %||% 0L) else 0L
  quarter_opened <- function(run, tour = FALSE) {
    n <- ui_chat_count(run); S$chat_open <- n > chat_seen(run) && !tour && !(run$status %in% c("over", "closed"))
    S$chat <- list(topic = run$topic, seen = if (S$chat_open) n else chat_seen(run)); rv$map_open <- FALSE
  }
  desk_opts <- function(run, dv) {
    o <- list(run_name = rv$rec$name, llm = model_on(run), chat_open = isTRUE(S$chat_open), map_open = isTRUE(rv$map_open), selection = isTRUE(S$selection),
              chat_unread = max(0L, ui_chat_count(run) - chat_seen(run)))
    if (o$map_open) { o$map_view <- map_view(run$topic, run); o$map <- S$map }
    if (!is.null(S$tour_at)) { o$tour_at <- S$tour_at; S$tour_at <- NULL }
    o
  }

  # --- the background worker: the open quarter's paper first, then the reference bank's steps in order, then
  # the term's end; without the worker, a paper missing from a saved run is written and a term saved closed is ended when its run is
  # opened --------------------------------------------------------------------------------------------------------------------------
  with_banks <- function(rec) {
    for (i in seq_along(rec$game$terms)) { x <- rec$game$terms[[i]]; b <- S$banks[[x$topic %||% ""]]
      if (ui_term_live(x) && !is.null(b) && length(b$decisions) > length(x$bank$decisions)) rec$game$terms[[i]]$bank <- b }
    rec
  }
  # The paper kept beside the run until the run takes it in, so that its return redraws nothing while the player types
  with_paper <- function(x) { p <- S$papers[[x$topic %||% ""]]; if (is.null(p) || !ui_term_live(x)) x else ui_paper_merge(x, p) }
  with_papers <- function(rec) { for (i in seq_along(rec$game$terms)) rec$game$terms[[i]] <- with_paper(rec$game$terms[[i]]); rec }
  bank_task <- shiny::ExtendedTask$new(function(kind, run, q) mirai::mirai(
    switch(kind, end = topic_end(run), paper = ui_paper_part(paper_write(run, q), q, length(run$calls)), bank_run(run, q)), kind = kind, run = run, q = q))
  bank_pump <- function() {
    rec <- shiny::isolate(rv$rec); if (is.null(rec)) return(invisible())
    if (!ui_bank_background()) {
      for (i in seq_along(rec$game$terms)) { x <- rec$game$terms[[i]]
        if (!ui_term_live(x) || !(identical(x$status, "closed") || ui_paper_due(x))) next
        n0 <- length(x$calls)
        x <- tryCatch(shiny::withProgress(message = ui_s(if (ui_paper_due(x)) "desk.progress_close" else "desk.progress_end"), value = 0.5, ui_bank_inline(x)),
                      error = function(e) { message("MPGAME the term could not be brought up to date: ", conditionMessage(e)); NULL })
        if (!is.null(x)) { rec$game$terms[[i]] <- x; rv$rec <- rec; log_calls(n0, x); save_run() }
      }
      return(invisible())
    }
    if (!is.null(S$bank_job)) return(invisible())
    rec <- with_papers(with_banks(rec))
    for (x in rec$game$terms) if (ui_term_live(x) && ui_paper_due(x)) {
      S$bank_job <- list(uid = rec$uid, topic = x$topic, kind = "paper", q = as.integer(x$t) + 1L); bank_task$invoke("paper", x, as.integer(x$t) + 1L); return(invisible())
    }
    for (x in rec$game$terms) {
      if (!ui_term_live(x) || identical(x$status, "over")) next
      n <- length(x$bank$decisions)
      if (n < x$t) { S$bank_job <- list(uid = rec$uid, topic = x$topic, kind = "bank", q = n + 1L); bank_task$invoke("bank", x, n + 1L); return(invisible()) }
      if (identical(x$status, "closed") && n >= x$T) { S$bank_job <- list(uid = rec$uid, topic = x$topic, kind = "end"); bank_task$invoke("end", x, NULL); return(invisible()) }
    }
  }
  # A paper in, kept beside its run, its calls logged and the run saved; on the desk of its topic it replaces the folded paper's
  # line "The morning edition is being printed" without a redraw. FALSE when the term has moved on or the paper is in already.
  paper_in <- function(topic, p) {
    rec <- shiny::isolate(rv$rec); i <- if (is.null(rec)) NA else live_index(rec, topic); if (is.na(i)) return(FALSE)
    x <- rec$game$terms[[i]]; if (!ui_paper_due(x) || !identical(as.integer(x$t) + 1L, as.integer(p$q))) return(FALSE)
    S$papers[[topic]] <- p; u <- shiny::isolate(rv$user)
    if (length(p$calls) && !is.null(u)) tryCatch(ui_store_log(u$id, rec$uid, topic, p$calls), error = function(e) message("MPGAME the log could not be written: ", ui_store_redact(conditionMessage(e))))
    save_run()
    if (identical(shiny::isolate(rv$screen), "desk") && identical(shiny::isolate(rv$topic), topic)) {
      run <- shiny::isolate(open_run()); dv <- desk_view(run); iss <- dv$issue
      session$sendCustomMessage("game_paper", list(view = paste0("desk:", topic), quarter = dv$topic$q, notice = ui_s("paper.arrived"), publish = ui_s("decision.publish"),
                                                   folded = ui_paper_folded_html(iss, S$selection), overlay = ui_paper_overlay_html(iss, S$selection)))
    }
    TRUE
  }
  # A paper the worker failed to write, written here under the close's line, so that the player is not left waiting for it.
  paper_inline <- function(job) {
    rec <- shiny::isolate(rv$rec); i <- if (is.null(rec) || !identical(rec$uid, job$uid)) NA else live_index(rec, job$topic); if (is.na(i)) return(FALSE)
    x <- with_paper(rec$game$terms[[i]]); if (!ui_paper_due(x)) return(FALSE)
    q <- as.integer(x$t) + 1L; n <- length(x$calls)
    r <- tryCatch(shiny::withProgress(message = ui_s("desk.progress_close"), value = 0.5, paper_write(x, q)),
                  error = function(e) { message("MPGAME the morning edition could not be written: ", conditionMessage(e)); NULL })
    !is.null(r) && paper_in(job$topic, ui_paper_part(r, q, n))
  }
  shiny::observeEvent(bank_task$status(), {
    st <- bank_task$status(); if (!st %in% c("success", "error")) return()
    job <- S$bank_job; S$bank_job <- NULL
    if (identical(st, "error")) {
      err <- tryCatch({ bank_task$result(); "" }, error = conditionMessage)
      if (identical(job$kind, "paper")) { message("MPGAME the morning edition failed in the worker: ", err); if (paper_inline(job)) bank_pump(); return() }
      message("MPGAME the reference bank's step failed: ", err); return()
    }
    res <- bank_task$result(); rec <- rv$rec; i <- if (is.null(rec) || !identical(rec$uid, job$uid)) NA else live_index(rec, job$topic)
    if (is.na(i)) { bank_pump(); return() }
    if (identical(job$kind, "paper")) { paper_in(job$topic, res); bank_pump(); return() }
    if (identical(job$kind, "bank")) S$banks[[job$topic]] <- res$bank
    else { cur <- rec$game$terms[[i]]; rec$game$terms[[i]] <- res; rv$rec <- rec; log_calls(length(cur$calls), res); S$banks[[job$topic]] <- NULL }
    save_run(); bank_pump()
  })

  # --- the screens ---------------------------------------------------------------------------------------------------------------
  screen_html <- function() {
    rv$stamp
    switch(rv$screen,
      login = ui_login_html(users, message = rv$login$message, held = isTRUE(rv$login$held), selected = rv$login$selected),
      runs = ui_runs_html(rv$user, runs_rows(), key = llm_available(), state = rv$runs_state, notice = rv$notice),
      menu = {
        terms <- rv$rec$game$terms
        mv <- menu_view(terms, rv$selected, rv$user$role)
        w <- rv$window; d <- if (!is.null(w)) { f <- Filter(function(x) identical(x$topic, w$topic) && identical(x$status, "over"), terms); if (length(f)) debrief_view(f[[length(f)]]) }
        first <- isTRUE(S$first_steps); S$first_steps <- FALSE                                           # the first steps drawn once
        ui_menu_html(mv, list(run_name = rv$rec$name, role = rv$user$role, window = d, llm = FALSE, map = S$map, notice = rv$menu_notice, first_steps = first))
      },
      desk = {
        run <- open_run(); if (is.null(run)) { rv$screen <- "menu"; return("") }
        dv <- desk_view(run)
        if (!is.null(S$tour)) { dv$tour <- S$tour; S$tour <- NULL }
        ui_desk_html(dv, desk_opts(run, dv))
      })
  }
  output$game_screen <- shiny::renderUI({
    html <- tryCatch(screen_html(), error = function(e) {
      message("MPGAME the screen could not be drawn: ", conditionMessage(e))
      game_tag("div", list(class = "game-error", role = "alert"), game_p("card-text", game_esc(ui_s("desk.error"))), game_button(ui_s("runs.retry"), "menu", "btn-main"))
    })
    shiny::HTML(html)
  })
  output$theory_screen <- shiny::renderUI({ t <- rv$theory; if (is.null(t)) return(NULL); shiny::HTML(ui_theory_html(t$chapter, t$k, t$back)) })
  shiny::observe(session$sendCustomMessage("game_tab", is.null(rv$theory)))

  # --- the login -----------------------------------------------------------------------------------------------
  shiny::observeEvent(input$game_login, {
    m <- input$game_login; if (isTRUE(m$clear)) return()
    reply <- function(status, message = "", wait = 0) session$sendCustomMessage("game_login", list(status = status, message = message, wait = wait))
    if (as.numeric(Sys.time()) < login_until) { reply("wait", ui_s("login.wait"), 2); return() }
    r <- ui_login_check(users, m$user, m$password)
    if (isTRUE(r$ok)) { rv$user <- r$user; rv$runs_state <- "connecting"; rv$runs <- list(); rv$notice <- NULL; rv$screen <- "runs"; reply("ok"); return() }
    if (identical(r$reason, "not_set_up")) { reply("not_set_up", ui_s("login.not_set_up")); return() }
    login_until <<- as.numeric(Sys.time()) + 2
    reply("wrong", ui_s("login.wrong"), 2)
  })

  # --- the Runs screen ---------------------------------------------------------------------------------------
  shiny::observeEvent(input$runs_action, {
    a <- input$runs_action; u <- rv$user; if (is.null(u)) return()
    act <- a$action; slot <- as.integer(a$slot %||% NA)
    if (act %in% c("load", "retry")) { runs_load(); return() }
    if (act == "create" && !is.na(slot)) {
      rec <- tryCatch(ui_store_put(u$id, ui_run_new(slot, substr(trimws(a$name %||% ""), 1, 60))), error = function(e) { message("MPGAME the run could not be created: ", ui_store_redact(conditionMessage(e))); NULL })
      if (is.null(rec)) { rv$notice <- ui_s("runs.error"); return() }
      runs_load(); run_open(rec); return()
    }
    if (act == "continue") {
      r <- run_of_slot(slot); if (is.null(r)) return()
      if (isTRUE(r$unreadable)) {                               # started again from the beginning, with its name
        r <- tryCatch(ui_store_put(u$id, ui_run_new(slot, r$name)), error = function(e) NULL); if (is.null(r)) { rv$notice <- ui_s("runs.error"); return() }
        runs_load(); run_open(r); rv$menu_notice <- ui_s("menu.notice_unreadable"); return()
      }
      run_open(r); return()
    }
    if (act == "rename") { r <- run_of_slot(slot); if (!is.null(r)) { r$name <- substr(trimws(a$name %||% r$name), 1, 60); tryCatch(ui_store_put(u$id, r), error = function(e) NULL) }; runs_load(); return() }
    if (act == "delete") { tryCatch(ui_store_delete(u$id, slot), error = function(e) NULL); runs_load(); return() }
    if (act == "setting") { r <- run_of_slot(slot); if (!is.null(r) && identical(a$key, "llm")) { r$settings$llm <- isTRUE(a$value); tryCatch(ui_store_put(u$id, r), error = function(e) NULL) }; runs_load(); return() }
    if (act == "tour_replay") { r <- run_of_slot(slot); if (!is.null(r)) { r$settings$tour_replay <- TRUE; tryCatch(ui_store_put(u$id, r), error = function(e) NULL) }; runs_load(); return() }
    if (act == "theory") { rv$theory <- list(chapter = "P1", k = 1L, back = "runs"); return() }
    if (act == "sign_out") { run_close(); rv$user <- NULL; rv$login <- list(); rv$screen <- "login"; return() }
  })

  # --- the game's actions ------------------------------------------------------------------------------------------------
  start_term <- function(topic) {
    rec <- rv$rec; i <- live_index(rec, topic)
    if (!is.na(i) && !identical(rec$game$terms[[i]]$status, "over")) { rv$topic <- topic; S$tour <- NULL; rv$screen <- "desk"; return() }
    if (!is.na(i)) { rec$game$terms[[i]] <- ui_term_file(rec$game$terms[[i]]); rv$rec <- rec }
    S$banks[[topic]] <- NULL; S$papers[[topic]] <- NULL
    if (identical(menu_view(rec$game$terms, topic, rv$user$role)$selected$status, "locked")) return()
    # with the worker, quarter 1's paper is printed there while the walk-through runs
    run <- tryCatch(shiny::withProgress(message = ui_s("desk.progress_start"), value = 0.5,
                                        topic_start(topic, llm = isTRUE(rec$settings$llm) && llm_available(), paper = !ui_bank_background())),
                    error = function(e) { message("MPGAME the term could not start: ", conditionMessage(e)); NULL })
    if (is.null(run)) { rv$menu_notice <- ui_s("desk.error"); return() }
    set_run(run); log_calls(0L, run); rv$topic <- topic; quarter_opened(run, tour = TRUE); S$tour_at <- 1L; rv$screen <- "desk"; save_run(); bank_pump()
  }
  close_quarter <- function(rate, path) {
    run <- open_run(); if (is.null(run) || !identical(run$status, "open")) return()
    refuse <- function(msg) session$sendCustomMessage("game_decision", list(status = "refused", message = msg))
    if (ui_paper_due(run)) { refuse(ui_s("paper.printing")); return() }        # Publish waits for the morning edition
    if (is.null(run$quarter$guided)) {
      if (is.na(rate) || (!is.null(path) && anyNA(path))) { refuse(ui_s("decision.error_rate", example = game_num(run$quarter$rate_in_force, 2))); return() }
      ck <- decision_check(run, rate, path); if (!is.null(ck)) { refuse(ui_refused(ck)); return() }
    }
    n0 <- length(run$calls); last <- run$t + 1L == run$T; bg <- ui_bank_background()
    new <- tryCatch(shiny::withProgress(message = ui_s(if (last && !bg) "desk.progress_end" else "desk.progress_close"), value = 0.5,
                                        quarter_close(if (bg) run else ui_bank_inline(run), rate, path, bank = !bg, paper = !bg)),
                    error = function(e) { message("MPGAME the quarter could not be closed: ", conditionMessage(e)); NULL })
    if (is.null(new)) { session$sendCustomMessage("game_decision", list(status = "error", message = ui_s("desk.error"))); return() }
    if (identical(new$status, "refused")) { refuse(ui_refused(new$message)); return() }
    set_run(new); log_calls(n0, new); quarter_opened(new); save_run(); bank_pump()
  }
  shiny::observeEvent(input$game_action, {
    a <- input$game_action; act <- a$action %||% ""
    if (is.null(rv$user) || is.null(rv$rec)) { if (act == "theory_back") rv$theory <- NULL; return() }
    switch(act,
      open = { rv$selected <- a$topic; rv$window <- NULL; rv$menu_notice <- NULL },
      play = start_term(a$topic),
      resume = {
        rv$topic <- a$topic
        if (isTRUE(rv$rec$settings$tour_replay)) { S$tour <- read_tour(a$topic); S$tour_at <- 1L; rec <- rv$rec; rec$settings$tour_replay <- FALSE; rv$rec <- rec }
        run <- open_run(); if (!is.null(run)) quarter_opened(run, tour = !is.null(S$tour))
        rv$screen <- "desk"
      },
      continue = {
        run <- open_run()
        if (!is.null(run) && identical(run$status, "over")) {
          rec <- rv$rec; rec$game$terms[[live_index(rec, run$topic)]] <- ui_term_file(run); rv$rec <- rec
          ord <- ui_topic_order(); k <- match(run$topic, ord); rv$selected <- ord[min(k + 1L, length(ord))]
        }
        rv$topic <- NULL; rv$map_open <- FALSE; rv$screen <- "menu"; save_run()
      },
      reset_topic = { rec <- rv$rec; i <- live_index(rec, a$topic); if (!is.na(i)) { rec$game$terms[[i]] <- NULL; rv$rec <- rec; S$banks[[a$topic]] <- NULL; S$papers[[a$topic]] <- NULL; save_run() } },
      report = { rv$window <- list(kind = "debrief", topic = a$topic) },
      window_close = { rv$window <- NULL; rv$map_open <- FALSE },
      map = { rv$map_open <- !isTRUE(rv$map_open) },
      menu = { save_run(); if (!is.null(rv$topic)) rv$selected <- rv$topic; rv$topic <- NULL; rv$map_open <- FALSE; rv$screen <- "menu" },
      save_return = { run_close(); runs_load(); rv$screen <- "runs" },
      theory = {
        chap <- a$chap %||% { b <- if (!is.null(rv$topic)) load_topic(rv$topic)$builds_on else NULL; if (length(b)) b[[1]] else "P1" }
        rv$theory <- list(chapter = chap, k = 1L, back = if (identical(rv$screen, "desk")) "desk" else "menu")
      },
      theory_back = { rv$theory <- NULL },
      publish = close_quarter(ui_parse_rate(a$rate), ui_parse_path(a$path)),
      ask = {
        run <- open_run(); q <- trimws(a$question %||% "")
        if (!is.null(run) && nzchar(q) && identical(run$status, "open")) {
          n0 <- length(run$calls)
          new <- tryCatch(chat_answer(run, substr(q, 1, ui_params$llm$question_max), ui_typed(a$rate, a$path)),        # with the decision on the page
                          error = function(e) { message("MPGAME the chat could not answer: ", conditionMessage(e)); NULL })
          if (!is.null(new)) { set_run(new); log_calls(n0, new); save_run() }
          S$chat_open <- TRUE; S$chat <- list(topic = run$topic, seen = ui_chat_count(open_run()))
          rv$stamp <- rv$stamp + 1L
        }
      },
      NULL)
  })
  shiny::observeEvent(input$theory_nav, { t <- rv$theory; n <- input$theory_nav; if (is.null(t)) return(); t$chapter <- n$chapter; t$k <- as.integer(n$k); rv$theory <- t })

  # --- the passing inputs: the forecast's points, the paper's switch, the map's arrangement, the chat read --------------------------
  shiny::observeEvent(input$game_forecast, {
    run <- shiny::isolate(open_run()); if (is.null(run) || !identical(run$status, "open")) return()
    f <- input$game_forecast; rate <- ui_parse_rate(f$rate); path <- ui_parse_path(f$path)
    if (is.na(rate) || (!is.null(path) && anyNA(path))) return()
    dv <- desk_view(run); typed <- list(rate = rate, path = path)
    pv <- tryCatch(quarter_preview(run, rate, path), error = function(e) NULL); if (is.null(pv)) return()
    o <- list(preview = pv, typed = typed)
    session$sendCustomMessage("game_forecast", list(quarter = as.integer(run$t) + 1L, points = ui_forecast_points(dv, o)))   # the projected points (Section 4.2.1)
  })
  shiny::observeEvent(input$game_paper_selection, { S$selection <- isTRUE(input$game_paper_selection$on) })
  shiny::observeEvent(input$game_map_arrange, { m <- input$game_map_arrange; S$map <- list(at = lapply(m$boxes, unlist), open = unlist(m$open)) })
  shiny::observeEvent(input$game_chat_read, {                       # the chat unfolded or folded on the page: what it shows has been read
    run <- shiny::isolate(open_run()); if (is.null(run)) return()
    S$chat_open <- isTRUE(input$game_chat_read$open)
    if (S$chat_open) S$chat <- list(topic = run$topic, seen = ui_chat_count(run))
  })
  session$onSessionEnded(function() shiny::isolate(save_run()))
}
