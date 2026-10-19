#' This file is a walk through of the code presented in slides, but in a usable,
#' one-location context

# worked close form case study -------------------------------------------------
# mu_t <- 57 # treatment
# mu_c <- 50 # control

two_tailed_power <- function(mu_t, mu_c, std_dev, alpha, n) {
  effect_in_sd <- (abs(mu_t - mu_c) * sqrt(n)) / (2 * std_dev)
  critical_val <- qnorm(1 - (alpha / 2)) # phi ^{-1} is qnorm!
  power <- pnorm(effect_in_sd - critical_val)
  power
}

two_tailed_power(mu_t = 75, mu_c = 72, std_dev = 10, alpha = 0.05, n = 400)
