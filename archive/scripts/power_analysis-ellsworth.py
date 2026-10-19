"""
=============================================================================
Statistical Power --- workshop code (Python)
Yale Library | StatLab

Every code block from presentation/python/statistical-power-python.qmd, in slide
order. Runnable top to bottom:  python scripts/power_analysis.py

Requires: numpy, pandas, scipy, matplotlib, statsmodels
=============================================================================
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy.stats import norm, ttest_ind
from scipy.special import expit, logit
import statsmodels.api as sm
import statsmodels.formula.api as smf

pd.set_option("display.width", 88)
plt.rcParams.update({"font.family": "serif", "figure.dpi": 150,
                     "savefig.bbox": "tight", "axes.edgecolor": "0.75"})


def minimal(ax, xgrid=True, ygrid=True):
    """Approximate ggplot2's theme_minimal()."""
    for s in ax.spines.values():
        s.set_visible(False)
    ax.set_facecolor("white")
    ax.tick_params(length=0, colors="0.3")
    if xgrid:
        ax.xaxis.grid(True, lw=0.35, color="0.88")
    if ygrid:
        ax.yaxis.grid(True, lw=0.35, color="0.88")
    ax.set_axisbelow(True)


# -----------------------------------------------------------------------------
# What Power Looks Like
# -----------------------------------------------------------------------------
cv = norm.ppf(0.975)
zz = np.linspace(-3.6, 6.2, 700)
null, alt = norm.pdf(zz, 0), norm.pdf(zz, 2.24)

fig, ax = plt.subplots(figsize=(7.6, 2.4))
tail = zz >= cv
ax.fill_between(zz[tail], alt[tail],  color="#4A90C2", alpha=0.55, lw=0)
ax.fill_between(zz[tail], null[tail], color="#B41E1E", alpha=0.70, lw=0)
ax.plot(zz, null, color="#B41E1E", lw=1.0, label="If the null is true")
ax.plot(zz, alt,  color="#0B2E52", lw=1.0, label="If the 7-point effect is real")
ax.axvline(cv, color="0.2", lw=0.5, ls=(0, (4, 3)))

ax.text(3.6,  0.20,  "power = 0.61", color="#0B2E52", fontsize=8.5,
        fontweight="bold", ha="center")
ax.text(2.45, 0.045, r"$\alpha/2 = 0.025$", color="#B41E1E", fontsize=7.5)
ax.text(cv + 0.07, 0.43, "reject to the right of 1.96", color="0.2", fontsize=7.5)

ax.set_xticks([0, cv, 2.24])
ax.set_xticklabels(["0", "1.96", "\n2.24"])   # drop 2.24 a row; they nearly collide
ax.set_yticks([]); ax.set_ylim(0, 0.47)
ax.set_xlabel("Effect, measured in standard errors", color="0.3", fontsize=8.5)
minimal(ax, ygrid=False)
ax.legend(loc="upper center", bbox_to_anchor=(0.5, -0.22), ncol=2,
          frameon=False, fontsize=8)
plt.show()


# -----------------------------------------------------------------------------
# The Formula, in Code
#
#   power = Phi( |mu_t - mu_c| * sqrt(N) / (2 * sigma)  -  Phi^-1(1 - alpha/2) )
#
#   Phi = norm.cdf     Phi^-1 = norm.ppf
# -----------------------------------------------------------------------------
def power_calc(mu_t, mu_c, sigma, N, alpha=0.05):
    z  = np.abs(mu_t - mu_c) * np.sqrt(N) / (2 * sigma)
    cv = norm.ppf(1 - alpha / 2)
    return norm.cdf(z - cv) + norm.cdf(-z - cv)   # both rejection tails


# The running example: 164 respondents, a 7-point effect, sigma = 20.
print("\n-- running example --")
print(power_calc(mu_t=57, mu_c=50, sigma=20, N=164))   # 0.6107


# -----------------------------------------------------------------------------
# Power Across a Range of N
# -----------------------------------------------------------------------------
grid = pd.merge(pd.DataFrame({"N":     np.arange(60, 1601, 10)}),
                pd.DataFrame({"delta": [3, 5, 7]}), how="cross")

