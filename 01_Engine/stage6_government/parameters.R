# 01_Engine/stage6_government/parameters.R — A.6 "Neutral Value and Parameters": the government's parameters added to the table

# A.6, "Neutral Value and Parameters": the share of government spending, its persistence, the stances, the election interval and the voters' weights
stage6_parameters <- function(par1, share, rho_g, stances, T_e, q_b, xi, eta_e, rho_m, eta_f, eta) {
  s_C <- 1 - from_percent(share)
  list(s_C = s_C, rho_g = rho_g, stances = from_percent(stances), boosts = c(from_percent(xi), 0),
       T_e = T_e, q_b = q_b, rho_m = rho_m, eta_f = eta_f, eta = eta, eta_e = eta_e)
}

# A.6, "Neutral Value and Parameters": the boost before a vote, V7's calibration
xi_V7    <- 3.75

# A.6, "Neutral Value and Parameters": the voters' weight before a vote, V7's calibration
eta_e_V7 <- 1.17

# A.6, "Neutral Value and Parameters": the source set
stage6_source <- stage6_parameters(stage1_source, share = 20, rho_g = 0.9, stances = c(5, -5), T_e = 8, q_b = 3,
                                   xi = xi_V7, eta_e = eta_e_V7, rho_m = 0.8, eta_f = 0.07, eta = 0.01)

# A.6, "Neutral Value and Parameters": the game set
stage6_game   <- stage6_parameters(stage1_game,   share = 20, rho_g = 0.9, stances = c(5, -5), T_e = 8, q_b = 3,
                                   xi = xi_V7, eta_e = eta_e_V7, rho_m = 0.8, eta_f = 0.07, eta = 0.01)
