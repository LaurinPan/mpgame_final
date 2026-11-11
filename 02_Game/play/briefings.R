# 02_Game/play/briefings.R — v6 §11 and §9: the briefings and the walk-throughs read from content/

# v6 §11: a briefing file, its header and its messages
read_briefing <- function(id) {
  lines  <- readLines(file.path("02_Game/content/briefings", paste0(id, ".md")), warn = FALSE, encoding = "UTF-8")
  cuts   <- which(lines == "---")
  header <- lines[seq_len(cuts[1] - 1)]
  h      <- setNames(sub("^[a-z]+: *", "", header), sub(":.*$", "", header))
  bounds <- c(cuts, length(lines) + 1)
  messages <- vapply(seq_along(cuts), function(i) trimws(paste(lines[(bounds[i] + 1):(bounds[i + 1] - 1)], collapse = " ")), "")
  list(id = h[["id"]], trigger = h[["trigger"]], topic = h[["topic"]], quarter = as.integer(h[["quarter"]]),
       kind = h[["kind"]], messages = messages)
}

# v6 §2.3: the briefings a trigger fires, filled from the sheet
briefings_due <- function(script, trigger, q, sheet, guided = NULL) {
  ids <- switch(trigger,
                chapter_open  = script$briefings$chapter_open,
                topic_open    = script$briefings$topic_open,
                quarter_start = { b <- script$briefings$quarter_start; if (as.character(q) %in% names(b)) b[[as.character(q)]] })
  out <- list()
  for (id in ids) {
    b <- read_briefing(id)
    for (i in seq_along(b$messages))
      out[[length(out) + 1]] <- list(q = q, kind = "briefing", id = id, step = i, of = length(b$messages),
                                     briefing_kind = b$kind, text = fill_placeholders(b$messages[i], sheet, guided))
  }
  out
}

# v6 §11: the chapter's and the topic's briefing as one message at a topic's start, ending with the topic briefing's invitation to ask
briefing_start <- function(script, sheet) {
  parts <- c(briefings_due(script, "chapter_open", 1, sheet), briefings_due(script, "topic_open", 1, sheet))
  list(q = 1, kind = "briefing", id = paste(unique(vapply(parts, `[[`, "", "id")), collapse = "+"), step = 1L, of = 1L, briefing_kind = "start",
       text = paste(vapply(parts, `[[`, "", "text"), collapse = " "))
}

# v6 §9: a walk-through as its steps
read_tour <- function(id) {
  lines <- readLines(file.path("02_Game/content/tours", paste0(id, ".md")), warn = FALSE, encoding = "UTF-8")
  heads <- grep("^## ", lines)
  lapply(seq_along(heads), function(i) {
    target <- sub("^## ", "", lines[heads[i]])
    end <- if (i < length(heads)) heads[i + 1] - 1 else length(lines)
    text <- trimws(paste(lines[(heads[i] + 1):end], collapse = " "))
    list(target = sub(" [(].*$", "", target),
         points = if (grepl("[(]", target)) trimws(strsplit(sub("^.*[(](.*)[)].*$", "\\1", target), ",")[[1]]) else character(0),
         text = text)
  })
}
