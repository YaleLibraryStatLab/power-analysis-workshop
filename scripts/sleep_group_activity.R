#' Your Turn 2 (groups): a sleep workshop on a budget
#'
#' Run the setup section first. Then work through the tasks with your group,
#' filling in each ___ and running each task before moving on.


# Setup -------------------------------------------------------------------------

# Power for a two-arm difference in means (the formula from the slides)
power_calc <- function(mu_t, mu_c, sigma, N, alpha = 0.05) {
  z <- abs(mu_t - mu_c) * sqrt(N) / (2 * sigma)
  cv <- qnorm(1 - alpha / 2)
  pnorm(z - cv) + pnorm(-z - cv) # both rejection tails
}

# From last year's tracker data (minutes of sleep per night)
mu_c <- 400
sigma <- 60

# Budget
cost_per_student <- 40
budget <- 12000


# Task 1: Discuss ---------------------------------------------------------------
#' Three sources disagree about the effect of the workshop:
#'   - a pilot with 20 students:                        +25 minutes
#'   - a meta-analysis of similar brief workshops:      +15 minutes
#'   - the office director's minimum worth acting on:   +10 minutes
#' Which would you trust most, and what is wrong with each one?


# Task 2: Sweep -----------------------------------------------------------------
#' Choose a range of N and the effect sizes (in minutes) to plan for.

grid <- expand.grid(
  N = seq(___, ___, by = 10),
  delta = c(___, ___, ___)
)
grid$power <- power_calc(
  mu_t = mu_c + grid$delta,
  mu_c = mu_c,
  sigma = sigma,
  N = grid$N
)

# Smallest N in the grid with 80% power, for each effect.
# Inf means no N in your grid reaches 80%: extend the grid.
sapply(unique(grid$delta), \(d) {
  min(grid$N[grid$delta == d & grid$power >= 0.80])
})

# Optional: plot power against N, one line per effect
plot(
  grid$N,
  grid$power,
  col = factor(grid$delta),
  pch = 19,
  cex = 0.4,
  ylim = c(0, 1),
  xlab = "Total students (N)",
  ylab = "Power"
)
abline(h = 0.80, lty = 2, col = "red")


# Task 3: Budget ----------------------------------------------------------------
#' How many students does the budget pay for, and what is the smallest effect
#' that N detects with 80% power?

n_budget <- ___ / ___
n_budget

mde <- (qnorm(0.975) + qnorm(0.80)) * 2 * sigma / sqrt(n_budget)
mde # minutes

#' Which of your effect sizes from Task 2 are at least this large?


# Task 4: Report ----------------------------------------------------------------
#' Write the sentence your group would put in a proposal:
#'   "With N = ___, the study has 80% power to detect effects of ___ minutes
#'    or larger."
