# Statistical Power workshop code (Python), Yale Library | StatLab.
# The code from presentation/python/statistical-power-python.qmd in slide order,
# with solutions to the group activities and the appendix.
# Requires numpy, pandas, scipy, matplotlib, statsmodels.

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy.stats import norm, ttest_ind
from scipy.special import expit
import statsmodels.formula.api as smf


# The formula, in code

def power_calc(mu_t, mu_c, sigma, N, alpha=0.05):
    z = np.abs(mu_t - mu_c) * np.sqrt(N) / (2 * sigma)
    cv = norm.ppf(1 - alpha / 2)
    return norm.cdf(z - cv) + norm.cdf(-z - cv)


def mde_calc(sigma, N, alpha=0.05, power=0.80):
    return (norm.ppf(1 - alpha / 2) + norm.ppf(power)) * 2 * sigma / np.sqrt(N)


def n_required(delta, sigma, alpha=0.05, power=0.80):
    return np.ceil(4 * sigma**2 * (norm.ppf(1 - alpha / 2) + norm.ppf(power))**2
                   / np.asarray(delta)**2).astype(int)


print(power_calc(57, 50, 20, 164))  # running example
print(power_calc(75, 72, 10, 400))  # Your Turn 1: tutoring study
print(mde_calc(20, np.array([164, 257, 400, 800, 1396])))
print(n_required([3, 5, 7], 20))


# Power across a range of N

grid = pd.merge(pd.DataFrame({"N": np.arange(60, 1601, 10)}),
                pd.DataFrame({"delta": [3, 5, 7]}), how="cross")
grid["power"] = power_calc(50 + grid["delta"], 50, 20, grid["N"])

for d, g in grid.groupby("delta"):
    plt.plot(g["N"], g["power"], label=d)
plt.axhline(0.80, ls="--", color="#B41E1E")
plt.xlabel("Total respondents (N)")
plt.ylabel("Power")
plt.legend(title="Assumed effect (points)")
plt.show()


# Your Turn 2: sleep workshop on a budget, one solution

grid = pd.merge(pd.DataFrame({"N": np.arange(50, 1501, 10)}),
                pd.DataFrame({"delta": [10, 15, 25]}), how="cross")
grid["power"] = power_calc(400 + grid["delta"], 400, 60, grid["N"])
print(grid[grid["power"] >= 0.80].groupby("delta")["N"].min())
print(mde_calc(60, 12000 / 40))


# Monte Carlo: three reds in a row

rng = np.random.default_rng(2026)
spins = rng.random((100_000, 3)) < 18 / 38
print(np.mean(spins.sum(axis=1) == 3), (18 / 38)**3)


# The simulation recipe

def simulate_power(n_sims, generate, analyze, success):
    return np.mean([success(analyze(generate())) for _ in range(n_sims)])


