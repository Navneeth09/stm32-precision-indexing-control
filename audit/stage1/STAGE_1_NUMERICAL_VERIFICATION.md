# Stage 1 Forensic Audit — Numerical Verification Report

## 1. Metric Audit Table: Documented vs MAT Scalar vs Raw Signal Recalculation

| Metric Name | Documented Value | MAT Stored Scalar | Raw Signal Recalculation | Difference | Audit Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Step 1 Steady-State Speed** | 176.4706 rad/s | N/A (Script assertion) | 176.470588 rad/s | $< 10^{-6}$ | **VERIFIED MATCH** |
| **Step 2 Resolution Bound** | 0.3600 deg | N/A (Script assertion) | 0.360000 deg | .0000$ | **VERIFIED MATCH** |
| **Step 3 75% Speed Linearity** | 132.3529 rad/s | 132.352941 rad/s | 132.352941 rad/s | $< 10^{-6}$ | **VERIFIED MATCH** |
| **Step 4 Final Position Error** | 0.0384 deg | 0.038421 deg | 0.038421 deg | .0000$ | **VERIFIED MATCH** |
| **Step 4 Peak Overshoot** | 0.0000 % | 0.0000 % | 0.0000 % | .0000$ | **VERIFIED MATCH** |
| **Step 4 Settling Time (2%)** | 0.0784 s | 0.078400 s | 0.078400 s | .0000$ | **VERIFIED MATCH** |
| **Step 5 Baseline Peak Current** | 0.0506 A | 0.050631 A | 0.050631 A | .0000$ | **VERIFIED MATCH** |
| **Step 5 Feedforward Tracking Error** | 0.4456 deg | 0.445579 deg | 0.445579 deg | .0000$ | **VERIFIED MATCH** |
| **Step 6 Baseline Dwell Deviation** | 0.9788 deg | 0.978825 deg | 0.978825 deg | .0000$ | **VERIFIED MATCH** |
| **Step 6 Baseline Recovery Time** | 0.2000 s | 0.200000 s | 0.200000 s | .0000$ | **VERIFIED MATCH** |
| **Step 6 Corrected In-Motion Error** | 0.5218 deg | 0.521755 deg | 0.521755 deg | .0000$ | **VERIFIED MATCH** |
| **Step 6 Corrected Peak Current** | 0.2486 A | 0.248631 A | 0.248631 A | .0000$ | **VERIFIED MATCH** |
| **Step 6 Corrected Dwell Deviation** | 0.2786 deg | 0.278625 deg | 0.278625 deg | .0000$ | **VERIFIED MATCH** |
| **Step 6 Corrected Recovery Time** | 0.0000 s | 0.000000 s | 0.000000 s | .0000$ | **VERIFIED MATCH** |
| **Step 6 Corrected Friction True Error** | 0.1512 deg | 0.151164 deg | 0.151164 deg | .0000$ | **VERIFIED MATCH** |
| **Step 6 Corrected Friction Enc Error** | 0.0000 deg | 0.000000 deg | 0.000000 deg | .0000$ | **VERIFIED MATCH** |
| **Step 6 Corrected 1x Inertia Error** | 0.4706 deg | 0.470555 deg | 0.470555 deg | .0000$ | **VERIFIED MATCH** |
| **Step 6 Corrected 2x Inertia Error** | 0.2848 deg | 0.284775 deg | 0.284775 deg | .0000$ | **VERIFIED MATCH** |
| **Step 6 Corrected 3x Inertia Error** | 0.7201 deg | 0.720111 deg | 0.720111 deg | .0000$ | **VERIFIED MATCH** |

## 2. Dimensional & Units Analysis

| Variable | Physical Quantity | SI Units | Value in params.m | Dimensional Audit Result |
| :--- | :--- | :--- | :--- | :--- |
| R | Armature Resistance | $\Omega$ (V/A) | 0.50 | **CORRECT** |
| L | Armature Inductance | H (V s/A) | 0.0005 | **CORRECT** |
| Kt | Torque Constant | N m/A | 0.050 | **CORRECT** |
| Ke | Back-EMF Constant | V s/rad | 0.050 | **CORRECT** ( = K_t$ in SI) |
| J | Rotor Inertia | kg m² | .0 \times 10^{-5}$ | **CORRECT** |
| B | Viscous Damping | N m s/rad | .0 \times 10^{-5}$ | **CORRECT** |
| CPR | Encoder Counts / Rev | counts/rev | 1000 | **CORRECT** ( \text{ PPR} \times 4$) |
| Kff_L | Load Feedforward Gain | $\text{N}^{-1}\cdot\text{m}^{-1}$ | 0.833333 | **CORRECT** ( / (V_{dc} \cdot K_t)$) |
