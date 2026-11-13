# 02_Game/sheet/classify.R — Section 4.3.1 with Table 1 and Section 4.2.2: the quarter's innovations classified as the issue reports them

# Section 4.2.2: the class of a size
size_class <- function(type, size, classes) {
  k <- findInterval(abs(size), c(0, classes$bounds[[type]]))
  classes$names[min(k, 3)]
}

# Section 4.3.1 and Table 1: the quarter's events, the shocks with their classes, the foreseen slump and a vote due
classify <- function(innovations, foreseen, votes, q, classes) {
  types  <- c(a = "technology", z = "demand", nu = "costs", g = "purchases")
  shocks <- list()
  for (col in names(types)) {
    size <- innovations[[col]]
    if (!is.null(size) && !is.na(size) && size != 0) {
      type <- types[[col]]
      sign <- if (size > 0) "positive" else "negative"
      cls  <- size_class(type, size, classes)
      shocks[[type]] <- list(type = type, sign = sign, class = cls, size = size,
                             words = classes$words[[type]][[sign]][[cls]], reported = NA)
    }
  }
  started <- !is.null(foreseen) && isTRUE(foreseen$start == q)
  depth   <- if (started) max(abs(foreseen$d)) else NA
  k       <- if (started) min(findInterval(depth, c(0, classes$bounds$slump)), 3) else NA
  list(shocks = shocks,
       path_started = started, path_class = if (started) classes$names[k] else NA,
       path_words = if (started) classes$words$slump[[k]] else NA,
       path_length = if (!is.null(foreseen) && q >= foreseen$start && q < foreseen$start + length(foreseen$d)) length(foreseen$d) else NA,
       path_depth = depth,
       vote_due = q %in% votes)
}
