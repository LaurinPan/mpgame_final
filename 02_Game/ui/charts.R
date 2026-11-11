# ui/charts.R — the charts as SVG drawn from the views' values (the fixed
# scales come from desk_view's charts, one per variable for every topic, a value beyond the scale
# ringed at the edge with its value on hover; the time axis's labels never
# overlap; the output chart draws the level with its trend, the
# recessions are read off the output level, two falls in a row; the rate chart
# carries the floor, the announced path, the word's layer from Topic 4 and the
# election marks from Topic 7; the projected point of the staff forecast from
# Topic 5). Pure functions returning SVG or HTML strings.

GAME_COL <- list(ink = "#1B2433", muted = "#5A6475", rule = "#D6DBE3", action = "#1F4E8C", ok = "#13866F", error = "#B3261E",
                 grey = "#C9D0DB", grid = "#E3E6EB", red = "#CC2229", amber = "#C77A1E", lilac = "#7E63B5")
GAME_FONT <- "Public Sans, system-ui, sans-serif"
GAME_MARK_COL <- c("#D9822B", "#8E5BB5", "#13866F", "#7A8B2E", "#C4522A", "#5B4FC4", "#B4651A", "#4A5568")   # the debrief's marks, numbered

# A text in a chart's SVG.
gsvg_text <- function(x, y, s, size = 12, fill = GAME_COL$muted, anchor = "middle", weight = NULL)
  sprintf('<text x="%.1f" y="%.1f" font-size="%s" fill="%s" text-anchor="%s"%s font-family="%s">%s</text>',
          x, y, size, fill, anchor, if (is.null(weight)) "" else sprintf(' font-weight="%s"', weight), GAME_FONT, game_esc(s))
# A line.
gsvg_line <- function(x1, y1, x2, y2, stroke = GAME_COL$rule, width = 1, dash = NULL)
  sprintf('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="%s"%s></line>', x1, y1, x2, y2, stroke, width,
          if (is.null(dash)) "" else sprintf(' stroke-dasharray="%s"', dash))
# A series' polyline, dashed where its style says.
gsvg_poly <- function(x, y, stroke = GAME_COL$action, width = 2.5, dash = NULL, cls = NULL)
  sprintf('<polyline points="%s" fill="none" stroke="%s" stroke-width="%s"%s%s></polyline>', paste(sprintf("%.1f,%.1f", x, y), collapse = " "),
          stroke, width, if (is.null(dash)) "" else sprintf(' stroke-dasharray="%s"', dash), if (is.null(cls)) "" else sprintf(' class="%s"', cls))
# A point.
gsvg_circle <- function(x, y, r = 4, fill = GAME_COL$action, stroke = NULL, cls = NULL)
  sprintf('<circle cx="%.1f" cy="%.1f" r="%s" fill="%s"%s%s></circle>', x, y, r, fill, if (is.null(stroke)) "" else sprintf(' stroke="%s" stroke-width="2"', stroke),
          if (is.null(cls)) "" else sprintf(' class="%s"', cls))
# A rectangle (a band, a bar, a shaded span).
gsvg_rect <- function(x, y, w, h, fill, opacity = 1, cls = NULL)
  sprintf('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="%s" fill-opacity="%s"%s></rect>', x, y, w, h, fill, opacity,
          if (is.null(cls)) "" else sprintf(' class="%s"', cls))
# A chart's opening svg tag with its label for screen readers.
gsvg_open <- function(w, h, label, cls = "game-chart", height = NULL)
  sprintf('<svg viewBox="0 0 %d %d" width="100%%"%s role="img" aria-label="%s" class="%s" preserveAspectRatio="xMidYMid meet">', as.integer(w), as.integer(h),
          if (is.null(height)) "" else sprintf(' height="%d"', as.integer(height)), game_esc(label), cls)

