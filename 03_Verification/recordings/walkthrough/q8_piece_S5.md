# Call 1 of 2

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

You write for the Analysis page of The Ledger. Write an analysis of a quiet quarter: why inflation, growth and unemployment all stand close to their normal levels. Write as a critic who voices the public's discontent with how the economy is going. Do not recommend a rate, a direction or a decision. The piece is a comment by a commentator for The Ledger. Write a headline of at most 9 words and a comment of three paragraphs with 240 to 320 words in all. Write in plain words, without figures: describe every size and direction in the words your facts use, and use a number only for a count of quarters or where your facts give one. Every fact under <use> must appear in your piece. Add facts from <may_use> only where they help the story.

## User message: the material

<use>
Inflation, growth, wage inflation and unemployment all stand close to their normal levels.
Inflation stood close to the target last quarter.
The central bank's inflation target is 2 percent a year.
Growth stood close to its trend last quarter.
Along its trend, output grows by 2 percent a year.
Unemployment stood close to its natural rate last quarter.
The natural rate of unemployment is 5 percent.
No single cause stands out behind last quarter's change in output.
No single cause stands out behind last quarter's change in inflation.
</use>
<may_use>
The public expects inflation close to the target for the coming quarter.
</may_use>
<terms>
natural rate of unemployment: the unemployment rate the economy settles at once wages have adjusted
expected inflation: the inflation the public expects for the coming quarter
</terms>

## The structure of the answer

{"type":"object","properties":{"headline":{"type":"string"},"body":{"type":"object","properties":{"paragraph_1":{"type":"string"},"paragraph_2":{"type":"string"},"paragraph_3":{"type":"string"}},"required":["paragraph_1","paragraph_2","paragraph_3"],"additionalProperties":false}},"required":["headline","body"],"additionalProperties":false}

## The answer

{"headline":"A quiet quarter that leaves many people cold","body":{"paragraph_1":"Last quarter, the economy did nothing dramatic. Inflation, growth, wage inflation and unemployment all stand close to their normal levels. Inflation stood close to the target. The central bank's inflation target is 2 percent a year. Many households will say that calm on paper does not match what they feel when they pay their bills.","paragraph_2":"Growth stood close to its trend last quarter. Along its trend, output grows by 2 percent a year. Unemployment stood close to its natural rate, which is the unemployment rate the economy settles at once wages have adjusted. The natural rate of unemployment is 5 percent. So by the usual yardsticks, nothing is out of place. Yet people want more than a result that is merely normal, and they are right to say so.","paragraph_3":"Why was the quarter so quiet? No single cause stands out behind last quarter's change in output. No single cause stands out behind last quarter's change in inflation. So the calm cannot be credited to any one policy or event. The public also expects inflation close to the target for the coming quarter. That matters for the central bank's next decision, because calm expectations make the picture steadier. But a steady picture is not yet a good one for those who feel left behind."}}

# Call 2 of 2

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

You write for the Analysis page of The Ledger. Write an analysis of a quiet quarter: why inflation, growth and unemployment all stand close to their normal levels. Write as a critic who voices the public's discontent with how the economy is going. Do not recommend a rate, a direction or a decision. The piece is a comment by a commentator for The Ledger. Write a headline of at most 9 words and a comment of three paragraphs with 240 to 320 words in all. Write in plain words, without figures: describe every size and direction in the words your facts use, and use a number only for a count of quarters or where your facts give one. Every fact under <use> must appear in your piece. Add facts from <may_use> only where they help the story.

## User message: the material

<use>
Inflation, growth, wage inflation and unemployment all stand close to their normal levels.
Inflation stood close to the target last quarter.
The central bank's inflation target is 2 percent a year.
Growth stood close to its trend last quarter.
Along its trend, output grows by 2 percent a year.
Unemployment stood close to its natural rate last quarter.
The natural rate of unemployment is 5 percent.
No single cause stands out behind last quarter's change in output.
No single cause stands out behind last quarter's change in inflation.
</use>
<may_use>
The public expects inflation close to the target for the coming quarter.
</may_use>
<terms>
natural rate of unemployment: the unemployment rate the economy settles at once wages have adjusted
expected inflation: the inflation the public expects for the coming quarter
</terms>
Your previous answer's body had 213 words, and 240 to 320 are asked for. Write the piece again from the same facts.

## The structure of the answer

{"type":"object","properties":{"headline":{"type":"string"},"body":{"type":"object","properties":{"paragraph_1":{"type":"string"},"paragraph_2":{"type":"string"},"paragraph_3":{"type":"string"}},"required":["paragraph_1","paragraph_2","paragraph_3"],"additionalProperties":false}},"required":["headline","body"],"additionalProperties":false}

## The answer

{"headline":"A Quiet Quarter That Leaves Many Feeling Unheard","body":{"paragraph_1":"Last quarter, the economy did almost nothing unusual. Inflation, growth, wage inflation and unemployment all stand close to their normal levels. Inflation stood close to the target, and the central bank's inflation target is 2 percent a year. Growth stood close to its trend, and along its trend, output grows by 2 percent a year. Officials may call this a success. Many households do not feel it as one, because a calm table of statistics says little about how a month at the shop or the rent office feels.","paragraph_2":"Unemployment tells the same story. It stood close to its natural rate last quarter. The natural rate of unemployment is the unemployment rate the economy settles at once wages have adjusted. That rate is 5 percent. So the job market is neither tight nor slack by the usual measure. Yet people who are out of work, or who fear for their jobs, do not take comfort from an average. The public has every right to ask why a normal quarter still feels hard, and the headline numbers offer no answer to that.","paragraph_3":"Nor does the quarter explain itself. No single cause stands out behind last quarter's change in output. No single cause stands out behind last quarter's change in inflation. That matters because a calm result with no clear cause is hard to trust, so readers are right to stay wary. The public also expects inflation close to the target for the coming quarter. The central bank will weigh that expectation, and it is a fair question whether expected inflation, the inflation the public expects for the coming quarter, will hold steady. For now the economy looks quiet, but quiet is not the same as good, and many people feel the difference."}}

