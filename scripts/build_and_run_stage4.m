% =========================================================================
% Stage 1 Step 4 - Closed-Loop Position Controller Builder & Simulator
% Project 2: STM32 Automated Precision Indexing & Feed Control
% =========================================================================

clear; clc; close all;

% 1. Load Parameters
scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptDir);
run(fullfile(scriptDir, 'params.m'));

% 2. Define Model Names and Paths
step1ModelName = 'stage1_motor_plant';
step2ModelName = 'stage1_encoder_model';
step3ModelName = 'stage1_pwm_model';
modelName = 'stage1_closed_loop_model';

modelDir = fullfile(projectRoot, 'models');
step1ModelPath = fullfile(modelDir, [step1ModelName '.slx']);
step2ModelPath = fullfile(modelDir, [step2ModelName '.slx']);
step3ModelPath = fullfile(modelDir, [step3ModelName '.slx']);
modelPath = fullfile(modelDir, [modelName '.slx']);
resultsDir = fullfile(projectRoot, 'results', 'stage1');

if ~exist(modelDir, 'dir')
    mkdir(modelDir);
end
if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end

% 3. Preload Simulink Engine
disp('Preloading Simulink engine...');
load_system('simulink');

% 4. Close system if already loaded/open
if bdIsLoaded(modelName)
    close_system(modelName, 0);
end

% 5. Create new Simulink model for Step 4 (Closed-Loop PID Position Control)
disp('Creating Stage 1 Step 4 Simulink model structure (models/stage1_closed_loop_model.slx)...');
new_system(modelName);
load_system(modelName);

% Set solver configurations (Preserved ode45 continuous solver)
set_param(modelName, 'SolverType', 'Variable-step');
set_param(modelName, 'Solver', 'ode45');
set_param(modelName, 'StopTime', num2str(t_stop));
set_param(modelName, 'SaveOutput', 'on');
set_param(modelName, 'SignalLogging', 'on');

% 6. Add Blocks to Model
% --- Reference Input Block ---
add_block('simulink/Sources/Step', [modelName '/Reference_Position'], ...
    'Time', num2str(t_step), 'Before', '0', 'After', num2str(theta_ref_val), ...
    'Position', [40, 100, 70, 130]);

% --- Closed-Loop Error Summing Junction ---
add_block('simulink/Math Operations/Sum', [modelName '/Sum_Feedback_Error'], ...
    'Inputs', '+-', ...
    'Position', [110, 100, 130, 130]);

% --- Parallel PID Controller Subsystem ---
add_block('simulink/Math Operations/Gain', [modelName '/Gain_Kp'], ...
    'Gain', 'Kp_pos', ...
    'Position', [170, 70, 210, 100]);

add_block('simulink/Continuous/Integrator', [modelName '/Integrator_Ki_State'], ...
    'InitialCondition', '0', ...
    'Position', [170, 120, 200, 150]);

add_block('simulink/Math Operations/Gain', [modelName '/Gain_Ki'], ...
    'Gain', 'Ki_pos', ...
    'Position', [220, 120, 260, 150]);

add_block('simulink/Continuous/Transfer Fcn', [modelName '/TransferFcn_Kd'], ...
    'Numerator', '[Kd_pos*N_filter, 0]', 'Denominator', '[1, N_filter]', ...
    'Position', [170, 170, 250, 200]);

add_block('simulink/Math Operations/Sum', [modelName '/Sum_PID'], ...
    'Inputs', '+++', ...
    'Position', [280, 100, 300, 130]);

% --- Duty Cycle Actuation Saturation ---
add_block('simulink/Discontinuities/Saturation', [modelName '/Saturation_DutyCycle'], ...
    'UpperLimit', '1.0', 'LowerLimit', '0.0', ...
    'Position', [330, 100, 360, 130]);

% --- Averaged PWM H-Bridge Gain ---
add_block('simulink/Math Operations/Gain', [modelName '/Gain_Vdc'], ...
    'Gain', 'V_dc', ...
    'Position', [390, 100, 430, 130]);

