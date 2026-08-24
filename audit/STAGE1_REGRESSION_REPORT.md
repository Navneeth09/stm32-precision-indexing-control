# Stage 1 Complete Regression Test Report

## 1. Baseline Model Hash Integrity

| Model File Path | Cryptographic SHA-256 Hash | Baseline Regression Status |
| :--- | :--- | :--- |
| `models/stage1_motor_plant.slx` | `EBBAA72E8B062D771293AB593FA65FA7A81BAB720E5B...` | **100% UNTOUCHED** |
| `models/stage1_encoder_model.slx` | `7767F20C415E68680F736D4730D2053C45716D1EE781...` | **100% UNTOUCHED** |
| `models/stage1_pwm_model.slx` | `E2BF6C923A8743F39CBF5B683247697D850E032DAE57...` | **100% UNTOUCHED** |
| `models/stage1_closed_loop_model.slx` | `92F41BBC4CD367D19E5EA9AFFE48930576330F4B5E3B...` | **100% UNTOUCHED** |
| `models/stage1_profiled_loop_model.slx` | `976E4B6EED995AF5E11F471A296570C3F39B0D8364E8...` | **100% UNTOUCHED** |

## 2. Quantitative Dataset Regression Comparisons

| Step | Output Dataset Path | Evaluated Metric | Expected Target | Re-Simulated Value | Max Absolute Error | Regression Result |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Step 1** | `results/stage1/stage1_data.mat` | Steady-State Speed | $176.4706\text{ rad/s}$ | $176.4706\text{ rad/s}$ | $< 10^{-6}\text{ rad/s}$ | **PASS** |
| **Step 2** | `results/stage1/stage2_data.mat` | Encoder Quantization Bound | $\le 0.3600^\circ$ | $0.3600^\circ$ | $0.0000^\circ$ | **PASS** |
| **Step 3** | `results/stage1/stage3_data.mat` | 75% Actuation Speed Linearity | $132.3529\text{ rad/s}$ | $132.3529\text{ rad/s}$ | $< 10^{-6}\text{ rad/s}$ | **PASS** |
| **Step 4** | `results/stage1/stage4_data.mat` | Steady-State Position Error | $0.0384^\circ$ | $0.0384^\circ$ | $0.0000^\circ$ | **PASS** |
| **Step 5** | `results/stage1/stage5_data.mat` | Phase 2 Max Tracking Error | $0.4456^\circ$ | $0.4456^\circ$ | $0.0000^\circ$ | **PASS** |
| **Step 6** | `results/stage1/stage6_data.mat` | Corrected In-Dwell Deviation | $0.2786^\circ$ | $0.2786^\circ$ | $0.0000^\circ$ | **PASS** |