grid["power"] = power_calc(mu_t  = 50 + grid["delta"],
                           mu_c  = 50,
                           sigma = 20,
                           N     = grid["N"])

print("\n-- sweep, first rows --")
print(grid.head(3))


# -----------------------------------------------------------------------------
# How Many Respondents Do We Need?
# -----------------------------------------------------------------------------
nstar = pd.DataFrame({"delta": [3, 5, 7]})
nstar["N"] = np.ceil((2 * 20 * (norm.ppf(0.975) + norm.ppf(0.80))
                      / nstar["delta"]) ** 2).astype(int)
ramp = {3: "#4A90C2", 5: "#1F5F8B", 7: "#0B2E52"}

fig, ax = plt.subplots(figsize=(7.6, 2.6))
ax.axhline(0.80, ls=(0, (4, 3)), color="#B41E1E", lw=0.5)
for d in (3, 5, 7):
    s = grid[grid["delta"] == d]
    ax.plot(s["N"], s["power"], color=ramp[d], lw=1.1, label=str(d))
ax.scatter(nstar["N"], [0.80] * 3, s=14, color="#B41E1E", zorder=3)
for _, r in nstar.iterrows():
    ax.annotate(r["N"], (r["N"], 0.80), textcoords="offset points",
                xytext=(5, -12), color="#B41E1E", fontsize=7.5)

ax.set_xticks(np.arange(0, 1601, 200))
ax.set_yticks(np.arange(0, 1.01, 0.2)); ax.set_ylim(0, 1.05)
ax.set_xlabel("Total respondents (N)", color="0.3", fontsize=9)
ax.set_ylabel("Power", color="0.3", fontsize=9)
minimal(ax)
ax.legend(title="Assumed effect (points):", loc="upper center",
          bbox_to_anchor=(0.5, -0.20), ncol=3, frameon=False,
          fontsize=8, title_fontsize=8)
plt.show()

print("\n-- N needed for 80% power, by assumed effect --")
print(nstar.to_string(index=False))       # 1396, 503, 257


# -----------------------------------------------------------------------------
# Your Turn: Build the Sweep  (peer-mentoring / GPA)
# -----------------------------------------------------------------------------
print("\n-- exercise: peer mentoring --")
grid = pd.merge(pd.DataFrame({"N":     np.arange(50, 1001, 10)}),
                pd.DataFrame({"delta": [0.10, 0.15, 0.20]}), how="cross")
grid["power"] = power_calc(mu_t = 3.05 + grid["delta"], mu_c = 3.05,
                           sigma = 0.45, N = grid["N"])

for d in grid["delta"].unique():
    ok = grid.loc[(grid["delta"] == d) & (grid["power"] >= 0.80), "N"]
    print("effect", d, "GPA points -> N =", ok.min())


# -----------------------------------------------------------------------------
# Anatomy of One Simulation
# -----------------------------------------------------------------------------
print("\n-- three single studies --")
rng = np.random.default_rng(26)


def ols(formula, **cols):   # R's lm() reads from the calling frame; statsmodels
    return smf.ols(formula, pd.DataFrame(cols)).fit()      # wants a DataFrame


def one_study():
    z = rng.permutation(np.repeat([0, 1], 82))  # RANDOMLY assign the message
    y = rng.normal(50 + 7 * z, 20)              # ESTIMAND: the truth is 7
    return ols("y ~ z", y=y, z=z).pvalues["z"]  # ESTIMATOR: what you run


print([round(one_study(), 4) for _ in range(3)])


# -----------------------------------------------------------------------------
# Building a Monte Carlo simulation for Power
# -----------------------------------------------------------------------------
def sim_power(N, tau, sigma, S=2000):
    p = np.empty(S)
    for i in range(S):
        z = rng.permutation(np.resize([0, 1], N))
        y = rng.normal(50 + tau * z, sigma)         # the ESTIMAND
        p[i] = ols("y ~ z", y=y, z=z).pvalues["z"]  # the ESTIMATOR
    return np.mean(p < 0.05)


print("\n-- simulation vs closed form --")
rng = np.random.default_rng(11)
print(pd.Series({"simulation": sim_power(164, 7, 20),
                 "formula":    power_calc(57, 50, 20, 164)}).round(4))


