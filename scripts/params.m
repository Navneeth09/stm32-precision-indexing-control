% =========================================================================
% Stage 1 Step 4 - Parameter Definitions
% Project 2: STM32 Automated Precision Indexing & Feed Control
% =========================================================================

% --- Electromechanical Motor Plant Parameters (Preserved Step 1 Baseline) ---
R  = 0.5;       % Armature Resistance (Ohm)
L  = 0.0005;    % Armature Inductance (H)
Kt = 0.05;      % Torque Constant (N*m/A)
Ke = 0.05;      % Back-EMF Constant (V*s/rad)
J  = 1e-5;      % Rotor Inertia (kg*m^2)
B  = 1e-5;      % Viscous Damping Coefficient (N*m*s/rad)
TL  = 0.0;       % Load Torque (N*m)
TL_step = 0.01;  % Load Torque Disturbance Step Magnitude (N*m)
t_load  = 0.30;  % Load Torque Disturbance Input Time (s)
V_app   = 12.0;  % Step 1 Applied Step Voltage (V)
w_ss_theoretical = (V_app * Kt) / (R * B + Kt * Ke); % Theoretical steady-state speed
i_ss_theoretical = (V_app * B) / (R * B + Kt * Ke);  % Theoretical steady-state current

% Simulation Timing Parameters
t_step = 0.05;  % Position Reference Step Input Time (s)
t_stop = 0.50;  % Simulation Duration (s)

% --- Incremental Encoder Model Parameters (Preserved Step 2 Baseline) ---
PPR = 250;               % Base Optical Disk Pulses Per Revolution (pulses/rev)
quadrature_factor = 4;   % 4x Quadrature Decoding Factor (edges/pulse)
CPR = PPR * quadrature_factor; % Counts Per Revolution (counts/rev) -> 1000 counts/rev
res_rad = (2 * pi) / CPR; % Encoder Resolution in Radians (rad/count) ~ 0.006283 rad
res_deg = 360 / CPR;      % Encoder Resolution in Degrees (deg/count) -> 0.36 deg

% --- Averaged PWM Actuation Parameters (Preserved Step 3 Baseline) ---
V_dc = 12.0;    % DC Supply Voltage for Averaged H-Bridge Model (V)
d_step = 0.75;  % Step 3 Applied Step Duty Cycle (0.75)
d_full = 1.0;   % Step 3 Full Duty Cycle (1.0)

% --- Closed-Loop PID Position Controller Parameters (Stage 1 Step 4) ---
theta_ref_deg = 90.0;              % Target Indexing Position Command (degrees)
theta_ref_val = theta_ref_deg * pi / 180; % Target Position Command (radians) = 1.5707963 rad (pi/2)

% PID Controller Gains tuned for Motor Plant + 1000 CPR Encoder Feedback
Kp_pos = 1.00;  % Proportional Gain
Ki_pos = 0.10;  % Integral Gain
Kd_pos = 0.0500; % Derivative Gain
N_filter = 1000; % Derivative Filter Coefficient

% --- Discrete-Time Sampled PID & Motion Profile Parameters (Stage 1 Step 5) ---
Ts_disc = 0.001;        % Discrete Control Sampling Period Ts = 1 ms (1000 Hz)
a_max = 50.0;           % Max Acceleration Limit (rad/s^2)
omega_max = 8.0;        % Max Cruising Velocity Limit (rad/s)

% Kinematic Profile Timings for 90 deg move
t_a_prof = omega_max / a_max;                        % Acceleration duration = 0.160 s
theta_a_prof = 0.5 * a_max * t_a_prof^2;             % Accel displacement = 0.640 rad
theta_c_prof = theta_ref_val - 2 * theta_a_prof;     % Cruising displacement = 0.2907963 rad
t_c_prof = theta_c_prof / omega_max;                 % Cruising duration = 0.0363495 s
t_f_prof = 2 * t_a_prof + t_c_prof;                  % Total motion duration = 0.3563495 s

