# 02_Game/llm/facts.R — Section 4.2.2 and v6 §2.4: the sheet's facts as sentences, with exact figures or in plain words, and the terms a call's texts use

# v6 §8.1, principle 7: a figure without trailing zeros, to two decimals at most
plain_number <- function(x) format(round(x, 2) + 0, nsmall = 0, scientific = FALSE, trim = TRUE)

# v6 §8.1, principle 7: one of the law's constants as the texts name it, to one decimal at most
constant <- function(x) plain_number(round(x, 1))

# v6 §8.1: a list in words, its last two parts joined by a word
word_list <- function(x, last = "and") if (length(x) < 2) paste(x) else paste(paste(x[-length(x)], collapse = ", "), last, x[length(x)])

# v6 §5.4: a figure's bounds on the plain-words scale, its threshold once, twice and three times, and half of them for a change
scale_bounds <- function(figure, change = FALSE) {
  th <- classes$thresholds
  th$pressing[[figure]] * th$scale_steps * (if (change) th$change_share else 1)
}

# v6 §5.4: where a value stands on the plain-words scale, from 0 within normal to 3 beyond the second class
scale_class <- function(x, bounds) findInterval(abs(x), bounds)

# v6 §2.4: each fact the sheet holds with the case and the values of its sentence; a distance is measured from the law's constant as the sentence names it, so that its figures agree; a fact the sheet does not hold is left out
fact_parts <- function(sheet) {
  fig <- sheet$figures; law <- sheet$law; pub <- sheet$public; w <- sheet$word; g <- sheet$government; sh <- sheet$shocks; th <- classes$thresholds
  zero   <- function(x) abs(x) < 0.005
  off    <- function(value, law_constant) value - round(law_constant, 1)
  side   <- function(x, up = "above", down = "below") if (x > 0) up else down
  away   <- function(x, figure) scale_words[[side(x)]][scale_class(x, scale_bounds(figure)) + 1]
  level  <- function(gap, figure, ...) c(list(case = c(exact = if (zero(gap)) "on" else "off", words = "off"),
                                              gap = n2(abs(gap)), side = side(gap), distance = away(gap, figure)), list(...))
  change <- function(x, figure) list(case = c(exact = if (zero(x)) "unchanged" else side(x, "rose", "fell"), words = "moved"), change = n2(abs(x)),
                                     moved = scale_words[[side(x, "rose", "fell")]][scale_class(x, scale_bounds(figure, TRUE)) + 1])
  billions <- function(x) formatC(x, format = "f", digits = 0, big.mark = ",")
  out <- list()
  out$population       <- list(population = round(fig$population / 1e6))
  out$labour_force     <- list(labour_force = round(fig$labour_force / 1e6))
  out$inflation        <- level(off(fig$inflation, law$target), "inflation", inflation = n2(fig$inflation), target = constant(law$target))
  out$inflation_change <- change(fig$inflation_change, "inflation")
  out$inflation_before <- list(inflation = n2(fig$inflation_before), distance = away(off(fig$inflation_before, law$target), "inflation"))
  out$wage_inflation   <- level(off(fig$wage_inflation, law$wage_normal), "wages", wage_inflation = n2(fig$wage_inflation), wage_normal = constant(law$wage_normal))
  out$wage_real <- list(case = c(exact = if (zero(fig$wage_real)) "same" else side(fig$wage_real, "faster", "slower"),
                                 words = if (scale_class(fig$wage_real, scale_bounds("wages", TRUE)) == 0) "same" else side(fig$wage_real, "faster", "slower")),
                        gap = n2(abs(fig$wage_real)))
  out$growth <- level(off(fig$growth, law$trend_growth), "growth", growth = n2(abs(fig$growth)), trend = constant(law$trend_growth))
  if (fig$growth <= -0.005) out$growth$case <- c(exact = "shrank", words = "shrank")
  out$output <- list(level = billions(fig$output_level), trend_level = billions(fig$output_trend))
  if (isTRUE(fig$recession)) out$output_fell <- list(case = "recession") else if (isTRUE(fig$output_fell)) out$output_fell <- list(case = "fell")
  jobless <- off(fig$unemployment, law$natural_unemployment)
  out$unemployment <- level(jobless, "unemployment", unemployment = n2(fig$unemployment), natural = constant(law$natural_unemployment))
  k <- scale_class(jobless, scale_bounds("unemployment"))
  out$persons <- list(case = c(exact = "one", words = if (k == 0) "same" else side(jobless, "more", "fewer")),
                      persons = persons(fig$unemployed_persons), Size = cap1(scale_words$size[k + 1]))
  if (fig$quarters_above_natural > 0) out$quarters_above <- list(case = if (fig$quarters_above_natural == 1) "one" else "many", n = fig$quarters_above_natural)
  k <- scale_class(fig$rate_change, scale_bounds("inflation", TRUE))
  out$rate <- list(case = c(exact = if (zero(fig$rate_change)) "unchanged" else "moved",
                            words = if (zero(fig$rate_change)) "unchanged" else if (k == 0) "still" else side(fig$rate_change, "raised", "lowered")),
                   rate = n2(fig$rate), change = n2(abs(fig$rate_change)), side = side(fig$rate_change, "higher", "lower"), pace = scale_words$pace[k + 1])
  out$target <- list(target = constant(law$target))
  out$trend_growth <- list(trend = constant(law$trend_growth))
  out$natural_unemployment <- list(natural = constant(law$natural_unemployment))
  out$wage_normal <- list(wage_normal = constant(law$wage_normal))
  out$floor <- list()
  out$cap <- list(cap = constant(law$cap))
  out$reach <- list(H = law$H)
  out$election_interval <- list(interval = law$election_interval)
  out$expected_inflation <- list(expected = n2(pub$expected_inflation), distance = away(off(pub$expected_inflation, law$target), "inflation"))
  if (!is.na(pub$perceived_aim)) {
    out$aim <- level(pub$perceived_aim, "inflation", aim = n2(law$target + pub$perceived_aim))
    out$aim_change <- change(pub$aim_change, "inflation")
  }
  if (!is.na(pub$trust_percent))
    out$trust <- list(trust = formatC(pub$trust_percent, format = "f", digits = 0),
                      level = scale_words$trust[findInterval(pub$trust_percent, th$trust_levels) + 1],
                      direction = scale_words$direction[[if (abs(pub$trust_change) < th$trust_steady) "steady" else side(pub$trust_change, "rising", "falling")]])
  if (pub$spell > 0) out$spell <- list(case = if (pub$spell == 1) "one" else "many", n = pub$spell)
  if (isTRUE(w$judged) && !is.na(w$announced)) {
    d <- w$departure; inside <- abs(d) <= law$cone_width; k <- scale_class(d, scale_bounds("inflation", TRUE))
    exact <- if (isTRUE(w$kept)) (if (zero(d)) "as_announced" else if (inside) "kept_band" else "kept_room") else if (inside) "broken_plan" else "broken_rate"
    out$judgement <- list(case = c(exact = exact, words = if (exact == "kept_band" && k == 0) "as_announced" else exact),
                          announced = n2(w$announced), set = n2(w$set), size = scale_words$size[k + 1], side = side(d))
  }
  if (isTRUE(w$has_path)) {
    out$room <- list(case = if (!isTRUE(w$news)) "none" else if (zero(w$room_due)) "flat" else "room", room = n2(abs(w$room_due)), side = side(w$room_due),
                     size = scale_words$size[scale_class(w$room_due, scale_bounds("inflation", TRUE)) + 1])
    out$path <- list(case = c(exact = "one", words = if (nrow(w$path) == 1) "one" else "many"), n = nrow(w$path), last = max(w$path$q),
                     path = word_list(sprintf("%s percent for quarter %d", n2(w$path$rate), w$path$q)))
  }
  for (s in sh$shocks) out[[paste0("shock_", s$type)]] <- list(case = c(exact = s$sign, words = "one"), size = plain_number(abs(s$size)), class_words = s$words)
  if (!length(sh$shocks)) out$no_shock <- list()
  if (isTRUE(sh$path_started)) out$slump <- list(case = "begins", Slump = cap1(sh$path_words), n = sh$path_length)
  else if (!is.null(sh$path_length) && !is.na(sh$path_length)) out$slump <- list(case = "running", n = sh$path_length)
  if (isTRUE(sh$vote_due)) out$vote_due <- list()
  if (!is.null(g)) {
    bounds <- c(0.05, classes$bounds$purchases[1:2]); kl <- findInterval(abs(g$purchases), bounds); kc <- findInterval(abs(g$purchases_change), bounds)
    out$spending <- list(case = c(exact = paste(if (kl == 0) "at" else "off", if (kc == 0) "same" else side(g$purchases_change, "more", "less"), sep = "_"),
                                  words = if (kl == 0) "at" else "off"),
                         purchases = n1(abs(g$purchases)), side = side(g$purchases), change = n1(abs(g$purchases_change)),
                         distance = scale_words[[side(g$purchases)]][kl + 1], moved = scale_words[[side(g$purchases_change, "rose", "fell")]][kc + 1])
    half <- function(share) if (share > 50.05) "more" else if (share < 49.95) "fewer" else "half"
    out$office <- list(case = c(exact = "one", words = half(g$poll)), Party = cap1(g$party), poll = n1(g$poll))
    out$opposition <- list(case = c(exact = "one", words = half(g$poll_opposition)), poll = n1(g$poll_opposition))
    if (isTRUE(is.finite(g$next_election))) out$next_election <- list(case = if (g$next_election <= 1) "now" else "later", n = g$next_election)
    if (isTRUE(g$vote_held)) out$vote_result <- list(case = if (g$vote_reelected) "reelected" else "won", Party = cap1(g$vote_winner), share = n1(g$vote_poll))
    if (!is.null(g$last_vote)) out$last_vote <- list(q = g$last_vote$q, party = g$last_vote$winner, share = n1(g$last_vote$share))
  }
  cause <- function(driver) if (driver %in% c("none", "mixed")) list(case = "none")
                            else list(case = "one", Cause = cause_words[[if (driver == "rate") side(fig$rate_change, "rate_up", "rate_down") else driver]])
  out$driver_output <- cause(sheet$drivers$output)
  out$driver_inflation <- cause(sheet$drivers$inflation)
  v <- sheet$pressing$variable
  out$pressing <- if (is.na(v)) list(case = "none")
                  else list(case = "one", Figure = cap1(variable_words[[v]]), others = word_list(variable_words[setdiff(names(pressing_facts), v)], "or"))
  out
}