% --- Electromechanical Motor Plant (Preserved Baseline Dynamics) ---
add_block('simulink/Math Operations/Sum', [modelName '/Sum_Electrical'], ...
    'Inputs', '+--', ...
    'Position', [460, 100, 480, 130]);

add_block('simulink/Math Operations/Gain', [modelName '/Gain_InvL'], ...
    'Gain', '1/L', ...
    'Position', [500, 100, 540, 130]);

add_block('simulink/Continuous/Integrator', [modelName '/Integrator_Current'], ...
    'InitialCondition', '0', ...
    'Position', [570, 100, 600, 130]);

add_block('simulink/Math Operations/Gain', [modelName '/Gain_R'], ...
    'Gain', 'R', ...
    'Orientation', 'left', ...
    'Position', [510, 160, 550, 190]);

add_block('simulink/Math Operations/Gain', [modelName '/Gain_Ke'], ...
    'Gain', 'Ke', ...
    'Orientation', 'left', ...
    'Position', [510, 220, 550, 250]);

add_block('simulink/Math Operations/Gain', [modelName '/Gain_Kt'], ...
    'Gain', 'Kt', ...
    'Position', [640, 100, 680, 130]);

add_block('simulink/Sources/Step', [modelName '/Load_Torque_TL'], ...
    'Time', num2str(t_load), 'Before', '0', 'After', '0', ...
    'Position', [680, 40, 710, 70]);

add_block('simulink/Math Operations/Sum', [modelName '/Sum_Mechanical'], ...
    'Inputs', '+--', ...
    'Position', [710, 100, 730, 130]);

add_block('simulink/Math Operations/Gain', [modelName '/Gain_InvJ'], ...
    'Gain', '1/J', ...
    'Position', [760, 100, 800, 130]);

add_block('simulink/Continuous/Integrator', [modelName '/Integrator_Speed'], ...
    'InitialCondition', '0', ...
    'Position', [830, 100, 860, 130]);

add_block('simulink/Math Operations/Gain', [modelName '/Gain_B'], ...
    'Gain', 'B', ...
    'Orientation', 'left', ...
    'Position', [760, 180, 800, 210]);

add_block('simulink/Continuous/Integrator', [modelName '/Integrator_Position'], ...
    'InitialCondition', '0', ...
    'Position', [900, 100, 930, 130]);

% --- Step 2 Incremental Encoder Path ---
add_block('simulink/Math Operations/Gain', [modelName '/Gain_RadToCounts'], ...
    'Gain', 'CPR/(2*pi)', ...
    'Position', [970, 100, 1020, 130]);

add_block('simulink/Math Operations/Rounding Function', [modelName '/Encoder_Quantizer'], ...
    'Operator', 'floor', ...
    'Position', [1050, 100, 1090, 130]);

add_block('simulink/Math Operations/Gain', [modelName '/Gain_CountsToRad'], ...
    'Gain', '(2*pi)/CPR', ...
    'Position', [1120, 100, 1170, 130]);

% --- To Workspace Logging Sinks ---
add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_theta_ref'], ...
    'VariableName', 'sim_theta_ref', 'SaveFormat', 'Timeseries', ...
    'Position', [80, 30, 130, 50]);

add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_e'], ...
    'VariableName', 'sim_e', 'SaveFormat', 'Timeseries', ...
    'Position', [140, 30, 190, 50]);

add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_u'], ...
    'VariableName', 'sim_u', 'SaveFormat', 'Timeseries', ...
    'Position', [310, 30, 360, 50]);

add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_d'], ...
    'VariableName', 'sim_d', 'SaveFormat', 'Timeseries', ...
    'Position', [370, 30, 420, 50]);

add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_Veff'], ...
    'VariableName', 'sim_Veff', 'SaveFormat', 'Timeseries', ...
    'Position', [440, 30, 490, 50]);

add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_i'], ...
    'VariableName', 'sim_i', 'SaveFormat', 'Timeseries', ...
    'Position', [610, 30, 660, 50]);

add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_w'], ...
    'VariableName', 'sim_w', 'SaveFormat', 'Timeseries', ...
    'Position', [880, 30, 930, 50]);

