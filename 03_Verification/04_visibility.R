# 04 Visibility (Section 3.2's criterion; Section 3.3, rules 1 and 3, the
# nesting table; topic scenes and seeded random shocks around them). One
# row per learning objective of Section 2.3 with one
# measure, as the thesis words it: its effect in its topic's scene without
# noise, from the scripts as they stand, against the spread, the standard
# deviation, of the same measure across 20 runs of the same topic over the
# same term, each run the scene with a small innovation added in every
# quarter, drawn from the run's seed with a standard deviation equal to the
# small class's value of Section 4.2.2 (content/classes.R), for each type the
# topic's chapter knows: demand in every chapter, costs in Chapter B,
# government spending in Chapter D. The bound is "effect above the spread", and an
# objective that fails is listed under the table. A vote's chance is read
# off the poll at the vote, exact, never over draws; the draws of the plain
# plays are 0.5. Run from the main folder; the engine and 02_Game/ are loaded
# with the one-line loader.
for (f in list.files(c("01_Engine", "02_Game"), pattern = "[.]R$", recursive = TRUE, full.names = TRUE)) source(f)
seeds <- 1:20

loss_of     <- function(q, par) term_loss(consts$loss_scale * q$loss, par)
parts_of    <- function(q, par) { p <- loss_parts(q$pi_p, q$x, par); c(inflation = term_loss(p$inflation, par), output = term_loss(p$output, par)) }
rule_rate   <- function(quarter, config) steady_rate(config$par) + to_year(solve_quarter(config, quarter, list(rate = "rule"))$i)
needed_rate <- function(quarter, config) steady_rate(config$par) + to_year(solve_quarter(config, quarter, list(rate = "rule"))$r_e)
by_quarter  <- function(f) { k <- 0; function(quarter, config) { k <<- k + 1; f(k, quarter, config) } }

# the topic's scene (Section 4.3.1 and Table 1) and, with a seed, the scene with the small noise:
# the small class's value of each type the chapter knows as the standard
# deviation of an innovation in every quarter, drawn from the seed as
# Chapter E's innovations are (engine_inputs)
scene <- function(id, seed = NULL) {
  s <- load_topic(id)
  if (!is.null(seed)) s$random <- list(demand = classes$values$demand[1], technology = 0,
                                       costs = if (s$chapter == "B") classes$values$costs[1] else 0,
                                       purchases = if (s$chapter == "D") classes$values$purchases[1] else 0)
  s
}
# the term through play() on the scene and a policy, the player's figures
# only, the votes' draws at 0.5
plain <- function(id, seed, policy) {
  run <- run_start(scene(id, seed), seed); run$draws[] <- 0.5
  list(quarters = play(run$config, run$start, term_script(run, run$T), policy)$quarters, config = run$config)
}
# the same through the five calls, the issues and the guided quarters as the
# player meets them, with the reference bank's own run; without `word` the
# topic is played without the bank's word, the bank without announcements
headless <- function(id, seed, word = TRUE) {
  s <- scene(id, seed); if (!word) s$word <- FALSE
  play_headless(s, "rule", llm = FALSE, seed = seed, print = FALSE)
}
# the engine's quarter object of quarter k, the quarters before it played
# under the believed rule
quarter_at <- function(id, seed, k) {
  run <- run_start(scene(id, seed), seed); run$draws[] <- 0.5
  if (k > 1) { run$states[[k]] <- play(run$config, run$start, term_script(run, k - 1), "rule")$state; run$t <- k - 1 }
  list(quarter = run_open(run)$quarter$engine, config = run$config)
}

# --- the measures, as the thesis words them -------------------------------------

