# 01_Engine/stage3_floor/stage3.R — A.3 "Stage 3: The Floor": the floor, the rule at the floor, foreseen paths and the expected spell

# (A11): the nominal rate cannot fall below zero
floor_level <- function(floor_year, par) from_year(floor_year) - steady_state(par)$i_star

# (A12): the rule's rate at the floor as the public believes it
rule_at_floor <- function(i_min, i_notional) pmax(i_min, i_notional)

# (A13): the foreseen path of the natural rate
foreseen_path <- function(d_path, horizon) c(d_path, numeric(horizon + 1))[seq_len(horizon + 1)]

# A.3, "Expectations at the Floor": the spell the public expects the floor to bind, found over the regimes
floor_spell <- function(sys, omega_t, announced) {
  k  <- sys$coef
  H  <- length(sys$quarters) - 1
  m  <- length(announced)
  rs <- reference_solution(sys)
  terminal <- list(c = drop(rs$F %*% (sys$exo$P %*% sys$quarters[[H + 1]]$s)), M = rs$G)
  regimes  <- c(rep("plan", m), rep("rule", H - m))
  for (guess in 1:100) {
    rules <- vector("list", H)
    ahead <- terminal
    for (j in H:1) {
      rules[[j]] <- switch(regimes[j],
                           plan  = decision_rule(sys, sys$quarters[[j + 1]], ahead, "rate", announced[j]),
                           floor = decision_rule(sys, sys$quarters[[j + 1]], ahead, "rate", k$i_min),
                           rule  = decision_rule(sys, sys$quarters[[j + 1]], ahead, "rule", NA))
      ahead <- list(c = rules[[j]][1:3, "c"], M = rules[[j]][1:3, "M"])
    }
    omega    <- omega_t
    notional <- numeric(H)
    for (j in 1:H) {
      q <- sys$quarters[[j + 1]]
      u <- drop(rules[[j]] %*% c(1, omega))
      notional[j] <- sum(-k$rule$A[1:3] * u[1:3]) + sum(k$rule$D * q$e)
      omega <- omega + u[["pi_w"]] - u[["pi_p"]] - q$d_omega_n
    }
    confirmed <- ifelse(seq_len(H) <= m, "plan", ifelse(notional < k$i_min, "floor", "rule"))
    if (identical(confirmed, regimes))
      return(list(regimes = regimes, rule = ahead,
                  rates = c(announced, rule_at_floor(k$i_min, notional[seq_len(H) > m]))))
    regimes <- confirmed
  }
  stop("the floor spell did not settle in 100 guesses")
}