# -----------------------------------------------------------------------------
# Branch 1: Same Estimand, Better Estimator
# -----------------------------------------------------------------------------
def sim_cov(adjust, N=164, S=2000, tau=7):
    p = np.empty(S)
    for i in range(S):
        z = rng.permutation(np.resize([0, 1], N)); x = rng.normal(0, 1, N)  # x = baseline
        y = 50 + tau * z + 12 * x + rng.normal(0, 16, N)      # cor(x, y) = 0.6
        p[i] = ols("y ~ z + x" if adjust else "y ~ z",
                   y=y, z=z, x=x).pvalues["z"]
    return np.mean(p < 0.05)


print("\n-- precision covariate --")
rng = np.random.default_rng(11)
print(pd.Series({"unadjusted": sim_cov(False), "adjusted": sim_cov(True)}))


# -----------------------------------------------------------------------------
# The Smallest Effect the Regression Can See
# -----------------------------------------------------------------------------
print("\n-- MDE by simulation, N = 164, adjusted estimator --")
rng = np.random.default_rng(5); taus = np.arange(5, 10)   # candidate effects
pw   = np.array([sim_cov(True, S=1000, tau=t) for t in taus])


def mde(p, tau, S=1000, target=0.80):                # fit, then invert
    succ = np.round(np.asarray(p) * S)
    X = sm.add_constant(np.log(np.asarray(tau, float)))
    b = sm.GLM(np.column_stack([succ, S - succ]), X,
               family=sm.families.Binomial()).fit().params
    return np.exp((logit(target) - b[0]) / b[1])


print(pd.DataFrame([dict(zip(taus, pw.round(2)),
                         MDE=round(mde(pw, taus), 2))]).to_string(index=False))


# -----------------------------------------------------------------------------
# What If x Is a Confounder Instead?
# -----------------------------------------------------------------------------
print("\n-- x as confounder (z NOT randomized) --")
rng = np.random.default_rng(3)


def sim_obs(adjust, N=164, S=2000):
    est, pv = np.empty(S), np.empty(S)
    for i in range(S):
        x = rng.normal(0, 1, N); z = rng.binomial(1, expit(1.2 * x))  # z DEPENDS on x
        y = 50 + 7 * z + 12 * x + rng.normal(0, 16, N)                # truth is still 7
        f = ols("y ~ z + x" if adjust else "y ~ z", y=y, z=z, x=x)
        est[i], pv[i] = f.params["z"], f.pvalues["z"]
    return est.mean(), np.mean(pv < 0.05)


obs = pd.DataFrame([sim_obs(False), sim_obs(True)], columns=["estimate", "rejection"],
                   index=["y ~ z", "y ~ z + x"])
print(obs.round(3).to_string())
# The unadjusted model rejects ~100% of the time, but that is NOT power:
# its estimate is centred far above the true 7.


# -----------------------------------------------------------------------------
# Branch 2: Same Study, Different Estimand
# -----------------------------------------------------------------------------
print("\n-- ATE vs interaction --")
rng = np.random.default_rng(11)
ate, inter = np.empty(2000), np.empty(2000)
for i in range(2000):
    z = rng.permutation(np.repeat([0, 1], 82)); g = np.tile([0, 1], 82)
    y = rng.normal(50 + 4 * z + 6 * z * g + 2 * g, 20)
    ate[i]   = ols("y ~ z",     y=y, z=z, g=g).pvalues["z"]
    inter[i] = ols("y ~ z * g", y=y, z=z, g=g).pvalues["z:g"]

print(pd.Series({"ate": np.mean(ate < 0.05), "int": np.mean(inter < 0.05)}))


# -----------------------------------------------------------------------------
# Your Turn: A Scaffold   (template --- fill in and un-comment)
# -----------------------------------------------------------------------------
# def one_study(N):
#     z = rng.permutation(np.resize([0, 1], N))  # 1. ASSIGN: randomize treatment
#
#     y = rng.normal(???, ???, N)                # 2. GENERATE: your ESTIMAND
#
#     return ols("y ~ z", y=y, z=z).pvalues["z"] # 3. ANALYSE: your ESTIMATOR
#
# def power_for(N, S=1000):
#     return np.mean(np.array([one_study(N) for _ in range(S)]) < 0.05)
#
# [power_for(N) for N in range(100, 601, 50)]