# v6 §2.4: a fact's sentence in a precision, NULL where the sheet does not hold the fact or the fact has no sentence in that precision
fact_sentence <- function(name, parts, precision) {
  p <- parts[[name]]; f <- facts[[name]]
  if (is.null(p)) return(NULL)
  set <- if (!is.null(f$both)) f$both else f[[precision]]
  if (is.null(set)) return(NULL)
  fill(if (is.null(names(set))) set else set[[if (length(p$case) > 1) p$case[[precision]] else p$case]], p)
}

# v6 §5.4: the fact that says where each pressing figure stands
pressing_facts <- c(inflation = "inflation", growth = "growth", wages = "wage_inflation", unemployment = "unemployment")

# v6 §2.4 and §12.5: the facts that word a list of sheet fields, in the fields' order and each once; all of a quarter's shocks for the field shocks, and with the pressing figure the fact of where it stands
facts_of <- function(fields, sheet) {
  of <- function(field) {
    if (field == "shocks") return(c(if (length(sheet$shocks$shocks)) paste0("shock_", names(sheet$shocks$shocks)), "no_shock", "slump"))
    v <- sheet$pressing$variable
    if (field == "pressing.variable") return(c("pressing", if (is.na(v)) pressing_facts[c("inflation", "growth", "unemployment")] else pressing_facts[[v]]))
    names(facts)[vapply(facts, function(f) field %in% f$fields, logical(1))]
  }
  unique(unlist(lapply(fields, of), use.names = FALSE))
}

