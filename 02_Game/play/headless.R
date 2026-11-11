# 02_Game/play/headless.R — Section 3.2, the headless player: a term in the console through the five calls

# Section 3.2: the headless player's decision, the rule, the bank, a held rate or a function
headless_decision <- function(run, policy) {
  q <- run$t + 1; par <- run$config$par; s <- run$script
  word <- word_on(s); required <- identical(s$path, "required")
  if (is.function(policy)) return(policy(run))
  if (identical(policy, "bank")) {
    fair <- fair_quarter(run, q)
    plan <- bank_plan(run$config, fair, word, word_boxes(run$config, fair, run$states[[q]], run$quarter$rate_in_force, word), run$T - q + 1, shifted(run$plan_before), previous = run$quarter$rate_in_force)
    return(list(rate = round(plan$rates[1], 2), path = if (word) round(plan$rates[-1], 2), plan = plan))
  }
  if (identical(policy, "hold")) return(list(rate = run$quarter$rate_in_force, path = if (required) rep(run$quarter$rate_in_force, par$H - 1)))
  if (identical(policy, "rule")) {
    path <- NULL
    if (required) { o <- solve_quarter(run$config, run$quarter$engine, list(rate = "rule")); path <- round(steady_rate(par) + to_year(o$rule_rates[seq_len(par$H - 1)]), 2) }
    return(list(rate = "rule", path = path))
  }
  stop("unknown policy")
}

# Section 3.2: the headless player's decision as the page holds it for the chat, the rule's rate as its number to two decimals, a guided quarter's as the game sets it
headless_typed <- function(run, d) {
  if (!is.null(run$quarter$guided)) return(run$quarter$start)
  rate <- d$rate
  if (identical(rate, "rule")) rate <- round(steady_rate(run$config$par) + to_year(solve_quarter(run$config, run$quarter$engine, list(rate = "rule", announce = d$path))$i), 2)
  list(rate = rate, path = d$path)
}

# Section 3.2: a term played in the console, or its first quarters, with the election draws seeded for a recording
play_headless <- function(id, policy = "rule", llm = FALSE, seed = NULL, print = TRUE, questions = NULL, quarters = NULL, draw_seed = NULL) {
  run <- topic_start(id, llm = llm, seed = seed, draw_seed = draw_seed)
  say <- function(...) if (print) cat(..., "\n", sep = "")
  say(sprintf("== %s %s: %d quarters, model %s", run$topic, run$script$name, run$T, if (model_on(run)) "on" else "off (templates)"))
  while (!identical(run$status, "over") && (is.null(quarters) || run$t < quarters)) {
    q <- run$t + 1
    new <- Filter(function(m) m$q == q && m$kind == "briefing", run$chat)
    for (m in new) say(sprintf("  briefing %s (%d of %d): %s", m$id, m$step, m$of, m$text))
    if (print) cat(paste0("  ", format_sheet(run$sheets[[q]])), sep = "\n")
    if (!is.null(run$issues[[q]])) say(sprintf("  issue: %s", paste(sprintf("%s %s", run$issues[[q]]$index$slot, run$issues[[q]]$index$headline), collapse = " | ")))
    d <- headless_decision(run, policy); run$plan_before <- d$plan
    if (!is.null(questions)) {
      run <- chat_answer(run, questions[(q - 1) %% length(questions) + 1], headless_typed(run, d))
      say(sprintf("  chat: %s", run$chat[[length(run$chat)]]$text))
    }
    say(sprintf("  decision: rate %s%s", if (identical(d$rate, "rule")) "the rule's" else sprintf("%.2f", d$rate), if (!is.null(d$path)) sprintf(", path %s", paste(sprintf("%.2f", d$path), collapse = " ")) else ""))
    run <- quarter_close(run, d$rate, d$path)
    if (identical(run$status, "refused")) stop("quarter ", q, " refused: ", run$message)
    say(sprintf("  closed quarter %d: rate %.2f, inflation %.2f, gap %.2f, unemployment %.2f, loss %.2f; the bank set %.2f",
                run$t, run$quarters$rate[run$t], run$quarters$pi_p[run$t], run$quarters$x[run$t], run$quarters$U[run$t],
                consts$loss_scale * run$quarters$loss[run$t], run$bank$quarters$rate[run$t]))
  }
  if (identical(run$status, "over")) {
    say(sprintf("== debrief (%s): term loss %.2f against the bank's %.2f; marks: %s", run$debrief$source, run$record$term$player, run$record$term$bank,
                if (length(run$record$marks)) paste(sprintf("q%d %s %.2f", vapply(run$record$marks, `[[`, 1L, "q"), vapply(run$record$marks, `[[`, "", "kind"), vapply(run$record$marks, `[[`, 1, "cost")), collapse = "; ") else "none"))
    say(sprintf("  %s", run$debrief$loss_text))
    for (m in run$debrief$marks) say(sprintf("  mark q%s: %s", m$q, m$text))
  }
  run
}

