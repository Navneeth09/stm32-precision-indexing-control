% =========================================================================
% Stage 1 Step 3 - Averaged PWM Motor Actuation Model Builder & Simulator
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
modelName = 'stage1_pwm_model';
modelDir = fullfile(projectRoot, 'models');
step1ModelPath = fullfile(modelDir, [step1ModelName '.slx']);
step2ModelPath = fullfile(modelDir, [step2ModelName '.slx']);
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

% 5. Create new Simulink model for Step 3 (Averaged PWM Actuation)
disp('Creating Stage 1 Step 3 Simulink model structure (models/stage1_pwm_model.slx)...');
new_system(modelName);
load_system(modelName);

% Set solver configurations (Preserved ode45 continuous solver)
set_param(modelName, 'SolverType', 'Variable-step');
set_param(modelName, 'Solver', 'ode45');
set_param(modelName, 'StopTime', num2str(t_stop));
set_param(modelName, 'SaveOutput', 'on');
set_param(modelName, 'SignalLogging', 'on');

% 6. Add Blocks to Model
% --- Averaged PWM Actuation Subsystem ---
% d(t) -> V_eff(t) = d(t) * V_dc
add_block('simulink/Sources/Step', [modelName '/Duty_Cycle_Input'], ...
    'Time', num2str(t_step), 'Before', '0', 'After', num2str(d_step), ...
    'Position', [40, 100, 70, 130]);

add_block('simulink/Math Operations/Gain', [modelName '/Gain_Vdc'], ...
    'Gain', 'V_dc', ...
    'Position', [100, 100, 140, 130]);

% --- Electromechanical Motor Plant (Identical to Step 1 Baseline) ---
add_block('simulink/Math Operations/Sum', [modelName '/Sum_Electrical'], ...
    'Inputs', '+--', ...
    'Position', [180, 100, 200, 130]);

add_block('simulink/Math Operations/Gain', [modelName '/Gain_InvL'], ...
    'Gain', '1/L', ...
    'Position', [230, 100, 280, 130]);

add_block('simulink/Continuous/Integrator', [modelName '/Integrator_Current'], ...
    'InitialCondition', '0', ...
    'Position', [310, 100, 340, 130]);

add_block('simulink/Math Operations/Gain', [modelName '/Gain_R'], ...
    'Gain', 'R', ...
    'Orientation', 'left', ...
    'Position', [240, 160, 280, 190]);

add_block('simulink/Math Operations/Gain', [modelName '/Gain_Ke'], ...
    'Gain', 'Ke', ...
    'Orientation', 'left', ...
    'Position', [240, 220, 280, 250]);

add_block('simulink/Math Operations/Gain', [modelName '/Gain_Kt'], ...
    'Gain', 'Kt', ...
    'Position', [380, 100, 420, 130]);

add_block('simulink/Sources/Constant', [modelName '/Load_Torque_TL'], ...
    'Value', 'TL', ...
    'Position', [430, 40, 460, 70]);

add_block('simulink/Math Operations/Sum', [modelName '/Sum_Mechanical'], ...
    'Inputs', '+--', ...
    'Position', [460, 100, 480, 130]);

add_block('simulink/Math Operations/Gain', [modelName '/Gain_InvJ'], ...
    'Gain', '1/J', ...
    'Position', [510, 100, 560, 130]);

add_block('simulink/Continuous/Integrator', [modelName '/Integrator_Speed'], ...
    'InitialCondition', '0', ...
    'Position', [590, 100, 620, 130]);

add_block('simulink/Math Operations/Gain', [modelName '/Gain_B'], ...
    'Gain', 'B', ...
    'Orientation', 'left', ...
    'Position', [520, 180, 560, 210]);

add_block('simulink/Continuous/Integrator', [modelName '/Integrator_Position'], ...
    'InitialCondition', '0', ...
    'Position', [680, 100, 710, 130]);

% --- Step 2 Incremental Encoder Path (Passive Logging) ---
add_block('simulink/Math Operations/Gain', [modelName '/Gain_RadToCounts'], ...
    'Gain', 'CPR/(2*pi)', ...
    'Position', [760, 100, 810, 130]);

add_block('simulink/Math Operations/Rounding Function', [modelName '/Encoder_Quantizer'], ...
    'Operator', 'floor', ...
    'Position', [840, 100, 880, 130]);

add_block('simulink/Math Operations/Gain', [modelName '/Gain_CountsToRad'], ...
    'Gain', '(2*pi)/CPR', ...
    'Position', [910, 100, 960, 130]);

