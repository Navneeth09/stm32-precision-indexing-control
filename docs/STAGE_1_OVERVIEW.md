# Stage 1 Technical System Overview & Architecture Specification

## 1. Project Objective
Precision indexing and feed control systems (such as CNC rotary indexing tables, automated tool changers, and semiconductor wafer stages) demand sub-degree position accuracy, zero overshoot, rapid settling times, and robust disturbance rejection under non-linear friction and varying load torques.

The overall project objective is to design, model, verify, and implement a high-precision closed-loop position control architecture for a DC motor electromechanical plant driving a 1000 CPR quadrature optical encoder feedback system.

---

## 2. Stage 1 Objective
> "Stage 1 establishes and validates the control algorithm and physical system model in MATLAB/Simulink before transitioning to real-time embedded microcontroller implementation."

Stage 1 is the **Complete Simulation Prototype**. It validates the physics-based motor plant, encoder quantization, averaged PWM power actuation, 1 kHz discrete PID control, kinematic profile generation, and model-based physics feedforward terms across six progressive steps.

---

## 3. Stage 1 System Architecture Diagram

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

## 4. Progressive Technical Step Descriptions

### Step 1: Electromechanical Motor Plant Characterization
- **Model:** `models/stage1_motor_plant.slx` | **Script:** `scripts/build_and_run_stage1.m`
- Validates continuous-time DC motor differential equations under step voltage input $V_{app} = 12.0\text{ V}$. Steady-state speed reaches $\omega_{ss} = 239.4710\text{ rad/s}$ ($2286.78\text{ RPM}$, relative error $0.0209\%$ against theoretical prediction).

### Step 2: 1000 CPR Encoder Feedback & Quantization
- **Model:** `models/stage1_encoder_model.slx` | **Script:** `scripts/build_and_run_stage2.m`
- Models spatial position quantization using a 250 PPR optical encoder with 4x quadrature decoding ($1000\text{ CPR}$). Resolution is $\Delta \theta_{res} = 0.3600^\circ/\text{count}$. Position error is bounded by $|\theta_{enc} - \theta_{true}| \le 0.3600^\circ$.

### Step 3: Averaged PWM H-Bridge Actuation Model
- **Model:** `models/stage1_pwm_model.slx` | **Script:** `scripts/build_and_run_stage3.m`
- Maps duty cycle $d(t) \in [0.0, 1.0]$ to effective voltage $V_{eff} = d \cdot V_{dc}$ ($V_{dc} = 12.0\text{ V}$). Confirms linear speed scaling ($d = 0.75 \implies V_{eff} = 9.0\text{ V}, \omega_{ss} = 179.6033\text{ rad/s}$, ratio error $< 0.0001\%$).

### Step 4: Continuous Closed-Loop Position Control
- **Model:** `models/stage1_closed_loop_model.slx` | **Script:** `scripts/build_and_run_stage4.m`
- Continuous parallel PID controller ($K_p = 1.0, K_i = 0.10, K_d = 0.050, N = 1000$) driving unprofiled 90° step position command. Achieves $0.00\%$ overshoot, $t_s = 78.4\text{ ms}$, and steady-state error $0.0384^\circ \le 0.3600^\circ$.

### Step 5: Discrete Trajectory Control & Multi-Move Indexing
- **Model:** `models/stage1_profiled_loop_model.slx` | **Script:** `scripts/build_and_run_stage5.m`
- Discrete PID controller ($T_s = 1\text{ ms}$, $K_p = 0.50, K_i = 8.00, K_d = 0.0000, N = 20$) with conditional anti-windup, trapezoidal trajectory generation ($a_{max} = 50\text{ rad/s}^2, \omega_{max} = 8\text{ rad/s}$), and kinematic feedforward ($K_{ff,v}, K_{ff,a}$). Dynamic tracking error is $\|e_{true}\|_{max} = 0.4456^\circ \le 1.7200^\circ$.

### Step 6: Robustness, Disturbance Rejection, & Non-Linear Friction Analysis
- **Model:** `models/stage1_robust_loop_model.slx` | **Script:** `scripts/build_and_run_stage6.m`
- Evaluates system under in-motion step load disturbance ($T_L = 0.010\text{ N}\cdot\text{m}$ at $t=0.20\text{s}$), in-dwell pulse disturbance ($t=0.60\text{s}$), Stribeck friction ($T_{stick} = 0.0020\text{ N}\cdot\text{m}, T_{coulomb} = 0.0010\text{ N}\cdot\text{m}$), and inertia sweep ($1\times, 2\times, 3\times J_0$). 
- Employs physics load feedforward ($K_{ff,L} = 0.833333\text{ N}^{-1}\cdot\text{m}^{-1}$) and continuous friction feedforward ($u_{ff,fric}$).

---

## 5. Subsystem Component Specifications

