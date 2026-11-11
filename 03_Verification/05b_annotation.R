# 05b The hand annotation (Section 3.3, rule 5; the error categories of
# Thomson and Reiter's annotation of generated texts, and the chat's own
# rules). Test 05 checks every figure a text writes; what a text says in
# words is read by hand, in two seeded samples. Each is drawn once into a
# file with one empty column per category, the annotator fills it in, and
# this script summarises both.
#   The pieces: 40 places of the paper from Topics 3 and 8, the same places
#   as the game's model wrote them in the final recordings and as the
#   comparison's model wrote them, 80 pieces in one shuffled order, in
#   03_Verification/annotation_sample.csv. Each piece stands as the player
#   reads it, with the facts its call received, and the model's name in the
#   last column. The reading is blind: that column is hidden in the
#   spreadsheet while the pieces are annotated.
#   The chat: 40 answers of the Chief Economist from the eight final
#   recordings, five per topic, in 03_Verification/annotation_chat_sample.csv.
#   A topic's five answers go to its steps in turn, the step with the most
#   answers first, so that every step the recording holds is drawn. Each
#   answer stands with its topic, quarter and step, the governor's question,
#   the facts and the staff forecast its call received, and the prohibition
#   its instruction held for the topic.
# The annotator reads every text claim by claim against the facts of its
# row and enters in every category cell the number of errors of that kind,
# 0 for none: incorrect number, incorrect named entity, incorrect word,
# context error, not checkable, other. A claim of change where the facts
# give only a level counts as not checkable, a size word is judged by the
# game's own word scale, the one the facts use, and omissions are not
# counted. The chat's seventh column, rule_breach, counts an answer that
# names a rate to set, a number of quarters to promise or a plan to
# announce, that names a hidden value, or that breaks its topic's
# prohibition. A file is never drawn again once it exists, and the files
# stand as the spreadsheet program saved them, with semicolons, a byte-order
# mark and Windows line endings. An empty cell is no zero: the tables are
# written only when every annotation cell of both samples holds a count, and
# until then the script names the rows that lack one and writes nothing. It
# then writes, per sample and category, the errors counted and the texts
# with at least one error, with the 95 percent Wilson interval of their
# share; in the rows "any" the same for a text with at least one error of
# any of the six kinds, which test 05c reads for the pieces; and the chat's
# rule breaches by topic and by step. The pieces' counts are given twice:
# with all errors, and without the incorrect words that only the strict
# reading of the word scale counts, where everyday usage would pass, which
# the annotator noted by piece and which stand below. The tables go into
# 03_Verification/results/05b_annotation.md. Run from the main folder:
# Rscript 03_Verification/05b_annotation.R
file <- "03_Verification/annotation_sample.csv"; chat_file <- "03_Verification/annotation_chat_sample.csv"
folders <- c("03_Verification/recordings", "03_Verification/recordings_comparison")
topics <- c("T3", "T8"); per_model <- 40; per_topic <- 5
categories <- c("incorrect_number", "incorrect_named_entity", "incorrect_word", "context_error", "not_checkable", "other"); chat_columns <- c(categories, "rule_breach")
# the incorrect words that only the strict reading of the word scale counts, as the annotator noted them: the piece's id, and how many of its incorrect words are of this kind
strict_scale <- c("11" = 1, "22" = 1, "51" = 1, "62" = 1)
wilson <- function(x, n) { z <- qnorm(0.975); p <- x / n; den <- 1 + z^2 / n
  ctr <- (p + z^2 / (2 * n)) / den; half <- z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / den; c(p, max(0, ctr - half), min(1, ctr + half)) }
share <- function(x, n) { w <- wilson(x, n); sprintf("%.3f (%.3f to %.3f)", w[1], w[2], w[3]) }
in_words <- function(n) if (n >= 1 && n <= 12) c("one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve")[n] else as.character(n)
lines_of <- function(text) strsplit(text, "\n", fixed = TRUE)[[1]]
block <- function(l, tag) { a <- which(l == paste0("<", tag, ">")); b <- which(l == paste0("</", tag, ">")); if (!length(a)) "" else paste(l[(a + 1):(b - 1)], collapse = " ") }
chat_calls <- function(id) Filter(function(c) c$task == "chat" && isTRUE(c$ok), readRDS(file.path(folders[1], paste0(id, ".rds")))$calls)

# a piece as the player reads it, its elements in the format's order on one line
piece_text <- function(p) { e <- p$elements
  paste(c(e$headline, e$standfirst, e$intro, if (!is.null(e$author)) paste("by", e$author),
          vapply(e$table, function(r) sprintf("[%s: %s; %s]", r$label, r$value, r$change), ""), unlist(e$body),
          vapply(e$qa, function(x) sprintf("Q: %s A: %s", x$question, x$answer), ""), vapply(e$quotes, function(x) sprintf("\"%s\" (%s)", x$text, x$role), "")), collapse = " | ") }