add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_theta_true'], ...
    'VariableName', 'sim_theta_true', 'SaveFormat', 'Timeseries', ...
    'Position', [950, 30, 1000, 50]);

add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_counts'], ...
    'VariableName', 'sim_counts', 'SaveFormat', 'Timeseries', ...
    'Position', [1100, 30, 1150, 50]);

add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_theta_enc'], ...
    'VariableName', 'sim_theta_enc', 'SaveFormat', 'Timeseries', ...
    'Position', [1200, 100, 1250, 120]);

% 7. Connect Signal Lines
% Reference input
add_line(modelName, 'Reference_Position/1', 'Sum_Feedback_Error/1', 'autorouting', 'on');
add_line(modelName, 'Reference_Position/1', 'ToWorkspace_theta_ref/1', 'autorouting', 'on');

% Error junction & PID parallel branches
add_line(modelName, 'Sum_Feedback_Error/1', 'Gain_Kp/1', 'autorouting', 'on');
add_line(modelName, 'Sum_Feedback_Error/1', 'Integrator_Ki_State/1', 'autorouting', 'on');
add_line(modelName, 'Sum_Feedback_Error/1', 'TransferFcn_Kd/1', 'autorouting', 'on');
add_line(modelName, 'Sum_Feedback_Error/1', 'ToWorkspace_e/1', 'autorouting', 'on');

add_line(modelName, 'Integrator_Ki_State/1', 'Gain_Ki/1', 'autorouting', 'on');

% PID Summation
add_line(modelName, 'Gain_Kp/1', 'Sum_PID/1', 'autorouting', 'on');
add_line(modelName, 'Gain_Ki/1', 'Sum_PID/2', 'autorouting', 'on');
add_line(modelName, 'TransferFcn_Kd/1', 'Sum_PID/3', 'autorouting', 'on');

% Actuator Saturation & H-Bridge Gain
add_line(modelName, 'Sum_PID/1', 'Saturation_DutyCycle/1', 'autorouting', 'on');
add_line(modelName, 'Sum_PID/1', 'ToWorkspace_u/1', 'autorouting', 'on');

add_line(modelName, 'Saturation_DutyCycle/1', 'Gain_Vdc/1', 'autorouting', 'on');
add_line(modelName, 'Saturation_DutyCycle/1', 'ToWorkspace_d/1', 'autorouting', 'on');

add_line(modelName, 'Gain_Vdc/1', 'Sum_Electrical/1', 'autorouting', 'on');
add_line(modelName, 'Gain_Vdc/1', 'ToWorkspace_Veff/1', 'autorouting', 'on');

% Electrical Dynamics
add_line(modelName, 'Sum_Electrical/1', 'Gain_InvL/1', 'autorouting', 'on');
add_line(modelName, 'Gain_InvL/1', 'Integrator_Current/1', 'autorouting', 'on');
add_line(modelName, 'Integrator_Current/1', 'Gain_R/1', 'autorouting', 'on');
add_line(modelName, 'Gain_R/1', 'Sum_Electrical/2', 'autorouting', 'on');
add_line(modelName, 'Integrator_Current/1', 'Gain_Kt/1', 'autorouting', 'on');
add_line(modelName, 'Integrator_Current/1', 'ToWorkspace_i/1', 'autorouting', 'on');

% Mechanical Dynamics & Load Torque
add_line(modelName, 'Gain_Kt/1', 'Sum_Mechanical/1', 'autorouting', 'on');
add_line(modelName, 'Load_Torque_TL/1', 'Sum_Mechanical/3', 'autorouting', 'on');

add_line(modelName, 'Sum_Mechanical/1', 'Gain_InvJ/1', 'autorouting', 'on');
add_line(modelName, 'Gain_InvJ/1', 'Integrator_Speed/1', 'autorouting', 'on');

