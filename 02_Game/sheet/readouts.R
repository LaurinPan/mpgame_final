# 02_Game/sheet/readouts.R — Section 4.2.1, the figures as a statistics office reports them

# Section 4.2.1: the output level from natural output and the gap
output_level <- function(rows, par, consts) {
  y_n <- 100 * natural_output(from_percent(rows$a), from_percent(rows$G), par)
  consts$Y0 * exp(par$g * rows$t) * exp((y_n + rows$x) / 100)
}

# Section 4.2.1: the trend
output_trend <- function(t, par, consts) consts$Y0 * exp(par$g * t)

# (A5) and Section 4.2.1: the mandate's miss in its two parts, in squared points a year
loss_parts <- function(pi_p, x, par) {
  list(inflation = (pi_p - to_year(par$pi_bar))^2, output = 16 * par$vartheta * x^2)
}

# Section 4.2.1 and (A19): the figures of quarter t
readouts <- function(rows, t, par, consts) {
  i <- which(rows$t == t)
  j <- which(rows$t == t - 1)
  level <- output_level(rows, par, consts)
  prev  <- function(col, at_start) if (length(j)) rows[[col]][j] else at_start
  growth <- if (length(j)) 400 * log(level[i] / level[j]) else to_year(par$g)
  fell   <- length(j) > 0 && level[i] < level[j]
  fell_before <- t >= 2 && level[j] < level[which(rows$t == t - 2)]
  u_n   <- to_percent(par$u_n)
  above <- rows$U[rows$t <= t] - u_n > classes$thresholds$pressing[["unemployment"]]
  run_above <- if (length(above) && above[length(above)]) tail(rle(above)$lengths, 1) else 0
  wage  <- rows$pi_w[i] + to_year(par$g)
  loss  <- loss_parts(rows$pi_p[i], rows$x[i], par)
  list(t = t,
       inflation = rows$pi_p[i], inflation_change = rows$pi_p[i] - prev("pi_p", to_year(par$pi_bar)),
       inflation_gap = rows$pi_p[i] - to_year(par$pi_bar), inflation_before = prev("pi_p", to_year(par$pi_bar)),
       wage_inflation = wage, wage_change = wage - (prev("pi_w", to_year(par$pi_bar)) + to_year(par$g)),
       wage_gap = wage - to_year(par$pi_bar + par$g), wage_real = wage - rows$pi_p[i],
       growth = growth, growth_gap = growth - to_year(par$g), output_level = level[i], output_trend = output_trend(t, par, consts),
       output_fell = fell, recession = fell && fell_before,
       unemployment = rows$U[i], unemployment_change = rows$U[i] - prev("U", u_n), unemployment_gap = rows$U[i] - u_n,
       unemployed_persons = consts$labour_force * rows$U[i] / 100, population = consts$population, labour_force = consts$labour_force,
       quarters_above_natural = run_above,
       rate = round(rows$rate[i], 2), rate_change = round(rows$rate[i] - prev("rate", rows$rate[i]), 2),
       loss = c(loss, list(total = loss$inflation + loss$output)))
}

# v6 §12.3: the history the charts draw
readouts_table <- function(rows, t, par, consts, quarters = t + 1) {
  ts <- seq(max(0, t - quarters + 1), t)
  do.call(rbind, lapply(ts, function(k) {
    r <- readouts(rows, k, par, consts)
    data.frame(t = k, inflation = r$inflation, wage_inflation = r$wage_inflation, growth = r$growth,
               output_level = r$output_level, output_trend = r$output_trend, unemployment = r$unemployment,
               rate = r$rate, loss_inflation = r$loss$inflation, loss_output = r$loss$output)
  }))
}
