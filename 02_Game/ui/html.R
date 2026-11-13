# ui/html.R — the UI layer's helpers: the HTML builders every renderer
# uses (game_esc, game_tag, game_button, game_void), the interface's strings
# ui_s() from 02_Game/ui/strings.yaml (each key with text, where and why) and the
# numbers' formats (the kinds the views carry). The UI formats; the views give
# values with units.

# --- the HTML builders ----------------------------------------------------------------------
game_esc <- function(x) {
  x <- as.character(x)
  x <- gsub("&", "&amp;", x, fixed = TRUE); x <- gsub("<", "&lt;", x, fixed = TRUE); x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub("\"", "&quot;", x, fixed = TRUE); gsub("'", "&#39;", x, fixed = TRUE)
}
# An element: attributes as a named list (NULL and FALSE dropped, TRUE a bare attribute, values escaped), children already-built HTML.
game_tag <- function(name, attrs = list(), ...) {
  a <- character(0)
  for (nm in names(attrs)) {
    v <- attrs[[nm]]
    if (is.null(v) || identical(v, FALSE) || (length(v) == 1 && is.na(v))) next
    a <- c(a, if (isTRUE(v)) nm else sprintf('%s="%s"', nm, game_esc(v)))
  }
  kids <- paste(unlist(list(...)), collapse = "")
  sprintf("<%s%s>%s</%s>", name, if (length(a)) paste0(" ", paste(a, collapse = " ")) else "", kids, name)
}
# An element without children.
game_void <- function(name, attrs = list()) {
  a <- character(0)
  for (nm in names(attrs)) { v <- attrs[[nm]]; if (is.null(v) || identical(v, FALSE) || (length(v) == 1 && is.na(v))) next
    a <- c(a, if (isTRUE(v)) nm else sprintf('%s="%s"', nm, game_esc(v))) }
  sprintf("<%s%s>", name, if (length(a)) paste0(" ", paste(a, collapse = " ")) else "")
}
# A paragraph with its class.
game_p <- function(class, ...) game_tag("p", list(class = class), ...)
# A button that sends its action and topic.
game_button <- function(label, action, class = "btn-quiet", topic = NULL, extra = list())
  game_tag("button", c(list(type = "button", class = class, `data-game` = action, `data-topic` = topic), extra), game_esc(label))
# A button drawn as a link.
game_link <- function(label, action, topic = NULL) game_button(label, action, class = "game-link", topic = topic)
# A text with its **bold** terms and its paragraph breaks kept, nothing else of Markdown.
game_text_html <- function(x) gsub("\\*\\*([^*\n]+?)\\*\\*", "<strong>\\1</strong>", game_esc(x %||% ""), perl = TRUE)
# The first letter in upper or lower case.
game_upper_first <- function(x) vapply(as.character(x), function(z) if (is.na(z) || !nzchar(z)) z else paste0(toupper(substr(z, 1, 1)), substr(z, 2, nchar(z))), "", USE.NAMES = FALSE)
# A label as a CSS class fragment: lower case, words joined by hyphens.
game_slug <- function(x) gsub("^-|-$", "", gsub("[^a-z0-9]+", "-", tolower(x)))

# --- the strings -----------------------------------------------------------------------
UI_STRINGS <- new.env(parent = emptyenv())
# The strings read from their file.
ui_strings_load <- function(path = "02_Game/ui/strings.yaml") {
  y <- yaml::read_yaml(path)
  for (k in names(y)) { e <- y[[k]]; if (!is.list(e) || !all(c("text", "where", "why") %in% names(e))) stop("the string ", k, " needs text, where and why") }
  UI_STRINGS$table <- y; UI_STRINGS$path <- path
  invisible(y)
}
# The strings' table, read at its first use.
ui_strings <- function() { if (is.null(UI_STRINGS$table)) ui_strings_load(); UI_STRINGS$table }
# The text of a key, its placeholders {name} filled from the arguments by name; a key missing or a placeholder left stops.
ui_s <- function(.key, ...) {
  if (!is.character(.key) || length(.key) != 1L) stop("ui_s needs one string key, not ", deparse(.key))
  e <- ui_strings()[[.key]]
  if (is.null(e)) stop("no string with the key ", .key, " in 02_Game/ui/strings.yaml")
  txt <- e$text; args <- list(...)
  for (nm in names(args)) txt <- gsub(paste0("{", nm, "}"), paste(as.character(args[[nm]]), collapse = ""), txt, fixed = TRUE)
  left <- regmatches(txt, gregexpr("\\{[a-z_][a-z0-9_]*\\}", txt))[[1]]
  if (length(left)) stop("the string ", .key, " has an unfilled placeholder: ", paste(left, collapse = ", "))
  txt
}
# Whether a key has a string.
ui_has_string <- function(key) !is.null(ui_strings()[[key]])

# --- the numbers -------------------------------------------------------------------------
GAME_MINUS <- "−"
# The numbers: a number to d decimals with the minus sign, thousands marked if big.
game_num <- function(x, d = 1, big = FALSE) {
  if (is.null(x) || length(x) != 1 || is.na(x)) return(NA_character_)
  r <- round(x, d); if (r == 0) r <- 0
  z <- formatC(abs(r), format = "f", digits = d, big.mark = if (big) "," else "")
  if (r < 0) paste0(GAME_MINUS, z) else z
}
# The numbers: a number with its sign.
game_signed <- function(x, d = 1, big = FALSE) {
  if (is.null(x) || length(x) != 1 || is.na(x)) return(NA_character_)
  r <- round(x, d); if (r == 0) return(formatC(0, format = "f", digits = d))
  paste0(if (r > 0) "+" else GAME_MINUS, formatC(abs(r), format = "f", digits = d, big.mark = if (big) "," else ""))
}
# The views' units as the screen prints them: rates and inflation-like figures in percent a year to two decimals, unemployment in
# percent to two, persons in millions to two, $ bn to none, government spending in percent of its usual level to one, the poll in
# percent to one.
fmt_pct <- function(x, d = 2) if (is.null(x) || !length(x)) "–" else vapply(x, function(z) if (is.na(z)) "–" else paste0(game_num(z, d), " %"), "", USE.NAMES = FALSE)
# The numbers: a rate in percent, two decimals.
fmt_rate <- function(x) fmt_pct(x, 2)
# An amount in $ bn with its sign.
fmt_bn <- function(x) if (is.null(x) || is.na(x)) "–" else ui_s("format.bn", sign = if (x < 0) GAME_MINUS else "", amount = game_num(abs(x), 0, big = TRUE))
# Unemployment in persons, in millions to two decimals.
fmt_persons <- function(x) if (is.null(x) || is.na(x)) "–" else ui_s("format.million", value = game_num(x / 1e6, 2))
# A change with its sign, nothing when missing.
fmt_change <- function(dx, d = 2) if (is.null(dx) || is.na(dx)) "" else game_signed(dx, d)
# A number of quarters in words.
fmt_quarters <- function(n) { n <- as.integer(round(n)); if (n == 1L) ui_s("format.quarters_one", n = n) else ui_s("format.quarters_many", n = n) }