# --- the scales and ticks ----------------------------------------------------------------------
game_round_out <- function(lo, hi, step) c(floor(lo / step + 1e-9) * step, ceiling(hi / step - 1e-9) * step)
# An axis step near a fifth of the span, 1, 2, 2.5, 5 or 10 times a power of ten.
game_nice_step <- function(span) {
  raw <- span / 5; mag <- 10^floor(log10(raw)); m <- raw / mag
  mag * (if (m <= 1) 1 else if (m <= 2) 2 else if (m <= 2.5) 2.5 else if (m <= 5) 5 else 10)
}
# An axis's ticks from lo to hi, the step widened until they stand gap px apart and number at most `most`.
game_ticks <- function(lo, hi, step, px, gap = 18, most = 10) {
  span <- hi - lo
  if (!isTRUE(is.finite(span)) || span <= 0) { out <- lo; attr(out, "step") <- step; return(out) }
  need <- max(step, span / most, gap * span / max(1, px))
  ts <- if (need <= step * (1 + 1e-9)) step else { mag <- 10^floor(log10(need)); m <- need / mag
          mag * (if (m <= 1 + 1e-9) 1 else if (m <= 2 + 1e-9) 2 else if (m <= 5 + 1e-9) 5 else 10) }
  out <- seq(ceiling(lo / ts - 1e-9) * ts, floor(hi / ts + 1e-9) * ts, by = ts)
  attr(out, "step") <- ts
  out
}
# A tick's label with the decimals its step needs (a step of 2.5 one, so that 7.5 never reads 8).
game_tick_label <- function(v, step) {
  if (is.na(v)) return("")
  d <- if (abs(step - round(step)) < 1e-9) 0 else if (abs(10 * step - round(10 * step)) < 1e-9) 1 else 2
  game_num(v, d)
}
# A quarter's label on the time axis.
game_q_label <- function(q) if (q == 0) ui_s("chart.q_start") else ui_s("chart.q_tick", n = q)
# A view's scale (lo, hi) with a round step for its ticks.
ui_scale <- function(lo, hi) { step <- game_nice_step(hi - lo); list(lo = lo, hi = hi, step = step) }
# Section 4.2.1, a recession: output falls for two quarters in a row. The spans c(first, last) of falling quarters, from the output level
# by quarter (the quarter before the term first), where a run of falls lasts two quarters or more.
ui_recession_spans <- function(t, level) {
  if (length(level) < 3) return(list())
  fell <- c(FALSE, diff(level) < 0)
  runs <- rle(fell); out <- list(); pos <- 0
  for (i in seq_along(runs$lengths)) { if (runs$values[i] && runs$lengths[i] >= 2) out[[length(out) + 1]] <- c(t[pos + 1], t[pos + runs$lengths[i]]); pos <- pos + runs$lengths[i] }
  out
}