% Discrete PID Controller Gains (T_s = 1 ms) - Corrected & Validated Optimization
Kp_disc = 0.50;         % Discrete Proportional Gain (lowered from 2.50 to eliminate current spikes)
Ki_disc = 8.00;         % Discrete Integral Gain (increased from 0.50 to eliminate quantization offset within 20ms)
Kd_disc = 0.0000;       % Discrete Derivative Gain (lowered from 0.080 to remove quantization noise spikes)
N_disc = 20;            % Discrete Derivative Filter Coefficient

% Explicit Configurable Feedforward Gains (Physical Plant Derivatives including damping & inductance)
Kff_v = (Ke + R * B / Kt) / V_dc;                     % Velocity Feedforward Gain = 0.004175 V/(rad/s)
Kff_a = (J * R / Kt + L * B / Kt) / V_dc;              % Acceleration Feedforward Gain = 0.00000834 V/(rad/s^2)

% Multi-Step Sequential Indexing Simulation Parameters (Test Case 2)
t_stop_seq = 1.500;     % Simulation Duration for 3x Sequential Moves (s)

% --- Robustness, Disturbance Rejection, & Nonlinear Friction Parameters (Stage 1 Step 6) ---
TL_step_val = 0.010;        % Load Torque Disturbance Magnitude (N*m)
t_load_motion = 0.200;      % In-Motion Load Disturbance Step Time (s)
t_load_dwell = 0.600;       % In-Dwell Load Disturbance Step Time (s)
t_load_pulse_dur = 0.150;   % In-Dwell Load Disturbance Pulse Duration (s)

T_stick = 0.0020;           % Static Stiction Breakaway Torque (N*m)
T_coulomb = 0.0010;         % Dynamic Coulomb Friction Torque (N*m)
omega_zero_thresh = 0.001;  % Zero-Velocity Threshold for Friction Sign Function (rad/s)

J_nominal = J;              % Nominal Inertia (1.0e-5 kg*m^2)
J_var_high = 2.0e-5;        % 2x Inertia Variation (+100%)
J_var_heavy = 3.0e-5;       % 3x Inertia Variation (+200%)

t_stop_rob = 0.800;         % Simulation Duration for Step 6 Robustness Tests (s)

disp('====================================================');
disp('Stage 1 Step 6 Parameters Loaded:');
fprintf('  Motor Plant: R=%.2f Ohm, L=%.6f H, Kt=%.4f, Ke=%.4f, J=%.2e, B=%.2e\n', R, L, Kt, Ke, J, B);
fprintf('  Encoder Resolution: %d CPR (%.6f rad/count, %.4f deg/count)\n', CPR, res_rad, res_deg);
fprintf('  Actuator: V_dc=%.1f V (Averaged PWM)\n', V_dc);
fprintf('  Step 4 Continuous PID: Kp=%.2f, Ki=%.2f, Kd=%.4f\n', Kp_pos, Ki_pos, Kd_pos);
fprintf('  Step 5 Discrete PID (Ts=%.3fs, 1kHz): Kp=%.2f, Ki=%.2f, Kd=%.4f (Filter N=%d)\n', Ts_disc, Kp_disc, Ki_disc, Kd_disc, N_disc);
fprintf('  Step 5 Feedforward Gains: Kff_v=%.6f V/(rad/s), Kff_a=%.8f V/(rad/s^2)\n', Kff_v, Kff_a);
fprintf('  Step 6 Disturbances: TL=%.3f N*m (t_motion=%.2fs, t_dwell=%.2fs)\n', TL_step_val, t_load_motion, t_load_dwell);
fprintf('  Step 6 Friction: T_stick=%.4f N*m, T_coulomb=%.4f N*m\n', T_stick, T_coulomb);
fprintf('  Step 6 Inertia Sensitivity: J_nominal=%.1ee, J_high=%.1ee, J_heavy=%.1ee kg*m^2\n', J_nominal, J_var_high, J_var_heavy);
fprintf('  Target Reference Command: theta_target = %.2f deg (%.6f rad)\n', theta_ref_deg, theta_ref_val);
disp('====================================================');

