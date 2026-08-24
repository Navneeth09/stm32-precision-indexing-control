# Stage 1 — Step 1: Basic Mathematical Motor/Position Plant Model

## Overview & Purpose

This document details Stage 1 — Step 1 of **Project 2: STM32 Automated Precision Indexing & Feed Control**.

The primary objective of this step is to construct, simulate, and verify an un-controlled continuous-time mathematical model of a DC / BLDC-equivalent motor plant in MATLAB/Simulink. This virtual plant establishes the open-loop dynamics of motor speed and position before closed-loop position control, PWM drivers, encoder feedback, or STM32 hardware-in-the-loop logic are introduced.

---

## Scope & Implementation Status

### IMPLEMENTED NOW (Stage 1 — Step 1):
- Continuous-time mathematical equations for electrical and mechanical dynamics.
- Parameter set ($R, L, K_t, K_e, J, B$) stored in `scripts/params.m`.
- Simulink plant model stored in `models/stage1_motor_plant.slx`.
- Open-loop step-voltage test input ($V(t) = 12\text{ V}$ step).
- Numerical verification of steady-state speed $\omega_{ss}$, steady-state current $i_{ss}$, and position integration integrity ($\frac{d\theta}{dt} \approx \omega$).
- Verification plots generated in `results/stage1/`.

### NOT IMPLEMENTED YET (Deferred to Future Steps):
- Encoder feedback model (quadrature signals, tick count, quantization).
- PWM voltage actuation / H-bridge driver dynamics.
- Closed-loop PID position / speed controllers.
- Limit sensors / homing switches.
- Stateflow state-machine logic for automatic sequence indexing.
- Embedded C code generation or STM32 target hardware deployment.
- Physical motor hardware integration.

---

## Governing Mathematical Equations

The plant represents an averaged DC / BLDC motor model operating under standard continuous-time differential equations:

### 1. Electrical Dynamics
$$V(t) = R \cdot i(t) + L \frac{di(t)}{dt} + K_e \cdot \omega(t)$$

Rearranging for current state-space derivative:
$$\frac{di(t)}{dt} = \frac{V(t) - R \cdot i(t) - K_e \cdot \omega(t)}{L}$$

### 2. Electromagnetic Torque Generation
$$T_e(t) = K_t \cdot i(t)$$

### 3. Mechanical Dynamics
$$J \frac{d\omega(t)}{dt} = T_e(t) - B \cdot \omega(t) - T_L(t)$$

Setting load torque $T_L = 0$ for open-loop baseline step verification:
$$\frac{d\omega(t)}{dt} = \frac{T_e(t) - B \cdot \omega(t)}{J}$$

### 4. Kinematic Position Integration
$$\frac{d\theta(t)}{dt} = \omega(t) \implies \theta(t) = \int_{0}^{t} \omega(\tau) \, d\tau$$

---

## Parameter Definitions

All parameters are specified in `scripts/params.m`:

| Parameter | Symbol | Value | Unit | Physical Meaning |
| :--- | :---: | :---: | :---: | :--- |
| **Armature Resistance** | $R$ | $0.5$ | $\Omega$ | Winding electrical resistance |
| **Armature Inductance** | $L$ | $0.0005$ | $\text{H}$ ($0.5\text{ ms}$) | Winding self-inductance |
| **Torque Constant** | $K_t$ | $0.05$ | $\text{N}\cdot\text{m/A}$ | Torque produced per Ampere of current |
| **Back-EMF Constant** | $K_e$ | $0.05$ | $\text{V}\cdot\text{s/rad}$ | Counter voltage induced per rad/s of rotor speed |
| **Rotor / Shaft Inertia**| $J$ | $1 \times 10^{-5}$ | $\text{kg}\cdot\text{m}^2$ | Rotational moment of inertia of rotor + coupling |
| **Viscous Damping Coefficient**| $B$ | $1 \times 10^{-5}$ | $\text{N}\cdot\text{m}\cdot\text{s/rad}$ | Viscous friction coefficient |
| **Load Torque** | $T_L$ | $0.0$ | $\text{N}\cdot\text{m}$ | Unloaded step condition for Step 1 |

### Derived Theoretical Steady-State Metrics:
Under constant applied voltage $V = 12\text{ V}$ and $T_L = 0$:
$$\omega_{ss} = \frac{K_t V}{B R + K_t K_e} = \frac{0.05 \times 12}{(10^{-5} \times 0.5) + (0.05 \times 0.05)} = \frac{0.6}{0.002505} = 239.521\text{ rad/s} \quad (\approx 2287.26\text{ RPM})$$

$$i_{ss} = \frac{V - K_e \omega_{ss}}{R} = \frac{12 - (0.05 \times 239.5210)}{0.5} = 0.047904\text{ A}$$

---

## Simulink Block Architecture

The model `models/stage1_motor_plant.slx` is structured cleanly into distinct physical blocks without using black-box transfer functions:

