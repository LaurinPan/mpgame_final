# 02_Game/sheet/record.R — Section 4.2.2, the Word block, and A.5 "Credibility and the Record"

# A.1, "Steady State, Trend, and Parameters": the steady-state nominal rate in percent a year
steady_rate <- function(par) to_year(steady_state(par)$i_star)

# A.5, "The Bank's Word": the standing path in percent a year
standing_path <- function(quarter, par) {
  (steady_rate(par) + to_year(c(quarter$word$due, quarter$word$ahead)))[seq_len(par$H)]
}

# A.5, "Credibility and the Record": the room the quarter's new shocks give
news_room <- function(config, quarter, state, in_force) {
  par <- config$par
  if (!isTRUE(quarter$exo$news)) return(list(due = 0, ahead = numeric(par$H)))
  with    <- solve_quarter(config, quarter, list(rate = in_force))
  quiet   <- begin_quarter(config, state, list(a = 0, z = 0, nu = 0, g = 0, draw = quarter$exo$draw))
  without <- solve_quarter(config, quiet, list(rate = in_force))
  list(due = to_year(with$i_rule - without$i_rule),
       ahead = to_year(with$rule_rates - without$rule_rates)[seq_len(par$H)])
}

# Section 4.2.2: the Word block, the standing path, the judgement, the record, the room and the band (A25)
word_block <- function(run, q) {
  config <- run$config; par <- config$par
  empty <- list(has_path = FALSE, path = NULL, due = NA, announced = NA, set = NA, judged = FALSE, kept = NA,
                departure = NA, miss = NA, record = NULL, room = NULL, room_due = 0, news = FALSE, cone = NULL)
  if (!(5 %in% config$on)) return(empty)
  eng <- run$quarter$engine; t <- q - 1
  standing <- standing_path(eng, par)
  has  <- !is.na(standing)
  path <- if (any(has)) data.frame(q = q + which(has) - 1, rate = standing[has]) else NULL
  due_for <- function(k) steady_rate(par) + to_year(run$states[[k]]$word$due)
  announced <- if (t >= 1) due_for(t) else NA
  miss_t <- if (t >= 1) run$quarters$miss[t] else NA
  judged <- t >= 1 && !is.na(miss_t)
  record <- NULL
  if (t >= 1) {
    record <- data.frame(q = seq_len(t), announced = vapply(seq_len(t), due_for, numeric(1)),
                         set = run$quarters$rate[seq_len(t)], miss = run$quarters$miss[seq_len(t)])
    record$entry <- ifelse(is.na(record$announced), NA, ifelse(is.na(record$miss) | record$miss == 0, "kept", "broken"))
  }
  in_force <- if (t >= 1) run$quarters$rate[t] else steady_rate(par)
  room <- news_room(config, eng, run$states[[q]], in_force)
  list(has_path = any(has), path = path, due = if (has[1]) standing[1] else NA,
       announced = announced, set = if (t >= 1) run$quarters$rate[t] else NA,
       judged = judged, kept = if (judged) miss_t == 0 else NA, departure = if (judged) run$quarters$rate[t] - announced else NA, miss = miss_t,
       record = record, room = room$ahead, room_due = room$due, news = isTRUE(eng$exo$news),
       cone = cone(seq_len(par$H), par))
}
