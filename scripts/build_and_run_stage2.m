% =========================================================================
% Stage 1 Step 2 - Encoder Model Creation and Simulation Script
% Project 2: STM32 Automated Precision Indexing & Feed Control
% =========================================================================

clear; clc; close all;

% 1. Load Parameters
scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptDir);
run(fullfile(scriptDir, 'params.m'));

% 2. Define Model Names and Paths
step1ModelName = 'stage1_motor_plant';
modelName = 'stage1_encoder_model';
modelDir = fullfile(projectRoot, 'models');
step1ModelPath = fullfile(modelDir, [step1ModelName '.slx']);
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

% 5. Create new Simulink model for Step 2
disp('Creating Step 2 Simulink model structure with Encoder path...');
new_system(modelName);
load_system(modelName);

% Set solver configurations (Preserved from Step 1)
set_param(modelName, 'SolverType', 'Variable-step');
set_param(modelName, 'Solver', 'ode45');
set_param(modelName, 'StopTime', num2str(t_stop));
set_param(modelName, 'SaveOutput', 'on');
set_param(modelName, 'SignalLogging', 'on');

% 6. Add Motor Plant Blocks (Identical to Step 1 Baseline)
add_block('simulink/Sources/Step', [modelName '/Voltage_Input'], ...
    'Time', num2str(t_step), 'Before', '0', 'After', num2str(V_app), ...
    'Position', [50, 100, 80, 130]);

add_block('simulink/Math Operations/Sum', [modelName '/Sum_Electrical'], ...
    'Inputs', '+--', ...
    'Position', [140, 100, 160, 130]);

add_block('simulink/Math Operations/Gain', [modelName '/Gain_InvL'], ...
    'Gain', '1/L', ...
    'Position', [190, 100, 240, 130]);

add_block('simulink/Continuous/Integrator', [modelName '/Integrator_Current'], ...
    'InitialCondition', '0', ...
    'Position', [270, 100, 300, 130]);

add_block('simulink/Math Operations/Gain', [modelName '/Gain_R'], ...
    'Gain', 'R', ...
    'Orientation', 'left', ...
    'Position', [200, 160, 240, 190]);

add_block('simulink/Math Operations/Gain', [modelName '/Gain_Ke'], ...
    'Gain', 'Ke', ...
    'Orientation', 'left', ...
    'Position', [200, 220, 240, 250]);

add_block('simulink/Math Operations/Gain', [modelName '/Gain_Kt'], ...
    'Gain', 'Kt', ...
    'Position', [340, 100, 380, 130]);

add_block('simulink/Sources/Constant', [modelName '/Load_Torque_TL'], ...
    'Value', 'TL', ...
    'Position', [390, 40, 420, 70]);

add_block('simulink/Math Operations/Sum', [modelName '/Sum_Mechanical'], ...
    'Inputs', '+--', ...
    'Position', [420, 100, 440, 130]);

add_block('simulink/Math Operations/Gain', [modelName '/Gain_InvJ'], ...
    'Gain', '1/J', ...
    'Position', [470, 100, 520, 130]);

add_block('simulink/Continuous/Integrator', [modelName '/Integrator_Speed'], ...
    'InitialCondition', '0', ...
    'Position', [550, 100, 580, 130]);

add_block('simulink/Math Operations/Gain', [modelName '/Gain_B'], ...
    'Gain', 'B', ...
    'Orientation', 'left', ...
    'Position', [480, 180, 520, 210]);

add_block('simulink/Continuous/Integrator', [modelName '/Integrator_Position'], ...
    'InitialCondition', '0', ...
    'Position', [640, 100, 670, 130]);

% --- Motor Logging ---
add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_V'], ...
    'VariableName', 'sim_V', 'SaveFormat', 'Timeseries', ...
    'Position', [120, 30, 170, 50]);

add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_i'], ...
    'VariableName', 'sim_i', 'SaveFormat', 'Timeseries', ...
    'Position', [320, 30, 370, 50]);

add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_w'], ...
    'VariableName', 'sim_w', 'SaveFormat', 'Timeseries', ...
    'Position', [600, 30, 650, 50]);

add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_theta_true'], ...
    'VariableName', 'sim_theta_true', 'SaveFormat', 'Timeseries', ...
    'Position', [700, 30, 750, 50]);

