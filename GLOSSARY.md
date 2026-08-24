# Project Technical Glossary & Symbol Reference

This document provides a concise reference guide to technical terms, physical parameters, control notation, and symbols used across the **STM32 Automated Precision Indexing & Feed Control System** (Stage 1 Simulation Prototype).

---

## 1. General Project Terms

* **Project Objective:** The overall goal of designing, modeling, and verifying a high-precision closed-loop position control system for DC motor actuators driving rotary indexing tables, tool changers, and automated feed mechanisms.
* **Simulation Prototype:** The software implementation of the electromechanical motor plant, optical encoder, PWM driver, discrete PID controller, profile generator, and disturbance models in MATLAB/Simulink.
* **Stage 1:** The first phase of the project, consisting of Steps 1 through 6, dedicated exclusively to constructing, validating, and freezing the Simulink simulation prototype before hardware or firmware development.
* **STM32 Target:** The intended 32-bit ARM Cortex-M microcontroller family targeted for future embedded controller deployment in Stage 2.
* **Indexing / Precision Positioning:** The act of moving an electromechanical actuator to precise target angular positions ($\theta$), stopping without overshoot, and holding position under external load torques.

---

## 2. Motor & Plant Parameters

* **$R$ (Armature Resistance):** Electrical resistance of the DC motor armature winding ($0.50\text{ }\Omega$).
* **$L$ (Armature Inductance):** Electrical inductance of the DC motor armature winding ($0.0005\text{ H}$ or $0.5\text{ mH}$).
* **$K_t$ (Torque Constant):** Motor electromagnetic torque constant relating armature current to motor torque ($0.050\text{ N}\cdot\text{m/A}$).
* **$K_e$ (Back-EMF Constant):** Motor voltage constant relating rotor angular speed to induced back-EMF voltage ($0.050\text{ V}\cdot\text{s/rad}$).
* **$J$ / $J_0$ (Rotor Inertia / Nominal Inertia):** Total moment of inertia of the motor rotor and load shaft. Nominal value $J_0 = 1.0 \times 10^{-5}\text{ kg}\cdot\text{m}^2$.
* **$B$ (Viscous Damping Coefficient):** Friction torque coefficient proportional to shaft angular speed ($1.0 \times 10^{-5}\text{ N}\cdot\text{m}\cdot\text{s/rad}$).
* **$V_{dc}$ (DC Bus Voltage):** Power supply voltage provided to the H-Bridge motor driver ($12.0\text{ V}$).
* **$T_L$ (Load Disturbance Torque):** External load torque applied to the motor shaft ($0.010\text{ N}\cdot\text{m}$).
* **$T_{stick}$ (Stiction Breakaway Torque):** Static friction torque required to initiate motion from standstill ($0.0020\text{ N}\cdot\text{m}$).
* **$T_{coulomb}$ (Coulomb Friction Torque):** Dynamic sliding friction torque opposing motion at non-zero speed ($0.0010\text{ N}\cdot\text{m}$).
* **$\omega$ / `omega` (Angular Speed):** Rotational velocity of the motor shaft in radians per second ($\text{rad/s}$).
* **$\theta$ / `theta` (Angular Position):** Continuous angular displacement of the motor shaft in radians ($\text{rad}$) or degrees ($\text{deg}$).
* **$i$ (Armature Current):** Electrical current flowing through the motor armature in Amperes ($\text{A}$).
* **$V_{eff}$ (Effective Motor Voltage):** Average terminal voltage applied across the motor armature by the PWM driver ($V_{eff} = d \cdot V_{dc}$).

---

## 3. Control-System Terms

