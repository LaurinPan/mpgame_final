# 02_Game/llm/editor.R — Section 4.2.2, the editor: the issue's plan, the number formats and the placeholders

# Section 4.2.2: a type's condition evaluated on the sheet
holds <- function(condition, sheet) {
  if (condition == "TRUE") return(TRUE)
  expr <- gsub("([a-z]+)[.]([a-z_]+)", "sheet$\\1$\\2", condition)
  env  <- list(sheet = sheet,
               shock = function(type) type %in% names(sheet$shocks$shocks),
               threshold = function(name) { th <- classes$thresholds; if (name %in% names(th$pressing)) th$pressing[[name]] else th[[name]] })
  isTRUE(eval(parse(text = expr), envir = env, enclos = baseenv()))
}

# Section 4.2.2: a draw from a seed, the global stream untouched
seeded <- function(seed, draw) {
  old <- if (exists(".Random.seed", envir = globalenv())) get(".Random.seed", envir = globalenv()) else NULL
  set.seed(seed)
  on.exit(if (is.null(old)) rm(".Random.seed", envir = globalenv()) else assign(".Random.seed", old, envir = globalenv()))
  draw()
}

# Section 4.2.2: the seed of a topic, quarter and slot
slot_seed <- function(topic, q, slot) sum(utf8ToInt(paste(topic, slot))) * 7919 + q * 131

# Section 4.2.2: the shocks a piece carries
shocks_in <- function(fields, sheet) {
  present <- names(sheet$shocks$shocks)
  if ("shocks" %in% fields) return(present)
  intersect(sub("^shocks[.]", "", grep("^shocks[.](demand|technology|costs|purchases)$", fields, value = TRUE)), present)
}

# Section 4.2.2: the features a type may require, the panels shown and, by topic, the word, the public's view of the aim, government spending and the politics of a vote
topic_features <- function(script) c(script$panels, if (word_on(script)) "word", if (5 %in% script$stages) "aim", if (6 %in% script$stages) "purchases",
                                     if (6 %in% script$stages && any(vapply(script$timeline, function(ev) isTRUE(ev$vote), logical(1)))) "politics")

# Section 4.2.2: the issue's plan, one type per slot with its tone, its precision, exact where the type draws exact only, and its speakers, all drawn from the slot's seed, and the shocks reported
edit_issue <- function(sheet, script) {
  shown  <- topic_features(script); stage6 <- 6 %in% script$stages
  sections <- c(L = "Front page", S1 = "The Economy", S2 = "Prices and Wages", S3 = "Jobs",
                S4 = "Markets and the Bank", S5 = if (stage6) "Politics" else "Analysis")
  requires_ok <- function(req) if (req == "") TRUE else if (req == "no politics") !("politics" %in% shown) else req %in% shown
  items <- list()
  for (slot in names(sections)) {
    cands  <- types[types$section == sections[[slot]], ]
    chosen <- NULL
    for (i in seq_len(nrow(cands))) {
      t <- cands[i, ]
      if (requires_ok(t$requires) && holds(t$condition, sheet)) { chosen <- t; break }
    }
    if (is.null(chosen)) stop("no article type holds for slot ", slot)
    tones_allowed <- strsplit(chosen$tones, ";")[[1]]
    draws <- seeded(slot_seed(script$id, sheet$q, slot),
                    function() list(tone = sample(tones_allowed, 1), exact = runif(1) < classes$p_exact, roles = sample(speakers$roles)))
    tone <- if (slot == "L") "reporter" else draws$tone
    exact <- draws$exact || isTRUE(chosen$exact_only)
    role <- if (slot == "L") "lead" else if (chosen$brief) "brief" else "piece"
    has_chart <- chosen$chart != ""
    hit <- which(format_rule$role == role & (is.na(format_rule$tone) | format_rule$tone == tone) &
                 (is.na(format_rule$exact) | format_rule$exact == exact) &
                 (is.na(format_rule$chart) | format_rule$chart == has_chart))[1]
    format <- format_rule$format[hit]
    carried <- function(fields) setdiff(strsplit(fields, ";")[[1]], c("", if (!("word" %in% shown)) word_fields))
    must <- carried(chosen$must); may <- carried(chosen$may)
    items[[slot]] <- list(slot = slot, section = sections[[slot]], type = chosen$id, star = chosen$star, brief = chosen$brief,
                          tone = tone, precision = if (exact) "exact" else "words", format = format,
                          speakers = if (format == "F-VOICES") draws$roles[seq_len(slot_format(format, slot)$quotations)],
                          chart = if (exact && has_chart) chosen$chart else NA,
                          must = must, may = may, carries = shocks_in(c(must, may), sheet))
  }
  reported <- setNames(rep("words", length(sheet$shocks$shocks)), names(sheet$shocks$shocks))
  for (it in items) if (it$precision == "exact") for (ty in it$carries) reported[[ty]] <- "exact"
  selection <- unique(c("L", names(items)[vapply(items, function(it) isTRUE(it$star), logical(1))]))
  list(items = items, reported = reported, selection = selection)
}

