# 01_Engine/combination/system.R — A.7 "The Full System": the stages' equations assembled at a configuration

# A.7, "The Full System": (A32), (A33), (A34) and (A35) as matrices, with (A16) and the natural levels of (A27)
full_system <- function(config, quarter, horizon) {
  par <- config$par
  is  <- par$s_C / par$sigma
  w   <- wage_block(par)
  s <- c(a = quarter$exo$a, a_lag = quarter$state$shocks$a, z = quarter$exo$z, nu = quarter$exo$nu,
         aim = quarter$aim)
  P <- diag(c(par$rho_a, 0, par$rho_z, par$rho_nu, 1))
  dimnames(P) <- list(names(s), names(s))
  P["a_lag", "a"] <- 1
  L <- rbind(nu    = c(0, 0, 0, 1, 0),
             r_e   = c(natural_rate_gov(1, 0, 0, 0, par), 0, natural_rate_gov(0, 1, 0, 0, par), 0, 0),
             const = c(0, 0, 0, 0, 1 - par$phi_pi))
  psi_wa   <- natural_real_wage(1, natural_output(1, 0, par), par)
  L_domega <- c(psi_wa, -psi_wa, 0, 0, 0)
  d <- foreseen_path(quarter$exo$d_path, horizon)
  G <- if (is.null(quarter$gov)) numeric(horizon + 3)
       else c(quarter$gov$G_prev, quarter$exo$G_hat,
              expected_purchases(quarter$gov, quarter$poll_share, horizon + 1, par))
  omega_n_G <- function(G_hat) natural_real_wage(0, natural_output(0, G_hat, par), par)
  coef <- list(A  = rbind(w$pcp$A, w$pcw$A, c(1, 0, 0, is)),
               B  = rbind(w$pcp$B, w$pcw$B, c(1, is, 0)),
               c  = c(w$pcp$c, w$pcw$c, 0),
               D  = rbind(c(1, 0, 0), c(0, 0, 0), c(0, is, 0)),
               dX = c(0, -1, 1, 0),
               rule  = list(A = c(-par$phi_y, -par$phi_pi, -par$phi_w, 1), D = c(0, par$rn_weight, 1)),
               i_min = par$i_min)
  quarters <- vector("list", horizon + 1)
  s_j <- s
  for (j in 0:horizon) {
    e <- drop(L %*% s_j)
    e[["r_e"]] <- e[["r_e"]] + d[j + 1] + natural_rate_gov(0, 0, G[j + 2], G[j + 3], par)
    quarters[[j + 1]] <- list(s = s_j, e = e,
                              d_omega_n = sum(L_domega * s_j) + omega_n_G(G[j + 2]) - omega_n_G(G[j + 1]))
    s_j <- drop(P %*% s_j)
  }
  list(coef = coef, exo = list(s = s, P = P, L = L, L_domega = L_domega), quarters = quarters)
}