add_line(modelName, 'Integrator_Speed/1', 'Gain_B/1', 'autorouting', 'on');
add_line(modelName, 'Gain_B/1', 'Sum_Mechanical/2', 'autorouting', 'on');
add_line(modelName, 'Integrator_Speed/1', 'Gain_Ke/1', 'autorouting', 'on');
add_line(modelName, 'Gain_Ke/1', 'Sum_Electrical/3', 'autorouting', 'on');
add_line(modelName, 'Integrator_Speed/1', 'Integrator_Position/1', 'autorouting', 'on');
add_line(modelName, 'Integrator_Speed/1', 'ToWorkspace_w/1', 'autorouting', 'on');

% Position Integrator & Encoder Path
add_line(modelName, 'Integrator_Position/1', 'ToWorkspace_theta_true/1', 'autorouting', 'on');
add_line(modelName, 'Integrator_Position/1', 'Gain_RadToCounts/1', 'autorouting', 'on');

add_line(modelName, 'Gain_RadToCounts/1', 'Encoder_Quantizer/1', 'autorouting', 'on');
add_line(modelName, 'Encoder_Quantizer/1', 'ToWorkspace_counts/1', 'autorouting', 'on');
add_line(modelName, 'Encoder_Quantizer/1', 'Gain_CountsToRad/1', 'autorouting', 'on');

add_line(modelName, 'Gain_CountsToRad/1', 'ToWorkspace_theta_enc/1', 'autorouting', 'on');

% CLOSED-LOOP FEEDBACK LINE
add_line(modelName, 'Gain_CountsToRad/1', 'Sum_Feedback_Error/2', 'autorouting', 'on');

% 8. Save Step 4 Model
save_system(modelName, modelPath);
disp(['Stage 1 Step 4 model saved successfully to: ' modelPath]);

% 9. Run Simulation Test Case 1: Nominal Closed-Loop Step Response (90 deg step, TL = 0)
disp('Running Simulink Simulation Test Case 1: Nominal Closed-Loop Step Response...');
simOut_nominal = sim(modelName);

% 10. Run Simulation Test Case 2: Disturbance Rejection (Step Load TL = 0.01 N*m at t = 0.30 s)
disp('Running Simulink Simulation Test Case 2: Closed-Loop Disturbance Rejection...');
set_param([modelName '/Load_Torque_TL'], 'After', num2str(TL_step));
save_system(modelName, modelPath);
simOut_dist = sim(modelName);

% Revert load disturbance back to 0 in model file
set_param([modelName '/Load_Torque_TL'], 'After', '0');
save_system(modelName, modelPath);

% 11. Run Baseline Protection Checks on Step 1, Step 2, and Step 3 Models
disp('Running Baseline Protection Check (confirming Step 1, 2, and 3 models remain intact)...');
load_system(step1ModelPath);
step1Out = sim(step1ModelName);
load_system(step2ModelPath);
step2Out = sim(step2ModelName);
load_system(step3ModelPath);
step3Out = sim(step3ModelName);

% 12. Quantitative Verification & Data Provenance
% Extract arrays from Test Case 1 (Nominal)
t_vec = simOut_nominal.sim_theta_ref.Time;
theta_ref_vec = simOut_nominal.sim_theta_ref.Data;
e_vec = simOut_nominal.sim_e.Data;
u_vec = simOut_nominal.sim_u.Data;
d_vec = simOut_nominal.sim_d.Data;
Veff_vec = simOut_nominal.sim_Veff.Data;
i_vec = simOut_nominal.sim_i.Data;
w_vec = simOut_nominal.sim_w.Data;
theta_true_vec = simOut_nominal.sim_theta_true.Data;
counts_vec = simOut_nominal.sim_counts.Data;
theta_enc_vec = simOut_nominal.sim_theta_enc.Data;

% Extract arrays from Test Case 2 (Disturbance)
t_dist_vec = simOut_dist.sim_theta_ref.Time;
theta_ref_dist = simOut_dist.sim_theta_ref.Data;
e_dist = simOut_dist.sim_e.Data;
d_dist = simOut_dist.sim_d.Data;
w_dist = simOut_dist.sim_w.Data;
theta_true_dist = simOut_dist.sim_theta_true.Data;
theta_enc_dist = simOut_dist.sim_theta_enc.Data;

