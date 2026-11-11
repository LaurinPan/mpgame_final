# 02_Game/play/script.R — v6 §2, the schema of a topic script, and the run object

# v6 §2.1: a topic's script, checked against the schema
load_topic <- function(id) {
  e <- new.env()
  sys.source(file.path("02_Game/content/scripts", paste0(id, ".R")), envir = e)
  s  <- get(id, envir = e)
  ch <- chapters[[s$chapter]]
  stopifnot(all(c(1, 3, 4) %in% s$stages), setequal(s$stages, ch$stages),
            nzchar(s$task), nzchar(s$summary), s$path %in% c("required", "optional"),
            all(s$panels %in% panels$id))
  for (p in s$panels) {
    st <- panels$stage[panels$id == p]
    if (st != "base" && !(as.numeric(st) %in% s$stages)) stop(id, ": the panel ", p, " needs stage ", st)
  }
  need <- c(demand = 1, technology = 1, costs = 2, purchases = 6)
  for (ev in s$timeline) {
    if (!is.null(ev$innovation) && !(need[[ev$innovation]] %in% s$stages)) stop(id, ": a ", ev$innovation, " shock needs stage ", need[[ev$innovation]])
    if (!is.null(ev$path) && !(3 %in% s$stages)) stop(id, ": a foreseen path needs stage 3")
    if (isTRUE(ev$vote) && !(6 %in% s$stages)) stop(id, ": a vote needs stage 6")
  }
  if (5 %in% s$stages && is.null(s$start$chi)) stop(id, ": stage 5 needs chi at the start")
  if (6 %in% s$stages && is.null(s$start$gov)) stop(id, ": stage 6 needs gov at the start")
  if (!is.null(s$random) && s$chapter != "E") stop(id, ": random innovations belong to Chapter E")
  if (!is.null(s$guided) && length(ch$topics) > 1 && id == tail(ch$topics, 1)) stop(id, ": no guided quarters in a chapter's last topic")
  s
}

# v6 §3 and §12.1: whether a topic has the bank's word, the path editor and box W; a script's own `word` field, which test 04 sets, overrides the topics' list
word_on <- function(script) if (is.null(script$word)) script$id %in% word_topics else isTRUE(script$word)

# v6 §2.2 and Section 4.3.1: the script as play()'s inputs, Chapter E's innovations drawn from the seed
engine_inputs <- function(script, seed = NULL) {
  T   <- script$term
  inn <- data.frame(q = seq_len(T), a = 0, z = 0, nu = 0, g = 0)
  if (!is.null(script$random)) {
    if (is.null(seed)) seed <- sample.int(.Machine$integer.max, 1)
    sd  <- lapply(script$random, function(v) if (is.character(v)) classes[[v]] else v)
    old <- if (exists(".Random.seed", envir = globalenv())) get(".Random.seed", envir = globalenv()) else NULL
    set.seed(seed)
    inn$a  <- rnorm(T, sd = sd$technology); inn$z <- rnorm(T, sd = sd$demand)
    inn$nu <- rnorm(T, sd = sd$costs);      inn$g <- rnorm(T, sd = sd$purchases)
    if (is.null(old)) rm(".Random.seed", envir = globalenv()) else assign(".Random.seed", old, envir = globalenv())
  }
  foreseen <- NULL; votes <- integer(0)
  for (ev in script$timeline) {
    if (!is.null(ev$innovation)) {
      col <- c(demand = "z", technology = "a", costs = "nu", purchases = "g")[[ev$innovation]]
      inn[[col]][ev$q] <- inn[[col]][ev$q] + ev$size
    }
    if (!is.null(ev$path)) foreseen <- list(start = ev$q, d = ev$path)
    if (isTRUE(ev$vote)) votes <- c(votes, ev$q)
  }
  start <- list(omega_gap = 0, shocks = list(a = 0, z = 0, nu = 0))
  if (!is.null(script$start$aim)) { start$aim <- script$start$aim; start$chi <- script$start$chi }
  if (!is.null(script$start$gov)) start$gov <- script$start$gov
  list(config = configure(script$stages, "game"), start = start, innovations = inn,
       foreseen = foreseen, votes = votes, T = T, seed = seed)
}

# Section 4.3.1: the run object at the term's start
run_start <- function(script, seed = NULL) {
  inp   <- engine_inputs(script, seed)
  empty <- list(eps_a = numeric(0), eps_z = numeric(0), eps_nu = numeric(0), eps_g = numeric(0), draws = numeric(0))
  run <- list(id = format(Sys.time(), "%Y%m%d%H%M%S"),
              topic = script$id, chapter = script$chapter, script = script,
              config = inp$config, T = inp$T, t = 0, seed = inp$seed,
              innovations = inp$innovations, foreseen = inp$foreseen, votes = inp$votes,
              draws = rep(NA_real_, inp$T), start = inp$start,
              decisions = list(), quarters = NULL,
              states = list(play(inp$config, inp$start, empty, "rule")$state),
              sheets = list(), quarter = NULL, bank = NULL)
  run$row0 <- quarter_zero(run)
  run
}

# A.7, "Solving a Quarter": play()'s script for the first q quarters
term_script <- function(run, q) {
  inn <- run$innovations[seq_len(q), ]
  list(eps_a = inn$a, eps_z = inn$z, eps_nu = inn$nu, eps_g = inn$g,
       draws = run$draws[seq_len(q)], foreseen = run$foreseen)
}

# A.7, "Solving a Quarter": play()'s policy from the decisions by quarter
policy_of <- function(decisions) {
  k <- 0
  function(quarter, config) { k <<- k + 1; d <- decisions[[k]]; list(rate = d$rate, announce = d$announce) }
}

# v6 §7, step 3: the open quarter's engine object
run_open <- function(run) {
  q <- run$t + 1; inn <- run$innovations[q, ]
  run$quarter <- list(engine = begin_quarter(run$config, run$states[[q]],
                        list(a = inn$a, z = inn$z, nu = inn$nu, g = inn$g, draw = run$draws[q],
                             d_path = if (isTRUE(run$foreseen$start == q)) run$foreseen$d)))
  run
}

# v6 §7, step 5: the quarter closed on a decision, the election's draw where a vote falls due
run_close <- function(run, decision) {
  q <- run$t + 1
  if (q %in% run$votes && is.na(run$draws[q]))
    run$draws[q] <- if (is.null(run$draw_seed)) runif(1) else seeded(run$draw_seed, function() { k <- match(q, run$votes); runif(k)[k] })
  run$decisions[[q]] <- decision
  out <- play(run$config, run$start, term_script(run, q), policy_of(run$decisions))
  run$quarters <- out$quarters; run$states[[q + 1]] <- out$state; run$t <- q
  run
}
