# 02_Game/sheet/pressing.R — v6 §5.4, the pressing figure

# v6 §5.4: the figure furthest from its normal, its direction and severity
pressing <- function(figures, law, thresholds) {
  distance <- c(inflation    = figures$inflation - law$target,
                unemployment = figures$unemployment - law$natural_unemployment,
                growth       = figures$growth - law$trend_growth,
                wages        = figures$wage_inflation - law$wage_normal)
  ratio <- abs(distance) / thresholds$pressing[names(distance)]
  if (max(ratio) < 1) return(list(variable = NA, direction = NA, severity = NA, distance = NA))
  v <- names(which.max(ratio))
  list(variable = v, direction = if (distance[[v]] > 0) "above" else "below",
       severity = if (ratio[[v]] >= thresholds$marked) "marked" else "mild",
       distance = unname(distance[[v]]))
}
