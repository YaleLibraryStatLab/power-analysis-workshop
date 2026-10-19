# =============================================================================
# Statistical Power --- workshop code (R)
# Yale Library | StatLab
#
# Every code block from presentation/R/statistical-power-r.qmd, in slide order.
# Runnable top to bottom:  Rscript scripts/power-analysis.R
# =============================================================================

library(ggplot2)


# -----------------------------------------------------------------------------
# What Power Looks Like
# -----------------------------------------------------------------------------
cv <- qnorm(0.975)
zz <- seq(-3.6, 6.2, length.out = 700)
dd <- rbind(
  data.frame(z = zz, y = dnorm(zz, 0),    curve = "If the null is true"),
  data.frame(z = zz, y = dnorm(zz, 2.24), curve = "If the 7-point effect is real"))

power_picture <- ggplot(dd, aes(z, y)) +
  geom_area(data = subset(dd, curve != "If the null is true" & z >= cv),
            fill = "#4A90C2", alpha = 0.55) +
  geom_area(data = subset(dd, curve == "If the null is true" & z >= cv),
            fill = "#B41E1E", alpha = 0.70) +
  geom_line(aes(colour = curve), linewidth = 0.75) +
  geom_vline(xintercept = cv, colour = "grey20", linewidth = 0.4, linetype = "dashed") +
  annotate("text", x = 3.6, y = 0.20, label = "power = 0.61",
           colour = "#0B2E52", size = 3.1, fontface = "bold") +
  annotate("text", x = 2.45, y = 0.045, label = "alpha/2 == 0.025", parse = TRUE,
           colour = "#B41E1E", size = 2.7, hjust = 0) +
  annotate("text", x = cv, y = 0.43, label = "reject to the right of 1.96",
           colour = "grey20", size = 2.7, hjust = -0.04) +
  scale_colour_manual(values = c("If the null is true" = "#B41E1E",
                                 "If the 7-point effect is real" = "#0B2E52"),
                      name = NULL) +
  # 1.96 and 2.24 nearly collide on the axis; drop the second label a row
  scale_x_continuous(breaks = c(0, cv, 2.24), labels = c("0", "1.96", "\n2.24")) +
  labs(x = "Effect, measured in standard errors", y = NULL) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_line(linewidth = 0.25, colour = "grey88"),
        axis.text.y = element_blank(),
        axis.title = element_text(colour = "grey30"),
        legend.position = "bottom", legend.margin = margin(t = -6))

print(power_picture)


# -----------------------------------------------------------------------------
# The Formula, in Code
#
#   power = Phi( |mu_t - mu_c| * sqrt(N) / (2 * sigma)  -  Phi^-1(1 - alpha/2) )
#
#   Phi = pnorm        Phi^-1 = qnorm
# -----------------------------------------------------------------------------
power_calc <- function(mu_t, mu_c, sigma, N, alpha = 0.05) {
  z  <- abs(mu_t - mu_c) * sqrt(N) / (2 * sigma)
  cv <- qnorm(1 - alpha / 2)
  pnorm(z - cv) + pnorm(-z - cv)     # both rejection tails
}

# The running example: 164 respondents, a 7-point effect, sigma = 20.
cat("\n-- running example --\n")
print(power_calc(mu_t = 57, mu_c = 50, sigma = 20, N = 164))   # 0.6107


# -----------------------------------------------------------------------------
# Power Across a Range of N
# -----------------------------------------------------------------------------
grid <- expand.grid(N     = seq(60, 1600, by = 10),
                    delta = c(3, 5, 7))

grid$power <- power_calc(mu_t  = 50 + grid$delta,
                         mu_c  = 50,
                         sigma = 20,
                         N     = grid$N)

cat("\n-- sweep, first rows --\n")
print(head(grid, 3))


# -----------------------------------------------------------------------------
# How Many Respondents Do We Need?
# -----------------------------------------------------------------------------
grid$delta <- factor(grid$delta, levels = c(3, 5, 7))
nstar <- data.frame(delta = factor(c(3, 5, 7), levels = c(3, 5, 7)))
nstar$N <- ceiling((2 * 20 * (qnorm(0.975) + qnorm(0.80)) / c(3, 5, 7))^2)
nstar$power <- 0.80
ramp <- c("3" = "#4A90C2", "5" = "#1F5F8B", "7" = "#0B2E52")

sweep_plot <- ggplot(grid, aes(N, power, colour = delta)) +
  geom_hline(yintercept = 0.80, linetype = "dashed",
             colour = "#B41E1E", linewidth = 0.4) +
  geom_line(linewidth = 0.85) +
  geom_point(data = nstar, size = 1.9, colour = "#B41E1E") +
  geom_text(data = nstar, aes(label = N), vjust = 1.9, hjust = -0.15,
            size = 3, colour = "#B41E1E", show.legend = FALSE) +
  scale_colour_manual(values = ramp, name = "Assumed effect (points):") +
  scale_y_continuous(limits = c(0, 1.05), breaks = seq(0, 1, 0.2)) +
  scale_x_continuous(breaks = seq(0, 1600, 200)) +
  labs(x = "Total respondents (N)", y = "Power") +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major = element_line(linewidth = 0.25, colour = "grey88"),
        axis.title = element_text(colour = "grey30"),
        legend.position = "bottom", legend.margin = margin(t = -4),
        legend.key.width = unit(16, "pt"),
        legend.title = element_text(colour = "grey30"))

