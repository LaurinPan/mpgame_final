# 05c The model comparison

The pieces and the leads of Topics 3 and 8, written by claude-sonnet-5-5 in `03_Verification/recordings` and by claude-haiku-5-5, with its reasoning off, in `03_Verification/recordings_comparison`: the same layer, the same plans and the same facts for both. Every number is counted as in test 05, over every answer, those replaced after a retry included, and each rate has its 95 percent Wilson interval in brackets.

## The rule and its six conditions

The rule was fixed before the comparison ran: claude-haiku-5-5 takes the pieces only if all six conditions hold, faithfulness first and speed last. An interval is below another when its upper end lies under the other's lower end.

| | Condition | claude-sonnet-5-5 | claude-haiku-5-5 | Holds |
|---|-------------------------------------|------------------------|------------------------|------------|
| 1 | No piece falls to a template | 0 of 216 pieces | 0 of 216 | yes |
| 2 | Its precision interval is not below the other's | 1.000 (0.996 to 1.000) | 0.997 (0.990 to 0.999) | yes |
| 3 | Its recall interval is not below the other's | 1.000 (0.996 to 1.000) | 0.964 (0.948 to 0.975) | no |
| 4 | It writes no more figures found nowhere in the request | 0 | 1 | no |
| 5 | It leaks nothing | 0 of 1208 hidden values | 0 of 1441 | yes |
| 6 | The issue is faster, median seconds | 13.4 | 10.6 | yes |

## The counts behind conditions 2 to 5

| Model | Answers | Numbers written | Counts of quarters | TP | FP | of them found nowhere in the request | FN | Hidden values | Leaks |
|----------------|--------|---------|---------|-------|------|----------------|------|---------|-------|
| claude-sonnet-5-5 | 257 | 923 | 24 | 899 | 0 | 0 | 0 | 1208 | 0 |
| claude-haiku-5-5 | 308 | 762 | 11 | 749 | 2 | 1 | 28 | 1441 | 0 |

Figures under `<use>` that an answer with exact figures did not write, of those it was given, by format:

| Format | claude-sonnet-5-5 | claude-haiku-5-5 |
|---|---|---|
| F-CHART | 0 of 205 | 0 of 272 |
| F-COMMENT | 0 of 23 | 0 of 37 |
| F-INTERVIEW | 0 of 25 | 0 of 32 |
| F-LEAD | 0 of 100 | 0 of 77 |
| F-MARKETS | 0 of 1 | 0 of 1 |
| F-VOICES | 0 of 26 | 28 of 30 |

The figures found nowhere in the request:

- comparison | T8 q18 | piece S5, exact figures | claude-haiku-5-5 | found nowhere: neither | 9.8 | ...pposition stands at 45.1 percent, so the gap between the two sides is 9.8 points. Government spending is 1.2 percent below ...

## Retries and failed checks

| | claude-sonnet-5-5 | claude-haiku-5-5 |
|--------------------------------------------------|-------------------------|-------------------------|
| Pieces and leads as the player reads them | 216 | 216 |
| Calls | 257 | 308 |
| of them died on the connection, neither retries nor failures of the model | 0 | 0 |
| of them answered without an answer that could be read | 0 | 0 |
| Further calls after a failed check | 41 | 92 |
| Retries per piece | 0.190 | 0.426 |
| Pieces kept with a failed check | 1 (body 1) | 50 (body 23, headline 24, paragraphs 3) |
| Pieces from the template | 0 | 0 |

## Speed

The seconds of the calls that were answered. The inside pieces of an issue are sent at once, and each of their records holds the time of the whole batch; an issue's seconds are those of its inside pieces, of the pieces asked for again and of the lead.

| | Model | Number | Median seconds | 90th percentile |
|---|---|---|---|---|
| An inside piece's call | claude-sonnet-5-5 | 190 | 5.5 | 10.4 |
| An inside piece's call | claude-haiku-5-5 | 253 | 3.6 | 4.6 |
| The lead's call | claude-sonnet-5-5 | 67 | 3.7 | 4.6 |
| The lead's call | claude-haiku-5-5 | 55 | 2.6 | 3.5 |
| An issue | claude-sonnet-5-5 | 36 | 13.4 | 22.6 |
| An issue | claude-haiku-5-5 | 36 | 10.6 | 12.8 |

## The hand annotation of the pieces

From `03_Verification/results/05b_annotation.md`, the pieces with at least one error of any kind, counted twice as in that table. They were read blind. The annotation is no condition of the rule.

| Model | Count | Pieces annotated | Errors counted | Pieces with at least one error | Share of pieces |
|----------------|--------------------------------|----------|---------|-------------|--------------------|
| claude-sonnet-5-5 | With all errors | 40 | 16 | 14 | 0.350 (0.221 to 0.505) |
| claude-sonnet-5-5 | Without the four errors that only the strict reading of the word scale counts | 40 | 15 | 14 | 0.350 (0.221 to 0.505) |
| claude-haiku-5-5 | With all errors | 40 | 42 | 30 | 0.750 (0.598 to 0.858) |
| claude-haiku-5-5 | Without the four errors that only the strict reading of the word scale counts | 40 | 39 | 29 | 0.725 (0.572 to 0.839) |

## The decision

Conditions 3 and 4 do not hold: claude-sonnet-5-5 keeps the pieces, and the recordings of claude-haiku-5-5 remain as the comparison.
