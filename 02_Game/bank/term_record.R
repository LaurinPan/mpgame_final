# 02_Game/bank/term_record.R — Section 4.2.2, the term's record for the debrief, its term losses discounted as in (A36)

# Section 4.2.2: the record of a term, the two runs, the loss by quarter with its weight, the term losses with their equivalent misses, the events, and what the topic shows of the public, the word and the government
term_record <- function(run) {
  T <- run$T; q <- run$quarters; b <- run$bank$quarters
  weight <- run$config$par$beta^(seq_len(T) - 1)
  loss <- data.frame(q = seq_len(T), player = consts$loss_scale * q$loss, bank = consts$loss_scale * b$loss, weight = weight)
  events <- list()
  for (k in seq_len(T)) {
    sh <- run$sheets[[k]]$shocks
    for (s in sh$shocks) events[[length(events) + 1]] <- list(q = k, type = s$type, sign = s$sign, class = s$class,
                                                           reported = s$reported, words = s$words)
    if (isTRUE(sh$path_started)) events[[length(events) + 1]] <- list(q = k, type = "slump", class = sh$path_class,
                                                                   length = sh$path_length, words = sh$path_words)
    if (isTRUE(sh$vote_due)) events[[length(events) + 1]] <- list(q = k, type = "vote")
  }
  list(topic = run$topic, name = run$script$name, T = T,
       covers = run$script$debrief$covers,
       player = q, bank = b, loss = loss, term = term_losses(loss), discount = run$config$par$beta, v = q$v,
       guided = run$script$guided$quarters, events = events,
       shows = list(aim = "expectations" %in% run$script$panels, word = word_on(run$script), spending = 6 %in% run$config$on,
                    votes = length(run$votes) > 0, paper = "newspaper" %in% run$script$panels, share = 1 - run$config$par$s_C))
}

# (A36): a term loss, each quarter's loss weighted by beta^(t - 1) from the term's first quarter
term_loss <- function(loss, par) sum(par$beta^(seq_along(loss) - 1) * loss)

# Section 4.2.2: the two term losses and their equivalent misses, the inflation miss in points that, held in every quarter, would give the same loss
term_losses <- function(loss) {
  player <- sum(loss$weight * loss$player); bank <- sum(loss$weight * loss$bank)
  list(player = player, bank = bank, equivalent = list(player = sqrt(player / sum(loss$weight)), bank = sqrt(bank / sum(loss$weight))))
}
