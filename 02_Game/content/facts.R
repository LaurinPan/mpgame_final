# 02_Game/content/facts.R — v6 §2.4: every field of the fact sheet as one sentence, with exact figures and in plain words

# v6 §5.4: the words of the plain-words scale, from within normal to beyond the second class
scale_words <- list(
  above = c("close to", "slightly above", "clearly above", "far above"),
  below = c("close to", "slightly below", "clearly below", "far below"),
  rose  = c("was almost unchanged", "rose slightly", "rose clearly", "rose sharply"),
  fell  = c("was almost unchanged", "fell slightly", "fell clearly", "fell sharply"),
  size  = c("slightly", "slightly", "clearly", "far"),
  pace  = c("slightly", "slightly", "clearly", "sharply"),
  trust = c("low", "moderate", "high"),
  direction = c(rising = "rising", falling = "falling", steady = "steady"))

# v6 §5.4: what moved a figure most, as the subject of its sentence
cause_words <- c(demand = "Spending by households and firms", technology = "Firms' productivity", costs = "Firms' costs",
                 purchases = "Government spending", slump = "The foreseen slump",
                 rate_up = "The rise in the policy rate", rate_down = "The cut in the policy rate")

# v6 §2.4: each fact with the sheet fields it words, the law's constant it compares with, and its sentence by case;
# `exact` with figures, `words` in plain words, `both` where the sentence is the same; {braces} are filled by the game
facts <- list(

  population = list(fields = "figures.population",
    exact = "The country has {population} million inhabitants."),

  labour_force = list(fields = "figures.labour_force",
    exact = "The labour force, everyone who works or looks for work, counts {labour_force} million people."),

  inflation = list(fields = c("figures.inflation", "figures.inflation_gap"), compares = "target",
    exact = c(off = "Inflation was {inflation} percent a year last quarter, {gap} points {side} the target of {target} percent.",
              on  = "Inflation was {inflation} percent a year last quarter, on the target of {target} percent."),
    words = "Inflation stood {distance} the target last quarter."),

  inflation_change = list(fields = "figures.inflation_change",
    exact = c(rose = "Inflation rose by {change} points since the quarter before.",
              fell = "Inflation fell by {change} points since the quarter before.",
              unchanged = "Inflation was unchanged since the quarter before."),
    words = "Inflation {moved} since the quarter before."),

  inflation_before = list(fields = "figures.inflation_before", compares = "target",
    exact = "The quarter before, inflation was {inflation} percent a year.",
    words = "The quarter before, inflation stood {distance} the target."),

  wage_inflation = list(fields = c("figures.wage_inflation", "figures.wage_gap"), compares = "wage_normal",
    exact = c(off = "Wage inflation was {wage_inflation} percent a year, {gap} points {side} its normal pace of {wage_normal} percent.",
              on  = "Wage inflation was {wage_inflation} percent a year, at its normal pace of {wage_normal} percent."),
    words = "Wage inflation stood {distance} its normal pace last quarter."),

  wage_real = list(fields = "figures.wage_real",
    exact = c(faster = "Wages rose {gap} points faster than prices last quarter.",
              slower = "Wages rose {gap} points more slowly than prices last quarter.",
              same   = "Wages rose as fast as prices last quarter."),
    words = c(faster = "Wages rose faster than prices last quarter.",
              slower = "Wages rose more slowly than prices last quarter.",
              same   = "Wages rose about as fast as prices last quarter.")),

  growth = list(fields = c("figures.growth", "figures.growth_gap"), compares = "trend_growth",
    exact = c(off    = "Output grew by {growth} percent a year, {gap} points {side} its trend of {trend} percent a year.",
              on     = "Output grew by {growth} percent a year, on its trend of {trend} percent a year.",
              shrank = "Output shrank by {growth} percent a year, {gap} points below its trend of {trend} percent a year."),
    words = c(off    = "Growth stood {distance} its trend last quarter.",
              shrank = "Output shrank last quarter, so growth stood {distance} its trend.")),

  output = list(fields = c("figures.output_level", "figures.output_trend"),
    exact = "Output was {level} billion dollars a year, against a trend of {trend_level} billion dollars."),

  output_fell = list(fields = c("figures.output_fell", "figures.recession"),
    both = c(fell      = "Output fell last quarter.",
             recession = "Output has fallen for two quarters in a row, so the economy is in recession.")),

  unemployment = list(fields = c("figures.unemployment", "figures.unemployment_gap"), compares = "natural_unemployment",
    exact = c(off = "Unemployment was {unemployment} percent, {gap} points {side} its natural rate of {natural} percent.",
              on  = "Unemployment was {unemployment} percent, at its natural rate of {natural} percent."),
    words = "Unemployment stood {distance} its natural rate last quarter."),

  persons = list(fields = "figures.unemployed_persons",
    exact = "About {persons} people were out of work.",
    words = c(more = "{Size} more people than usual were out of work.",
              fewer = "{Size} fewer people than usual were out of work.",
              same = "About as many people as usual were out of work.")),

  quarters_above = list(fields = "figures.quarters_above_natural",
    both = c(many = "Unemployment has stood above its natural rate for {n} quarters in a row.",
             one  = "Unemployment has stood above its natural rate for 1 quarter.")),

  rate = list(fields = "figures.rate",
    exact = c(moved     = "The central bank set the policy rate at {rate} percent, {change} points {side} than the quarter before.",
              unchanged = "The central bank set the policy rate at {rate} percent, unchanged from the quarter before."),
    words = c(raised    = "The central bank raised the policy rate {pace} last quarter.",
              lowered   = "The central bank lowered the policy rate {pace} last quarter.",
              still     = "The central bank left the policy rate almost unchanged last quarter.",
              unchanged = "The central bank left the policy rate unchanged last quarter.")),

  target = list(fields = "law.target",
    both = "The central bank's inflation target is {target} percent a year."),

  trend_growth = list(fields = "law.trend_growth",
    both = "Along its trend, output grows by {trend} percent a year."),

  natural_unemployment = list(fields = "law.natural_unemployment",
    both = "The natural rate of unemployment is {natural} percent."),

  wage_normal = list(fields = "law.wage_normal",
    both = "The normal pace of wage inflation is {wage_normal} percent a year."),

  floor = list(fields = "law.floor",
    both = "The policy rate cannot be set below zero."),

  cap = list(fields = "law.cap",
    both = "The policy rate cannot be set above {cap} percent."),

  reach = list(fields = "law.H",
    both = "An announcement can name the policy rates of up to {H} quarters ahead."),

  election_interval = list(fields = "law.election_interval",
    both = "An election takes place every {interval} quarters."),

  expected_inflation = list(fields = "public.expected_inflation", compares = "target",
    exact = "The public expects inflation of {expected} percent a year for the coming quarter.",
    words = "The public expects inflation {distance} the target for the coming quarter."),

  aim = list(fields = "public.perceived_aim", compares = "target",
    exact = c(off = "The public believes the central bank aims at inflation of {aim} percent a year, {gap} points {side} the target.",
              on  = "The public believes the central bank aims at inflation of {aim} percent a year, which is the target."),
    words = "The public believes the central bank aims at inflation {distance} the target."),

  aim_change = list(fields = "public.aim_change",
    exact = c(rose = "The public's view of the central bank's aim rose by {change} points since the quarter before.",
              fell = "The public's view of the central bank's aim fell by {change} points since the quarter before.",
              unchanged = "The public's view of the central bank's aim was unchanged since the quarter before."),
    words = "The public's view of the central bank's aim {moved} since the quarter before."),

  trust = list(fields = c("public.trust", "public.trust_percent", "public.trust_change"),
    exact = "Trust in the central bank's announcements stands at {trust} percent.",
    words = "Trust in the central bank's announcements is {level} and {direction}."),

  spell = list(fields = "public.spell",
    both = c(many = "The public expects the policy rate to stay at zero for {n} more quarters.",
             one  = "The public expects the policy rate to stay at zero for 1 more quarter.")),

  judgement = list(fields = c("word.announced", "word.kept", "word.departure", "word.judged"),
    exact = c(as_announced = "The central bank had announced a policy rate of {announced} percent for last quarter and set {set} percent, as announced, so the announcement counts as kept.",
              kept_band    = "The central bank had announced a policy rate of {announced} percent for last quarter and set {set} percent, within the band around its announcement, so the announcement counts as kept.",
              kept_room    = "The central bank had announced a policy rate of {announced} percent for last quarter and set {set} percent, a difference that last quarter's new shocks gave room for, so the announcement counts as kept.",
              broken_rate  = "The central bank had announced a policy rate of {announced} percent for last quarter and set {set} percent, outside the band around its announcement, so the announcement counts as broken.",
              broken_plan  = "The central bank had announced a policy rate of {announced} percent for last quarter and set {set} percent, but it changed the rates it had announced for later quarters by more than the band allows, so the announcement counts as broken."),
    words = c(as_announced = "The central bank set the policy rate where it had announced it would, so the announcement counts as kept.",
              kept_band    = "The central bank set the policy rate {size} {side} the rate it had announced, within the band around its announcement, so the announcement counts as kept.",
              kept_room    = "The central bank set the policy rate {size} {side} the rate it had announced, a difference that last quarter's new shocks gave room for, so the announcement counts as kept.",
              broken_rate  = "The central bank set the policy rate {size} {side} the rate it had announced, outside the band around its announcement, so the announcement counts as broken.",
              broken_plan  = "The central bank set the policy rate within the band around its announcement, but it changed the rates it had announced for later quarters by more than the band allows, so the announcement counts as broken.")),

  room = list(fields = "word.room",
    exact = c(none = "No new shock arrived this quarter, so none gave the central bank room to change its announced plan.",
              flat = "This quarter's new shocks give the central bank no room to change its announced plan.",
              room = "This quarter's new shocks give the central bank room to set the policy rate up to {room} points {side} its announcement without breaking its word."),
    words = c(none = "No new shock arrived this quarter, so none gave the central bank room to change its announced plan.",
              flat = "This quarter's new shocks give the central bank no room to change its announced plan.",
              room = "This quarter's new shocks give the central bank room to set the policy rate {size} {side} its announcement without breaking its word.")),

  path = list(fields = c("word.path", "word.has_path"),
    exact = "The central bank has announced these policy rates: {path}.",
    words = c(many = "The central bank has announced its policy rates for {n} quarters, up to quarter {last}.",
              one  = "The central bank has announced its policy rate for this quarter only.")),

  shock_demand = list(fields = "shocks.demand",
    exact = c(positive = "This quarter, households and firms spend {size} percent more than usual.",
              negative = "This quarter, households and firms spend {size} percent less than usual."),
    words = "This quarter, {class_words}."),

  shock_technology = list(fields = "shocks.technology",
    exact = c(positive = "This quarter, firms can produce {size} percent more with the same work.",
              negative = "This quarter, firms can produce {size} percent less with the same work."),
    words = "This quarter, {class_words}."),

  shock_costs = list(fields = "shocks.costs",
    exact = c(positive = "This quarter, higher costs for firms push prices up by an extra {size} percent at an annual rate.",
              negative = "This quarter, lower costs for firms hold prices down by {size} percent at an annual rate."),
    words = "This quarter, {class_words}."),

  shock_purchases = list(fields = "shocks.purchases",
    exact = c(positive = "This quarter, the government spends {size} percent more than usual.",
              negative = "This quarter, the government spends {size} percent less than usual."),
    words = "This quarter, {class_words}."),

  no_shock = list(fields = "shocks",
    both = "No new shock arrived this quarter."),

  slump = list(fields = c("shocks.path_started", "shocks.path_class", "shocks.path_length"),
    both = c(begins  = "{Slump} begins this quarter, and it is foreseen to last {n} quarters.",
             running = "The foreseen slump lasts {n} quarters in all.")),

  vote_due = list(fields = "shocks.vote_due",
    both = "An election takes place at the end of this quarter."),

  spending = list(fields = c("government.purchases", "government.purchases_change"),
    exact = c(off_more = "Government spending is {purchases} percent {side} its normal level, {change} points more than the quarter before.",
              off_less = "Government spending is {purchases} percent {side} its normal level, {change} points less than the quarter before.",
              off_same = "Government spending is {purchases} percent {side} its normal level, unchanged from the quarter before.",
              at_more  = "Government spending is at its normal level, {change} points more than the quarter before.",
              at_less  = "Government spending is at its normal level, {change} points less than the quarter before.",
              at_same  = "Government spending is at its normal level, unchanged from the quarter before."),
    words = c(off = "Government spending is {distance} its normal level, and it {moved} since the quarter before.",
              at  = "Government spending is at its normal level, and it {moved} since the quarter before.")),

  office = list(fields = c("government.party", "government.poll"),
    exact = "{Party} is in office, and {poll} percent of voters support it.",
    words = c(more  = "{Party} is in office, and more than half of voters support it.",
              fewer = "{Party} is in office, and fewer than half of voters support it.",
              half  = "{Party} is in office, and half of voters support it.")),

  opposition = list(fields = "government.poll_opposition",
    exact = "{poll} percent of voters support the opposition.",
    words = c(more  = "More than half of voters support the opposition.",
              fewer = "Fewer than half of voters support the opposition.",
              half  = "Half of voters support the opposition.")),

  next_election = list(fields = "government.next_election",
    both = c(later = "The next election takes place in {n} quarters.",
             now   = "The next election takes place at the end of this quarter.")),

  vote_result = list(fields = c("government.vote_result", "government.vote_held"),
    exact = c(won       = "{Party} won the election with {share} percent of the vote.",
              reelected = "{Party} was re-elected with {share} percent of the vote."),
    words = c(won       = "{Party} won the election.",
              reelected = "{Party} was re-elected.")),

  last_vote = list(fields = "government.last_vote",
    exact = "The last election took place in quarter {q}, and {party} won it with {share} percent of the vote."),

  driver_output = list(fields = "drivers.output",
    both = c(one  = "{Cause} moved output most last quarter.",
             none = "No single cause stands out behind last quarter's change in output.")),

  driver_inflation = list(fields = "drivers.inflation",
    both = c(one  = "{Cause} moved inflation most last quarter.",
             none = "No single cause stands out behind last quarter's change in inflation.")),

  pressing = list(fields = c("pressing.variable", "pressing.direction", "pressing.severity"),
    both = c(one  = "{Figure} stands further from its normal than {others}.",
             none = "Inflation, growth, wage inflation and unemployment all stand close to their normal levels.")))
