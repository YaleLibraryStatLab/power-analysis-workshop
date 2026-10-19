# Your Turn 3 (groups): the tutoring study with dropout.
# Run the setup, then work through the tasks, filling in each ___.

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy.special import expit
import statsmodels.formula.api as smf

rng = np.random.default_rng(2026)


# Setup: functions from the slides

def simulate_power(n_sims, generate, analyze, success):
    return np.mean([success(analyze(generate())) for _ in range(n_sims)])


def gen_pretest(n=350, effect=3, sd=10, rho=0.6):
    treat = np.repeat([0, 1], n // 2)
    pre = rng.normal(70, sd, n)
    post = 72 + rho * (pre - 70) + effect * treat + rng.normal(0, sd * np.sqrt(1 - rho**2), n)
    return pd.DataFrame({"treat": treat, "pre": pre, "post": post})


# Low scorers, and control students, are more likely to drop out
# (about 23% of control and 11% of tutored students leave).
def gen_dropout(n=350, effect=3, sd=10, rho=0.6):
    dat = gen_pretest(n, effect, sd, rho)
    p_drop = expit(-2.2 + 0.7 * (dat["treat"] == 0) - 0.12 * (dat["post"] - 72))
    return dat[rng.random(n) > p_drop]


def analyze_ancova(dat):
    fit = smf.ols("post ~ treat + pre", data=dat).fit()
    return {"estimate": fit.params["treat"], "p": fit.pvalues["treat"]}


def success_sig(est):
    return est["p"] < 0.05


# Task 1: Predict, before running anything.
# Will power with dropout be higher or lower than without it?
# Will the average estimate be above or below the true effect of 3? Why?


# Task 2: Power with and without dropout

print(simulate_power(2000, gen_pretest, analyze_ancova, success_sig))
print(simulate_power(2000, ___, analyze_ancova, success_sig))


# Task 3: Is the estimate biased? The true effect is 3.

estimates = [analyze_ancova(___())["estimate"] for _ in range(1000)]
print(np.mean(estimates))


# Task 4: Count a run as a success if the estimate is within 1.5 of the truth.

def success_close(est):
    return abs(est["estimate"] - ___) < ___


print(simulate_power(2000, gen_pretest, analyze_ancova, success_close))
print(simulate_power(2000, gen_dropout, analyze_ancova, success_close))


# Task 5 (if time): How many students are needed?

ns = np.arange(150, 501, 50)
powers = [simulate_power(500, lambda: gen_dropout(n=n), analyze_ancova, success_sig)
          for n in ns]

plt.plot(ns, powers, "o-")
plt.axhline(0.80, ls="--", color="red")
plt.ylim(0, 1)
plt.xlabel("Students enrolled (N)")
plt.ylabel("Simulated power")
plt.show()

# Does enrolling more students remove the bias you found in Task 3?
