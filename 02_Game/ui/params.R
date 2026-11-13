# ui/params.R — the UI's own geometry and constants. No
# figure of the economy is here: every such figure comes from the views.
ui_params <- list(
  # the economy's map: the canvas in the map's units, the boxes' designed places (their centres, by the box
  # id of content/map.R), the boxes' and nodes' sizes, the arrow keys' steps, a node's label's characters a line
  map = list(canvas = c(w = 1240, h = 660),
             places = list(central_bank = c(210, 100), households = c(620, 92), firms = c(1030, 120), general_public = c(210, 390),
                           outcomes = c(620, 380), government = c(1030, 410)),
             box = list(w = 220, h = 60, mark_line = 15, part_w = 176, part_h = 36, gap = 12, head = 32, pad = 14),
             step = c(small = 8, large = 40), wrap = 27L, mark_wrap = 34L),
  # the newspaper's geometry: a spread of two pages, the rows the layout counts, the slots' heights on pages 2 to 4
  paper = list(grid = list(width = 660L, height = 760L, pad_top = 22L, pad_bottom = 26L, head = 40L, row = 20L, gap = 14L, chart = 150L, cont = 20L,
                           headline_line = 26L, after_headline = 4L, after_standfirst = 4L,
                           chars = list(headline = 44L, standfirst = 70L, body = 40L)),
               # page 1 as the browser draws it (measured on the recordings' 100 issues): the lead's body's top under the masthead and the
               # index (six lines, 247 px) when its head is not taller, the head's kicker and gaps, the body's frame, the chart in the right
               # column with its gap, the strip of figures, the template's note; characters a line never too many (headline, standfirst, body)
               lead = list(body_top = 345L, index = 247L, head = 32L, headline_line = 32L, standfirst_line = 21L, frame = 6L, chart = 167L,
                           strip = 12L, strip_line = 15L, note = 32L, chars = list(headline = 27L, standfirst = 51L, body = 41L, strip = 90L)),
               slot_rows = 16L,                              # a medium slot: 16 rows of 20 px (329 px with its gap)
               chart = list(W = 320L, H = 128L, height = 118L),
               squares = 8L),
  # the charts: the wide rate chart, the figure charts, the small ones, the margins, the tick gap
  chart = list(wide = c(W = 1200, H = 220), main = c(W = 600, H = 300), small = c(W = 480, H = 250), debrief = c(W = 960, H = 200),
               margin = list(L = 56, R = 28, top = 18, bottom = 30), tick_gap = 18, series_from = 2L),
  # the parties' colours by the party's number (the poll's line, the election clock's flag; the tokens --real and --policy)
  party_colours = c("#C4522A", "#5B4FC4"),
  decimals = list(pct_year = 2, rate = 2, pct = 2, persons = 2, bn = 0, loss = 2, poll = 1, purchases = 1),
  word = list(step = 0.05),                                  # the path's points snap to five hundredths when dragged
  runs = list(name_max = 40L, slots = 3L),
  login = list(wait = 2),
  llm = list(question_max = 600L),
  time_zone = "Europe/Zurich",
  menu = list(toc_variant = 2L),
  # the theory section's chapters by their titles, which the Menu's box "Related Theory" names for a topic's builds_on
  theory_titles = c(P1 = "Macroeconomics, actors and models", P2 = "Measuring output: GDP", P3 = "The goods market in the short run",
                    P4 = "Money, prices and interest", P5 = "Labour market, unemployment and the Phillips relation", P6 = "Growth and potential output"),
  # the next quarter's paper, the reference bank's steps and the term's end: in app.R's background worker, or,
  # with background FALSE, inside the close, the fallback for a server where mirai's worker does not run
  bank = list(background = TRUE))
