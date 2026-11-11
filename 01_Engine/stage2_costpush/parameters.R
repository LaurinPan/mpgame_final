# 01_Engine/stage2_costpush/parameters.R — A.2 "Neutral Value and Parameters": the cost-push shock's persistence added to Stage 1's table

# A.2, "Neutral Value and Parameters": Stage 1's table with the persistence rho_nu
stage2_parameters <- function(rho_nu) list(rho_nu = rho_nu)

# A.2, "Neutral Value and Parameters": the source set
stage2_source <- stage2_parameters(rho_nu = 0.8)

# A.2, "Neutral Value and Parameters": the game set
stage2_game   <- stage2_parameters(rho_nu = 0.8)
