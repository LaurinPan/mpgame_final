# 02_Game/content/debrief.R — Section 4.2.2: the sentences of the debrief's instruction and of the term's record in words

# Section 4.2.2: the sentences the debrief's instruction is composed from
debrief_sentences <- list(
  guided     = "In quarters {list} the bank set the policy rate itself, to show you how it works, so those quarters carry no mark, and you do not judge them.",
  guided_one = "In quarter {list} the bank set the policy rate itself, to show you how it works, so that quarter carries no mark, and you do not judge it.",
  case       = "Your loss is at most the reference bank's. Say so, and say why this can happen: the reference bank counts every change of its rate as a cost and moves gradually, so a governor who moves faster can end a term with a lower loss, and it decides well on your information without being the best possible bank.",
  marks      = "write one text of 60 to 100 words for each of the {n} decisions under <marks>, in their order. Say what you decided in that quarter, what the reference bank would have set in your place, what followed in the economy and why, and the decision's cost as its equivalent miss.",
  marks_one  = "write one text of 60 to 100 words for the decision under <marks>. Say what you decided in that quarter, what the reference bank would have set in your place, what followed in the economy and why, and the decision's cost as its equivalent miss.",
  later      = "Where a decision's cost came later, say how the next quarters gained and why the later quarters lost, because the public's expectations or its trust moved.",
  no_marks   = "leave the list of decisions empty, since this term marks none.")

# Section 4.2.2: the fewest words the instruction asks for, of the text on the term and of a mark's text
debrief_words <- c(term = 120, mark = 60)

# Section 4.2.2: the term's record in words, every figure with its unit
record_sentences <- list(
  term           = "The term ran for {T} quarters. Your loss over the term equals an inflation miss of {player} points in every quarter, and the reference bank's an inflation miss of {bank} points.",
  rates          = "In quarter {q} you set the policy rate at {rate} percent, and the reference bank on its own path at {bank_rate} percent.",
  rates_guided   = "In quarter {q} the bank set the policy rate itself at {rate} percent, and the reference bank on its own path at {bank_rate} percent.",
  figures        = "Inflation was {inflation} percent a year against {bank_inflation} percent under the reference bank, the output gap {gap} percent against {bank_gap} percent, and unemployment {unemployment} percent against {bank_unemployment} percent.",
  reading        = "The public read your rate as {reading}.",
  reading_guided = "The public read the rate as {reading}.",
  aim            = "The public's view of our aim stood {aim}, against {bank_aim}.",
  trust          = "Trust in our announcements stood at {trust} percent, against {bank_trust} percent.",
  path           = "After the quarter your announced path read {path}.",
  spending       = "Government spending stood {spending}, against {bank_spending}.",
  poll           = "{poll} percent of voters supported the party in office, against {bank_poll} percent.",
  vote_same      = "The election of this quarter went to {party}, as it did under the reference bank.",
  vote_other     = "The election of this quarter went to {party}, and under the reference bank to {bank_party}.",
  shock          = "In quarter {q} {words}, {kind} {source} reported {how}.",
  slump          = "In quarter {q} {slump} began that was foreseen to last {n} quarters.",
  vote           = "In quarter {q} an election took place.",
  mark           = "In quarter {q} you set {rate} percent, where the reference bank would have set {bank_rate} percent in your place. Its cost came at once and equals an inflation miss of {miss} points in that quarter.",
  mark_later     = "In quarter {q} you set {rate} percent, where the reference bank would have set {bank_rate} percent in your place. Its cost came later: the quarters after it gained, and {quarters} lost. The cost equals an inflation miss of {miss} points in that quarter.")

# Section 4.2.2: how the public read a rate, by its distance from the rate it expected
record_readings <- c(as = "about what it expected", higher = "higher than it expected", lower = "lower than it expected",
                     clearly_higher = "clearly higher than it expected", clearly_lower = "clearly lower than it expected")

# Section 4.2.2: a distance from a normal level in the record
record_levels <- list(aim = c(off = "{points} points {side} the target", on = "at the target"),
                      spending = c(off = "{percent} percent {side} its normal level", on = "at its normal level"))

# Section 4.2.2: a new shock in the record, its words in the past and its kind
record_shocks <- list(
  words = list(
    demand     = c(positive = "households and firms spent {size} more than usual", negative = "households and firms spent {size} less than usual"),
    technology = c(positive = "firms could produce {size} more with the same work", negative = "firms could produce {size} less with the same work"),
    costs      = c(positive = "firms' costs rose {size}", negative = "firms' costs fell {size}"),
    purchases  = c(positive = "the government spent {size} more than usual", negative = "the government spent {size} less than usual")),
  sizes = list(demand = c(small = "slightly", notable = "clearly", large = "far"),
               technology = c(small = "slightly", notable = "clearly", large = "much"),
               costs = c(small = "slightly", notable = "clearly", large = "sharply"),
               purchases = c(small = "slightly", notable = "clearly", large = "far")),
  kinds = c(demand = "a demand shock", technology = "a productivity shock", costs = "a cost-push shock", purchases = "a change in government spending"),
  sources = c(newspaper = "the newspaper", briefing = "your briefing"),
  how = c(exact = "exactly", words = "in words"))

# Section 4.2.2: the debrief without a model, the losses as equivalent misses
debrief_fallback_texts <- list(
  term_at_most = "Over the term your decisions cost as much as an inflation miss of {equivalent} points held in every quarter would have, against {bank_equivalent} points for a reference bank that had the same information and the same mandate, so your term loss is at most the bank's. The reference bank moves its policy rate gradually, since it counts a change of the rate as a cost, and a governor who moves faster can end a term with a lower loss.",
  term         = "Over the term your decisions cost as much as an inflation miss of {equivalent} points held in every quarter would have, against {bank_equivalent} points for a reference bank that had the same information and the same mandate.",
  mark         = "In quarter {q} you set the policy rate at {player_rate} percent where the reference bank would have set {bank_rate}. Over the term that decision cost as much as an inflation miss of {equivalent} points in that quarter, {kind_words}.",
  kinds        = c(immediate = "most of it within the next two quarters", deferred = "with a gain at first and a larger loss later"))
