# ui/store.R — the store of the runs and of the model's log: Postgres when MPGAME_DATABASE_URL_FINAL
# is set (Connect Cloud, a Neon URL with ?sslmode=require), else one RDS file per user and slot under MPGAME_SAVE_DIR (a laptop).
# A run is one user's slot: its uid, name, times, settings, the UI's state and its game (the terms). The URL and the passwords are
# never printed: an error's message is redacted before it reaches the log. Definitions only.

UI_STORE <- new.env(parent = emptyenv())

# The database's store when its URL is set, else the files'.
ui_store_db <- function() nzchar(Sys.getenv("MPGAME_DATABASE_URL_FINAL"))

# The files' folder (MPGAME_SAVE_DIR, else the app's data folder in the user's profile).
ui_store_dir <- function() {
  d <- Sys.getenv("MPGAME_SAVE_DIR")
  if (!nzchar(d)) d <- file.path(tools::R_user_dir("mpgame", "data"), "runs")
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  d
}

# An error's message without a connection URL or its password.
ui_store_redact <- function(msg) gsub("postgres(ql)?://[^ ]*", "postgres://<redacted>", msg)

# The database's URL taken apart for RPostgres, which does not read a URL itself.
ui_store_url_parts <- function(url) {
  m <- regmatches(url, regexec("^postgres(ql)?://([^:@/]*)(:([^@/]*))?@([^:/?]+)(:([0-9]+))?/([^?]+)([?](.*))?$", url))[[1]]
  if (!length(m)) stop("MPGAME_DATABASE_URL_FINAL is not a postgres URL")
  a <- list(user = utils::URLdecode(m[3]), password = utils::URLdecode(m[5]), host = m[6], port = if (nzchar(m[8])) as.integer(m[8]) else 5432L, dbname = m[9])
  if (nzchar(m[11])) for (kv in strsplit(strsplit(m[11], "&", fixed = TRUE)[[1]], "=", fixed = TRUE)) if (length(kv) == 2) a[[kv[1]]] <- utils::URLdecode(kv[2])
  a
}

# The pool of connections and the three tables, made once per process.
ui_store_pool <- function() {
  if (!is.null(UI_STORE$pool)) return(UI_STORE$pool)
  p <- do.call(pool::dbPool, c(list(drv = RPostgres::Postgres()), ui_store_url_parts(Sys.getenv("MPGAME_DATABASE_URL_FINAL"))))
  DBI::dbExecute(p, paste("CREATE TABLE IF NOT EXISTS mpgame_runs (user_id TEXT NOT NULL, slot INTEGER NOT NULL, uid TEXT NOT NULL, name TEXT NOT NULL,",
                          "created TIMESTAMPTZ NOT NULL, updated TIMESTAMPTZ NOT NULL, settings TEXT, ui_state TEXT, game BYTEA, PRIMARY KEY (user_id, slot))"))
  DBI::dbExecute(p, paste("CREATE TABLE IF NOT EXISTS mpgame_llm_log (id BIGSERIAL PRIMARY KEY, run_uid TEXT, topic TEXT, user_id TEXT, time TIMESTAMPTZ,",
                          "task TEXT, model TEXT, model_served TEXT, seconds DOUBLE PRECISION, ok BOOLEAN, stop_reason TEXT, usage TEXT, body TEXT, raw TEXT)"))
  DBI::dbExecute(p, "CREATE TABLE IF NOT EXISTS mpgame_schema (version INTEGER NOT NULL)")
  if (!nrow(DBI::dbGetQuery(p, "SELECT version FROM mpgame_schema"))) DBI::dbExecute(p, "INSERT INTO mpgame_schema (version) VALUES (1)")
  UI_STORE$pool <- p
  p
}