# ---- the pieces' sample, drawn when its file is missing
draw_pieces <- function() {
  runs <- lapply(folders, function(d) setNames(lapply(topics, function(id) readRDS(file.path(d, paste0(id, ".rds")))), topics))
  places <- do.call(rbind, lapply(topics, function(id) do.call(rbind, lapply(seq_along(runs[[1]][[id]]$issues), function(q) data.frame(topic = id, q = q, slot = names(runs[[1]][[id]]$issues[[q]]$pieces), stringsAsFactors = FALSE)))))
  piece_at <- function(k, i) runs[[k]][[places$topic[i]]]$issues[[places$q[i]]]$pieces[[places$slot[i]]]
  both <- vapply(seq_len(nrow(places)), function(i) identical(piece_at(1, i)$source, "model") && identical(piece_at(2, i)$source, "model"), logical(1))
  set.seed(5); drawn <- sort(sample(which(both), per_model))
  rows <- do.call(rbind, lapply(seq_along(folders), function(k) do.call(rbind, lapply(drawn, function(i) { p <- piece_at(k, i); facts <- runs[[k]][[places$topic[i]]]$masks[[places$q[i]]][[places$slot[i]]]
    data.frame(topic = places$topic[i], quarter = places$q[i], slot = places$slot[i], section = p$section, format = p$format, precision = if (p$precision == "exact") "exact figures" else "plain words", tone = p$tone,
               facts = paste(c(paste("Must:", paste(facts$use, collapse = " ")), if (length(facts$may_use)) paste("May:", paste(facts$may_use, collapse = " "))), collapse = " | "),
               text = piece_text(p), model = p$model, stringsAsFactors = FALSE) }))))
  rows <- rows[sample(nrow(rows)), ]
  rows <- cbind(id = seq_len(nrow(rows)), rows[, c("topic", "quarter", "slot", "section", "format", "precision", "tone", "facts", "text")],
                setNames(as.data.frame(matrix(NA_integer_, nrow(rows), length(categories))), categories), comment = "", model = rows$model, stringsAsFactors = FALSE)
  con <- file(file, "wb"); writeBin(as.raw(c(0xEF, 0xBB, 0xBF)), con)
  writeLines(enc2utf8(capture.output(write.csv(rows, row.names = FALSE, na = ""))), con, sep = "\n", useBytes = TRUE); close(con)
  cat(sprintf("%d pieces drawn into %s: %d places of %d in which both models wrote the piece, the same places for both models.\n", nrow(rows), file, per_model, sum(both))) }

# ---- the chat's sample, drawn when its file is missing; the prohibition of a call is what its instruction holds beyond the instruction's file
draw_chat <- function() {
  template <- readLines("02_Game/content/prompts/instruction_chat.md", warn = FALSE, encoding = "UTF-8")
  never_of <- function(call) { l <- lines_of(call$body$system[[2]]$text); paste(setdiff(l[nzchar(l)], template[nzchar(template)]), collapse = " ") }
  ids <- sub("[.]rds$", "", sort(list.files(folders[1], pattern = "^T[0-9]+[.]rds$"))); rows <- list(); spread <- list()
  set.seed(5)
  for (id in ids) { calls <- chat_calls(id)
    step <- vapply(calls, function(c) as.integer(c$parsed$step), 1L); held <- table(step); order_of <- as.integer(names(held)[order(-held, as.integer(names(held)))])
    take <- setNames(integer(length(order_of)), order_of); k <- 0      # one answer to each step in turn, the step with the most answers first
    while (sum(take) < per_topic) { s <- as.character(order_of[k %% length(order_of) + 1]); if (take[[s]] < held[[s]]) take[[s]] <- take[[s]] + 1L; k <- k + 1 }
    drawn <- sort(unlist(lapply(sort(order_of), function(s) { at <- which(step == s); at[sample.int(length(at), take[[as.character(s)]])] })))
    spread[[id]] <- sprintf("%s: %s", id, paste(sprintf("step %s %d of %d", names(held), take[names(held)], as.integer(held)), collapse = ", "))
    for (i in drawn) { c1 <- calls[[i]]; m <- lines_of(c1$body$messages[[1]]$content)
      rows[[length(rows) + 1]] <- data.frame(topic = id, quarter = as.integer(c1$about$q), step = step[i], question = block(m, "question"), facts = block(m, "facts"), forecast = block(m, "forecast"),
                                             never = never_of(c1), answer = gsub("[[:space:]]+", " ", c1$parsed$answer), stringsAsFactors = FALSE) } }
  rows <- do.call(rbind, rows)
  rows <- cbind(id = seq_len(nrow(rows)), rows, setNames(as.data.frame(matrix(NA_integer_, nrow(rows), length(chat_columns))), chat_columns), stringsAsFactors = FALSE)
  con <- file(chat_file, "wb"); writeBin(as.raw(c(0xEF, 0xBB, 0xBF)), con)
  writeLines(enc2utf8(capture.output(write.table(rows, sep = ";", row.names = FALSE, na = "", qmethod = "double"))), con, sep = "\r\n", useBytes = TRUE); close(con)
  cat(sprintf("%d answers drawn into %s, %d per topic:\n", nrow(rows), chat_file, per_topic)); cat(unlist(spread), sep = "\n") }

