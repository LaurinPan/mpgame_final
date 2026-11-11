# 01_Engine/stage5_learning/parameters.R — A.5 "Neutral Value and Parameters": the gain, the horizon, the band and the trust parameters

# A.5, "Neutral Value and Parameters": the learning and word parameters added to the table
stage5_parameters <- function(k, H, band, sigma_R, b) {
  list(k = k, H = H, band = from_year(band), sigma_R = sigma_R, b = b)
}

# A.5, "Neutral Value and Parameters": the source set
stage5_source <- stage5_parameters(k = 0.13, H = 8, band = 4, sigma_R = 1.1, b = 1.5 / sqrt(8))

# A.5, "Neutral Value and Parameters": the game set
stage5_game   <- stage5_parameters(k = 0.13, H = 8, band = 4, sigma_R = 1.1, b = 1.5 / sqrt(8))