* **$K_p$ (Proportional Gain):** PID gain multiplying position error directly ($0.50$ in discrete controller).
* **$K_i$ (Integral Gain):** PID gain multiplying accumulated position error to eliminate steady-state error ($8.00\text{ s}^{-1}$).
* **$K_d$ (Derivative Gain):** PID gain multiplying rate of change of position error to damp transient response ($0.0000$ in discrete controller).
* **$N$ (Derivative Filter Coefficient):** Low-pass filter coefficient for continuous derivative action ($N = 20$ in discrete PID block).
* **PID (Proportional-Integral-Derivative):** Feedback control algorithm generating control effort based on present, past, and future position error.
* **$T_s$ (Sample Time):** Discrete control loop update interval ($0.001\text{ s}$ or $1\text{ ms}$).
* **Sampling Frequency:** Reciprocal of sample time ($1 / T_s = 1000\text{ Hz}$ or $1\text{ kHz}$).
* **Steady-State Error ($e_{ss}$):** Positioning error remaining after transient oscillations have died out.
* **Tracking Error ($e_{true}$):** Real-time difference between reference position command $\theta_{ref}(t)$ and true shaft angle $\theta_{true}(t)$.
* **Overshoot:** Maximum percentage by which true position exceeds target reference position.
* **Settling Time ($t_s$):** Time required for position output to enter and remain within a specified error band (e.g., 2% band).
* **Anti-Windup:** Conditional integration clamping that pauses integral accumulation during duty cycle saturation ($d \notin [0, 1]$).
* **Feedforward:** Open-loop control compensation calculated directly from trajectory commands ($\theta_{ref}, \omega_{ref}, a_{ref}$) to improve tracking speed without introducing instability.

---

## 4. Trajectory & Motion Terms

* **Trapezoidal Velocity Profile:** Motion trajectory with constant acceleration, constant velocity (cruising), and constant deceleration phases.
* **Reference Position ($\theta_{ref}$):** Target angular position command generated by the trajectory planner.
* **Reference Velocity ($\omega_{ref}$):** Target angular velocity profile generated by the trajectory planner.
* **Reference Acceleration ($a_{ref}$):** Target angular acceleration profile generated by the trajectory planner.
* **$\omega_{max}$ (Cruising Speed Limit):** Maximum velocity constraint for profile generation ($8.0\text{ rad/s}$).
* **$a_{max}$ (Acceleration Limit):** Maximum acceleration/deceleration constraint for profile generation ($50.0\text{ rad/s}^2$).
* **Single Move:** Indexing operation executing a single move command (e.g., 90° indexing move).
* **Multi-Move Indexing:** Sequential execution of multiple indexing moves (e.g., $3\times$ 90° moves reaching 270°).

---

## 5. Encoder Terms

* **CPR (Counts Per Revolution):** Total quadrature edges per revolution ($1000\text{ CPR}$).
* **PPR (Pulses Per Revolution):** Physical optical disk lines per revolution ($250\text{ PPR}$).
* **Encoder Count ($N_{count}$):** Integer quadrature counter accumulated by decoding optical encoder signals.
* **Encoder Quantization:** Discretization of continuous continuous shaft position into integer step counts ($0.3600^\circ/\text{count}$).
* **True Position ($\theta_{true}$):** Actual continuous physical motor shaft angle.
* **Encoder Position ($\theta_{enc}$):** Measured angle derived from floor quantization of true position ($N_{count} \cdot \frac{2\pi}{1000}$).
* **Encoder Error ($e_{enc}$):** Position error calculated using encoder feedback ($\theta_{ref} - \theta_{enc}$).
* **One-Count Position Resolution:** Minimum resolvable physical displacement angle ($\Delta \theta_{res} = 0.3600^\circ$).

---

## 6. PWM & Actuation Terms

* **PWM (Pulse-Width Modulation):** High-frequency switching technique used to control effective motor terminal voltage.
* **Duty Cycle ($d$):** Normalized ratio of pulse high time to total period ($d(t) \in [0.0, 1.0]$).
* **Averaged PWM Model:** Simulation model replacing high-frequency switching with equivalent continuous average voltage ($V_{eff} = d \cdot V_{dc}$).
* **H-Bridge:** Power transistor topology allowing bidirectional current flow and voltage polarity across motor terminals.
* **Armature Current ($i(t)$):** Dynamic motor current driven by effective terminal voltage.
* **Applied Motor Voltage:** Effective terminal voltage applied across the motor winding.

---

## 7. Step 6 Robustness Terms

