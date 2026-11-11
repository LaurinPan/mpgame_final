# 01_Engine/stage2_costpush/stage2.R — A.2 "Stage 2: Cost-Push Shocks": the shock in the price Phillips curve (A6), the rule and the loss as in Stage 1

# (A7): the cost-push shock follows a first-order autoregression
costpush_shock <- function(nu_prev, eps_nu, par) par$rho_nu * nu_prev + eps_nu
