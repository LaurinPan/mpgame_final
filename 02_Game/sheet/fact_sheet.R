# 02_Game/sheet/fact_sheet.R — Section 4.2.2: the fact sheet

# Section 4.2.1: the figures before the term's first quarter
quarter_zero <- function(run) {
  zero <- list(eps_a = 0, eps_z = 0, eps_nu = 0, eps_g = 0, draws = NA)
  row  <- play(run$config, run$start, zero, "rule")$quarters
  row$t <- 0
  row
}

# Section 4.2.2: the Law block
law_block <- function(config) {
  par <- config$par
  list(target = to_year(par$pi_bar), trend_growth = to_year(par$g), natural_unemployment = to_percent(par$u_n),
       floor = 0, cap = consts$cap, H = par$H, cone_width = par$b, election_interval = par$T_e, boost_window = par$q_b,
       wage_normal = to_year(par$pi_bar + par$g), weight_on_output = 16 * par$vartheta)
}

# Section 4.2.2: the Government block
government_block <- function(run, q, rows) {
  config <- run$config; par <- config$par
  if (!(6 %in% config$on)) return(NULL)
  eng   <- run$quarter$engine; t <- q - 1
  row   <- rows[nrow(rows), ]
  share <- 1 - par$s_C
  previous <- if (t >= 1) rows$G[nrow(rows) - 1] else row$G
  held  <- t >= 1 && !is.na(row$election)
  last  <- if (t >= 1 && any(!is.na(rows$election[-1]))) { k <- max(which(!is.na(rows$election))); list(q = rows$t[k], winner = consts$parties[rows$election[k]], share = 100 * (if (rows$election[k] == rows$party[k]) rows$vote_poll[k] else 1 - rows$vote_poll[k])) } else NULL
  result <- NA
  if (held) {
    winner <- consts$parties[row$election]
    result <- if (row$election == row$party) paste(winner, "was re-elected") else paste(winner, "won the election")
  }
  list(purchases = row$G / share, purchases_change = (row$G - previous) / share,
       party = consts$parties[eng$gov$party],
       boost_window = isTRUE(eng$exo$e), poll = 100 * row$poll, poll_opposition = 100 * (1 - row$poll), next_election = eng$gov$to_election,
       vote_held = held, vote_result = result, vote_winner = if (held) consts$parties[row$election] else NA,
       vote_reelected = held && row$election == row$party, last_vote = last,
       vote_poll = if (held) 100 * (if (row$election == row$party) row$vote_poll else 1 - row$vote_poll) else NA)
}

# Section 4.2.2: the sheet's blocks
fact_sheet <- function(run, q, step = 1, reported = NULL) {
  config <- run$config; par <- config$par; t <- q - 1
  rows <- rbind(run$row0, if (t >= 1) run$quarters[seq_len(t), ])
  figures <- readouts(rows, t, par, consts)
  history <- readouts_table(rows, t, par, consts, consts$history_quarters)
  at <- match(history$t, rows$t)
  history$expected_inflation <- rows$e_pi_p[at]
  history$poll      <- if (6 %in% config$on) 100 * rows$poll[at] else NA
  history$purchases <- if (6 %in% config$on) rows$G[at] / (1 - par$s_C) else NA
  shocks  <- classify(run$innovations[q, ], run$foreseen, run$votes, q, classes)
  if (step == 2) for (ty in names(shocks$shocks))
    shocks$shocks[[ty]]$reported <- if (!is.null(reported[[ty]])) reported[[ty]] else "words"
  state <- run$states[[q]]
  on5   <- 5 %in% config$on
  public <- list(expected_inflation = rows$e_pi_p[nrow(rows)],
                 perceived_aim = if (on5) to_year(state$aim) else NA,
                 aim_change = if (on5 && t >= 1) to_year(state$aim - run$states[[t]]$aim) else 0,
                 trust = if (on5) state$cred$chi else NA,
                 trust_percent = if (on5) 100 * state$cred$chi else NA,
                 trust_change = if (on5 && t >= 1) 100 * (state$cred$chi - run$states[[t]]$cred$chi) else 0,
                 spell = rows$spell[nrow(rows)])
  law <- law_block(config)
  list(q = q, t = t, step = step,
       figures = figures, history = history, shocks = shocks, public = public,
       word = word_block(run, q), government = government_block(run, q, rows),
       drivers = drivers(run, q, classes),
       pressing = pressing(figures, law, classes$thresholds),
       law = law)
}

