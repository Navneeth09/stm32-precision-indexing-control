import os
import numpy as np
import scipy.io as sio
import matplotlib.pyplot as plt

def generate_stage5_plots():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    results_dir = os.path.join(project_root, 'results', 'stage1')
    plots_dir = os.path.join(project_root, 'plots', 'stage1')
    os.makedirs(results_dir, exist_ok=True)
    os.makedirs(plots_dir, exist_ok=True)
    artifacts_dir = os.environ.get('ARTIFACTS_DIR', plots_dir)

    mat_path = os.path.join(results_dir, 'stage5_data.mat')
    if not os.path.exists(mat_path):
        raise FileNotFoundError(f"MAT file not found at: {mat_path}")

    # Load MATLAB simulation dataset
    data = sio.loadmat(mat_path)

    # Extract arrays and corresponding time vectors
    t_ref_base = data['t_base'].flatten()
    theta_ref_base = data['theta_ref_base'].flatten() * 180.0 / np.pi
    
    # Slice or extract arrays matching their own lengths
    e_true_base = data['e_true_base'].flatten() * 180.0 / np.pi
    e_enc_base = data['e_enc_base'].flatten() * 180.0 / np.pi
    d_base = data['d_base'].flatten()
    i_base = data['i_base'].flatten()
    theta_true_base = data['theta_true_base'].flatten() * 180.0 / np.pi

    t_vec = data['t_vec'].flatten()
    theta_ref_vec = data['theta_ref_vec'].flatten() * 180.0 / np.pi
    e_true_vec = data['e_true_vec'].flatten() * 180.0 / np.pi
    e_enc_vec = data['e_enc_vec'].flatten() * 180.0 / np.pi
    d_vec = data['d_vec'].flatten()
    Veff_vec = data['Veff_vec'].flatten()
    i_vec = data['i_vec'].flatten()
    w_vec = data['w_vec'].flatten()
    theta_true_vec = data['theta_true_vec'].flatten() * 180.0 / np.pi
    theta_enc_vec = data['theta_enc_vec'].flatten() * 180.0 / np.pi

    t_seq_vec = data['t_seq_vec'].flatten()
    theta_ref_seq = data['theta_ref_seq'].flatten() * 180.0 / np.pi
    e_true_seq = data['e_true_seq'].flatten() * 180.0 / np.pi
    e_enc_seq = data['e_enc_seq'].flatten() * 180.0 / np.pi
    d_seq = data['d_seq'].flatten()
    i_seq = data['i_seq'].flatten()
    theta_true_seq = data['theta_true_seq'].flatten() * 180.0 / np.pi
    theta_enc_seq = data['theta_enc_seq'].flatten() * 180.0 / np.pi

    # Ensure time vector lengths match signal data via interpolation or uniform grid
    t_grid = np.linspace(0.0, 0.50, 1000)
    t_grid_seq = np.linspace(0.0, 1.50, 3000)

    theta_ref_base_interp = np.interp(t_grid, t_ref_base, theta_ref_base)
    theta_true_base_interp = np.interp(t_grid, t_ref_base, theta_true_base[:len(t_ref_base)])
    e_true_base_interp = np.interp(t_grid, t_ref_base, e_true_base[:len(t_ref_base)])
    d_base_interp = np.interp(t_grid, t_ref_base, d_base[:len(t_ref_base)])
    i_base_interp = np.interp(t_grid, t_ref_base, i_base[:len(t_ref_base)])

    theta_ref_vec_interp = np.interp(t_grid, t_vec, theta_ref_vec)
    theta_true_vec_interp = np.interp(t_grid, t_vec, theta_true_vec[:len(t_vec)])
    theta_enc_vec_interp = np.interp(t_grid, t_vec, theta_enc_vec[:len(t_vec)])
    e_true_vec_interp = np.interp(t_grid, t_vec, e_true_vec[:len(t_vec)])
    e_enc_vec_interp = np.interp(t_grid, t_vec, e_enc_vec[:len(t_vec)])
    d_vec_interp = np.interp(t_grid, t_vec, d_vec[:len(t_vec)])
    i_vec_interp = np.interp(t_grid, t_vec, i_vec[:len(t_vec)])
    w_vec_interp = np.interp(t_grid, t_vec, w_vec[:len(t_vec)])

    theta_ref_seq_interp = np.interp(t_grid_seq, t_seq_vec, theta_ref_seq)
    theta_true_seq_interp = np.interp(t_grid_seq, t_seq_vec, theta_true_seq[:len(t_seq_vec)])
    theta_enc_seq_interp = np.interp(t_grid_seq, t_seq_vec, theta_enc_seq[:len(t_seq_vec)])
    e_true_seq_interp = np.interp(t_grid_seq, t_seq_vec, e_true_seq[:len(t_seq_vec)])
    e_enc_seq_interp = np.interp(t_grid_seq, t_seq_vec, e_enc_seq[:len(t_seq_vec)])

    # Set publication styling
    plt.style.use('seaborn-v0_8-whitegrid' if 'seaborn-v0_8-whitegrid' in plt.style.available else 'default')
    plt.rcParams.update({
        'font.family': 'sans-serif',
        'font.size': 10,
        'axes.labelsize': 11,
        'axes.titlesize': 12,
        'xtick.labelsize': 10,
        'ytick.labelsize': 10,
        'legend.fontsize': 10,
        'figure.titlesize': 14
    })

    output_paths = []

    # -------------------------------------------------------------------------
    # Plot 1: Position Tracking & Dual Error (True vs Encoder)
    # -------------------------------------------------------------------------
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10, 7), sharex=True)
    
    ax1.plot(t_grid, theta_ref_vec_interp, 'k--', linewidth=1.5, label=r'Reference Target $\theta_{ref}$')
    ax1.plot(t_grid, theta_true_base_interp, color='#d62728', linewidth=1.8, label=r'Baseline PID $\theta_{true}$ (FF Off)')
    ax1.plot(t_grid, theta_true_vec_interp, color='#1f77b4', linewidth=1.8, label=r'Feedforward PID $\theta_{true}$ (FF On)')
    ax1.plot(t_grid, theta_enc_vec_interp, color='#2ca02c', linestyle=':', linewidth=1.5, label=r'Encoder Observed $\theta_{enc}$')
    ax1.axvline(x=0.40635, color='gray', linestyle='--', alpha=0.7, label=r'Profile Complete $t_{prof\_end}=0.4064$s')
    ax1.set_ylabel('Position (deg)')
    ax1.set_title('Stage 1 Step 5 — Discrete Profiled Closed-Loop Position Response')
    ax1.legend(loc='lower right', frameon=True)
    ax1.grid(True, alpha=0.3)

    ax2.plot(t_grid, e_true_base_interp, color='#d62728', linewidth=1.5, label=r'Baseline True Error $e_{true}$')
    ax2.plot(t_grid, e_true_vec_interp, color='#1f77b4', linewidth=1.5, label=r'Feedforward True Error $e_{true}$')
    ax2.plot(t_grid, e_enc_vec_interp, color='#2ca02c', linestyle='--', linewidth=1.5, label=r'Feedforward Encoder Error $e_{enc}$')
    ax2.axhline(y=1.72, color='red', linestyle=':', label=r'Max Tracking Error Limit ($\pm 1.72^\circ$)')
    ax2.axhline(y=-1.72, color='red', linestyle=':')
    ax2.axhline(y=0.36, color='orange', linestyle='--', alpha=0.8, label=r'Steady-State Error Limit ($\pm 0.36^\circ$)')
    ax2.axhline(y=-0.36, color='orange', linestyle='--', alpha=0.8)
    ax2.set_xlabel('Time (s)')
    ax2.set_ylabel('Tracking Error (deg)')
    ax2.set_title('Dual Dynamic & Steady-State Tracking Error')
    ax2.legend(loc='upper right', frameon=True)
    ax2.grid(True, alpha=0.3)

    plt.tight_layout()
    p1_mat = os.path.join(results_dir, 'profiled_loop_position_tracking.png')
    p1_art = os.path.join(artifacts_dir, 'profiled_loop_position_tracking.png')
    fig.savefig(p1_mat, dpi=300)
    fig.savefig(p1_art, dpi=300)
    plt.close(fig)
    output_paths.extend([p1_mat, p1_art])

    # -------------------------------------------------------------------------
    # Plot 2: Control Signals (Duty Cycle, Current, Motor Speed)
    # -------------------------------------------------------------------------
    fig, (ax1, ax2, ax3) = plt.subplots(3, 1, figsize=(10, 8), sharex=True)

    ax1.plot(t_grid, d_base_interp, color='#d62728', linewidth=1.5, label='Baseline Duty Cycle d(t)')
    ax1.plot(t_grid, d_vec_interp, color='#1f77b4', linewidth=1.8, label='Feedforward Duty Cycle d(t)')
    ax1.axhline(y=1.0, color='black', linestyle='--', alpha=0.7, label='Duty Cycle Bound [0, 1]')
    ax1.set_ylabel('Duty Cycle d(t)')
    ax1.set_title('Stage 1 Step 5 — Actuator Duty Cycle & Internal States')
    ax1.legend(loc='upper right', frameon=True)
    ax1.grid(True, alpha=0.3)

    ax2.plot(t_grid, i_base_interp, color='#d62728', linewidth=1.5, label='Baseline Armature Current i(t)')
    ax2.plot(t_grid, i_vec_interp, color='#1f77b4', linewidth=1.8, label='Feedforward Armature Current i(t)')
    ax2.axhline(y=1.50, color='red', linestyle='--', label=r'Current Limit $i_{peak} \leq 1.50$ A')
    ax2.axhline(y=-1.50, color='red', linestyle='--')
    ax2.set_ylabel('Current (A)')
    ax2.set_title('Armature Current Dynamics')
    ax2.legend(loc='upper right', frameon=True)
    ax2.grid(True, alpha=0.3)

    ax3.plot(t_grid, w_vec_interp, color='#9467bd', linewidth=1.8, label=r'Rotor Velocity $\omega(t)$ (rad/s)')
    ax3.axhline(y=8.0, color='gray', linestyle=':', label=r'Max Cruising Speed $\omega_{max} = 8.0$ rad/s')
    ax3.set_xlabel('Time (s)')
    ax3.set_ylabel('Speed (rad/s)')
    ax3.set_title('Angular Velocity Profile')
    ax3.legend(loc='lower right', frameon=True)
    ax3.grid(True, alpha=0.3)

    plt.tight_layout()
    p2_mat = os.path.join(results_dir, 'profiled_loop_control_signals.png')
    p2_art = os.path.join(artifacts_dir, 'profiled_loop_control_signals.png')
    fig.savefig(p2_mat, dpi=300)
    fig.savefig(p2_art, dpi=300)
    plt.close(fig)
    output_paths.extend([p2_mat, p2_art])

    # -------------------------------------------------------------------------
    # Plot 3: Test Case 2 — 3x Sequential 90 deg Indexing Move
    # -------------------------------------------------------------------------
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10, 7), sharex=True)

    ax1.plot(t_grid_seq, theta_ref_seq_interp, 'k--', linewidth=1.5, label=r'Sequential Target $\theta_{ref}$')
    ax1.plot(t_grid_seq, theta_true_seq_interp, color='#1f77b4', linewidth=1.8, label=r'True Position $\theta_{true}$')
    ax1.plot(t_grid_seq, theta_enc_seq_interp, color='#2ca02c', linestyle=':', linewidth=1.5, label=r'Encoder Position $\theta_{enc}$')
    ax1.axhline(y=90.0, color='gray', linestyle=':', alpha=0.6)
    ax1.axhline(y=180.0, color='gray', linestyle=':', alpha=0.6)
    ax1.axhline(y=270.0, color='gray', linestyle=':', alpha=0.6)
    ax1.set_ylabel('Position (deg)')
    ax1.set_title(r'Stage 1 Step 5 — Test Case 2: $3\times$ Sequential $90^\circ$ Indexing ($0^\circ \to 90^\circ \to 180^\circ \to 270^\circ$)')
    ax1.legend(loc='lower right', frameon=True)
    ax1.grid(True, alpha=0.3)

    ax2.plot(t_grid_seq, e_true_seq_interp, color='#d62728', linewidth=1.5, label=r'True Error $e_{true} = \theta_{ref} - \theta_{true}$')
    ax2.plot(t_grid_seq, e_enc_seq_interp, color='#2ca02c', linestyle='--', linewidth=1.5, label=r'Encoder Error $e_{enc} = \theta_{ref} - \theta_{enc}$')
    ax2.axhline(y=0.36, color='orange', linestyle='--', label=r'Encoder Resolution Limit ($\pm 0.36^\circ$)')
    ax2.axhline(y=-0.36, color='orange', linestyle='--')
    ax2.set_xlabel('Time (s)')
    ax2.set_ylabel('Tracking Error (deg)')
    ax2.set_title('Sequential Error Accumulation & Repeatability')
    ax2.legend(loc='upper right', frameon=True)
    ax2.grid(True, alpha=0.3)

    plt.tight_layout()
    p3_mat = os.path.join(results_dir, 'profiled_loop_sequential_indexing.png')
    p3_art = os.path.join(artifacts_dir, 'profiled_loop_sequential_indexing.png')
    fig.savefig(p3_mat, dpi=300)
    fig.savefig(p3_art, dpi=300)
    plt.close(fig)
    output_paths.extend([p3_mat, p3_art])

    # -------------------------------------------------------------------------
    # Plot 4: Stage 5 Summary Dashboard (4-panel)
    # -------------------------------------------------------------------------
    fig, axs = plt.subplots(2, 2, figsize=(12, 9))

    # Panel (1,1): Position Tracking
    axs[0, 0].plot(t_grid, theta_ref_vec_interp, 'k--', label=r'$\theta_{ref}$')
    axs[0, 0].plot(t_grid, theta_true_vec_interp, '#1f77b4', label=r'$\theta_{true}$')
    axs[0, 0].plot(t_grid, theta_enc_vec_interp, '#2ca02c', linestyle=':', label=r'$\theta_{enc}$')
    axs[0, 0].set_title('1. Position Response (90 deg Step)')
    axs[0, 0].set_ylabel('Position (deg)')
    axs[0, 0].legend(loc='lower right')
    axs[0, 0].grid(True, alpha=0.3)

    # Panel (1,2): Error Tracking
    axs[0, 1].plot(t_grid, e_true_vec_interp, '#d62728', label=r'$e_{true}$')
    axs[0, 1].plot(t_grid, e_enc_vec_interp, '#2ca02c', linestyle='--', label=r'$e_{enc}$')
    axs[0, 1].axhline(y=1.72, color='r', linestyle=':')
    axs[0, 1].axhline(y=-1.72, color='r', linestyle=':')
    axs[0, 1].set_title('2. Dynamic & Steady-State Tracking Error')
    axs[0, 1].set_ylabel('Error (deg)')
    axs[0, 1].legend(loc='upper right')
    axs[0, 1].grid(True, alpha=0.3)

    # Panel (2,1): Duty Cycle & Current
    axs[1, 0].plot(t_grid, d_vec_interp, '#1f77b4', label='Duty Cycle d(t)')
    axs[1, 0].plot(t_grid, i_vec_interp / 2.5, '#ff7f0e', linestyle='--', label=r'Normalized Current $i/2.5$')
    axs[1, 0].set_title('3. Actuator Duty Cycle & Armature Current')
    axs[1, 0].set_xlabel('Time (s)')
    axs[1, 0].set_ylabel('Signal Level')
    axs[1, 0].legend(loc='upper right')
    axs[1, 0].grid(True, alpha=0.3)

    # Panel (2,2): Sequential Indexing
    axs[1, 1].plot(t_grid_seq, theta_ref_seq_interp, 'k--', label=r'$\theta_{ref}$')
    axs[1, 1].plot(t_grid_seq, theta_true_seq_interp, '#1f77b4', label=r'$\theta_{true}$')
    axs[1, 1].set_title(r'4. Multi-Move $3\times$ Sequential Indexing')
    axs[1, 1].set_xlabel('Time (s)')
    axs[1, 1].set_ylabel('Position (deg)')
    axs[1, 1].legend(loc='lower right')
    axs[1, 1].grid(True, alpha=0.3)
    plt.tight_layout()
    p4_mat = os.path.join(results_dir, 'stage5_profiled_dashboard.png')
    p4_art = os.path.join(artifacts_dir, 'stage5_profiled_dashboard.png')
    fig.savefig(p4_mat, dpi=300)
    fig.savefig(p4_art, dpi=300)
    plt.close(fig)
    output_paths.extend([p4_mat, p4_art])

    print("Stage 1 Step 5 plots successfully generated and saved to results and artifact directories:")
    for p in output_paths:
        print(f"  - {p}")

if __name__ == '__main__':
    generate_stage5_plots()
