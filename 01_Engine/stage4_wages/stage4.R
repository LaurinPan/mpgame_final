# 01_Engine/stage4_wages/stage4.R — A.4 "Stage 4: Sticky Wages and Unemployment": the wage block, the Taylor condition, unemployment and the reference solution

# A.4, "Equations", and A.7, "Where Stages Meet": the natural real wage and its change
natural_real_wage <- function(a, y_n, par) (a - par$alpha * y_n) / (1 - par$alpha)

# (A14) and (A15) as rows of the system, each as its coefficients
wage_block <- function(par) {
  slope <- par$sigma / par$s_C + par$phi / (1 - par$alpha)
  list(pcp = list(A = c(-par$alpha * par$lambda / (1 - par$alpha), 1, 0, 0),
                  B = c(0, par$beta, 0), c = par$lambda),
       pcw = if (par$theta_w == 0)
               list(A = c(-slope, 0, 0, 0), B = c(0, 0, 0), c = -1)
             else
               list(A = c(-par$lambda_w * slope, 0, 1, 0), B = c(0, 0, par$beta), c = -par$lambda_w))
}

# A.4, "Policy and the Player": with sticky wages the equilibrium is unique if and only if the rule responds enough to inflation
taylor_condition_wages <- function(par) {
  par$phi_pi + par$phi_y * (1 - par$beta) / (par$sigma + (par$alpha + par$phi) / (1 - par$alpha)) *
    (1 / par$lambda + 1 / par$lambda_w) > 1
}

# (A18): the unemployment gap from the real wage gap and the output gap
unemployment <- function(omega_gap, x, par) {
  (omega_gap - (par$sigma / par$s_C + par$phi / (1 - par$alpha)) * x) / par$phi
}

# (A19): the reported unemployment rate, smooth and never negative
readout <- function(u, par) pmax(u, 0) + par$varsigma * log1p(exp(-abs(u) / par$varsigma))

# (A17): the reference solution under the believed rule by undetermined coefficients
reference_solution <- function(sys) {
  k <- sys$coef; ex <- sys$exo
  a_i   <- -k$rule$A[1:3]
  A_bar <- k$A[, 1:3] + k$A[, 4] %o% a_i
  D_bar <- k$D - k$A[, 4] %o% k$rule$D
  d     <- k$dX[1:3]
  A2    <- A_bar - k$c %o% d
  B     <- k$B
  g     <- function(l) det(A2 - l * B) * ((l - 1) - sum(d * solve(A2 - l * B, k$c)))
  nodes <- c(-1.7, -0.9, -0.1, 0.7, 1.5)
  coefs <- solve(outer(nodes, 0:4, "^"), sapply(nodes, g))
  coefs <- coefs[seq_len(max(which(abs(coefs) > 1e-10 * max(abs(coefs)))))]
  stable <- Filter(function(r) abs(r) < 1, polyroot(coefs))
  if (length(stable) != 1) stop("no unique stable solution (Blanchard and Kahn, 1980)")
  lambda <- Re(stable[[1]])
  G <- solve(A2 - lambda * B, k$c)
  M <- solve(A2 - (B %*% G) %*% t(d))
  R <- M %*% (D_bar %*% ex$L - (drop(B %*% G) + k$c) %o% ex$L_domega)
  n <- length(ex$s)
  F <- matrix(solve(diag(3 * n) - kronecker(t(ex$P), M %*% B), as.vector(R)), 3, n,
              dimnames = list(c("x", "pi_p", "pi_w"), names(ex$s)))
  list(F = F, G = G, root = lambda)
}
