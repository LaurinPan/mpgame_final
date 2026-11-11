# ui/theory.R — the theory section (scripts appendix §14): its reading shell (the rail with the chapters and their topics, the main
# column with a topic's steps, More Detail panels, term boxes, the modules' frames, the static figures, the navigation). Its content
# is 02_Game/content/theory/:
# the six chapter files P1.yaml to P6.yaml (texts revised as scripts appendix §8 asks, term cards, the places of modules and figures),
# economy.yaml (the example economy's data), modules.yaml (the ten modules' sliders, scales, readouts and words), labels.yaml (the
# section's own interface words) and references.yaml (the sources, not displayed), read once at the first page drawn. The static
# figures are SVG drawn here from economy.yaml; the modules are drawn and computed in the browser by 02_Game/web/theory.js from one data
# attribute each. Every element that opens another topic carries data-theory-go="P5:7" (chapter:topic): theory.js sends it to the
# server as theory_nav, or on a static page opens theory_P5_7.html, the page's href.

ui_theory_outline <- list(
  list(id = "P1", title = "Macroeconomics, actors and models", topics = c("Economic models", "Microeconomics and macroeconomics", "The circular flow of the economy", "History of macroeconomics", "Economic schools of thought")),
  list(id = "P2", title = "Measuring output: GDP", topics = c("GDP", "Nominal and real GDP", "Limits of GDP")),
  list(id = "P3", title = "The goods market in the short run", topics = c("The Economy in the Short, Medium and Long Run", "The Demand Side of the Economy", "Equilibrium in the Goods Market", "The Multiplier")),
  list(id = "P4", title = "Money, prices and interest", topics = c("Price Indices and Inflation", "Money", "Banks and Money Creation", "The Central Bank and the Policy Rate", "Inflation: Causes and Costs", "Nominal and Real Interest Rates", "Investment and the Interest Rate")),
  list(id = "P5", title = "Labour market, unemployment and the Phillips relation", topics = c("Measuring Unemployment", "Flows in the Labour Market", "Wage Setting", "Price Setting and the Natural Rate of Unemployment", "Okun's Law", "Downward Wage Rigidity", "The Phillips Curve")),
  list(id = "P6", title = "Growth and potential output", topics = c("The Production Function", "Potential Output and the Output Gap", "Capital Accumulation and the Steady State", "Labour-Force Growth and Technological Progress", "Growth Accounting")))
UI_THEORY <- new.env(parent = emptyenv())

# --- the content ------------------------------------------------------------------------------------------------------------------

# The content files read once; the chapters' and topics' titles must be the rail's.
ui_theory_content <- function(dir = "02_Game/content/theory") {
  if (!is.null(UI_THEORY$content)) return(UI_THEORY$content)
  rd <- function(f) yaml::read_yaml(file.path(dir, f))
  ids <- vapply(ui_theory_outline, `[[`, "", "id")
  chapters <- stats::setNames(lapply(ids, function(id) rd(paste0(id, ".yaml"))), ids)
  for (o in ui_theory_outline) if (!identical(chapters[[o$id]]$chapter$title, o$title) || !identical(vapply(chapters[[o$id]]$topics, `[[`, "", "title"), o$topics))
    stop("theory: the titles in ", o$id, ".yaml differ from ui_theory_outline")
  UI_THEORY$content <- list(chapters = chapters, economy = rd("economy.yaml"), modules = rd("modules.yaml"), labels = rd("labels.yaml"))
  UI_THEORY$content
}
# A word of labels.yaml, its placeholders {name} filled (as ui_s does for strings.yaml).
ui_theory_label <- function(key, ...) {
  e <- ui_theory_content()$labels[[key]]; if (is.null(e)) stop("theory: no label ", key, " in labels.yaml")
  txt <- e$text; a <- list(...)
  for (nm in names(a)) txt <- gsub(paste0("{", nm, "}"), paste(a[[nm]], collapse = ""), txt, fixed = TRUE)
  txt
}
# A value of economy.yaml by its path, for example P4.money.money_stock.
ui_theory_value <- function(path) {
  x <- ui_theory_content()$economy
  for (p in strsplit(path, ".", fixed = TRUE)[[1]]) { x <- x[[p]]; if (is.null(x)) stop("theory: no ", path, " in economy.yaml") }
  x
}
# Links between passages: an anchor P4, P4-s7 or P2-s1d as its chapter, the topic's number and the step.
ui_theory_anchor <- function(ref) {
  p <- strsplit(ref, "-", fixed = TRUE)[[1]]; ch <- ui_theory_content()$chapters[[p[1]]]
  if (is.null(ch)) stop("theory: no chapter for the link ", ref)
  if (length(p) == 1L) return(list(chapter = p[1], k = 1L, step = NULL))
  for (k in seq_along(ch$topics)) {
    if (identical(ch$topics[[k]]$id, p[2])) return(list(chapter = p[1], k = k, step = NULL))
    if (p[2] %in% vapply(ch$topics[[k]]$steps, `[[`, "", "id")) return(list(chapter = p[1], k = k, step = p[2]))
  }
  stop("theory: no topic or step for the link ", ref)
}
# An element that opens a topic: data-theory-go (chapter:topic), the step to scroll to, for a link the static page's file.
ui_theory_go <- function(chapter, k, step = NULL, href = FALSE) {
  frag <- if (!is.null(step)) sprintf("step-%s-%s", chapter, step)
  c(if (href) list(href = sprintf("theory_%s_%d.html%s", chapter, as.integer(k), if (is.null(frag)) "" else paste0("#", frag))),
    list(`data-theory-go` = sprintf("%s:%d", chapter, as.integer(k)), `data-theory-step` = frag))
}

# --- the prose: Markdown, links, term boxes ---------------------------------------------------------------------------------------

