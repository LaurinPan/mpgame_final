# 02_Game/content/newspaper/instruction.R — v6 §12: the sentences a piece's instruction is composed from

# v6 §12.1: the page a piece is written for
page_sentences <- c(piece = "You write for the {section} page of The Ledger.",
                    lead  = "You write the lead on the front page of The Ledger.")

# v6 §12.6: the voice of each tone
voices <- c(
  reporter  = "Write as a reporter: plain, factual reporting that gives each figure its context, without opinion.",
  critic    = "Write as a critic who voices the public's discontent with how the economy is going. Do not recommend a rate, a direction or a decision.",
  business  = "Write from the side of firms: their costs, orders and hiring, as firms describe them. Invent no figures for them.",
  household = "Write from the side of households: prices, wages and jobs, as people feel them at home. Invent no figures for them.",
  markets   = "Write as a markets reporter: the policy rate, the central bank's announcements and how long the rate stays at zero, as traders read them.",
  economist = "Write as an economist who explains why things moved, and which figures and coming events matter for the central bank's next decision. Do not recommend a rate, a direction or a decision.")

# v6 §12.4: who speaks in each format, the roles a voices piece draws from and the author line of a comment
speakers <- list(
  roles  = c("a shop owner", "a factory manager", "a nurse", "a retired teacher", "a young engineer looking for work", "a farmer"),
  author = "a commentator for The Ledger",
  sentences = c("F-INTERVIEW" = "The piece is an interview with an economist at the Institute for Economic Research.",
                "F-VOICES"    = "The piece quotes these people, one quotation each: {roles}.",
                "F-COMMENT"   = "The piece is a comment by a commentator for The Ledger.",
                "F-MARKETS"   = "The piece may quote a bond trader once.",
                other         = "The piece quotes no one."))

# v6 §5.3: the precision of a piece
precision_sentences <- c(
  exact = "Write with exact figures: use each number exactly as your facts give it, with its unit and what it is compared with.",
  words = "Write in plain words, without figures: describe every size and direction in the words your facts use, and use a number only for a count of quarters or where your facts give one.")

# v6 §12.7: how a piece uses its facts, and what the lead does with the issue's other pages
facts_sentences <- c(
  use         = "Every fact under <use> must appear in your piece.",
  use_may     = "Every fact under <use> must appear in your piece. Add facts from <may_use> only where they help the story.",
  other_pages = "The issue's other pages carry the stories under <other_pages>. Leave those stories to them, and do not point to them.")

# v6 §12.7: the end of the list of tags in the newspaper's fixed part, for a piece and for the lead
lead_tags <- c(piece = "and <terms> the explanations of terms.",
               lead  = "<terms> the explanations of terms, and <other_pages> the stories of the issue's other pages.")

# v6 §12.7: the sentence a failed answer is asked for again with, by the check it failed
retry_sentences <- c(
  paragraphs = "Your previous answer had {k} in its body, and the piece asks for exactly {n}. Write the piece again from the same facts.",
  headline   = "Your previous answer's headline had {k} words, and at most {h} are allowed. Write the piece again from the same facts.",
  body       = "Your previous answer's body had {k} words, and {lo} to {hi} are asked for. Write the piece again from the same facts.",
  structure  = "Your previous answer did not follow the structure given. Write the piece again from the same facts.")
