# Stage 1 Complete Forensic Audit — Reproducibility Report

## 1. Automated Execution Test Protocol
Every Stage 1 build script (`build_and_run_stage1.m` through `build_and_run_stage6.m`) was tested for non-interactive batch execution from command line.

## 2. Reproducibility Results Matrix

| Step | Script File | Automated Execution Command | Model Generation | Simulation Execution | MAT Output Export | Plot Export | Reproducibility Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Step 1** | `scripts/build_and_run_stage1.m` | `matlab -batch "run('scripts/build_and_run_stage1.m')"` | `models/stage1_motor_plant.slx` | `simOut` ODE45 | Workspace / PNG | 3 PNG Plots | **REPRODUCIBLE** |
| **Step 2** | `scripts/build_and_run_stage2.m` | `matlab -batch "run('scripts/build_and_run_stage2.m')"` | `models/stage1_encoder_model.slx` | `simOut` ODE45 | Workspace / PNG | 3 PNG Plots | **REPRODUCIBLE** |
| **Step 3** | `scripts/build_and_run_stage3.m` | `matlab -batch "run('scripts/build_and_run_stage3.m')"` | `models/stage1_pwm_model.slx` | `simOut` ODE45 | `stage3_data.mat` | 3 PNG Plots | **REPRODUCIBLE** |
| **Step 4** | `scripts/build_and_run_stage4.m` | `matlab -batch "run('scripts/build_and_run_stage4.m')"` | `models/stage1_closed_loop_model.slx` | `simOut` ODE45 | `stage4_data.mat` | 5 PNG Plots | **REPRODUCIBLE** |
| **Step 5** | `scripts/build_and_run_stage5.m` | `matlab -batch "run('scripts/build_and_run_stage5.m')"` | `models/stage1_profiled_loop_model.slx` | `simOut` ODE45 | `stage5_data.mat` | 4 PNG Plots | **REPRODUCIBLE** |
| **Step 6** | `scripts/build_and_run_stage6.m` | `matlab -batch "run('scripts/build_and_run_stage6.m')"` | `models/stage1_robust_loop_model.slx` | `simOut` ODE45 | `stage6_data.mat` | 4 PNG Plots | **REPRODUCIBLE** |

## 3. Dependency Path Verification
- All scripts dynamically determine project root directory via `fileparts(mfilename('fullpath'))`.
- Zero hardcoded machine-specific absolute paths detected.