# Section 4.2.2 and v6 §12.5: the facts of a piece as sentences in its precision, the must facts, each followed by the law's constant it compares with, and the may facts
piece_facts <- function(item, sheet) {
  parts <- fact_parts(sheet)
  must <- character(0)
  for (f in facts_of(item$must, sheet)) must <- c(must, f, facts[[f]]$compares)
  must <- unique(must)
  say <- function(names) unlist(lapply(names, fact_sentence, parts = parts, precision = item$precision), use.names = FALSE)
  list(use = say(must), may_use = say(setdiff(facts_of(item$may, sheet), must)))
}

# v6 §8.2: the glossary's entries for the terms a call's texts use, as lines; a longer phrase is found before a shorter one inside it, and the newspaper's readers are given no everyday term
terms_of <- function(texts, always = character(0), reader = FALSE) {
  text <- tolower(paste(texts, collapse = "\n"))
  phrases <- lapply(strsplit(glossary$found_as, ";", fixed = TRUE), trimws)
  all <- data.frame(entry = rep(seq_along(phrases), lengths(phrases)), phrase = unlist(phrases), stringsAsFactors = FALSE)
  found <- glossary$term %in% always
  for (i in order(-nchar(all$phrase))) {
    pattern <- paste0("(?<![a-z])", all$phrase[i], "s?(?![a-z])")
    if (grepl(pattern, text, perl = TRUE)) { found[all$entry[i]] <- TRUE; text <- gsub(pattern, " ", text, perl = TRUE) }
  }
  if (reader) found <- found & !glossary$everyday
  sprintf("%s: %s", glossary$term[found], glossary$explanation[found])
}
