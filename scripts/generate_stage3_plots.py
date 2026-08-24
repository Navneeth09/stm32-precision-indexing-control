import os
import numpy as np
import scipy.io as sio
import matplotlib.pyplot as plt

plt.style.use('dark_background')
plt.rcParams['font.sans-serif'] = 'DejaVu Sans'

project_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
results_dir = os.path.join(project_dir, 'results', 'stage1')
data_file = os.path.join(results_dir, 'stage3_data.mat')

if not os.path.exists(data_file):
    raise FileNotFoundError(f"Simulation MAT file not found at: {data_file}")

# Load raw simulation arrays exported by MATLAB/Simulink
mat_data = sio.loadmat(data_file)
t_vec = mat_data['t_vec'].flatten()
d_vec_75 = mat_data['d_vec_75'].flatten()
Veff_vec_75 = mat_data['Veff_vec_75'].flatten()
i_vec_75 = mat_data['i_vec_75'].flatten()
w_vec_75 = mat_data['w_vec_75'].flatten()
theta_true_75 = mat_data['theta_true_75'].flatten()
counts_vec_75 = mat_data['counts_vec_75'].flatten()
theta_enc_75 = mat_data['theta_enc_75'].flatten()
w_vec_100 = mat_data['w_vec_100'].flatten()

w_ss_analytical_75 = float(mat_data['w_ss_analytical_75'].flatten()[0])
w_ss_analytical_100 = float(mat_data['w_ss_analytical_100'].flatten()[0])
w_ss_sim_75 = float(mat_data['w_ss_sim_75'].flatten()[0])
w_ss_sim_100 = float(mat_data['w_ss_sim_100'].flatten()[0])

# Plot 1: pwm_voltage_vs_time.png (Duty Cycle d(t) and Effective Voltage V_eff(t))
fig1, (ax1a, ax1b) = plt.subplots(2, 1, figsize=(10, 7), dpi=150)

ax1a.plot(t_vec, d_vec_75, color='#00ffcc', linewidth=2.0, label='PWM Duty Cycle Command $d(t)$ ($75\\%$)')
ax1a.set_xlabel('Time (s)', fontsize=11)
ax1a.set_ylabel('Duty Cycle $d$', fontsize=11)
ax1a.set_title('Stage 1 Step 3: Averaged PWM Duty Cycle Command $d(t)$', fontsize=13, fontweight='bold')
ax1a.grid(True, linestyle=':', alpha=0.5)
ax1a.set_ylim(-0.05, 1.05)
ax1a.legend(loc='lower right', fontsize=10)

ax1b.plot(t_vec, Veff_vec_75, color='#ff9900', linewidth=2.0, label='Effective Voltage $V_{eff}(t) = d(t) \\cdot V_{dc}$ ($9.0\\text{ V}$)')
ax1b.axhline(12.0, color='gray', linestyle='--', linewidth=1, label='Max DC Supply $V_{dc} = 12.0\\text{ V}$')
ax1b.set_xlabel('Time (s)', fontsize=11)
ax1b.set_ylabel('Effective Voltage $V_{eff}$ (V)', fontsize=11)
ax1b.set_title('Effective Averaged Motor Terminal Voltage $V_{eff}(t)$', fontsize=13, fontweight='bold')
ax1b.grid(True, linestyle=':', alpha=0.5)
ax1b.legend(loc='lower right', fontsize=10)

fig1.suptitle('Stage 1 Step 3: Averaged PWM Voltage Actuation Signal Chain', fontsize=14, fontweight='bold', y=0.98)
plt.tight_layout()
fig1.savefig(os.path.join(results_dir, 'pwm_voltage_vs_time.png'))
plt.close(fig1)
print(f"Saved: {os.path.join(results_dir, 'pwm_voltage_vs_time.png')}")

# Plot 2: pwm_speed_response.png (Speed response comparing d=1.0 vs d=0.75)
fig2, ax2 = plt.subplots(figsize=(10, 6), dpi=150)