# The number style of the game's texts: a figure to two decimals, a zero without a sign
n2 <- function(x) if (is.null(x) || length(x) == 0 || is.na(x[1])) "n/a" else formatC(round(x, 2) + 0, format = "f", digits = 2)

# The number style of the game's texts: a figure to one decimal, a zero without a sign
n1 <- function(x) if (is.null(x) || length(x) == 0 || is.na(x[1])) "n/a" else formatC(round(x, 1) + 0, format = "f", digits = 1)

# The number style of the game's texts: a change with its sign
signed <- function(x) if (is.null(x) || length(x) == 0 || is.na(x[1])) "n/a" else sprintf("%+.2f", x)

# The number style of the game's texts: a count of persons
persons <- function(x) if (is.null(x) || length(x) == 0 || is.na(x[1])) "n/a" else formatC(round(x / 1e5) * 1e5, format = "d", big.mark = ",")

# The style of the game's texts: a sentence's first letter capitalised
cap1 <- function(s) paste0(toupper(substr(s, 1, 1)), substr(s, 2, nchar(s)))

# Section 4.2.2: the pressing variables in words
variable_words <- c(inflation = "inflation", unemployment = "unemployment", growth = "growth", wages = "wage inflation")

# The placeholders of a template or a briefing filled from the sheet
fill_placeholders <- function(text, sheet, guided = NULL) {
  value <- function(name) {
    p <- strsplit(name, "[.]")[[1]]; fig <- sheet$figures; law <- sheet$law; pub <- sheet$public; g <- sheet$government
    switch(name,
      "law.target" = n1(law$target), "law.natural_unemployment" = n1(law$natural_unemployment),
      "law.election_interval" = as.character(law$election_interval), "law.trend_growth" = n1(law$trend_growth),
      "public.perceived_aim" = n2(abs(pub$perceived_aim)),
      "public.spell" = as.character(pub$spell),
      "government.vote_result" = if (!is.null(g) && !is.na(g$vote_result)) g$vote_result else "no election was held",
      "government.poll" = n1(g$poll), "government.purchases" = n1(g$purchases), "government.purchases_change" = signed(g$purchases_change),
      "government.next_election" = as.character(g$next_election),
      "figures.inflation" = n2(fig$inflation), "figures.growth" = n2(fig$growth), "figures.unemployment" = n2(fig$unemployment),
      "figures.unemployed_persons" = persons(fig$unemployed_persons), "figures.wage_inflation" = n2(fig$wage_inflation),
      "figures.rate" = n2(fig$rate), "figures.quarters_above_natural" = as.character(fig$quarters_above_natural),
      "pressing.variable" = if (is.na(sheet$pressing$variable)) "the figures" else variable_words[[sheet$pressing$variable]],
      "pressing.direction" = if (is.na(sheet$pressing$variable)) "near" else sheet$pressing$direction,
      "drivers.output" = sheet$drivers$output_words, "drivers.inflation" = sheet$drivers$inflation_words,
      "word.announced" = n2(sheet$word$announced), "word.kept" = if (isTRUE(sheet$word$kept)) "kept" else "broke",
      "guided.rate" = n2(guided$rate),
      "guided.change" = { d <- guided$rate - guided$previous
                          if (abs(d) < 0.005) "unchanged from last quarter" else sprintf("%s percentage points %s than last quarter", n2(abs(d)), if (d > 0) "higher" else "lower") },
      "guided.path" = paste(sprintf("%s percent", n2(guided$plan)), collapse = ", "),
      {
        if (p[1] == "shocks" && length(p) == 3) {
          s <- sheet$shocks$shocks[[p[2]]]
          if (is.null(s)) "" else if (p[3] == "words") s$words else if (p[3] == "size") signed(s$size) else stop("unknown placeholder ", name)
        } else stop("unknown placeholder ", name)
      })
  }
  for (m in unique(regmatches(text, gregexpr("[{][a-z_.]+[}]", text))[[1]])) {
    v <- value(gsub("[{}]", "", m))
    text <- gsub(m, if (is.null(v) || length(v) == 0 || is.na(v[1])) "n/a" else v, text, fixed = TRUE)
  }
  text
}