# Monetary policy with lags (Topic 1): the share of a one-point rate rise's
# effect on inflation that arrives after its quarter, the rise in quarter 1
# at the rule's rate plus one point, the rule afterwards
share_after <- function(id, seed) {
  base <- plain(id, seed, "rule")$quarters
  imp  <- plain(id, seed, by_quarter(function(k, quarter, config) if (k == 1) list(rate = rule_rate(quarter, config) + 1) else list(rate = "rule")))$quarters
  d <- abs(imp$pi_p - base$pi_p); sum(d[-1]) / sum(d)
}
# Trade-off after supply shocks (Topic 2): the smallest larger part of the
# loss any constant rate from 0 to 15 or the believed rule achieves after
# the rise in costs
smallest_larger_part <- function(id, seed) {
  cands <- c(lapply(0:15, function(r) by_quarter(function(k, quarter, config) list(rate = r))), list("rule"))
  min(vapply(cands, function(p) { q <- plain(id, seed, p); max(parts_of(q$quarters, q$config$par)) }, numeric(1)))
}
# Expectations (Topic 3): the fall of the public's view of the aim under the
# reference bank's own run, from the start's view to the term's end, points
# a year
aim_fall <- function(id, seed) { r <- headless(id, seed); r$start$aim - r$bank$quarters$aim[r$T] }
# Forward guidance at the floor (Topic 4): the term loss the reference bank
# saves with its word, against the same bank without announcements
guidance <- function(id, seed) headless(id, seed, word = FALSE)$record$term$bank - headless(id, seed)$record$term$bank
# Gains from commitment (Topic 5): the term loss of breaking the word, the
# reference bank's decisions with only quarter 8's rate set one point a year
# below the rate announced for it, without news, against the decisions as
# they stand
commitment <- function(id, seed, at = 8) {
  r <- headless(id, seed); bank <- r$bank
  announced <- steady_rate(r$config$par) + to_year(bank$states[[at]]$word$due)
  broken <- bank$decisions; broken[[at]]$rate <- max(0, announced - 1)
  loss_of(play(r$config, r$start, term_script(r, r$T), policy_of(broken))$quarters, r$config$par) - r$record$term$bank
}
# Fiscal policy (Topic 6): the rise of the rate the economy needs, r^n plus
# the target, in the programme's first quarter, from the quarter before it,
# the steady-state rate where the programme opens the term, points a year
fiscal <- function(id, seed) {
  at  <- scene(id)$timeline[[1]]$q
  now <- quarter_at(id, seed, at)
  before <- if (at > 1) { b <- quarter_at(id, seed, at - 1); needed_rate(b$quarter, b$config) } else steady_rate(now$config$par)
  needed_rate(now$quarter, now$config) - before
}
# Electoral pressure (Topic 7): the boosting party's chance at its first
# re-election, the poll at the vote, under a bank that holds the rate
# through the window against the believed rule
hold_window <- function() { last <- NULL; function(quarter, config) {
  if (quarter$gov$to_election > config$par$q_b) { last <<- rule_rate(quarter, config); list(rate = "rule") } else list(rate = last) } }
chance_first_vote <- function(id, seed, policy) {
  q <- plain(id, seed, policy)$quarters; v <- which(!is.na(q$election))[1]
  if (q$party[v] == 1) q$vote_poll[v] else 1 - q$vote_poll[v]
}
electoral <- function(id, seed) chance_first_vote(id, seed, hold_window()) - chance_first_vote(id, seed, "rule")

# --- the effects in the scenes and the spreads across the noisy runs ---------------
measures <- list(lags = function(seed) share_after("T1", seed), trade_off = function(seed) smallest_larger_part("T2", seed),
                 aim = function(seed) aim_fall("T3", seed), guidance = function(seed) guidance("T4", seed),
                 commitment = function(seed) commitment("T5", seed), fiscal = function(seed) fiscal("T6", seed),
                 electoral = function(seed) electoral("T7", seed))
effect <- vapply(measures, function(m) m(NULL), numeric(1))
noisy  <- matrix(sapply(measures, function(m) vapply(seeds, m, numeric(1))), nrow = length(seeds), dimnames = list(NULL, names(measures)))
spread <- apply(noisy, 2, sd); mean_noisy <- colMeans(noisy)

# --- the table -------------------------------------------------------------------
rows <- c(lags       = "Monetary policy with lags (Topic 1): the share of a one-point rate rise's effect on inflation that arrives after its quarter",
          trade_off  = "Trade-off after supply shocks (Topic 2): the smallest larger part of the loss any constant rate or the rule achieves after the rise in costs, squared points a year",
          aim        = "Expectations (Topic 3): the fall of the public's view of the aim under the reference bank, points a year",
          guidance   = "Forward guidance at the floor (Topic 4): the term loss the reference bank saves with its word, against the same bank without announcements",
          commitment = "Gains from commitment (Topic 5): the term loss of breaking the word, quarter 8's rate one point below the rate announced for it, against the decisions as they stand",
          fiscal     = "Fiscal policy (Topic 6): the rise of the rate the economy needs in the programme's first quarter, points a year",
          electoral  = "Electoral pressure (Topic 7): the boosting party's chance at its first re-election under a bank that holds the rate in the window, less the chance under the believed rule, from the poll at the vote")
visible <- effect > spread
lines <- c("| Objective and measure | Effect in its scene | Spread across the noisy runs (mean) | Visible |", "|---|---|---|---|",
           sprintf("| %s | %.3f | %.3f (%.3f) | %s |", rows, effect, spread, mean_noisy, ifelse(visible, "yes", "no")),
           "",
           sprintf("Bound: the effect above the spread (Section 3.2). Every term loss is discounted as in (A36), each quarter's loss weighted by beta^(t-1) from the term's first quarter. %s", if (all(visible)) "Every objective is visible." else paste0("Not visible: ", paste(sub(" [(].*$", "", rows[!visible]), collapse = "; "), ".")),
           sprintf("Noise: %d seeded runs of each scene over its term with a small innovation in every quarter, its standard deviation the small class's value (Section 4.2.2): demand %.2f percent in every chapter, costs %.2f points a year in Chapter B, government spending %.0f percent of government spending in Chapter D.",
                   length(seeds), classes$values$demand[1], classes$values$costs[1], classes$values$purchases[1]))
writeLines(lines, "03_Verification/results/04_visibility.md")
cat(lines, sep = "\n")
