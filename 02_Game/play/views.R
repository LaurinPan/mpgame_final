# 02_Game/play/views.R — the interface, the views each screen reads

# Section 4.2.1: the charts' series of the term so far
term_series <- function(run) {
  par <- run$config$par; t <- run$t
  rows <- rbind(run$row0, if (t >= 1) run$quarters[seq_len(t), ])
  h <- readouts_table(rows, t, par, consts, t + 1)
  data.frame(t = h$t, rate = h$rate, inflation = h$inflation, wage_inflation = h$wage_inflation,
             output_level = h$output_level, output_trend = h$output_trend, unemployment = h$unemployment,
             expected_inflation = rows$e_pi_p, aim_level = if (5 %in% run$config$on) to_year(par$pi_bar) + rows$aim else NA,
             election = if (6 %in% run$config$on) !is.na(rows$election) else FALSE)
}

# Section 4.2.1: a chart's reference line from the law
reference_value <- function(name, law) {
  if (is.na(name)) return(NA)
  switch(name, floor = 0, target = law$target, wage_normal = law$wage_normal, trend_growth = law$trend_growth,
         natural_unemployment = law$natural_unemployment, zero = 0, half = 50, normal = 0, trend = NA, NA)
}

# Section 4.2.1 and v6 §3: the desk, everything the dashboard, the rate control, the chat and the paper read
desk_view <- function(run) {
  q <- run$t + 1; s <- run$script; sheet <- run$sheets[[min(q, length(run$sheets))]]
  law <- sheet$law; f <- sheet$figures; p <- sheet$public; w <- sheet$word; g <- sheet$government
  over <- identical(run$status, "over")
  series <- term_series(run)
  shown <- desk_charts[desk_charts$panel %in% s$panels, ]
  charts <- lapply(seq_len(nrow(shown)), function(i) {
    ch <- shown[i, ]; sc <- scales[scales$variable == ch$scale, ]
    list(id = ch$id, panel = ch$panel, series = strsplit(ch$series, ";")[[1]],
         data = series[, intersect(c("t", strsplit(ch$series, ";")[[1]], "election"), names(series))],
         announced = if (ch$id == "rate" && isTRUE(w$has_path)) w$path else NULL,
         scale = list(lo = sc$lo, hi = sc$hi, unit = sc$unit, beyond = "ring at the edge"),
         reference = reference_value(ch$reference, law), reference_name = ch$reference)
  })
  names(charts) <- shown$id
  list(
    topic = list(id = s$id, name = s$name, chapter = s$chapter, chapter_name = chapters[[s$chapter]]$name, task = s$task,
                 q = min(q, run$T), T = run$T, guided = !is.null(run$quarter$guided), path_required = identical(s$path, "required"),
                 status = run$status, message = run$message),
    header = list(rate_in_force = run$quarter$rate_in_force, target = law$target, at_floor = isTRUE(run$quarter$rate_in_force < 0.005),
                  spell = if (p$spell > 0) p$spell else NULL,
                  election = if (!is.null(g) && length(run$votes)) list(quarters_to = g$next_election, this_quarter = g$next_election == 1, party = g$party) else NULL,
                  path = if (isTRUE(w$has_path)) list(standing = w$path, due = w$due) else NULL),
    panels = s$panels,
    slump = if (!is.null(run$foreseen) && q >= run$foreseen$start) list(start = run$foreseen$start, length = length(run$foreseen$d)) else NULL,
    figures = list(output = list(level = f$output_level, trend = f$output_trend, growth = f$growth, fell = f$output_fell, recession = f$recession, unit = "$ bn a year; growth in percent a year"),
                   inflation = list(value = f$inflation, change = f$inflation_change, unit = "percent a year"),
                   wage_inflation = list(value = f$wage_inflation, change = f$wage_change, unit = "percent a year"),
                   unemployment = list(rate = f$unemployment, change = f$unemployment_change, persons = f$unemployed_persons, quarters_above = f$quarters_above_natural, unit = "percent; persons"),
                   population = list(value = f$population, unit = "persons"),
                   labour_force = list(value = f$labour_force, unit = "persons"),
                   rate = list(value = f$rate, change = f$rate_change, unit = "percent a year")),
    expectations = if ("expectations" %in% s$panels) list(expected_inflation = p$expected_inflation, aim = if (5 %in% run$config$on) law$target + p$perceived_aim else NA, target = law$target, unit = "percent a year") else NULL,
    word = if (word_on(s)) list(has_path = w$has_path, standing = w$path, due = w$due, cone = w$cone, room = w$room, room_due = w$room_due,
                                new_shock = w$news, floor_expected = p$spell) else NULL,
    forecast = if ("forecast" %in% s$panels && !is.null(run$quarter$forecast)) {
      fc <- run$quarter$forecast
      list(rows = lapply(consts$forecast_rows, function(r) list(name = r, mean = fc$mean[[r]], lo = fc$band$lo[[r]], hi = fc$band$hi[[r]])),
           at = run$quarter$start,
           spell = fc$spell, in_words = fc$in_words) } else NULL,
    charts = charts,
    decision = list(rate_start = run$quarter$start$rate, path_start = run$quarter$start$path,
                    guided = run$quarter$guided, path_required = identical(s$path, "required"), floor = 0, cap = consts$cap, H = law$H,
                    word = word_on(s), publish = if (!is.null(run$quarter$guided)) "Close the quarter" else "Publish"),
    chat = list(messages = run$chat, pending = NULL),
    issue = if (length(run$issues) >= min(q, run$T)) issue_view(run, min(q, run$T)) else NULL,
    tour = if (q == 1 && !over) run$tour else NULL,
    debrief = if (over) debrief_view(run) else NULL)
}