# --- a series chart -----------------------------------------------------------------------------------------------------
# `dat` the view's data by quarter (t from the quarter before the term); `series` the columns drawn, the first the main series, each with
# its style in `styles` (col, dash, width, label); `scale` list(lo, hi, step); `reference` a number with its label; `T` the term; `x1` the
# axis's last quarter (the rate chart runs to q + H - 1 with the word); `layer` a function(x, y, g) of under and over parts; `recessions`
# the spans shaded; `elections` the quarters marked on the axis; `dims` the paper's size; `points` the quarters whose main value is drawn
# as a point (the announced path's hollow points).
ui_series_svg <- function(dat, series, styles, scale, reference = NA, ref_label = NULL, T, x1 = NULL, title = "", unit = "", wide = FALSE, small = FALSE,
                          style = c("panel", "paper"), dims = NULL, layer = NULL, recessions = list(), elections = integer(0), legend = TRUE) {
  style <- match.arg(style); P <- ui_params$chart
  if (is.null(dat) || !nrow(dat)) return("")
  q0 <- min(dat$t); x1 <- max(T, x1 %||% T, max(dat$t))
  size <- if (!is.null(dims)) c(W = dims$W, H = dims$H) else if (isTRUE(wide)) P$wide else if (isTRUE(small)) P$small else P$main
  W <- size[["W"]]; H <- size[["H"]]
  L <- if (!is.null(dims)) 40 else P$margin$L; R <- W - (if (!is.null(dims)) 10 else P$margin$R); top <- if (!is.null(dims)) 10 else P$margin$top; bot <- H - (if (!is.null(dims)) 20 else P$margin$bottom)
  x <- function(q) L + (q - q0) / max(1, x1 - q0) * (R - L)
  y <- function(v) bot - (pmin(pmax(v, scale$lo), scale$hi) - scale$lo) / (scale$hi - scale$lo) * (bot - top)
  dq <- (R - L) / max(1, x1 - q0); half <- dq / 2
  parts <- character(0)
  for (sp in recessions) parts <- c(parts, gsvg_rect(x(sp[1]) - half, top, x(sp[2]) - x(sp[1]) + 2 * half, bot - top, GAME_COL$error, 0.12, "chart-recession"))
  ticks <- game_ticks(scale$lo, scale$hi, scale$step, bot - top, gap = if (is.null(dims)) P$tick_gap else 14, most = if (is.null(dims)) 10 else 5)
  if (style != "paper") parts <- c(parts, gsvg_line(L, y(scale$lo), R, y(scale$lo)))
  for (tk in ticks) parts <- c(parts, if (style == "paper") gsvg_line(L, y(tk), R, y(tk), GAME_COL$grid), gsvg_text(L - 6, y(tk) + 4, game_tick_label(tk, attr(ticks, "step")), if (is.null(dims)) 12 else 10, anchor = "end"))
  parts <- c(parts, gsvg_line(L, top, L, bot))
  legend_pos <- c(R - 300, R, bot - 12)
  g <- list(L = L, R = R, top = top, bot = bot, q0 = q0, q1 = x1, lo = scale$lo, hi = scale$hi, dq = dq, W = W, H = H, legend = legend_pos)
  lay <- if (is.function(layer)) layer(x, y, g)
  if (!is.null(lay$under)) parts <- c(parts, lay$under)
  if (isTRUE(is.finite(reference))) {
    parts <- c(parts, gsvg_line(L, y(reference), R, y(reference), GAME_COL$ink, 1.5, "6 4"))
    if (!is.null(ref_label)) parts <- c(parts, if (isTRUE(legend) && length(series) > 1 && is.null(dims)) gsvg_text(L + 6, y(reference) - 6, ref_label, 11, GAME_COL$ink, "start") else gsvg_text(R - 4, y(reference) - 6, ref_label, 11, GAME_COL$ink, "end"))
  }
  for (q in elections) if (q >= q0 && q <= x1)
    parts <- c(parts, sprintf('<g class="chart-election" data-quarter="%d">%s%s</g>', as.integer(q), gsvg_line(x(q), top, x(q), bot, GAME_COL$ink, 1.2, "4 3"),
                              gsvg_text(x(q) + 4, top + 10, ui_s("chart.election_mark"), 11, GAME_COL$ink, "start")))
  main <- series[1]; last_x <- NA; last_y <- NA
  for (k in rev(seq_along(series))) {                       # the main series drawn last, on top
    nm <- series[k]; st <- styles[[nm]] %||% list(); v <- dat[[nm]]; ok <- !is.na(v)
    if (!any(ok)) next
    col <- st$col %||% (if (k == 1) GAME_COL$action else GAME_COL$ink); wd <- st$width %||% (if (k == 1) 2.5 else 1.5); dash <- st$dash %||% (if (k == 1) NULL else "6 4")
    if (isTRUE(st$points)) {                                 # hollow points joined dashed (the announced path)
      parts <- c(parts, gsvg_poly(x(dat$t[ok]), y(v[ok]), col, wd, dash %||% "6 4", "chart-announced"))
      for (i in which(ok)) parts <- c(parts, gsvg_circle(x(dat$t[i]), y(v[i]), 4, "#FFFFFF", col))
      next
    }
    parts <- c(parts, gsvg_poly(x(dat$t[ok]), y(v[ok]), col, wd, dash, cls = if (k == 1) "chart-series" else "chart-ref"))
    if (k == 1) {
      inside <- v >= scale$lo & v <= scale$hi
      for (i in which(ok & !inside)) parts <- c(parts, sprintf('<circle class="chart-beyond" cx="%.1f" cy="%.1f" r="5" fill="#FFFFFF" stroke="%s" stroke-width="2"><title>%s</title></circle>',
                                                                       x(dat$t[i]), y(v[i]), col, game_esc(game_num(v[i], 2))))   # the ring alone, its value on hover
      li <- max(which(ok)); last_x <- x(dat$t[li]); last_y <- y(v[li])
      parts <- c(parts, gsvg_circle(last_x, last_y, 4.5, col))
    }
  }
  if (!is.null(lay$over)) parts <- c(parts, lay$over)
  every <- if (x1 - q0 <= 16) 1L else if (x1 - q0 <= 32) 2L else 4L
  if (W < 600) every <- if (x1 - q0 <= 8) 1L else if (x1 - q0 <= 16) 2L else 4L
  tl <- max(dat$t); fs <- if (is.null(dims)) 11 else 9
  wid <- function(q) nchar(game_q_label(q)) * fs * 0.62 * (if (q == tl) 1.1 else 1)              # a label's width in px, the bold one wider
  near <- function(a, b) abs(x(a) - x(b)) < (wid(a) + wid(b)) / 2 + 4
  labs <- sort(unique(c(seq(q0, x1)[((seq(q0, x1) - q0) %% every) == 0], tl)))                # the regular labels and the latest quarter's
  labs <- labs[labs == tl | !vapply(labs, function(q) near(q, tl), logical(1))]                  # none too close to the bold one
  keep <- integer(0); for (q in labs) if (q == tl || !length(keep) || !near(q, keep[length(keep)])) keep <- c(keep, q)   # nor to each other
  for (q in keep)
    parts <- c(parts, gsvg_text(x(q), H - (if (is.null(dims)) 10 else 6), game_q_label(q), fs, if (q == tl) GAME_COL$ink else GAME_COL$muted, weight = if (q == tl) "600" else NULL))
  if (isTRUE(legend) && length(series) > 1 && is.null(dims)) {
    lx <- legend_pos[1]; ly <- legend_pos[3]
    for (k in seq_along(series)) { st <- styles[[series[k]]] %||% list(); lab <- st$label %||% series[k]
      col <- st$col %||% (if (k == 1) GAME_COL$action else GAME_COL$ink); dash <- st$dash %||% (if (k == 1) NULL else "6 4")
      parts <- c(parts, gsvg_line(lx, ly, lx + 26, ly, col, if (k == 1) 2.5 else 1.5, dash), gsvg_text(lx + 32, ly + 4, lab, 12, GAME_COL$ink, "start"))
      lx <- lx + 40 + 7 * nchar(lab) }
  }
  v1 <- dat[[main]]; li <- max(which(!is.na(v1)))
  label <- ui_s("chart.series_label", title = title, unit = unit, from = game_q_label(q0), to = game_q_label(tl), latest = tl, value = game_num(v1[li], 2),
             reference = if (isTRUE(is.finite(reference)) && !is.null(ref_label)) ui_s("chart.series_reference", label = ref_label, value = game_num(reference, 2)) else "",
             recessions = if (length(recessions)) ui_s("chart.series_recession", n = sum(vapply(recessions, function(z) z[2] - z[1] + 1, 0))) else "")
  paste0(gsvg_open(W, H, label, paste("game-chart", paste0("chart-", style)), height = if (!is.null(dims)) dims$height else NULL), paste(parts, collapse = ""), "</svg>")
}
# The first quarter's data alone: a table of the start.
ui_chart_table <- function(dat, series, labels, title, fmt = function(v) game_num(v, 2)) {
  if (is.null(dat) || !nrow(dat)) return(game_tag("p", list(class = "chart-empty"), game_esc(ui_s("chart.empty"))))
  head <- paste0(game_tag("th", list(scope = "col"), game_esc(ui_s("chart.table_quarter"))), paste(vapply(dat$t, function(q) game_tag("th", list(scope = "col"), game_esc(game_q_label(q))), ""), collapse = ""))
  rows <- vapply(seq_along(series), function(k) { v <- dat[[series[k]]]; if (all(is.na(v))) return("")
    game_tag("tr", list(), game_tag("th", list(scope = "row"), game_esc(labels[k])), paste(vapply(v, function(z) game_tag("td", list(), game_esc(fmt(z))), ""), collapse = "")) }, "")
  game_tag("table", list(class = "chart-table"), game_tag("caption", list(), game_esc(title)),
           game_tag("thead", list(), game_tag("tr", list(), head)), game_tag("tbody", list(), paste(rows, collapse = "")))
}
# A chart's box: the title with its unit, the body.
ui_chart_box <- function(id, title, unit, body, cls = "chart-box") game_tag("figure", list(class = cls, `data-chart` = id),
  game_tag("figcaption", list(class = "chart-title"), game_esc(title), if (nzchar(unit)) game_tag("span", list(class = "chart-unit"), paste0(" · ", game_esc(unit)))), body)
