# Stage 1 — Step 2: Incremental Encoder / Position Measurement Model

## 1. Objective

The objective of **Stage 1 — Step 2** of **Project 2: STM32 Automated Precision Indexing & Feed Control** is to extend the open-loop continuous-time motor plant model created in Step 1 with a realistic simulated incremental encoder position measurement path.

This step models how a physical encoder measures shaft rotation, converts continuous angular position into discrete digital pulses/counts, and yields a quantized position measurement $\theta_{encoder}(t)$ for future feedback control.

> [!IMPORTANT]
> **Virtual Simulation Only Notice:**
> - This is a virtual simulation model only.
> - No physical hardware, STM32 microcontrollers, C code, PWM switching drivers, closed-loop controllers, or Stateflow logic are included in this step.

---

## 2. Why an Encoder is Required

In automated precision indexing systems (e.g., rotary indexing tables, feed mechanisms, CNC tool changers), the controller cannot directly observe the continuous physical angle of the motor shaft. 

An incremental optical or magnetic encoder is required to:
1. **Provide Position Feedback:** Convert physical mechanical rotation into digital pulse signals readable by timer/counter peripherals (e.g., STM32 Timer Encoder Mode).
2. **Enable Closed-Loop Control:** Allow future feedback algorithms to compare measured position against target position commands.
3. **Achieve Indexing Accuracy:** Enable precise stopping at pre-programmed angular increments (e.g., $45^\circ$, $90^\circ$, or fractional-degree feed steps).

---

## 3. Encoder Operating Principle

An incremental quadrature encoder consists of a code disk with transparent and opaque radial lines (pulses), an LED optical emitter, and photodetector receivers producing two square wave signals: **Channel A** and **Channel B**, phase-shifted by $90^\circ$ (in quadrature).

### 4x Quadrature Decoding Principle
By detecting both **rising and falling edges** on both Channel A and Channel B:
$$\text{Total Counts Per Revolution (CPR)} = 4 \times \text{Pulses Per Revolution (PPR)}$$

- **Clockwise Rotation:** Channel A leads Channel B $\to$ Counter Increments ($+1$).
- **Counter-Clockwise Rotation:** Channel B leads Channel A $\to$ Counter Decrements ($-1$).

---

## 4. Selected Encoder Resolution

For this virtual prototype step:
- **Base Optical Disk Line Count:** $\text{PPR} = 250\text{ pulses/revolution}$
- **Quadrature Factor:** $4\times\text{ Quadrature Decoding}$
- **Total Resolution (CPR):** $\text{CPR} = 250 \times 4 = 1000\text{ counts/revolution}$

### Resolution Units
- **Radians per count:**
  $$\Delta \theta_{res} = \frac{2\pi}{\text{CPR}} = \frac{2\pi}{1000} = \frac{\pi}{500} \approx 0.0062831853\text{ rad/count} \quad (6.2832\text{ mrad/count})$$
- **Degrees per count:**
  $$\Delta \theta_{deg} = \frac{360^\circ}{\text{CPR}} = \frac{360^\circ}{1000} = 0.36^\circ/\text{count}$$

### Rationale for Selection:
A resolution of $1000\text{ CPR}$ ($0.36^\circ/\text{count}$) provides a standard industrial optical encoder resolution suitable for fractional-degree precision indexing, offering clean quantization steps while maintaining fast real-time computational performance.

---

## 5. Mathematical Equations

The encoder path models the conversion from continuous **True Motor Position $\theta_{true}(t)$** to discrete **Encoder Counts $N_{counts}(t)$**, and back to **Encoder-Measured Position $\theta_{encoder}(t)$**:

1. **Continuous Count Derivation:**
   $$N_{cont}(t) = \theta_{true}(t) \times \frac{\text{CPR}}{2\pi} = \theta_{true}(t) \times \frac{1000}{2\pi}$$

2. **Quantized Integer Count (Floor Function):**
   $$N_{counts}(t) = \lfloor N_{cont}(t) \rfloor = \left\lfloor \theta_{true}(t) \times \frac{1000}{2\pi} \right\rfloor$$

3. **Encoder-Measured Position (Radians):**
   $$\theta_{encoder}(t) = N_{counts}(t) \times \frac{2\pi}{\text{CPR}} = N_{counts}(t) \times 0.0062831853$$

4. **Position Measurement Error:**
   $$e_\theta(t) = \theta_{encoder}(t) - \theta_{true}(t)$$

### Theoretical Error Bound:
Because of the floor quantization operator, the measurement error is strictly bounded by:
$$-\Delta \theta_{res} < e_\theta(t) \le 0 \implies |e_\theta(t)|_{max} \le \Delta \theta_{res} = 0.0062831853\text{ rad} \quad (0.36^\circ)$$

---

## 6. Simulink Implementation

The Step 2 model is saved as **`models/stage1_encoder_model.slx`**, leaving the original Step 1 baseline (`models/stage1_motor_plant.slx`) completely untouched.

