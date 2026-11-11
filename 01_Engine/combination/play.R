# 01_Engine/combination/play.R — A.7 "Solving a Quarter": a quarter's beginning and end, and play(), the entry point of a term

# A.7, "Solving a Quarter": the quarter begins with its innovations ((A7), (A13), (A29)) and a vote's draw
begin_quarter <- function(config, state, innovations) {
  par <- config$par
  on  <- config$on
  d_path <- if (!(3 %in% on)) numeric(0)
            else if (!is.null(innovations$d_path)) from_year(innovations$d_path)
            else state$d_path
  pur <- if (6 %in% on) purchases(state$gov, from_percent(innovations$g), par)
  list(state = state,
       exo   = list(a  = par$rho_a * state$shocks$a + from_percent(innovations$a),
                    z  = par$rho_z * state$shocks$z + from_percent(innovations$z),
                    nu = if (2 %in% on) costpush_shock(state$shocks$nu, from_year(innovations$nu), par) else 0,
                    d_path = d_path, d = foreseen_path(d_path, 0),
                    G_hat = if (6 %in% on) pur$G_hat else 0, e = if (6 %in% on) pur$e else FALSE,
                    draw  = innovations$draw,
                    news  = any(c(innovations$a, innovations$z, innovations$nu, innovations$g) != 0) ||
                            !is.null(innovations$d_path)),
       aim   = if (5 %in% on) state$aim  else 0,
       cred  = if (5 %in% on) state$cred else list(chi = 1, sigma2_hat = 0),
       word  = if (5 %in% on) state$word else list(due = NA, ahead = rep(NA, par$H)),
       gov   = if (6 %in% on) modifyList(state$gov, list(g_base = pur$g_base)),
       poll_share = if (6 %in% on) poll(state$gov$standing, state$gov$tau, par))
}

# A.7, "Solving a Quarter": the state moves on at the quarter's end ((A16), (A21), (A24), (A31), (A30))
end_of_quarter <- function(config, quarter, outcome) {
  par <- config$par
  on  <- config$on
  state  <- list(omega_gap = outcome$omega_gap, shocks = quarter$exo[c("a", "z", "nu")],
                 d_path = quarter$exo$d_path[-1])
  record <- list()
  after  <- quarter
  vote   <- FALSE
  if (6 %in% on) {
    g <- quarter$gov
    D <- to_year(outcome$pi_p) + to_percent(outcome$u - par$u_n)
    S <- standing(g$standing, D, quarter$exo$e, par$boosts[g$party] > 0, g$tau, par)
    vote <- g$to_election == 1
    if (vote) {
      stopifnot(!is.null(quarter$exo$draw))
      P   <- poll(S, g$tau, par)
      new <- election(g, S, P, quarter$exo$draw, par)
      record$election  <- list(poll = P, draw = quarter$exo$draw, winner = new$party)
      after$gov        <- modifyList(g, list(party = new$party, to_election = par$T_e + 1))
      after$poll_share <- P
    } else new <- list(party = g$party, standing = S, tau = g$tau)
    state$gov <- list(party = new$party, g_base = g$g_base, G_prev = quarter$exo$G_hat,
                      standing = new$standing, tau = new$tau,
                      to_election = if (vote) par$T_e else g$to_election - 1)
  }
  if (5 %in% on) {
    const    <- (1 - par$phi_pi) * quarter$aim
    notional <- believed_rule(outcome$r_e, outcome$pi_p, outcome$x, const, par)
    pi_star  <- observed_aim(outcome$i, outcome$r_e, outcome$pi_p, outcome$x, par)
    state$aim <- aim_filter(quarter$aim, pi_star, notional >= par$i_min, par)
    room <- numeric(par$H); room_due <- 0
    if (quarter$exo$news || vote) {
      without    <- full_system(config, begin_quarter(config, quarter$state, list(a = 0, z = 0, nu = 0, g = 0)),
                                forecast_horizon)
      with_rates <- if (vote) floor_spell(full_system(config, after, forecast_horizon), outcome$omega_gap, numeric(0))$rates
                    else outcome$rule_rates
      room     <- to_year(with_rates - floor_spell(without, outcome$omega_gap, numeric(0))$rates)[seq_len(par$H)]
      room_due <- to_year(outcome$i_rule - rule_at_floor(par$i_min,
                    believed_rule(without$quarters[[1]]$e[["r_e"]], outcome$pi_p, outcome$x, const, par)))
    }
    misses <- c(if (!is.na(quarter$word$due)) miss(to_year(outcome$i - quarter$word$due), room_due, 1, par),
                if (nrow(outcome$revisions)) mapply(function(h, old, new) miss(to_year(new - old), room[h], h, par),
                                                   outcome$revisions$h, outcome$revisions$old, outcome$revisions$new))
    state$cred <- if (length(misses)) credibility(quarter$cred, max(misses), par) else quarter$cred
    state$word <- list(due = outcome$word[1], ahead = c(outcome$word[-1], NA))
    record$pi_star <- pi_star
    record$miss    <- if (length(misses)) max(misses) else NA
  }
  state$record <- record
  state
}