add_block('simulink/Sinks/Scope', [modelName '/Scope_TRUE_POSITION'], ...
    'Position', [710, 170, 740, 200]);

% 7. Add Encoder Measurement Subsystem / Path (Step 2 Extension)
% Input: True Position theta(t)
% Gain (Rad to Counts): CPR / (2*pi)
add_block('simulink/Math Operations/Gain', [modelName '/Gain_RadToCounts'], ...
    'Gain', 'CPR/(2*pi)', ...
    'Position', [730, 100, 780, 130]);

% Quantization: Floor rounding function to obtain integer counts
add_block('simulink/Math Operations/Rounding Function', [modelName '/Encoder_Quantizer'], ...
    'Operator', 'floor', ...
    'Position', [810, 100, 850, 130]);

% Encoder Counts output log & scope
add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_counts'], ...
    'VariableName', 'sim_counts', 'SaveFormat', 'Timeseries', ...
    'Position', [880, 30, 930, 50]);

add_block('simulink/Sinks/Scope', [modelName '/Scope_ENCODER_COUNTS'], ...
    'Position', [880, 170, 910, 200]);

% Gain (Counts to Rad): (2*pi) / CPR
add_block('simulink/Math Operations/Gain', [modelName '/Gain_CountsToRad'], ...
    'Gain', '(2*pi)/CPR', ...
    'Position', [880, 100, 930, 130]);

% Measured Position output log & scope
add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_theta_enc'], ...
    'VariableName', 'sim_theta_enc', 'SaveFormat', 'Timeseries', ...
    'Position', [970, 30, 1020, 50]);

add_block('simulink/Sinks/Scope', [modelName '/Scope_MEASURED_POSITION'], ...
    'Position', [970, 170, 1000, 200]);

% Position Error Junction: Measured Position - True Position
add_block('simulink/Math Operations/Sum', [modelName '/Sum_Error'], ...
    'Inputs', '+-', ...
    'Position', [970, 100, 990, 130]);

add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_err'], ...
    'VariableName', 'sim_err', 'SaveFormat', 'Timeseries', ...
    'Position', [1020, 100, 1070, 120]);

% 8. Connect Signal Lines
% --- Motor Connections ---
add_line(modelName, 'Voltage_Input/1', 'Sum_Electrical/1', 'autorouting', 'on');
add_line(modelName, 'Voltage_Input/1', 'ToWorkspace_V/1', 'autorouting', 'on');

add_line(modelName, 'Sum_Electrical/1', 'Gain_InvL/1', 'autorouting', 'on');
add_line(modelName, 'Gain_InvL/1', 'Integrator_Current/1', 'autorouting', 'on');

add_line(modelName, 'Integrator_Current/1', 'Gain_R/1', 'autorouting', 'on');
add_line(modelName, 'Gain_R/1', 'Sum_Electrical/2', 'autorouting', 'on');
add_line(modelName, 'Integrator_Current/1', 'Gain_Kt/1', 'autorouting', 'on');
add_line(modelName, 'Integrator_Current/1', 'ToWorkspace_i/1', 'autorouting', 'on');

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

add_line(modelName, 'Integrator_Position/1', 'ToWorkspace_theta_true/1', 'autorouting', 'on');
add_line(modelName, 'Integrator_Position/1', 'Scope_TRUE_POSITION/1', 'autorouting', 'on');

% --- Encoder Measurement Path Connections ---
% True Position -> Gain_RadToCounts -> Encoder_Quantizer -> Gain_CountsToRad
add_line(modelName, 'Integrator_Position/1', 'Gain_RadToCounts/1', 'autorouting', 'on');
add_line(modelName, 'Integrator_Position/1', 'Sum_Error/2', 'autorouting', 'on'); % (-) input for error

add_line(modelName, 'Gain_RadToCounts/1', 'Encoder_Quantizer/1', 'autorouting', 'on');

add_line(modelName, 'Encoder_Quantizer/1', 'ToWorkspace_counts/1', 'autorouting', 'on');
add_line(modelName, 'Encoder_Quantizer/1', 'Scope_ENCODER_COUNTS/1', 'autorouting', 'on');
add_line(modelName, 'Encoder_Quantizer/1', 'Gain_CountsToRad/1', 'autorouting', 'on');

