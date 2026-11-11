# app.R — the Monetary Policy Game. The backend's loader sources 01_Engine/ and 02_Game/, and 02_Game/ui/
# with them; the page and the server are 02_Game/ui/server.R's. On a laptop: shiny::runApp() from this folder, each account's password
# in ~/.Renviron under the name 02_Game/ui/users.yaml gives it (MPGAME_PASSWORD_DEV_1_FINAL and so on); on Posit Connect Cloud the
# same file runs, the secrets in the content's settings.
for (f in list.files(c("01_Engine", "02_Game"), pattern = "[.]R$", recursive = TRUE, full.names = TRUE)) source(f)
# the next quarter's paper, the reference bank and the debrief in one worker at the lowest priority, unless
# 02_Game/ui/params.R's bank$background is FALSE; without the worker the close runs them inline
if (isTRUE(ui_params$bank$background) && requireNamespace("mirai", quietly = TRUE) && !mirai::daemons_set()) tryCatch({
  mirai::daemons(1)
  mirai::everywhere({ setwd(dir); tools::psnice(value = 19L); for (f in list.files(c("01_Engine", "02_Game"), pattern = "[.]R$", recursive = TRUE, full.names = TRUE)) source(f) }, dir = getwd())
  shiny::onStop(function() mirai::daemons(0))
}, error = function(e) { message("MPGAME no background worker: ", conditionMessage(e)); try(mirai::daemons(0), silent = TRUE) })
# the page's styles and scripts, served from 02_Game/web (in the working folder Shiny serves its www/ folder itself)
shiny::addResourcePath("web", "02_Game/web")
shiny::shinyApp(ui_app_ui(), ui_server)
