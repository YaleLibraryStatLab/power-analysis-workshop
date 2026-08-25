# Yale StatLab: Power Analysis

Materials for the Yale Library **StatLab** workshop on statistical power. The
workshop runs about two hours and is taught in two parallel versions, R and
Python, covering the same material slide for slide: what power is, the
closed-form calculation worked by hand, the minimum detectable effect, sweeping
power over a grid of assumptions, and Monte Carlo simulation for designs the
formula cannot describe.

## Presentation

The slides are Quarto documents that render to Beamer PDF. Pick the language you
work in; the two decks are equivalent.

| File | Description |
| --- | --- |
| [`presentation/R/statistical-power-r.qmd`](presentation/R/statistical-power-r.qmd) | Source for the R deck |
| [`presentation/python/statistical-power-python.qmd`](presentation/python/statistical-power-python.qmd) | Source for the Python deck |
| [`presentation/statistical-power-r.pdf`](presentation/statistical-power-r.pdf) | Rendered R deck |
| [`presentation/statistical-power-python.pdf`](presentation/statistical-power-python.pdf) | Rendered Python deck |

To rebuild a deck, render it from its own folder — the PDF is written up to
`presentation/`:

```sh
cd presentation/R      && quarto render statistical-power-r.qmd
cd presentation/python && quarto render statistical-power-python.qmd
```

The R deck needs `ggplot2`; the Python deck needs `numpy`, `pandas`,
`matplotlib`, `scipy`, and `statsmodels`.

## Scripts

Every code block from the slides, in slide order, as a plain script you can run
top to bottom. Use these to follow along or to lift a block into your own
analysis.

| File | Description |
| --- | --- |
| [`scripts/power-analysis.R`](scripts/power-analysis.R) | All R code from the deck |
| [`scripts/power_analysis.py`](scripts/power_analysis.py) | All Python code from the deck |

```sh
Rscript scripts/power-analysis.R
python3 scripts/power_analysis.py
```

Both simulate several thousand studies and take a minute or two to finish.

---

Everything else in the repository supports those two groups: `assets/` holds the
shared LaTeX header both decks include, and each presentation folder carries a
`_quarto.yml` and an `images/` directory needed to render.

Taught by Ted Ellsworth, PhD — Yale Library | StatLab.
Free for all Yale affiliates: [library.yale.edu/statlab](https://library.yale.edu/statlab)