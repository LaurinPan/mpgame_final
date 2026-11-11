# The Monetary Policy Game: submission

This folder holds the game and its verification as submitted with the thesis. It was built from the working folder by `tools/make_submission.R` from an explicit list of files, and it contains only what the game and the tests need.

Built from R 4.4.1.

## Links

- The live app: to be added
- The repository: to be added

## The three folders

- `01_Engine/`: the model's engine, stage by stage with the stages combined (thesis Section 4.1 and the model appendix).
- `02_Game/`: the game's backend and content (`bank/`, `sheet/`, `llm/`, `play/`, `content/` with the theory section) and its user interface (`ui/`, the page's styles and scripts in `web/`) (Section 4.2).
- `03_Verification/`: the tests with their tables in `results/`, the recordings they read and the recorder (Section 5.1); the next section names its files.

`manifest.json` lists the folder's files and the R packages the app needs, as `rsconnect::writeManifest()` wrote it; Posit Connect Cloud publishes the app from the repository with it. `.gitignore` keeps `.Renviron`, `.Rhistory`, `.RData` and `.Rproj.user/` out of the repository.

## What 03_Verification holds

- `01_closed_forms.R`, `02_reductions.R`, `03_gali_table_6_1.R` and `04_visibility.R`: the four tests of the engine and of the game as built, each with its table of the same name in `results/`.
- `results/05_faithfulness.md`: the table of test 05 (`05_faithfulness.R`, with its count in `05_counts.R`), the confusion-matrix test of every number the LLM layer wrote in the eight recordings, with the count of the residual wording.
- `results/05b_annotation.md`: the tables of the hand annotation (`05b_annotation.R`, which also drew the two samples), the errors per category with the share of texts that have at least one: the pieces per model, counted with all errors and without those of the strict reading of the word scale, and the chat's answers with their rule breaches by topic and step.
- `results/05c_model_comparison.md`: the table of the model comparison (`05c_model_comparison.R`), the six conditions of the rule fixed in advance, the retries, the speed and the decision.
- `recordings_comparison/T3.rds` and `T8.rds`: the recordings of the comparison, Topics 3 and 8 with the pieces and the leads written by claude-haiku-5-5.
- `annotation_sample.csv`: the annotated sample of the pieces, 80 pieces of Topics 3 and 8, 40 per model, each with the facts its call received and the annotator's count of errors per category.
- `annotation_chat_sample.csv`: the annotated sample of the chat, 40 answers of the Chief Economist from the eight final recordings, 5 per topic, each with its question, the facts, the forecast and the prohibition its call received, and the annotator's count of errors per category and of rule breaches.
- `recordings/T1.rds` to `T8.rds`: the eight final recordings, one run per topic with the model, each with every call as sent and as answered.
- `recordings/walkthrough/`: Topic 5's walk-through, quarter 8 with every call of its issue, its chat and the debrief.
- `record_topics.R`: the recorder, which makes the recordings that are missing; it needs `ANTHROPIC_API_KEY`.
- `run_all.R`: runs the tests in order.

## Starting the game

From this folder, in R:

    shiny::runApp()

or `Rscript -e "shiny::runApp()"` from a terminal. The app opens on the sign-in page. Each account's password is the environment variable named in `.Renviron.example`; an account whose variable is not set cannot sign in. The player's runs are saved under `MPGAME_SAVE_DIR`, by default R's user data directory for "mpgame", or in a PostgreSQL database when `MPGAME_DATABASE_URL_FINAL` is set.

## Running the tests

From this folder, in R:

    source("03_Verification/run_all.R")

The five tests write their tables to `03_Verification/results/`, and so do 05b and 05c, which build on test 05. Tests 01 to 03 take seconds and 04 about two hours; 05, 05b and 05c read the recordings and the two annotated samples and take seconds. None of them needs a key. `03_Verification/record_topics.R` makes the recordings that are missing with the model, the eight topics, the walk-through and the model comparison: it needs `ANTHROPIC_API_KEY`. The headless player of `02_Game/play/headless.R` plays any topic without the model, for example `play_headless("T1")` after `for (f in list.files(c("01_Engine", "02_Game"), pattern = "[.]R$", recursive = TRUE, full.names = TRUE)) source(f)`.

## Environment variables

- `ANTHROPIC_API_KEY`: the key of the model that writes the newspaper, answers the chat and writes the debrief. Without it the game prints the newspaper's, the chat's and the debrief's texts without a model, and the tests run unchanged.
- `MPGAME_PASSWORD_DEV_1_FINAL`, `MPGAME_PASSWORD_DEV_2_FINAL`, `MPGAME_PASSWORD_DEV_3_FINAL`, `MPGAME_PASSWORD_TEST_USER_1_FINAL`, `MPGAME_PASSWORD_TEST_USER_2_FINAL`, `MPGAME_PASSWORD_TEST_USER_3_FINAL`: the six accounts' passwords, one each (`02_Game/ui/users.yaml`).
- `MPGAME_SAVE_DIR` (optional): where the runs are saved. `MPGAME_DATABASE_URL_FINAL` (optional): a PostgreSQL database for the runs instead of files.

`.Renviron.example` lists the variable names; copy it to `.Renviron` in this folder or to your home folder and fill in the values.

## R and packages

R 4.4.1. Packages: shiny 1.14.0, htmltools 0.5.8.1, jsonlite 2.0.0, httr2 1.3.0, yaml 2.3.12, commonmark 2.0.0, mirai 2.7.4, DBI 1.3.0, pool 1.0.5, RPostgres 1.4.10, blob 1.2.4. The database packages are needed only with `MPGAME_DATABASE_URL_FINAL`, and mirai only for the background worker, which the app does without if the package is missing.
