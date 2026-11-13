# 02_Game/bank/marks.R — Section 4.2.2: the debrief's marks

# Section 4.2.2: a decision's cost, the discounted term loss (A36) of the player's path less the same path with the bank's decision in that quarter
decision_costs <- function(run, record) {
  config <- run$config; par <- config$par; T <- run$T
  word   <- word_on(run$script)
  within <- classes$thresholds$immediate_within
  w <- par$beta^(seq_len(T) - 1); player <- consts$loss_scale * run$quarters$loss
  rows <- list(); later <- list()
  for (k in setdiff(record$covers, record$guided)) {
    fair <- fair_quarter(run, k)
    in_force <- if (k > 1) run$quarters$rate[k - 1] else steady_rate(par)
    plan <- bank_plan(config, fair, word, word_boxes(config, fair, run$states[[k]], in_force, word), T - k + 1, previous = in_force)
    altered <- run$decisions
    altered[[k]] <- list(rate = plan$rates[1], announce = if (word) plan$rates[-1])
    d <- player - consts$loss_scale * play(config, run$start, term_script(run, T), policy_of(altered))$quarters$loss
    rows[[length(rows) + 1]] <- data.frame(q = k, cost = sum((w * d)[k:T]),
                                           kind = if (sum((w * d)[k:min(T, k + within - 1)]) > 0) "immediate" else "deferred",
                                           bank_rate = plan$rates[1], player_rate = run$quarters$rate[k], weight = w[k])
    later[[as.character(k)]] <- which(d > 0 & seq_len(T) > k + within - 1)
  }
  list(table = do.call(rbind, rows), later = later)
}

# Section 4.2.2: a decision is marked when its cost is at least 0.5 squared points and, where the player's term loss exceeds the bank's, above a tenth of the excess; of these, at most the three costliest, each with its equivalent miss, the inflation miss that would cost as much in its quarter
debrief_marks <- function(costs, term_loss_player, term_loss_bank) {
  tab <- costs$table
  if (is.null(tab)) return(list())
  excess <- term_loss_player - term_loss_bank
  tab <- tab[tab$cost >= classes$thresholds$mark_min & (excess <= 0 | tab$cost > classes$thresholds$mark_share * excess), , drop = FALSE]
  tab <- tab[order(-tab$cost), , drop = FALSE][seq_len(min(classes$thresholds$marks_max, nrow(tab))), , drop = FALSE]
  tab <- tab[order(tab$q), , drop = FALSE]
  lapply(seq_len(nrow(tab)), function(i) {
    k <- tab$q[i]
    list(q = k, kind = tab$kind[i], cost = tab$cost[i], equivalent = sqrt(tab$cost[i] / tab$weight[i]), bank_rate = tab$bank_rate[i], player_rate = tab$player_rate[i],
         shaded = if (tab$kind[i] == "deferred") costs$later[[as.character(k)]] else integer(0))
  })
}
