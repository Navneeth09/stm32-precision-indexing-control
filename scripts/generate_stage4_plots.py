import os
import numpy as np
import scipy.io as sio
import matplotlib.pyplot as plt

plt.style.use('dark_background')
plt.rcParams['font.sans-serif'] = 'DejaVu Sans'

project_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
results_dir = os.path.join(project_dir, 'results', 'stage1')
data_file = os.path.join(results_dir, 'stage4_data.mat')

if not os.path.exists(data_file):
    raise FileNotFoundError(f"Simulation MAT file not found at: {data_file}")

# Load raw simulation arrays exported by MATLAB/Simulink
mat_data = sio.loadmat(data_file)

# Nominal Step Response (Test Case 1)
t_vec = mat_data['t_vec'].flatten()
theta_ref_vec = mat_data['theta_ref_vec'].flatten()
e_vec = mat_data['e_vec'].flatten()
u_vec = mat_data['u_vec'].flatten()
d_vec = mat_data['d_vec'].flatten()
Veff_vec = mat_data['Veff_vec'].flatten()
i_vec = mat_data['i_vec'].flatten()
w_vec = mat_data['w_vec'].flatten()
theta_true_vec = mat_data['theta_true_vec'].flatten()
counts_vec = mat_data['counts_vec'].flatten()
theta_enc_vec = mat_data['theta_enc_vec'].flatten()

# Disturbance Rejection Test Response (Test Case 2)
t_dist_vec = mat_data['t_dist_vec'].flatten()
theta_ref_dist = mat_data['theta_ref_dist'].flatten()
e_dist = mat_data['e_dist'].flatten()
d_dist = mat_data['d_dist'].flatten()
w_dist = mat_data['w_dist'].flatten()
theta_true_dist = mat_data['theta_true_dist'].flatten()
theta_enc_dist = mat_data['theta_enc_dist'].flatten()

res_rad = float(mat_data['res_rad'].flatten()[0])
res_deg = float(mat_data['res_deg'].flatten()[0])

# Plot 1: closed_loop_position_response.png
fig1, (ax1a, ax1b) = plt.subplots(2, 1, figsize=(10, 8), dpi=150)

# Position Tracking
ax1a.plot(t_vec, np.degrees(theta_ref_vec), color='#ffffff', linestyle='--', linewidth=1.5, label='Reference Step $\\theta_{ref} = 90.0^\\circ$')
ax1a.plot(t_vec, np.degrees(theta_true_vec), color='#00aaff', linewidth=2.0, label='True Position $\\theta_{true}(t)$')
ax1a.plot(t_vec, np.degrees(theta_enc_vec), color='#00ffcc', linewidth=1.5, linestyle=':', label='Encoder Quantized $\\theta_{enc}(t)$ (1000 CPR)')
ax1a.set_xlabel('Time (s)', fontsize=11)
ax1a.set_ylabel('Position (deg)', fontsize=11)
ax1a.set_title('Stage 1 Step 4: Closed-Loop PID Position Step Response ($90^\\circ$ Indexing Step)', fontsize=13, fontweight='bold')
ax1a.grid(True, linestyle=':', alpha=0.5)
ax1a.legend(loc='lower right', fontsize=10)

# Tracking Error
ax1b.plot(t_vec, np.degrees(e_vec), color='#ff3366', linewidth=1.8, label='Quantized Tracking Error $e(t) = \\theta_{ref} - \\theta_{enc}$')
ax1b.axhline(res_deg, color='#ffcc00', linestyle='--', linewidth=1.2, label=f'Encoder Resolution Bound ($\\pm {res_deg:.2f}^\\circ$)')
ax1b.axhline(-res_deg, color='#ffcc00', linestyle='--', linewidth=1.2)
ax1b.set_xlabel('Time (s)', fontsize=11)
ax1b.set_ylabel('Position Error (deg)', fontsize=11)
ax1b.set_title('Closed-Loop Tracking Error Convergence', fontsize=13, fontweight='bold')
ax1b.grid(True, linestyle=':', alpha=0.5)
ax1b.legend(loc='upper right', fontsize=10)

fig1.suptitle('Stage 1 Step 4: Closed-Loop Position Control Response', fontsize=14, fontweight='bold', y=0.98)
plt.tight_layout()
fig1.savefig(os.path.join(results_dir, 'closed_loop_position_response.png'))
plt.close(fig1)
print(f"Saved: {os.path.join(results_dir, 'closed_loop_position_response.png')}")