print(sweep_plot)

cat("\n-- N needed for 80% power, by assumed effect --\n")
print(nstar[, c("delta", "N")])       # 1396, 503, 257


# -----------------------------------------------------------------------------
# Your Turn: Build the Sweep  (peer-mentoring / GPA)
# -----------------------------------------------------------------------------
cat("\n-- exercise: peer mentoring --\n")
grid <- expand.grid(N     = seq(50, 1000, by = 10),
                    delta = c(0.10, 0.15, 0.20))
grid$power <- power_calc(mu_t = 3.05 + grid$delta, mu_c = 3.05,
                         sigma = 0.45, N = grid$N)

for (d in unique(grid$delta)) {
  ok <- grid$N[grid$delta == d & grid$power >= 0.80]
  cat("effect", d, "GPA points -> N =", min(ok), "\n")
}


# -----------------------------------------------------------------------------
# Anatomy of One Simulation
# -----------------------------------------------------------------------------
cat("\n-- three single studies --\n")
set.seed(3)
one_study <- function() {
  z <- sample(rep(0:1, each = 82))             # RANDOMLY assign the message
  y <- rnorm(164, mean = 50 + 7 * z, sd = 20)  # ESTIMAND: the truth is 7
  coef(summary(lm(y ~ z)))["z", 4]             # ESTIMATOR: what you run
}

print(c(study_1 = one_study(), study_2 = one_study(), study_3 = one_study()))


# -----------------------------------------------------------------------------
# Building a Monte Carlo simulation for Power
# -----------------------------------------------------------------------------
sim_power <- function(N, tau, sigma, S = 2000) {
  mean(replicate(S, {
    z <- sample(rep(0:1, length.out = N))
    y <- rnorm(N, 50 + tau * z, sigma)  # the ESTIMAND
    coef(summary(lm(y ~ z)))["z", 4]    # the ESTIMATOR
  }) < 0.05)
}

cat("\n-- simulation vs closed form --\n")
set.seed(11)
print(c(simulation = sim_power(164, 7, 20),
        formula    = power_calc(57, 50, 20, 164)))


# -----------------------------------------------------------------------------
# Branch 1: Same Estimand, Better Estimator
# -----------------------------------------------------------------------------
sim_cov <- function(adjust, N = 164, S = 2000, tau = 7) {
  mean(replicate(S, {
    z <- sample(rep(0:1, length.out = N)); x <- rnorm(N)  # x = baseline
    y <- 50 + tau * z + 12 * x + rnorm(N, 0, 16) # cor(x, y) = 0.6
    fit <- if (adjust) lm(y ~ z + x) else lm(y ~ z)
    coef(summary(fit))["z", 4]
  }) < 0.05)
}

cat("\n-- precision covariate --\n")
set.seed(11)
print(c(unadjusted = sim_cov(FALSE), adjusted = sim_cov(TRUE)))


# -----------------------------------------------------------------------------
# The Smallest Effect the Regression Can See
# -----------------------------------------------------------------------------
cat("\n-- MDE by simulation, N = 164, adjusted estimator --\n")
set.seed(5)
taus <- 5:9                                    # candidate effects, in points
pw   <- sapply(taus, function(t) sim_cov(TRUE, S = 1000, tau = t))

mde <- function(p, tau, S = 1000, target = 0.80) {   # fit, then invert
  b <- coef(glm(cbind(round(p*S), S - round(p*S)) ~ log(tau), binomial))
  exp((qlogis(target) - b[[1]]) / b[[2]])
}
print(c(setNames(round(pw, 2), taus), MDE = round(mde(pw, taus), 2)))


# -----------------------------------------------------------------------------
# What If x Is a Confounder Instead?
# -----------------------------------------------------------------------------
cat("\n-- x as confounder (z NOT randomized) --\n")
set.seed(3)
sim_obs <- function(adjust, N = 164, S = 2000) {
  out <- replicate(S, {
    x <- rnorm(N); z <- rbinom(N, 1, plogis(1.2 * x))  # z DEPENDS on x
    y <- 50 + 7 * z + 12 * x + rnorm(N, 0, 16)         # truth is still 7
    fit <- if (adjust) lm(y ~ z + x) else lm(y ~ z)
    c(coef(fit)["z"], coef(summary(fit))["z", 4]) })
  c(estimate = mean(out[1, ]), rejection = mean(out[2, ] < 0.05)) }

obs <- rbind(`y ~ z` = sim_obs(FALSE), `y ~ z + x` = sim_obs(TRUE))
print(obs)
# The unadjusted model rejects ~100% of the time, but that is NOT power:
# its estimate is centred far above the true 7.


