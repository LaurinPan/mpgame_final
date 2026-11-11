# 05 Faithfulness

Recordings: `03_Verification/recordings`, T1, T2, T3, T4, T5, T6, T7, T8, each topic's final attempt; 811 calls, 0 of them died on the connection, and 0 were answered without an answer that could be read.

Every number in an answer is set against the request of its own call. TP: it stands in the call's material, equal to a number there at two decimals, the decimals the desk shows. FP: it does not; it then stands in the instruction or the fixed part, or nowhere in the request. FN: a figure under `<use>` that an exact-figures piece or lead does not write. TN and leaks: the hidden values of the quarter that the request does not hold, not written and written. A number the text calls quarters is counted apart. Each rate has its 95 percent Wilson interval in brackets.

## The answers the player reads

The last answer of every piece and lead, and every chat answer and debrief.

| Pipeline | Model | Answers | Numbers written | Counts of quarters | TP | FP | FN | TN | Leaks | Precision | Recall | F1 | Leak rate |
|--------------|----------|-------|-------|--------|-----|---|---|-----|-----|---------|---------|---------|---------|
| Newspaper, inside pieces, exact figures | claude-sonnet-5-5 | 271 | 1405 | 6 | 1398 | 1 | 1 | 1266 | 0 | 0.999 (0.996 to 1.000) | 0.999 (0.996 to 1.000) | 0.999 (0.996 to 1.000) | 0.000 (0.000 to 0.003) |
| Newspaper, inside pieces, plain words | claude-sonnet-5-5 | 229 | 163 | 20 | 143 | 0 | 0 | 1100 | 0 | 1.000 (0.974 to 1.000) | n/a | n/a | 0.000 (0.000 to 0.003) |
| Newspaper, the lead, exact figures | claude-sonnet-5-5 | 40 | 410 | 2 | 408 | 0 | 0 | 167 | 0 | 1.000 (0.991 to 1.000) | 1.000 (0.991 to 1.000) | 1.000 (0.991 to 1.000) | 0.000 (0.000 to 0.022) |
| Newspaper, the lead, plain words | claude-sonnet-5-5 | 60 | 128 | 4 | 124 | 0 | 0 | 281 | 0 | 1.000 (0.970 to 1.000) | n/a | n/a | 0.000 (0.000 to 0.013) |
| Newspaper, all | claude-sonnet-5-5 | 600 | 2106 | 32 | 2073 | 1 | 1 | 2814 | 0 | 1.000 (0.997 to 1.000) | 1.000 (0.997 to 1.000) | 1.000 (0.997 to 1.000) | 0.000 (0.000 to 0.001) |
| Chat | claude-sonnet-5-5 | 112 | 803 | 30 | 773 | 0 | 0 | 411 | 0 | 1.000 (0.995 to 1.000) | n/a | n/a | 0.000 (0.000 to 0.009) |
| Debrief | claude-sonnet-5-5 | 8 | 266 | 73 | 193 | 0 | 0 | 97 | 0 | 1.000 (0.980 to 1.000) | n/a | n/a | 0.000 (0.000 to 0.038) |

## Every answer, those replaced after a retry included

| Pipeline | Model | Answers | Numbers written | Counts of quarters | TP | FP | FN | TN | Leaks | Precision | Recall | F1 | Leak rate |
|--------------|----------|-------|-------|--------|-----|---|---|-----|-----|---------|---------|---------|---------|
| Newspaper, inside pieces, exact figures | claude-sonnet-5-5 | 289 | 1493 | 6 | 1486 | 1 | 1 | 1353 | 0 | 0.999 (0.996 to 1.000) | 0.999 (0.996 to 1.000) | 0.999 (0.996 to 1.000) | 0.000 (0.000 to 0.003) |
| Newspaper, inside pieces, plain words | claude-sonnet-5-5 | 242 | 173 | 23 | 150 | 0 | 0 | 1160 | 0 | 1.000 (0.975 to 1.000) | n/a | n/a | 0.000 (0.000 to 0.003) |
| Newspaper, the lead, exact figures | claude-sonnet-5-5 | 66 | 663 | 4 | 659 | 0 | 0 | 277 | 0 | 1.000 (0.994 to 1.000) | 1.000 (0.994 to 1.000) | 1.000 (0.994 to 1.000) | 0.000 (0.000 to 0.014) |
| Newspaper, the lead, plain words | claude-sonnet-5-5 | 94 | 179 | 7 | 172 | 0 | 0 | 433 | 0 | 1.000 (0.978 to 1.000) | n/a | n/a | 0.000 (0.000 to 0.009) |
| Newspaper, all | claude-sonnet-5-5 | 691 | 2508 | 40 | 2467 | 1 | 1 | 3223 | 0 | 1.000 (0.998 to 1.000) | 1.000 (0.998 to 1.000) | 1.000 (0.998 to 1.000) | 0.000 (0.000 to 0.001) |
| Chat | claude-sonnet-5-5 | 112 | 803 | 30 | 773 | 0 | 0 | 411 | 0 | 1.000 (0.995 to 1.000) | n/a | n/a | 0.000 (0.000 to 0.009) |
| Debrief | claude-sonnet-5-5 | 8 | 266 | 73 | 193 | 0 | 0 | 97 | 0 | 1.000 (0.980 to 1.000) | n/a | n/a | 0.000 (0.000 to 0.038) |

## The false positives by where the number stands, every answer