# Plot 2: closed_loop_control_signals.png
fig2, (ax2a, ax2b) = plt.subplots(2, 1, figsize=(10, 7), dpi=150)

# Duty Cycle Signal & Saturation
ax2a.plot(t_vec, u_vec, color='#ff9900', linestyle='--', linewidth=1.5, label='Calculated Controller Output $u_{calc}(t)$')
ax2a.plot(t_vec, d_vec, color='#00ffcc', linewidth=2.0, label='Saturated Duty Cycle $d(t) \\in [0.0, 1.0]$')
ax2a.axhline(1.0, color='gray', linestyle=':', label='Upper Saturation Bound ($d_{max} = 1.0$)')
ax2a.axhline(0.0, color='gray', linestyle=':', label='Lower Saturation Bound ($d_{min} = 0.0$)')
ax2a.set_xlabel('Time (s)', fontsize=11)
ax2a.set_ylabel('Duty Cycle Command $d$', fontsize=11)
ax2a.set_title('Stage 1 Step 4: PID Controller Duty Cycle Command & Saturation Dynamics', fontsize=13, fontweight='bold')
ax2a.grid(True, linestyle=':', alpha=0.5)
ax2a.legend(loc='upper right', fontsize=10)

# Voltage & Current
ax2b.plot(t_vec, Veff_vec, color='#00aaff', linewidth=1.8, label='Effective Terminal Voltage $V_{eff}(t) = d \\cdot V_{dc}$')
ax2b_twin = ax2b.twinx()
ax2b_twin.plot(t_vec, i_vec, color='#b366ff', linewidth=1.8, label='Armature Current $i(t)$')
ax2b.set_xlabel('Time (s)', fontsize=11)
ax2b.set_ylabel('Effective Voltage $V_{eff}$ (V)', color='#00aaff', fontsize=11)
ax2b_twin.set_ylabel('Current $i$ (A)', color='#b366ff', fontsize=11)
ax2b.set_title('Effective Motor Terminal Voltage & Armature Current', fontsize=13, fontweight='bold')
ax2b.grid(True, linestyle=':', alpha=0.5)

# Combine legends for twinx
lines_1, labels_1 = ax2b.get_legend_handles_labels()
lines_2, labels_2 = ax2b_twin.get_legend_handles_labels()
ax2b.legend(lines_1 + lines_2, labels_1 + labels_2, loc='upper right', fontsize=10)

fig2.suptitle('Stage 1 Step 4: Control Signals & Actuator Power Dynamics', fontsize=14, fontweight='bold', y=0.98)
plt.tight_layout()
fig2.savefig(os.path.join(results_dir, 'closed_loop_control_signals.png'))
plt.close(fig2)
print(f"Saved: {os.path.join(results_dir, 'closed_loop_control_signals.png')}")

# Plot 3: closed_loop_disturbance_rejection.png
fig3, (ax3a, ax3b) = plt.subplots(2, 1, figsize=(10, 7), dpi=150)

ax3a.plot(t_dist_vec, np.degrees(theta_true_dist), color='#00aaff', linewidth=2.0, label='True Position $\\theta_{true}(t)$ under Load Disturbance')
ax3a.plot(t_dist_vec, np.degrees(theta_ref_dist), color='#ffffff', linestyle='--', linewidth=1.5, label='Reference Target ($90^\\circ$)')
ax3a.axvline(0.30, color='#ff3366', linestyle='--', linewidth=1.5, label='Step Load Disturbance $T_L = 0.01\\text{ N}\\cdot\\text{m}$ at $t = 0.30\\text{ s}$')
ax3a.set_xlabel('Time (s)', fontsize=11)
ax3a.set_ylabel('Position (deg)', fontsize=11)
ax3a.set_title('Stage 1 Step 4: Closed-Loop Position Under Load Disturbance $T_L = 0.01\\text{ N}\\cdot\\text{m}$', fontsize=13, fontweight='bold')
ax3a.grid(True, linestyle=':', alpha=0.5)
ax3a.legend(loc='lower right', fontsize=10)