# -----------------------------------------------------------------------------
# Branch 2: Same Study, Different Estimand
# -----------------------------------------------------------------------------
cat("\n-- ATE vs interaction --\n")
set.seed(11)
p <- replicate(2000, {
  z <- sample(rep(0:1, each = 82)); g <- rep(0:1, 82)
  y <- rnorm(164, 50 + 4 * z + 6 * z * g + 2 * g, 20)
  c(ate = coef(summary(lm(y ~ z)))["z", 4],
    int = coef(summary(lm(y ~ z * g)))["z:g", 4])
})
print(rowMeans(p < 0.05))


# -----------------------------------------------------------------------------
# Your Turn: A Scaffold   (template --- fill in and un-comment)
# -----------------------------------------------------------------------------
# one_study <- function(N) {
#   z <- sample(rep(0:1, length.out = N))  # 1. ASSIGN: randomize treatment
#
#   y <- rnorm(N, mean = ???, sd = ???)    # 2. GENERATE: your ESTIMAND
#
#   coef(summary(lm(y ~ z)))["z", 4]       # 3. ANALYSE: your ESTIMATOR
# }
#
# power_for <- function(N, S = 1000) mean(replicate(S, one_study(N)) < 0.05)
#
# sapply(seq(100, 600, by = 50), power_for)


# -----------------------------------------------------------------------------
# Appendix: Two Loops, Not One   (outer = designs, inner = draws)
# -----------------------------------------------------------------------------
# grid <- expand.grid(N = seq(120, 300, by = 30),      # OUTER
#                     adjust = c(FALSE, TRUE))
# grid$power <- mapply(function(n, a) sim_cov(a, n),   # INNER runs inside
#                      grid$N, grid$adjust)


# -----------------------------------------------------------------------------
# Appendix: Sweeping the Simulation
# -----------------------------------------------------------------------------
cat("\n-- simulated power across N --\n")
set.seed(4); Ns <- seq(120, 300, by = 30)
sweep_sim <- data.frame(N = Ns,
  unadjusted = sapply(Ns, function(n) sim_cov(FALSE, n, S = 1500)),
  adjusted   = sapply(Ns, function(n) sim_cov(TRUE,  n, S = 1500)))
print(sweep_sim)


# -----------------------------------------------------------------------------
# Appendix: Finding the Cutoff by Simulation
# -----------------------------------------------------------------------------
long <- data.frame(
  N         = rep(sweep_sim$N, 2),
  power     = c(sweep_sim$unadjusted, sweep_sim$adjusted),
  estimator = rep(c("y ~ z", "y ~ z + x"), each = nrow(sweep_sim)))

sim_plot <- ggplot(long, aes(N, power, colour = estimator)) +
  geom_hline(yintercept = 0.80, linetype = "dashed", colour = "#B41E1E",
             linewidth = 0.4) +
  geom_line(linewidth = 0.8) + geom_point(size = 1.7) +
  scale_colour_manual(values = c("y ~ z" = "#4A90C2", "y ~ z + x" = "#0B2E52"),
                      name = NULL) +
  scale_y_continuous(limits = c(0.4, 1), breaks = seq(0.4, 1, 0.2)) +
  labs(x = "Total respondents (N)", y = "Simulated power") +
  theme_minimal(base_size = 8) +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major = element_line(linewidth = 0.25, colour = "grey88"),
        axis.title = element_text(colour = "grey30"),
        legend.position = "right", legend.key.width = unit(14, "pt"),
        plot.margin = margin(2, 2, 2, 2))

print(sim_plot)

# Do NOT run approx() straight over simulated power: noise makes the curve
# non-monotone, and approx() warns rather than errors. Fit a curve and invert.
cutoff <- function(p, N, S = 1500, target = 0.80) {   # fit, then invert
  b <- coef(glm(cbind(round(p*S), S - round(p*S)) ~ log(N), binomial))
  exp((qlogis(target) - b[1]) / b[2])
}

cat("\n-- N at 80% power, read off the simulation --\n")
print(round(c(adjusted   = cutoff(sweep_sim$adjusted,   sweep_sim$N),
              unadjusted = cutoff(sweep_sim$unadjusted, sweep_sim$N))))


# -----------------------------------------------------------------------------
# Appendix: Clustering in Simulation
# -----------------------------------------------------------------------------
cat("\n-- clustered assignment, analysed two ways --\n")
set.seed(7)
n_clus <- 12; m <- 25                  # 300 students in 12 classrooms
sb <- 0.45 * sqrt(0.15); sw <- 0.45 * sqrt(0.85)
p <- replicate(1500, {
  zc <- sample(rep(0:1, each = n_clus / 2))  # assign CLASSROOMS, not students
  u  <- rnorm(n_clus, 0, sb)           # classroom-level shock
  y  <- rnorm(n_clus * m, rep(3.05 + 0.15 * zc + u, each = m), sw)
  id <- rep(1:n_clus, each = m)
  c(as_individuals = t.test(y ~ rep(zc, each = m))$p.value,
    as_clusters    = t.test(tapply(y, id, mean) ~ zc)$p.value)
})
print(rowMeans(p < 0.05))