# Section 4.3: the chapters and topics with their status, the selected card and the topic's map
menu_view <- function(runs = list(), selected = "T1", role = "player") {
  order <- unlist(lapply(chapters, `[[`, "topics"))
  played_out <- function(id) any(vapply(runs, function(r) identical(r$topic, id) && identical(r$status, "over"), logical(1)))
  open_term <- function(id) { rs <- Filter(function(r) identical(r$topic, id) && !identical(r$status, "over"), runs); if (!length(rs)) NULL else list(q = rs[[length(rs)]]$t, T = rs[[length(rs)]]$T) }
  status_of <- function(id) {
    if (played_out(id)) return("played_out")
    if (any(vapply(runs, function(r) identical(r$topic, id), logical(1)))) return("in_play")
    earlier <- order[seq_len(match(id, order) - 1)]
    if (role == "developer" || all(vapply(earlier, played_out, logical(1)))) "next" else "locked"
  }
  chs <- lapply(chapters, function(ch) list(id = ch$id, name = ch$name,
    topics = lapply(ch$topics, function(id) { s <- load_topic(id); list(id = id, name = s$name, status = status_of(id), T = s$term,
                                                                      played = sum(vapply(runs, function(r) identical(r$topic, id) && identical(r$status, "over"), logical(1))), open = open_term(id)) })))
  s <- load_topic(selected); st <- status_of(selected)
  list(chapters = chs,
       selected = list(id = selected, chapter = s$chapter, name = s$name, task = s$task, summary = s$summary, builds_on = s$builds_on,
                       status = st, T = s$term, played = sum(vapply(runs, function(r) identical(r$topic, selected) && identical(r$status, "over"), logical(1))), open = open_term(selected),
                       action = if (!is.null(open_term(selected))) "continue" else switch(st, played_out = "play_again", in_play = "continue", "next" = "begin", locked = "locked")),
       map = map_view(selected))
}

# v6 §12.1: the paper's two fixed boxes, drawn by the game from the sheet, box W with the bank's word and box G with the government and the politics of a vote
issue_boxes <- function(run, q) {
  sheet <- run$sheets[[q]]; w <- sheet$word; p <- sheet$public; g <- sheet$government
  list(W = if (word_on(run$script)) list(path = w$path, last = if (isTRUE(w$judged)) list(announced = w$announced, set = w$set, kept = w$kept, departure = w$departure) else NULL,
                                         record = w$record, trust = p$trust_percent, room = list(new_shock = w$news, due = w$room_due)) else NULL,
       G = if (!is.null(g)) list(purchases = g$purchases, change = g$purchases_change,
                                 politics = if (length(run$votes)) list(party = g$party, poll = g$poll, next_election = g$next_election, last_vote = g$last_vote) else NULL) else NULL)
}

