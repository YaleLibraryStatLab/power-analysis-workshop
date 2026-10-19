# Your Turn 4: simulate your own design.
# Fill in every ___, running each step before moving on.
#
# No study in mind? Use the blood-pressure coaching study from the slides:
#   systolic BP under usual care: mean 140 mmHg, SD 15
#   expected effect of coaching: -5 mmHg
#   the clinic can enroll 250 patients
# For Step 7, adjust for baseline BP (correlation 0.5 with the six-month
# reading), or coach only one in three patients.

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import statsmodels.formula.api as smf

rng = np.random.default_rng(2026)


def simulate_power(n_sims, generate, analyze, success):
    return np.mean([success(analyze(generate())) for _ in range(n_sims)])


# Step 1: Describe your study

baseline = ___     # control-group mean
true_effect = ___  # effect you hope to detect
noise_sd = ___     # subject-to-subject SD of the outcome
n_start = ___      # total sample size to try first


# Step 2: generate() one fake data set:  y = baseline + effect * treat + noise

def generate(n=n_start, effect=true_effect):
    treat = np.resize([0, 1], n)
    y = ___ + ___ * treat + rng.normal(0, ___, n)
    return pd.DataFrame({"treat": treat, "y": y})


dat = generate()
print(dat.groupby("treat")["y"].mean())  # roughly what you expected?


# Step 3: analyze() it the way you would analyze the real data

def analyze(dat):
    fit = smf.___("y ~ treat", data=dat).fit()
    return {"estimate": fit.params["treat"], "p": fit.pvalues["treat"]}


print(analyze(generate()))


# Step 4: success(): did this one run recover the effect? Return True or False.

def success(est):
    return ___


print(success(analyze(generate())))


# Step 5: Estimate power. Start with few simulations so it runs quickly.

print(simulate_power(___, generate, analyze, success))

# With no effect, a significance-based success() should succeed about 5% of the time
print(simulate_power(1000, lambda: generate(effect=0), analyze, success))


# Step 6: How many subjects do you need?

ns = np.arange(___, ___, ___)
powers = np.array([simulate_power(500, lambda: generate(n=n), analyze, success)
                   for n in ns])

plt.plot(ns, powers, "o-")
plt.axhline(0.80, ls="--", color="red")
plt.ylim(0, 1)
plt.xlabel("Total sample size (N)")
plt.ylabel("Simulated power")
plt.show()

print(ns[powers >= 0.80][:1])  # smallest N in the grid reaching 80%; simulation is noisy


# Step 7: Add one complication (a covariate, unequal groups, a skewed outcome,
# dropout) in a new generate(), and rerun Steps 5-6. How much power changes?