# Section 3.2: a request as text, its three parts and the structure of its answer
request_text <- function(body) c("## System block 1: the fixed part", "", body$system[[1]]$text, "",
                                 "## System block 2: the instruction", "", body$system[[2]]$text, "",
                                 "## User message: the material", "", body$messages[[1]]$content, "",
                                 "## The structure of the answer", "", as.character(jsonlite::toJSON(body$output_config$format$schema, auto_unbox = TRUE)))

# Section 3.2: a topic's walk-through recorded for the LLM appendix, the player deciding as the reference bank: the sheet, the plan and the issue of one quarter, the calls of that quarter and the debrief's as sent with their answers, one file for each piece, for the lead, for the chat and for the debrief with every call it took, and the record
record_walkthrough <- function(id = "T5", at = 8, question = "Should I raise the policy rate above my announced plan this quarter?",
                               llm = TRUE, seed = 1, draw_seed = as.integer(sub("^T", "", id)), dir = "03_Verification/recordings/walkthrough") {
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  save_json <- function(x, name) jsonlite::write_json(x, file.path(dir, name), auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null", digits = 6)
  save_calls <- function(rs, name) {
    if (!length(rs)) return(invisible())
    lines <- unlist(lapply(seq_along(rs), function(i) c(sprintf("# Call %d of %d", i, length(rs)), "", request_text(rs[[i]]$body), "", "## The answer", "", if (is.null(rs[[i]]$raw)) "none" else rs[[i]]$raw, "")))
    con <- file(file.path(dir, name), "wb"); writeLines(enc2utf8(lines), con, sep = "\n", useBytes = TRUE); close(con)
  }
  run <- topic_start(id, llm = llm, seed = seed, draw_seed = draw_seed)
  while (!identical(run$status, "over")) {
    q <- run$t + 1
    d <- headless_decision(run, "bank"); run$plan_before <- d$plan
    if (q == at) {
      typed <- headless_typed(run, d)
      for (i in 1:3) run <- chat_answer(run, question, typed)
      save_json(run$sheets[[q]], sprintf("q%d_sheet.json", at)); save_json(run$plans[[q]], sprintf("q%d_editor.json", at)); save_json(run$issues[[q]], sprintf("q%d_issue.json", at))
      save_json(list(decision = typed, forecast = quarter_preview(run, typed$rate, typed$path)), sprintf("q%d_decision_and_forecast.json", at))
    }
    run <- quarter_close(run, d$rate, d$path)
    if (identical(run$status, "refused")) stop("quarter ", q, " refused: ", run$message)
  }
  of <- function(task, slot = NULL) Filter(function(r) r$task == task && (task == "debrief" || isTRUE(r$about$q == at)) && (is.null(slot) || identical(r$about$slot, slot)), run$calls)
  for (slot in setdiff(names(run$plans[[at]]$items), "L")) save_calls(of("piece", slot), sprintf("q%d_piece_%s.md", at, slot))
  save_calls(of("lead"), sprintf("q%d_lead.md", at)); save_calls(of("chat"), sprintf("q%d_chat.md", at)); save_calls(of("debrief"), "debrief_call.md")
  rec <- run$record
  save_json(list(loss_text = run$debrief$loss_text, marks = run$debrief$marks, source = run$debrief$source, model = run$debrief$model), "debrief_output.json")
  save_json(list(loss = rec$loss, term = rec$term, player_rates = rec$player$rate, bank_rates = rec$bank$rate, costs = rec$costs$table, marks = rec$marks,
                 guided = rec$guided, covers = rec$covers), "record_and_marks.json")
  save_json(models, "models.json")
  save_json(lapply(run$calls, function(r) list(task = r$task, about = r$about, model = r$model, model_served = r$model_served, seconds = r$seconds, ok = r$ok,
                                                stop_reason = r$stop_reason, error = r$error, usage = r$usage)), "calls.json")
  invisible(run)
}
