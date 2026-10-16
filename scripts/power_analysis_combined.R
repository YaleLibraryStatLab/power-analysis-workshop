# =============================================================================
# Statistical Power --- workshop code (R)
# Yale Library | StatLab
#
# The code from presentation/R/statistical-power-combined-t.qmd, in slide order,
# including the solutions to the group activities and the appendix.
# Runnable top to bottom:  Rscript scripts/power_analysis_combined.R
# =============================================================================

library(ggplot2)


# -----------------------------------------------------------------------------
# The Formula, in Code
#
#   power = Phi( |mu_t - mu_c| * sqrt(N) / (2 * sigma)  -  Phi^-1(1 - alpha/2) )
#
#   Phi = pnorm        Phi^-1 = qnorm
# -----------------------------------------------------------------------------

power_calc <- function(mu_t, mu_c, sigma, N, alpha = 0.05) {
  z <- abs(mu_t - mu_c) * sqrt(N) / (2 * sigma)
  cv <- qnorm(1 - alpha / 2)
  pnorm(z - cv) + pnorm(-z - cv) # both rejection tails
}

# The running example: 164 respondents, a 7-point effect, sigma = 20
power_calc(mu_t = 57, mu_c = 50, sigma = 20, N = 164)

# Your Turn 1: the tutoring study, 400 students, 3-point effect, sigma = 10
power_calc(mu_t = 75, mu_c = 72, sigma = 10, N = 400)


# -----------------------------------------------------------------------------
# The Smallest Effect This Study Can Detect
# -----------------------------------------------------------------------------

mde_calc <- function(sigma, N, alpha = 0.05, power = 0.80) {
  (qnorm(1 - alpha / 2) + qnorm(power)) * 2 * sigma / sqrt(N)
}

mde_calc(sigma = 20, N = c(164, 257, 400, 800, 1396))

# Solved for N instead
n_required <- function(delta, sigma, alpha = 0.05, power = 0.80) {
  ceiling(4 * sigma^2 * (qnorm(1 - alpha / 2) + qnorm(power))^2 / delta^2)
}

n_required(delta = c(3, 5, 7), sigma = 20)


# -----------------------------------------------------------------------------
# Power Across a Range of N
# -----------------------------------------------------------------------------

grid <- expand.grid(N = seq(60, 1600, by = 10), delta = c(3, 5, 7))

grid$power <- power_calc(
  mu_t = 50 + grid$delta,
  mu_c = 50,
  sigma = 20,
  N = grid$N
)

head(grid, 3)


# -----------------------------------------------------------------------------
# How Many Respondents Do We Need?
# -----------------------------------------------------------------------------

grid$delta <- factor(grid$delta, levels = c(3, 5, 7))
nstar <- data.frame(
  delta = factor(c(3, 5, 7), levels = c(3, 5, 7)),
  N = n_required(delta = c(3, 5, 7), sigma = 20),
  power = 0.80
)

