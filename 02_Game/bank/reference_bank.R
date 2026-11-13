# 02_Game/bank/reference_bank.R — A.8 "The Reference Bank": the bank's problem (A36) solved each quarter on the player's information

# A.8, "Solving the Problem": the term simulated under a plan, the mandate's discounted loss plus the cost on rate changes (A36)
simulate_plan <- function(config, quarter, rates, word, horizon, previous, lambda_i = consts$lambda_i) {
  par <- config$par; m <- length(rates)
  pi <- x <- numeric(horizon); loss <- 0; q <- quarter
  for (j in seq_len(horizon)) {
    decision <- if (j <= m) list(rate = rates[j], announce = if (j == 1 && word && m > 1) rates[-1]) else list(rate = "rule")
    o <- solve_quarter(config, q, decision)
    pi[j] <- o$pi_p; x[j] <- o$x; loss <- loss + par$beta^(j - 1) * o$loss
    if (j < horizon) q <- begin_quarter(config, end_of_quarter(config, q, o), list(a = 0, z = 0, nu = 0, g = 0, draw = 0.5))
  }
  loss <- loss + sum(change_weights(lambda_i, horizon, par) * rate_changes(rates, previous, horizon, par)^2)
  list(pi = pi, x = x, loss = loss)
}

# (A36): the plan's rate changes over min(H, h) quarters from p_0, in the engine's units
rate_changes   <- function(rates, previous, horizon, par) from_year(diff(c(previous, rates[seq_len(min(par$H, horizon))])))

# (A36): the weights lambda_i beta^(j - 1) of the rate changes
change_weights <- function(lambda_i, horizon, par) lambda_i * par$beta^(seq_len(min(par$H, horizon)) - 1)

# A.8, "Solving the Problem": the plan's system solved outright, since the cost on rate changes gives it full rank
plain_solve <- function(A, b) drop(solve(A, b))

# (A25), A.5 "Credibility and the Record" and Section 4.2.1: the boxes the word allows each planned rate, between the floor and the law's cap
word_boxes <- function(config, quarter, state, in_force, word) {
  par <- config$par; H <- par$H
  lo <- rep(0, H); hi <- rep(consts$cap, H)
  if (word) {
    standing <- standing_path(quarter, par)
    r <- news_room(config, quarter, state, in_force)
    room <- c(r$due, r$ahead[seq_len(H - 1)])
    for (k in seq_len(H)) if (!is.na(standing[k])) {
      h <- if (k == 1) 1 else k - 1
      lo[k] <- max(0, standing[k] + min(0, room[k]) - cone(h, par))
      hi[k] <- min(consts$cap, standing[k] + max(0, room[k]) + cone(h, par))
    }
  }
  list(lo = lo, hi = hi)
}

# A.8, "Solving the Problem": the plan by trial and improvement, the linear system within the word's boxes, at most five rounds, the rates beyond the term's end left where they start
bank_plan <- function(config, quarter, word, boxes, horizon, start = NULL, previous = steady_rate(config$par), lambda_i = consts$lambda_i) {
  par <- config$par; H <- par$H
  W <- par$beta^(seq_len(horizon) - 1); w <- c(W, par$vartheta * W, change_weights(lambda_i, horizon, par))
  simulate <- function(rates) tryCatch(simulate_plan(config, quarter, rates, word, horizon, previous, lambda_i),
                                       error = function(e) list(pi = numeric(horizon), x = numeric(horizon), loss = Inf))
  value <- function(sim, rates) c(sim$pi, sim$x, rate_changes(rates, previous, horizon, par))
  n <- length(w)
  clip  <- function(r) pmin(pmax(r, boxes$lo), boxes$hi)
  rule_path <- function() {
    o <- solve_quarter(config, quarter, list(rate = "rule"))
    steady_rate(par) + to_year(c(o$i, o$rule_rates[seq_len(H - 1)]))
  }
  r0 <- clip(if (is.null(start)) rule_path() else start)
  base <- simulate(r0)
  if (!is.finite(base$loss) && !is.null(start)) { r0 <- clip(rule_path()); base <- simulate(r0) }
  best <- list(rates = r0, loss = base$loss)
  if (!is.finite(base$loss)) return(best)
  for (round in 1:5) {
    y0 <- value(base, r0)
    J  <- vapply(seq_len(H), function(k) { r <- r0; r[k] <- r[k] + 1; s <- simulate(r)
      if (is.finite(s$loss)) value(s, r) - y0 else numeric(n) }, numeric(n))
    free <- seq_len(H) <= min(H, horizon); d <- numeric(H)
    for (pass in seq_len(H + 1)) {
      if (!any(free)) break
      Jf <- J[, free, drop = FALSE]
      d[free] <- plain_solve(t(Jf) %*% (w * Jf), -t(Jf) %*% (w * (y0 + J[, !free, drop = FALSE] %*% d[!free])))
      r <- r0 + d; out <- (r < boxes$lo - 1e-9 | r > boxes$hi + 1e-9) & free
      if (!any(out)) break
      d[out] <- clip(r)[out] - r0[out]; free[out] <- FALSE
    }
    r <- clip(r0 + d)
    predicted <- sum(w * (y0 + J %*% (r - r0))^2)
    at <- simulate(r)
    if (!is.finite(at$loss)) break
    if (at$loss < best$loss) best <- list(rates = r, loss = at$loss)
    if (abs(at$loss - predicted) <= 0.02 * max(at$loss, 1e-12) && at$loss <= base$loss + 1e-12) break
    r0 <- r; base <- at
  }
  best
}

# A.8, "Solving the Problem": last quarter's plan moved on by one quarter
shifted <- function(plan) if (is.null(plan)) NULL else c(plan$rates[-1], plan$rates[length(plan$rates)])

# A.8, "What the Bank Knows": the bank's own run advanced by quarter q on the fair quarter, from its own rate of the quarter before
bank_run <- function(run, q) {
  config <- run$config; par <- config$par
  bank <- run$bank
  if (is.null(bank)) bank <- list(decisions = list(), quarters = NULL, states = list(run$states[[1]]), plans = list())
  word  <- word_on(run$script)
  state <- bank$states[[q]]
  fair  <- fair_quarter(run, q, state = state)
  in_force <- if (q > 1) bank$quarters$rate[q - 1] else steady_rate(par)
  plan  <- bank_plan(config, fair, word, word_boxes(config, fair, state, in_force, word), run$T - q + 1,
                     if (q > 1) shifted(bank$plans[[q - 1]]), previous = in_force)
  bank$decisions[[q]] <- list(rate = plan$rates[1], announce = if (word) plan$rates[-1])
  out <- play(config, run$start, term_script(run, q), policy_of(bank$decisions))
  bank$quarters <- out$quarters; bank$states[[q + 1]] <- out$state; bank$plans[[q]] <- plan
  run$bank <- bank
  run
}
