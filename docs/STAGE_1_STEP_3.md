# Stage 1 — Step 3: Averaged PWM Motor Actuation Model

## 1. Objective & Overview

This document details **Stage 1 — Step 3** of **Project 2: STM32 Automated Precision Indexing & Feed Control**.

The objective of Step 3 is to introduce an **Averaged PWM Duty-Cycle Actuation Model** into the open-loop electromechanical motor plant system built in Steps 1 and 2. This step models how a digital PWM duty cycle command $d(t) \in [0.0, 1.0]$ scales the DC supply voltage to produce an effective continuous terminal voltage $V_{eff}(t)$ driving the motor plant.

> [!IMPORTANT]
> **Actuator Model Scope & Boundaries:**
> - **Model Type:** Averaged voltage actuation model ($V_{eff}(t) = d(t) \cdot V_{dc}$).
> - **Zero High-Frequency Switching Claims:** This model does **not** simulate MOSFET switching dynamics, H-bridge switching losses, dead time, gate driver delays, current ripple, or high-frequency carrier modulation.
> - **Hardware Target Reference:** PWM carrier frequency $f_{pwm} = 20\text{ kHz}$ is explicitly identified as a **future target hardware assumption** (for STM32 TIM1/TIM8 PWM timer setup) and is not an active switching parameter in the continuous plant differential equations.
> - **Plant Classification:** Single-axis DC equivalent electromechanical motor model.
> - **Strict Open-Loop:** No closed-loop PID controllers, Stateflow state machines, limit switches, or STM32 C code are included.
> - **Baseline Protection:** `models/stage1_motor_plant.slx` (Step 1) and `models/stage1_encoder_model.slx` (Step 2) remain 100% untouched.

---

## 2. Mathematical Formulation

### Actuation Voltage Relationship
The relationship between the digital duty cycle command $d(t)$ and effective motor armature terminal voltage $V_{eff}(t)$ is:

$$V_{eff}(t) = d(t) \cdot V_{dc}$$

where:
- $d(t) \in [0.0, 1.0]$ is the duty cycle command ($0.0 = 0\%$, $1.0 = 100\%$).
- $V_{dc} = 12.0\text{ V}$ is the constant DC bus supply voltage.
- $V_{eff}(t)$ is the effective continuous average voltage applied across the motor winding.

### Electromechanical Motor Plant State Equations
$$\frac{di(t)}{dt} = \frac{V_{eff}(t) - R \cdot i(t) - K_e \cdot \omega(t)}{L} = \frac{d(t) \cdot V_{dc} - R \cdot i(t) - K_e \cdot \omega(t)}{L}$$

$$T_e(t) = K_t \cdot i(t)$$

$$\frac{d\omega(t)}{dt} = \frac{T_e(t) - B \cdot \omega(t) - T_L}{J} \quad (T_L = 0)$$

$$\frac{d\theta(t)}{dt} = \omega(t)$$

---

## 3. Parameter Definitions

All parameters are specified in `scripts/params.m`:

| Parameter | Symbol | Value | Unit | Role / Physical Meaning |
| :--- | :---: | :---: | :---: | :--- |
| **DC Supply Voltage** | $V_{dc}$ | $12.0$ | $\text{V}$ | Supply voltage for averaged H-bridge model |
| **Full Duty Cycle Test** | $d_{full}$ | $1.00$ | $-$ | $100\%$ duty cycle command ($V_{eff} = 12.0\text{ V}$) |
| **Step Duty Cycle Test** | $d_{step}$ | $0.75$ | $-$ | $75\%$ duty cycle step command ($V_{eff} = 9.0\text{ V}$) |
| **Target PWM Frequency** | $f_{pwm}$ | $20$ | $\text{kHz}$ | Target hardware assumption for future STM32 timer setup |
| **Armature Resistance** | $R$ | $0.5$ | $\Omega$ | Preserved from Step 1 baseline |
| **Armature Inductance** | $L$ | $0.0005$ | $\text{H}$ | Preserved from Step 1 baseline |
| **Torque Constant** | $K_t$ | $0.05$ | $\text{N}\cdot\text{m/A}$ | Preserved from Step 1 baseline |
| **Back-EMF Constant** | $K_e$ | $0.05$ | $\text{V}\cdot\text{s/rad}$ | Preserved from Step 1 baseline |
| **Rotor Inertia** | $J$ | $1 \times 10^{-5}$ | $\text{kg}\cdot\text{m}^2$ | Preserved from Step 1 baseline |
| **Viscous Damping** | $B$ | $1 \times 10^{-5}$ | $\text{N}\cdot\text{m}\cdot\text{s/rad}$ | Preserved from Step 1 baseline |
| **Encoder Resolution** | $\text{CPR}$ | $1000$ | $\text{counts/rev}$ | Preserved from Step 2 baseline |

