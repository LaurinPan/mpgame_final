# 02_Game/play/topic.R — the interface, the five calls the UI makes on a run (Section 4.2.1)

# Section 4.2.1 and the interface: the run at a topic's start, its first quarter opened
topic_start <- function(id, llm = TRUE, seed = NULL, draw_seed = NULL, paper = TRUE) {
  s   <- if (is.character(id)) load_topic(id) else id; id <- s$id
  run <- run_start(s, seed)
  run$draw_seed <- draw_seed
  run$llm    <- list(on = llm)
  run$chat   <- list(); run$calls <- list(); run$issues <- list(); run$plans <- list(); run$masks <- list()
  run$guided <- if (!is.null(s$guided)) read.csv(file.path("02_Game/content/guided", paste0(id, ".csv")), stringsAsFactors = FALSE) else NULL
  run$tour   <- read_tour(id)
  quarter_open(run, paper)
}

# Section 4.3.2: the guided decision of quarter q, or NULL; its announcement only where the topic has the bank's word
guided_row <- function(run, q) {
  if (is.null(run$guided) || !(q %in% run$guided$q)) return(NULL)
  row <- run$guided[run$guided$q == q, ]
  list(rate = row$rate, previous = if (q > 1) run$quarters$rate[q - 1] else steady_rate(run$config$par),
       plan = unname(unlist(row[paste0("plan_", 2:run$config$par$H)])), action = if (row$action == "announce" && !word_on(run$script)) "rate" else row$action, locked = TRUE)
}

# Section 4.2.2: in a topic without a newspaper the briefings carry the quarter's news, exact in the guided quarters and in words otherwise, and the fair quarter follows
reported_by_briefings <- function(script, q, sheet) setNames(rep(if (q %in% script$guided$quarters) "exact" else "words", length(sheet$shocks$shocks)), names(sheet$shocks$shocks))

# Section 4.2.1: the quarter opened, with the staff forecast at the decision the desk starts from, the paper written where the topic has one unless the UI writes it with paper_write
quarter_open <- function(run, paper = TRUE) {
  q <- run$t + 1; s <- run$script
  run <- run_open(run)
  sheet1 <- fact_sheet(run, q, 1)
  if ("newspaper" %in% s$panels) {
    iss <- plan_issue(run, q, sheet1)
    run$plans[[q]] <- iss$plan; run$sheets[[q]] <- iss$sheet
    if (paper) run <- paper_write(run, q) else { run$issues[q] <- list(NULL); run$masks[q] <- list(NULL) }
  } else {
    run$plans[q] <- list(NULL); run$issues[q] <- list(NULL); run$masks[q] <- list(NULL)
    run$sheets[[q]] <- fact_sheet(run, q, 2, reported = reported_by_briefings(s, q, sheet1))
  }
  g <- guided_row(run, q)
  run$quarter$guided <- g
  msgs <- list()
  if (q == 1) msgs <- c(msgs, list(briefing_start(s, run$sheets[[q]])))
  msgs <- c(msgs, briefings_due(s, "quarter_start", q, run$sheets[[q]], g))
  run$chat <- c(run$chat, msgs)
  in_force <- if (q > 1) run$quarters$rate[q - 1] else steady_rate(run$config$par)
  run$quarter$rate_in_force <- in_force
  w <- run$sheets[[q]]$word; ahead <- if (isTRUE(w$has_path)) w$path$rate[w$path$q > q] else numeric(0)
  start <- if (!is.null(g)) list(rate = g$rate, path = if (g$action == "announce") g$plan else NULL)
           else list(rate = if (isTRUE(w$has_path) && !is.na(w$due)) w$due else in_force, path = if (length(ahead)) ahead else NULL)
  run$quarter$start <- start
  run$quarter$forecast <- if ("forecast" %in% s$panels) staff_forecast(run, q, start$rate, start$path) else NULL
  run$status <- "open"; run$message <- NULL
  run
}

# Section 4.3.1 with Table 1, Section 4.2.1 and (A11): the checks a decision must pass, the floor and the cap included, or the reason it is refused
decision_check <- function(run, rate, path) {
  par <- run$config$par; g <- run$quarter$guided
  if (!identical(rate, "rule")) {
    if (!is.numeric(rate) || is.na(rate)) return("the rate is not a number")
    if (rate < 0) return("the policy rate cannot be set below zero")
    if (rate > consts$cap) return("Rates above 20 percent lie outside what this game can show. Its economy is modelled near normal times, and 20 percent is the record high that the US federal funds rate reached, in late 1980.")
  }
  if (!is.null(path)) {
    if (!word_on(run$script)) return("announcements need the bank's word, from Topic 4 on")
    if (length(path) > par$H) return(sprintf("an announcement names at most %d quarters", par$H))
    if (any(path < 0)) return("an announced rate cannot lie below zero")
    if (any(path > consts$cap)) return("Rates above 20 percent lie outside what this game can show. Its economy is modelled near normal times, and 20 percent is the record high that the US federal funds rate reached, in late 1980.")
  }
  if (identical(run$script$path, "required") && is.null(path)) return("this topic needs an announced plan with every decision")
  if (!is.null(g)) {
    if (!identical(rate, "rule") && abs(rate - g$rate) > 1e-9) return("this quarter's decision is the bank's: the rate is set")
    if (g$action == "announce" && (is.null(path) || length(path) != length(g$plan) || any(abs(path - g$plan) > 1e-9))) return("this quarter's announcement is the bank's: the plan is set")
  }
  NULL
}

# Section 4.2.1: the preview at the typed decision
quarter_preview <- function(run, rate, path = NULL) {
  check <- decision_check(run, rate, path)
  if (!is.null(check)) return(list(refused = check, forecast = NULL))
  list(refused = NULL, forecast = if ("forecast" %in% run$script$panels) staff_forecast(run, run$t + 1, rate, path) else NULL)
}

# Section 4.2.1: the quarter closed on the decision, the bank advanced unless the UI does it with bank_run, the next paper written unless it does it with paper_write
quarter_close <- function(run, rate, path = NULL, bank = TRUE, paper = TRUE) {
  q <- run$t + 1; g <- run$quarter$guided
  if (!is.null(g)) { rate <- g$rate; path <- if (g$action == "announce") g$plan else NULL }
  check <- decision_check(run, rate, path)
  if (!is.null(check)) { run$status <- "refused"; run$message <- check; return(run) }
  run <- run_close(run, list(rate = rate, announce = path))
  if (bank) run <- bank_run(run, q)
  if (run$t < run$T) quarter_open(run, paper) else if (bank) topic_end(run) else { run$status <- "closed"; run$message <- NULL; run }
}

# Sections 4.2.1 and 4.2.2: the term's end, the record, the marks and the debrief
topic_end <- function(run) {
  if (is.null(run$bank) || length(run$bank$decisions) < run$T) stop("the reference bank's run must be advanced through every quarter (bank_run) before the term ends")
  record <- term_record(run)
  costs  <- decision_costs(run, record)
  marks  <- debrief_marks(costs, record$term$player, record$term$bank)
  record$costs <- costs; record$marks <- marks
  run$record  <- record
  d <- write_debrief(record, marks, on = model_on(run))
  run$calls   <- c(run$calls, d$records)
  run$debrief <- d
  run$chat <- c(run$chat, list(list(q = run$T, kind = "note", id = "debrief", text = "The term is over. Your debrief is ready on the desk.")))
  run$status <- "over"; run$message <- NULL
  run
}
