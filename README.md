# The Monetary Policy Game

This repository holds the game and its verification for the bachelor thesis *Enhancing Economic Literacy Through Play: Building a Guided Learning Game to Teach Modern Monetary Policy to Non-Experts* (Laurin Pan, University of St. Gallen, 2026). Section, table, and equation numbers in this file and in the comments of the code refer to that thesis.

## Links

- The game: https://laurinpan-mpgame.share.connect.posit.cloud
- The repository: https://github.com/LaurinPan/mpgame_final
- The release the thesis cites: https://github.com/LaurinPan/mpgame_final/releases/tag/submission

## Folders

| Folder | Holds | Thesis |
|---|---|---|
| `01_Engine/` | The model, stage by stage, and the stages combined | Section 4.1 and the model appendix |
| `02_Game/` | The game around the model: the reference bank (`bank/`), the facts of a quarter (`sheet/`), the calls to Claude Sonnet 5.5 (`llm/`), the course of a term (`play/`), the scripts and texts (`content/`), and the interface (`ui/`, `web/`) | Sections 4.2 and 4.3 |
| `03_Verification/` | The tests, their result tables, the recordings, and the two annotated samples | Section 5.1 and the verification appendix |

`app.R` starts the game. `manifest.json` lists the files and packages for Posit Connect Cloud.

## Starting the game

In R, from this folder:

    shiny::runApp()

The game opens on the sign-in page. Each account's password is an environment variable. `.Renviron.example` lists the names. Copy it to `.Renviron` and fill in the values. Without `ANTHROPIC_API_KEY` the game writes the newspaper, the chat answers, and the debrief without a language model.

## Running the tests

In R, from this folder:

    source("03_Verification/run_all.R")

| Test | Script | Checks | Time |
|---|---|---|---|
| 01 Closed forms | `01_closed_forms.R` | The engine against formulas solved by hand | Seconds |
| 02 Reductions | `02_reductions.R` | Each later stage, switched off, against Stage 1 | Seconds |
| 03 Published results | `03_gali_table_6_1.R` | The engine against Galí's (2015) Table 6.1 | Seconds |
| 04 Visibility | `04_visibility.R` | The effect behind each learning objective against its spread | About two hours |
| 05 Faithfulness | `05_faithfulness.R` | Every figure in the recorded texts against the facts of its call | Seconds |
| 05b Hand annotation | `05b_annotation.R` | The counts of the two samples annotated by hand | Seconds |
| 05c Model comparison | `05c_model_comparison.R` | Claude Haiku 5.5 against Claude Sonnet 5.5, the game's model | Seconds |

Each test writes its table to `03_Verification/results/`.

## The recordings

- `recordings/T1.rds` to `T8.rds`: one recorded term per topic, with every call to Claude Sonnet 5.5 as sent and as answered.
- `recordings/walkthrough/`: quarter 8 of Topic 5 with every call of its newspaper, the chat exchange, and the debrief.
- `recordings_comparison/`: Topics 3 and 8 with the newspaper written by Claude Haiku 5.5.
- `annotation_sample.csv` and `annotation_chat_sample.csv`: the two samples annotated by hand.

The numbers of the thesis rest on these files. `record_topics.R` is the script that made them. It plays a topic with the language model and saves every call, and it needs `ANTHROPIC_API_KEY`. It skips a recording that already exists, so it leaves the files of this folder untouched. A new recording holds new texts, so its counts differ from those of the thesis.

## Names used in the files

| Family | Names | Meaning |
|---|---|---|
| Topics | `T1` to `T8` | Topics 1 to 8 |
| Chapters | `A` to `E` | The five chapters |
| Places in the newspaper | `L`, `S1` to `S5` | `L` the lead on the front page. `S1` The Economy and `S2` Prices and Wages on page 2. `S3` Jobs and `S4` Markets and the Bank on page 3. `S5` Politics or Analysis on page 4. |
| Formats | `F-LEAD`, `F-REPORT`, `F-CHART`, `F-INTERVIEW`, `F-VOICES`, `F-COMMENT`, `F-MARKETS`, `F-BRIEF` | The form of a piece: lead, report, chart with a short text, interview, voices of several people, comment, table of market figures, brief |
| Piece types | For example `J-count` | What a piece reports. The letter is the page: `L` front page, `E` The Economy, `P` Prices and Wages, `J` Jobs, `M` Markets and the Bank, `G` Politics, `A` Analysis. |
| Charts | For example `CH-inflation` | The chart a piece shows |
| Briefings | `B-A`, `B-T1`, `B-G1-5`, `B-E7-9` | A chapter's opening, a topic's opening, the guided quarter 5 of Topic 1, the event briefing in quarter 9 of Topic 7 |
| Theory | `P1` to `P6` | The six chapters of the theory section |

## R and packages

R 4.4.1. Packages: shiny 1.14.0, htmltools 0.5.8.1, jsonlite 2.0.0, httr2 1.3.0, yaml 2.3.12, commonmark 2.0.0, mirai 2.7.4, DBI 1.3.0, pool 1.0.5, RPostgres 1.4.10, blob 1.2.4. The database packages are needed only with a database, and mirai only for the background worker.