# The prose: a text's Markdown as HTML, its links opening their topic, its marked terms with their boxes.
ui_theory_md <- function(md, chapter, step, main = TRUE) {
  html <- commonmark::markdown_html(md %||% "", extensions = "table")
  ui_theory_terms(ui_theory_links(html), chapter, step, main)
}
# [label](theory:P2-s1d) as a link to its chapter, topic or step.
ui_theory_links <- function(html) {
  m <- gregexpr('(?s)<a href="theory:([^"]+)">(.*?)</a>', html, perl = TRUE); hits <- regmatches(html, m)[[1]]
  if (!length(hits)) return(html)
  regmatches(html, m) <- list(vapply(hits, function(h) {
    a <- ui_theory_anchor(sub('(?s)^<a href="theory:([^"]+)">.*$', "\\1", h, perl = TRUE))
    game_tag("a", c(list(class = "tlink"), ui_theory_go(a$chapter, a$k, a$step, href = TRUE)), gsub("\n", " ", sub('(?s)^<a href="theory:[^"]+">(.*)</a>$', "\\1", h, perl = TRUE)))
  }, "", USE.NAMES = FALSE))
  html
}
# Term boxes: a card's explanation as shown, the glossary's (scripts appendix §8.2) with its first letter raised and a full stop.
ui_theory_core <- function(card) {
  x <- card$core %||% ""
  if (isTRUE(card$glossary)) x <- paste0(game_upper_first(x), if (grepl("[.!?]$", x)) "" else ".")
  x
}
# Term boxes: [label](term:P4:id) as the term with its box (term, explanation, example, where it is defined); plain without a box and where its own step defines it in bold.
ui_theory_terms <- function(html, chapter, step, main) {
  m <- gregexpr('(?s)(<strong>)?<a href="term:([A-Z0-9]+):([A-Za-z0-9_]+)">(.*?)</a>', html, perl = TRUE); hits <- regmatches(html, m)[[1]]
  if (!length(hits)) return(html)
  chs <- ui_theory_content()$chapters; num <- function(id) match(id, names(chs))
  regmatches(html, m) <- list(vapply(seq_along(hits), function(n) {
    h <- hits[n]; bold <- startsWith(h, "<strong>")
    cc <- sub('(?s)^(<strong>)?<a href="term:([A-Z0-9]+):.*$', "\\2", h, perl = TRUE); id <- sub('(?s)^(<strong>)?<a href="term:[A-Z0-9]+:([A-Za-z0-9_]+)">.*$', "\\2", h, perl = TRUE)
    lab <- gsub("\n", " ", sub('(?s)^(<strong>)?<a href="term:[^"]+">(.*)</a>$', "\\2", h, perl = TRUE)); pre <- if (bold) "<strong>" else ""
    card <- chs[[cc]]$cards[[id]]; if (is.null(card)) stop("theory: no card ", cc, ":", id)
    if (isFALSE(card$box) || (bold && main && identical(cc, chapter) && identical(card$step, step))) return(paste0(pre, lab))
    where <- function(c2, st, key) { a <- ui_theory_anchor(paste0(c2, "-", st)); tp <- chs[[c2]]$topics[[a$k]]$title
      game_tag("span", list(class = "term-where"), game_tag("a", c(list(class = "tlink"), ui_theory_go(a$chapter, a$k, a$step, href = TRUE)),
        game_esc(if (key == "here") ui_theory_label("term.introduced_here", topic = tp) else ui_theory_label(paste0("term.", key), n = num(c2), topic = tp)))) }
    w1 <- if (!is.null(card$step) && !(identical(cc, chapter) && identical(card$step, step))) where(cc, card$step, if (identical(cc, chapter)) "here" else "introduced_in")
    w2 <- if (!is.null(card$see_also)) { sa <- strsplit(card$see_also, ":", fixed = TRUE)[[1]]; where(sa[1], chs[[sa[1]]]$cards[[sa[2]]]$step, "defined_in") }
    bid <- sprintf("tb-%s-%s-%s%d", chapter, step, if (main) "m" else "d", n)
    paste0(pre, game_tag("span", list(class = "term", tabindex = "0", `aria-describedby` = bid), lab,
      game_tag("span", list(class = "term-box", role = "tooltip", id = bid), game_tag("strong", list(), game_esc(card$term)), " ", game_esc(ui_theory_core(card)),
               if (!is.null(card$example)) game_tag("span", list(class = "term-example"), game_esc(ui_theory_label("term.example", text = card$example))), w1, w2)))
  }, ""))
  html
}

# --- the rail and the page ----------------------------------------------------------------------------------------------------------

# The rail, its title with the line on the example economy, the chapters and the current chapter's topics, each
# opening its topic (the reading statuses are theory.js's).
ui_theory_rail_html <- function(chapter, k) {
  items <- vapply(seq_along(ui_theory_outline), function(n) { c <- ui_theory_outline[[n]]; cur <- identical(c$id, chapter)
    topics <- if (cur) game_tag("ol", list(class = "toc-topics"), paste(vapply(seq_along(c$topics), function(j)
      game_tag("li", c(list(class = paste("toc-topic", if (j == k) "st-in_progress is-current" else "st-not_seen"), tabindex = "0", `aria-current` = if (j == k) "page"), ui_theory_go(c$id, j)),
               game_tag("span", list(class = "num"), as.character(j)), game_tag("span", list(), game_esc(c$topics[j]))), ""), collapse = ""))
    game_tag("li", list(class = paste("toc-chap", if (cur) "st-in_progress" else "st-not_seen"), `data-chap` = c$id, `data-topics` = length(c$topics)),
             game_tag("div", c(list(class = "toc-head", tabindex = "0"), ui_theory_go(c$id, if (cur) k else 1L)), game_tag("span", list(class = "num"), as.character(n)), game_tag("span", list(), game_esc(c$title))), topics) }, "")
  paste0(game_tag("h1", list(), game_esc(ui_s("theory.title"))), game_p("theory-note", game_esc(ui_s("theory.economy_note"))),
         game_tag("ol", list(class = "toc"), paste(items, collapse = "")))
}
# A step: its prose, its More Detail panel, its module, its figure.
ui_theory_step_html <- function(chapter, tp, st) {
  more <- if (!is.null(st$details)) game_tag("details", list(class = "more"), game_tag("summary", list(), game_esc(ui_s("theory.more", title = st$details$title))),
                                              game_tag("div", list(class = "prose"), ui_theory_md(st$details$text, chapter, st$id, main = FALSE)))
  module <- if (!is.null(st$module)) ui_theory_module_html(chapter, tp, st)
  figure <- if (!is.null(st$figure)) ui_theory_figure_html(st$figure$kind, st$figure$description)
  game_tag("div", list(class = "step", id = sprintf("step-%s-%s", chapter, st$id)), game_tag("div", list(class = "prose"), ui_theory_md(st$text, chapter, st$id)), more, module, figure)
}
# A topic's page: the bar that leads back, the rail, the steps, Previous topic, Next topic, Continue to chapter n or Mark chapter as read.
ui_theory_html <- function(chapter = "P1", k = 1L, back = c("desk", "runs", "menu")) {
  back <- match.arg(back); n <- match(chapter, vapply(ui_theory_outline, `[[`, "", "id")); if (is.na(n)) stop("theory: no chapter ", chapter)
  ch <- ui_theory_content()$chapters[[chapter]]; m <- length(ch$topics); k <- max(1L, min(m, as.integer(k))); tp <- ch$topics[[k]]
  nxt <- if (n < length(ui_theory_outline)) ui_theory_outline[[n + 1L]]$id else NA_character_
  done <- list(`data-theory-done` = sprintf("%s:%d", chapter, k))
  nav <- game_tag("div", list(class = "navrow"),
    if (k > 1L) game_tag("button", c(list(type = "button", class = "btn-quiet"), ui_theory_go(chapter, k - 1L)), game_esc(ui_s("theory.previous"))) else game_tag("span", list(), ""),
    if (k < m) game_tag("button", c(list(type = "button", class = "btn-main"), ui_theory_go(chapter, k + 1L), done), game_esc(ui_s("theory.next")))
    else if (!is.na(nxt)) game_tag("button", c(list(type = "button", class = "btn-main"), ui_theory_go(nxt, 1L), done), game_esc(ui_s("theory.continue_chapter", n = n + 1L)))
    else game_tag("button", list(type = "button", class = "btn-main", `data-theory-read` = chapter), game_esc(ui_s("theory.mark_read"))))
  main <- paste0(game_p("chap", game_esc(ui_s("theory.chapter_topic", n = n, k = k, m = m))), game_tag("h2", list(id = "topic-title", tabindex = "-1"), game_esc(tp$title)),
                 paste(vapply(tp$steps, function(st) ui_theory_step_html(chapter, tp, st), ""), collapse = ""), nav)
  paste0(game_tag("div", list(class = "topbar theory-bar", role = "navigation", `aria-label` = ui_s("theory.bar_label")),
                  game_tag("button", list(type = "button", class = "theory-back", `data-game` = "theory_back"), game_esc(ui_s(paste0("theory.back_", back))))),
         game_tag("div", list(class = "shell", `data-view` = "theory", `data-theory-at` = sprintf("%s:%d", chapter, k)),
                  game_tag("div", list(class = "rail"), ui_theory_rail_html(chapter, k)), game_tag("div", list(class = "main"), main)))
}

