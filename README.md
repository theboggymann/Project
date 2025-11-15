# Newborn Care Simulation-Based Power Analysis

Author: Yusuf Suleiman Babana  
Email: babanayusuff@gmail.com  

---

## Overview

This repository contains a reproducible R workflow for **simulation-based power analysis** of newborn care interventions. The study evaluates two primary outcomes:

- **Binary Outcome:** Healthy vs At Risk/Critical (`healthy_flag`)  
- **Continuous Outcome:** Oxygen saturation (`oxy_sat`)  

Simulations account for clustering at the baby level using **mixed-effects models**.

---

## Features

- Cluster-level random assignment of treatment  
- Mixed-effects modeling for both binary and continuous outcomes  
- Empirical power estimation across simulation iterations  
- Assumptions table for reporting and study design  
- Fully reproducible with synthetic example data  

---

## Dependencies

- R packages: `tidyverse`, `lme4`, `broom.mixed`, `tibble`, `performance`  
- R version >= 4.0 recommended  

---

## Usage

1. Clone or download the repository  
2. Open `newborn_simulation_power.R` in RStudio or R environment  
3. Run the script. All data and parameters are included.  
4. Outputs include:
   - `power_binary` (empirical power for Healthy outcome)  
   - `power_cont` (empirical power for Oxygen saturation)  
   - `assumptions_table` summarizing study design and parameters  

---

## Google Colab Version

You can run the workflow interactively in **Google Colab**:  
[Open in Colab](https://colab.research.google.com/drive/1Y79CDcLtjah7ypymHVtkKAQ6Wy1XH7YS?usp=sharing)

---

## Example Output

| Parameter | Value | Notes |
|-----------|-------|-------|
| Number of clusters (babies) | 100 | Clustered design |
| Observations per cluster (days) | 30 | Daily measurements per baby |
| Binary outcome baseline probability (Healthy) | 0.87 | Mean probability across dataset |
| Continuous outcome baseline (Oxygen saturation mean) | 97.47 | Mean across dataset |
| Binary outcome effect size (treated) | 0.20 | Intervention effect |
| Continuous outcome effect size (treated) | 5 | Intervention effect |
| Number of simulation iterations | 500 | Iterations for empirical power |
| Significance level (alpha) | 0.05 | Detection threshold |
| ICC binary outcome | 0.00 | Intra-cluster correlation |
| ICC continuous outcome | 0.00 | Intra-cluster correlation |

---

## License

This repository is open-source and freely available for educational and research purposes.