```
True Position theta_true(t)
          │
          ├───────────────────────────────────────────────────────┐ (-)
          ▼                                                       ▼
┌──────────────────┐   N_cont   ┌───────────┐  N_counts   ┌──────────────────┐  theta_enc  ┌────────────┐  e_theta
│ Gain (CPR / 2pi) │ ─────────> │   Floor   │ ──────────> │ Gain (2pi / CPR) │ ──────────> │ Sum Junction│ ───────> Log & Scope
└──────────────────┘            └───────────┘             └──────────────────┘             │  (+ / -)   │
                                      │                                                    └────────────┘
                                      ▼                                                          ▲
                                Log & Scope                                                      │ (+)
                              (ENCODER COUNTS)                                           (MEASURED POSITION)
```

### Simulink Block Structure:
- **`Gain_RadToCounts`**: Gain block with parameter `CPR / (2*pi)` ($1000 / 2\pi \approx 159.1549$).
- **`Encoder_Quantizer`**: `Rounding Function` block set to `floor`.
- **`Gain_CountsToRad`**: Gain block with parameter `(2*pi) / CPR` ($2\pi / 1000 \approx 0.0062831853$).
- **`Sum_Error`**: Summing block (`+-`) computing $\theta_{encoder}(t) - \theta_{true}(t)$.
- **Logging Blocks:** `To Workspace` (`sim_counts`, `sim_theta_enc`, `sim_err`) and dedicated Scopes labelled `TRUE POSITION`, `ENCODER COUNTS`, `MEASURED POSITION`.

---

## 7. Validation Methodology & Dynamics Preservation

To confirm that the encoder model is a pure measurement sensor and does not back-react or alter the physical motor plant dynamics:
1. Both `models/stage1_motor_plant.slx` (Step 1) and `models/stage1_encoder_model.slx` (Step 2) were executed under the exact same $12\text{ V}$ step input conditions ($t_{step} = 0.01\text{ s}$, $t_{stop} = 0.10\text{ s}$, solver `ode45`).
2. Motor speed trajectories $\omega(t)$ and true position trajectories $\theta_{true}(t)$ were compared point-by-point.

---

## 8. Actual Simulation Results

Running `scripts/build_and_run_stage2.m` produced the following empirical simulation results:

| Metric | Analytical / Expected | Actual Simulation Result | Status |
| :--- | :---: | :---: | :---: |
| **Motor Dynamics Preservation** | Max Speed Diff $= 0.0\text{ rad/s}$ | **$0.000000\times 10^0\text{ rad/s}$** | **PASS** |
| **Encoder CPR** | $1000\text{ counts/rev}$ | **$1000\text{ counts/rev}$** | **PASS** |
| **Resolution ($\text{rad/count}$)** | $0.0062831853\text{ rad}$ | **$0.0062831853\text{ rad}$** | **PASS** |
| **Resolution ($\text{deg/count}$)** | $0.3600^\circ$ | **$0.3600^\circ$** | **PASS** |
| **Final True Position $\theta_{true}(t_{stop})$** | $21.078322\text{ rad}$ | **$21.078322\text{ rad}$ ($1207.70^\circ$)** | **PASS** |
| **Final Measured Position $\theta_{enc}(t_{stop})$** | $21.073804\text{ rad}$ | **$21.073804\text{ rad}$ ($1207.44^\circ$)** | **PASS** |
| **Total Accumulated Counts** | $\lfloor 21.078322 \times \frac{1000}{2\pi} \rfloor = 3354$ | **$3354\text{ counts}$** | **PASS** |
| **Max Measurement Error $|e_\theta|_{max}$** | $\le 0.0062831853\text{ rad}$ | **$0.00622966\text{ rad}$ ($0.3569^\circ$)** | **PASS** |
| **Mean Measurement Error $|e_\theta|_{mean}$** | N/A | **$0.00288448\text{ rad}$ ($0.1653^\circ$)** | **PASS** |

---

## 9. Plot Visualizations

### 1. True Motor Position vs Encoder-Measured Position
![True vs Encoder Position](results/stage1/true_vs_encoder_position.png)

### 2. Accumulated Incremental Encoder Counts
![Encoder Counts vs Time](results/stage1/encoder_counts_vs_time.png)

### 3. Measurement Error & Staircase Quantization Analysis
![Encoder Error and Quantization Zoom](results/stage1/encoder_error.png)

---

## 10. Assumptions & Limitations

### Assumptions:
1. Ideal noise-free optical encoder signals (no mechanical chatter, optical jitter, or lost pulses).
2. Infinite channel bandwidth (no high-speed pulse clipping at maximum RPM).
3. Zero indexing reference pulse (Z-phase index pulse not modeled in open-loop step test).

### Limitations:
1. This is a digital measurement model; physical hardware delays or STM32 Timer input capture latching latencies are not included.
2. The measured position output $\theta_{encoder}(t)$ is quantized but not yet fed back into any controller.

---

## 11. Implemented vs Remaining

### IMPLEMENTED NOW (Stage 1 Step 2):
- Preserved baseline motor plant model (`models/stage1_motor_plant.slx`).
- Step 2 model with incremental encoder measurement path (`models/stage1_encoder_model.slx`).
- Quantization math (1000 CPR, $0.36^\circ/\text{count}$ resolution).
- Measurement error computation and bound verification.
- Plot generation in `results/stage1/`.

### REMAINING FOR LATER STAGES:
- Closed-loop position/speed controller (e.g. PID).
- PWM voltage driver / H-bridge actuation model.
- Limit switches / homing logic.
- Stateflow state machine indexing control.
- STM32 Embedded C code generation and physical hardware deployment.