ax3b.plot(t_dist_vec, d_dist, color='#ff9900', linewidth=1.8, label='PID Restoring Duty Cycle $d(t)$')
ax3b.axvline(0.30, color='#ff3366', linestyle='--', linewidth=1.5, label='Load Disturbance Applied ($t = 0.30\\text{ s}$)')
ax3b.set_xlabel('Time (s)', fontsize=11)
ax3b.set_ylabel('Duty Cycle $d$', fontsize=11)
ax3b.set_title('Controller Compensatory Duty Cycle Response to Load Disturbance', fontsize=13, fontweight='bold')
ax3b.grid(True, linestyle=':', alpha=0.5)
ax3b.legend(loc='upper right', fontsize=10)

fig3.suptitle('Stage 1 Step 4: Closed-Loop Disturbance Rejection Performance', fontsize=14, fontweight='bold', y=0.98)
plt.tight_layout()
fig3.savefig(os.path.join(results_dir, 'closed_loop_disturbance_rejection.png'))
plt.close(fig3)
print(f"Saved: {os.path.join(results_dir, 'closed_loop_disturbance_rejection.png')}")

# Plot 4: stage4_closed_loop_dashboard.png
fig4, axes = plt.subplots(2, 2, figsize=(11, 8), dpi=150)

# Panel 1: Position Tracking
axes[0, 0].plot(t_vec, np.degrees(theta_true_vec), color='#00aaff', linewidth=1.8, label='$\\theta_{true}$')
axes[0, 0].plot(t_vec, np.degrees(theta_enc_vec), ':', color='#00ffcc', linewidth=1.5, label='$\\theta_{enc}$')
axes[0, 0].plot(t_vec, np.degrees(theta_ref_vec), '--', color='#ffffff', linewidth=1.2, label='$\\theta_{ref}$')
axes[0, 0].grid(True, linestyle=':', alpha=0.5)
axes[0, 0].set_xlabel('Time (s)')
axes[0, 0].set_ylabel('Position (deg)')
axes[0, 0].set_title('1. Closed-Loop Position Step Response ($90^\\circ$)')
axes[0, 0].legend(loc='lower right', fontsize=8)

# Panel 2: Error Convergence
axes[0, 1].plot(t_vec, np.degrees(e_vec), color='#ff3366', linewidth=1.8)
axes[0, 1].axhline(res_deg, color='#ffcc00', linestyle='--', linewidth=1.0)
axes[0, 1].axhline(-res_deg, color='#ffcc00', linestyle='--', linewidth=1.0)
axes[0, 1].grid(True, linestyle=':', alpha=0.5)
axes[0, 1].set_xlabel('Time (s)')
axes[0, 1].set_ylabel('Error $e$ (deg)')
axes[0, 1].set_title(f'2. Quantized Tracking Error Bound ($\\pm {res_deg:.2f}^\\circ$)')

# Panel 3: Duty Cycle Action
axes[1, 0].plot(t_vec, d_vec, color='#ff9900', linewidth=1.8)
axes[1, 0].axhline(1.0, color='gray', linestyle=':', linewidth=1.0)
axes[1, 0].grid(True, linestyle=':', alpha=0.5)
axes[1, 0].set_xlabel('Time (s)')
axes[1, 0].set_ylabel('Duty Cycle $d$')
axes[1, 0].set_title('3. Actuator Duty Cycle $d(t) \\in [0, 1]$')

# Panel 4: Speed & Current
ax4_twin = axes[1, 1].twinx()
axes[1, 1].plot(t_vec, w_vec, color='#00aaff', linewidth=1.8, label='Speed $\\omega$ (rad/s)')
ax4_twin.plot(t_vec, i_vec, color='#b366ff', linewidth=1.5, linestyle='--', label='Current $i$ (A)')
axes[1, 1].grid(True, linestyle=':', alpha=0.5)
axes[1, 1].set_xlabel('Time (s)')
axes[1, 1].set_ylabel('Speed $\\omega$ (rad/s)', color='#00aaff')
ax4_twin.set_ylabel('Current $i$ (A)', color='#b366ff')
axes[1, 1].set_title('4. Motor Speed & Armature Current Dynamics')

fig4.suptitle('Stage 1 Step 4: Closed-Loop Encoder-Feedback PID Control Dashboard', fontsize=15, fontweight='bold', y=0.98)
plt.tight_layout()
fig4.savefig(os.path.join(results_dir, 'stage4_closed_loop_dashboard.png'))
plt.close(fig4)
print(f"Saved: {os.path.join(results_dir, 'stage4_closed_loop_dashboard.png')}")
