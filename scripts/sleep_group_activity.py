# Your Turn 2 (groups): a sleep workshop on a budget.
# Run the setup, then work through the tasks, filling in each ___.

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy.stats import norm


# Setup

def power_calc(mu_t, mu_c, sigma, N, alpha=0.05):
    z = np.abs(mu_t - mu_c) * np.sqrt(N) / (2 * sigma)
    cv = norm.ppf(1 - alpha / 2)
    return norm.cdf(z - cv) + norm.cdf(-z - cv)


mu_c, sigma = 400, 60  # minutes of sleep per night, from last year's tracker data
cost_per_student, budget = 40, 12000


# Task 1: Discuss
# Three sources disagree about the effect of the workshop:
#   a pilot with 20 students: +25 min
#   a meta-analysis of similar brief workshops: +15 min
#   the office director's minimum worth acting on: +10 min
# Which would you trust most, and what is wrong with each one?


# Task 2: Sweep. Choose a range of N and the effects (in minutes) to plan for.

grid = pd.merge(pd.DataFrame({"N": np.arange(___, ___, 10)}),
                pd.DataFrame({"delta": [___, ___, ___]}), how="cross")
grid["power"] = power_calc(mu_c + grid["delta"], mu_c, sigma, grid["N"])

# Smallest N with 80% power for each effect; a missing effect means extend the grid
print(grid[grid["power"] >= 0.80].groupby("delta")["N"].min())

for d, g in grid.groupby("delta"):
    plt.plot(g["N"], g["power"], label=d)
plt.axhline(0.80, ls="--", color="red")
plt.xlabel("Total students (N)")
plt.ylabel("Power")
plt.legend(title="Effect")
plt.show()


# Task 3: Budget. How many students can you afford, and what can that N detect?

n_budget = ___ / ___
mde = (norm.ppf(0.975) + norm.ppf(0.80)) * 2 * sigma / np.sqrt(n_budget)
print(n_budget, mde)

# Which of your effects from Task 2 are at least this large?


# Task 4: Report. Write the sentence your group would put in a proposal:
#   "With N = ___, the study has 80% power to detect effects of ___ minutes or larger."