ax2.plot(t_vec, w_vec_100, color='#00aaff', linewidth=2.0, label=f'Full Scale $d = 1.00$ ($V_{{eff}} = 12.0\\text{{ V}}$) $\\to$ $\\omega_{{ss}} = {w_ss_sim_100:.2f}\\text{{ rad/s}}$')
ax2.plot(t_vec, w_vec_75, color='#ff3366', linewidth=2.0, label=f'Reduced Scale $d = 0.75$ ($V_{{eff}} = 9.0\\text{{ V}}$) $\\to$ $\\omega_{{ss}} = {w_ss_sim_75:.2f}\\text{{ rad/s}}$')

ax2.axhline(w_ss_analytical_100, color='#00aaff', linestyle='--', alpha=0.7, label=f'Analytical $\\omega_{{ss}}(1.00) = {w_ss_analytical_100:.2f}\\text{{ rad/s}}$')
ax2.axhline(w_ss_analytical_75, color='#ff3366', linestyle='--', alpha=0.7, label=f'Analytical $\\omega_{{ss}}(0.75) = {w_ss_analytical_75:.2f}\\text{{ rad/s}}$')

ax2.set_xlabel('Time (s)', fontsize=12)
ax2.set_ylabel('Motor Speed $\\omega$ (rad/s)', fontsize=12)
ax2.set_title('Stage 1 Step 3: Electromechanical Motor Speed Response to Averaged PWM Duty Cycle Commands', fontsize=13, fontweight='bold', pad=12)
ax2.grid(True, linestyle=':', alpha=0.5)
ax2.legend(loc='lower right', fontsize=10)

plt.tight_layout()
fig2.savefig(os.path.join(results_dir, 'pwm_speed_response.png'))
plt.close(fig2)
print(f"Saved: {os.path.join(results_dir, 'pwm_speed_response.png')}")

# Plot 3: pwm_actuation_dashboard.png (Full 4-panel dashboard under d=0.75 actuation)
fig3, axes = plt.subplots(2, 2, figsize=(11, 8), dpi=150)

# Panel 1: Duty Cycle and Effective Voltage
axes[0, 0].plot(t_vec, Veff_vec_75, color='#ff9900', linewidth=1.8)
axes[0, 0].grid(True, linestyle=':', alpha=0.5)
axes[0, 0].set_xlabel('Time (s)')
axes[0, 0].set_ylabel('Effective Voltage $V_{eff}$ (V)')
axes[0, 0].set_title('1. Averaged Voltage $V_{eff} = d \\cdot V_{dc}$ ($9.0\\text{V}$)')

# Panel 2: Armature Current
axes[0, 1].plot(t_vec, i_vec_75, color='#b366ff', linewidth=1.8)
axes[0, 1].grid(True, linestyle=':', alpha=0.5)
axes[0, 1].set_xlabel('Time (s)')
axes[0, 1].set_ylabel('Current $i$ (A)')
axes[0, 1].set_title('2. Armature Current $i(t)$ Response')

# Panel 3: Motor Speed
axes[1, 0].plot(t_vec, w_vec_75, color='#ff3366', linewidth=1.8)
axes[1, 0].grid(True, linestyle=':', alpha=0.5)
axes[1, 0].set_xlabel('Time (s)')
axes[1, 0].set_ylabel('Speed $\\omega$ (rad/s)')
axes[1, 0].set_title('3. Motor Speed $\\omega(t)$ ($179.64\\text{ rad/s}$ SS)')

# Panel 4: True & Encoder Measured Position
axes[1, 1].plot(t_vec, theta_true_75, color='#00aaff', linewidth=1.8, label='True Position $\\theta_{true}$')
axes[1, 1].plot(t_vec, theta_enc_75, '--', color='#00ffcc', linewidth=1.5, label='Encoder Measured $\\theta_{enc}$')
axes[1, 1].grid(True, linestyle=':', alpha=0.5)
axes[1, 1].set_xlabel('Time (s)')
axes[1, 1].set_ylabel('Position $\\theta$ (rad)')
axes[1, 1].set_title('4. Open-Loop Position Accumulation')
axes[1, 1].legend(loc='upper left', fontsize=9)

fig3.suptitle('Stage 1 Step 3: Averaged PWM Actuator Open-Loop Simulation Dashboard', fontsize=15, fontweight='bold', y=0.98)
plt.tight_layout()
fig3.savefig(os.path.join(results_dir, 'pwm_actuation_dashboard.png'))
plt.close(fig3)
print(f"Saved: {os.path.join(results_dir, 'pwm_actuation_dashboard.png')}")
