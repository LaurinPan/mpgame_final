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

The material comes in tags: <use> holds the facts your piece must contain, <may_use> facts you may add where they help the story, <terms> the explanations of terms, and <other_pages> the stories of the issue's other pages. The tags only sort the material, so never write their names. Return one JSON object in the structure given, and nothing else.

## System block 2: the instruction

You write the lead on the front page of The Ledger. Write the lead on a calm quarter: inflation, growth and unemployment all stand close to their normal levels. Say so plainly, and tell readers what such a quarter means for them. Write as a reporter: plain, factual reporting that gives each figure its context, without opinion. The piece quotes no one. Write a headline of at most 10 words, a standfirst of one sentence and at most 25 words, and a body of three paragraphs with 150 to 190 words in all. Write in plain words, without figures: describe every size and direction in the words your facts use, and use a number only for a count of quarters or where your facts give one. Every fact under <use> must appear in your piece. The issue's other pages carry the stories under <other_pages>. Leave those stories to them, and do not point to them.

## User message: the material

<use>
Inflation stood close to the target last quarter.
The central bank's inflation target is 2 percent a year.
Growth stood close to its trend last quarter.
Along its trend, output grows by 2 percent a year.
Unemployment stood close to its natural rate last quarter.
The natural rate of unemployment is 5 percent.
</use>
<terms>
natural rate of unemployment: the unemployment rate the economy settles at once wages have adjusted
</terms>
<other_pages>
The Economy: Economy grows slightly slower than its usual pace
Prices and Wages: Prices rose slightly faster than the target last quarter
Jobs: Unemployment Edges Above Its Natural Rate of 5 Percent
Markets and the Bank: "The bank did what it said it would"
Analysis: A Quiet Quarter That Leaves Many Feeling Unheard
</other_pages>

## The structure of the answer

{"type":"object","properties":{"headline":{"type":"string"},"standfirst":{"type":"string"},"body":{"type":"object","properties":{"paragraph_1":{"type":"string"},"paragraph_2":{"type":"string"},"paragraph_3":{"type":"string"}},"required":["paragraph_1","paragraph_2","paragraph_3"],"additionalProperties":false}},"required":["headline","standfirst","body"],"additionalProperties":false}

## The answer

{"headline":"A calm quarter: prices, growth and jobs near normal","standfirst":"Inflation, growth and unemployment all stood close to their normal levels last quarter, so the economy showed no strain in any of the three.","body":{"paragraph_1":"Last quarter was a calm one for the economy. Inflation stood close to the target. The central bank's inflation target is 2 percent a year. Prices therefore rose at about the pace the bank aims for.","paragraph_2":"Growth also stood close to its trend last quarter. Along its trend, output grows by 2 percent a year. Unemployment stood close to its natural rate too. The natural rate of unemployment is 5 percent. That is the unemployment rate the economy settles at once wages have adjusted.","paragraph_3":"For households and firms, a calm quarter means few surprises. Prices are not climbing faster than planned, so budgets hold steady. Output is growing at its usual pace, so firms can plan with some confidence. Jobs are neither unusually scarce nor unusually easy to find, so workers face ordinary conditions. For the central bank, all three readings near normal levels matter as it looks toward its next decision."}}

