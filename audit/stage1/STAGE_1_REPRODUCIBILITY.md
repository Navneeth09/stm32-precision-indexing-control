# Stage 1 Forensic Audit — Reproducibility & Simulation Audit

## 1. Simulation Reproduction Protocol
All Stage 1 models (stage1_motor_plant.slx through stage1_robust_loop_model.slx) were re-simulated in MATLAB batch mode under exact solver settings (ode45 variable step,  = 1\text{ ms}$ discrete controller).

## 2. Reproduction Results Table

| Step | Script Command | Output MAT File | Original Results | Audit Reproduction Results | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Step 1** | uild_and_run_stage1.m | Workspace | {ss} = 176.4706$ rad/s | {ss} = 176.4706$ rad/s | **REPRODUCED** |
| **Step 2** | uild_and_run_stage2.m | Workspace | Max Err $= 0.3600^\circ$ | Max Err $= 0.3600^\circ$ | **REPRODUCED** |
| **Step 3** | uild_and_run_stage3.m | stage3_data.mat | Linearity $= 0.7500$ | Linearity $= 0.7500$ | **REPRODUCED** |
| **Step 4** | uild_and_run_stage4.m | stage4_data.mat | Err $= 0.0384^\circ$, Overshoot $= 0\%$ | Err $= 0.0384^\circ$, Overshoot $= 0\%$ | **REPRODUCED** |
| **Step 5** | uild_and_run_stage5.m | stage5_data.mat | Phase 2 Err $= 0.4456^\circ$ | Phase 2 Err $= 0.4456^\circ$ | **REPRODUCED** |
| **Step 6** | uild_and_run_stage6.m | stage6_data.mat | Dwell Dev $= 0.2786^\circ, t_{rec}=0$ | Dwell Dev $= 0.2786^\circ, t_{rec}=0$ | **REPRODUCED** |
