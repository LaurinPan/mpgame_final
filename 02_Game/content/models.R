# 02_Game/content/models.R — Section 4.2.2: the model, effort, token limit, time limit and retries of each call

# Section 4.2.2: the models by task; a token limit leaves room for the thinking the model does before some answers; a call past its time limit counts as failed, is retried once and then falls to its template; comparison names the model the pieces are also recorded with for test 05, and thinking_off the models whose calls switch reasoning off
models <- list(
  pieces           = "claude-sonnet-5-5",
  chat             = "claude-sonnet-5-5",
  debrief          = "claude-sonnet-5-5",
  comparison       = "claude-haiku-5-5",
  thinking_off     = "claude-haiku-5-5",
  effort           = list(pieces = "low", chat = "low", debrief = "high"),
  max_tokens       = list(pieces = 4000, chat = 3000, debrief = 16000),
  endpoint         = "https://api.anthropic.com/v1/messages",
  api_version      = "2026-10-21",
  retries          = 1,
  timeout_seconds  = list(pieces = 60, chat = 60, debrief = 120))
