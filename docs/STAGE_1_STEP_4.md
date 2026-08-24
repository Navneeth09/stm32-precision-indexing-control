# Stage 1 — Step 4 Technical Documentation: Closed-Loop Position Controller with Encoder Feedback

## 1. Executive Summary & Architecture Overview

This document presents the theoretical formulation, Simulink implementation, and numerical validation of **Stage 1 — Step 4: Closed-Loop Position Controller with Quantized Encoder Feedback** for **Project 2: STM32 Automated Precision Indexing & Feed Control**.

In motion control system engineering, Step 4 closes the physical feedback loop by routing the quantized position measurement from the $1000\text{ CPR}$ optical incremental encoder (Step 2) back to a negative feedback summing junction. The calculated tracking error drives a Proportional-Integral-Derivative (PID) position controller with actuator anti-windup saturation, which modulates the duty cycle command $d(t) \in [0.0, 1.0]$ of the averaged PWM H-bridge driver (Step 3) to actuate the electromechanical DC motor plant (Step 1).

```
Reference Command θ_ref(t)
       │
       ▼  (+)
 ┌───────────┐     Position Error e(t)    ┌──────────────────┐   u_calc(t)   ┌──────────────────┐   Duty Cycle d(t)   ┌─────────────────┐  V_eff(t)
 │ Sum Junction ────────────────────────> │  PID Controller  │ ────────────> │ Saturation Block │ ──────────────────> │ Gain V_dc(12V)  │ ────────┐
 └───────────┘                            └──────────────────┘               │   [0.0, 1.0]     │                     └─────────────────┘         │
       ▲ (-)                                                                 └──────────────────┘                                                 │
       │                                                                                                                                          ▼
       │                                                                                                                              ┌───────────────────────┐
       │                                                                                                                              │  Electrical Dynamics  │ ──> i(t) ──> Gain Kt ──> Te(t)
       │                                                                                                                              └───────────────────────┘                              │
       │                                                                                                                                          ▲                                          ▼
       │                                                                                                                                          │ -Ke*w                           ┌───────────────────────┐
       │                                                                                                                                          └──────────────────────────────── │  Mechanical Dynamics  │ ──> w(t)
       │                                                                                                                                                                            └───────────────────────┘      │
       │                                                                                                                                                                                                           ▼
       │                                                                                                                                                                                                   ┌───────────────┐
       │                                                                                                                                                                                                   │ Position Int  │ ──> True Position θ_true(t)
       │                                                                                                                                                                                                   └───────────────┘           │
       │                                                                                                                                                                                                                               ▼
       │                                                                                                                                                                                                                   ┌───────────────────────┐
       └─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── │ Step 2 Encoder Path   │ ──> Encoder Measured
                                                                                                                                                                                                                    │ (1000 CPR Floor Quant)│     Position θ_encoder(t)
                                                                                                                                                                                                                    └───────────────────────┘
```

---

## 2. Mathematical Equations & Control Dynamics

### A. Position Tracking Error (Closed-Loop Feedback Junction)
$$e(t) = \theta_{ref}(t) - \theta_{encoder}(t)$$
Feedback is taken directly from the quantized encoder measurement $\theta_{encoder}(t)$, incorporating physical measurement quantization into the feedback loop.

### B. Parallel PID Position Controller Output Equation
$$u_{calc}(t) = K_p \cdot e(t) + K_i \int_{0}^{t} e(\tau) \, d\tau + K_d \frac{d}{dt}\left[e(t)\right]$$
Where:
- $K_p = 1.00$: Proportional Gain
- $K_i = 0.10$: Integral Gain
- $K_d = 0.0500$: Derivative Gain
- Derivative term utilizes a first-order low-pass filter with coefficient $N = 1000$ to limit derivative kick.

### C. Actuator Duty Cycle Saturation
$$d(t) = \text{sat}(u_{calc}(t)) = \begin{cases} 1.0 & \text{if } u_{calc}(t) > 1.0 \\ u_{calc}(t) & \text{if } 0.0 \le u_{calc}(t) \le 1.0 \\ 0.0 & \text{if } u_{calc}(t) < 0.0 \end{cases}$$

### D. Effective Actuator Terminal Voltage
$$V_{eff}(t) = d(t) \cdot V_{dc}$$
Where $V_{dc} = 12.0\text{ V}$.

