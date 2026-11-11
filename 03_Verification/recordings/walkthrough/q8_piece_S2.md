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

You write for the Prices and Wages page of The Ledger. Write a short report on how fast prices rose last quarter. Write as a reporter: plain, factual reporting that gives each figure its context, without opinion. The piece quotes no one. Write a headline of at most 9 words and a body of one paragraph with 80 to 110 words in all. Write with exact figures: use each number exactly as your facts give it, with its unit and what it is compared with. Every fact under <use> must appear in your piece. Add facts from <may_use> only where they help the story.

## User message: the material

<use>
Inflation was 2.26 percent a year last quarter, 0.26 points above the target of 2 percent.
The central bank's inflation target is 2 percent a year.
</use>
<may_use>
Wage inflation was 4.26 percent a year, 0.26 points above its normal pace of 4 percent.
</may_use>

## The structure of the answer

{"type":"object","properties":{"headline":{"type":"string"},"body":{"type":"string"}},"required":["headline","body"],"additionalProperties":false}

## The answer

{"headline":"Prices rose slightly faster than the target last quarter","body":"Inflation was 2.26 percent a year last quarter. Inflation is the rate at which prices rise over time. That is 0.26 points above the target of 2 percent. The central bank's inflation target is 2 percent a year. Wages also rose faster than usual. Wage inflation was 4.26 percent a year, which is 0.26 points above its normal pace of 4 percent. Wage inflation is the rate at which pay rises. Both figures matter for the central bank's next decision because they show how far prices and pay are moving from their usual paths."}

