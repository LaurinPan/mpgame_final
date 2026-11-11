# ui/map.R — the economy's map drawn from map_view (scripts appendix §4: six
# boxes in the UI's places, folded
# by default, their nodes, the arrows from node to node that the browser draws
# from the map's data (02_Game/web/game.js), merged into one line between two folded boxes
# whose infobox lists each relation as a button that unfolds its text; the walk
# through the quarter from the quarter's cause along the arrows; the infoboxes of
# nodes (their text, last quarter's figure where the desk shows it), of arrows
# (named by their two ends, their text, the equation as a small grey line at the
# foot) and of boxes, with no header; the levers' outline, the topic's new nodes
# and arrows in green, the Outcomes box semi-transparent; the three small graphs
# on a3, a12 and g1 from the game set). Pure functions on the view; the texts
# are the content's (content/map.R, scripts appendix §4 word for word).
#
# `opts`: open (the box ids drawn unfolded), pin (a node or arrow id pinned when the map is drawn), walk (the arrow ids the walk follows
# from its start when the map is drawn), lit (nodes and arrows lit, for a walk-through step), at (box id -> c(x, y), a moved box).

# A node's class, the levers keeping their outline (scripts appendix §4).
ui_map_node_class <- function(lever) if (isTRUE(lever)) "kind-your-lever" else "kind-node"
# A box's text wrapped at n characters.
ui_map_wrap <- function(x, n = 27L) {
  out <- character(0); cur <- ""
  for (t in strsplit(x, " ", fixed = TRUE)[[1]]) { if (nzchar(cur) && nchar(cur) + 1 + nchar(t) > n) { out <- c(out, cur); cur <- t } else cur <- if (nzchar(cur)) paste(cur, t) else t }
  c(out, cur)
}
# A box's size, folded or open, by its lines and marks.
ui_map_box_size <- function(n, open, marks = 0L, g = ui_params$map$box) {
  if (!open) return(c(w = g$w, h = g$h + marks * g$mark_line))
  cols <- if (n <= 1L) 1L else 2L; rows <- ceiling(n / cols)
  c(w = 2 * g$pad + cols * g$part_w + (cols - 1L) * g$gap, h = g$head + rows * g$part_h + (rows - 1L) * g$gap + g$pad)
}
# A box's centre kept inside the canvas.
ui_map_clamp <- function(cx, cy, size, W, H) c(min(max(cx, size[["w"]] / 2), W - size[["w"]] / 2), min(max(cy, size[["h"]] / 2), H - size[["h"]] / 2))
# Scripts appendix §4: an arrow's name, its two ends ("Policy Rate → Real Interest Rate").
ui_map_arrow_name <- function(mv, from, to) ui_s("map.arrow_title", from = mv$nodes$name[match(from, mv$nodes$id)], to = mv$nodes$name[match(to, mv$nodes$id)])
# Scripts appendix §4: an arrow's equation line in topic `topic` from the numbers of the model appendix its entry holds ("(A34)",
# "(A22), (A34)", or "(A32); (A6) from Topic 2", the second number only from that topic on): "Equation (A34) of the model appendix.",
# for two "Equations (A32) and (A6) of the model appendix."; an entry that names no number, as it stands ("The Full System of the
# model appendix."); an empty entry, no line.
ui_map_equation <- function(eq, topic) {
  if (is.na(eq) || !nzchar(trimws(eq))) return("")
  t <- as.integer(sub("^T", "", topic)); parts <- trimws(strsplit(eq, "[;,]")[[1]])
  from <- suppressWarnings(as.integer(sub("^.*from Topic ([0-9]+).*$", "\\1", parts))); from[!grepl("from Topic", parts)] <- 1L
  n <- unlist(regmatches(parts[from <= t], gregexpr("\\(A[0-9]+[a-z]?\\)", parts[from <= t])))
  if (!length(n)) ui_s("map.equation_named", entry = trimws(eq))
  else if (length(n) == 1L) ui_s("map.equation", number = n) else ui_s("map.equations", list = paste(n[-length(n)], collapse = ", "), last = n[length(n)])
}
# A node's last-quarter figure in its infobox, only where the desk shows it (scripts appendix §4; never a hidden value).
ui_map_value <- function(field, value) {
  if (is.na(field) || !isTRUE(is.finite(value))) return(NULL)
  switch(field,
    figures.rate = fmt_rate(value), figures.growth = paste(fmt_pct(value), ui_s("chart.unit_pct_year")), figures.inflation = paste(fmt_pct(value), ui_s("chart.unit_pct_year")),
    figures.wage_inflation = paste(fmt_pct(value), ui_s("chart.unit_pct_year")), figures.unemployment = fmt_pct(value), public.expected_inflation = paste(fmt_pct(value), ui_s("chart.unit_pct_year")),
    public.perceived_aim = paste0(game_signed(value, 2), " ", ui_s("map.graph_distance"), " from the target"), game_num(value, 2))
}
# A graph's relation and starting value.
ui_map_graph_data <- function(mv, id) {
  gr <- mv$graphs[[id]]; if (is.null(gr)) return(NULL)
  v <- gr$values
  d <- switch(gr$kind,
    demand_curve = list(kind = "demand_curve", slope = v$slope, x = c(gr$slider$from, gr$slider$to), y = c(-1, 1), step = gr$slider$step),
    trade_off = list(kind = "trade_off", slope = v$slope, lift = v$lift, x = c(-4, 4), y = c(-3, 5), cost = c(gr$slider$from, gr$slider$to), step = gr$slider$step),
    crowding_out = list(kind = "crowding_out", output_share = v$output_share, g = c(gr$slider$from, gr$slider$to), bars = as.list(gr$bars), step = gr$slider$step), NULL)
  if (is.null(d)) return(NULL)
  c(d, list(sliders = list(gr$slider$label), axes = list(gr$x %||% "", gr$y %||% "")))
}
# A graph in its arrow's infobox, with its slider.
ui_map_graph_html <- function(mv, id) {
  gd <- ui_map_graph_data(mv, id); gr <- mv$graphs[[id]]; if (is.null(gd)) return("")
  data <- as.character(jsonlite::toJSON(gd, auto_unbox = TRUE, digits = NA))
  game_tag("div", list(class = "map-graph-area", `data-map-graph` = data, `data-map-for` = id),
           game_tag("h4", list(class = "map-graph-title"), game_esc(gr$question)),
           game_tag("div", list(class = "map-graph", `aria-live` = "polite"), ""),
           game_p("map-graph-caption", game_esc(gr$caption)),
           game_p("map-graph-note", game_esc(ui_s("map.graph_pinned"))))
}
# Scripts appendix §4: an infobox, its name, its text and what follows, the foot last (an arrow's equation); no header.
ui_map_tip <- function(prefix, id, kind, title, body, extra = "", foot = "") {
  tid <- sprintf("%s-tip-%s", prefix, id)
  game_tag("div", list(class = paste("map-tip", paste0("kind-", kind)), id = tid, `data-tip-for` = id, role = "dialog", `aria-modal` = "false", `aria-labelledby` = paste0(tid, "-title"), hidden = TRUE),
    game_tag("div", list(class = "map-tip-head"),
             game_tag("h3", list(class = "map-tip-title", id = paste0(tid, "-title"), tabindex = "-1"), game_esc(title)),
             game_tag("button", list(type = "button", class = "map-tip-close", `data-map` = "unpin", `aria-label` = ui_s("map.close_label")), game_esc(ui_s("map.close")))),
    game_tag("div", list(class = "map-tip-body"), body), extra, foot)
}
# The map's title by topic.
ui_map_title <- function(mv) { s <- load_topic(mv$topic); ui_s("map.title", topic = sub("^T", "", mv$topic), name = s$name) }