* **Load Disturbance:** External torque opposing motor motion ($T_L = 0.010\text{ N}\cdot\text{m}$).
* **In-Motion Load Step:** Load torque step applied during the acceleration phase of motion ($t = 0.200\text{ s}$).
* **In-Dwell Load Pulse:** Pulse disturbance applied while the system is holding position at rest ($t = 0.600\text{ s}$).
* **Disturbance Recovery Time ($t_{rec}$):** Time required for position error to re-enter and stay inside the $\pm 1\text{ count}$ bound after a disturbance pulse.
* **Nonlinear Friction:** Combined friction model including static stiction breakaway and sliding Coulomb friction.
* **Stiction:** Static breakaway friction resisting initial motion from zero speed ($T_{stick} = 0.0020\text{ N}\cdot\text{m}$).
* **Coulomb Friction:** Dynamic sliding friction opposing velocity ($T_{coulomb} = 0.0010\text{ N}\cdot\text{m}$).
* **Stribeck Friction Model:** Continuous friction model transitioning smoothly between stiction and Coulomb friction via exponential velocity dependence.
* **Inertia Sensitivity:** Robustness evaluation under payload inertia variations ($1\times J_0, 2\times J_0, 3\times J_0$).

---

## 8. Symbols Used in Equations

| Symbol | Meaning | Standard Unit | Where Used |
| :--- | :--- | :--- | :--- |
| $R$ | Armature Resistance | $\Omega$ (Ohm) | Motor electrical equation |
| $L$ | Armature Inductance | $\text{H}$ (Henry) | Motor electrical equation |
| $K_t$ | Torque Constant | $\text{N}\cdot\text{m/A}$ | Motor electromagnetic torque equation |
| $K_e$ | Back-EMF Constant | $\text{V}\cdot\text{s/rad}$ | Motor voltage equation |
| $J$ | Total Moment of Inertia | $\text{kg}\cdot\text{m}^2$ | Motor mechanical dynamics equation |
| $B$ | Viscous Damping | $\text{N}\cdot\text{m}\cdot\text{s/rad}$ | Mechanical damping equation |
| $V_{dc}$ | Driver Bus Voltage | $\text{V}$ (Volt) | PWM H-bridge actuation model |
| $d$ | Normalized Duty Cycle | Dimensionless ($[0, 1]$) | PWM actuation & saturated controller output |
| $T_L$ | External Load Torque | $\text{N}\cdot\text{m}$ | Mechanical plant sum node & load feedforward |
| $T_{fric}$ | Non-linear Friction Torque | $\text{N}\cdot\text{m}$ | Mechanical plant dynamics equation |
| $\omega$ | Shaft Angular Speed | $\text{rad/s}$ | Motor back-EMF & mechanical dynamics |
| $\theta_{true}$ | True Shaft Angle | $\text{rad}$ or $\text{deg}$ | Continuous plant ground truth |
| $\theta_{enc}$ | Quantized Encoder Angle | $\text{rad}$ or $\text{deg}$ | Discrete PID feedback input |
| $\theta_{ref}$ | Target Reference Angle | $\text{rad}$ or $\text{deg}$ | Kinematic profile generator output |
| $T_s$ | Discrete Control Sample Time | $\text{s}$ (Second) | Discrete PID controller ($T_s = 0.001\text{ s}$) |
| $K_{ff,v}$ | Velocity Feedforward Gain | $\text{V}/(\text{rad/s})$ | Profile velocity feedforward term |
| $K_{ff,a}$ | Acceleration Feedforward Gain | $\text{V}/(\text{rad/s}^2)$ | Profile acceleration feedforward term |
| $K_{ff,L}$ | Load Feedforward Gain | $\text{N}^{-1}\cdot\text{m}^{-1}$ | Physics load torque compensation |

---

## 9. Stage 1 Boundary

This glossary describes **Stage 1 (Complete Simulation Prototype)** functionality ONLY. 

The following advanced concepts belong to future project stages and are **NOT implemented in Stage 1**:
* **Disturbance Observer (DOB):** Sensorless load estimation (Stage 2).
* **Discrete Velocity Estimator ($\hat{\omega}$):** Filtering measured encoder position to derive speed (Stage 2).
* **STM32 Firmware:** 32-bit C code, HAL drivers, or CMSIS-DSP implementation (Stage 2).
* **Hardware Bench Testing:** Physical H-Bridge, physical gearmotor, or real-time hardware validation (Stage 3).

---

## How to Use This Glossary
Refer to this document while reviewing `README.md`, parameter files (`scripts/params.m`), MATLAB scripts (`build_and_run_stage*.m`), or Simulink models (`models/stage1_*.slx`). Every definition and parameter value matches the source-of-truth simulation implementation.