### 10. Final Controller Architecture
Discrete parallel PID operating at $1\text{ kHz}$ ($T_s = 1\text{ ms}$):
$$u_{pid}[k] = K_p e[k] + K_i T_s \sum_{m=0}^{k} e[m] + K_d \frac{e[k] - e[k-1]}{T_s}$$
with conditional anti-windup clamping ($d[k] \in [0.0, 1.0]$).

### 11. Electromechanical Plant Model
Armature electrical dynamics:
$$\frac{di}{dt} = \frac{1}{L} \left( V_{eff}(t) - R \cdot i(t) - K_e \cdot \omega(t) \right)$$
Rotor mechanical dynamics:
$$\frac{d\omega}{dt} = \frac{1}{J} \left( K_t \cdot i(t) - B \cdot \omega(t) - T_L(t) - T_{fric}(\omega) \right)$$

### 12. Encoder Model
Floor quantization of true continuous shaft angle $\theta_{true}(t)$:
$$N_{count}[k] = \left\lfloor \theta_{true}(t) \cdot \frac{CPR}{2\pi} \right\rfloor, \quad \theta_{enc}[k] = N_{count}[k] \cdot \frac{2\pi}{CPR}$$

### 13. Profile Generator
Kinematic trapezoidal trajectory generator producing continuous position $\theta_{ref}(t)$, velocity $\omega_{ref}(t)$, and acceleration $a_{ref}(t)$ commands constrained by $a_{max} = 50.0\text{ rad/s}^2$ and $\omega_{max} = 8.0\text{ rad/s}$.

### 14. PID Controller Parameters
- Discrete Gains: $K_p = 0.50$, $K_i = 8.00$, $K_d = 0.0000$, Filter $N = 20$.
- Sampling Rate: $T_s = 0.001\text{ s}$ ($1000\text{ Hz}$).

### 15. Feedforward Terms
- Velocity Feedforward: $K_{ff,v} = \frac{K_e + R B / K_t}{V_{dc}} = 0.004175\text{ V}/(\text{rad/s})$
- Acceleration Feedforward: $K_{ff,a} = \frac{J R / K_t + L B / K_t}{V_{dc}} = 0.00000834\text{ V}/(\text{rad/s}^2)$
- Load Torque Feedforward: $K_{ff,L} = \frac{R}{V_{dc} \cdot K_t} = 0.833333\text{ N}^{-1}\cdot\text{m}^{-1}$

### 16. Disturbance Model
Step and pulse disturbance torque $T_L(t) = 0.010\text{ N}\cdot\text{m}$ applied during in-motion ($t = 0.20\text{ s}$) and in-dwell ($t = 0.60\text{ s}$) simulation phases.

### 17. Friction Model
Continuous Stribeck friction model compensating for static stiction breakaway ($T_{stick} = 0.0020\text{ N}\cdot\text{m}$) and Coulomb sliding friction ($T_{coulomb} = 0.0010\text{ N}\cdot\text{m}$):
$$u_{ff,fric}(\omega_{ref}) = K_{ff,L} \cdot \left[ T_{coulomb} + (T_{stick} - T_{coulomb}) e^{-(\omega_{ref}/\omega_s)^2} \right] \cdot \tanh(1000 \cdot \omega_{ref})$$

### 18. Inertia Sensitivity
Robustness evaluated across payload inertia variations $J \in \{1.0 \times 10^{-5}, 2.0 \times 10^{-5}, 3.0 \times 10^{-5}\}\text{ kg}\cdot\text{m}^2$ ($1\times, 2\times, 3\times J_0$).

---

## 6. Verification Methodology, Limitations & Stage 2 Boundary

### 19. Verification Methodology
Every simulation step is executed via script automation (`run_stage1.m`), saving raw timeseries arrays into `.mat` files and rendering publication-quality PNG figure dashboards. Numerical outputs are checked against theoretical physical derivations.

### 20. Simulation Prototype Limitations
1. **Oracle Load Estimate:** Step 6 load feedforward ($u_{ff,L}$) relies on direct load torque knowledge ($T_{L,est}$).
2. **Reference Velocity Friction Feedforward:** Friction feedforward $u_{ff,fric}(\omega_{ref})$ uses ideal profile velocity $\omega_{ref}$ rather than measured motor velocity to avoid quantization noise amplification during dwell.
3. **Idealized Power Electronics:** PWM H-Bridge is modeled via averaged voltage scaling without MOSFET switching dead-time or thermal effects.

### 21. Stage 2 Boundary
Stage 1 is strictly a software simulation prototype. The boundary to Stage 2 involves:
- Implementing a **Disturbance Observer (DOB)** for sensorless load torque estimation.
- Discrete differentiation and low-pass filtering for measured velocity estimation $\hat{\omega}$.
- Translating control algorithms into 32-bit floating point C firmware for STM32 deployment.
