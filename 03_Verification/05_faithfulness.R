# 05 Faithfulness (Section 3.3, rule 5; Section 3.2's check that every figure
# the layer writes stands on what its call received, and the layer of Section
# 4.2.2). The confusion-matrix test of the layer's numbers, over the eight final
# recordings of 03_Verification/record_topics.R, one run per topic with the
# model. 05_counts.R sets every number of every answer against the request
# of its own call: a number that stands in the call's material, equal to a
# number there at the two decimals the desk shows, is a TP, every other
# number an FP, a figure under <use> that an exact-figures piece or lead
# does not write an FN, a hidden value not written a TN and one written a
# leak, and a number the text calls quarters is counted apart.
# This script writes the tables: per pipeline and model the counts with
# precision = TP / (TP + FP), recall = TP / (TP + FN), F1 = 2 TP / (2 TP +
# FP + FN) and the leak rate = leaks / hidden values, each with its 95
# percent Wilson interval, F1's on TP out of TP + (FP + FN) / 2; the false
# positives by where the number stands; every figure found nowhere in the
# request and every figure under <use> not written, each as a line; and the
# speed per call type and per issue with the retries per piece. Calls that
# died on the connection are kept apart from the model's failures: they
# count neither as retries nor as answers, and the speed is that of the
# calls that were answered. Beside the numbers the script counts the
# residual wording: the texts the player reads in which a sentence names
# what its call received as its source (the material, the facts, a tag, the
# sheet), or says that its source does not give something, although the
# fixed parts forbid both. Its patterns were set by reading every sentence
# that a wider search for such wording returned, and every counted sentence
# is listed. An answer that says at which step of the ladder it answers
# refers to the conversation and is not counted. The test reads the
# recordings only. Run from the main folder:
# Rscript 03_Verification/05_faithfulness.R
source("03_Verification/05_counts.R")

# ---- the tables
pipelines <- function(d) list("Newspaper, inside pieces, exact figures" = d$kind == "piece" & d$precision %in% "exact figures", "Newspaper, inside pieces, plain words" = d$kind == "piece" & d$precision %in% "plain words",
  "Newspaper, the lead, exact figures" = d$kind == "lead" & d$precision %in% "exact figures", "Newspaper, the lead, plain words" = d$kind == "lead" & d$precision %in% "plain words",
  "Newspaper, all" = d$kind %in% c("piece", "lead"), "Chat" = d$kind == "chat", "Debrief" = d$kind == "debrief")
metrics_table <- function(d) { d <- d[d$ok, , drop = FALSE]; S <- pipelines(d)
  out <- c("| Pipeline | Model | Answers | Numbers written | Counts of quarters | TP | FP | FN | TN | Leaks | Precision | Recall | F1 | Leak rate |", rule(c(14, 10, 7, 7, 8, 5, 3, 3, 5, 5, 9, 9, 9, 9)))
  for (p in names(S)) for (m in sort(unique(d$model[S[[p]]]))) { x <- d[S[[p]] & d$model == m, , drop = FALSE]; s <- sums(x)
    out <- c(out, sprintf("| %s | %s | %d | %d | %d | %d | %d | %d | %d | %d | %s | %s | %s | %s |", p, m, nrow(x), sum(x$written), sum(x$exempt), s$TP, s$FP, s$FN, s$hidden - s$leak, s$leak,
                          show(wilson(s$TP, s$TP + s$FP)), if (s$must) show(wilson(s$TP, s$TP + s$FN)) else "n/a", if (s$must) show(wilson(s$TP, s$TP + (s$FP + s$FN) / 2)) else "n/a", show(wilson(s$leak, s$hidden)))) }
  out }
fp_table <- function(d) { d <- d[d$ok, , drop = FALSE]; S <- pipelines(d)
  out <- c("| Pipeline | Model | FP | In the instruction or the fixed part | Found nowhere in the request | of them rounded from a figure of the material | equal to a hidden value | neither | Answers with a figure found nowhere |", rule(c(17, 11, 5, 12, 11, 13, 10, 8, 13)))
  for (p in names(S)) for (m in sort(unique(d$model[S[[p]]]))) { x <- d[S[[p]] & d$model == m, , drop = FALSE]
    out <- c(out, sprintf("| %s | %s | %d | %d | %d | %d | %d | %d | %d of %d |", p, m, sum(x$FP), sum(x$in_system), sum(x$rounded + x$leak + x$neither), sum(x$rounded), sum(x$leak), sum(x$neither), sum(x$rounded + x$leak + x$neither > 0), nrow(x))) }
  out }
