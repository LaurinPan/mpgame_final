# 01_Engine/stage5_learning/stage5.R — A.5 "Stage 5: Learning and the Bank's Word": the aim the public reads, the word, its survival, the band and trust

# (A20): the aim the public reads off the rate
observed_aim <- function(i, r_e, pi_p, x, par) {
  (i - believed_rule(r_e, pi_p, x, 0, par)) / (1 - par$phi_pi)
}

# (A21): the perceived aim moves a share k towards the observed aim
aim_filter <- function(aim, pi_star, revealed, par) {
  if (!revealed) return(aim)
  pi_star <- min(max(pi_star, -par$band), par$band)
  min(max(aim + par$k * (pi_star - aim), -par$band), par$band)
}

# A.5, "The Bank's Word": an announcement of the next m quarters' rates
announce <- function(ahead, rates, par) {
  m <- length(rates)
  stopifnot(m <= par$H, all(rates >= par$i_min))
  revised <- which(!is.na(ahead[seq_len(m)]))
  revisions <- data.frame(h = revised, old = ahead[revised], new = rates[revised])
  ahead[seq_len(m)] <- rates
  list(ahead = ahead, revisions = revisions)
}

# (A22): the probability that the plan is kept h quarters ahead
survival <- function(chi, h) chi / sqrt(h)

# A.5, "The Bank's Word": the weights of the paths the public mixes for an announced plan
path_weights <- function(chi, M) {
  p    <- survival(chi, seq_len(M))
  kept <- cumprod(c(1, p))
  c(kept[seq_len(M)] * (1 - p), kept[M + 1])
}

# (A25): the band around an announced rate
cone <- function(h, par) par$b * sqrt(h)

# A.5, "Credibility and the Record": the miss of a departure from an announced rate
miss <- function(d, r, h, par) {
  dist <- max(0, d - max(0, r), min(0, r) - d)
  max(0, dist - cone(h, par))
}

# (A24): the estimate of the squared miss, updated with the gain
credibility <- function(cred, m_tilde, par) {
  sigma2 <- cred$sigma2_hat + par$k * (m_tilde^2 - cred$sigma2_hat)
  list(chi = par$sigma_R^2 / (par$sigma_R^2 + sigma2), sigma2_hat = sigma2)
}
