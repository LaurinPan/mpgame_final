# 01_Engine/stage4_wages/parameters.R — A.4 "Neutral Value and Parameters": the wage parameters added to the table

# A.4, "Neutral Value and Parameters": Gali's wage parameters and the rule's response to wage inflation (A35)
stage4_parameters <- function(par1, theta_w, epsilon_w, varsigma) {
  list(theta_w = theta_w, epsilon_w = epsilon_w, varsigma = varsigma,
       lambda_w = (1 - theta_w) * (1 - par1$beta * theta_w) / (theta_w * (1 + epsilon_w * par1$phi)),
       u_n = log(epsilon_w / (epsilon_w - 1)) / par1$phi,
       phi_w = 0)
}

# A.4, "Neutral Value and Parameters": the source set
stage4_source <- stage4_parameters(stage1_source, theta_w = 3/4, epsilon_w = 4.5, varsigma = 0.005)

# A.4, "Neutral Value and Parameters": the game set
stage4_game   <- stage4_parameters(stage1_game,   theta_w = 3/4, epsilon_w = 4.5, varsigma = 0.005)