# A.7, "Solving a Quarter": the entry point, a term played quarter by quarter under a policy from a start state and a script
play <- function(config, start, script, policy) {
  par <- config$par
  ss  <- steady_state(par)
  on5 <- 5 %in% config$on
  on6 <- 6 %in% config$on
  state <- list(omega_gap = from_percent(start$omega_gap),
                shocks = list(a = from_percent(start$shocks$a), z = from_percent(start$shocks$z),
                              nu = from_year(start$shocks$nu)),
                d_path = from_year(start$d_path))
  if (on5) {
    stopifnot(!is.null(start$chi))
    state$aim  <- from_year(start$aim)
    state$cred <- list(chi = start$chi, sigma2_hat = par$sigma_R^2 * (1 - start$chi) / start$chi)
    state$word <- list(due = NA, ahead = rep(NA, par$H))
  }
  if (on6) {
    g <- from_percent(start$gov$g_base)
    state$gov <- list(party = start$gov$party, g_base = g, G_prev = (1 - par$s_C) * g,
                      standing = start$gov$standing, tau = start$gov$tau, to_election = start$gov$to_election)
  }
  rows <- vector("list", length(script$eps_a))
  for (t in seq_along(rows)) {
    quarter  <- begin_quarter(config, state,
                              list(a = script$eps_a[t], z = script$eps_z[t], nu = script$eps_nu[t],
                                   g = script$eps_g[t], draw = script$draws[t],
                                   d_path = if (isTRUE(script$foreseen$start == t)) script$foreseen$d))
    decision <- if (is.function(policy)) policy(quarter, config)
                else if (identical(policy, "rule")) list(rate = "rule")
                else list(rate = policy$rate[t],
                          announce = if (!is.null(policy$announce)) policy$announce[[t]])
    outcome  <- solve_quarter(config, quarter, decision)
    state    <- end_of_quarter(config, quarter, outcome)
    rows[[t]] <- data.frame(
      t = t, a = to_percent(quarter$exo$a), z = to_percent(quarter$exo$z),
      nu        = to_year(quarter$exo$nu),
      d         = to_year(quarter$exo$d),
      G         = to_percent(quarter$exo$G_hat),
      r_n       = to_year(ss$r_star + outcome$r_e),
      rate      = to_year(ss$i_star + outcome$i),
      i_rule    = to_year(ss$i_star + outcome$i_rule),
      v         = to_year(outcome$v),
      x         = to_percent(outcome$x),
      pi_p      = to_year(par$pi_bar + outcome$pi_p),
      pi_w      = to_year(par$pi_bar + outcome$pi_w),
      omega_gap = to_percent(outcome$omega_gap),
      u         = to_percent(outcome$u),
      U         = to_percent(outcome$U),
      e_x       = to_percent(outcome$expected[1]),
      e_pi_p    = to_year(par$pi_bar + outcome$expected[2]),
      spell     = outcome$spell,
      aim       = if (on5) to_year(state$aim) else NA,
      pi_star   = if (on5) to_year(state$record$pi_star) else NA,
      chi       = if (on5) state$cred$chi else NA,
      miss      = if (on5) state$record$miss else NA,
      word      = paste(round(to_year(ss$i_star + outcome$word[!is.na(outcome$word)]), 2), collapse = " "),
      party     = if (on6) quarter$gov$party else NA,
      boost     = if (on6) quarter$exo$e else NA,
      standing  = if (on6) state$gov$standing else NA,
      poll      = if (on6) poll(state$gov$standing, state$gov$tau, par) else NA,
      tau       = if (on6) state$gov$tau else NA,
      election  = if (on6 && !is.null(state$record$election)) state$record$election$winner else NA,
      vote_poll = if (on6 && !is.null(state$record$election)) state$record$election$poll else NA,
      loss      = outcome$loss)
  }
  list(quarters = do.call(rbind, rows), state = state)
}