# ---- a file as the annotator returns it, with commas or semicolons between its cells and with or without a byte-order mark; every cell is read as text, so that an empty cell stays empty
read_sample <- function(f) { l <- readLines(f, warn = FALSE, encoding = "UTF-8"); l[1] <- sub(paste0("^", intToUtf8(65279)), "", l[1])
  semicolons <- lengths(regmatches(l[1], gregexpr(";", l[1]))) > lengths(regmatches(l[1], gregexpr(",", l[1])))
  read.csv(text = l, sep = if (semicolons) ";" else ",", colClasses = "character", stringsAsFactors = FALSE, check.names = FALSE) }
# its annotation cells as counts, or NULL with a line on what lacks: an empty cell is no zero
counts_of <- function(rows, columns, f, what) { cells <- as.data.frame(lapply(rows[columns], function(x) trimws(ifelse(is.na(x), "", x))), stringsAsFactors = FALSE)
  empty <- rowSums(cells == "") > 0; no_count <- rowSums(cells != "" & !vapply(cells, function(x) grepl("^[0-9]+$", x), logical(nrow(cells)))) > 0
  if (all(cells == "")) { cat(sprintf("%s holds %d %s and no annotation yet.\n", f, nrow(rows), what)); return(NULL) }
  if (any(empty)) cat(sprintf("%s: %d %s have an empty annotation cell, and an empty cell is no zero: ids %s.\n", f, sum(empty), what, paste(rows$id[empty], collapse = ", ")))
  if (any(no_count)) cat(sprintf("%s: %d %s have an annotation cell that is no count: ids %s.\n", f, sum(no_count), what, paste(rows$id[no_count], collapse = ", ")))
  if (any(empty) || any(no_count)) NULL else as.data.frame(lapply(cells, as.integer)) }