| Pipeline | Model | FP | In the instruction or the fixed part | Found nowhere in the request | of them rounded from a figure of the material | equal to a hidden value | neither | Answers with a figure found nowhere |
|-----------------|-----------|-----|------------|-----------|-------------|----------|--------|-------------|
| Newspaper, inside pieces, exact figures | claude-sonnet-5-5 | 1 | 0 | 1 | 0 | 0 | 1 | 1 of 289 |
| Newspaper, inside pieces, plain words | claude-sonnet-5-5 | 0 | 0 | 0 | 0 | 0 | 0 | 0 of 242 |
| Newspaper, the lead, exact figures | claude-sonnet-5-5 | 0 | 0 | 0 | 0 | 0 | 0 | 0 of 66 |
| Newspaper, the lead, plain words | claude-sonnet-5-5 | 0 | 0 | 0 | 0 | 0 | 0 | 0 of 94 |
| Newspaper, all | claude-sonnet-5-5 | 1 | 0 | 1 | 0 | 0 | 1 | 1 of 691 |
| Chat | claude-sonnet-5-5 | 0 | 0 | 0 | 0 | 0 | 0 | 0 of 112 |
| Debrief | claude-sonnet-5-5 | 0 | 0 | 0 | 0 | 0 | 0 | 0 of 8 |

## The figures found nowhere in the request

- final | T5 q6 | piece S4, exact figures | claude-sonnet-5-5 | found nowhere: neither | 100 | ...nt Trust in the central bank's announcements 80 percent full trust of 100 percent The central bank had announced a policy r...

## Figures under `<use>` that an answer did not write

- final | T2 q7 | piece S2, exact figures | claude-sonnet-5-5 | not written: 0.7 | Lower firm costs hold prices down this quarter Four people tell us how prices, wages and jobs feel at home, now that lower costs for firms a

## Residual wording

The texts the player reads in which a sentence names what its call received as its source (the material, the facts, a tag, the sheet), or says that its source does not give something. The fixed parts forbid both. This is wording, no error of a number, and the categories of the hand annotation in test 05b do not cover it. Each text is listed with its topic, its quarter and the sentences.

| Texts the player reads | Texts | Name their own input | Say that something is not given | Either |
|--------------------|--------|------------|--------------|--------|
| Newspaper | 600 | 2 | 3 | 4 |
| Chat | 112 | 4 | 4 | 4 |
| Debrief | 8 | 0 | 0 | 0 |

- chat | T5 q2 | names its input, says that something is not given | Our material does not give the lags in the economy, so we cannot say how many quarters it takes.
- chat | T5 q5 | names its input, says that something is not given | Our material gives no lags, so we cannot say how many quarters it takes.
- chat | T5 q8 | names its input, says that something is not given | Our material gives no lags, so we cannot say how many quarters.
- chat | T5 q11 | names its input, says that something is not given | Our material gives no lags, so we cannot say how many quarters.
- piece S5, F-CHART | T8 q3 | says that something is not given | The poll does not say whether spending has changed how people vote.
- piece S5, F-CHART | T8 q4 | names its input, says that something is not given | The poll does not say whether this spending is linked to voter views, so the two facts are reported side by side.
- piece S5, F-INTERVIEW | T8 q6 | names its input | Not yet, according to the latest facts.
- piece S5, F-CHART | T8 q13 | says that something is not given | It does not say how those voters expect the party to act in the months ahead, so it should be read as a snapshot of support today.

## Speed and retries

The seconds of a call are those its record holds, over the calls that were answered; the inside pieces of an issue are sent at once, and each of their records holds the time of the whole batch.

| Call type | Model | Calls | Died on the connection | Answered, the answer not readable | Median seconds | 90th percentile | Median input tokens | Median output tokens | Calls with reasoning |
|---------|--------------|-------|-----------|-------------|---------|---------|---------|---------|----------|
| piece | claude-sonnet-5-5 | 531 | 0 | 0 | 5.6 | 9.8 | 957 | 215 | 15 |
| lead | claude-sonnet-5-5 | 160 | 0 | 0 | 3.9 | 4.6 | 1433 | 369 | 0 |
| chat | claude-sonnet-5-5 | 112 | 0 | 0 | 3.4 | 7.2 | 3292 | 255 | 26 |
| debrief | claude-sonnet-5-5 | 8 | 0 | 0 | 28.6 | 42.5 | 3584 | 3638 | 8 |

Issues: 100. Seconds per issue, the inside pieces sent at once, then those asked for again, then the lead: median 13.1, 90th percentile 20.0; calls per issue: median 7.
Retries per piece: 0.152: 91 further calls for 600 pieces, the leads included, 91 of them asked again with the sentence of a failed check and 0 after an answer that could not be read. Calls that died on the connection: 0; they count neither as retries nor as the model's failures. Pieces as the player reads them: 509 by the model at the first answer, 91 after a retry, 0 of these with a text shortened, 5 kept with a failed check (body 2, headline 3), 0 from the template.

| Format | Pieces | Asked again for the number of paragraphs | for the headline's length | for the body's length | for the structure | Asked again, share of pieces |
|--------------|--------|------------------|----------------|----------------|-------------|---------------|
| F-BRIEF | 128 | 0 | 0 | 0 | 0 | 0.00 |
| F-CHART | 208 | 0 | 5 | 6 | 0 | 0.05 |
| F-COMMENT | 51 | 0 | 12 | 5 | 0 | 0.33 |
| F-INTERVIEW | 47 | 0 | 0 | 0 | 0 | 0.00 |
| F-LEAD | 100 | 0 | 1 | 59 | 0 | 0.60 |
| F-MARKETS | 3 | 0 | 0 | 0 | 0 | 0.00 |
| F-REPORT | 18 | 0 | 0 | 3 | 0 | 0.17 |
| F-VOICES | 45 | 0 | 0 | 0 | 0 | 0.00 |