# The output chart's window, a fixed band around the trend over the term: from the trend at the start less the scale's lower edge to
# the trend at the term's end plus its upper edge, in $ bn.
ui_output_scale <- function(trend, T, sc) {
  tr0 <- trend[1]; fac <- if (length(trend) >= 2) trend[2] / trend[1] else 1.005
  trT <- tr0 * fac^T
  ui_scale(floor(tr0 * (1 + sc$lo / 100) / 50) * 50, ceiling(trT * (1 + sc$hi / 100) / 50) * 50)
}

# --- the desk's charts, one per entry of desk_view's `charts` -------------------------------------------------------------------
# `dv` the desk view; `opts` list(forecast = the staff forecast's points by variable, word = the rate chart's word layer).
ui_desk_chart <- function(id, dv, opts = list()) {
  ch <- dv$charts[[id]]; if (is.null(ch)) return("")
  dat <- ch$data; T <- dv$topic$T; q <- dv$topic$q; sc <- ch$scale
  rec <- if (!is.null(dv$charts$output)) ui_recession_spans(dv$charts$output$data$t, dv$charts$output$data$output_level) else list()
  first <- nrow(dat) < ui_params$chart$series_from
  proj <- function(var) if (!is.null(opts$forecast[[var]])) ui_forecast_layer(q, opts$forecast[[var]], var)
  elections <- if ("election" %in% names(dat)) dat$t[which(dat$election)] else integer(0)
  if (id == "rate") {
    w <- dv$word; H <- dv$decision$H %||% 8
    if (!is.null(ch$announced) && nrow(ch$announced)) { ann <- data.frame(t = ch$announced$q, announced = ch$announced$rate); dat <- merge(dat, ann, by = "t", all = TRUE); dat <- dat[order(dat$t), ] }
    else dat$announced <- NA_real_
    series <- c("rate", if (any(!is.na(dat$announced))) "announced")
    styles <- list(rate = list(label = ui_s("chart.series_rate")), announced = list(col = GAME_COL$ink, points = TRUE, label = ui_s("chart.series_announced")))
    x1 <- if (!is.null(w)) max(T, q + H - 1) else T
    elect <- c(elections, if (!is.null(dv$header$election)) q + dv$header$election$quarters_to - 1)   # the votes held and the next
    if (first && is.null(w)) body <- ui_chart_table(dat, "rate", ui_s("chart.rate"), ui_s("chart.rate"))
    else body <- ui_series_svg(dat, series, styles, ui_scale(sc$lo, sc$hi), reference = ch$reference, ref_label = ui_s("chart.ref_floor"), T = T, x1 = x1,
                               title = ui_s("chart.rate"), unit = ui_s("chart.unit_pct_year"), wide = TRUE, recessions = rec, elections = unique(elect),
                               layer = ui_layers(ui_slump_layer(dv$slump, x1), if (!is.null(w) && !is.null(opts$word_layer)) opts$word_layer), legend = !is.null(w))
    return(ui_chart_box("rate", ui_s("chart.rate"), if (is.null(w)) ui_s("chart.unit_pct_year") else ui_s("word.chart_unit"), paste0(body, opts$word_editor %||% ""), "chart-box chart-wide"))
  }
  spec <- switch(id,
    inflation = list(series = "inflation", title = ui_s("chart.inflation"), unit = ui_s("chart.unit_pct_year"), ref = ui_s("chart.ref_target"), proj = "inflation"),
    wage_inflation = list(series = "wage_inflation", title = ui_s("chart.wage_inflation"), unit = ui_s("chart.unit_pct_year"), ref = ui_s("chart.ref_wage_normal")),
    unemployment = list(series = "unemployment", title = ui_s("chart.unemployment"), unit = ui_s("chart.unit_pct"), ref = ui_s("chart.ref_natural"), proj = "unemployment"),
    output = list(series = c("output_level", "output_trend"), title = ui_s("chart.output"), unit = ui_s("chart.unit_bn"), ref = NULL, proj = "output"),
    expectations = list(series = c("expected_inflation", if (any(!is.na(dat$aim_level))) "aim_level"), title = ui_s("chart.expectations"), unit = ui_s("chart.unit_pct_year"), ref = ui_s("chart.ref_target")),
    NULL)
  if (is.null(spec)) return("")
  styles <- list(output_level = list(label = ui_s("chart.series_output")), output_trend = list(label = ui_s("chart.series_trend")),
                 expected_inflation = list(label = ui_s("chart.series_expected")), aim_level = list(col = GAME_COL$lilac, dash = "4 3", label = ui_s("chart.series_aim")))
  scale <- if (id == "output") ui_output_scale(dat$output_trend, T, sc) else ui_scale(sc$lo, sc$hi)
  labels <- vapply(spec$series, function(nm) styles[[nm]]$label %||% spec$title, "")
  body <- if (first) ui_chart_table(dat, spec$series, labels, spec$title, fmt = if (id == "output") function(v) fmt_bn(v) else function(v) game_num(v, 2))
          else ui_series_svg(dat, spec$series, styles, scale, reference = if (id == "output") NA else ch$reference, ref_label = spec$ref, T = T,
                             title = spec$title, unit = spec$unit, recessions = rec,
                             layer = if (!is.null(spec$proj)) proj(spec$proj), legend = length(spec$series) > 1, small = !(id %in% c("inflation", "wage_inflation", "unemployment", "output")))
  ui_chart_box(id, spec$title, spec$unit, body, if (id %in% c("inflation", "wage_inflation", "unemployment", "output")) "chart-box" else "chart-box chart-small")
}
# The staff forecast's projected point and band at the quarter being decided: under the series a light column,
# over it the point and the band, in a group the script redraws from the preview's numbers (data-geom).
ui_forecast_layer <- function(q, p, var) {
  force(q); force(p)
  function(x, y, g) {
    half <- g$dq / 2; xq <- x(q)
    geom <- as.character(jsonlite::toJSON(list(x = xq, lo = g$lo, hi = g$hi, top = g$top, bot = g$bot), auto_unbox = TRUE, digits = NA))
    under <- paste0(gsvg_rect(xq - half, g$top, 2 * half, g$bot - g$top, GAME_COL$action, 0.06, "proj-col"), gsvg_text(xq, g$top - 4, ui_s("forecast.projected"), 10, GAME_COL$action))
    pts <- if (is.null(p)) "" else sprintf('<line class="proj-band" x1="%.1f" x2="%.1f" y1="%.1f" y2="%.1f" stroke="%s" stroke-width="7" stroke-opacity="0.3" stroke-linecap="round"/><circle class="proj-mean" cx="%.1f" cy="%.1f" r="4.5" fill="#FFFFFF" stroke="%s" stroke-width="2"/>',
                                           xq, xq, y(p$hi), y(p$lo), GAME_COL$action, xq, y(p$mean), GAME_COL$action)
    list(under = under, over = sprintf('<g class="proj-point" data-var="%s" data-geom="%s">%s</g>', var, game_esc(geom), pts))
  }
}
# A foreseen slump's span on the rate chart once the newspaper has reported it, quarters start to start + length - 1.
ui_slump_layer <- function(sl, x1) {
  if (is.null(sl)) return(NULL)
  a <- as.integer(sl$start); b <- as.integer(sl$start + sl$length - 1L)
  function(x, y, g) { half <- g$dq / 2; a2 <- max(a, g$q0); b2 <- min(b, x1); if (b2 < a2) return(list())
    list(under = c(gsvg_rect(x(a2) - half, g$top, x(b2) - x(a2) + 2 * half, g$bot - g$top, GAME_COL$error, 0.10, "chart-slump"),
                   gsvg_text((x(a2) + x(b2)) / 2, g$top + 12, ui_s("chart.slump", from = a, to = b), 11, GAME_COL$error, "middle"))) }
}
# Two layers of a chart drawn as one, the first under the second.
ui_layers <- function(f1, f2) {
  if (is.null(f1)) return(f2); if (is.null(f2)) return(f1)
  function(x, y, g) { a <- f1(x, y, g); b <- f2(x, y, g); list(under = c(a$under, b$under), over = c(a$over, b$over)) }
}
# The rate chart's layer from Topic 4: the future region (this quarter and the H after it), the
# bands of the cone around the rate due and the standing rates, hollow points for them, the room the news gives in green, and the group
# the script fills with the new path (class path-draft, its geometry in data-geom). `w` desk_view's word, `q` the quarter, `H` the horizon.
ui_word_layer <- function(w, q, H) {
  force(w); force(q); force(H)
  function(x, y, g) {
    half <- g$dq / 2; xs <- x(q) - half; xe <- x(min(q + H - 1, g$q1)) + half
    under <- c(gsvg_rect(xs, g$top, xe - xs, g$bot - g$top, GAME_COL$action, 0.05, "path-future"),
               gsvg_line(xs, g$top, xs, g$bot, GAME_COL$muted, 1, "2 3"),
               gsvg_text(xs - 6, g$top - 4, ui_s("word.played"), 11, GAME_COL$muted, "end"),
               gsvg_text(xs + 6, g$top - 4, ui_s("word.region"), 11, GAME_COL$muted, "start"))
    over <- character(0); room_said <- FALSE
    if (isTRUE(w$has_path) && !is.null(w$standing)) for (i in seq_len(nrow(w$standing))) {
      qi <- w$standing$q[i]; a <- w$standing$rate[i]; h <- qi - q; b <- w$cone[max(1, h)]
      room <- if (h == 0) w$room_due else w$room[h]; d <- a + (room %||% 0)
      if (qi > g$q1) next
      xq <- x(qi); y1 <- y(a + b); y0 <- y(a - b)
      under <- c(under, sprintf('<rect class="path-band" data-q="%d" x="%.1f" y="%.1f" width="12" height="%.1f" fill="%s" fill-opacity="0.16" rx="2"/>', qi, xq - 6, y1, max(1, y0 - y1), GAME_COL$ink))
      if (isTRUE(w$new_shock) && abs(d - a) > 1e-9) {
        ya <- y(a); yd <- y(d)
        under <- c(under, sprintf('<rect class="path-room" data-q="%d" x="%.1f" y="%.1f" width="7" height="%.1f" fill="%s" fill-opacity="0.35" rx="2"/>', qi, xq + 7, min(ya, yd), max(1, abs(yd - ya)), GAME_COL$ok))
        if (!room_said) { under <- c(under, sprintf('<text class="path-room-label" x="%.1f" y="%.1f" font-size="11" fill="%s" text-anchor="start" font-family="%s">%s</text>', xq + 18, max(ya, yd) - 2, GAME_COL$ok, GAME_FONT, game_esc(ui_s("word.room_label")))); room_said <- TRUE }
      }
      over <- c(over, sprintf('<circle class="path-standing" data-q="%d" cx="%.1f" cy="%.1f" r="5" fill="#FFFFFF" stroke="%s" stroke-width="1.5"/>', qi, xq, y(a), GAME_COL$ink))
    }
    geom <- as.character(jsonlite::toJSON(list(x0 = x(g$q0), q0 = g$q0, dq = g$dq, lo = g$lo, hi = g$hi, top = g$top, bot = g$bot, right = g$R), auto_unbox = TRUE, digits = NA))
    list(under = paste(under, collapse = ""), over = paste0(paste(over, collapse = ""), sprintf('<g class="path-draft" data-geom="%s"></g>', game_esc(geom))))
  }
}