# The JSON of a setting or of the UI's state, and back.
ui_store_json <- function(x) as.character(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null", digits = NA))
# A JSON text read back as lists.
ui_store_unjson <- function(s) if (is.null(s) || is.na(s) || !nzchar(s)) list() else jsonlite::fromJSON(s, simplifyVector = FALSE)

# One row of mpgame_runs as a run.
ui_store_row <- function(d) {
  raw <- d$game[[1]]
  list(slot = as.integer(d$slot), uid = d$uid, name = d$name, created = d$created, updated = d$updated,
       settings = ui_store_unjson(d$settings), ui = ui_store_unjson(d$ui_state),
       game = if (length(raw)) unserialize(memDecompress(as.raw(raw), "gzip")) else list(terms = list()))
}

# A run's file on a laptop.
ui_store_file <- function(user, slot) file.path(ui_store_dir(), sprintf("%s_slot%d.rds", user, as.integer(slot)))

# A user's runs, slot by slot, each with its game.
ui_store_list <- function(user) {
  if (ui_store_db()) {
    d <- DBI::dbGetQuery(ui_store_pool(), "SELECT * FROM mpgame_runs WHERE user_id = $1 ORDER BY slot", params = list(user))
    return(lapply(seq_len(nrow(d)), function(i) tryCatch(ui_store_row(d[i, , drop = FALSE]), error = function(e) ui_store_unreadable(d$slot[i], d$name[i]))))
  }
  fs <- list.files(ui_store_dir(), pattern = paste0("^", user, "_slot[1-3][.]rds$"), full.names = TRUE)
  lapply(sort(fs), function(f) tryCatch(readRDS(f), error = function(e) ui_store_unreadable(as.integer(sub("^.*_slot([1-3])[.]rds$", "\\1", f)))))
}

# A slot the store could not read, its name kept where the store still has it.
ui_store_unreadable <- function(slot, name = NULL) {
  message("MPGAME the run in slot ", slot, " could not be read")
  list(slot = as.integer(slot), uid = NA_character_, name = if (is.null(name) || is.na(name)) ui_s("runs.slot_name", slot = as.integer(slot)) else name,
       created = Sys.time(), updated = NA, settings = list(), ui = list(), game = list(terms = list()), unreadable = TRUE)
}

# A run written, created or replaced; its updated time is now.
ui_store_put <- function(user, run) {
  run$updated <- Sys.time()
  if (ui_store_db()) {
    DBI::dbExecute(ui_store_pool(), paste(
      "INSERT INTO mpgame_runs (user_id, slot, uid, name, created, updated, settings, ui_state, game) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)",
      "ON CONFLICT (user_id, slot) DO UPDATE SET uid = EXCLUDED.uid, name = EXCLUDED.name, created = EXCLUDED.created, updated = EXCLUDED.updated,",
      "settings = EXCLUDED.settings, ui_state = EXCLUDED.ui_state, game = EXCLUDED.game"),
      params = list(user, as.integer(run$slot), run$uid, run$name, run$created, run$updated, ui_store_json(run$settings), ui_store_json(run$ui),
                    blob::blob(memCompress(serialize(run$game, NULL), "gzip"))))
  } else saveRDS(run, ui_store_file(user, run$slot), compress = "gzip")
  run
}

# A run deleted from its slot.
ui_store_delete <- function(user, slot) {
  if (ui_store_db()) DBI::dbExecute(ui_store_pool(), "DELETE FROM mpgame_runs WHERE user_id = $1 AND slot = $2", params = list(user, as.integer(slot)))
  else unlink(ui_store_file(user, slot))
  invisible(TRUE)
}

# The model's new calls written to the log, one line each also on standard error (prefix MPGAME-LLM, never the body).
ui_store_log <- function(user, run_uid, topic, records) {
  if (!length(records)) return(invisible(0L))
  for (r in records) message(sprintf("MPGAME-LLM %s %s %s %.1fs ok=%s", topic, r$task %||% "", r$model_served %||% r$model %||% "", as.numeric(r$seconds %||% NA), isTRUE(r$ok)))
  rows <- lapply(records, function(r) list(run_uid = run_uid, topic = topic, user_id = user, time = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
                                         task = r$task %||% NA, model = r$model %||% NA, model_served = r$model_served %||% NA, seconds = as.numeric(r$seconds %||% NA),
                                         ok = isTRUE(r$ok), stop_reason = r$stop_reason %||% NA, usage = ui_store_json(r$usage),
                                         body = if (is.null(r$body)) NA else ui_store_json(r$body), raw = if (is.null(r$raw)) NA else ui_store_json(r$raw)))
  if (ui_store_db()) {
    for (x in rows) DBI::dbExecute(ui_store_pool(), paste("INSERT INTO mpgame_llm_log (run_uid, topic, user_id, time, task, model, model_served, seconds, ok, stop_reason, usage, body, raw)",
                                                          "VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)"),
                                  params = unname(lapply(x, function(v) if (is.null(v)) NA else v)))
  } else {
    con <- file(file.path(ui_store_dir(), "llm_log.jsonl"), "ab")
    for (x in rows) writeLines(ui_store_json(x), con, useBytes = TRUE)
    close(con)
  }
  invisible(length(rows))
}
