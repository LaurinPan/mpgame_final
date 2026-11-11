# 01_Engine/stage6_government/stage6.R — A.6 "Stage 6: Government, Parties, and Elections": spending, the natural levels with it, the standing, the poll and the election

# (A29): the party in office sets government spending
purchases <- function(gov, eps_g, par) {
  g_base <- par$rho_g * gov$g_base + (1 - par$rho_g) * par$stances[gov$party] + eps_g
  e      <- gov$to_election <= par$q_b
  list(g_base = g_base, e = e, G_hat = (1 - par$s_C) * (g_base + par$boosts[gov$party] * e))
}

# A.6, "Parties and Elections" and "The Poll": the path of government spending the public expects
expected_purchases <- function(gov, P, horizon, par) {
  other  <- 3 - gov$party
  stance <- c(before = par$stances[gov$party], after = P * par$stances[gov$party] + (1 - P) * par$stances[other])
  boost  <- c(before = par$boosts[gov$party],  after = P * par$boosts[gov$party]  + (1 - P) * par$boosts[other])
  k <- gov$to_election; voted <- FALSE; g_base <- gov$g_base
  G <- numeric(horizon)
  for (j in seq_len(horizon)) {
    voted  <- voted || k == 1
    k      <- if (k == 1) par$T_e else k - 1
    phase  <- if (voted) "after" else "before"
    g_base <- par$rho_g * g_base + (1 - par$rho_g) * stance[[phase]]
    G[j]   <- (1 - par$s_C) * (g_base + boost[[phase]] * (k <= par$q_b))
  }
  G
}

# (A27): natural output with government spending
natural_output <- function(a, G_hat, par) {
  D <- par$sigma / par$s_C + (par$phi + par$alpha) / (1 - par$alpha)
  ((1 + par$phi) / (1 - par$alpha) * a + par$sigma / par$s_C * G_hat) / D
}

# (A28): the natural rate of interest with government spending
natural_rate_gov <- function(a, z, G_now, G_next, par) {
  d_y_n <- natural_output(par$rho_a * a, G_next, par) - natural_output(a, G_now, par)
  par$sigma / par$s_C * (d_y_n - (G_next - G_now)) + (1 - par$rho_z) * z
}

# (A31): the standing of the party in office
standing <- function(S, D, e, boosting, tau, par) {
  w <- if (!e) par$eta * D else if (boosting && tau >= 1) par$eta_e * abs(D) else par$eta_e * D
  par$rho_m * S - w
}

# (A30): the share of the party in office
poll <- function(S, tau, par) 1 / (1 + exp(-(S - par$eta_f * tau)))

# A.6, "The Poll": the election at the end of its quarter, drawn with the poll
election <- function(gov, S, P, draw, par) {
  if (draw < P) list(party = gov$party, standing = S, tau = gov$tau + 1)
  else list(party = 3 - gov$party, standing = -(S - par$eta_f * gov$tau), tau = 0)
}
