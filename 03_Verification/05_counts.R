# 05 The count behind tests 05 and 05c (Section 3.3, rule 5; Section 3.2's
# check that every figure the layer writes stands on what its call received,
# and the layer of Section 4.2.2). Over recordings of 03_Verification/record_topics.R,
# every number in the layer's texts, the pieces, the leads, the chat's
# answers and the debriefs, is set against the request of its own call as the
# model received it, and counted as in a confusion matrix:
#   exempt  a number the text calls quarters ("3 quarters", "quarter 8"),
#           counted apart
#   TP      a number that stands in the call's material, the user's message,
#           as the material gives it: the two are equal at two decimals, the
#           decimals the desk shows ("2.1 million" equals 2,100,000); the
#           same in a plain-words piece, whose material holds no figure but
#           the law's constants and counts of quarters, so that every other
#           figure it writes is an FP
#   FP      every other number: one that stands in the instruction or the
#           fixed part (a word limit, a count), or one found nowhere in the
#           request, which is rounded from a figure of the material (it
#           differs from it by less than 0.055, as a figure written at one
#           decimal does), equal to a hidden value, or neither
#   FN      a figure under <use> that an exact-figures piece or lead does
#           not write
#   hidden  the quarter's values no call receives: the rate the economy
#           needs, the believed rule's rate, the rate's deviation from it
#           and, during the term, the reference bank's rate, without those
#           the request itself holds as a figure; one written is a leak, one
#           not written a TN
# A call that died on the connection, one the service never answered, is no
# failure of the model: the recorder records a topic again when one of its
# calls died, so that only a topic's final attempt is in a folder, and the
# count keeps such calls apart, neither as retries nor as answers. This file
# only defines the count: 05_faithfulness.R and 05c_model_comparison.R load
# it and write their tables from it. It reads the recordings only. The
# recordings name a topic, a place in the newspaper and a format by the names
# the README lists (T5, S4, F-CHART), and the tables print them in words.

# ---- a recorded call: its answer's text, its material without the sentence a retry adds after it, its system blocks
answer_of <- function(c) { p <- c$parsed
  if (c$task == "chat") p$answer else if (c$task == "debrief") paste(c(p$text_on_the_term, vapply(p$marks, function(m) m$text, "")), collapse = " ") else paste(unlist(p), collapse = " ") }
material_of <- function(c) { l <- strsplit(c$body$messages[[1]]$content, "\n", fixed = TRUE)[[1]]; l[seq_len(max(grep("^</[a-z_]+>$", l)))] }
block     <- function(l, tag) { a <- which(l == paste0("<", tag, ">")); b <- which(l == paste0("</", tag, ">")); if (!length(a)) character(0) else l[(a + 1):(b - 1)] }
system_of <- function(c) paste(vapply(c$body$system, function(b) b$text, ""), collapse = "\n")
model_of  <- function(c) if (is.null(c$model_served) || is.na(c$model_served)) c$model else c$model_served
# the check a piece was asked again for, read from the sentence a retry adds after the material
asked_of  <- function(c) { s <- tail(strsplit(c$body$messages[[1]]$content, "\n", fixed = TRUE)[[1]], 1)
  if (grepl("headline had", s, fixed = TRUE)) "headline" else if (grepl("body had", s, fixed = TRUE)) "body" else if (grepl("in its body", s, fixed = TRUE)) "paragraphs" else "structure" }
# the hidden values of a call: the quarter before and the open quarter during the term; every quarter, the bank's rates excepted, for the debrief
hidden_of <- function(run, q, kind) { Q <- run$quarters; B <- run$bank$quarters; at <- if (kind == "debrief") seq_len(nrow(Q)) else intersect(c(q - 1, q), seq_len(nrow(Q)))
  list("the rate the economy needs" = Q$r_n[at], "the believed rule's rate" = Q$i_rule[at], "the rate's deviation from the rule" = Q$v[at],
       "the reference bank's rate" = if (kind == "debrief" || is.null(B)) numeric(0) else B$rate[intersect(at, seq_len(nrow(B)))]) }

