# 02_Game/bank/fair_quarter.R — A.8 "What the Bank Knows" and Section 4.2.2: the fair quarter, each shock at the size the issue reported

# A.8, "What the Bank Knows", and Section 4.2.2: the quarter object with each shock at its reported size, exact or its class value, and a vote's draw at 0.5, which the bank never sees
fair_quarter <- function(run, q, state = run$states[[q]], shocks = run$sheets[[q]]$shocks) {
  if (is.null(shocks)) stop("quarter ", q, " has no sheet yet: the fair quarter needs the issue's Shocks block")
  cols <- c(technology = "a", demand = "z", costs = "nu", purchases = "g")
  inn  <- list(a = 0, z = 0, nu = 0, g = 0)
  for (ty in names(shocks$shocks)) {
    s <- shocks$shocks[[ty]]
    inn[[cols[[ty]]]] <- if (identical(s$reported, "exact")) s$size
                         else sign(s$size) * classes$values[[ty]][match(s$class, classes$names)]
  }
  inn$draw <- 0.5
  if (isTRUE(run$foreseen$start == q)) inn$d_path <- run$foreseen$d
  begin_quarter(run$config, state, inn)
}
