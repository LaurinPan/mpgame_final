# 03 Galí's Table 6.1 (Section 3.2: the sources' published results, to their
# printed digits; Galí, 2015, Ch. 6, Section 6.5). Stage 4 on the source set
# under Galí's six simple rules, the engine's values beside his printed
# ones, the 48 cells of both panels. The Optimal column needs the Ramsey
# policy, which the engine does not contain. The rules are test-only
# coefficients of the believed rule: no natural-rate term (rn_weight), no
# gap term, 1.5 on price, wage or composite inflation (phi_w). Two
# conventions follow Galí's own table:
# the strict rules use a coefficient of 1000 in place of 1.5, and the
# printed digits are read as truncated, not rounded. Standard deviations and
# the loss of Eq. 29 follow analytically from the reference solution: the
# state (omega_{t-1}, s_t) is a first-order autoregression whose covariance
# solves the Lyapunov equation, with innovations of 0.01 to technology in the
# first panel and to demand in the second; the perceived aim of Stage 5, a
# constant of zero here, is left out of it. Units: standard deviations in
# percent, 100 times the quarterly rates; the loss in percent of
# steady-state consumption, 100 times Eq. 29. The line under the table gives
# the exact limit of strict price targeting under technology shocks. Run
# from the main folder.
for (f in list.files("01_Engine", pattern = "[.]R$", recursive = TRUE, full.names = TRUE)) source(f)

config  <- configure(on = c(1, 4), set = "source")
par     <- config$par
quarter <- begin_quarter(config, list(omega_gap = 0, shocks = list(a = 0, z = 0, nu = 0)),
                         list(a = 0, z = 0, nu = 0))
config$par$rn_weight <- 0
config$par$phi_y     <- 0
share_p <- par$lambda_w / (par$lambda + par$lambda_w)   # composite inflation's weight on price inflation
share_w <- par$lambda / (par$lambda + par$lambda_w)     # and on wage inflation
strict  <- 1000
rules <- list("Strict price" = c(strict, 0), "Strict wage" = c(0, strict), "Strict composite" = strict * c(share_p, share_w),
              "Flexible price" = c(1.5, 0), "Flexible wage" = c(0, 1.5), "Flexible composite" = 1.5 * c(share_p, share_w))
printed <- list(
  technology = rbind("sd(pi^p)"  = c("0", "0.13", "0.12", "0.29", "0.24", "0.24"),
                     "sd(pi^w)"  = c("0.26", "0", "0.02", "0.23", "0.16", "0.16"),
                     "sd(y gap)" = c("3.38", "0.20", "0", "0.84", "1.18", "1.11"),
                     "loss"      = c("0.78", "0.039", "0.0337", "0.47", "0.305", "0.307")),
  demand     = rbind("sd(pi^p)"  = c("0", "0", "0", "0.02", "0.04", "0.03"),
                     "sd(pi^w)"  = c("0", "0", "0", "0.05", "0.06", "0.06"),
                     "sd(y gap)" = c("0", "0", "0", "1.08", "1.05", "1.06"),
                     "loss"      = c("0", "0", "0", "0.061", "0.067", "0.066")))
printed <- lapply(printed, function(m) { colnames(m) <- names(rules); m })

# sd(pi^p), sd(pi^w), sd(y gap) and the loss under a rule, in the table's units
moments <- function(phi_pi, phi_w, shock) {
  config$par$phi_pi <- phi_pi
  config$par$phi_w  <- phi_w
  sys  <- full_system(config, quarter, 1)
  rs   <- reference_solution(sys)
  d    <- sys$coef$dX[1:3]
  keep <- names(sys$exo$s) != "aim"
  # the state S = (omega_{t-1}, s_t): omega_t = lambda omega_{t-1} + (d'F - L_domega) s_t, E s' = P s
  Tm  <- rbind(c(rs$root, (drop(d %*% rs$F) - sys$exo$L_domega)[keep]), cbind(0, sys$exo$P[keep, keep]))
  Q   <- matrix(0, nrow(Tm), nrow(Tm))
  idx <- 1 + match(shock, names(sys$exo$s)[keep])
  Q[idx, idx] <- 0.01^2
  Sigma <- matrix(solve(diag(nrow(Tm)^2) - kronecker(Tm, Tm), as.vector(Q)), nrow(Tm))   # Lyapunov
  GF    <- cbind(rs$G, rs$F[, keep])                           # X_t = G omega_{t-1} + F s_t
  V     <- GF %*% Sigma %*% t(GF)                               # var(x, pi_p, pi_w)
  L     <- 0.5 * ((par$sigma + (par$phi + par$alpha) / (1 - par$alpha)) * V[1, 1] +
                  par$epsilon / par$lambda * V[2, 2] +
                  par$epsilon_w * (1 - par$alpha) / par$lambda_w * V[3, 3])   # Galí's Eq. 29
  100 * c(sqrt(V[2, 2]), sqrt(V[3, 3]), sqrt(V[1, 1]), L)
}
truncated <- function(v, digits) formatC(trunc(v * 10^digits + 1e-9) / 10^digits, format = "f", digits = digits)

lines <- c()
for (panel in c("technology", "demand")) {
  cells <- matrix("", 4, 6, dimnames = list(rownames(printed[[panel]]), names(rules)))
  for (r in names(rules)) {
    values <- moments(rules[[r]][1], rules[[r]][2], if (panel == "technology") "a" else "z")
    digits <- nchar(sub("^[^.]*[.]?", "", printed[[panel]][, r]))              # the decimals Galí prints
    cells[, r] <- sprintf("%s (%s)", mapply(truncated, values, digits), printed[[panel]][, r])
  }
  lines <- c(lines, sprintf("**%s shocks**: engine value truncated to the printed digits, Galí's printed value in brackets", panel), "",
             paste("|", paste(c("", colnames(cells)), collapse = " | "), "|"),
             paste("|", paste(rep("---", 7), collapse = " | "), "|"),
             sprintf("| %s | %s |", rownames(cells), apply(cells, 1, paste, collapse = " | ")), "")
}
limit <- moments(1e6, 0, "a")
lines <- c(lines, sprintf("Strict price targeting under technology shocks in the exact limit (coefficient 1e6): sd(pi^w) %.4f, sd(y gap) %.4f, loss %.4f.",
                          limit[2], limit[3], limit[4]),
           "", "Tolerance: the printed digits, read as truncated; the strict rules at a coefficient of 1000.")
writeLines(lines, "03_Verification/results/03_gali_table_6_1.md")
cat(lines, sep = "\n")