# --- the newspaper's charts (scripts appendix §12.3) ---------------------------------------------------------------------------------------------
# A piece's chart from issue_view's chart_data: the series over the last eight quarters, the reference line, the caption; at the panel's
# fixed scales (content/panels.R's `scales`), the paper's size. The poll and government spending, no longer on the desk, have no
# fixed scale there: their charts take the series and the reference line rounded out to a round step.
ui_paper_chart_svg <- function(cd) {
  if (is.null(cd) || !length(cd$series)) return("")
  var <- switch(cd$id, `CH-output` = "output", `CH-inflation` = "inflation", `CH-wages` = "wage_inflation", `CH-unemployment` = "unemployment",
                `CH-rate` = "rate", `CH-expectations` = "expected_inflation", `CH-poll` = "poll", `CH-purchases` = "purchases", "inflation")
  sc <- scales[scales$variable == var, ]
  frames <- Filter(Negate(is.null), cd$series); if (!length(frames)) return("")
  dat <- NULL
  for (nm in names(frames)) { f <- frames[[nm]]; if (nm == "announced") f <- data.frame(t = f$q, value = f$rate)
    d <- data.frame(t = f$t); d[[nm]] <- f$value; dat <- if (is.null(dat)) d else merge(dat, d, by = "t", all = TRUE) }
  dat <- dat[order(dat$t), ]; series <- names(frames)
  styles <- list(output_trend = list(col = GAME_COL$ink, dash = "6 4"), announced = list(col = GAME_COL$ink, points = TRUE))
  if (identical(cd$id, "CH-wages")) styles$inflation <- list(col = GAME_COL$ink, dash = "6 4")
  if (var == "output") { tr <- dat$output_trend[!is.na(dat$output_trend)]; scale <- ui_scale(floor(min(tr) * (1 + sc$lo / 100) / 50) * 50, ceiling(max(tr) * (1 + sc$hi / 100) / 50) * 50) }
  else if (nrow(sc)) scale <- ui_scale(sc$lo, sc$hi)
  else { v <- c(unlist(dat[series]), cd$reference); v <- v[is.finite(v)]; st <- game_nice_step(max(diff(range(v)), 1)); scale <- ui_scale(floor(min(v) / st) * st, ceiling(max(v) / st) * st) }
  if (identical(series[1], "inflation") && identical(cd$id, "CH-wages")) series <- c("wage_inflation", "inflation")
  x1 <- max(dat$t, if (!is.null(frames$announced)) max(frames$announced$q))
  ui_series_svg(dat, series, styles, scale, reference = if (isTRUE(is.finite(cd$reference))) cd$reference else NA, ref_label = NULL, T = x1, x1 = x1,
                title = cd$caption, unit = "", style = "paper", dims = ui_params$paper$chart, legend = FALSE)
}