---

## 4. Simulink Model Architecture (`models/stage1_pwm_model.slx`)

```
Step Duty Cycle Input d(t)
           │
           ▼
┌──────────────────────┐  V_eff(t)  ┌──────────────────────┐  i(t)  ┌─────────┐ Te(t) ┌──────────────────────┐  w(t)  ┌──────────────┐ theta(t)
│ Gain: V_dc (12.0V)   │ ─────────> │ Electrical Dynamics  │ ────> │ Gain Kt │ ─────> │ Mechanical Dynamics  │ ────> │Position Integr│ ──────┐
└──────────────────────┘            └──────────────────────┘        └─────────┘        └──────────────────────┘       └──────────────┘       │
                                               ▲                                           ▲                                                 │
                                               │ -Ke*w                                     │ -B*w                                            ▼
                                               └───────────────────────────────────────────┴───────────────────────────────   ┌───────────────┐
                                                                                                                              │Step 2 Encoder │
                                                                                                                              │(1000 CPR Floor│
                                                                                                                              └───────────────┘
```

- **Actuation Path:** `Duty_Cycle_Input` ($d(t) = 0.75$) feeds `Gain_Vdc` ($12.0\text{ V}$), producing $V_{eff}(t) = 9.0\text{ V}$.
- **Motor Plant:** Continuous-time electromechanical equations integrated with solver `ode45`.
- **Encoder Path:** Passive $1000\text{ CPR}$ quantization path logging counts and measured position without feedback.

---

## 5. Analytical Reference Predictions vs Simulink Simulation Results

To enforce strict numerical data provenance, analytical predictions were calculated independently in MATLAB using analytical state equations and compared against actual Simulink outputs from `sim('stage1_pwm_model')`:

### Analytical Reference Formulas:
$$\omega_{ss,analytical}(d) = \frac{K_t \cdot (d \cdot V_{dc})}{B R + K_t K_e} = \frac{0.05 \cdot (d \cdot 12.0)}{0.002505}$$

$$i_{ss,analytical}(d) = \frac{(d \cdot V_{dc}) - K_e \cdot \omega_{ss,analytical}(d)}{R}$$

### Dynamic Convergence & Time Horizon Breakdown

The plant's equivalent electromechanical time constant is $\tau_{eq} \approx \frac{J R}{B R + K_t K_e} \approx 0.001996\text{ s} \approx 2\text{ ms}$.

- **At $t = 0.10\text{ s}$ ($50 \times \tau_{eq}$):** The motor response has reached **$> 99.98\%$** of its steady-state target and is evaluated as a **transient / near-steady-state result** with a tiny residual error of $\approx 0.019984\%$ ($\approx 0.0359\text{ rad/s}$ residual).
- **At $t = 0.50\text{ s}$ / $1.00\text{ s}$ ($> 250 \times \tau_{eq}$):** The motor response achieves **100% full convergence** to analytical predictions down to double-precision machine epsilon ($1.42 \times 10^{-13}\text{ rad/s}$ error, $7.91 \times 10^{-14}\%$ error).

### Empirical Verification Table:

