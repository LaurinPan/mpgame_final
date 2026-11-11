# 02_Game/sheet/drivers.R — v6 §5.4, the drivers of output and inflation

# v6 §5.4: the largest driver of last quarter's output and inflation among the innovations and the rate change
drivers <- function(run, q, classes) {
  none <- list(output = "none", inflation = "none", output_words = classes$driver_words[["none"]],
               inflation_words = classes$driver_words[["none"]], table = NULL)
  t <- q - 1
  if (t < 1) return(none)
  config <- run$config; par <- config$par
  inn    <- run$innovations[t, ]
  types  <- c(a = "technology", z = "demand", nu = "costs", g = "purchases")
  active <- names(types)[vapply(names(types), function(col) !is.na(inn[[col]]) && inn[[col]] != 0, logical(1))]
  started <- !is.null(run$foreseen) && isTRUE(run$foreseen$start == t)
  row    <- run$quarters[t, ]
  before <- if (t > 1) run$quarters[t - 1, ] else run$row0
  held   <- before$rate
  moved  <- abs(row$rate - held) > 1e-9
  if (!length(active) && !started && !moved) return(none)
  decision <- list(rate = row$rate, announce = run$decisions[[t]]$announce)
  base <- list(a = inn$a, z = inn$z, nu = inn$nu, g = inn$g, draw = run$draws[t])
  if (started) base$d_path <- run$foreseen$d
  resolve <- function(innovations, decision) {
    o <- solve_quarter(config, begin_quarter(config, run$states[[t]], innovations), decision)
    c(output = row$x - to_percent(o$x), inflation = row$pi_p - to_year(par$pi_bar + o$pi_p))
  }
  contribution <- function(cause) {
    if (cause == "rate") return(resolve(base, list(rate = held, announce = decision$announce)))
    i <- base
    if (cause == "path") i$d_path <- NULL else i[[cause]] <- 0
    resolve(i, decision)
  }
  causes <- c(active, if (started) "path", if (moved) "rate")
  tab <- t(vapply(causes, contribution, numeric(2)))
  rownames(tab) <- c(types[active], if (started) "slump", if (moved) "rate")
  change <- c(output = row$x - before$x, inflation = row$pi_p - before$pi_p)
  pick <- function(col) {
    if (abs(change[[col]]) < 0.05) return("none")
    k <- which.max(abs(tab[, col]))
    if (abs(tab[k, col]) >= classes$thresholds$drivers_half * abs(change[[col]])) rownames(tab)[k] else "mixed"
  }
  words <- function(driver) classes$driver_words[[if (driver == "rate") (if (row$rate > held) "rate_up" else "rate_down") else driver]]
  out <- pick("output"); inf <- pick("inflation")
  list(output = out, inflation = inf, output_words = words(out), inflation_words = words(inf),
       table = rbind(tab, change = change))
}