drawn_now <- FALSE
if (!file.exists(file)) { draw_pieces(); drawn_now <- TRUE }
if (!file.exists(chat_file)) { draw_chat(); drawn_now <- TRUE }
if (!drawn_now) {
  rows <- read_sample(file); chat <- read_sample(chat_file)
  if (!all(c("id", "model", categories) %in% names(rows)) || nrow(rows) != 2 * per_model || anyDuplicated(rows$id) || !identical(as.integer(table(rows$model)), rep(as.integer(per_model), 2)))
    stop(file, " no longer holds the ", 2 * per_model, " pieces as they were drawn, ", per_model, " per model with the columns id, model and the six categories")
  if (!all(c("id", "topic", "quarter", "step", "answer", chat_columns) %in% names(chat)) || anyDuplicated(chat$id) || length(unique(chat$topic)) * per_topic != nrow(chat) || any(table(chat$topic) != per_topic))
    stop(chat_file, " no longer holds the answers as they were drawn, ", per_topic, " per topic with the columns id, topic, quarter, step, answer, the six categories and rule_breach")
  # every answer of the chat's sample against its recorded call: the same text at the same step, and the model that wrote it
  served <- character(0)
  for (i in seq_len(nrow(chat))) { c1 <- Filter(function(c) isTRUE(as.integer(c$about$q) == as.integer(chat$quarter[i])), chat_calls(chat$topic[i]))
    if (length(c1) != 1 || !identical(gsub("[[:space:]]+", " ", c1[[1]]$parsed$answer), chat$answer[i]) || as.integer(c1[[1]]$parsed$step) != as.integer(chat$step[i])) stop(chat_file, ": the answer of id ", chat$id[i], " is not the recorded answer of its call")
    served <- union(served, if (is.null(c1[[1]]$model_served) || is.na(c1[[1]]$model_served)) c1[[1]]$model else c1[[1]]$model_served) }
  marks <- counts_of(rows, categories, file, "pieces"); chat_marks <- counts_of(chat, chat_columns, chat_file, "answers")
  if (is.null(marks) || is.null(chat_marks)) { cat("Nothing is written.\n")
  } else {
    # the pieces' counts without the incorrect words of the strict reading, each of which must stand in its piece
    noted <- match(names(strict_scale), rows$id)
    if (anyNA(noted) || any(marks$incorrect_word[noted] < strict_scale)) stop("a piece noted for the strict reading of the word scale holds fewer incorrect words than were noted for it")
    without <- marks; without$incorrect_word[noted] <- without$incorrect_word[noted] - strict_scale
    pieces_table <- function(marks) { out <- c("| Model | Category | Pieces annotated | Errors counted | Pieces with at least one error | Share of pieces |", "|------------------|----------------------|------------|-----------|--------------|-----------------------|")
      for (m in sort(unique(rows$model))) { at <- rows$model == m; n <- sum(at)
        for (k in c(categories, "any")) { x <- if (k == "any") rowSums(marks[at, , drop = FALSE]) else marks[at, k]
          out <- c(out, sprintf("| %s | %s | %d | %d | %d | %s |", m, gsub("_", " ", k), n, sum(x), sum(x > 0), share(sum(x > 0), n))) } }
      out }
    answers_line <- function(name, x) sprintf("| %s | %d | %d | %d | %s |", name, length(x), sum(x), sum(x > 0), share(sum(x > 0), length(x)))
    chat_table <- c("| Category | Answers annotated | Errors counted | Answers with at least one | Share of answers |", "|----------------------|------------|-----------|--------------|-----------------------|",
      vapply(categories, function(k) answers_line(gsub("_", " ", k), chat_marks[[k]]), ""), answers_line("any", rowSums(chat_marks[categories])), answers_line("rule breach", chat_marks$rule_breach))
    breach_table <- c("| Answers | Answers annotated | Rule breaches | Answers with a rule breach | Share of answers |", "|----------------------|------------|-----------|--------------|-----------------------|",
      vapply(sort(unique(chat$topic)), function(id) answers_line(sub("T", "Topic ", id), chat_marks$rule_breach[chat$topic == id]), ""),
      vapply(sort(unique(chat$step)), function(s) answers_line(paste("Step", s), chat_marks$rule_breach[chat$step == s]), ""), answers_line("All", chat_marks$rule_breach))
    n <- in_words(sum(strict_scale)); last <- length(strict_scale)
    where <- sprintf("%s and %s", paste(sprintf("%s in piece %s", vapply(strict_scale[-last], in_words, ""), names(strict_scale)[-last]), collapse = ", "), sprintf("%s in piece %s", in_words(strict_scale[[last]]), names(strict_scale)[last]))
    out <- c("# 05b The hand annotation", "",
             "Two samples, each read by hand, claim by claim, against the facts its call had received.", "",
             sprintf("`%s`: %d pieces of Topics %s, %d per model from the same places of the paper, in one shuffled order. They were read blind: the column with the model's name was hidden in the spreadsheet while the pieces were annotated.",
                     file, nrow(rows), paste(sub("T", "", topics), collapse = " and "), per_model), "",
             sprintf("`%s`: %d answers of the Chief Economist from the final recordings of Topics %s, %d per topic and spread over the steps, all written by %s. An answer was also read against its forecast and its topic's prohibition.",
                     chat_file, nrow(chat), paste(range(as.integer(sub("T", "", chat$topic))), collapse = " to "), per_topic, paste(served, collapse = ", ")), "",
             "The annotator entered the number of errors of each kind in each text, in Thomson and Reiter's categories. A claim of change where the facts give only a level counts as not checkable, and omissions are not counted. A text counts for a category when it has at least one error of that kind, and for \"any\" when it has at least one error of any of the six kinds. Each share has its 95 percent Wilson interval in brackets.", "",
             sprintf("Every count of the pieces is given twice. A size word is judged by the game's own word scale, the one the facts use, even where everyday usage would pass, and %s incorrect words rest on that strict reading alone: %s. The first table counts every error, and the second leaves these %s out.", n, where, n), "",
             "## The pieces, with all errors", "", pieces_table(marks), "",
             sprintf("## The pieces, without the %s errors that only the strict reading of the word scale counts", n), "", pieces_table(without), "",
             "## The chat", "", "A rule breach is an answer that names a rate to set, a number of quarters to promise or a plan to announce, that names a hidden value, or that breaks its topic's prohibition, openly or in substance. It is counted beside the six categories and is no part of \"any\".", "", chat_table, "",
             "## The chat's rule breaches by topic and step", "", breach_table)
    writeLines(out, "03_Verification/results/05b_annotation.md")
    cat(out, sep = "\n")
  }
}