def gen_basic(n=350, effect=3, sd=10):
    treat = np.repeat([0, 1], n // 2)
    post = 72 + effect * treat + rng.normal(0, sd, n)
    return pd.DataFrame({"treat": treat, "post": post})


def treat_coef(fit):
    return {"estimate": fit.params["treat"], "p": fit.pvalues["treat"]}


def analyze_lm(dat):
    return treat_coef(smf.ols("post ~ treat", data=dat).fit())


def success_sig(est):
    return est["p"] < 0.05


rng = np.random.default_rng(2026)
print(simulate_power(2000, gen_basic, analyze_lm, success_sig),
      power_calc(75, 72, 10, 350))


# Adding a pre-test

def gen_pretest(n=350, effect=3, sd=10, rho=0.6):
    treat = np.repeat([0, 1], n // 2)
    pre = rng.normal(70, sd, n)
    post = 72 + rho * (pre - 70) + effect * treat + rng.normal(0, sd * np.sqrt(1 - rho**2), n)
    return pd.DataFrame({"treat": treat, "pre": pre, "post": post})


def analyze_ancova(dat):
    return treat_coef(smf.ols("post ~ treat + pre", data=dat).fit())


rng = np.random.default_rng(2026)
print(simulate_power(2000, gen_pretest, analyze_lm, success_sig),
      simulate_power(2000, gen_pretest, analyze_ancova, success_sig))


# Your Turn 3: tutoring study with dropout, solutions

def gen_dropout(n=350, effect=3, sd=10, rho=0.6):
    dat = gen_pretest(n, effect, sd, rho)
    p_drop = expit(-2.2 + 0.7 * (dat["treat"] == 0) - 0.12 * (dat["post"] - 72))
    return dat[rng.random(n) > p_drop]


def success_close(est):
    return abs(est["estimate"] - 3) < 1.5


rng = np.random.default_rng(2026)
print(simulate_power(2000, gen_dropout, analyze_ancova, success_sig),
      np.mean([analyze_ancova(gen_dropout())["estimate"] for _ in range(2000)]))

rng = np.random.default_rng(2026)
print(simulate_power(2000, gen_pretest, analyze_ancova, success_close),
      simulate_power(2000, gen_dropout, analyze_ancova, success_close))

rng = np.random.default_rng(2026)
ns = np.arange(150, 501, 50)
powers = [simulate_power(1000, lambda: gen_dropout(n=n), analyze_ancova, success_sig)
          for n in ns]
plt.plot(ns, powers, "o-", color="#0B2E52")
plt.axhline(0.80, ls="--", color="#B41E1E")
plt.ylim(0, 1)
plt.xlabel("Students enrolled (N)")
plt.ylabel("Simulated power")
plt.show()


# Appendix: power for an interaction (N = 164)

rng = np.random.default_rng(11)
p = np.empty((2000, 2))
for i in range(2000):
    z = rng.permutation(np.repeat([0, 1], 82))
    g = np.tile([0, 1], 82)
    d = pd.DataFrame({"y": rng.normal(50 + 4 * z + 6 * z * g + 2 * g, 20), "z": z, "g": g})
    p[i] = (smf.ols("y ~ z", d).fit().pvalues["z"],
            smf.ols("y ~ z * g", d).fit().pvalues["z:g"])
print((p < 0.05).mean(axis=0))  # ATE, interaction


# Appendix: x as a confounder

def sim_obs(adjust, N=164):
    out = np.empty((2000, 2))
    for i in range(2000):
        x = rng.normal(size=N)
        z = rng.binomial(1, expit(1.2 * x))
        y = 50 + 7 * z + 12 * x + rng.normal(0, 16, N)
        fit = smf.ols("y ~ z + x" if adjust else "y ~ z",
                      pd.DataFrame({"y": y, "z": z, "x": x})).fit()
        out[i] = fit.params["z"], fit.pvalues["z"]
    return out[:, 0].mean(), np.mean(out[:, 1] < 0.05)


rng = np.random.default_rng(3)
print(sim_obs(False), sim_obs(True))  # (estimate, rejection rate)


# Appendix: randomizing groups of 25, intra-cluster correlation 0.15

deff = 1 + (25 - 1) * 0.15
print(np.ceil(n_required(7, 20) * deff))


# Appendix: clustering in simulation

def sim_clus(tau, k=12, m=25):
    p = np.empty((1500, 2))
    for i in range(1500):
        zc = rng.permutation(np.repeat([0, 1], k // 2))
        u = rng.normal(0, 20 * np.sqrt(0.15), k)
        y = rng.normal(np.repeat(50 + tau * zc + u, m), 20 * np.sqrt(0.85))
        zi, gm = np.repeat(zc, m), y.reshape(k, m).mean(axis=1)
        p[i] = (ttest_ind(y[zi == 1], y[zi == 0], equal_var=False).pvalue,
                ttest_ind(gm[zc == 1], gm[zc == 0], equal_var=False).pvalue)
    return (p < 0.05).mean(axis=0)


rng = np.random.default_rng(7)
print(sim_clus(0), sim_clus(7))  # [as individuals, as group means]
