# 02_Game/bank/guided.R — Section 4.3.2, the guided start: the game's rates and plans computed once into content/guided/

# Section 4.3.2: the reference bank's decisions for a topic's guided quarters. The game itself never calls this function: it wrote the files of content/guided/, one for each topic with guided quarters, and the game reads those files
guided_rates <- function(id) {
  s <- load_topic(id)
  if (is.null(s$guided)) return(NULL)
  run  <- run_start(s, seed = 1)
  par  <- run$config$par; H <- par$H
  word <- word_on(s)
  rows <- list(); plan <- NULL
  for (q in s$guided$quarters) {
    shocks <- classify(run$innovations[q, ], run$foreseen, run$votes, q, classes)
    for (ty in names(shocks$shocks)) shocks$shocks[[ty]]$reported <- "exact"
    run$sheets[[q]] <- list(shocks = shocks)
    state <- run$states[[q]]
    fair  <- fair_quarter(run, q, state = state)
    in_force <- if (q > 1) run$quarters$rate[q - 1] else steady_rate(par)
    plan  <- bank_plan(run$config, fair, word, word_boxes(run$config, fair, state, in_force, word), run$T - q + 1, shifted(plan), previous = in_force)
    rates <- round(plan$rates, 2)
    rows[[length(rows) + 1]] <- data.frame(topic = id, q = q, action = s$guided$action, rate = rates[1],
                                           as.list(setNames(rates, paste0("plan_", seq_len(H)))))
    run <- run_close(run, list(rate = rates[1], announce = if (word) rates[-1]))
  }
  table <- do.call(rbind, rows)
  write.csv(table, file.path("02_Game/content/guided", paste0(id, ".csv")), row.names = FALSE)
  table
}
