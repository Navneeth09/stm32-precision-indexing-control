STM32 Automated Precision Indexing & Feed Control

[![Stage 1 Status](https://img.shields.io/badge/Stage_1-Simulation_Prototype_Verified-success.svg)](#stage-1-scope)
[![MATLAB/Simulink](https://img.shields.io/badge/MATLAB-R2023b%20%7C%20R2024a%20%7C%20R2025a-blue.svg)](https://www.mathworks.com/)
[![Python](https://img.shields.io/badge/Python-3.9%2B-blue.svg)](https://www.python.org/)

---

## Project Objective
Precision indexing and feed control systems (e.g., CNC rotary tables, automated feed mechanisms, precision optical stage indexers) require sub-degree position accuracy, zero overshoot, rapid settling times, and robust disturbance rejection under varying load torques and non-linear friction.

This project designs, verifies, and deploys a complete closed-loop position control architecture for a DC motor electromechanical plant using discrete PID control, kinematic feedforward, Stribeck friction compensation, and disturbance rejection.

---

## Project Architecture & Roadmap

```
+-----------------------------------------------------------------------------------+
|                            PROJECT ROADMAP & MILESTONES                           |
+-----------------------------------------------------------------------------------+
|  [CURRENT MILESTONE]                                                              |
|  Stage 1: Complete Simulation Prototype (Steps 1–6)      <-- VERIFIED & FROZEN   |
|  - MATLAB/Simulink electromechanical plant, encoder, PWM, discrete PID,           |
|    trapezoidal profiling, physics feedforward, and robustness analysis.           |
+-----------------------------------------------------------------------------------+
|  [UPCOMING MILESTONES]                                                            |
|  Stage 2: Embedded Real-Time Firmware & Disturbance Observer (DOB)                |
|  - STM32 C firmware, 1 kHz TIM interrupt, CMSIS-DSP, Disturbance Observer (DOB).  |
|                                                                                   |
|  Stage 3: STM32 Hardware-in-the-Loop (HIL) & Physical Validation                  |
|  - STM32 Nucleo/Discovery evaluation, H-bridge driver, optical encoder HIL test. |
+-----------------------------------------------------------------------------------+
```

> [!IMPORTANT]
> **Current Repository Status:**
> - **CURRENTLY COMPLETED:** Stage 1 — Complete Simulation Prototype (Steps 1 through 6).
> - **NOT YET IMPLEMENTED:** Stage 2 — Embedded Firmware & DOB / Stage 3 — Physical STM32 Hardware Validation.

---

## Stage 1 Scope (Steps 1 through 6)
Stage 1 establishes a physically consistent MATLAB/Simulink simulation model across six progressive technical steps:

1. **Step 1 — Motor Electromechanical Dynamics:** First-principles ODE model ($R, L, K_t, K_e, J, B$).
2. **Step 2 — 1000 CPR Encoder Feedback:** 4x quadrature floor quantization ($0.3600^\circ/\text{count}$).
3. **Step 3 — Averaged PWM Actuator:** Voltage duty-cycle scaling $V_{eff} = d \cdot V_{dc}$ ($V_{dc} = 12.0\text{ V}$).
4. **Step 4 — Continuous Closed-Loop Control:** Parallel PID position control ($0.0384^\circ$ steady-state error, $0\%$ overshoot).
5. **Step 5 — Discrete Trajectory & Multi-Move Indexing:** 1 kHz discrete PID ($T_s = 1\text{ ms}$) + Trapezoidal profile + Kinematic feedforward ($u_{ff,v}, u_{ff,a}$).
6. **Step 6 — Robustness & Friction Analysis:** Physics load feedforward ($u_{ff,L}$), continuous Stribeck friction feedforward ($u_{ff,fric}$), and payload inertia sweeps ($1\times, 2\times, 3\times J_0$).

---

## System Architecture

```
                                              +-------------------------------------------------------------+
                                              |                   PHYSICAL FEEDFORWARD                      |
                                              |  u_ff,v = Kff_v * w_ref    u_ff,a = Kff_a * a_ref           |
                                              |  u_ff,L = Kff_L * TL_est   u_ff,fric = f(w_ref)             |
                                              +------------------------------+------------------------------+
                                                                             |
                                                                             v
+-----------------------+     theta_ref     +------------------+  u_pid   +---+  u_total  +----------------+  V_eff  +-----------------+
| Trapezoidal Kinematic |------------------>| Discrete PID     |--------->| + |---------->| Averaged PWM   |-------->| Electromechanical|
| Profile Generator     |  w_ref, a_ref     | Controller       |          +---+           | H-Bridge Model |         | DC Motor Plant  |
+-----------------------+   (1 kHz)         | (Ts = 1 ms)      |            ^             +----------------+         +--------+--------+
                                            +------------------+            |                                                | w(t), theta_true
                                                      ^                     | Load Disturbance T_L(t)                        v
                                                      |                     v Striction & Coulomb Friction         +------------------+
                                                      |             +---------------+                              | 1000 CPR Optical |
                                                      +-------------| Quantization  |<-----------------------------| Quadrature       |
                                                       theta_enc    | floor(N_c)    |          theta_true          | Encoder          |
                                                                    +---------------+                              +------------------+
```

---

## Key Parameters

| Parameter Category | Symbol / Parameter | Value | Units |
| :--- | :--- | :--- | :--- |
| **System Timing** | Sample Time $T_s$ | $0.001$ ($1\text{ kHz}$) | $\text{s}$ |
| **Feedback Sensor** | Encoder Resolution | $1000$ ($250\text{ PPR} \times 4$) | $\text{CPR}$ |
| **Encoder Resolution** | $\Delta \theta_{res}$ | $0.3600^\circ$ ($0.006283$) | $\text{deg / count}$ |
| **Actuator Voltage** | Supply Voltage $V_{dc}$ | $12.0$ | $\text{V}$ |
| **Motor Resistance** | Armature Resistance $R$ | $0.50$ | $\Omega$ |
| **Motor Inductance** | Armature Inductance $L$ | $0.0005$ ($0.5\text{ mH}$) | $\text{H}$ |
| **Torque Constant** | $K_t$ | $0.050$ | $\text{N}\cdot\text{m/A}$ |
| **Back-EMF Constant**| $K_e$ | $0.050$ | $\text{V}\cdot\text{s/rad}$ |
| **Rotor Inertia** | Nominal Inertia $J_0$ | $1.0 \times 10^{-5}$ | $\text{kg}\cdot\text{m}^2$ |
| **Viscous Damping** | Damping Coefficient $B$ | $1.0 \times 10^{-5}$ | $\text{N}\cdot\text{m}\cdot\text{s/rad}$ |
| **Discrete PID Gains**| $K_p, K_i, K_d, N$ | $0.50, 8.00, 0.00, 20$ | — |
| **Kinematic Profile** | Max Speed $\omega_{max}$, Accel $a_{max}$ | $8.0\text{ rad/s}, 50.0\text{ rad/s}^2$ | — |
| **Load Feedforward** | Gain $K_{ff,L}$ | $0.833333$ | $\text{N}^{-1}\cdot\text{m}^{-1}$ |
| **Stiction / Coulomb**| $T_{stick}, T_{coulomb}$ | $0.0020, 0.0010$ | $\text{N}\cdot\text{m}$ |

---

## Validated Stage 1 Performance Summary

| Verification Metric | Target Constraint | Stage 1 Result | Compliance |
| :--- | :--- | :--- | :--- |
| **Step 1 Motor Steady-State Speed** | $176.4706\text{ rad/s}$ | **$176.4706\text{ rad/s}$** ($1685.2\text{ RPM}$) | **PASS** |
| **Step 2 Encoder Max Error Bound** | $\le 0.3600^\circ$ ($1\text{ count}$) | **$0.3600^\circ$** ($1.0\text{ count}$) | **PASS** |
| **Step 3 PWM Actuation Linearity** | $< 0.01\%$ ratio error | **$< 0.0001\%$** error | **PASS** |
| **Step 4 Step Response Overshoot** | $0.00\%$ peak overshoot | **$0.00\%$** overshoot | **PASS** |
| **Step 4 2% Settling Time** | $\le 100\text{ ms}$ | **$78.4\text{ ms}$** | **PASS** |
| **Step 5 Dynamic Tracking Error** | $\le 1.7200^\circ$ | **$0.4456^\circ$** | **PASS** |
| **Step 6 In-Motion Step Tracking Error** | $\le 1.7200^\circ$ | **$0.5218^\circ$** | **PASS** |
| **Step 6 In-Motion Peak Current** | $\le 1.5000\text{ A}$ | **$0.2486\text{ A}$** ($248.6\text{ mA}$) | **PASS** |
| **Step 6 In-Dwell Pulse Deviation** | $\le 0.3600^\circ$ ($1\text{ count}$) | **$0.2786^\circ$** ($0.77\text{ counts}$) | **PASS** |
| **Step 6 In-Dwell Recovery Time** | $\le 0.0500\text{ s}$ | **$0.0000\text{ s}$** ($0\text{ ms}$) | **PASS** |
| **Step 6 Final True Friction Error** | $\le 0.3600^\circ$ | **$0.1512^\circ$** | **PASS** |
| **Step 6 Final Encoder Error** | $\le 0.3600^\circ$ ($1\text{ count}$) | **$0.0000^\circ$** ($0\text{ counts}$) | **PASS** |
| **Step 6 Inertia Sweep ($1\times, 2\times, 3\times J_0$)**| $\le 1.7200^\circ$ | **$0.47^\circ, 0.28^\circ, 0.72^\circ$** | **PASS** |

---

## How To Run & Reproduce

### Single-Command MATLAB Execution
1. Open **MATLAB** (R2023b or newer).
2. Set the repository root directory as current working folder:
   ```matlab
   cd('path/to/Project2')
   ```
3. Execute the master entry point script:
   ```matlab
   run_stage1
   ```
4. All simulation datasets will be saved into [`results/stage1/`](results/stage1/) and summary verification statistics printed to the Command Window.

### Python Plot Dashboard Generation (Optional)
To regenerate publication-ready figure dashboards:
```bash
pip install -r requirements/python_requirements.txt
python scripts/generate_stage6_plots.py
```

---

## Reproducibility & Environment Specs
- **Tested MATLAB Environment:** MATLAB R2025a (64-bit Windows)
- **Required Toolboxes:** Simulink, Control System Toolbox
- **Python Environment:** Python 3.12 (`numpy`, `scipy`, `matplotlib`)
- **Total Execution Time:** $\approx 15\text{ seconds}$ for full 6-step pipeline execution.

---

## Known Project Limitations
1. **Simulation Prototype Scope:** Stage 1 represents a software simulation model; real STM32 hardware target code will be introduced in Stage 2.
2. **Encoder Noise:** Encoder feedback models spatial quantization but does not model high-frequency sensor electrical jitter or EMI.
3. **Load Torque Estimate Assumption:** Step 6 load feedforward ($u_{ff,L}$) currently assumes known direct load torque ($T_{L,est}$). Stage 2 firmware will implement a **Disturbance Observer (DOB)** to estimate load torque sensorlessly.
