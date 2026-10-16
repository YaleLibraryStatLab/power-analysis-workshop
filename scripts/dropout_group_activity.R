#' Your Turn 3 (groups): the tutoring study with dropout
#'
#' Run the setup section first. Then work through the tasks with your group,
#' filling in each ___ and running each task before moving on.

set.seed(2026)


# Setup: functions from the slides ---------------------------------------------

simulate_power <- function(n_sims, generate, analyze, success) {
  hits <- replicate(n_sims, success(analyze(generate())))
  mean(hits) # proportion of successful runs = power
}

# 350 students, half tutored. The post-test correlates 0.6 with the pre-test.
gen_pretest <- function(n = 350, effect = 3, sd = 10, rho = 0.6) {
  treat <- rep(0:1, each = n / 2)
  pre <- rnorm(n, mean = 70, sd = sd)
  post <- 72 +
    rho * (pre - 70) +
    effect * treat +
    rnorm(n, mean = 0, sd = sd * sqrt(1 - rho^2))
  data.frame(treat, pre, post)
}

# The same study, but students with low scores, and control students, are more
# likely to drop out. About 23% of control and 11% of tutored students leave.
gen_dropout <- function(n = 350, effect = 3, sd = 10, rho = 0.6) {
  dat <- gen_pretest(n, effect, sd, rho)
  p_drop <- plogis(-2.2 + 0.7 * (dat$treat == 0) - 0.12 * (dat$post - 72))
  dat[runif(n) > p_drop, ] # we only observe the students who stayed
}

# Regression of post-test on treatment, adjusting for the pre-test
analyze_ancova <- function(dat) {
  summary(lm(post ~ treat + pre, data = dat))$coefficients["treat", ]
}

success_sig <- function(est) {
  est[["Pr(>|t|)"]] < 0.05 # did we reject the null?
}


# Task 1: Predict ---------------------------------------------------------------
#' Before running anything, agree as a group:
#'   - Will power with dropout be higher or lower than without it?
#'   - Will the average estimated effect be above or below the true value of 3?
#'     Why?


# Task 2: Power with and without dropout ---------------------------------------

simulate_power(2000, gen_pretest, analyze_ancova, success_sig) # no dropout
simulate_power(2000, ___, analyze_ancova, success_sig) # dropout


# Task 3: Is the estimate biased? ----------------------------------------------
#' Collect the estimated effect from 1,000 simulated studies with dropout.

estimates <- replicate(1000, analyze_ancova(___())[["Estimate"]])
mean(estimates) # the true effect is 3


# Task 4: A different definition of success ------------------------------------
#' Count a run as a success if the estimate is within 1.5 points of the true
#' effect, instead of p < 0.05.

success_close <- function(est) abs(est[["Estimate"]] - ___) < ___

simulate_power(2000, gen_pretest, analyze_ancova, success_close) # no dropout
simulate_power(2000, gen_dropout, analyze_ancova, success_close) # dropout


# Task 5 (if time): How many students are needed? ------------------------------

ns <- seq(150, 500, by = 50)
powers <- sapply(ns, \(n) {
  simulate_power(500, \() gen_dropout(n = n), analyze_ancova, success_sig)
})

plot(
  ns,
  powers,
  type = "b",
  pch = 19,
  ylim = c(0, 1),
  xlab = "Students enrolled (N)",
  ylab = "Simulated power"
)
abline(h = 0.8, lty = 2, col = "red")

#' Does enrolling more students remove the bias you found in Task 3?