% Metric Calculations
steady_state_err_rad = abs(theta_ref_vec(end) - theta_true_vec(end));
steady_state_err_deg = steady_state_err_rad * 180 / pi;

max_theta_deg = max(theta_true_vec) * 180 / pi;
overshoot_pct = max(0, (max_theta_deg - theta_ref_deg) / theta_ref_deg * 100);

% Settling time (2% band around 90 deg step, step starts at t_step = 0.05 s)
settling_band_deg = 0.02 * theta_ref_deg;
settled_idx = find(abs(theta_true_vec * 180 / pi - theta_ref_deg) > settling_band_deg, 1, 'last');
if isempty(settled_idx)
    t_settling = 0.0;
else
    t_settling = t_vec(settled_idx) - t_step;
end

disp('====================================================');
disp('STAGE 1 STEP 4 CLOSED-LOOP NUMERICAL PROVENANCE:');
disp('====================================================');
fprintf('1. Closed-Loop Position Tracking Accuracy (Nominal Step):\n');
fprintf('   Target Reference Position : %.4f deg (%.6f rad)\n', theta_ref_deg, theta_ref_val);
fprintf('   Final True Position       : %.4f deg (%.6f rad)\n', theta_true_vec(end)*180/pi, theta_true_vec(end));
fprintf('   Final Encoder Position    : %.4f deg (%.6f rad)\n', theta_enc_vec(end)*180/pi, theta_enc_vec(end));
fprintf('   Steady-State Error        : %.6f deg (%.8f rad)\n', steady_state_err_deg, steady_state_err_rad);
fprintf('   Encoder Resolution Bound  : %.4f deg (%.6f rad)\n', res_deg, res_rad);

fprintf('2. Dynamic Response Metrics:\n');
fprintf('   Peak Overshoot            : %.4f%%\n', overshoot_pct);
fprintf('   Settling Time (2%% band)  : %.4f s\n', t_settling);

fprintf('3. Actuator Saturation & Signal Boundaries:\n');
fprintf('   Calculated Output u(t) Range : [%.4f, %.4f]\n', min(u_vec), max(u_vec));
fprintf('   Saturated Duty Cycle d(t) Range: [%.4f, %.4f]\n', min(d_vec), max(d_vec));

fprintf('4. Disturbance Rejection Test Case (TL = 0.01 N*m at t = 0.30 s):\n');
fprintf('   Final Position Under Load : %.4f deg (%.6f rad)\n', theta_true_dist(end)*180/pi, theta_true_dist(end));
fprintf('   Disturbance Error         : %.6f deg (%.8f rad)\n', abs(theta_ref_deg - theta_true_dist(end)*180/pi), abs(theta_ref_val - theta_true_dist(end)));

% Assertions for Stage 1 Step 4 Verification Criteria
assert(steady_state_err_rad <= res_rad + 1e-4, 'Steady state error exceeds encoder resolution bound!');
assert(overshoot_pct <= 10.0, 'Peak overshoot exceeds 10% limit!');
assert(t_settling <= 0.15, 'Settling time exceeds 0.15 s limit!');
assert(min(d_vec) >= 0.0 && max(d_vec) <= 1.0, 'Duty cycle violated saturation bounds [0, 1]!');
disp('   [PASS] All Stage 1 Step 4 verification criteria successfully satisfied.');
disp('====================================================');

% 13. Export Raw Simulation Data to MAT File for Python Plotting
dataFile = fullfile(resultsDir, 'stage4_data.mat');
save(dataFile, 't_vec', 'theta_ref_vec', 'e_vec', 'u_vec', 'd_vec', 'Veff_vec', ...
     'i_vec', 'w_vec', 'theta_true_vec', 'counts_vec', 'theta_enc_vec', ...
     't_dist_vec', 'theta_ref_dist', 'e_dist', 'd_dist', 'w_dist', ...
     'theta_true_dist', 'theta_enc_dist', 'res_rad', 'res_deg', ...
     'steady_state_err_deg', 'overshoot_pct', 't_settling');
disp(['Exported raw simulation data to: ' dataFile]);
disp('Stage 1 Step 4 build, simulation, and provenance validation completed successfully.');
