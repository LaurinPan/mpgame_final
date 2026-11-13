# 02_Game/content/classes.R — Section 4.2.2: size classes, class words, precision and thresholds

# Section 4.2.2: the classes with their bounds and values, their words, the probability of exact figures and the thresholds
classes <- list(

  bounds = list(demand     = c(0.4, 1.2, 2.0),
                technology = c(0.5, 1.5, 2.5),
                costs      = c(0.5, 1.5, 2.5),
                purchases  = c(4, 12, 20),
                slump      = c(3, 6, Inf)),

  values = list(demand     = c(0.2, 0.8, 1.6),
                technology = c(0.25, 1.0, 2.0),
                costs      = c(0.25, 1.0, 2.0),
                purchases  = c(2, 8, 16)),

  names = c("small", "notable", "large"),

  words = list(
    demand = list(
      positive = c(small   = "households and firms spend slightly more than usual",
                   notable = "households and firms spend clearly more than usual",
                   large   = "households and firms spend far more than usual"),
      negative = c(small   = "households and firms spend slightly less than usual",
                   notable = "households and firms spend clearly less than usual",
                   large   = "households and firms spend far less than usual")),
    technology = list(
      positive = c(small   = "firms can produce slightly more with the same work",
                   notable = "firms can produce clearly more with the same work",
                   large   = "firms can produce much more with the same work"),
      negative = c(small   = "firms can produce slightly less with the same work",
                   notable = "firms can produce clearly less with the same work",
                   large   = "firms can produce much less with the same work")),
    costs = list(
      positive = c(small   = "firms' costs have risen slightly",
                   notable = "firms' costs have risen clearly",
                   large   = "firms' costs have risen sharply"),
      negative = c(small   = "firms' costs have fallen slightly",
                   notable = "firms' costs have fallen clearly",
                   large   = "firms' costs have fallen sharply")),
    purchases = list(
      positive = c(small   = "the government spends slightly more than usual",
                   notable = "the government spends clearly more than usual",
                   large   = "the government spends far more than usual"),
      negative = c(small   = "the government spends slightly less than usual",
                   notable = "the government spends clearly less than usual",
                   large   = "the government spends far less than usual")),
    slump = c(small = "a mild slump", notable = "a marked slump", large = "a deep slump")),

  driver_words = c(technology = "the change in productivity",
                   demand     = "the change in households' and firms' spending",
                   costs      = "the change in firms' costs",
                   purchases  = "the change in government spending",
                   slump      = "the foreseen slump",
                   rate_up    = "the rise in the policy rate",
                   rate_down  = "the cut in the policy rate",
                   mixed      = "several causes together",
                   none       = "no single cause"),

  p_exact = 0.4,

  nu_bar   = 2.0,
  sigma_nu = 1.0,
  sigma_g  = 5,

  thresholds = list(
    pressing           = c(inflation = 0.5, unemployment = 0.5, growth = 1.0, wages = 1.0),
    marked             = 2,
    drivers_half       = 0.5,
    recession_quarters = 2,
    mark_share         = 0.10,
    mark_min           = 0.5,
    marks_max          = 3,
    immediate_within   = 2,
    m_aim              = 0.25,
    g_spending         = 4,
    scale_steps        = 1:3,
    change_share       = 0.5,
    trust_levels       = c(60, 80),
    trust_steady       = 0.5,
    reading            = c(0.25, 1)))