# --- the modules' frames -------------------------------------------------------------------------------------------------------------

# A module's frame, its sliders at the example economy's values, its configuration in data-config for 02_Game/web/theory.js.
ui_theory_module_html <- function(chapter, tp, st) {
  mod <- st$module; kind <- mod$kind; spec <- ui_theory_content()$modules[[kind]]; if (is.null(spec)) stop("theory: no module ", kind, " in modules.yaml")
  key <- sprintf("tm-%s-%s", chapter, st$id); controls <- as.character(unlist(mod$controls))
  data <- if (kind == "circular_flow") tp$circular_flow else if (!is.null(spec$data)) ui_theory_value(spec$data)
  sliders <- lapply(stats::setNames(controls, controls), function(c) { s <- spec$sliders[[c]]; if (is.null(s)) stop("theory: no slider ", c, " for ", kind)
    s$value <- if (!is.null(s$from)) ui_theory_value(s$from) else s$value; s$from <- NULL; s })
  cfg <- list(kind = kind, key = key, controls = I(controls), show = I(as.character(unlist(mod$show))), view = mod$view, sliders = sliders,
              spec = spec[setdiff(names(spec), c("sliders", "data"))], data = data,
              words = list(now = ui_s("theory.readout_now"), change = ui_s("theory.readout_change"), back = ui_s("theory.back_example")))
  attrs <- list(class = paste("theory-module", paste0("tm-", kind)), `data-module` = kind, `data-config` = as.character(jsonlite::toJSON(cfg, auto_unbox = TRUE, digits = NA, null = "null")))
  slider_html <- paste(vapply(controls, function(c) { s <- sliders[[c]]; id <- paste0(key, "-", c)
    game_tag("div", list(class = "theory-slider"), game_tag("label", list(class = "control-label", `for` = id), game_esc(s$label)),
             game_tag("div", list(class = "ts-row"), game_void("input", list(type = "range", id = id, min = s$min, max = s$max, step = s$step, value = s$value, `data-key` = c)),
                      game_tag("output", list(`for` = id, class = "ts-value"), game_esc(format(s$value))))) }, ""), collapse = "")
  reset <- game_tag("button", list(type = "button", class = "btn-quiet", `data-theory-reset` = "1"), game_esc(ui_s("theory.back_example")))
  out <- game_tag("div", list(class = "tm-out"), game_tag("div", list(class = "tm-figure"), ""), game_tag("table", list(class = "p3-readout"), ""), game_p("p3-caption", ""))
  body <- switch(kind,
    circular_flow = game_tag("div", attrs, ""),
    timeline = game_tag("div", attrs, paste(vapply(seq_along(tp$stations), function(j) ui_theory_station_html(tp$stations[[j]], chapter, st$id, j), ""), collapse = "")),
    price_toggle = game_tag("div", attrs, game_tag("fieldset", list(class = "tm-toggle"), game_tag("legend", list(), game_esc(spec$legend)),
      paste(vapply(names(spec$options), function(o) game_tag("label", list(), game_void("input", list(type = "radio", name = key, value = o, checked = identical(o, names(spec$options)[1]))), " ", game_esc(spec$options[[o]])), ""), collapse = "")), out),
    labour_flows = game_tag("div", attrs, if (length(controls)) game_tag("div", list(class = "p5-toolbar"),
      game_tag("div", list(class = "p5-anim-bar"), game_tag("button", list(type = "button", class = "btn-main tm-play"), game_esc(spec$text$play)),
               game_tag("button", list(type = "button", class = "btn-quiet tm-slump"), game_esc(gsub("{f}", format(ui_theory_value("P5.slump.finding_rate")), spec$text$slump, fixed = TRUE))), reset,
               game_tag("span", list(class = "p5-rm-note"), game_esc(spec$text$reduced))), game_tag("div", list(class = "p4-controls"), slider_html)), out),
    project_pool = game_tag("div", attrs, out, if (length(controls)) game_tag("div", list(class = "p4-controls"), slider_html, reset)),
    game_tag("div", c(attrs[-1], list(class = paste(attrs$class, "p3-module", if (!length(controls)) "tm-wide"))), out, if (length(controls)) game_tag("div", list(class = "p3-controls"), slider_html, reset)))
  if (kind == "circular_flow") return(game_tag("div", list(class = "panel"), game_tag("h3", list(), game_esc(ui_theory_label("flow.title"))),
                                               game_tag("div", list(class = "prose"), ui_theory_md(tp$circular_flow$intro, chapter, st$id, main = FALSE)), body))
  game_tag("div", list(class = "panel"), body)
}
# The timeline: a station: its period, title, puzzle, idea, the economists it names and its lesson.
ui_theory_station_html <- function(s, chapter, step, j) {
  game_tag("div", list(class = "station", `data-station` = j),
           game_tag("div", list(class = "period"), game_esc(s$period)), game_tag("h4", list(), game_esc(s$title)), game_p("puzzle", game_esc(s$puzzle)),
           game_tag("div", list(class = "prose"), ui_theory_md(s$idea, chapter, step, main = FALSE)),
           if (length(s$figures)) game_p("who", game_esc(paste(unlist(s$figures), collapse = ", "))),
           game_tag("div", list(class = "lesson"), sub("^<p>(.*)</p>\n?$", "\\1", ui_theory_md(s$lesson, chapter, step, main = FALSE))))
}