# --- the debrief's chart (Section 4.2.2) --------------------------------------------------------------------------------------------
# One chart of the player's rates beside the reference bank's; the guided quarters shaded grey; each mark a numbered circle at its quarter
# in its colour, a deferred mark's later quarters shaded in that colour.
ui_debrief_chart_svg <- function(d) {
  ch <- d$chart; T <- d$T; P <- ui_params$chart$debrief; W <- P[["W"]]; H <- P[["H"]]; L <- 44; R <- W - 14; top <- 16; bot <- H - 30
  v <- c(ch$player, ch$bank)
  r <- game_round_out(min(0, v, na.rm = TRUE), max(v, na.rm = TRUE) + 0.5, 2); scale <- list(lo = r[1], hi = r[2], step = 2)
  x <- function(q) L + (q - 1) / max(1, T - 1) * (R - L); dq <- (R - L) / max(1, T - 1)
  y <- function(z) bot - (pmin(pmax(z, scale$lo), scale$hi) - scale$lo) / (scale$hi - scale$lo) * (bot - top)
  span <- function(a, b) { x0 <- max(L, x(a) - dq / 2); x1 <- min(R, x(b) + dq / 2); c(x0, x1 - x0) }
  parts <- character(0)
  gq <- ch$q[ch$guided]
  if (length(gq)) { g <- span(min(gq), max(gq)); parts <- c(parts, gsvg_rect(g[1], top, g[2], bot - top, GAME_COL$grid, 0.9, "debrief-guided")) }
  for (k in seq_along(d$marks)) { m <- d$marks[[k]]; col <- GAME_MARK_COL[(k - 1) %% length(GAME_MARK_COL) + 1]
    for (sq in m$shaded) { g <- span(sq, sq); parts <- c(parts, gsvg_rect(g[1], top, g[2], bot - top, col, 0.14, "debrief-shaded")) }
    g <- span(m$q, m$q); parts <- c(parts, gsvg_rect(g[1], top, g[2], bot - top, col, 0.30, "debrief-mark")) }
  ticks <- game_ticks(scale$lo, scale$hi, scale$step, bot - top, gap = 18, most = 8)
  parts <- c(parts, gsvg_line(L, y(scale$lo), R, y(scale$lo), GAME_COL$rule))
  for (tk in ticks) parts <- c(parts, if (tk != scale$lo) gsvg_line(L, y(tk), R, y(tk), GAME_COL$grid), gsvg_text(L - 6, y(tk) + 4, game_tick_label(tk, attr(ticks, "step")), 11, anchor = "end"))
  parts <- c(parts, gsvg_line(L, y(0), R, y(0), GAME_COL$ink, 1.2, "6 4"), gsvg_text(R - 2, y(0) - 5, ui_s("chart.ref_floor"), 11, GAME_COL$ink, "end"))
  parts <- c(parts, sprintf('<g class="debrief-line line-bank">%s</g>', gsvg_poly(x(ch$q), y(ch$bank), GAME_COL$ink, 1.8)),
             sprintf('<g class="debrief-line line-player">%s</g>', gsvg_poly(x(ch$q), y(ch$player), GAME_COL$action, 2.5)))
  for (k in seq_along(d$marks)) { m <- d$marks[[k]]; col <- GAME_MARK_COL[(k - 1) %% length(GAME_MARK_COL) + 1]
    parts <- c(parts, sprintf('<g class="debrief-mark-num" data-mark="%d">%s%s</g>', k, gsvg_circle(x(m$q), bot - 11, 8, col), gsvg_text(x(m$q), bot - 7, as.character(k), 11, "#FFFFFF", weight = "700"))) }
  every <- if (T <= 16) 2L else if (T <= 32) 4L else 8L
  for (q in seq_len(T)) if (q == 1L || q %% every == 0L) parts <- c(parts, gsvg_text(x(q), H - 8, game_q_label(q), 11))
  label <- sprintf("%s, %s from %s to %s and %s from %s to %s.", ui_s("debrief.chart_title"), ui_s("debrief.legend_player"), game_num(ch$player[1], 2), game_num(ch$player[T], 2),
                   ui_s("debrief.legend_bank"), game_num(ch$bank[1], 2), game_num(ch$bank[T], 2))
  ui_chart_box("debrief_rate", ui_s("debrief.chart_title"), ui_s("debrief.unit_rate"), paste0(gsvg_open(W, H, label, "game-chart chart-debrief"), paste(parts, collapse = ""), "</svg>"), "chart-box debrief-chart")
}
# Scripts appendix §5.4: the two losses quarter by quarter on one scale, under the rates' chart and on its quarter axis, the marks' quarters
# shaded in their colours; no text of it names squared points.
ui_debrief_loss_svg <- function(d) {
  lq <- d$loss_by_quarter; if (is.null(lq) || !nrow(lq)) return("")
  T <- d$T; P <- ui_params$chart$debrief; W <- P[["W"]]; H <- P[["H"]]; L <- 44; R <- W - 14; top <- 16; bot <- H - 30
  hi <- max(c(lq$player, lq$bank), na.rm = TRUE); step <- game_nice_step(if (isTRUE(hi > 0)) hi else 1); scale <- list(lo = 0, hi = game_round_out(0, if (isTRUE(hi > 0)) hi else 1, step)[2], step = step)
  x <- function(q) L + (q - 1) / max(1, T - 1) * (R - L); dq <- (R - L) / max(1, T - 1)
  y <- function(z) bot - (pmin(pmax(z, scale$lo), scale$hi) - scale$lo) / (scale$hi - scale$lo) * (bot - top)
  span <- function(a, b) { x0 <- max(L, x(a) - dq / 2); x1 <- min(R, x(b) + dq / 2); c(x0, x1 - x0) }
  parts <- character(0)
  for (k in seq_along(d$marks)) { m <- d$marks[[k]]; g <- span(m$q, m$q); parts <- c(parts, gsvg_rect(g[1], top, g[2], bot - top, GAME_MARK_COL[(k - 1) %% length(GAME_MARK_COL) + 1], 0.30, "debrief-mark")) }
  ticks <- game_ticks(scale$lo, scale$hi, scale$step, bot - top, gap = 18, most = 6)
  parts <- c(parts, gsvg_line(L, y(0), R, y(0), GAME_COL$rule))
  for (tk in ticks) parts <- c(parts, if (tk != 0) gsvg_line(L, y(tk), R, y(tk), GAME_COL$grid), gsvg_text(L - 6, y(tk) + 4, game_tick_label(tk, attr(ticks, "step")), 11, anchor = "end"))
  parts <- c(parts, sprintf('<g class="debrief-line line-bank">%s</g>', gsvg_poly(x(lq$q), y(lq$bank), GAME_COL$ink, 1.8)),
             sprintf('<g class="debrief-line line-player">%s</g>', gsvg_poly(x(lq$q), y(lq$player), GAME_COL$action, 2.5)))
  every <- if (T <= 16) 2L else if (T <= 32) 4L else 8L
  for (q in seq_len(T)) if (q == 1L || q %% every == 0L) parts <- c(parts, gsvg_text(x(q), H - 8, game_q_label(q), 11))
  label <- sprintf("%s, %s highest in quarter %d and %s highest in quarter %d.", ui_s("debrief.loss_chart_title"), ui_s("debrief.legend_player"), lq$q[which.max(lq$player)],
                   ui_s("debrief.legend_bank"), lq$q[which.max(lq$bank)])
  ui_chart_box("debrief_loss", ui_s("debrief.loss_chart_title"), ui_s("debrief.unit_loss"), paste0(gsvg_open(W, H, label, "game-chart chart-debrief chart-debrief-loss"), paste(parts, collapse = ""), "</svg>"), "chart-box debrief-chart")
}
