# Call 1 of 1

## System block 1: the fixed part

You write one piece for The Ledger, a quality newspaper in a fictional country. The Ledger explains the economy to its readers: its reporters explain terms, its experts give reasons, and the people it quotes speak in everyday words. The country, its central bank and the people in it are fictional, and the people in a piece speak by their role, never by name.

The rules of every piece:
1. Write only from the facts you are given. Add no fact, figure or event they do not contain, and never say that something is missing.
2. Every number appears exactly as the facts give it, with its unit and what it is compared with. Never compute a number of your own.
3. The first time a term listed under the terms appears in your piece, explain it in a short clause, in the words given there.
4. Write about the economy for your readers, never about the newspaper itself.
5. You may say what matters for the central bank's next decision, but never what it should do: no rate, no direction and no decision.
6. Write plainly: one idea per sentence, about 25 words at most, with cause and effect linked by "because" or "so", and with no abbreviations or symbols.
7. Keep every element within its word limit.

The material comes in tags: <use> holds the facts your piece must contain, <may_use> facts you may add where they help the story, and <terms> the explanations of terms. The tags only sort the material, so never write their names. Return one JSON object in the structure given, and nothing else.

## System block 2: the instruction

You write for the Markets and the Bank page of The Ledger. Write about whether the central bank kept its word this quarter: the policy rate it had announced, the rate it set, and whether the announcement counts as kept or broken. Write as an economist who explains why things moved, and which figures and coming events matter for the central bank's next decision. Do not recommend a rate, a direction or a decision. The piece is an interview with an economist at the Institute for Economic Research. Write a headline of at most 8 words that quotes one of the economist's answers, one sentence that introduces the economist by role, and 4 questions of at most 15 words, each followed by the economist's answer of at most 40 words. Write in plain words, without figures: describe every size and direction in the words your facts use, and use a number only for a count of quarters or where your facts give one. Every fact under <use> must appear in your piece. Add facts from <may_use> only where they help the story.

## User message: the material

<use>
The central bank set the policy rate where it had announced it would, so the announcement counts as kept.
</use>
<may_use>
Trust in the central bank's announcements is high and rising.
No new shock arrived this quarter, so none gave the central bank room to change its announced plan.
</may_use>
<terms>
new shock: a sudden change in spending, firms' costs, productivity or government spending that arrives this quarter
announcement: the policy rates the central bank says it will set in the coming quarters
trust: how far the public believes the central bank's announcements
</terms>

## The structure of the answer

{"type":"object","properties":{"headline":{"type":"string"},"intro":{"type":"string"},"qa":{"type":"object","properties":{"exchange_1":{"type":"object","properties":{"question":{"type":"string"},"answer":{"type":"string"}},"required":["question","answer"],"additionalProperties":false},"exchange_2":{"type":"object","properties":{"question":{"type":"string"},"answer":{"type":"string"}},"required":["question","answer"],"additionalProperties":false},"exchange_3":{"type":"object","properties":{"question":{"type":"string"},"answer":{"type":"string"}},"required":["question","answer"],"additionalProperties":false},"exchange_4":{"type":"object","properties":{"question":{"type":"string"},"answer":{"type":"string"}},"required":["question","answer"],"additionalProperties":false}},"required":["exchange_1","exchange_2","exchange_3","exchange_4"],"additionalProperties":false}},"required":["headline","intro","qa"],"additionalProperties":false}

## The answer

{"headline":"\"The bank did what it said it would\"","intro":"The Ledger spoke with an economist at the Institute for Economic Research about whether the central bank kept its word this quarter.","qa":{"exchange_1":{"question":"Did the central bank keep its word this quarter?","answer":"Yes. The central bank set the policy rate where it had announced it would, so the announcement counts as kept. The announcement is the policy rates the bank says it will set in the coming quarters."}, "exchange_2":{"question":"Why did the bank stay on its announced path?","answer":"No new shock arrived this quarter, so nothing gave the bank room to change its plan. A new shock is a sudden change in spending, firms' costs, productivity or government spending that arrives this quarter."},"exchange_3":{"question":"What does keeping its word mean for trust?","answer":"Trust is high and rising. Trust is how far the public believes the central bank's announcements. Each kept announcement gives people more reason to believe the next one, so it matters for the bank."},"exchange_4":{"question":"What should we watch for the bank's next decision?","answer":"Watch whether a new shock arrives, because without one the bank has no room to change its announced plan. Also watch trust, because it is high and rising and that shapes how people read the bank."}}}