# v6 §12: the issue as the paper reads it with its fixed boxes, NULL where the topic has no newspaper or while the quarter's paper is pending
issue_view <- function(run, q) {
  iss <- run$issues[[q]]
  if (is.null(iss)) return(NULL)
  c(iss, list(budgets = lapply(formats, `[[`, "budgets"), slots = slots, boxes = issue_boxes(run, q)))
}

# Section 4.2.2 and v6 §5.4: the debrief, the two paths, the two losses quarter by quarter, the term losses with their equivalent misses and the marks
debrief_view <- function(run) {
  rec <- run$record; d <- run$debrief
  if (is.null(rec)) return(NULL)
  texts <- setNames(lapply(d$marks, `[[`, "text"), vapply(d$marks, function(m) as.character(m$q), ""))
  list(topic = rec$topic, name = rec$name, T = rec$T, covers = rec$covers,
       chart = data.frame(q = seq_len(rec$T), player = rec$player$rate, bank = rec$bank$rate, guided = seq_len(rec$T) %in% rec$guided),
       loss_text = d$loss_text, source = d$source,
       loss_by_quarter = rec$loss, term = rec$term, player_at_most_bank = rec$term$player <= rec$term$bank,
       marks = lapply(rec$marks, function(m) list(q = m$q, kind = m$kind, cost = m$cost, equivalent = m$equivalent, shaded = m$shaded,
                                                 player_rate = m$player_rate, bank_rate = m$bank_rate, text = texts[[as.character(m$q)]])))
}

# v6 §4: the map of a topic, the boxes, nodes and arrows reached with the topic's own new ones flagged, the walk's start and the three graphs
map_view <- function(topic, run = NULL) {
  s <- if (!is.null(run)) run$script else load_topic(topic); n <- as.integer(sub("^T", "", s$id))
  reached <- function(df) { out <- df[df$first_topic <= n, , drop = FALSE]; out$new <- out$first_topic == n; rownames(out) <- NULL; out }
  boxes <- reached(map$boxes); nodes <- reached(map$nodes); arrows <- reached(map$arrows)
  par <- if (!is.null(run)) run$config$par else configure(s$stages, "game")$par
  sheet <- if (!is.null(run) && length(run$sheets)) run$sheets[[length(run$sheets)]] else NULL
  value_of <- function(field, panel) {
    if (is.null(sheet) || is.na(field) || !(panel %in% s$panels)) return(NA_real_)
    p <- strsplit(field, "[.]")[[1]]; v <- sheet[[p[1]]][[p[2]]]
    if (is.null(v) || is.na(v)) NA_real_ else if (field == "public.perceived_aim") sheet$law$target + v else v
  }
  nodes$value <- unname(mapply(value_of, nodes$field, nodes$panel))
  start <- "rate"
  if (!is.null(sheet)) { sh <- sheet$shocks
    if (length(sh$shocks)) start <- map$walk_start[[sh$shocks[[1]]$type]]
    else if (isTRUE(sh$path_started)) start <- map$walk_start[["slump"]]
    else if (isTRUE(sh$vote_due)) start <- map$walk_start[["vote"]] }
  graphs <- lapply(map$graphs[vapply(map$graphs, function(gr) TRUE, logical(1))], function(gr) {
    gr$values <- list()
    for (k in intersect(c("slope", "lift", "output_share"), names(gr))) gr$values[[k]] <- eval(parse(text = gr[[k]]), envir = as.list(par))
    gr })
  graphs <- graphs[names(graphs) %in% arrows$id]
  list(topic = s$id, boxes = boxes, nodes = nodes, arrows = arrows, walk_start = start, graphs = graphs)
}