# The map of a topic: the canvas with its boxes and nodes, the infoboxes, the legend and the walk box, the data for the script.
ui_map_html <- function(mv, prefix = "map", opts = list()) {
  P <- ui_params$map; g <- P$box; W <- P$canvas[["w"]]; H <- P$canvas[["h"]]; f <- function(x) formatC(x, format = "f", digits = 1)
  nodes <- mv$nodes; arw <- mv$arrows
  nname <- function(id) nodes$name[match(id, nodes$id)]
  boxes <- lapply(seq_len(nrow(mv$boxes)), function(i) { b <- mv$boxes[i, ]; ids <- nodes$id[nodes$box == b$id]; nw <- ids[nodes$new[match(ids, nodes$id)]]
    ml <- if (length(nw)) ui_map_wrap(ui_s("map.box_new", parts = paste(nname(nw), collapse = ", ")), P$mark_wrap) else character(0)
    folded <- ui_map_box_size(length(ids), FALSE, length(ml), g); opened <- ui_map_box_size(length(ids), TRUE, 0L, g)
    home <- P$places[[b$id]]; open <- b$id %in% (opts$open %||% character(0)); at <- opts$at[[b$id]] %||% home
    at <- ui_map_clamp(at[1], at[2], if (open) opened else folded, W, H)
    list(id = b$id, label = b$name, infobox = b$infobox, parts = ids, new = nw, marks = ml, folded = folded, opened = opened, home = home, at = at, open = open, outcomes = identical(b$id, "outcomes")) })
  box_svg <- vapply(boxes, function(b) {
    fw <- b$folded[["w"]]; fh <- b$folded[["h"]]; ow <- b$opened[["w"]]; oh <- b$opened[["h"]]; n <- length(b$parts)
    marks_l <- vapply(seq_along(b$marks), function(j) sprintf('<text class="map-box-new" x="0" y="%s" text-anchor="middle">%s</text>', f(-fh / 2 + 52 + (j - 1) * g$mark_line), game_esc(b$marks[j])), "")
    folded <- sprintf('<g class="map-fold-view" data-map-item="box-%s" role="button" tabindex="-1" aria-label="%s"><rect class="map-box-rect" x="%s" y="%s" width="%s" height="%s" rx="8"/><text class="map-box-title" x="0" y="%s" text-anchor="middle">%s</text><text class="map-box-sub" x="0" y="%s" text-anchor="middle">%s</text>%s</g>',
                      b$id, game_esc(ui_s("map.box_label", box = b$label, parts = n)), f(-fw / 2), f(-fh / 2), f(fw), f(fh), f(-fh / 2 + 22), game_esc(b$label), f(-fh / 2 + 38),
                      game_esc(if (n == 1L) ui_s("map.box_parts_one", n = n) else ui_s("map.box_parts_many", n = n)), paste(marks_l, collapse = ""))
    cols <- if (n <= 1L) 1L else 2L
    ps <- vapply(seq_along(b$parts), function(j) { id <- b$parts[j]; p <- nodes[nodes$id == id, ]
      cx <- -ow / 2 + g$pad + ((j - 1L) %% cols) * (g$part_w + g$gap); cy <- -oh / 2 + g$head + ((j - 1L) %/% cols) * (g$part_h + g$gap)
      lines <- ui_map_wrap(p$name, P$wrap); ty <- cy + g$part_h / 2 - (length(lines) - 1) * 7 + 4.5
      tx <- paste(vapply(seq_along(lines), function(i) sprintf('<tspan x="%s" y="%s">%s</tspan>', f(cx + g$part_w / 2), f(ty + (i - 1) * 14), game_esc(lines[i])), ""), collapse = "")
      badge <- if (isTRUE(p$new)) sprintf('<g class="map-badge is-new"><rect x="%s" y="%s" width="40" height="16" rx="8"/><text x="%s" y="%s" text-anchor="middle">%s</text></g>', f(cx + g$part_w - 44), f(cy - 8), f(cx + g$part_w - 24), f(cy + 4), game_esc(ui_s("map.badge_new"))) else ""
      lit <- id %in% (opts$lit %||% character(0))
      sprintf('<g class="map-part %s%s%s" data-map-item="%s" data-part="%s" tabindex="0" role="button" aria-expanded="false" aria-controls="%s-tip-%s" aria-label="%s" data-x="%s" data-y="%s" data-w="%s" data-h="%s"><rect x="%s" y="%s" width="%s" height="%s" rx="5"/><text class="map-part-label" text-anchor="middle">%s</text>%s</g>',
              ui_map_node_class(p$lever), if (isTRUE(p$new)) " is-new" else "", if (lit) " is-tour-lit" else "", id, id, prefix, id,
              game_esc(if (isTRUE(p$lever)) ui_s("map.part_label_lever", name = p$name) else p$name),
              f(cx), f(cy), f(g$part_w), f(g$part_h), f(cx), f(cy), f(g$part_w), f(g$part_h), tx, badge) }, "")
    opened <- sprintf('<g class="map-open-view"><rect class="map-box-rect%s" x="%s" y="%s" width="%s" height="%s" rx="10"/><text class="map-box-head" x="%s" y="%s">%s</text>%s</g>',
                      if (b$outcomes) " is-band" else "", f(-ow / 2), f(-oh / 2), f(ow), f(oh), f(-ow / 2 + g$pad), f(-oh / 2 + 20), game_esc(b$label), paste(ps, collapse = ""))
    sprintf('<g class="map-box%s%s%s" data-box="%s" data-actor="%s" transform="translate(%s,%s)" tabindex="0" role="group" aria-roledescription="%s" aria-label="%s" data-fw="%s" data-fh="%s" data-ow="%s" data-oh="%s" data-hx="%s" data-hy="%s">%s%s</g>',
            if (b$open) " is-open" else "", if (b$outcomes) " is-outcomes" else "", if (length(b$new)) " has-marks" else "", b$id, b$id, f(b$at[1]), f(b$at[2]),
            game_esc(ui_s("map.box_role")), game_esc(ui_s("map.box_label", box = b$label, parts = n)), f(fw), f(fh), f(ow), f(oh), f(b$home[1]), f(b$home[2]), folded, opened)
  }, "")
  defs <- sprintf(paste0('<defs><marker id="%1$s-head" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path class="map-head" d="M0,0 L10,5 L0,10 z"/></marker>',
                         '<marker id="%1$s-head-new" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path class="map-head is-new" d="M0,0 L10,5 L0,10 z"/></marker>',
                         '<marker id="%1$s-head-lit" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path class="map-head is-lit" d="M0,0 L10,5 L0,10 z"/></marker></defs>'), prefix)
  svg <- sprintf('<svg class="map-svg" viewBox="0 0 %s %s" role="group" aria-label="%s">%s<g class="map-lines"></g><g class="map-boxes">%s</g><g class="map-pins"></g></svg>',
                 f(W), f(H), game_esc(ui_s("map.svg_label", parts = nrow(nodes), links = nrow(arw))), defs, paste(box_svg, collapse = ""))
  # the infoboxes: a node's text with last quarter's figure where the desk shows it, an arrow's text with its small graph and its
  # equation at the foot, a box's text, and the merged line's, which the script fills with one button per relation
  part_tips <- vapply(seq_len(nrow(nodes)), function(i) { p <- nodes[i, ]; v <- ui_map_value(p$field, p$value)
    ui_map_tip(prefix, p$id, "part", p$name, paste0(game_p("map-lead", game_esc(p$infobox)), if (!is.null(v)) game_p("map-value-line", game_esc(ui_s("map.value", value = v))))) }, "")
  arrow_tips <- vapply(seq_len(nrow(arw)), function(i) { a <- arw[i, ]
    ui_map_tip(prefix, a$id, "arrow", ui_map_arrow_name(mv, a$from, a$to), game_p("map-lead", game_esc(a$infobox)), ui_map_graph_html(mv, a$id),
               if (nzchar(ui_map_equation(a$equation, mv$topic))) game_p("map-equation", game_esc(ui_map_equation(a$equation, mv$topic)))) }, "")
  box_tips <- vapply(boxes, function(b) ui_map_tip(prefix, paste0("box-", b$id), "box", b$label, game_p("map-lead", game_esc(b$infobox))), "")
  group_tip <- ui_map_tip(prefix, "group", "group", "", "")
  # the data for the script: the boxes, the nodes with the walk's text, the arrows with theirs (the text and the
  # equation), the walk's start, the words; and the preview's presets (pin, walk, lit)
  bx <- lapply(boxes, function(b) list(id = b$id, label = b$label, parts = as.list(b$parts), home = b$home, at = b$at, open = b$open, folded = unname(b$folded), opened = unname(b$opened)))
  pd <- setNames(lapply(seq_len(nrow(nodes)), function(i) list(name = nodes$name[i], box = nodes$box[i], kind = if (isTRUE(nodes$lever[i])) "lever" else "node", walk = list(nodes$infobox[i]))), nodes$id)
  ad <- lapply(seq_len(nrow(arw)), function(i) { a <- arw[i, ]
    list(id = a$id, row = a$id, from = a$from, to = a$to, kind = "relation", new = isTRUE(a$new),
         walk = as.list(c(a$infobox, if (nzchar(ui_map_equation(a$equation, mv$topic))) ui_map_equation(a$equation, mv$topic))), follow = ui_s("map.walk_follow", part = nname(a$to))) })
  hole <- function(nm) paste0("\001", nm, "\001"); tpl <- function(x) gsub("\001([a-z_]+)\001", "{\\1}", x)
  words <- list(start = ui_s("map.walk_start"), `next` = ui_s("map.walk_next"), previous = ui_s("map.walk_previous"), again = ui_s("map.walk_again"), decision = "",
                group_title = tpl(ui_s("map.group_title", from = hole("from"), to = hole("to"))),
                graph = list(distance = ui_s("map.graph_distance"), percent = ui_s("map.graph_percent"), spending = tpl(ui_s("map.graph_spending", value = hole("value"))),
                             inflation = tpl(ui_s("map.graph_inflation", value = hole("value"))), output = tpl(ui_s("map.graph_output", value = hole("value")))))
  data <- as.character(jsonlite::toJSON(list(topic = mv$topic, canvas = unname(P$canvas), boxes = bx, parts = pd, arrows = ad, start = mv$walk_start, words = words, step = unname(P$step),
                                             pin = opts$pin, walk = if (!is.null(opts$walk)) I(as.character(opts$walk)) else NULL), auto_unbox = TRUE, digits = NA, null = "null"))
  legend <- game_tag("ul", list(class = "map-legend", `aria-label` = ui_s("map.legend_label")),
                     game_tag("li", list(class = "map-key-item"), game_tag("span", list(class = "map-key-kind kind-your-lever", `aria-hidden` = "true"), ""), " ", game_esc(ui_s("map.legend_lever"))),
                     if (any(nodes$new) || any(arw$new)) game_tag("li", list(class = "map-key-item"), game_tag("span", list(class = "map-key-new", `aria-hidden` = "true"), ""), " ", game_esc(ui_s("map.legend_new", topic = sub("^T", "", mv$topic)))))
  walk <- game_tag("section", list(class = "map-walk", `aria-label` = ui_s("map.walk_label")),
                   game_tag("div", list(class = "map-walk-buttons"), game_tag("button", list(type = "button", class = "btn-quiet map-walk-btn", `data-map` = "walk_start"), game_esc(ui_s("map.walk_start")))),
                   game_tag("div", list(class = "map-walk-text", id = paste0(prefix, "-walk-text"), `aria-live` = "polite", hidden = TRUE), ""),
                   game_tag("div", list(class = "map-walk-steps", hidden = TRUE),
                            game_tag("button", list(type = "button", class = "btn-quiet map-walk-btn map-walk-prev", `data-map` = "walk_previous"), game_esc(ui_s("map.walk_previous"))),
                            game_tag("button", list(type = "button", class = "btn-quiet map-walk-btn map-walk-next", `data-map` = "walk_next"), game_esc(ui_s("map.walk_next"))),
                            game_tag("button", list(type = "button", class = "btn-quiet map-walk-btn map-walk-end", `data-map` = "walk_end"), game_esc(ui_s("map.walk_end")))))
  game_tag("div", list(class = "map", id = prefix, `data-map-topic` = mv$topic, `data-pin` = opts$pin),
           game_tag("div", list(class = "map-canvas"),
                    game_tag("button", list(type = "button", class = "btn-quiet map-reset", `data-map` = "reset", `aria-label` = ui_s("map.reset_label")), game_tag("span", list(class = "map-reset-icon", `aria-hidden` = "true"), "↻"), " ", game_esc(ui_s("map.reset"))),
                    svg, game_p("map-keys", game_esc(ui_s("map.keys")))),
           paste(c(part_tips, arrow_tips, box_tips, group_tip), collapse = ""),
           game_tag("div", list(class = "map-foot"), legend, walk),
           game_tag("script", list(type = "application/json", class = "map-data"), gsub("</", "<\\/", data, fixed = TRUE)))
}
# The Desk's map panel, a drop-down window from the screen's top.
ui_map_panel_html <- function(mv, opts = list()) {
  game_tag("div", list(class = "game-window map-panel", role = "dialog", `aria-modal` = "false", `aria-labelledby` = "map-panel-title", `data-window` = "map"),
    game_tag("header", list(class = "window-head"), game_tag("h2", list(class = "window-title", id = "map-panel-title"), game_esc(ui_map_title(mv))),
             game_tag("button", list(type = "button", class = "window-close", `data-game` = "window_close", `aria-label` = ui_s("map.hide_label")), game_esc(ui_s("map.hide")))),
    game_tag("div", list(class = "window-body"), ui_map_html(mv, prefix = "deskmap", opts = opts)))
}
# The Menu's map area, under the selected topic's card.
ui_map_menu_html <- function(mv, opts = list()) {
  game_tag("section", list(class = "game-map-area", `aria-labelledby` = "game-map-title"),
           game_tag("div", list(class = "game-map-head"), game_tag("h2", list(id = "game-map-title", class = "game-map-title"), game_esc(ui_map_title(mv)))),
           ui_map_html(mv, prefix = "menumap", opts = opts))
}