ggplot(grid, aes(N, power, colour = delta)) +
  geom_hline(yintercept = 0.80, linetype = "dashed", colour = "#B41E1E") +
  geom_line(linewidth = 0.85) +
  geom_point(data = nstar, size = 1.9, colour = "#B41E1E") +
  geom_text(
    data = nstar,
    aes(label = N),
    vjust = 1.9,
    hjust = -0.15,
    colour = "#B41E1E",
    show.legend = FALSE
  ) +
  scale_y_continuous(limits = c(0, 1.05), breaks = seq(0, 1, 0.2)) +
  labs(
    x = "Total respondents (N)",
    y = "Power",
    colour = "Assumed effect (points):"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")


# -----------------------------------------------------------------------------
# Your Turn 2 (groups): A Sleep Workshop on a Budget --- one solution
# -----------------------------------------------------------------------------

grid <- expand.grid(N = seq(50, 1500, by = 10), delta = c(10, 15, 25))
grid$power <- power_calc(400 + grid$delta, 400, sigma = 60, N = grid$N)

# smallest N with 80% power, for effects of 10, 15, and 25 minutes
sapply(c(10, 15, 25), \(d) min(grid$N[grid$delta == d & grid$power >= 0.8]))

mde_calc(sigma = 60, N = 12000 / 40) # what the budget can detect


# -----------------------------------------------------------------------------
# Monte Carlo Simulation: Simulating the Spins
# -----------------------------------------------------------------------------

set.seed(2026)
spins <- matrix(runif(3 * 100000) < 18 / 38, ncol = 3) # each row is 3 spins
mean(rowSums(spins) == 3) # proportion of rows where all three are red
(18 / 38)^3 # the exact answer


# -----------------------------------------------------------------------------
# The Simulation Recipe
# -----------------------------------------------------------------------------

simulate_power <- function(n_sims, generate, analyze, success) {
  hits <- replicate(n_sims, success(analyze(generate())))
  mean(hits) # proportion of successful runs = power
}


# -----------------------------------------------------------------------------
# Generating Data for the Tutoring Study
# -----------------------------------------------------------------------------

gen_basic <- function(n = 350, effect = 3, sd = 10) {
  treat <- rep(0:1, each = n / 2) # half control, half tutored
  post <- 72 + effect * treat + rnorm(n, mean = 0, sd = sd)
  data.frame(treat, post)
}

head(gen_basic(), 3)


# -----------------------------------------------------------------------------
# Analyzing It and Defining Success
# -----------------------------------------------------------------------------

analyze_lm <- function(dat) {
  fit <- lm(post ~ treat, data = dat) # same as an equal-variance t-test
  summary(fit)$coefficients["treat", ] # estimate, SE, t, p for treat
}

success_sig <- function(est) {
  est[["Pr(>|t|)"]] < 0.05 # did we reject the null?
}

analyze_lm(gen_basic())


# -----------------------------------------------------------------------------
# Does the Simulation Agree with the Formula?
# -----------------------------------------------------------------------------

set.seed(2026)
simulate_power(
  n_sims = 2000,
  generate = gen_basic,
  analyze = analyze_lm,
  success = success_sig
)
power_calc(mu_t = 75, mu_c = 72, sigma = 10, N = 350) # the formula

sqrt(0.80 * (1 - 0.80) / 2000) # Monte Carlo standard error at power 0.80


# -----------------------------------------------------------------------------
# Adding a Pre-Test
# -----------------------------------------------------------------------------

gen_pretest <- function(n = 350, effect = 3, sd = 10, rho = 0.6) {
  treat <- rep(0:1, each = n / 2)
  pre <- rnorm(n, mean = 70, sd = sd)
  post <- 72 +
    rho * (pre - 70) +
    effect * treat +
    rnorm(n, mean = 0, sd = sd * sqrt(1 - rho^2))
  data.frame(treat, pre, post)
}

analyze_ancova <- function(dat) {
  summary(lm(post ~ treat + pre, data = dat))$coefficients["treat", ]
}

set.seed(2026)
simulate_power(2000, gen_pretest, analyze_lm, success_sig) # no pre-test
simulate_power(2000, gen_pretest, analyze_ancova, success_sig) # pre-test


# -----------------------------------------------------------------------------
# Your Turn 3 (groups): The Tutoring Study with Dropout --- solutions
# -----------------------------------------------------------------------------

gen_dropout <- function(n = 350, effect = 3, sd = 10, rho = 0.6) {
  dat <- gen_pretest(n, effect, sd, rho)
  p_drop <- plogis(-2.2 + 0.7 * (dat$treat == 0) - 0.12 * (dat$post - 72))
  dat[runif(n) > p_drop, ] # we only observe the students who stayed
}

nrow(gen_dropout()) # out of the 350 we enrolled

# Power and bias
set.seed(2026)
simulate_power(2000, gen_dropout, analyze_ancova, success_sig)
estimates <- replicate(2000, analyze_ancova(gen_dropout())[["Estimate"]])
mean(estimates) # the true effect is 3

# Other definitions of success
success_close <- function(est) abs(est[["Estimate"]] - 3) < 1.5

set.seed(2026)
simulate_power(2000, gen_pretest, analyze_ancova, success_close) # no dropout
simulate_power(2000, gen_dropout, analyze_ancova, success_close) # dropout

# How many students?
set.seed(2026)
ns <- seq(150, 500, by = 50)
powers <- sapply(ns, \(n) {
  simulate_power(
    1000,
    generate = \() gen_dropout(n = n),
    analyze = analyze_ancova,
    success = success_sig
  )
})

ggplot(data.frame(N = ns, power = powers), aes(N, power)) +
  geom_hline(yintercept = 0.80, linetype = "dashed", colour = "#B41E1E") +
  geom_line(colour = "#0B2E52") +
  geom_point(colour = "#0B2E52") +
  scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
  labs(x = "Students enrolled (N)", y = "Simulated power") +
  theme_minimal()


# -----------------------------------------------------------------------------
# Appendix: Power for an Interaction
# -----------------------------------------------------------------------------

set.seed(11)
p <- replicate(2000, {
  z <- sample(rep(0:1, each = 82))
  g <- rep(0:1, 82)
  y <- rnorm(164, 50 + 4 * z + 6 * z * g + 2 * g, 20)
  c(
    ate = coef(summary(lm(y ~ z)))["z", 4],
    int = coef(summary(lm(y ~ z * g)))["z:g", 4]
  )
})
rowMeans(p < 0.05) # N = 164


# -----------------------------------------------------------------------------
# Appendix: What If x Is a Confounder?
# -----------------------------------------------------------------------------

set.seed(3)
sim_obs <- function(adjust, N = 164) {
  out <- replicate(2000, {
    x <- rnorm(N)
    z <- rbinom(N, 1, plogis(1.2 * x)) # z DEPENDS on x
    y <- 50 + 7 * z + 12 * x + rnorm(N, 0, 16) # truth is still 7
    fit <- if (adjust) lm(y ~ z + x) else lm(y ~ z)
    c(coef(fit)["z"], coef(summary(fit))["z", 4])
  })
  c(estimate = mean(out[1, ]), rejection = mean(out[2, ] < 0.05))
}
rbind(`y ~ z` = sim_obs(FALSE), `y ~ z + x` = sim_obs(TRUE))


# -----------------------------------------------------------------------------
# Appendix: When You Randomize Groups, Not People
# -----------------------------------------------------------------------------

deff <- 1 + (25 - 1) * 0.15 # groups of 25, intra-cluster correlation 0.15
ceiling(n_required(delta = 7, sigma = 20) * deff)


# -----------------------------------------------------------------------------
# Appendix: Clustering in Simulation
# -----------------------------------------------------------------------------

set.seed(7)
sim_clus <- function(tau, k = 12, m = 25) {
  rowMeans(
    replicate(1500, {
      zc <- sample(rep(0:1, each = k / 2)) # assign GROUPS, not people
      u <- rnorm(k, 0, 20 * sqrt(0.15)) # group-level shock
      y <- rnorm(k * m, rep(50 + tau * zc + u, each = m), 20 * sqrt(0.85))
      c(
        as_individuals = t.test(y ~ rep(zc, each = m))$p.value,
        as_groups = t.test(tapply(y, rep(1:k, each = m), mean) ~ zc)$p.value
      )
    }) <
      0.05
  )
}
rbind(`no effect` = sim_clus(0), `7-point effect` = sim_clus(7))
