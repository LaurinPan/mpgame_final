# 02_Game/content/glossary.R — v6 §8.2: the glossary, one explanation per term

# v6 §8.2: each term with its explanation, without figures, the phrases by which a call's texts are found to use it, and whether it is an everyday term, which the newspaper's readers are not given
glossary <- read.table(header = TRUE, sep = "|", strip.white = TRUE, quote = "", comment.char = "",
                       stringsAsFactors = FALSE, text = "
term | explanation | found_as | everyday
central bank | the institution that sets the policy rate to keep prices stable | central bank | TRUE
policy rate | the short-term interest rate the central bank sets each quarter | policy rate | TRUE
the floor | the policy rate cannot be set below zero | the floor; at zero; below zero | FALSE
real interest rate | the policy rate minus the inflation people expect | real interest rate | FALSE
the rate the economy needs | the real interest rate at which spending neither grows nor shrinks, so that output stays at its potential; economists call it the natural rate of interest, never the natural rate alone | rate the economy needs | FALSE
output | everything the economy produces in a quarter | output | TRUE
potential output | the output the economy produces when prices and wages have fully adjusted, growing along its trend | potential output; potential | FALSE
trend | the path along which output grows over time | trend | TRUE
output gap | the difference between output and its potential, in percent | output gap | FALSE
recession | output falls for two quarters in a row | recession | TRUE
inflation | how fast prices rise, in percent a year | inflation | TRUE
inflation target | the inflation rate the central bank aims at | inflation target; target | TRUE
wage inflation | how fast wages rise, in percent a year | wage inflation | TRUE
real wage | wages measured by what they can buy | real wage | FALSE
unemployment rate | the share of people who want to work but have no job | unemployment rate; unemployment | TRUE
natural rate of unemployment | the unemployment rate the economy settles at once wages have adjusted | natural rate of unemployment; natural rate | FALSE
expected inflation | the inflation the public expects for the coming quarter | expected inflation; expects inflation; expect inflation | FALSE
new shock | a sudden change in spending, firms' costs, productivity or government spending that arrives this quarter | new shock | FALSE
demand shock | a change in how much households and firms want to spend that does not come from the policy rate | demand shock | FALSE
cost-push shock | a change in firms' costs, for example for energy, that firms pass on to their prices | cost-push shock | FALSE
productivity shock | a change in how much firms can produce with the same work | productivity shock | FALSE
mandate | the task the central bank is given: inflation close to the target and output close to its potential | mandate | FALSE
loss | how far a term missed the mandate, stated as the inflation miss that would have cost as much in every quarter | loss; losses | FALSE
the public's view of the aim | the inflation rate the public believes the central bank is aiming at, read from the policy rates it sets | view of the aim; view of our aim; view of the central bank's aim; aims at; aiming at | FALSE
announcement | the policy rates the central bank says it will set in the coming quarters | announcement; announced; announce | FALSE
band | the range around an announced rate within which a set rate still counts as keeping the announcement | band | FALSE
record | the list of announced quarters and whether each announcement was kept | record | FALSE
trust | how far the public believes the central bank's announcements | trust | FALSE
staff forecast | the bank's own forecast of this quarter's figures at the rate and plan the governor is about to set | staff forecast | FALSE
government spending | what the government buys, compared with its normal level | government spending | TRUE
poll | the share of voters who support the party in office | poll | TRUE
reference bank | a central bank that decides each quarter on the information the governor had, for the same mandate, and moves its rate gradually | reference bank | FALSE
")
