# Stage 1 Reproducibility Specification & Guide

## 1. Executive Summary
This document provides complete instructions for cloning this repository and reproducing all simulation steps, verification matrices, and figure dashboards for **Stage 1 (Complete Simulation Prototype)** of the **STM32 Automated Precision Indexing & Feed Control System**.

All simulations run autonomously via MATLAB script automation (`run_stage1.m` and `test_stage1.m`), validating Steps 1 through 6 and exporting raw `.mat` datasets and high-resolution figure dashboards.

---

## 2. System Environment Requirements

### MATLAB Requirements
- **Supported Versions:** MATLAB R2023b, R2024a, or R2025a (64-bit Windows/Linux/macOS).
- **Required Toolboxes:**
  - Simulink (Base)
  - Control System Toolbox

### Python Requirements (Optional Plot Generation)
- **Supported Versions:** Python 3.9+
- **Dependencies (`requirements/python_requirements.txt`):**
  ```text
  numpy >= 1.24.0
  scipy >= 1.10.0
  matplotlib >= 3.7.0
  ```

---

## 3. Reproduction Step-by-Step Instructions

### Step 1: Clone Repository
```bash
git clone https://github.com/user/Project2.git
cd Project2
```

### Step 2: Open MATLAB & Set Working Directory
Launch MATLAB and navigate to the repository root directory:
```matlab
cd('path/to/Project2')
```

### Step 3: Run Authoritative Execution Pipeline
In the MATLAB Command Window, execute:
```matlab
run_stage1
```
This script will sequentially build/load all 6 Simulink models, execute ODE45 simulations, verify analytical physics derivations, and save raw datasets to `results/stage1/`.

### Step 4: Run Authoritative Automated Regression Suite
To run the automated regression test suite across all 6 steps:
```matlab
test_stage1
```
Expected terminal output:
```text
====================================
STAGE 1 REGRESSION TEST SUMMARY
====================================
Step 1: PASS
Step 2: PASS
Step 3: PASS
Step 4: PASS
Step 5: PASS
Step 6: PASS
------------------------------------
Overall: PASS
====================================
```

---

## 4. Output Verification & Artifact Directory Structure

Upon successful execution, the following files will be populated:
- **Raw Simulation Datasets (`results/stage1/`):**
  - `stage1_data.mat` through `stage6_data.mat`
- **High-Resolution Figure Dashboards (`plots/stage1/`):**
  - 20 publication-quality PNG figure dashboards.

---

## 5. Headless Command-Line Execution
For automated CI/CD pipelines, MATLAB can be invoked headlessly:
```bash
matlab -batch "test_stage1; exit;"
```