add_block('simulink/Math Operations/Sum', [modelName '/Sum_Error'], ...
    'Inputs', '+-', ...
    'Position', [1000, 100, 1020, 130]);

% --- Logging Blocks ---
add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_d'], ...
    'VariableName', 'sim_d', 'SaveFormat', 'Timeseries', ...
    'Position', [80, 30, 130, 50]);

add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_Veff'], ...
    'VariableName', 'sim_Veff', 'SaveFormat', 'Timeseries', ...
    'Position', [160, 30, 210, 50]);

add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_i'], ...
    'VariableName', 'sim_i', 'SaveFormat', 'Timeseries', ...
    'Position', [360, 30, 410, 50]);

add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_w'], ...
    'VariableName', 'sim_w', 'SaveFormat', 'Timeseries', ...
    'Position', [640, 30, 690, 50]);

add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_theta_true'], ...
    'VariableName', 'sim_theta_true', 'SaveFormat', 'Timeseries', ...
    'Position', [730, 30, 780, 50]);

add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_counts'], ...
    'VariableName', 'sim_counts', 'SaveFormat', 'Timeseries', ...
    'Position', [900, 30, 950, 50]);

add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_theta_enc'], ...
    'VariableName', 'sim_theta_enc', 'SaveFormat', 'Timeseries', ...
    'Position', [990, 30, 1040, 50]);

add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_err'], ...
    'VariableName', 'sim_err', 'SaveFormat', 'Timeseries', ...
    'Position', [1050, 100, 1100, 120]);

% 7. Connect Signal Lines
add_line(modelName, 'Duty_Cycle_Input/1', 'Gain_Vdc/1', 'autorouting', 'on');
add_line(modelName, 'Duty_Cycle_Input/1', 'ToWorkspace_d/1', 'autorouting', 'on');

add_line(modelName, 'Gain_Vdc/1', 'Sum_Electrical/1', 'autorouting', 'on');
add_line(modelName, 'Gain_Vdc/1', 'ToWorkspace_Veff/1', 'autorouting', 'on');

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
add_line(modelName, 'Integrator_Position/1', 'Gain_RadToCounts/1', 'autorouting', 'on');
add_line(modelName, 'Integrator_Position/1', 'Sum_Error/2', 'autorouting', 'on');

add_line(modelName, 'Gain_RadToCounts/1', 'Encoder_Quantizer/1', 'autorouting', 'on');
add_line(modelName, 'Encoder_Quantizer/1', 'ToWorkspace_counts/1', 'autorouting', 'on');
add_line(modelName, 'Encoder_Quantizer/1', 'Gain_CountsToRad/1', 'autorouting', 'on');

add_line(modelName, 'Gain_CountsToRad/1', 'ToWorkspace_theta_enc/1', 'autorouting', 'on');
add_line(modelName, 'Gain_CountsToRad/1', 'Sum_Error/1', 'autorouting', 'on');
add_line(modelName, 'Sum_Error/1', 'ToWorkspace_err/1', 'autorouting', 'on');

% 8. Save Step 3 Model
save_system(modelName, modelPath);
disp(['Stage 1 Step 3 model saved successfully to: ' modelPath]);

% 9. Run Simulation Test Case 1: Duty Cycle d = 0.75 (75% Duty Cycle)
disp('Running Simulink Simulation Case 1: Duty Cycle d = 0.75...');
simOut_75 = sim(modelName);

% 10. Run Simulation Test Case 2: Duty Cycle d = 1.0 (100% Duty Cycle)
disp('Running Simulink Simulation Case 2: Duty Cycle d = 1.0...');
set_param([modelName '/Duty_Cycle_Input'], 'After', num2str(d_full));
save_system(modelName, modelPath);
simOut_100 = sim(modelName);

% Revert model input back to d_step (0.75)
set_param([modelName '/Duty_Cycle_Input'], 'After', num2str(d_step));
save_system(modelName, modelPath);

% 11. Run Baseline Checks against Step 1 & Step 2 Models
disp('Running Baseline Protection Check (confirming Step 1 & Step 2 models remain intact)...');
load_system(step1ModelPath);
step1Out = sim(step1ModelName);

% 12. Perform Quantitative Validation (Simulink vs Independent Analytical Predictions)
% Extract raw simulation output data directly from simOut_75 and simOut_100
t_vec = simOut_75.sim_w.Time;
d_vec_75 = simOut_75.sim_d.Data;
Veff_vec_75 = simOut_75.sim_Veff.Data;
i_vec_75 = simOut_75.sim_i.Data;
w_vec_75 = simOut_75.sim_w.Data;
theta_true_75 = simOut_75.sim_theta_true.Data;
counts_vec_75 = simOut_75.sim_counts.Data;
theta_enc_75 = simOut_75.sim_theta_enc.Data;