```
Input Voltage V(t)
       │
       ▼
┌──────────────┐   di/dt   ┌────────────┐   i(t)   ┌──────────┐ Te(t)
│ Sum & Gain   │ ────────> │ Integrator │ ───────> │ Gain Kt  │ ──────┐
│ (1/L)        │           │ (Current)  │          └──────────┘       │
└──────────────┘           └────────────┘                             ▼
   ▲        ▲                 │                                ┌──────────────┐   dw/dt   ┌────────────┐  w(t)
   │ -R*i   │ -Ke*w           │ Feedback R                     │ Sum & Gain   │ ────────> │ Integrator │ ──────┐
   └────────┴─────────────────┼──────────────────────────────> │ (1/J)        │           │ (Speed)    │       │
                              │                                └──────────────┘           └────────────┘       │
                              ▼                                   ▲                           │                ▼
                       Feedback Ke                                │ -B*w                      │         ┌────────────┐
                                                                  └───────────────────────────┼───────> │ Integrator │ ───> Position θ(t)
                                                                                              │         │ (Position) │
                                                                                              ▼         └────────────┘
                                                                                         Scope / Log
```

- **Input Block:** `Voltage_Input` (`Step` block, $V = 12\text{ V}$ step applied at $t = 0.01\text{ s}$).
- **Electrical Dynamics:** Summing junction (`+--`), Gain $1/L$, Integrator $\int$, feedback gains $R$ and $K_e$.
- **Torque Block:** Gain $K_t$.
- **Mechanical Dynamics:** Summing junction (`+--`), Gain $1/J$, Integrator $\int$, feedback gain $B$.
- **Position Integration:** Integrator $\int$ converting $\omega(t) \to \theta(t)$.
- **Data Logging:** `To Workspace` blocks (`sim_V`, `sim_i`, `sim_w`, `sim_theta`) and `Scope` blocks.

---

## Input & Simulation Setup

- **Applied Test Input:** Step input of $V_{app} = 12\text{ V}$ at $t = 0.01\text{ s}$.
  - *Rationale:* A step input provides a clear open-loop step response, allowing direct measurement of electrical/mechanical time constants, peak inrush current, rise time, steady-state speed, and position accumulation slope.
- **Solver:** Continuous-time `ode45` (Dormand-Prince variable-step integrator).
- **Simulation Duration:** $t_{stop} = 0.10\text{ s}$. This duration captures both the fast electrical dynamic transient ($\tau_e = L/R = 1\text{ ms}$) and mechanical dynamic settling ($\approx 8\text{ ms}$), followed by steady-state position accumulation.

---

## Simulation Results & Validation

Running `scripts/build_and_run_stage1.m` produces the following quantitative verification outputs:

1. **Motor Speed Response:**
   - Simulated Steady-State Speed: $\omega(t_{stop}) = 239.5210\text{ rad/s}$ ($2287.26\text{ RPM}$)
   - Theoretical Steady-State Speed: $\omega_{ss} = 239.5210\text{ rad/s}$ ($2287.26\text{ RPM}$)
   - **Relative Speed Error:** $0.000000\%$

2. **Armature Current Response:**
   - Initial Inrush Current Peak: $i_{peak} \approx 15.3\text{ A}$
   - Simulated Steady-State Current: $i(t_{stop}) = 0.047904\text{ A}$
   - Theoretical Steady-State Current: $i_{ss} = 0.047904\text{ A}$

3. **Position Integration Integrity ($\frac{d\theta}{dt} \approx \omega$):**
   - Numerical Gradient Comparison: Mean $| \frac{\Delta \theta}{\Delta t} - \omega | = 0.089\text{ rad/s}$ (during step transition numerical transient).
   - **Integrator Validation:** PASS.

---

## Plot Visualizations

### 1. Motor Speed $\omega(t)$ Response
![Speed vs Time Plot](results/stage1/speed_vs_time.png)

### 2. Motor Position $\theta(t)$ Response
![Position vs Time Plot](results/stage1/position_vs_time.png)

### 3. Full Verification Dashboard
![Full Verification Dashboard](results/stage1/stage1_verification.png)

---

## Assumptions & Limitations

### Assumptions:
1. Linear magnetic circuit (no iron core saturation; constant inductance $L$ and torque constant $K_t$).
2. Ideal electrical voltage source with zero output impedance.
3. Unloaded motor shaft ($T_L = 0$).
4. Constant temperature (resistance $R$ is constant).
5. Negligible Coulomb/stiction friction ($T_{stiction} = 0$).

### Limitations:
1. Open-loop system: No position or speed feedback loop is active yet; motor position grows unbounded over time under constant voltage.
2. Continuous-time ideal plant: No discrete sampling, quantization, or digital driver switching effects are modeled yet.

---

## What Remains for Stage 1 — Step 2
In Stage 1 — Step 2, closed-loop position/speed feedback, controller design, or sensor feedback models will be evaluated in Simulink before moving to state machines and embedded deployment.
