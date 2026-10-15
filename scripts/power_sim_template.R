#'  Welcome to the "Build it on your own"!!
#'
#' Fill in every ___ as you go, working from top to bottom and running each
#' step before moving on. Every step ends with a little check, so you'll know
#' right away if there's a mistake hiding
#'
#' No study of your own in mind? Use the tutoring study from the
#' workshop with some new components. Maybe try asking about GPAs and
#' choose some values you think you'd like.

set.seed(2026)

# here's a copy of our nice simple function
simulate_power <- function(n_sims, generate, analyze, success) {
  hits <- replicate(n_sims, success(analyze(generate())))
  mean(hits) # proportion of successful runs = power
}


#' Step 1: Describe your study -------------------------------------------------
# These are your educated guesses

baseline <- ___ # average outcome in the control group
true_effect <- ___ # the effect you hope to detect (treatment minus control)
noise_sd <- ___ # how much the outcome varies from subject to subject
n_start <- ___ # a total sample size to try first


#' Step 2: generate() ----------------------------------------------------------
#' Make ONE fake data set that looks like your study. This is the model
#'   y_i = baseline + effect * T_i + noise_i,   noise_i ~ N(0, noise_sd^2)
#' written out as a code-based version of the linear predictor. keep it simple
#' for now!
generate <- function(n = n_start, effect = true_effect) {
  treat <- rep(0:1, length.out = n)
  y <- ___ + ___ * treat + rnorm(n, mean = 0, sd = ___)
  data.frame(treat, y)
}

# DOUBLE CHECK: does thislook like something your study could produce?
dat <- generate()
head(dat)
tapply(dat$y, dat$treat, mean) # check group means: roughly what you expected?


#' Step 3: analyze() -----------------------------------------------------------
#' Run the analysis you would run on your real data! (The slides used lm() but
#' a t-test or anything else works too, as long as success() below knows how to
#' read what analyze() return
analyze <- function(dat) {
  fit <- ___(y ~ treat, data = dat)
  summary(fit)$coefficients["treat", ] # estimate, SE, t value, p value
}

# Check again!!
analyze(generate())


#' Step 4: success() -----------------------------------------------------------
#' What counts as "recovering" the effect in ONE run? Return TRUE or FALSE.
#' Some options are in the slides in terms of other versions of success!
success <- function(est) {
  ___
}

# check once more!!!
success(analyze(generate()))


#' Step 5: Estimate power ------------------------------------------------------
#' Start with a small number of simulations so it runs quickly
simulate_power(n_sims = ___, generate, analyze, success)

# check!! if there is NO effect, a significance-based success() should
# succeed about 5% of the time. That's alpha! Is yours close to that??
simulate_power(n_sims = 1000, \() generate(effect = 0), analyze, success)


#' Step 6: How many subjects do you need? --------------------------------------
#' try a grid of sample sizes and see where power crosses your target

ns <- seq(___, ___, by = ___) # a range of total sample sizes to try

powers <- sapply(ns, \(n) {
  simulate_power(500, \() generate(n = n), analyze, success)
})

plot(
  ns,
  powers,
  type = "b",
  pch = 19,
  ylim = c(0, 1),
  xlab = "Total sample size (N)",
  ylab = "Simulated power"
)
abline(h = 0.8, lty = 2, col = "red")

ns[powers >= 0.8][1] # smallest N in your grid that reaches 80%
#' NOTE: Simulated power is a little noisy, so treat this as approximately N

#' Step 7:Add something in -----------------------------------------------------
#' Your actual study is probably messier than step 2, so pick a single
#' complication, make a new generate() function, and re-run the next steps with
#' your new function! How much power do you lose or gain?
