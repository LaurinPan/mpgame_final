# 01 Closed forms (Section 3.2: closed forms, to rounding error). Each claim
# of the model appendix or of Galí (2015) is checked on the game set; the
# value is the largest absolute difference in the engine's units, quarterly
# decimals. Run from the main folder.
for (f in list.files("01_Engine", pattern = "[.]R$", recursive = TRUE, full.names = TRUE)) source(f)

value <- c()
start <- list(omega_gap = 0, shocks = list(a = 0, z = 0, nu = 0))

# Stage 1, "Policy and the Player" and Section 4.1.1: under the believed rule
# the gap and inflation stay at zero over a term of 12 quarters, the length
# of a topic, of seeded technology and demand innovations of Galí's sizes
# (1 percent, 0.5 points), which is the path of Galí's model from the same shocks
T <- 12
set.seed(2)
script <- list(eps_a = rnorm(T, sd = 1), eps_z = rnorm(T, sd = 0.5), eps_nu = rep(0, T))
config <- configure(on = 1, set = "game")
q <- play(config, start, script, "rule")$quarters
value["Stage 1, (A4) and Policy and the Player: under the believed rule the gap and inflation stay at zero, the path of Galí's model"] <-
  max(abs(from_percent(q$x)), abs(from_year(q$pi_p) - config$par$pi_bar))

# Stage 2, (A9) and (A10): the reference solution's response to
# the cost-push shock, as coefficients
config <- configure(on = c(1, 2), set = "game")
par    <- config$par
Lambda <- 1 / ((1 - par$beta * par$rho_nu) * (par$sigma * (1 - par$rho_nu) + par$phi_y) + par$kappa * (par$phi_pi - par$rho_nu))
F <- reference_solution(full_system(config, begin_quarter(config, start, list(a = 0, z = 0, nu = 0)), 1))$F
value["Stage 2, (A9): the gap's response to the cost-push shock"]      <- abs(F["x", "nu"] + (par$phi_pi - par$rho_nu) * Lambda)
value["Stage 2, (A10): inflation's response to the cost-push shock"] <- abs(F["pi_p", "nu"] - (par$sigma * (1 - par$rho_nu) + par$phi_y) * Lambda)

# The third closed form, discretion (Galí, 2015, Ch. 5, Eqs. 4 to 6, Figure 5.2's rho = 0.8): the
# believed rule with the test-only coefficients phi_pi = rho_nu +
# sigma (1 - rho_nu) kappa / vartheta and phi_y = 0 implements the
# discretionary outcome, and the rule-following player reproduces it under a
# shock of one point a year in quarter 1 of a term of 12 quarters
config$par$phi_pi <- par$rho_nu + par$sigma * (1 - par$rho_nu) * par$kappa / par$vartheta
config$par$phi_y  <- 0
par <- config$par
shock <- list(eps_a = rep(0, T), eps_z = rep(0, T), eps_nu = c(1, rep(0, T - 1)))
q  <- play(config, start, shock, "rule")$quarters
nu <- from_year(q$nu); x <- from_percent(q$x); pi <- from_year(q$pi_p) - par$pi_bar
den <- par$kappa^2 + par$vartheta * (1 - par$beta * par$rho_nu)
value["Galí Ch. 5, Eq. 4: x_t = -(kappa/vartheta) pi_t under discretion"] <- max(abs(x + par$kappa / par$vartheta * pi))
value["Galí Ch. 5, Eq. 5: pi_t = vartheta / (kappa^2 + vartheta (1 - beta rho_nu)) nu_t"] <- max(abs(pi - par$vartheta / den * nu))
value["Galí Ch. 5, Eq. 6: x_t = -kappa / (kappa^2 + vartheta (1 - beta rho_nu)) nu_t"] <- max(abs(x + par$kappa / den * nu))

table <- data.frame(claim = names(value), largest_difference = unname(value))
print(table, digits = 2, right = FALSE)
writeLines(c("| Claim | Largest absolute difference (quarterly decimals) |", "|---|---|",
             sprintf("| %s | %.1e |", table$claim, table$largest_difference), "",
             "Tolerance: rounding error. Game set, terms of 12 quarters."),
           "03_Verification/results/01_closed_forms.md")
