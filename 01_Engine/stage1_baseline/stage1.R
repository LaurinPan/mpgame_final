# 01_Engine/stage1_baseline/stage1.R — A.1 "Stage 1: The Baseline": the natural rate, the believed rule, the deviation, the loss and the steady state

# (A3): the natural rate of interest, measured from rho + g
natural_rate <- function(a, z, par) {
  -par$sigma * (1 - par$rho_a) * par$psi_ya * a + (1 - par$rho_z) * z
}

# (A4): the rule the public believes the bank follows
believed_rule <- function(r_n, pi, x, v, par) {
  par$rn_weight * r_n + par$phi_pi * pi + par$phi_y * x + v
}

# A.1, "Policy and the Player": the deviation the public reads off the player's rate
deviation <- function(i, i_rule) i - i_rule

# A.1, "Policy and the Player": the condition for a unique stationary equilibrium
taylor_condition <- function(par) {
  par$kappa * (par$phi_pi - 1) + (1 - par$beta) * par$phi_y > 0
}

# (A5): the quarter's loss, the mandate
loss <- function(pi, x, par) pi^2 + par$vartheta * x^2

# A.1, "Steady State, Trend, and Parameters": the steady-state real and nominal rates
steady_state <- function(par) {
  list(r_star = par$rho + par$g, i_star = par$rho + par$g + par$pi_bar)
}
