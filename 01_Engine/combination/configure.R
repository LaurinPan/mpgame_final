# 01_Engine/combination/configure.R — A.7 "The Game's Configurations": which stages are on, with each stage off at its neutral value

# A.7, "The Game's Configurations": the configuration of a set of stages at the source or game set, a stage off at its neutral value
configure <- function(on, set) {
  stopifnot(1 %in% on, all(on %in% 1:6))
  par <- c(switch(set, game = stage1_game, source = stage1_source),
           switch(set, game = stage2_game, source = stage2_source),
           switch(set, game = stage4_game, source = stage4_source),
           switch(set, game = stage5_game, source = stage5_source),
           switch(set, game = stage6_game, source = stage6_source))
  par$i_min <- floor_level(if (3 %in% on) 0 else -Inf, par)
  if (!(4 %in% on)) { par$theta_w <- 0; par$lambda_w <- Inf }
  if (!(5 %in% on)) par$k <- 0
  if (!(6 %in% on)) par$s_C <- 1
  stopifnot(if (4 %in% on) taylor_condition_wages(par) else taylor_condition(par))
  list(on = on, par = par)
}
