# ECO346 Assignment 1 — FA24-BEDS-052

**Variant 4: Khyber Pakhtunkhwa, rural.**
Registration number FA24-BEDS-052 gives 52 = 6 × 8 + 4, so the remainder is 4.

This repository contains the R and Python code, figures and slides for the PSLM
2019–20 analysis. The scripts read the local CSV files in `data/`, so a fresh
clone reproduces every figure and number without internet access.

## Repository contents

```
README.md
data/       pslm_person_subset.csv, pslm_hh_subset.csv
scripts/    01_distribution.R, 02_default.R, 03_literacy.R, 04_literacy.py
figures/    distribution.svg, default.svg, literacy.svg, literacy_python.svg
slides/     FA24-BEDS-052.pptx
```

## Reproducing the results

Run from the repository root (the scripts also locate the root automatically):

```bash
Rscript scripts/01_distribution.R
Rscript scripts/02_default.R
Rscript scripts/03_literacy.R
python scripts/04_literacy.py
```

R is used for Questions 2, 3 and 4. Python is the second language for Question 5.
The R scripts use `ggplot2` and `svglite`; the Python script uses `pandas` and
`matplotlib`.

## Question 2 — The distribution

![Weighted distribution of annual education spending](figures/distribution.svg)

**Numbers.** Students with `ed_total > 0`: **4,912**. Weighted median:
**Rs 7,000**. Unweighted median: **Rs 7,000**. Weighted 10th percentile:
**Rs 2,500**. Weighted 90th percentile: **Rs 25,000**. Ratio of the 90th to the
10th percentile: **10.00**. Students excluded outside Rs 100–Rs 1,000,000:
**3**.

**What the figure shows (78 words).** The distribution is strongly right-skewed:
most KP rural students incur a few thousand rupees annually, but a thin upper
tail reaches Rs 1 million. The weighted 90th percentile is ten times the 10th
(Rs 25,000 versus Rs 2,500). Both medians equal Rs 7,000 because spending
clusters at round figures. Exactly 134 students report Rs 7,000, straddling 50%
in both unweighted (49.2% to 52.0%) and weighted (47.4% to 50.3%) cumulative
distributions.

## Question 3 — The relationship

![Weighted literacy rate by age band and sex](figures/literacy.svg)

**Numbers.** Women aged 15–19: **52.6%**; men aged 15–19: **85.1%**. Women aged
55–59: **2.9%**; men aged 55–59: **43.0%**. The largest gender gap is in the
**45–49** band: women **10.5%**, men **57.0%**, a gap of **46.6 percentage
points** (unrounded: 46.55 pp, edging out 35–39 at 46.52 pp and 40–44 at 46.50
pp).

### Band table

| Age band | Men (N) | Men weighted % | Women (N) | Women weighted % |
|---|---:|---:|---:|---:|
| 10–14 | 1,439 | 81.5 | 1,210 | 54.6 |
| 15–19 | 1,162 | 85.1 | 985 | 52.6 |
| 20–24 | 768 | 79.5 | 906 | 33.3 |
| 25–29 | 580 | 70.6 | 826 | 30.0 |
| 30–34 | 499 | 68.4 | 588 | 24.8 |
| 35–39 | 421 | 67.5 | 546 | 21.0 |
| 40–44 | 357 | 60.1 | 449 | 13.6 |
| 45–49 | 385 | 57.0 | 392 | 10.5 |
| 50–54 | 278 | 45.1 | 384 | 6.7 |
| 55–59 | 255 | 43.0 | 308 | 2.9 |
| 60–64 | 272 | 39.2 | 190 | 3.6 |

Every age–sex cell has at least 30 unweighted persons, so no hollow (thin)
markers appear in this variant.

**Interpretation (88 words).** Literacy falls with age from the late teens, with
small reversals at the ends (men rise between 10–14 and 15–19; women slightly
between 55–59 and 60–64). This pattern reflects cohort replacement: younger
generations had greater educational access, whereas older cohorts faced severe
supply constraints. The gender gap peaks at ages 45–49 at 46.6 percentage points
(57.0% vs. 10.5%), in a near-tie with 35–44. The cross-section records only
current status; it cannot reveal when individuals became literate, nor separate
schooling expansion from age or survival effects.

## Question 4 — The makeover

**Default (committed before the redesign):**

![Default scatterplot](figures/default.svg)

**Redesign (the Question 3 figure):**

![Weighted conditional means by age band and sex (Question 3 redesign)](figures/literacy.svg)

**Redesign explanation (126 words).** The default plot places individual age on
the x-axis and binary literacy (0/1) on the y-axis; 13,200 points collapse into
two horizontal bands, obscuring the age pattern. I made three key changes. First,
aggregating into five-year bands and computing weighted **conditional means**
resolves severe **overplotting**, exposing the underlying demographic
relationship. Second, mapping aggregate literacy rates to **position along a
common scale** (0–100%) leverages the highest-ranked elementary perceptual task
(Cleveland–McGill) rather than binary scatter. Third, directly labeling each sex
at line ends removes a detached legend, maximizing the **data–ink ratio**
(Tufte). What the default shows that the redesign hides is the raw
individual-level sample structure, showing exact sample counts at each single
year of age and revealing any respondent age heaping, which five-year aggregation
conceals.

## Question 5 — A second language

The Python script `scripts/04_literacy.py` recomputes the band table and redraws
the Question 3 figure as `figures/literacy_python.svg`. Its band table matches
the R table to one decimal place.

![Question 3 figure redrawn in Python](figures/literacy_python.svg)

**Numbers.** Women aged 15–19: **52.6%** from R and **52.6%** from Python.

**What differed (69 words).** A key difference arose in age binning defaults:
standard binning functions in Python like `pd.cut` default to right-closed
intervals `(10, 15]`, which misclassifies boundary ages compared to R's
left-closed bands `[10, 15)`. To ensure the five-year age bands and midpoints
matched exactly, I used integer floor division `(age - 10) // 5` in Python. I
also aligned the weighted aggregation formula, hex colours, direct end-labels,
and y-axis limits (0–100%).

## Question 6 — Presentation

The four-slide PowerPoint is `slides/FA24-BEDS-052.pptx`. It shows the variant,
the makeover (default and redesign side by side), and the main finding.