# Section 3.2: the sheet as lines for the headless player
format_sheet <- function(sheet) {
  f <- sheet$figures; p <- sheet$public; w <- sheet$word; g <- sheet$government; d <- sheet$drivers; pr <- sheet$pressing
  n2 <- function(x) formatC(x, format = "f", digits = 2)
  n1 <- function(x) formatC(x, format = "f", digits = 1)
  plural <- function(n, word) sprintf("%d %s%s", n, word, if (n == 1) "" else "s")
  lines <- c(sprintf("Fact sheet, quarter %d (step %d): last quarter's figures are quarter %d's", sheet$q, sheet$step, sheet$t),
    sprintf("  Figures     inflation %s (%+.2f); wage inflation %s; growth %s; output %s $ bn, trend %s%s%s; unemployment %s (%s persons), %s above the natural rate; rate %s; loss %s = %s + %s",
            n2(f$inflation), f$inflation_change, n2(f$wage_inflation), n2(f$growth), formatC(f$output_level, format = "f", digits = 0),
            formatC(f$output_trend, format = "f", digits = 0), if (f$output_fell) ", output fell" else "", if (f$recession) ", recession" else "",
            n2(f$unemployment), formatC(f$unemployed_persons, format = "d", big.mark = ","), plural(f$quarters_above_natural, "quarter"), n2(f$rate),
            n2(f$loss$total), n2(f$loss$inflation), n2(f$loss$output)))
  sh <- sheet$shocks
  shock_lines <- vapply(sh$shocks, function(s) sprintf("%s %s %s (%s)%s%s", s$type, s$sign, s$class, s$words,
                        if (!is.na(s$reported)) paste0(", reported: ", s$reported) else "",
                        if (identical(s$reported, "exact")) sprintf(", size %+.2f", s$size) else ""), "")
  lines <- c(lines, sprintf("  Shocks      %s%s%s", if (length(shock_lines)) paste(shock_lines, collapse = "; ") else "none",
                            if (sh$path_started) sprintf("; a foreseen path starts: %d quarters, %s", sh$path_length, sh$path_words) else "",
                            if (sh$vote_due) "; an election is due this quarter" else ""))
  lines <- c(lines, sprintf("  Public      expected inflation %s%s%s%s", n2(p$expected_inflation),
                            if (!is.na(p$perceived_aim)) sprintf("; perceived aim %+.2f (%+.2f)", p$perceived_aim, p$aim_change) else "",
                            if (!is.na(p$trust)) sprintf("; trust %s", n2(p$trust)) else "",
                            if (p$spell > 0) sprintf("; the public expects the rate at zero for %s", plural(p$spell, "quarter")) else ""))
  lines <- c(lines, sprintf("  Word        %s", if (!w$has_path && !w$judged) "no announcement" else paste0(
    if (w$has_path) sprintf("standing path %s", paste(sprintf("q%d %s", w$path$q, n2(w$path$rate)), collapse = ", ")) else "no standing path",
    if (w$judged) sprintf("; last quarter judged: announced %s, set %s, %s", n2(w$announced), n2(w$set), if (w$kept) "kept" else "broken") else "",
    if (w$news) sprintf("; room this quarter %+.2f, ahead %s", w$room_due, paste(sprintf("%+.2f", w$room), collapse = " ")) else "")))
  if (!is.null(g)) lines <- c(lines, sprintf("  Government  spending %s percent of normal (%+.1f); %s in office; poll %s; election in %s%s%s",
                            n1(g$purchases), g$purchases_change, g$party, n1(g$poll), plural(g$next_election, "quarter"),
                            if (g$boost_window) "; boost window" else "", if (g$vote_held) paste0("; ", g$vote_result) else ""))
  lines <- c(lines, sprintf("  Drivers     output: %s; inflation: %s", d$output, d$inflation))
  lines <- c(lines, sprintf("  Pressing    %s", if (is.na(pr$variable)) "none" else sprintf("%s %s its normal by %.2f, %s", pr$variable, pr$direction, abs(pr$distance), pr$severity)))
  l <- sheet$law
  lines <- c(lines, sprintf("  Law         target %s; trend growth %s; natural unemployment %s; floor %s; H %d; cone width %s; election every %d quarters; boost window %d; wage normal %s; weight on output %s",
                            n1(l$target), n1(l$trend_growth), n1(l$natural_unemployment), n1(l$floor), l$H, n2(l$cone_width), l$election_interval, l$boost_window, n1(l$wage_normal), n2(l$weight_on_output)))
  lines
}
