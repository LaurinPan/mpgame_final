# 01_Engine/combination/forecast.R — A.7 "Solving a Quarter" and A.5 "The Bank's Word": the public's forecast

# A.7, "Solving a Quarter", and A.5, "The Bank's Word": the public's forecast for the quarters ahead under the believed rule and the announced path
forecast <- function(sys, omega_t, ahead, chi) {
  M     <- sum(!is.na(ahead))
  w     <- path_weights(chi, M)
  paths <- lapply(0:M, function(m) floor_spell(sys, omega_t, ahead[seq_len(m)]))
  list(c = Reduce(`+`, Map(function(p, wm) wm * p$rule$c, paths, w)),
       M = Reduce(`+`, Map(function(p, wm) wm * p$rule$M, paths, w)),
       regimes = lapply(paths, `[[`, "regimes"),
       rates   = paths[[1]]$rates)
}