# -----------------------------------------------------------------------------
# Appendix: Two Loops, Not One   (outer = designs, inner = draws)
# -----------------------------------------------------------------------------
# grid = pd.merge(pd.DataFrame({"N": np.arange(120, 301, 30)}),      # OUTER
#                 pd.DataFrame({"adjust": [False, True]}), how="cross")
# grid["power"] = [sim_cov(a, n)                                     # INNER
#                  for n, a in zip(grid["N"], grid["adjust"])]


# -----------------------------------------------------------------------------
# Appendix: Sweeping the Simulation
# -----------------------------------------------------------------------------
print("\n-- simulated power across N --")
rng = np.random.default_rng(4); Ns = np.arange(120, 301, 30)
sweep_sim = pd.DataFrame({"N": Ns,
    "unadjusted": [sim_cov(False, n, S=1500) for n in Ns],
    "adjusted":   [sim_cov(True,  n, S=1500) for n in Ns]})
print(sweep_sim.round(3).to_string(index=False))


# -----------------------------------------------------------------------------
# Appendix: Finding the Cutoff by Simulation
# -----------------------------------------------------------------------------
fig, ax = plt.subplots(figsize=(7.6, 0.78))
ax.axhline(0.80, ls=(0, (4, 3)), color="#B41E1E", lw=0.5)
for col, c in [("unadjusted", "#4A90C2"), ("adjusted", "#0B2E52")]:
    lab = "y ~ z" if col == "unadjusted" else "y ~ z + x"
    ax.plot(sweep_sim["N"], sweep_sim[col], color=c, lw=1.0, marker="o",
            ms=2.6, label=lab)
ax.set_yticks(np.arange(0.4, 1.01, 0.2)); ax.set_ylim(0.4, 1.0)
ax.set_xlabel("Total respondents (N)", color="0.3", fontsize=7)
ax.set_ylabel("Simulated power", color="0.3", fontsize=7)
ax.tick_params(labelsize=6.5)
minimal(ax)
ax.legend(loc="center left", bbox_to_anchor=(1.01, 0.5), frameon=False, fontsize=7)
plt.show()


# Do NOT run np.interp() over simulated power: it assumes x increases, and
# noise breaks that silently. Fit a monotone curve and invert that.
def cutoff(p, N, S=1500, target=0.80):        # fit, then invert
    succ = np.round(np.asarray(p) * S)
    X = sm.add_constant(np.log(np.asarray(N, float)))
    b = sm.GLM(np.column_stack([succ, S - succ]), X,
               family=sm.families.Binomial()).fit().params
    return np.exp((logit(target) - b[0]) / b[1])


print("\n-- N at 80% power, read off the simulation --")
print({"adjusted":   round(cutoff(sweep_sim["adjusted"],   sweep_sim["N"])),
       "unadjusted": round(cutoff(sweep_sim["unadjusted"], sweep_sim["N"]))})


# -----------------------------------------------------------------------------
# Appendix: Clustering in Simulation
# -----------------------------------------------------------------------------
print("\n-- clustered assignment, analysed two ways --")
rng = np.random.default_rng(7)
n_clus, m = 12, 25                       # 300 students in 12 classrooms
sb, sw = 0.45 * np.sqrt(0.15), 0.45 * np.sqrt(0.85)
p = np.empty((1500, 2))
for i in range(1500):
    zc = rng.permutation(np.repeat([0, 1], n_clus // 2))  # assign CLASSROOMS
    u  = rng.normal(0, sb, n_clus)                        # classroom-level shock
    y  = rng.normal(np.repeat(3.05 + 0.15 * zc + u, m), sw)
    zi, cm = np.repeat(zc, m), y.reshape(n_clus, m).mean(axis=1)
    p[i] = (ttest_ind(y[zi == 1],  y[zi == 0],  equal_var=False).pvalue,
            ttest_ind(cm[zc == 1], cm[zc == 0], equal_var=False).pvalue)

print(pd.Series(dict(zip(["as_individuals", "as_clusters"], (p < 0.05).mean(axis=0)))))
