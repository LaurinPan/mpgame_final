# The recordings for 05 (Section 3.3, rule 5), made with the model and kept
# with their calls; a recording that exists is skipped. Three parts:
#   final        one run per topic into 03_Verification/recordings/<topic>.rds,
#                the player under the believed rule with one question to the
#                Chief Economist each quarter, asked with the decision the
#                player is about to take as the typed one
#   walkthrough  Topic 5's walk-through into 03_Verification/recordings/walkthrough/, the player
#                deciding as the reference bank
#   comparison   Topics 3 and 8 again into 03_Verification/recordings_comparison/,
#                the pieces and the leads by the second model of
#                content/models.R with its reasoning off, on the same layer
# A call that died on the connection, one the service never answered, is no
# answer of the model: a topic with such a call is recorded again, three
# times at most, and only an attempt in which every call reached the model
# is kept, so that the folder holds each topic's final attempt alone. The
# election draws come from a seed per topic, the topic's number, so that a
# recording can be made again; in play they stay unseeded. Run from the main
# folder with the key in the environment:
#   Rscript 03_Verification/record_topics.R [part=final|walkthrough|comparison] [topics=T1,T2] [to=<folder>]
for (f in list.files(c("01_Engine", "02_Game"), pattern = "[.]R$", recursive = TRUE, full.names = TRUE)) source(f)
stopifnot(llm_available())
args <- commandArgs(trailingOnly = TRUE)
arg  <- function(name, default) { v <- sub(paste0("^", name, "="), "", grep(paste0("^", name, "="), args, value = TRUE)); if (length(v)) v else default }
parts  <- strsplit(arg("part", "final,walkthrough,comparison"), ",")[[1]]
topics <- strsplit(arg("topics", paste0("T", 1:8, collapse = ",")), ",")[[1]]
questions <- c("What moved inflation most last quarter?",
               "Why does a change in the policy rate reach prices only over the following quarters?",
               "What should I look at before I decide this quarter?")
reached <- function(run) all(vapply(run$calls, function(call) isTRUE(as.integer(call$status) == 200L), logical(1)))
# a run in which every call reached the model, tried three times at most
attempt <- function(what, play, discard = function() NULL) {
  for (k in 1:3) {
    run <- play()
    if (reached(run)) return(run)
    discard()
    cat(what, "attempt", k, ": a call died on the connection, so the attempt is dropped\n")
  }
  stop(what, ": no attempt in which every call reached the model")
}
record <- function(ids, folder) {
  dir.create(folder, showWarnings = FALSE, recursive = TRUE)
  for (id in ids) {
    file <- file.path(folder, paste0(id, ".rds"))
    if (file.exists(file)) next
    saveRDS(attempt(id, function() play_headless(id, "rule", llm = TRUE, seed = 1, draw_seed = as.integer(sub("^T", "", id)), print = FALSE, questions = questions)), file)
    cat(id, "recorded into", folder, "\n")
  }
}
if ("final" %in% parts) record(topics, arg("to", "03_Verification/recordings"))
if ("walkthrough" %in% parts && !file.exists(file.path(arg("to", "03_Verification/recordings/walkthrough"), "calls.json"))) {
  to <- arg("to", "03_Verification/recordings/walkthrough")
  attempt("the walk-through of T5", function() record_walkthrough("T5", dir = to), function() unlink(to, recursive = TRUE))
  cat("the walk-through of T5 recorded into", to, "\n")
}
if ("comparison" %in% parts) {
  models$pieces <- models$comparison
  record(intersect(c("T3", "T8"), topics), arg("to", "03_Verification/recordings_comparison"))
}
