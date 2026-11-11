# 02_Game/bank/staff_forecast.R — Section 4.2.1, the staff forecast on the fair quarter, with the band the reports leave open (v6 §5.3)

# Section 4.2.1 and v6 §5.3: the forecast at a decision, with its band from the class edges of every shock reported in words
staff_forecast <- function(run, q, rate, path = NULL) {
  config <- run$config; par <- config$par
  if (rate < 0 || rate > consts$cap) stop("the rate lies outside the floor and the cap")
  shocks <- run$sheets[[q]]$shocks
  decision <- list(rate = rate, announce = path)
  figures <- function(fair) {
    o <- solve_quarter(config, fair, decision)
    c(inflation = to_year(par$pi_bar + o$pi_p), output_gap = to_percent(o$x), unemployment = to_percent(o$U), spell = o$spell)
  }
  centre <- figures(fair_quarter(run, q))
  lo <- hi <- centre[1:3]
  words <- names(shocks$shocks)[!vapply(shocks$shocks, function(s) identical(s$reported, "exact"), logical(1))]
  if (length(words)) {
    edges <- lapply(words, function(ty) {
      s <- shocks$shocks[[ty]]; k <- match(s$class, classes$names); b <- c(0, classes$bounds[[ty]])
      sign(s$size) * b[c(k, k + 1)]
    })
    grid <- expand.grid(edges)
    for (i in seq_len(nrow(grid))) {
      sh <- shocks
      for (j in seq_along(words)) { sh$shocks[[words[j]]]$size <- grid[i, j]; sh$shocks[[words[j]]]$reported <- "exact" }
      p  <- figures(fair_quarter(run, q, shocks = sh))[1:3]
      lo <- pmin(lo, p); hi <- pmax(hi, p)
    }
  }
  list(mean = centre[1:3], band = list(lo = lo, hi = hi), spell = unname(centre[["spell"]]), in_words = words)
}
