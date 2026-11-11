# 05c The model comparison (Section 3.3, rule 5; Section 4.2.2, the model
# that writes the pieces). The pieces and the leads of Topics 3 and 8 as the
# game's model wrote them in the final recordings and as the comparison's
# model wrote them, with its reasoning off, in
# 03_Verification/recordings_comparison/: the same layer, the same plans and
# the same facts for both. The rule was fixed before the comparison ran: the
# comparison's model takes the pieces only if all six conditions hold,
# faithfulness first and speed last:
#   1 no piece falls to a template
#   2 its precision interval is not below the other model's
#   3 its recall interval is not below the other model's
#   4 it writes no more figures found nowhere in the request
#   5 it leaks nothing
#   6 the issue is faster, by its median seconds
# An interval is below another when its upper end lies under the other's
# lower end. The numbers are counted by 05_counts.R as in test 05, over every
# answer, those replaced after a retry included. Beside the conditions the
# script gives the retries per piece and the pieces kept with a failed
# check, the speed per call type and per issue and, once
# 03_Verification/results/05b_annotation.md exists, the hand annotation's
# result per model from the rows "any" of that file's two tables of the
# pieces, with all errors and without those of the strict reading of the
# word scale; the annotation is no condition of the rule. Calls that died on the connection
# are kept apart as in test 05. The script reads the recordings and that
# file only. Run from the main folder:
# Rscript 03_Verification/05c_model_comparison.R
source("03_Verification/05_counts.R")
folders <- recording_folders()
if (!("comparison" %in% names(folders))) stop("no recordings of the comparison: run 03_Verification/record_topics.R comparison with the key first")
topics_in <- function(d) sub("[.]rds$", "", list.files(d, pattern = "^T[0-9]+[.]rds$"))
common <- intersect(topics_in(folders[["final"]]), topics_in(folders[["comparison"]]))
counted <- count_recordings(folders, common)

# ---- one model's side: its calls for pieces and leads, its issues, its pieces as the player reads them, and its totals
side <- function(label) { d <- counted$calls[counted$calls$label == label & counted$calls$kind %in% c("piece", "lead"), ]
  i <- counted$issues[counted$issues$label == label, ]; r <- d[d$reached, ]; written <- nrow(unique(r[, c("topic", "q", "slot")]))
  list(model = paste(sort(unique(d$model)), collapse = ", "), calls = d, issues = i[i$calls > 0, ], pieces = counted$pieces[counted$pieces$label == label, ], sums = sums(d[d$ok, ]),
       written = written, further = nrow(r) - written, lines = grep(" (piece|lead) ", counted$lines[startsWith(counted$lines, paste0(label, " |"))], value = TRUE)) }
a <- side("final"); b <- side("comparison"); both <- list(a, b)
precision <- function(s) wilson(s$sums$TP, s$sums$TP + s$sums$FP); recall <- function(s) wilson(s$sums$TP, s$sums$TP + s$sums$FN)
templates <- function(s) sum(s$pieces$source == "template"); kept <- function(s) s$pieces$kept[!is.na(s$pieces$kept)]

# ---- the six conditions of the rule, in its order
holds <- c(templates(b) == 0, precision(b)[3] >= precision(a)[2], recall(b)[3] >= recall(a)[2], b$sums$nowhere <= a$sums$nowhere, b$sums$leak == 0, median(b$issues$seconds) < median(a$issues$seconds))
yes <- function(x) if (x) "yes" else "no"
conditions <- c(sprintf("| | Condition | %s | %s | Holds |", a$model, b$model), rule(c(3, 37, 24, 24, 12)),
  sprintf("| 1 | No piece falls to a template | %d of %d pieces | %d of %d | %s |", templates(a), nrow(a$pieces), templates(b), nrow(b$pieces), yes(holds[1])),
  sprintf("| 2 | Its precision interval is not below the other's | %s | %s | %s |", show(precision(a)), show(precision(b)), yes(holds[2])),
  sprintf("| 3 | Its recall interval is not below the other's | %s | %s | %s |", show(recall(a)), show(recall(b)), yes(holds[3])),
  sprintf("| 4 | It writes no more figures found nowhere in the request | %d | %d | %s |", a$sums$nowhere, b$sums$nowhere, yes(holds[4])),
  sprintf("| 5 | It leaks nothing | %d of %d hidden values | %d of %d | %s |", a$sums$leak, a$sums$hidden, b$sums$leak, b$sums$hidden, yes(holds[5])),
  sprintf("| 6 | The issue is faster, median seconds | %.1f | %.1f | %s |", median(a$issues$seconds), median(b$issues$seconds), yes(holds[6])))
failed <- which(!holds)
decision <- if (!length(failed)) sprintf("All six conditions hold: %s takes the pieces.", b$model) else
  sprintf("%s not hold: %s keeps the pieces, and the recordings of %s remain as the comparison.", if (length(failed) == 1) sprintf("Condition %d does", failed) else
    sprintf("Conditions %s do", paste(c(paste(head(failed, -1), collapse = ", "), tail(failed, 1)), collapse = " and ")), a$model, b$model)

# ---- the counts behind conditions 2 to 5, and where the two models' figures differ
counts <- c("| Model | Answers | Numbers written | Counts of quarters | TP | FP | of them found nowhere in the request | FN | Hidden values | Leaks |", rule(c(16, 8, 9, 9, 7, 6, 16, 6, 9, 7)),
  vapply(both, function(s) { d <- s$calls[s$calls$ok, ]
    sprintf("| %s | %d | %d | %d | %d | %d | %d | %d | %d | %d |", s$model, nrow(d), sum(d$written), sum(d$exempt), s$sums$TP, s$sums$FP, s$sums$nowhere, s$sums$FN, s$sums$hidden, s$sums$leak) }, ""))