# --- the static figures: SVG drawn from economy.yaml in the desk's look (02_Game/web/theory.css, the tokens of 02_Game/web/base.css) ----------------

# A figure's svg element, its description for screen readers.
ui_theory_svg <- function(w, h, label, body, cls = "") sprintf('<svg class="tfig %s" viewBox="0 0 %d %d" role="img" aria-label="%s">%s</svg>', cls, as.integer(w), as.integer(h), game_esc(label), paste(body, collapse = ""))
# A text in a figure.
ui_theory_tx <- function(x, y, s, cls = "", anchor = "start") sprintf('<text x="%.1f" y="%.1f" class="%s" text-anchor="%s">%s</text>', x, y, cls, anchor, game_esc(s))
# A line in a figure.
ui_theory_ln <- function(x1, y1, x2, y2, cls) sprintf('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" class="%s"/>', x1, y1, x2, y2, cls)
# A rectangle in a figure.
ui_theory_rc <- function(x, y, w, h, cls, title = NULL) sprintf('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" class="%s">%s</rect>', x, y, max(w, 0), max(h, 0), cls, if (is.null(title)) "" else paste0("<title>", game_esc(title), "</title>"))
# A polyline in a figure.
ui_theory_pl <- function(x, y, cls) sprintf('<polyline points="%s" class="%s"/>', paste(sprintf("%.1f,%.1f", x, y), collapse = " "), cls)
# A point in a figure.
ui_theory_pt <- function(x, y, cls, r = 5) sprintf('<circle cx="%.1f" cy="%.1f" r="%s" class="%s"/>', x, y, r, cls)
# An amount with thousands marked and the typographic minus.
ui_theory_n <- function(x, d = 0) game_num(x, d, big = TRUE)
# A change with its sign, as many decimals as it has.
ui_theory_sg <- function(x) paste0(if (x > 0) "+" else if (x < 0) GAME_MINUS else "", format(abs(x)))
# The figure of a step by its kind (the chapter files' `figure`).
ui_theory_figure_html <- function(kind, label) {
  e <- ui_theory_content()$economy
  switch(kind, stacked_bar = ui_theory_fig_value_added(e$P2, label), three_bars = ui_theory_fig_three_bars(e$P2, label), line = ui_theory_fig_lines(e$P2, label),
         horizons = ui_theory_fig_horizons(e$P3$horizons, label), multiplier_rounds = ui_theory_fig_rounds(e$P3, label),
         price_indices = ui_theory_fig_price_indices(e$P2, e$P4, label), balance_sheet = ui_theory_fig_balance_sheet(e$P4, label),
         labour_force = ui_theory_fig_labour_force(e$P5, label), okun = ui_theory_fig_okun(e$P5$okun, label),
         production_function = ui_theory_fig_production(e$P6, label), output_gap = ui_theory_fig_gap(e$P6, label), growth_accounting = ui_theory_fig_accounting(e$P6, label),
         stop("theory: no figure ", kind))
}
# P2: a firm's value added, its sales minus what it buys from other firms.
ui_theory_value_added <- function(f) sum(unlist(f$sales)) - sum(unlist(f$inputs))
# P2: the output of a year valued at the prices of a year (nominal: the same year; real: the base year 1).
ui_theory_valued <- function(goods, t, at) sum(vapply(goods, function(g) g$q[[t]] * g$p[[at]], 0))
# Stacked bars with their parts labelled beside them and their totals above (the figures of P2, topic 1).
ui_theory_bars <- function(bars, top, w, h, label, cls) {
  L <- 40; T <- 24; B <- 40; H <- h - T - B; slot <- (w - L - 20) / length(bars); bw <- min(110, slot * 0.28)
  y <- function(v) T + H - v / top * H; out <- character(0)
  for (j in seq_along(bars)) { b <- bars[[j]]; x <- L + (j - 1) * slot + 12; acc <- 0
    for (i in seq_along(b$parts)) { v <- b$parts[[i]]
      out <- c(out, ui_theory_rc(x, y(acc + v), bw, y(acc) - y(acc + v), sprintf("tf-c%d", (i - 1) %% 6 + 1), sprintf("%s: $%s million", names(b$parts)[i], ui_theory_n(v))))
      if (y(acc) - y(acc + v) >= 15) out <- c(out, ui_theory_tx(x + bw + 8, (y(acc) + y(acc + v)) / 2 + 4, sprintf("%s %s", names(b$parts)[i], ui_theory_n(v)), "tf-seg"))
      acc <- acc + v }
    out <- c(out, ui_theory_tx(x + bw / 2, y(acc) - 7, ui_theory_n(acc), "tf-tot", "middle"), ui_theory_tx(x + bw / 2, h - 16, b$label, "tf-lab", "middle")) }
  ui_theory_svg(w, h, label, c(ui_theory_ln(L - 10, y(0), w - 10, y(0), "tf-axis"), out), cls)
}
# P2, topic 1, the stacked bar: the bread's $520 million as the value added by the farm, the mill and the bakery.
ui_theory_fig_value_added <- function(d, label) {
  f <- Filter(function(x) x$id %in% unlist(d$chain), d$firms)
  parts <- stats::setNames(vapply(f, ui_theory_value_added, 0), vapply(f, function(x) paste(x$name, "adds"), ""))
  ui_theory_bars(list(list(label = "The bread, $ million", parts = parts)), sum(parts) * 1.12, 520, 300, label, "tf-narrow")
}
# P2, topic 1, the three bars: GDP of $900 million by production, expenditure and income.
ui_theory_fig_three_bars <- function(d, label) {
  prod <- stats::setNames(vapply(d$firms, ui_theory_value_added, 0), vapply(d$firms, `[[`, "", "name"))
  ex <- c("Consumption C" = sum(unlist(d$expenditure$C)), "Investment I" = sum(unlist(d$expenditure$I)), "Government spending G" = sum(unlist(d$expenditure$G)))
  inc <- c(Wages = sum(vapply(d$firms, `[[`, 0, "wages")), Profits = sum(vapply(d$firms, `[[`, 0, "profits")))
  ui_theory_bars(list(list(label = "Production (value added)", parts = prod), list(label = "Expenditure", parts = ex), list(label = "Income", parts = inc)), sum(prod) * 1.08, 820, 380, label, "tf-wide")
}
# P2, topic 2, the lines: nominal and real output over the three years of the price example.
ui_theory_fig_lines <- function(d, label) {
  yrs <- seq_along(d$goods[[1]]$q); nom <- vapply(yrs, function(t) ui_theory_valued(d$goods, t, t), 0); real <- vapply(yrs, function(t) ui_theory_valued(d$goods, t, 1), 0)
  w <- 600; h <- 280; L <- 56; R <- 130; T <- 24; B <- 40; lo <- 700; hi <- 870
  x <- function(t) L + (t - 1) / (length(yrs) - 1) * (w - L - R); y <- function(v) T + (hi - v) / (hi - lo) * (h - T - B)
  out <- c(vapply(seq(lo, hi, 50), function(v) paste0(ui_theory_ln(L, y(v), w - R + 10, y(v), "tf-grid"), ui_theory_tx(L - 8, y(v) + 4, ui_theory_n(v), "tf-tick", "end")), ""),
           vapply(yrs, function(t) ui_theory_tx(x(t), h - 14, paste("Year", t), "tf-lab", "middle"), ""))
  for (s in list(list(v = nom, cls = "tf-s1", lab = "Nominal: each year's prices", dy = -10), list(v = real, cls = "tf-s2", lab = "Real: year-1 prices", dy = 20)))
    out <- c(out, ui_theory_pl(x(yrs), y(s$v), paste("tf-line", s$cls)), vapply(yrs, function(t) paste0(ui_theory_pt(x(t), y(s$v[t]), paste("tf-dot", s$cls), 4),
             if (t > 1) ui_theory_tx(x(t), y(s$v[t]) + s$dy, ui_theory_n(s$v[t]), paste("tf-val", s$cls), "middle") else ""), ""),
             ui_theory_tx(x(length(yrs)) + 12, y(s$v[length(yrs)]) + 4, s$lab, paste("tf-val", s$cls)))
  ui_theory_svg(w, h, label, c(out, ui_theory_tx(x(1), y(nom[1]) - 10, ui_theory_n(nom[1]), "tf-val", "middle")), "tf-mid")
}
# P3, topic 1, the horizons: a schematic output path; a downturn fades back to the trend, which rises by 2% a year.
ui_theory_fig_horizons <- function(d, label) {
  w <- 640; h <- 360; L <- 30; R <- 24; T <- 100; B <- 40; W <- w - L - R; H <- h - T - B
  t <- seq(0, d$years, by = 0.25); trend <- 100 * (1 + d$trend_growth / 100)^t
  s0 <- pmax(t - d$downturn_start, 0); dip <- (s0 / d$trough_after) * exp(1 - s0 / d$trough_after); path <- trend * (1 - d$depth / 100 * dip)
  lo <- min(path) * 0.92; hi <- max(trend) * 1.03; x <- function(v) L + v / d$years * W; y <- function(v) T + H - (v - lo) / (hi - lo) * H
  t0 <- d$downturn_start; low <- which.min(path - trend)
  brace <- function(a, b, yy) sprintf('<path d="M%.1f %.1f v6 H%.1f v-6" class="tf-brace"/>', x(a), yy, x(b))
  ui_theory_svg(w, h, label, c(ui_theory_pl(x(t), y(trend), "tf-trend"), ui_theory_pl(x(t), y(path), "tf-line tf-s1"),
    brace(t0, t0 + 5, 16), ui_theory_tx(x(t0 + 5) + 8, 22, "short run: a few years, output follows demand", "tf-note"),
    brace(t0, t0 + 14, 42), ui_theory_tx(x(t0 + 14) + 8, 48, "medium run: about a decade, back to the trend", "tf-note"),
    brace(0.5, d$years, 68), ui_theory_tx(x(d$years), 90, sprintf("long run: decades, the trend itself rises by %s%% a year", format(d$trend_growth)), "tf-note", "end"),
    ui_theory_tx(x(d$years * 0.78), y(100 * (1 + d$trend_growth / 100)^(d$years * 0.78)) - 12, "trend", "tf-note", "end"),
    ui_theory_tx(x(t[low]), y(path[low]) + 22, "downturn", "tf-note", "middle"), ui_theory_tx(x(t0 + 9), y(path[match(t0 + 9, t)]) + 18, "output", "tf-key tf-s1"),
    ui_theory_ln(L, T + H, L + W, T + H, "tf-axis"), ui_theory_tx(L + W / 2, h - 12, "Years (schematic)", "tf-lab", "middle")), "tf-mid")
}
# P3, topic 4, the multiplier rounds: the extra output after each round of a rise in government spending.
ui_theory_fig_rounds <- function(d, label) {
  c1 <- d$params$c1; dA <- d$rounds$change; n <- d$rounds$shown; extra <- dA * c1^(0:(n - 1)); cum <- cumsum(extra); lim <- dA / (1 - c1)
  w <- 600; h <- 300; L <- 56; R <- 20; T <- 30; B <- 44; W <- w - L - R; H <- h - T - B; slot <- W / n; bw <- slot * 0.62
  y <- function(v) T + H - v / (lim * 1.12) * H
  out <- c(ui_theory_ln(L, y(lim), L + W, y(lim), "tf-limit"),
           ui_theory_tx(L + 4, y(lim) - 8, sprintf("the limit: %s × 1 / (1 − %s) = %s", format(dA), format(c1), format(lim)), "tf-note"))
  for (k in seq_len(n)) { x0 <- L + (k - 0.5) * slot - bw / 2; before <- if (k > 1) cum[k - 1] else 0
    out <- c(out, ui_theory_rc(x0, y(before), bw, y(0) - y(before), "tf-old"), ui_theory_rc(x0, y(cum[k]), bw, y(before) - y(cum[k]), "tf-new"),
             if (extra[k] >= 0.12 * dA) ui_theory_tx(x0 + bw / 2, y(cum[k]) - 5, paste0("+", format(round(extra[k], 2))), "tf-tick", "middle"),
             ui_theory_tx(x0 + bw / 2, T + H + 16, as.character(k), "tf-tick", "middle")) }
  ui_theory_svg(w, h, label, c(out, ui_theory_ln(L, y(0), L + W, y(0), "tf-axis"), ui_theory_tx(L + W / 2, h - 6, "Round", "tf-lab", "middle"),
                               sprintf('<text transform="translate(16,%.1f) rotate(-90)" class="tf-lab" text-anchor="middle">Extra output so far ($ million)</text>', T + H / 2)), "tf-mid")
}
# P4, topic 1, the price indices: the GDP deflator and the consumer price index over the three years.
ui_theory_fig_price_indices <- function(d2, d4, label) {
  g <- d2$goods; yrs <- seq_along(g[[1]]$q); basket <- Filter(function(x) x$id %in% unlist(d4$basket), g)
  def <- vapply(yrs, function(t) 100 * ui_theory_valued(g, t, t) / ui_theory_valued(g, t, 1), 0)
  cpi <- vapply(yrs, function(t) 100 * sum(vapply(basket, function(b) b$q[[1]] * b$p[[t]], 0)) / sum(vapply(basket, function(b) b$q[[1]] * b$p[[1]], 0)), 0)
  w <- 640; h <- 300; L <- 52; R <- 190; T <- 20; B <- 40; lo <- 95; hi <- 120; x <- function(t) L + (w - L - R) * (t - 1) / (length(yrs) - 1); y <- function(v) T + (h - T - B) * (1 - (v - lo) / (hi - lo))
  out <- c(vapply(seq(lo, hi, 5), function(v) paste0(ui_theory_ln(x(1), y(v), x(length(yrs)), y(v), "tf-grid"), ui_theory_tx(L - 8, y(v) + 4, v, "tf-tick", "end")), ""),
           vapply(yrs, function(t) ui_theory_tx(x(t), h - 12, paste("Year", t), "tf-lab", "middle"), ""))
  for (s in list(list(v = cpi, cls = "tf-s3", lab = "Consumer price index", dy = -10, d = 0), list(v = def, cls = "tf-s1", lab = "GDP deflator", dy = 20, d = 1)))
    out <- c(out, ui_theory_pl(x(yrs), y(s$v), paste("tf-line", s$cls)), vapply(yrs, function(t) paste0(ui_theory_pt(x(t), y(s$v[t]), paste("tf-dot", s$cls), 4),
             if (t > 1) ui_theory_tx(x(t), y(s$v[t]) + s$dy, ui_theory_n(s$v[t], s$d), paste("tf-val", s$cls), "middle") else ""), ""),
             ui_theory_tx(x(length(yrs)) + 28, y(s$v[length(yrs)]) + if (s$dy < 0) -4 else 14, s$lab, paste("tf-val", s$cls)))
  ui_theory_svg(w, h, label, c(out, ui_theory_tx(x(1), y(100) - 10, "100", "tf-tick", "middle"), ui_theory_ln(x(1), y(lo), x(length(yrs)), y(lo), "tf-axis")), "tf-mid")
}
# P4, topic 3, the balance sheet: the banks' accounts before and after a loan, and the borrower's change.
ui_theory_fig_balance_sheet <- function(d, label) {
  b0 <- d$bank; a <- d$loan$amount; b1 <- b0; b1$loans <- b0$loans + a; b1$deposits <- b0$deposits + a
  acct <- function(x0, y0, title, left, right, changed) {
    w <- 300; rows <- max(length(left), length(right))
    out <- c(ui_theory_tx(x0 + w / 2, y0, title, "tf-acct-title", "middle"), ui_theory_ln(x0, y0 + 10, x0 + w, y0 + 10, "tf-acct-rule"),
             ui_theory_ln(x0 + w / 2, y0 + 10, x0 + w / 2, y0 + 16 + 22 * rows, "tf-acct-rule"),
             ui_theory_tx(x0 + 6, y0 + 28, "Assets", "tf-tick"), ui_theory_tx(x0 + w / 2 + 6, y0 + 28, "Liabilities and capital", "tf-tick"))
    for (side in list(list(v = left, x = x0), list(v = right, x = x0 + w / 2))) for (k in seq_along(side$v)) {
      cls <- if (names(side$v)[k] %in% changed) "tf-acct-chg" else "tf-acct-row"
      out <- c(out, ui_theory_tx(side$x + 6, y0 + 50 + 22 * (k - 1), names(side$v)[k], cls), ui_theory_tx(side$x + w / 2 - 8, y0 + 50 + 22 * (k - 1), ui_theory_n(side$v[[k]]), cls, "end")) }
    out }
  ui_theory_svg(720, 330, label, c(ui_theory_tx(18, 22, "Before the loan", "tf-acct-head"), ui_theory_tx(18, 186, sprintf("After a loan of $%s million to the %s for %s", ui_theory_n(a), tolower(d$loan$borrower), d$loan$purpose), "tf-acct-head"),
    acct(30, 44, "Banks", c(Reserves = b0$reserves, Loans = b0$loans), c(Deposits = b0$deposits, Capital = b0$capital), character(0)),
    acct(30, 208, "Banks", c(Reserves = b1$reserves, Loans = b1$loans), c(Deposits = b1$deposits, Capital = b1$capital), c("Loans", "Deposits")),
    acct(380, 208, sprintf("%s (change)", d$loan$borrower), c(Deposit = a), c(Loan = a), c("Deposit", "Loan"))), "tf-wide")
}
# P5, topic 1, the labour force: the population as nested bars down to the employed and the unemployed.
ui_theory_fig_labour_force <- function(d, label) {
  w <- 680; L <- 20; W <- w - 40; tot <- d$population; x <- function(v) L + W * v / tot; below <- tot - d$working_age_population
  outlf <- d$working_age_population - d$labour_force; u <- 100 * d$unemployed / d$labour_force; part <- 100 * d$labour_force / d$working_age_population
  row <- function(yy, segs) unlist(lapply(segs, function(s) c(ui_theory_rc(x(s$a), yy, x(s$b) - x(s$a), 34, s$cls),
                                                             if (s$b - s$a >= 2000) ui_theory_tx((x(s$a) + x(s$b)) / 2, yy + 22, s$lab, s$tcls %||% "tf-seglab", "middle"))))
  ui_theory_svg(w, 250, label, c(
    ui_theory_tx(L, 22, sprintf("Population %s", ui_theory_n(tot)), "tf-lab"),
    row(30, list(list(a = 0, b = below, cls = "tf-pale", lab = sprintf("Under 15: %s", ui_theory_n(below))), list(a = below, b = tot, cls = "tf-mid-fill", lab = sprintf("Working age %s", ui_theory_n(d$working_age_population))))),
    ui_theory_tx(x(below), 94, sprintf("Working-age population %s", ui_theory_n(d$working_age_population)), "tf-lab"),
    row(102, list(list(a = below, b = below + outlf, cls = "tf-pale", lab = sprintf("Not in the labour force %s", ui_theory_n(outlf))), list(a = below + outlf, b = tot, cls = "tf-mid-fill", lab = sprintf("Labour force %s", ui_theory_n(d$labour_force))))),
    ui_theory_tx(x(below + outlf), 166, sprintf("Labour force %s (participation %s%%)", ui_theory_n(d$labour_force), ui_theory_n(part, 1)), "tf-lab"),
    row(174, list(list(a = below + outlf, b = tot - d$unemployed, cls = "tf-emp", lab = sprintf("Employed %s", ui_theory_n(d$employed)), tcls = "tf-seglab tf-white"), list(a = tot - d$unemployed, b = tot, cls = "tf-unemp", lab = ""))),
    ui_theory_ln(x(tot) - 3, 212, x(tot) - 3, 228, "tf-leader"), ui_theory_tx(x(tot), 242, sprintf("Unemployed %s: rate %s%%", ui_theory_n(d$unemployed), ui_theory_n(u, 1)), "tf-val tf-s3", "end")), "tf-wide")
}
# P5, topic 5, Okun's law: the change in unemployment against output growth, with the text's cases.
ui_theory_fig_okun <- function(d, label) {
  w <- 560; h <- 340; L <- 64; R <- 20; T <- 20; B <- 52; W <- w - L - R; H <- h - T - B; gw <- c(-1, 6); dw <- c(-2.5, 2)
  x <- function(g) L + W * (g - gw[1]) / diff(gw); y <- function(v) T + H * (1 - (v - dw[1]) / diff(dw)); du <- function(g) -d$coefficient * (g - d$normal_growth)
  out <- c(vapply(seq(dw[1], dw[2], 0.5), function(v) paste0(ui_theory_ln(x(gw[1]), y(v), x(gw[2]), y(v), if (v == 0) "tf-zero" else "tf-grid"),
                                                              if (v == round(v)) ui_theory_tx(L - 8, y(v) + 4, if (v > 0) paste0("+", v) else ui_theory_n(v), "tf-tick", "end") else ""), ""),
           vapply(gw[1]:gw[2], function(g) ui_theory_tx(x(g), T + H + 18, paste0(ui_theory_n(g), "%"), "tf-tick", "middle"), ""),
           ui_theory_ln(x(gw[1]), y(du(gw[1])), x(gw[2]), y(du(gw[2])), "tf-okun"), ui_theory_pt(x(d$normal_growth), y(0), "tf-open"),
           ui_theory_tx(x(d$normal_growth) + 8, y(0) - 10, sprintf("normal growth %s%%", format(d$normal_growth)), "tf-note"))
  for (g in unlist(d$examples)) { v <- du(g); left <- g > d$normal_growth && g < max(unlist(d$examples))
    out <- c(out, ui_theory_pt(x(g), y(v), "tf-dot tf-s1"), ui_theory_tx(x(g) + if (left) -10 else 10, y(v) + if (left) 22 else -12,
             sprintf("g = %s%%: %s point%s", format(g), ui_theory_sg(v), if (abs(v) == 1) "" else "s"), "tf-val tf-s1", if (left) "end" else "start")) }
  ui_theory_svg(w, h, label, c(out, ui_theory_ln(x(gw[1]), y(dw[1]), x(gw[2]), y(dw[1]), "tf-axis"), ui_theory_ln(x(gw[1]), y(dw[1]), x(gw[1]), y(dw[2]), "tf-axis"),
    ui_theory_tx(L + W / 2, h - 10, "Growth of real output g (% a year)", "tf-lab", "middle"),
    sprintf('<text transform="translate(16,%.1f) rotate(-90)" class="tf-lab" text-anchor="middle">Change in unemployment (points)</text>', T + H / 2)), "tf-mid")
}
# P6, topic 1, the production function: Y = K^alpha (A N)^(1 - alpha) against capital; equal additions of capital add less and less.
ui_theory_fig_production <- function(d, label) {
  al <- d$profits / d$output; N <- d$natural_employment; A <- (d$output / d$capital^al)^(1 / (1 - al)) / N; F <- function(K) K^al * (A * N)^(1 - al)
  w <- 560; h <- 340; L <- 64; R <- 48; T <- 20; B <- 52; W <- w - L - R; H <- h - T - B; kw <- c(1000, 3000); yw <- c(650, 1050)
  x <- function(K) L + W * (K - kw[1]) / diff(kw); y <- function(Y) T + H * (1 - (Y - yw[1]) / diff(yw)); K <- seq(kw[1], kw[2], by = 20)
  st <- d$capital + d$capital_steps$add * (0:d$capital_steps$steps); sy <- F(st)
  out <- c(vapply(seq(700, 1050, 50), function(v) paste0(ui_theory_ln(x(kw[1]), y(v), x(kw[2]), y(v), "tf-grid"), ui_theory_tx(L - 8, y(v) + 4, ui_theory_n(v), "tf-tick", "end")), ""),
           vapply(seq(kw[1], kw[2], 500), function(k) ui_theory_tx(x(k), T + H + 18, ui_theory_n(k), "tf-tick", "middle"), ""), ui_theory_pl(x(K), y(F(K)), "tf-line tf-ink"))
  for (i in seq_len(d$capital_steps$steps)) out <- c(out, ui_theory_ln(x(st[i]), y(sy[i]), x(st[i + 1]), y(sy[i]), "tf-step"), ui_theory_ln(x(st[i + 1]), y(sy[i]), x(st[i + 1]), y(sy[i + 1]), "tf-rise"),
                                                     ui_theory_tx(x(st[i + 1]) + 6, (y(sy[i]) + y(sy[i + 1])) / 2 + 4, paste0("+", ui_theory_n(sy[i + 1] - sy[i], 1)), "tf-val tf-s1"))
  ui_theory_svg(w, h, label, c(out, ui_theory_pt(x(d$capital), y(d$output), "tf-dot tf-s1", 6), ui_theory_tx(x(d$capital) - 8, y(d$output) - 12, sprintf("today: $%s million", ui_theory_n(d$output)), "tf-note", "end"),
    ui_theory_tx(x(kw[2]) - 4, y(d$output) + 30, sprintf("each step: +$%s million of capital", ui_theory_n(d$capital_steps$add)), "tf-note", "end"),
    ui_theory_ln(x(kw[1]), y(yw[1]), x(kw[2]), y(yw[1]), "tf-axis"), ui_theory_ln(x(kw[1]), y(yw[1]), x(kw[1]), y(yw[2]), "tf-axis"),
    ui_theory_tx(L + W / 2, h - 10, sprintf("Capital stock ($ million), with %s workers", ui_theory_n(N)), "tf-lab", "middle"),
    sprintf('<text transform="translate(16,%.1f) rotate(-90)" class="tf-lab" text-anchor="middle">Output ($ million a year)</text>', T + H / 2)), "tf-mid")
}
# P6, topic 2, the output gap: potential output and actual output in the text's three cases.
ui_theory_fig_gap <- function(d, label) {
  w <- 560; h <- 300; L <- 64; R <- 20; T <- 30; B <- 64; W <- w - L - R; H <- h - T - B; yw <- c(850, 950); Yn <- d$potential_output
  y <- function(v) T + H * (1 - (v - yw[1]) / diff(yw)); cx <- L + W * (2 * seq_along(d$gaps) - 1) / (2 * length(d$gaps))
  out <- c(vapply(seq(yw[1], yw[2], 25), function(v) paste0(ui_theory_ln(L, y(v), L + W, y(v), "tf-grid"), ui_theory_tx(L - 8, y(v) + 4, ui_theory_n(v), "tf-tick", "end")), ""),
           ui_theory_ln(L, y(Yn), L + W, y(Yn), "tf-potential"), ui_theory_tx(L + 8, y(Yn) + 20, sprintf("Potential output $%s million", ui_theory_n(Yn)), "tf-note"))
  for (i in seq_along(d$gaps)) { cs <- d$gaps[[i]]; gap <- cs$output - Yn; pc <- 100 * gap / Yn; lab2 <- unlist(cs$label)
    if (gap != 0) out <- c(out, sprintf('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" class="tf-arrow" marker-end="url(#tf-head)"/>', cx[i], y(Yn), cx[i], y(cs$output) + if (gap > 0) 9 else -9),
                           ui_theory_tx(cx[i] - 10, (y(Yn) + y(cs$output)) / 2 + 4, sprintf("gap %s%s (%s%s%%)", if (gap > 0) "+" else "−", ui_theory_n(abs(gap)), if (gap > 0) "+" else "−", ui_theory_n(abs(pc), 1)), "tf-note", "end"))
    out <- c(out, ui_theory_pt(cx[i], y(cs$output), "tf-dot tf-s1", 6), ui_theory_tx(cx[i] + 12, y(cs$output) + 4, sprintf("$%s", ui_theory_n(cs$output)), "tf-val tf-s1"),
             ui_theory_tx(cx[i], T + H + 20, lab2[1], "tf-tick", "middle"), ui_theory_tx(cx[i], T + H + 36, lab2[2], "tf-tick", "middle")) }
  head <- '<defs><marker id="tf-head" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M1 1L9 5L1 9z" class="tf-head"/></marker></defs>'
  ui_theory_svg(w, h, label, c(head, out, ui_theory_ln(L, y(yw[1]), L + W, y(yw[1]), "tf-axis"), ui_theory_ln(L, y(yw[1]), L, y(yw[2]), "tf-axis"),
    sprintf('<text transform="translate(16,%.1f) rotate(-90)" class="tf-lab" text-anchor="middle">Output ($ million a year)</text>', T + H / 2)), "tf-mid")
}
# P6, topic 5, growth accounting: g_Y = alpha g_K + (1 - alpha) g_N + g_TFP on the balanced path (g_K = g_Y = n + g_A).
ui_theory_fig_accounting <- function(d, label) {
  al <- d$profits / d$output; gY <- d$labour_force_growth + d$technology_growth; cap <- al * gY; lab <- (1 - al) * d$labour_force_growth
  parts <- list(list(v = cap, lab = "Capital", cls = "tf-c1"), list(v = lab, lab = "Labour", cls = "tf-c2"), list(v = gY - cap - lab, lab = "Technology (TFP)", cls = "tf-c3"))
  w <- 560; L <- 30; T <- 26; W <- w - 60; bh <- 46; x <- function(g) L + W * g / gY; out <- character(0); x0 <- 0
  for (p in parts) { out <- c(out, ui_theory_rc(x(x0), T, x(x0 + p$v) - x(x0), bh, p$cls), ui_theory_tx((x(x0) + x(x0 + p$v)) / 2, T + 20, p$lab, "tf-seglab tf-white", "middle"),
                              ui_theory_tx((x(x0) + x(x0 + p$v)) / 2, T + 37, sprintf("%s points", formatC(p$v, format = "f", digits = 2)), "tf-seglab tf-white", "middle")); x0 <- x0 + p$v }
  ticks <- seq(0, gY, 0.5)
  ui_theory_svg(w, 132, label, c(out, vapply(ticks, function(g) paste0(ui_theory_ln(x(g), T + bh, x(g), T + bh + 5, "tf-axis"), ui_theory_tx(x(g), T + bh + 20, paste0(format(g), "%"), "tf-tick", "middle")), ""),
                                 ui_theory_tx(L + W / 2, T + bh + 46, sprintf("Output growth of %s%% a year", format(gY)), "tf-lab", "middle")), "tf-mid")
}