| Simulation Horizon | Test Case | Metric | Analytical Prediction | Simulink Output Result | Calculated Error | Convergence Classification |
| :--- | :--- | :--- | :---: | :---: | :---: | :---: |
| **$t = 0.10\text{ s}$** | Case 1: $d = 1.00$ ($V_{eff} = 12.0\text{ V}$) | Speed $\omega(0.10\text{s})$ | $239.520958\text{ rad/s}$ | **$239.473092\text{ rad/s}$** | **$0.019984\%$** | Transient / Near-Steady-State ($> 99.98\%$) |
| | Case 2: $d = 0.75$ ($V_{eff} = 9.0\text{ V}$) | Speed $\omega(0.10\text{s})$ | $179.640719\text{ rad/s}$ | **$179.604819\text{ rad/s}$** | **$0.019984\%$** | Transient / Near-Steady-State ($> 99.98\%$) |
| | Encoder Counts ($d = 0.75$) | Counts at $t = 0.10\text{ s}$ | $\lfloor 15.8087 \times \frac{1000}{2\pi} \rfloor = 2516$ | **$2516\text{ counts}$** | **$0.000000\%$** | Exact Floor Integer Count |
| **$t = 0.50\text{ s}$ / $1.00\text{ s}$** | Case 1: $d = 1.00$ ($V_{eff} = 12.0\text{ V}$) | Steady-State Speed $\omega_{ss}$ | $239.520958\text{ rad/s}$ ($2287.26\text{ RPM}$) | **$239.520958\text{ rad/s}$** | **$8.31 \times 10^{-14}\%$** | **Fully Converged Steady-State ($100.00\%$)** |
| | Case 2: $d = 0.75$ ($V_{eff} = 9.0\text{ V}$) | Steady-State Speed $\omega_{ss}$ | $179.640719\text{ rad/s}$ ($1715.44\text{ RPM}$) | **$179.640719\text{ rad/s}$** | **$7.91 \times 10^{-14}\%$** | **Fully Converged Steady-State ($100.00\%$)** |
| | Actuation Linearity | Ratio $\frac{\omega_{ss}(0.75)}{\omega_{ss}(1.00)}$ | $0.750000$ | **$0.750000$** | **$0.000000\%$** | **Exact Actuation Linearity Match** |

---

## 6. Plot Visualizations

### 1. Averaged PWM Voltage Actuation Signal Chain
![PWM Voltage vs Time](results/stage1/pwm_voltage_vs_time.png)

### 2. Electromechanical Motor Speed Response ($d = 1.00$ vs $d = 0.75$)
![PWM Speed Response](results/stage1/pwm_speed_response.png)

### 3. Open-Loop Actuation Dashboard ($d = 0.75$)
![PWM Actuation Dashboard](results/stage1/pwm_actuation_dashboard.png)

---

## 7. Assumptions & Limitations

### Assumptions:
1. Ideal averaged voltage scaling ($V_{eff} = d \cdot V_{dc}$) across the DC motor terminal.
2. Constant DC supply voltage $V_{dc} = 12.0\text{ V}$ with zero source impedance.
3. Unloaded motor shaft ($T_L = 0$).

### Limitations:
1. High-frequency PWM switching harmonics, MOSFET switching losses, dead time, and current ripple are not modeled in this continuous-time averaged representation.
2. System remains strictly open-loop; duty cycle command $d(t)$ is manually set rather than automatically controlled by a feedback algorithm.

---

## 8. Implemented vs Remaining

### IMPLEMENTED NOW (Stage 1 Step 3):
- Preserved Step 1 (`models/stage1_motor_plant.slx`) and Step 2 (`models/stage1_encoder_model.slx`) baseline models.
- Created Step 3 model (`models/stage1_pwm_model.slx`).
- Averaged PWM duty cycle actuation model ($V_{eff} = d \cdot V_{dc}$).
- Simulation execution, analytical vs simulation provenance validation, transient vs fully converged steady-state classification, data export to `stage3_data.mat`, and Python plot generation.

### REMAINING FOR LATER STAGES:
- Closed-loop position / speed controllers (e.g. PID).
- Limit switches / homing logic.
- Stateflow state machine indexing logic.
- High-frequency carrier switching models or physical H-bridge driver dynamics.
- STM32 Embedded C code generation and target hardware deployment.