w_vec_100 = simOut_100.sim_w.Data;
w_vec_step1 = step1Out.sim_w.Data;

% Extract actual simulated steady-state speeds from Simulink output
w_ss_sim_75 = w_vec_75(end);
w_ss_sim_100 = w_vec_100(end);
w_ss_sim_step1 = w_vec_step1(end);

% Calculate independent analytical predictions in MATLAB
w_ss_analytical_100 = (Kt * V_dc - R * TL) / (B * R + Kt * Ke);
w_ss_analytical_75  = (Kt * (d_step * V_dc) - R * TL) / (B * R + Kt * Ke);

% Calculate actual errors between simulation and analytical predictions
err_pct_100 = abs(w_ss_sim_100 - w_ss_analytical_100) / w_ss_analytical_100 * 100;
err_pct_75  = abs(w_ss_sim_75  - w_ss_analytical_75)  / w_ss_analytical_75  * 100;

% Compute linearity ratio from actual simulation outputs
sim_ratio = w_ss_sim_75 / w_ss_sim_100;
analytical_ratio = d_step / d_full;
ratio_err_pct = abs(sim_ratio - analytical_ratio) / analytical_ratio * 100;

disp('====================================================');
disp('STAGE 1 STEP 3 NUMERICAL PROVENANCE & VALIDATION:');
disp('====================================================');

fprintf('1. Full Duty Cycle Test (d = 1.00, V_eff = %.1f V):\n', V_dc * d_full);
fprintf('   Analytical Prediction  : %.6f rad/s (%.2f RPM)\n', w_ss_analytical_100, w_ss_analytical_100 * 30 / pi);
fprintf('   Simulink Output Result : %.6f rad/s (%.2f RPM)\n', w_ss_sim_100, w_ss_sim_100 * 30 / pi);
fprintf('   Step 1 Baseline Output : %.6f rad/s (%.2f RPM)\n', w_ss_sim_step1, w_ss_sim_step1 * 30 / pi);
fprintf('   Calculated Error       : %.8f%%\n', err_pct_100);

fprintf('2. 75%% Duty Cycle Test (d = 0.75, V_eff = %.1f V):\n', V_dc * d_step);
fprintf('   Analytical Prediction  : %.6f rad/s (%.2f RPM)\n', w_ss_analytical_75, w_ss_analytical_75 * 30 / pi);
fprintf('   Simulink Output Result : %.6f rad/s (%.2f RPM)\n', w_ss_sim_75, w_ss_sim_75 * 30 / pi);
fprintf('   Calculated Error       : %.8f%%\n', err_pct_75);

fprintf('3. Actuation Linearity Ratio (w_ss(0.75) / w_ss(1.00)):\n');
fprintf('   Analytical Expected Ratio : %.6f\n', analytical_ratio);
fprintf('   Actual Simulink Ratio    : %.6f\n', sim_ratio);
fprintf('   Calculated Ratio Error   : %.8f%%\n', ratio_err_pct);

fprintf('4. Step 2 Encoder Integration Check under 75%% Actuation:\n');
fprintf('   Final True Position       : %.6f rad\n', theta_true_75(end));
fprintf('   Final Encoder Counts      : %d counts\n', counts_vec_75(end));
fprintf('   Expected Floor Counts     : %d counts\n', floor(theta_true_75(end) / res_rad));

% Assertions
assert(err_pct_100 < 0.05, 'Discrepancy in 100% duty cycle simulation!');
assert(err_pct_75 < 0.05, 'Discrepancy in 75% duty cycle simulation!');
assert(ratio_err_pct < 0.01, 'Discrepancy in PWM linearity scaling!');
disp('   [PASS] All Stage 1 Step 3 validation checks satisfied.');
disp('====================================================');

% 13. Export Raw Simulation Arrays to MAT File for Python Plotting
dataFile = fullfile(resultsDir, 'stage3_data.mat');
save(dataFile, 't_vec', 'd_vec_75', 'Veff_vec_75', 'i_vec_75', 'w_vec_75', ...
     'theta_true_75', 'counts_vec_75', 'theta_enc_75', 'w_vec_100', ...
     'w_ss_analytical_75', 'w_ss_analytical_100', 'w_ss_sim_75', 'w_ss_sim_100');
disp(['Exported raw simulation data to: ' dataFile]);
disp('Stage 1 Step 3 build and simulation completed successfully.');