# ---- the numbers of a text, each with whether the text calls it quarters and its context
numbers_of <- function(text) {
  empty <- data.frame(value = numeric(0), raw = character(0), quarters = logical(0), ctx = character(0), stringsAsFactors = FALSE)
  if (is.null(text) || length(text) != 1 || is.na(text) || !nzchar(text)) return(empty)
  m <- gregexpr("[0-9][0-9,]*[.]?[0-9]*", text)[[1]]; if (m[1] == -1) return(empty)
  from <- as.integer(m); to <- from + attr(m, "match.length") - 1; raw <- substring(text, from, to)
  before <- substring(text, pmax(1, from - 9), from - 1); after <- substring(text, to + 1, to + 12); before2 <- substring(text, pmax(1, from - 30), from - 1)
  value <- suppressWarnings(as.numeric(gsub(",", "", sub("[.,]+$", "", raw))))
  value <- ifelse(grepl("^[ -]?million", after, ignore.case = TRUE), value * 1e6, value)
  quarters <- grepl("quarters? $", before, ignore.case = TRUE) | grepl("^[ -]?quarters?", after, ignore.case = TRUE) | grepl("quarters? ([0-9]+(,| and| or| to| through)? )+$", before2, ignore.case = TRUE)
  glued <- grepl("[A-Za-z_]$", before) | grepl("^(st|nd|rd|th)([^a-z]|$)", after)
  d <- data.frame(value = value, raw = sub("[.,]+$", "", raw), quarters = quarters, ctx = gsub("[[:space:]]+", " ", substring(text, pmax(1, from - 70), pmin(nchar(text), to + 50))), stringsAsFactors = FALSE)
  d[!is.na(d$value) & !glued, , drop = FALSE]
}
# a number against the numbers of a set: equal to one of them at two decimals, the decimals the desk shows; and rounded from one of them, a difference under 0.055 as a figure written at one decimal has
near    <- function(x, set) length(set) > 0 && any(round(set * 100) == round(x * 100))
rounded <- function(x, set) length(set) > 0 && any(abs(set - x) < 0.055)
wilson <-function(x, n) { if (is.na(n) || n <= 0) return(c(NA, NA, NA)); z <- qnorm(0.975); p <- x / n; den <- 1 + z^2 / n
  ctr <- (p + z^2 / (2 * n)) / den; half <- z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / den; c(p, max(0, ctr - half), min(1, ctr + half)) }
show   <- function(w) if (is.na(w[1])) "n/a" else sprintf("%.3f (%.3f to %.3f)", w[1], w[2], w[3])
# the line under a table's header; where the table is typeset, its numbers of dashes are the columns' relative widths
rule   <- function(widths) paste0("|", paste(strrep("-", widths), collapse = "|"), "|")
# the words the tables print for the names of the recordings: one topic, several topics, a place in the newspaper, a format
topic_words  <- function(id) sub("^T", "Topic ", id)
topics_words <- function(ids) { n <- sort(as.integer(sub("^T", "", ids)))
  if (length(n) > 2 && all(diff(n) == 1)) sprintf("Topics %d to %d", n[1], n[length(n)]) else if (length(n) > 1) paste("Topics", paste(c(paste(head(n, -1), collapse = ", "), tail(n, 1)), collapse = " and ")) else paste("Topic", n) }
place_words  <- c(L = "the lead on the front page", S1 = "The Economy", S2 = "Prices and Wages", S3 = "Jobs", S4 = "Markets and the Bank", S5 = "Politics or Analysis")
format_words <- c("F-BRIEF" = "Brief", "F-CHART" = "Chart", "F-COMMENT" = "Comment", "F-INTERVIEW" = "Interview", "F-LEAD" = "Lead", "F-MARKETS" = "Markets table", "F-REPORT" = "Report", "F-VOICES" = "Voices")

# ---- one call: its row of counts, and the figures found nowhere and the must figures not written, each as a line
classify <- function(c, run, label, topic, idx) {
  kind <- c$task; q <- if (kind == "debrief") run$T else c$about$q; paper <- kind %in% c("piece", "lead")
  counts <- c(written = 0, exempt = 0, TP = 0, FP = 0, in_system = 0, rounded = 0, leak = 0, neither = 0, must = 0, must_found = 0, hidden = 0)
  u <- c$usage; tok <- function(x) if (is.null(x)) NA_real_ else as.numeric(x)
  row <- data.frame(label = label, topic = topic, call = idx, q = q, kind = kind, slot = if (paper) c$about$slot else NA, type = if (paper) c$about$type else NA, format = if (paper) c$about$format else NA,
                    precision = if (paper) c(exact = "exact figures", words = "plain words")[[c$about$precision]] else NA, retry = paper && isTRUE(c$about$retry),
                    asked = if (paper && isTRUE(c$about$retry)) asked_of(c) else NA, model = model_of(c),
                    seconds = c$seconds, ok = isTRUE(c$ok), reached = isTRUE(as.integer(c$status) == 200L), input_tokens = tok(u$input_tokens), output_tokens = tok(u$output_tokens), thinking_tokens = tok(u$output_tokens_details$thinking_tokens), stringsAsFactors = FALSE)
  if (!isTRUE(c$ok)) return(list(row = cbind(row, as.list(counts)), lines = character(0)))
  m <- material_of(c); given <- numbers_of(paste(m, collapse = "\n")); G <- given$value[!given$quarters]; Gq <- given$value[given$quarters]; S <- numbers_of(system_of(c))$value
  H <- hidden_of(run, q, kind); hv <- round(unlist(H, use.names = FALSE), 2); hk <- rep(names(H), lengths(H))
  keep <- is.finite(hv) & abs(hv) >= 0.005 & !duplicated(hv); hv <- hv[keep]; hk <- hk[keep]
  open <- !vapply(hv, near, logical(1), set = c(given$value, S)); hv <- hv[open]; hk <- hk[open]
  w <- numbers_of(answer_of(c))
  cls <- vapply(seq_len(nrow(w)), function(i) { x <- w$value[i]
    if (w$quarters[i]) "exempt" else if (near(x, G)) "TP" else if (near(x, S)) "in_system" else if (near(x, hv)) "leak" else if (rounded(x, G)) "rounded" else "neither" }, "")
  where <- sprintf("%s, quarter %d, %s | %s", topic_words(topic), q, if (paper) sprintf("%s, %s", place_words[[c$about$slot]], row$precision) else kind, row$model)
  lines <- vapply(which(cls %in% c("leak", "rounded", "neither")), function(i)
    sprintf("%s | found nowhere: %s | %s | ...%s...", where, if (cls[i] == "leak") paste("equal to", hk[which.min(abs(hv - w$value[i]))]) else if (cls[i] == "rounded") "rounded from a figure of the material" else "neither", w$raw[i], w$ctx[i]), "")
  counts[["written"]] <- nrow(w); counts[["exempt"]] <- sum(cls == "exempt"); counts[["TP"]] <- sum(cls == "TP"); counts[["FP"]] <- sum(cls %in% c("in_system", "leak", "rounded", "neither"))
  for (k in c("in_system", "rounded", "leak", "neither")) counts[[k]] <- sum(cls == k)
  counts[["hidden"]] <- length(hv)
  if (paper && c$about$precision == "exact") { use <- numbers_of(paste(block(m, "use"), collapse = "\n"))
    for (asq in c(FALSE, TRUE)) for (fig in unique(round(use$value[use$quarters == asq], 4))) { found <- near(fig, w$value[w$quarters == asq])
      counts[["must"]] <- counts[["must"]] + 1; counts[["must_found"]] <- counts[["must_found"]] + found
      if (!found) lines <- c(lines, sprintf("%s | not written: %s%s | %s", where, format(fig, big.mark = ","), if (asq) " quarters" else "", substr(gsub("[[:space:]]+", " ", answer_of(c)), 1, 140))) } }
  list(row = cbind(row, as.list(counts)), lines = setNames(lines, rep(paste(label, kind), length(lines))))   # each line under the name of its folder and its kind of call, which no table prints
}

