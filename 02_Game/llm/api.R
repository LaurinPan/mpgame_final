# 02_Game/llm/api.R — Section 4.2.2, the LLM layer's one call: the texts a model receives, the request, the call and the answer parsed

# Section 4.2.2: whether a key is set
llm_available <- function() nzchar(Sys.getenv("ANTHROPIC_API_KEY"))

# Section 4.2.2: whether the run uses the model
model_on <- function(run) isTRUE(run$llm$on) && llm_available()

# Section 4.2.2: a file of model text, a fixed part or an instruction, as one text
model_text <- function(file) paste(readLines(file.path("02_Game/content/prompts", file), warn = FALSE, encoding = "UTF-8"), collapse = "\n")

# Section 4.2.2: a sentence with its {braces} filled
fill <- function(text, values) {
  for (m in unique(regmatches(text, gregexpr("[{][A-Za-z_]+[}]", text))[[1]])) {
    v <- values[[gsub("[{}]", "", m)]]
    if (is.null(v) || length(v) != 1) stop("no value for ", m, " in: ", text)
    text <- gsub(m, as.character(v), text, fixed = TRUE)
  }
  text
}

# Section 4.2.2: a part of the material in its tag, left out where it is empty
tagged <- function(tag, lines) if (length(lines)) paste0("<", tag, ">\n", paste(lines, collapse = "\n"), "\n</", tag, ">")

# Section 4.2.2: the request, the fixed part and the instruction as the system's two blocks and the material as the user's message, with the answer's schema, the call's time limit in seconds, what the call is about, and reasoning off for the models that models$thinking_off names
llm_request <- function(task, fixed, instruction, material, schema, model, effort, max_tokens, timeout, about = NULL) {
  body <- list(model = model, max_tokens = max_tokens,
               system = list(list(type = "text", text = fixed), list(type = "text", text = instruction)),
               messages = list(list(role = "user", content = material)),
               output_config = list(effort = effort, format = list(type = "json_schema", schema = schema)))
  if (model %in% models$thinking_off) body$thinking <- list(type = "disabled")
  req <- httr2::request(models$endpoint)
  req <- httr2::req_headers(req, `x-api-key` = Sys.getenv("ANTHROPIC_API_KEY"), `anthropic-version` = models$api_version,
                            `content-type` = "application/json", .redact = "x-api-key")
  req <- httr2::req_body_json(req, body, auto_unbox = TRUE, null = "null")
  req <- httr2::req_timeout(req, timeout)
  req <- httr2::req_error(req, is_error = function(resp) FALSE)
  list(task = task, about = about, model = model, request = req, body = body)
}

# Section 4.2.2: the answer parsed, its status, its stop reason and its JSON
llm_parse <- function(req, resp, seconds) {
  record <- list(task = req$task, about = req$about, model = req$model, seconds = seconds, ok = FALSE, parsed = NULL, raw = NULL,
                 usage = NULL, model_served = NA, stop_reason = NA, status = NA, error = NULL, body = req$body)
  if (inherits(resp, "error")) { record$error <- conditionMessage(resp); return(record) }
  record$status <- httr2::resp_status(resp)
  js <- tryCatch(httr2::resp_body_json(resp), error = function(e) NULL)
  if (record$status != 200 || is.null(js)) {
    record$error <- if (!is.null(js$error$message)) js$error$message else paste("HTTP", record$status)
    return(record)
  }
  record$stop_reason <- js$stop_reason; record$model_served <- js$model; record$usage <- js$usage
  texts <- vapply(Filter(function(b) identical(b$type, "text"), js$content), function(b) b$text, "")
  record$raw <- paste(texts, collapse = "")
  if (identical(js$stop_reason, "refusal")) { record$error <- "refusal"; return(record) }
  parsed <- tryCatch(jsonlite::fromJSON(record$raw, simplifyVector = FALSE), error = function(e) NULL)
  if (is.null(parsed)) { record$error <- "the answer is not JSON"; return(record) }
  record$parsed <- parsed; record$ok <- TRUE
  record
}

# Section 4.2.2: one call performed and parsed, with its latency
llm_call <- function(req) {
  started <- proc.time()[["elapsed"]]
  resp <- tryCatch(httr2::req_perform(req$request), error = function(e) e)
  llm_parse(req, resp, proc.time()[["elapsed"]] - started)
}

# Section 4.2.2, "one call per piece": several calls at once
llm_calls <- function(reqs) {
  if (!length(reqs)) return(list())
  started <- proc.time()[["elapsed"]]
  resps <- httr2::req_perform_parallel(lapply(reqs, `[[`, "request"), on_error = "continue", progress = FALSE)
  seconds <- proc.time()[["elapsed"]] - started
  Map(function(r, resp) llm_parse(r, if (is.null(resp)) simpleError("no response") else resp, seconds), reqs, resps)
}
