# 02 Reductions (Section 3.2: the baseline once an extension is switched off;
# Section 3.3, rule 1). Each of Stages 2 to 6 at its neutral value ("Neutral
# Value and Parameters" of each stage) reproduces Stage 1, checked against
# Stage 1's closed forms of "Policy and the Player" quarter by quarter: given
# the player's rate, x = -(i - r^n)/sigma and pi = kappa x with r^n of
# (A3), since from the next quarter on the public expects the rule's
# outcome. Game set, a term of 12 quarters, the length of a topic, of seeded
# technology and demand innovations of Galí's sizes, and a player who holds
# the steady-state rate of 5 percent, so that the gap, inflation and the real
# wage gap all move and every block does work. Each row reports the largest
# absolute difference, the gap in percent and inflation in points a year.
# Run from the main folder.
for (f in list.files("01_Engine", pattern = "[.]R$", recursive = TRUE, full.names = TRUE)) source(f)

set.seed(5)
T      <- 12
script <- list(eps_a = rnorm(T, sd = 1), eps_z = rnorm(T, sd = 0.5), eps_nu = numeric(T), eps_g = numeric(T), draws = numeric(T))
start  <- list(omega_gap = 0, shocks = list(a = 0, z = 0, nu = 0), d_path = numeric(0), aim = 0, chi = 0.9,
               gov = list(party = 1, g_base = 0, standing = 0, tau = 0, to_election = 8))
hold   <- data.frame(rate = rep(5, T))

# the stage's neutral value on the configuration of Stage 1 with the stage:
# the cost-push innovations are zero in the script; the others are set here
neutral <- function(stage) {
  config <- configure(on = c(1, stage), set = "game")
  if (stage == 3) config$par$i_min <- -Inf                                   # a floor at minus infinity, no path
  if (stage == 4) { config$par$theta_w <- 0; config$par$lambda_w <- Inf }   # flexible wages
  if (stage == 5) config$par$k <- 0                                          # a public that never revises its view, no word
  if (stage == 6) config$par$s_C <- 1                                        # a share of government spending of zero
  config
}
# the largest difference from the closed forms of "Policy and the Player"
against_stage1 <- function(config) {
  q   <- play(config, start, script, hold)$quarters
  par <- config$par
  i   <- from_year(q$rate) - steady_state(par)$i_star
  x   <- -(i - natural_rate(from_percent(q$a), from_percent(q$z), par)) / par$sigma
  max(abs(q$x - to_percent(x)), abs(q$pi_p - to_year(par$pi_bar + par$kappa * x)))
}

value <- c()
value["Stage 2 at its neutral value, a shock that stays at zero"]              <- against_stage1(neutral(2))
value["Stage 3 at its neutral value, the floor at minus infinity and no path"] <- against_stage1(neutral(3))
value["Stage 4 at its neutral value, flexible wages"]                          <- against_stage1(neutral(4))
value["Stage 5 at its neutral value, k = 0, a zero aim and no word"]           <- against_stage1(neutral(5))
value["Stage 6 at its neutral value, a share of government spending of zero"]            <- against_stage1(neutral(6))

table <- data.frame(reduction = names(value), largest_difference = unname(value))
print(table, digits = 2, right = FALSE)
writeLines(c("| Reduction, against Stage 1's closed forms of Policy and the Player | Largest absolute difference |", "|---|---|",
             sprintf("| %s | %.1e |", table$reduction, table$largest_difference), "",
             "Tolerance: rounding error. Game set, a term of 12 quarters of seeded innovations, a player holding 5 percent."),
           "03_Verification/results/02_reductions.md")
