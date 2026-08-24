# Stage 1 Forensic Audit — Requirement Traceability Matrix

## 1. Overview
This matrix traces every engineering requirement across Stage 1 (Steps 1 through 6) to its physical implementation, numerical simulation output, verification method, and audit status.

## 2. Requirement Traceability Table

| Step | Requirement Description | Source | Implementation Location | Simulation Evidence | Target Limit | Measured Result | Audit Status | Confidence |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Step 1** | Motor Electrical Dynamics | Physics Eq. | models/stage1_motor_plant.slx | speed_vs_time.png | {ss} = 176.47$ rad/s | 176.4706 rad/s | **VERIFIED PASS** | 100% |
| **Step 1** | Motor Mechanical Dynamics | Physics Eq. | models/stage1_motor_plant.slx | position_vs_time.png | \theta/dt = w$ | Error $< 10^{-6}$ | **VERIFIED PASS** | 100% |
| **Step 1** | SI Parameter Consistency | Physics Eq. | scripts/params.m | Math Check |  = K_t = 0.05$ |  = K_t = 0.05$ | **VERIFIED PASS** | 100% |
| **Step 2** | Encoder Quantization | Spec | models/stage1_encoder_model.slx | encoder_error.png | 1000 CPR (0.36 deg) | 0.3600 deg/count | **VERIFIED PASS** | 100% |
| **Step 2** | Position Error Bound | Spec | models/stage1_encoder_model.slx | 	rue_vs_encoder_position.png | $\le 0.3600^\circ$ | .3600^\circ$ | **VERIFIED PASS** | 100% |
| **Step 3** | Averaged PWM Actuation | Spec | models/stage1_pwm_model.slx | stage3_data.mat | {eff} = d \cdot V_{dc}$ | Linearity Err $< 0.01\%$ | **VERIFIED PASS** | 100% |
| **Step 3** | Full Duty Speed | Spec | models/stage1_pwm_model.slx | stage3_data.mat | 176.47 rad/s | 176.4706 rad/s | **VERIFIED PASS** | 100% |
| **Step 4** | Closed-Loop Position Tracking | Spec | models/stage1_closed_loop_model.slx | stage4_data.mat | Error $\le 0.3600^\circ$ | .0384^\circ$ | **VERIFIED PASS** | 100% |
| **Step 4** | Dynamic Overshoot | Spec | models/stage1_closed_loop_model.slx | stage4_data.mat | $\le 10.0\%$ | .00\%$ | **VERIFIED PASS** | 100% |
| **Step 4** | Settling Time (2%) | Spec | models/stage1_closed_loop_model.slx | stage4_data.mat | $\le 0.1500$ s | .0784$ s | **VERIFIED PASS** | 100% |
| **Step 5** | Trapezoidal Profile Generator | Kinematics | models/stage1_profiled_loop_model.slx | stage5_data.mat | {max}=50, w_{max}=8$ |  = 0.35635$ s | **VERIFIED PASS** | 100% |
| **Step 5** | Discrete PID (Ts=1ms) | MCU Spec | models/stage1_profiled_loop_model.slx | stage5_data.mat | =0.50, Ki=8, Kd=0$ | Error $\le 0.3600^\circ$ | **VERIFIED PASS** | 100% |
| **Step 5** | Physical Kinematic Feedforward | Physics Eq. | models/stage1_profiled_loop_model.slx | stage5_data.mat | , Kff_a$ | Tracking Err .4456^\circ$ | **VERIFIED PASS** | 100% |
| **Step 6** | In-Motion Load Step (=0.010$ N m) | Robust Spec | models/stage1_robust_loop_model.slx | stage6_data.mat | Tracking $\le 1.7200^\circ$ | .5218^\circ$ | **VERIFIED PASS** | 100% |
| **Step 6** | In-Motion Peak Current | Robust Spec | models/stage1_robust_loop_model.slx | stage6_data.mat | Peak  \le 1.5000$ A | .2486$ A | **VERIFIED PASS** | 100% |
| **Step 6** | In-Dwell Load Pulse Deviation | Robust Spec | models/stage1_robust_loop_model.slx | stage6_data.mat | Max Dev $\le 0.3600^\circ$ | .2786^\circ$ | **VERIFIED PASS** | 100% |
| **Step 6** | In-Dwell Recovery Time | Robust Spec | models/stage1_robust_loop_model.slx | stage6_data.mat | {rec} \le 0.0500$ s | .0000$ s (Option A) | **VERIFIED PASS** | 100% |
| **Step 6** | Nonlinear Friction Final True Error | Robust Spec | models/stage1_robust_loop_model.slx | stage6_data.mat | Error $\le 0.3600^\circ$ | .1512^\circ$ | **VERIFIED PASS** | 100% |
| **Step 6** | Payload Inertia Sweep (,2x,3x J_0$) | Robust Spec | models/stage1_robust_loop_model.slx | stage6_data.mat | Tracking $\le 1.7200^\circ$ | .47^\circ, 0.28^\circ, 0.72^\circ$ | **VERIFIED PASS** | 100% |
