# Stage 1 Forensic Audit — Physics & Mathematical Modeling Audit

## 1. Electromechanical Motor Plant Physics
The continuous-time motor plant differential equations are:
V(t) = L \frac{di}{dt} + R i(t) + K_e \omega(t)
J \frac{d\omega}{dt} = K_t i(t) - B \omega(t) - T_L(t) - T_{fric}(t)
\frac{d\theta}{dt} = \omega(t)

### SI Unit Compatibility Verification
In SI units, mechanical power equals electrical back-EMF power:
P = T_e \cdot \omega = (K_t \cdot i) \cdot \omega = e_{back} \cdot i = (K_e \cdot \omega) \cdot i \implies K_e = K_t
Since  = 0.050\text{ V}\cdot\text{s/rad}$ and  = 0.050\text{ N}\cdot\text{m/A}$, the parameter definitions in params.m are **100% physically compatible**.

## 2. Load-Torque Feedforward Compensation Derivation
To balance an external load torque $, the required steady armature current is {load} = T_L / K_t$.
The terminal voltage required is {load} = R \cdot i_{load} = (R / K_t) T_L$.
Dividing by supply voltage {dc} = 12.0\text{ V}$ yields the normalized duty cycle feedforward:
u_{ff,L} = \frac{V_{load}}{V_{dc}} = \left( \frac{R}{V_{dc} \cdot K_t} \right) T_L = K_{ff,L} \cdot T_L
K_{ff,L} = \frac{0.50}{12.0 \times 0.050} = 0.83333333...\text{ N}^{-1}\cdot\text{m}^{-1}
For  = 0.010\text{ N}\cdot\text{m}$, {ff,L} = 0.00833333$ (.833\%\text{ duty cycle}$).

## 3. Nonlinear Friction Model Physics
The continuous friction model formulation is:
T_{fric,ref}(\omega_{ref}) = \left[ T_{coulomb} + (T_{stick} - T_{coulomb}) e^{-(\omega_{ref}/\omega_s)^2} \right] \cdot \tanh(1000 \cdot \omega_{ref})
- $\omega_{ref} = 0 \implies u_{ff,fric} = 0.0$ (Zero static voltage offset during dwell, zero risk of limit cycles).
- $\omega_{ref} \approx 0.001\text{ rad/s} \implies T_{fric,ref} \approx T_{stick} = 0.0020\text{ N}\cdot\text{m}$ (Stiction breakaway).
- $\omega_{ref} \ge 0.1\text{ rad/s} \implies T_{fric,ref} \approx T_{coulomb} = 0.0010\text{ N}\cdot\text{m}$ (Sliding Coulomb friction).