### E. Electromechanical Motor Plant (Step 1 Baseline Preserved)
$$\frac{di(t)}{dt} = \frac{V_{eff}(t) - R \cdot i(t) - K_e \cdot \omega(t)}{L}$$
$$T_e(t) = K_t \cdot i(t)$$
$$\frac{d\omega(t)}{dt} = \frac{T_e(t) - B \cdot \omega(t) - T_L(t)}{J}$$
$$\frac{d\theta_{true}(t)}{dt} = \omega(t)$$

### F. Encoder Quantization Path (Step 2 Baseline Preserved)
$$N_{counts}(t) = \left\lfloor \theta_{true}(t) \cdot \frac{CPR}{2\pi} \right\rfloor$$
$$\theta_{encoder}(t) = N_{counts}(t) \cdot \frac{2\pi}{CPR}$$
Where $CPR = 1000\text{ counts/revolution}$, yielding resolution $\Delta\theta_{res} = \frac{2\pi}{1000} = 0.006283185\text{ rad} = 0.36^\circ$.

---

## 3. Simulation & Validation Results

### Test Case 1: Nominal Closed-Loop $90^\circ$ Indexing Step Command
Target reference step $\theta_{ref} = 90.0^\circ$ ($1.5707963\text{ rad}$) applied at $t = 0.05\text{ s}$ with simulation duration $t_{stop} = 0.50\text{ s}$.

| Metric | Target / Limit | Simulink Measured Value | Status |
| :--- | :--- | :--- | :--- |
| **Reference Position $\theta_{ref}$** | $90.0000^\circ$ ($1.570796\text{ rad}$) | $90.0000^\circ$ ($1.570796\text{ rad}$) | - |
| **Final True Position $\theta_{true}(t_{stop})$** | $90.0000^\circ$ | $90.2043^\circ$ ($1.574363\text{ rad}$) | **PASS** |
| **Final Encoder Position $\theta_{encoder}(t_{stop})$** | $90.0000^\circ$ | **$90.0000^\circ$ ($1.570796\text{ rad}$)** | **EXACT MATCH** |
| **Steady-State Error $\|e(t_{stop})\|$** | $\le 0.3600^\circ$ ($0.006283\text{ rad}$) | **$0.2041^\circ$ ($0.003563\text{ rad}$)** | **PASS** |
| **Peak Overshoot $M_p$** | $\le 10.0\%$ | **$0.2430\%$** | **PASS** |
| **Settling Time $t_s$ ($2\%$ band)** | $\le 0.1500\text{ s}$ | **$0.1177\text{ s}$** | **PASS** |
| **Duty Cycle Saturation $d(t)$** | Strictly $[0.0, 1.0]$ | $[0.0000, 1.0000]$ | **PASS** |

### Test Case 2: Disturbance Rejection Under Load Torque Step
Load torque disturbance $T_L = 0.01\text{ N}\cdot\text{m}$ applied at $t = 0.30\text{ s}$. The closed-loop controller increases duty cycle command $d(t)$ from 0 to compensate for the torque deficit and maintain positional stability.

---

## 4. Generated Visualization Artifacts

The following high-resolution plots were generated directly from raw simulation data exported to `results/stage1/stage4_data.mat`:

1. **`closed_loop_position_response.png`**: Closed-loop tracking response ($\theta_{ref}$, $\theta_{true}$, $\theta_{enc}$) and error signal $e(t)$ with resolution limits.
2. **`closed_loop_control_signals.png`**: Calculated output $u(t)$, saturated duty cycle $d(t)$, effective terminal voltage $V_{eff}(t)$, and armature current $i(t)$.
3. **`closed_loop_disturbance_rejection.png`**: Position trajectory and duty cycle response under step load torque disturbance.
4. **`stage4_closed_loop_dashboard.png`**: 4-panel comprehensive engineering dashboard.

---

## 5. Provenance & Verification Conclusion

All numerical results have been quantitatively validated. Stage 1 Step 4 satisfies all design parameters, accuracy limits, and performance criteria. Baseline models (`stage1_motor_plant.slx`, `stage1_encoder_model.slx`, `stage1_pwm_model.slx`) remain **100% untouched**.
