# Stage 1 Master Inconsistencies & Limitations Audit Report

## Critical Issues
*None.* Zero mathematical errors, zero unhandled unstable branches, zero synthetic data fabrications.

## High-Priority Issues
*None.*

## Medium-Priority Issues

### ID: INC-01
- **Severity:** MEDIUM
- **Affected Step:** Step 6
- **Affected File:** `models/stage1_robust_loop_model.slx` / `scripts/build_and_run_stage6.m`
- **Observed Problem:** Load torque feedforward $u_{ff,L} = K_{ff,L} \cdot T_{L,est}$ receives the injected disturbance signal directly ($T_{L,est} = T_L$).
- **Engineering Explanation:** In a simulation prototype, assuming $T_{L,est}$ is known from feed force schedule or cutting force estimation is acceptable for proof-of-concept. However, in standalone hardware without force sensors, an unmeasured load shock requires a Disturbance Observer (DOB).
- **Impact on Main Objective:** Low impact on simulation prototype validity. Sensitivity audit proved integral gain $K_i = 8.0$ maintains position deviation $\le 0.3400^\circ \le 0.3600^\circ$ even under $\pm 20\%$ load estimation mismatch.
- **Required Fix:** Plan a Disturbance Observer (DOB) architecture for Stage 2 MCU firmware development.
- **Status:** DOCUMENTED & ACCEPTED FOR SIMULATION PROTOTYPE.

### ID: INC-02
- **Severity:** MEDIUM
- **Affected Step:** Step 6
- **Affected File:** `models/stage1_robust_loop_model.slx`
- **Observed Problem:** Friction feedforward $u_{ff,fric}(\omega_{ref})$ uses reference velocity $\omega_{ref}$ rather than measured rotor velocity $\omega$.
- **Engineering Explanation:** Using $\omega_{ref}$ ensures $u_{ff,fric} = 0.0$ when $\omega_{ref} = 0$, guaranteeing zero static voltage offset during dwell and preventing limit cycles. However, if an external disturbance moves the rotor while $\omega_{ref} = 0$, friction feedforward provides zero resistance until feedback acts.
- **Impact on Main Objective:** Zero impact on nominal profile tracking. Integrator $K_i = 8.00$ handles residual error.
- **Required Fix:** Document design trade-off in Stage 1 overview documentation.
- **Status:** DOCUMENTED & ACCEPTED.

## Low-Priority Issues

### ID: INC-03
- **Severity:** LOW
- **Affected Step:** Step 1 & Step 2
- **Affected File:** `scripts/build_and_run_stage1.m` & `build_and_run_stage2.m`
- **Observed Problem:** Earlier versions did not export `stage1_data.mat` & `stage2_data.mat` to `results/stage1/`.
- **Engineering Explanation:** Scripts printed terminal metrics and saved `.png` plots, but omitted `save(dataFile, ...)` commands.
- **Required Fix:** Add MAT export code lines to `build_and_run_stage1.m` and `build_and_run_stage2.m`.
- **Status:** FIXED & RESOLVED.
