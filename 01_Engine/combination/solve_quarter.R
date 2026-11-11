# 01_Engine/combination/solve_quarter.R — A.7 "Solving a Quarter": the quarter's equations solved for a decision

# A.7, "Solving a Quarter": the quarters the public's forecasts reach
forecast_horizon <- 40

# A.7, "Solving a Quarter": the quarter's equations, (A32), (A33), (A34) and (A35), with the decision in place of the rule
decision_rule <- function(sys, q, ahead, regime, rate) {
  k  <- sys$coef
  h  <- drop(k$B %*% ahead$M) + k$c
  A  <- rbind(k$A - h %o% k$dX,
              switch(regime, rate = c(0, 0, 0, 1), rule = k$rule$A))
  r0 <- c(drop(k$B %*% ahead$c) + drop(k$D %*% q$e),
          switch(regime, rate = rate, rule = sum(k$rule$D * q$e)))
  rw <- c(h, 0)
  out <- solve(A, cbind(c = r0 - rw * q$d_omega_n, M = rw))
  rownames(out) <- c("x", "pi_p", "pi_w", "i")
  out
}

# A.7, "Solving a Quarter": the quarter's outcome for a decision, with the floor (A11) and the real wage (A16)
solve_quarter <- function(config, quarter, decision) {
  par    <- config$par
  i_star <- steady_state(par)$i_star
  if (!is.null(decision$announce) && !(5 %in% config$on)) stop("announcements need Stage 5")
  word <- if (is.null(decision$announce))
            list(ahead = quarter$word$ahead, revisions = data.frame(h = integer(0), old = numeric(0), new = numeric(0)))
          else announce(quarter$word$ahead, from_year(decision$announce) - i_star, par)
  sys  <- full_system(config, quarter, forecast_horizon)
  q    <- sys$quarters[[1]]
  r_e  <- q$e[["r_e"]]
  rate <- if (identical(decision$rate, "rule")) NA else from_year(decision$rate) - i_star
  if (!is.na(rate) && rate < par$i_min) stop("the rate lies below the floor")
  omega_prev <- quarter$state$omega_gap
  fc    <- forecast(sys, omega_prev, word$ahead, quarter$cred$chi)
  steps <- 0
  repeat {
    sol <- drop(decision_rule(sys, q, fc, if (is.na(rate)) "rule" else "rate", rate) %*% c(1, omega_prev))
    if (is.na(rate) && sol[["i"]] < par$i_min)
      sol <- drop(decision_rule(sys, q, fc, "rate", par$i_min) %*% c(1, omega_prev))
    omega  <- omega_prev + sol[["pi_w"]] - sol[["pi_p"]] - q$d_omega_n
    fc_new <- forecast(sys, omega, word$ahead, quarter$cred$chi)
    if (identical(fc_new$regimes, fc$regimes)) break
    fc <- fc_new
    if ((steps <- steps + 1) > 100) stop("the regimes did not agree in 100 steps")
  }
  i_rule <- rule_at_floor(par$i_min, believed_rule(r_e, sol[["pi_p"]], sol[["x"]], q$e[["const"]], par))
  u      <- par$u_n + unemployment(omega, sol[["x"]], par)
  list(x = sol[["x"]], pi_p = sol[["pi_p"]], pi_w = sol[["pi_w"]], i = sol[["i"]],
       omega_gap = omega, r_e = r_e, i_rule = i_rule,
       v        = deviation(sol[["i"]], i_rule),
       u        = u, U = readout(u, par),
       word     = word$ahead, revisions = word$revisions,
       rule_rates = fc$rates,
       regimes  = fc$regimes[[1]],
       spell    = sum(fc$regimes[[1]] == "floor"),
       expected = fc$c + fc$M * omega,
       loss     = loss(sol[["pi_p"]], sol[["x"]], par))
}
