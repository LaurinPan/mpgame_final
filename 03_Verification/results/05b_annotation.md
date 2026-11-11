# 05b The hand annotation

Two samples, each read by hand, claim by claim, against the facts its call had received.

`03_Verification/annotation_sample.csv`: 80 pieces of Topics 3 and 8, 40 per model from the same places of the paper, in one shuffled order. They were read blind: the column with the model's name was hidden in the spreadsheet while the pieces were annotated.

`03_Verification/annotation_chat_sample.csv`: 40 answers of the Chief Economist from the final recordings of Topics 1 to 8, 5 per topic and spread over the steps, all written by claude-sonnet-5-5. An answer was also read against its forecast and its topic's prohibition.

The annotator entered the number of errors of each kind in each text, in Thomson and Reiter's categories. A claim of change where the facts give only a level counts as not checkable, and omissions are not counted. A text counts for a category when it has at least one error of that kind, and for "any" when it has at least one error of any of the six kinds. Each share has its 95 percent Wilson interval in brackets.

Every count of the pieces is given twice. A size word is judged by the game's own word scale, the one the facts use, even where everyday usage would pass, and four incorrect words rest on that strict reading alone: one in piece 11, one in piece 22, one in piece 51 and one in piece 62. The first table counts every error, and the second leaves these four out.

## The pieces, with all errors

| Model | Category | Pieces annotated | Errors counted | Pieces with at least one error | Share of pieces |
|------------------|----------------------|------------|-----------|--------------|-----------------------|
| claude-haiku-5-5 | incorrect number | 40 | 0 | 0 | 0.000 (0.000 to 0.088) |
| claude-haiku-5-5 | incorrect named entity | 40 | 0 | 0 | 0.000 (0.000 to 0.088) |
| claude-haiku-5-5 | incorrect word | 40 | 13 | 11 | 0.275 (0.161 to 0.428) |
| claude-haiku-5-5 | context error | 40 | 1 | 1 | 0.025 (0.004 to 0.129) |
| claude-haiku-5-5 | not checkable | 40 | 28 | 23 | 0.575 (0.422 to 0.715) |
| claude-haiku-5-5 | other | 40 | 0 | 0 | 0.000 (0.000 to 0.088) |
| claude-haiku-5-5 | any | 40 | 42 | 30 | 0.750 (0.598 to 0.858) |
| claude-sonnet-5-5 | incorrect number | 40 | 0 | 0 | 0.000 (0.000 to 0.088) |
| claude-sonnet-5-5 | incorrect named entity | 40 | 0 | 0 | 0.000 (0.000 to 0.088) |
| claude-sonnet-5-5 | incorrect word | 40 | 1 | 1 | 0.025 (0.004 to 0.129) |
| claude-sonnet-5-5 | context error | 40 | 0 | 0 | 0.000 (0.000 to 0.088) |
| claude-sonnet-5-5 | not checkable | 40 | 15 | 14 | 0.350 (0.221 to 0.505) |
| claude-sonnet-5-5 | other | 40 | 0 | 0 | 0.000 (0.000 to 0.088) |
| claude-sonnet-5-5 | any | 40 | 16 | 14 | 0.350 (0.221 to 0.505) |

## The pieces, without the four errors that only the strict reading of the word scale counts

| Model | Category | Pieces annotated | Errors counted | Pieces with at least one error | Share of pieces |
|------------------|----------------------|------------|-----------|--------------|-----------------------|
| claude-haiku-5-5 | incorrect number | 40 | 0 | 0 | 0.000 (0.000 to 0.088) |
| claude-haiku-5-5 | incorrect named entity | 40 | 0 | 0 | 0.000 (0.000 to 0.088) |
| claude-haiku-5-5 | incorrect word | 40 | 10 | 9 | 0.225 (0.123 to 0.375) |
| claude-haiku-5-5 | context error | 40 | 1 | 1 | 0.025 (0.004 to 0.129) |
| claude-haiku-5-5 | not checkable | 40 | 28 | 23 | 0.575 (0.422 to 0.715) |
| claude-haiku-5-5 | other | 40 | 0 | 0 | 0.000 (0.000 to 0.088) |
| claude-haiku-5-5 | any | 40 | 39 | 29 | 0.725 (0.572 to 0.839) |
| claude-sonnet-5-5 | incorrect number | 40 | 0 | 0 | 0.000 (0.000 to 0.088) |
| claude-sonnet-5-5 | incorrect named entity | 40 | 0 | 0 | 0.000 (0.000 to 0.088) |
| claude-sonnet-5-5 | incorrect word | 40 | 0 | 0 | 0.000 (0.000 to 0.088) |
| claude-sonnet-5-5 | context error | 40 | 0 | 0 | 0.000 (0.000 to 0.088) |
| claude-sonnet-5-5 | not checkable | 40 | 15 | 14 | 0.350 (0.221 to 0.505) |
| claude-sonnet-5-5 | other | 40 | 0 | 0 | 0.000 (0.000 to 0.088) |
| claude-sonnet-5-5 | any | 40 | 15 | 14 | 0.350 (0.221 to 0.505) |

## The chat

A rule breach is an answer that names a rate to set, a number of quarters to promise or a plan to announce, that names a hidden value, or that breaks its topic's prohibition, openly or in substance. It is counted beside the six categories and is no part of "any".

| Category | Answers annotated | Errors counted | Answers with at least one | Share of answers |
|----------------------|------------|-----------|--------------|-----------------------|
| incorrect number | 40 | 0 | 0 | 0.000 (0.000 to 0.088) |
| incorrect named entity | 40 | 0 | 0 | 0.000 (0.000 to 0.088) |
| incorrect word | 40 | 2 | 2 | 0.050 (0.014 to 0.165) |
| context error | 40 | 0 | 0 | 0.000 (0.000 to 0.088) |
| not checkable | 40 | 0 | 0 | 0.000 (0.000 to 0.088) |
| other | 40 | 0 | 0 | 0.000 (0.000 to 0.088) |
| any | 40 | 2 | 2 | 0.050 (0.014 to 0.165) |
| rule breach | 40 | 0 | 0 | 0.000 (0.000 to 0.088) |

## The chat's rule breaches by topic and step

| Answers | Answers annotated | Rule breaches | Answers with a rule breach | Share of answers |
|----------------------|------------|-----------|--------------|-----------------------|
| Topic 1 | 5 | 0 | 0 | 0.000 (0.000 to 0.434) |
| Topic 2 | 5 | 0 | 0 | 0.000 (0.000 to 0.434) |
| Topic 3 | 5 | 0 | 0 | 0.000 (0.000 to 0.434) |
| Topic 4 | 5 | 0 | 0 | 0.000 (0.000 to 0.434) |
| Topic 5 | 5 | 0 | 0 | 0.000 (0.000 to 0.434) |
| Topic 6 | 5 | 0 | 0 | 0.000 (0.000 to 0.434) |
| Topic 7 | 5 | 0 | 0 | 0.000 (0.000 to 0.434) |
| Topic 8 | 5 | 0 | 0 | 0.000 (0.000 to 0.434) |
| Step 1 | 16 | 0 | 0 | 0.000 (0.000 to 0.194) |
| Step 2 | 8 | 0 | 0 | 0.000 (0.000 to 0.324) |
| Step 3 | 16 | 0 | 0 | 0.000 (0.000 to 0.194) |
| All | 40 | 0 | 0 | 0.000 (0.000 to 0.088) |