add_line(modelName, 'Gain_CountsToRad/1', 'ToWorkspace_theta_enc/1', 'autorouting', 'on');
add_line(modelName, 'Gain_CountsToRad/1', 'Scope_MEASURED_POSITION/1', 'autorouting', 'on');
add_line(modelName, 'Gain_CountsToRad/1', 'Sum_Error/1', 'autorouting', 'on'); % (+) input for error

add_line(modelName, 'Sum_Error/1', 'ToWorkspace_err/1', 'autorouting', 'on');

% 9. Save Step 2 Model
save_system(modelName, modelPath);
disp(['Stage 1 Step 2 model saved successfully to: ' modelPath]);

% 10. Run Simulation for Step 2
disp('Running Stage 1 Step 2 Simulink simulation...');
simOut = sim(modelName);
disp('Simulation completed successfully.');

% 11. Run Step 1 Baseline Simulation to Verify Dynamics Preservation
disp('Verifying Step 1 Baseline Model dynamics preservation...');
load_system(step1ModelPath);
step1Out = sim(step1ModelName);

% 12. Extract Signal Data
t_vec = simOut.sim_w.Time;
theta_true = simOut.sim_theta_true.Data;
counts_vec = simOut.sim_counts.Data;
theta_enc = simOut.sim_theta_enc.Data;
err_vec = simOut.sim_err.Data;
w_vec_step2 = simOut.sim_w.Data;
w_vec_step1 = step1Out.sim_w.Data;

% 13. Perform Comprehensive Validation
disp('====================================================');
disp('STAGE 1 STEP 2 VALIDATION RESULTS:');
disp('====================================================');

% Baseline Integrity Check
max_speed_diff = max(abs(w_vec_step2 - w_vec_step1));
fprintf('1. Motor Plant Dynamics Preservation Check:\n');
fprintf('   Max Speed Difference between Step 1 and Step 2 = %.6e rad/s\n', max_speed_diff);
assert(max_speed_diff < 1e-12, 'Step 1 baseline motor dynamics altered!');
disp('   [PASS] Step 1 baseline motor dynamics 100% preserved.');

% Encoder Metrics Calculation
final_true_pos = theta_true(end);
final_enc_pos = theta_enc(end);
final_counts = counts_vec(end);
max_pos_err = max(abs(err_vec));
mean_pos_err = mean(abs(err_vec));

fprintf('2. Encoder Measurement Metrics:\n');
fprintf('   Encoder Specification: %d PPR, 4x Quadrature -> %d CPR\n', PPR, CPR);
fprintf('   Encoder Resolution (rad/count): %.8f rad/count\n', res_rad);
fprintf('   Encoder Resolution (deg/count): %.4f deg/count\n', res_deg);
fprintf('   Final True Position theta(t_stop): %.6f rad (%.4f deg)\n', final_true_pos, final_true_pos * 180 / pi);
fprintf('   Final Measured Position theta_enc(t_stop): %.6f rad (%.4f deg)\n', final_enc_pos, final_enc_pos * 180 / pi);
fprintf('   Total Accumulated Encoder Counts: %d counts\n', final_counts);
fprintf('   Expected Theoretical Counts: %d counts\n', floor(final_true_pos / res_rad));
fprintf('   Max Absolute Measurement Error |e_theta|_max: %.8f rad (%.4f deg)\n', max_pos_err, max_pos_err * 180 / pi);
fprintf('   Mean Absolute Measurement Error |e_theta|_mean: %.8f rad (%.4f deg)\n', mean_pos_err, mean_pos_err * 180 / pi);

% Check error bound
assert(max_pos_err <= res_rad + 1e-12, 'Encoder error exceeds theoretical resolution bound!');
disp('   [PASS] Position error strictly bounded by encoder resolution (<= 0.006283 rad / 0.36 deg).');
disp('====================================================');

% 14. Save Data for Plot Generation
dataFile = fullfile(resultsDir, 'stage2_data.mat');
save(dataFile, 't_vec', 'theta_true', 'counts_vec', 'theta_enc', 'err_vec', 'res_rad');
disp(['Saved simulation data to: ' dataFile]);
disp('Stage 1 Step 2 simulation and verification complete.');