# ---- the folders of recordings: the eight final recordings and the comparison's, or those the arguments final=<folder> and comparison=<folder> name; a folder without recordings is left out
recording_folders <- function() { folders <- c(final = "03_Verification/recordings", comparison = "03_Verification/recordings_comparison")
  for (a in grep("^(final|comparison)=", commandArgs(trailingOnly = TRUE), value = TRUE)) folders[[sub("=.*$", "", a)]] <- sub("^[a-z]+=", "", a)
  folders <- folders[vapply(folders, function(d) length(list.files(d, pattern = "^T[0-9]+[.]rds$")) > 0, logical(1))]
  if (!("final" %in% names(folders))) stop("no recordings of the eight topics: run 03_Verification/record_topics.R with the key first")
  folders }

# ---- the count over folders of recordings, of every topic or of those named: every call with its counts, every issue with its seconds and its calls, every piece as the player reads it, and the lines
count_recordings <- function(folders, topics = NULL) {
  rows <- list(); lines <- character(0); issues <- list(); pieces <- list()
  for (label in names(folders)) for (f in sort(list.files(folders[[label]], pattern = "^T[0-9]+[.]rds$", full.names = TRUE))) {
    topic <- sub("[.]rds$", "", basename(f)); if (!is.null(topics) && !(topic %in% topics)) next
    run <- readRDS(f)
    for (i in seq_along(run$calls)) { r <- classify(run$calls[[i]], run, label, topic, i); rows[[length(rows) + 1]] <- r$row; lines <- c(lines, r$lines) }
    for (q in seq_along(run$issues)) { if (is.null(run$issues[[q]])) next
      cs <- Filter(function(c) c$task %in% c("piece", "lead") && isTRUE(c$about$q == q), run$calls)
      inside <- vapply(Filter(function(c) c$task == "piece", cs), function(c) c$seconds, 1); lead <- vapply(Filter(function(c) c$task == "lead", cs), function(c) c$seconds, 1)
      issues[[length(issues) + 1]] <- data.frame(label = label, topic = topic, q = q, seconds = sum(unique(inside)) + sum(lead), calls = length(cs), stringsAsFactors = FALSE)
      for (p in run$issues[[q]]$pieces) pieces[[length(pieces) + 1]] <- data.frame(label = label, topic = topic, q = q, slot = p$slot, format = p$format, source = p$source,
        model = if (is.null(p$model) || is.na(p$model)) NA_character_ else p$model, retried = isTRUE(p$retried), shortened = isTRUE(p$shortened), kept = if (is.null(p$kept)) NA_character_ else p$kept, stringsAsFactors = FALSE) }
  }
  calls <- do.call(rbind, rows)
  calls$last <- !duplicated(paste(calls$label, calls$topic, calls$q, calls$slot), fromLast = TRUE) | !(calls$kind %in% c("piece", "lead"))
  list(calls = calls, issues = do.call(rbind, issues), pieces = do.call(rbind, pieces), lines = lines)
}
# the totals of a set of calls
sums <- function(x) list(TP = sum(x$TP), FP = sum(x$FP), FN = sum(x$must - x$must_found), must = sum(x$must), hidden = sum(x$hidden), leak = sum(x$leak), nowhere = sum(x$rounded + x$leak + x$neither))