formats <- sort(unique(unlist(lapply(both, function(s) s$calls$format[s$calls$ok & s$calls$must > 0]))))
missed <- function(s, fm) { d <- s$calls[s$calls$ok & s$calls$format == fm, ]; sprintf("%d of %d", sum(d$must - d$must_found), sum(d$must)) }
not_written <- c(sprintf("| Format | %s | %s |", a$model, b$model), "|---|---|---|", vapply(formats, function(fm) sprintf("| %s | %s | %s |", fm, missed(a, fm), missed(b, fm)), ""))
nowhere <- unlist(lapply(both, function(s) grep("| found nowhere:", s$lines, value = TRUE, fixed = TRUE)))

# ---- the retries and the failed checks, the dropped calls apart
measure <- function(name, f) sprintf("| %s | %s | %s |", name, f(a), f(b))
retries <- c(sprintf("| | %s | %s |", a$model, b$model), rule(c(50, 25, 25)),
  measure("Pieces and leads as the player reads them", function(s) sprintf("%d", nrow(s$pieces))),
  measure("Calls", function(s) sprintf("%d", nrow(s$calls))),
  measure("of them died on the connection, neither retries nor failures of the model", function(s) sprintf("%d", sum(!s$calls$reached))),
  measure("of them answered without an answer that could be read", function(s) sprintf("%d", sum(s$calls$reached & !s$calls$ok))),
  measure("Further calls after a failed check", function(s) sprintf("%d", sum(!is.na(s$calls$asked[s$calls$reached])))),
  measure("Retries per piece", function(s) sprintf("%.3f", s$further / s$written)),
  measure("Pieces kept with a failed check", function(s) if (!length(kept(s))) "0" else sprintf("%d (%s)", length(kept(s)), paste(sprintf("%s %d", names(table(kept(s))), as.integer(table(kept(s)))), collapse = ", "))),
  measure("Pieces from the template", function(s) sprintf("%d", templates(s))))

# ---- the speed of the calls that were answered, per call type and per issue
speed_row <- function(name, s, x) sprintf("| %s | %s | %d | %.1f | %.1f |", name, s$model, length(x), median(x), quantile(x, 0.9))
speed <- c("| | Model | Number | Median seconds | 90th percentile |", "|---|---|---|---|---|",
  unlist(lapply(both, function(s) speed_row("An inside piece's call", s, s$calls$seconds[s$calls$kind == "piece" & s$calls$reached]))),
  unlist(lapply(both, function(s) speed_row("The lead's call", s, s$calls$seconds[s$calls$kind == "lead" & s$calls$reached]))),
  unlist(lapply(both, function(s) speed_row("An issue", s, s$issues$seconds))))

# ---- the hand annotation's result per model, from the rows "any" of 05b's two tables of the pieces once they exist, each under the heading of its table: with all errors, and without those of the strict reading of the word scale
table_05b <- "03_Verification/results/05b_annotation.md"; any_rows <- list()
if (file.exists(table_05b)) { heading <- ""
  for (line in readLines(table_05b, warn = FALSE, encoding = "UTF-8")) { if (startsWith(line, "## ")) heading <- sub("^## ", "", line)
    r <- strsplit(sub(" *[|] *$", "", sub("^[|] *", "", line)), " *[|] *")[[1]]
    if (startsWith(line, "| ") && startsWith(heading, "The pieces, ") && length(r) == 6 && r[2] == "any") any_rows[[length(any_rows) + 1]] <- c(sub("^w", "W", sub("^The pieces, ", "", heading)), r) } }
annotation <- if (length(any_rows)) c("## The hand annotation of the pieces", "",
  sprintf("From `%s`, the pieces with at least one error of any kind, counted twice as in that table. They were read blind. The annotation is no condition of the rule.", table_05b), "",
  "| Model | Count | Pieces annotated | Errors counted | Pieces with at least one error | Share of pieces |", rule(c(16, 32, 10, 9, 13, 20)),
  unlist(lapply(both, function(s) vapply(Filter(function(r) r[2] == s$model, any_rows), function(r) sprintf("| %s | %s | %s | %s | %s | %s |", r[2], r[1], r[4], r[5], r[6], r[7]), ""))), "")

# ---- the table
out <- c("# 05c The model comparison", "",
  sprintf("The pieces and the leads of Topics %s, written by %s in `%s` and by %s, with its reasoning off, in `%s`: the same layer, the same plans and the same facts for both. Every number is counted as in test 05, over every answer, those replaced after a retry included, and each rate has its 95 percent Wilson interval in brackets.",
          paste(sub("T", "", sort(common)), collapse = " and "), a$model, folders[["final"]], b$model, folders[["comparison"]]), "",
  "## The rule and its six conditions", "",
  sprintf("The rule was fixed before the comparison ran: %s takes the pieces only if all six conditions hold, faithfulness first and speed last. An interval is below another when its upper end lies under the other's lower end.", b$model), "",
  conditions, "",
  "## The counts behind conditions 2 to 5", "", counts, "",
  "Figures under `<use>` that an answer with exact figures did not write, of those it was given, by format:", "", not_written, "",
  "The figures found nowhere in the request:", "", if (length(nowhere)) paste("-", nowhere) else "None.", "",
  "## Retries and failed checks", "", retries, "",
  "## Speed", "", "The seconds of the calls that were answered. The inside pieces of an issue are sent at once, and each of their records holds the time of the whole batch; an issue's seconds are those of its inside pieces, of the pieces asked for again and of the lead.", "", speed, "",
  annotation,
  "## The decision", "", decision)
writeLines(out, "03_Verification/results/05c_model_comparison.md")
cat(out, sep = "\n")
