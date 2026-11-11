# 01_Engine/stage1_baseline/parameters.R — A.1 "Steady State, Trend, and Parameters": the units and the parameter table of Stage 1

# A.1, "Steady State, Trend, and Parameters": a quarterly decimal as percent a year
to_year      <- function(x) 400 * x

# A.1, "Steady State, Trend, and Parameters": percent a year as a quarterly decimal
from_year    <- function(x) x / 400

# A.1, "Steady State, Trend, and Parameters": a decimal as percent
to_percent   <- function(x) 100 * x

# A.1, "Steady State, Trend, and Parameters": percent as a decimal
from_percent <- function(x) x / 100

# A.1, "Steady State, Trend, and Parameters": the parameter table with its composites, the slope of (A1) and the weight of (A5)
stage1_parameters <- function(beta, sigma, phi, alpha, epsilon, theta,
                              phi_pi, phi_y, rho_a, rho_z, pi_bar, g) {
  lambda <- (1 - theta) * (1 - beta * theta) / theta *
            (1 - alpha) / (1 - alpha + alpha * epsilon)
  kappa  <- lambda * (sigma + (phi + alpha) / (1 - alpha))
  list(beta = beta, sigma = sigma, phi = phi, alpha = alpha, epsilon = epsilon,
       theta = theta, phi_pi = phi_pi, phi_y = phi_y, rho_a = rho_a, rho_z = rho_z,
       pi_bar = from_year(pi_bar), g = from_year(g),
       rho = -log(beta), lambda = lambda, kappa = kappa,
       psi_ya = (1 + phi) / (sigma * (1 - alpha) + phi + alpha),
       vartheta = kappa / epsilon,
       rn_weight = 1)
}

# A.1, "Steady State, Trend, and Parameters": Gali's source set
stage1_source <- stage1_parameters(beta = 0.99, sigma = 1, phi = 5, alpha = 1/4,
                                   epsilon = 9, theta = 3/4, phi_pi = 1.5, phi_y = 0.125,
                                   rho_a = 0.9, rho_z = 0.5, pi_bar = 0, g = 0)

# A.1, "Steady State, Trend, and Parameters": the game set
stage1_game   <- stage1_parameters(beta = exp(-0.0025), sigma = 1, phi = 5, alpha = 1/4,
                                   epsilon = 9, theta = 3/4, phi_pi = 1.5, phi_y = 0.125,
                                   rho_a = 0.9, rho_z = 0.5, pi_bar = 2, g = 2)