speed_table <- function(d, i, p) { out <- c("| Call type | Model | Calls | Died on the connection | Answered, the answer not readable | Median seconds | 90th percentile | Median input tokens | Median output tokens | Calls with reasoning |", rule(c(9, 14, 7, 11, 13, 9, 9, 9, 9, 10)))
  for (k in c("piece", "lead", "chat", "debrief")) for (m in sort(unique(d$model[d$kind == k]))) { x <- d[d$kind == k & d$model == m, ]; s <- x$seconds[x$reached]
    out <- c(out, sprintf("| %s | %s | %d | %d | %d | %.1f | %.1f | %.0f | %.0f | %d |", k, m, nrow(x), sum(!x$reached), sum(x$reached & !x$ok), median(s), quantile(s, 0.9), median(x$input_tokens, na.rm = TRUE), median(x$output_tokens, na.rm = TRUE), sum(x$thinking_tokens > 0, na.rm = TRUE))) }
  n <- d$kind %in% c("piece", "lead"); i <- i[i$calls > 0, ]; r <- d[n & d$reached, ]; written <- nrow(unique(r[, c("topic", "q", "slot")])); further <- nrow(r) - written
  again <- c("| Format | Pieces | Asked again for the number of paragraphs | for the headline's length | for the body's length | for the structure | Asked again, share of pieces |", rule(c(14, 8, 18, 16, 16, 13, 15)))
  for (fm in sort(unique(d$format[n]))) { x <- d[n & d$format == fm, ]; k <- nrow(unique(x[, c("topic", "q", "slot")])); a <- function(what) sum(x$asked %in% what)
    again <- c(again, sprintf("| %s | %d | %d | %d | %d | %d | %.2f |", format_words[[fm]], k, a("paragraphs"), a("headline"), a("body"), a("structure"), sum(!is.na(x$asked)) / k)) }
  c(out, "", sprintf("Issues: %d. Seconds per issue, the inside pieces sent at once, then those asked for again, then the lead: median %.1f, 90th percentile %.1f; calls per issue: median %g.", nrow(i), median(i$seconds), quantile(i$seconds, 0.9), median(i$calls)),
    sprintf("Retries per piece: %.3f: %d further calls for %d pieces, the leads included, %d of them asked again with the sentence of a failed check and %d after an answer that could not be read. Calls that died on the connection: %d; they count neither as retries nor as the model's failures. Pieces as the player reads them: %d by the model at the first answer, %d after a retry, %d of these with a text shortened, %d kept with a failed check (%s), %d from the template.",
            further / written, further, written, sum(!is.na(r$asked)), further - sum(!is.na(r$asked)), sum(n & !d$reached), sum(p$source == "model" & !p$retried), sum(p$source == "model" & p$retried), sum(p$shortened), sum(!is.na(p$kept)),
            if (any(!is.na(p$kept))) paste(sprintf("%s %d", names(table(p$kept)), as.integer(table(p$kept))), collapse = ", ") else "none", sum(p$source == "template")), "", again) }
listing <- function(l, what) { x <- grep(what, l, value = TRUE, fixed = TRUE); if (length(x)) paste("-", x) else "None." }

