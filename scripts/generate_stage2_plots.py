import os
import numpy as np
import scipy.io as sio
import matplotlib.pyplot as plt

plt.style.use('dark_background')
plt.rcParams['font.sans-serif'] = 'DejaVu Sans'

project_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
results_dir = os.path.join(project_dir, 'results', 'stage1')
data_file = os.path.join(results_dir, 'stage2_data.mat')

mat_data = sio.loadmat(data_file)
t_vec = mat_data['t_vec'].flatten()
theta_true = mat_data['theta_true'].flatten()
counts_vec = mat_data['counts_vec'].flatten()
theta_enc = mat_data['theta_enc'].flatten()
err_vec = mat_data['err_vec'].flatten()
res_rad = float(mat_data['res_rad'].flatten()[0])

# Plot 1: true_vs_encoder_position.png
fig1, ax1 = plt.subplots(figsize=(10, 6), dpi=150)
ax1.plot(t_vec, theta_true, label='True Motor Position $\\theta_{true}(t)$', color='#00aaff', linewidth=2.2)
ax1.plot(t_vec, theta_enc, '--', label='Encoder Measured Position $\\theta_{encoder}(t)$', color='#ff6600', linewidth=1.8)
ax1.set_xlabel('Time (s)', fontsize=12)
ax1.set_ylabel('Position $\\theta$ (rad)', fontsize=12)
ax1.set_title('Stage 1 Step 2: True Motor Position vs Encoder-Measured Position', fontsize=14, fontweight='bold', pad=12)
ax1.grid(True, linestyle=':', alpha=0.5)
ax1.legend(loc='upper left', fontsize=11)
plt.tight_layout()
fig1.savefig(os.path.join(results_dir, 'true_vs_encoder_position.png'))
plt.close(fig1)
print(f"Saved: {os.path.join(results_dir, 'true_vs_encoder_position.png')}")

# Plot 2: encoder_counts_vs_time.png
fig2, ax2 = plt.subplots(figsize=(10, 6), dpi=150)
ax2.plot(t_vec, counts_vec, label='Simulated Encoder Counts (1000 CPR)', color='#b366ff', linewidth=2.0)
ax2.set_xlabel('Time (s)', fontsize=12)
ax2.set_ylabel('Encoder Counts $N_{counts}$', fontsize=12)
ax2.set_title('Stage 1 Step 2: Accumulated Incremental Encoder Counts (1000 CPR)', fontsize=14, fontweight='bold', pad=12)
ax2.grid(True, linestyle=':', alpha=0.5)
ax2.legend(loc='upper left', fontsize=11)
plt.tight_layout()
fig2.savefig(os.path.join(results_dir, 'encoder_counts_vs_time.png'))
plt.close(fig2)
print(f"Saved: {os.path.join(results_dir, 'encoder_counts_vs_time.png')}")

# Plot 3: encoder_error.png
fig3, (ax3a, ax3b) = plt.subplots(2, 1, figsize=(10, 7.5), dpi=150)

# Subplot 3a: Position Measurement Error over full simulation
ax3a.plot(t_vec, err_vec, color='#ff3366', linewidth=1.5, label='Measurement Error $e_{\\theta}(t) = \\theta_{encoder}(t) - \\theta_{true}(t)$')
ax3a.axhline(0, color='gray', linestyle='--', linewidth=1)
ax3a.axhline(-res_rad, color='#ffcc00', linestyle='--', label=f'Lower Bound (-\\Delta\\theta_{{res}} = -{res_rad:.6f} rad)')
ax3a.axhline(res_rad, color='#ffcc00', linestyle='--', label=f'Upper Bound (+\\Delta\\theta_{{res}} = +{res_rad:.6f} rad)')
ax3a.set_xlabel('Time (s)', fontsize=11)
ax3a.set_ylabel('Error $e_{\\theta}$ (rad)', fontsize=11)
ax3a.set_title('Position Measurement Error $e_{\\theta}(t)$ Bounded by Resolution $\\Delta\\theta_{res}$', fontsize=12, fontweight='bold')
ax3a.grid(True, linestyle=':', alpha=0.5)
ax3a.legend(loc='upper right', fontsize=9)

# Subplot 3b: Zoomed-in staircase quantization behavior
idx_zoom = np.where((t_vec >= 0.080) & (t_vec <= 0.085))[0]
ax3b.plot(t_vec[idx_zoom], theta_true[idx_zoom], color='#00aaff', linewidth=2.2, label='True Position $\\theta_{true}(t)$')
ax3b.step(t_vec[idx_zoom], theta_enc[idx_zoom], where='post', color='#ff6600', linewidth=1.8, label='Quantized Measured Position $\\theta_{encoder}(t)$')
ax3b.set_xlabel('Time (s)', fontsize=11)
ax3b.set_ylabel('Position $\\theta$ (rad)', fontsize=11)
ax3b.set_title('Zoomed-in Staircase Quantization Behavior (t = 0.080s to 0.085s)', fontsize=12, fontweight='bold')
ax3b.grid(True, linestyle=':', alpha=0.5)
ax3b.legend(loc='lower right', fontsize=10)

fig3.suptitle('Stage 1 Step 2: Incremental Encoder Quantization & Measurement Error Analysis', fontsize=14, fontweight='bold', y=0.98)
plt.tight_layout()
fig3.savefig(os.path.join(results_dir, 'encoder_error.png'))
plt.close(fig3)
print(f"Saved: {os.path.join(results_dir, 'encoder_error.png')}")
