############################################################
# Newborn Care Simulation-Based Power Analysis
# Author: Yusuf Suleiman Babana
# Purpose: Cluster-level simulation for binary (Healthy) 
#          and continuous (Oxygen saturation) outcomes
# Dataset: Synthetic newborn longitudinal data
# Date: 2025-11-15
############################################################

# ---------------------------
# 1. Load Libraries
# ---------------------------
library(tidyverse)        # data manipulation
library(lme4)             # mixed-effects models
library(broom.mixed)      # tidy model outputs
library(tibble)           # create tables
library(performance)      # for ICC estimation

# ---------------------------
# 2. Example Synthetic Dataset
# ---------------------------
set.seed(123)

# 100 babies, 30 daily records each
newborn_data <- expand.grid(
  baby_id = paste0("B", sprintf("%03d", 1:100)),
  day = 1:30
) %>%
  mutate(
    # Binary outcome: healthy_flag (1 = Healthy, 0 = At Risk)
    healthy_flag = rbinom(n(), 1, 0.87),
    
    # Continuous outcome: oxygen saturation
    oxy_sat = round(rnorm(n(), mean = 97.47, sd = 1), 1),
    
    # Risk level for reference
    risk_level = if_else(healthy_flag == 1, "Healthy", "At Risk")
  )

# Quick look
head(newborn_data, 10)

# ---------------------------
# 3. Cluster Information
# ---------------------------
num_clusters <- length(unique(newborn_data$baby_id)) # 100 clusters
obs_per_baby <- newborn_data %>%
  group_by(baby_id) %>%
  summarise(obs_count = n())
obs_per_baby

# Cluster summary
cluster_summary <- newborn_data %>%
  group_by(baby_id) %>%
  summarise(
    mean_healthy = mean(healthy_flag),
    mean_oxy_sat = mean(oxy_sat)
  )
cluster_summary

# ---------------------------
# 4. Estimate ICCs
# ---------------------------
# Binary outcome ICC
binary_model <- glmer(
  healthy_flag ~ 1 + (1 | baby_id),
  data = newborn_data,
  family = binomial
)
var_u <- as.numeric(VarCorr(binary_model)$baby_id[1])
var_e <- pi^2 / 3
icc_binary <- var_u / (var_u + var_e)
icc_binary

# Continuous outcome ICC
continuous_model <- lmer(
  oxy_sat ~ 1 + (1 | baby_id),
  data = newborn_data
)
var_components <- as.data.frame(VarCorr(continuous_model))
icc_continuous <- var_components$vcov[1] / sum(var_components$vcov)
icc_continuous

# ---------------------------
# 5. Simulation Parameters
# ---------------------------
num_sim <- 500         # simulation iterations
effect_binary <- 0.20  # 20% increase for Healthy
effect_cont <- 5       # +5 units oxygen saturation
clusters <- unique(newborn_data$baby_id)
num_clusters <- length(clusters)

# Storage
results_binary <- numeric(num_sim)
results_cont <- numeric(num_sim)

set.seed(123)  # reproducibility

# ---------------------------
# 6. Simulation Loop
# ---------------------------
for (i in 1:num_sim) {
  
  # Random cluster-level treatment assignment
  intervention_clusters <- sample(clusters, num_clusters / 2)
  
  # Simulated dataset for iteration
  newborn_data_sim <- newborn_data %>%
    mutate(
      treated = if_else(baby_id %in% intervention_clusters, 1, 0),
      
      # Binary outcome simulation
      prob_healthy_sim = case_when(
        treated == 1 & healthy_flag == 0 ~ effect_binary,
        treated == 1 & healthy_flag == 1 ~ 1,
        TRUE ~ as.numeric(healthy_flag)
      ),
      healthy_sim = rbinom(n(), size = 1, prob = prob_healthy_sim),
      
      # Continuous outcome simulation
      oxy_sim = if_else(treated == 1, oxy_sat + effect_cont, oxy_sat)
    )
  
  # Fit mixed models
  mod_bin <- glmer(healthy_sim ~ treated + (1|baby_id),
                   data = newborn_data_sim,
                   family = binomial)
  mod_cont <- lmer(oxy_sim ~ treated + (1|baby_id),
                   data = newborn_data_sim)
  
  # Extract p-values
  tidy_bin <- broom.mixed::tidy(mod_bin)
  p_value_bin <- if(any(tidy_bin$term == "treated") & "p.value" %in% colnames(tidy_bin)) {
    tidy_bin %>% filter(term == "treated") %>% pull(p.value)
  } else 1
  
  tidy_cont <- broom.mixed::tidy(mod_cont)
  p_value_cont <- if(any(tidy_cont$term == "treated") & "p.value" %in% colnames(tidy_cont)) {
    tidy_cont %>% filter(term == "treated") %>% pull(p.value)
  } else 1
  
  # Record significance
  results_binary[i] <- p_value_bin < 0.05
  results_cont[i] <- p_value_cont < 0.05
}

# ---------------------------
# 7. Power Estimates
# ---------------------------
power_binary <- mean(results_binary)
power_cont <- mean(results_cont)

power_binary
power_cont

# ---------------------------
# 8. Assumptions Table
# ---------------------------
assumptions_table <- tibble(
  Parameter = c(
    "Number of clusters (babies)",
    "Observations per cluster (days)",
    "Binary outcome baseline probability (Healthy)",
    "Continuous outcome baseline (Oxygen saturation mean)",
    "Binary outcome effect size (treated)",
    "Continuous outcome effect size (treated)",
    "Number of simulation iterations",
    "Significance level (alpha)",
    "ICC binary outcome",
    "ICC continuous outcome"
  ),
  Value = c(
    num_clusters,
    30,
    round(mean(newborn_data$healthy_flag), 2),
    round(mean(newborn_data$oxy_sat), 2),
    effect_binary,
    effect_cont,
    num_sim,
    0.05,
    round(icc_binary, 2),
    round(icc_continuous, 2)
  ),
  Notes = c(
    "Clustered design: babies are clusters",
    "Daily measurements for 30 days per baby",
    "Mean probability of being Healthy across dataset",
    "Mean oxygen saturation across dataset",
    "Effect of intervention on probability of Healthy",
    "Effect of intervention on oxygen saturation",
    "Number of iterations in simulation",
    "Significance threshold for detecting effect",
    "Intra-cluster correlation for Healthy outcome",
    "Intra-cluster correlation for oxygen saturation"
  )
)

assumptions_table