# ---- the residual wording of the texts the player reads: the sentences that name what their call received as their source, and those that say that their source does not give something
names_input <- "\\b(our|my|the|this) material\\b|according to the (latest |given )?facts\\b|\\bfacts are reported\\b|\\bthe (tags?|sheet)\\b|<[a-z_]+>"
not_given   <- "\\b(material|poll|facts|sheet|it) (does|do) not (give|say|show|hold|include)\\b|\\b(material|poll|facts|sheet) (gives?|holds?|shows?) no\\b"
sentences   <- function(text) trimws(strsplit(gsub("([.!?][\"')]*) (?=[A-Z\"(\\[])", "\\1\n", gsub("[[:space:]]+", " ", text), perl = TRUE), "\n", fixed = TRUE)[[1]])
residual_wording <- function(folder, d) { d <- d[d$ok & d$last, , drop = FALSE]; found <- list()
  for (topic in sort(unique(d$topic))) { run <- readRDS(file.path(folder, paste0(topic, ".rds")))
    for (k in which(d$topic == topic)) { s <- sentences(answer_of(run$calls[[d$call[k]]])); a <- grepl(names_input, tolower(s), perl = TRUE); b <- grepl(not_given, tolower(s), perl = TRUE)
      if (any(a | b)) found[[length(found) + 1]] <- data.frame(text = if (d$kind[k] %in% c("piece", "lead")) "Newspaper" else if (d$kind[k] == "chat") "Chat" else "Debrief", names = any(a), not_given = any(b),
        line = sprintf("%s, quarter %d, %s | %s | %s", topic_words(topic), d$q[k], if (d$kind[k] == "lead") place_words[["L"]] else if (d$kind[k] == "piece") sprintf("%s, %s", place_words[[d$slot[k]]], tolower(format_words[[d$format[k]]])) else d$kind[k],
                       paste(c(if (any(a)) "names its input", if (any(b)) "says that something is not given"), collapse = ", "), paste(s[a | b], collapse = " ")), stringsAsFactors = FALSE) } }
  found <- if (length(found)) do.call(rbind, found) else data.frame(text = character(0), names = logical(0), not_given = logical(0), line = character(0))
  groups <- c(Newspaper = sum(d$kind %in% c("piece", "lead")), Chat = sum(d$kind == "chat"), Debrief = sum(d$kind == "debrief"))
  c("| Texts the player reads | Texts | Name their own input | Say that something is not given | Either |", rule(c(20, 8, 12, 14, 8)),
    vapply(names(groups), function(g) { x <- found[found$text == g, ]; sprintf("| %s | %d | %d | %d | %d |", g, groups[[g]], sum(x$names), sum(x$not_given), nrow(x)) }, ""), "",
    if (nrow(found)) paste("-", found$line) else "None.") }

# ---- the report on the final recordings
folders <- recording_folders()["final"]; counted <- count_recordings(folders); calls <- counted$calls
out <- c("# 05 Faithfulness", "",
  sprintf("Recordings: `%s`, %s, each topic's final attempt; %d calls, %d of them died on the connection, and %d were answered without an answer that could be read.", folders[["final"]], topics_words(unique(calls$topic)), nrow(calls), sum(!calls$reached), sum(calls$reached & !calls$ok)), "",
  "Every number in an answer is set against the request of its own call. TP: it stands in the call's material, equal to a number there at two decimals, the decimals the desk shows. FP: it does not; it then stands in the instruction or the fixed part, or nowhere in the request. FN: a figure under `<use>` that an exact-figures piece or lead does not write. TN and leaks: the hidden values of the quarter that the request does not hold, not written and written. A number the text calls quarters is counted apart. Each rate has its 95 percent Wilson interval in brackets.", "",
  "## The answers the player reads", "", "The last answer of every piece and lead, and every chat answer and debrief.", "", metrics_table(calls[calls$last, ]), "",
  "## Every answer, those replaced after a retry included", "", metrics_table(calls), "",
  "## The false positives by where the number stands, every answer", "", fp_table(calls), "",
  "## The figures found nowhere in the request", "", listing(counted$lines, "| found nowhere:"), "",
  "## Figures under `<use>` that an answer did not write", "", listing(counted$lines, "| not written:"), "",
  "## Residual wording", "", "The texts the player reads in which a sentence names what its call received as its source (the material, the facts, a tag, the sheet), or says that its source does not give something. The fixed parts forbid both. This is wording, no error of a number, and the categories of the hand annotation in test 05b do not cover it. Each text is listed with its topic, its quarter and the sentences.", "",
  residual_wording(folders[["final"]], calls), "",
  "## Speed and retries", "", "The seconds of a call are those its record holds, over the calls that were answered; the inside pieces of an issue are sent at once, and each of their records holds the time of the whole batch.", "",
  speed_table(calls, counted$issues, counted$pieces))
writeLines(out, "03_Verification/results/05_faithfulness.md")
cat(out, sep = "\n")
