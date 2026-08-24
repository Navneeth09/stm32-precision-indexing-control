% =========================================================================
% Stage 1 Step 1 - Model Creation and Simulation Script
% Project 2: STM32 Automated Precision Indexing & Feed Control
% =========================================================================

clear; clc; close all;

% 1. Load Parameters
scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptDir);
run(fullfile(scriptDir, 'params.m'));

% 2. Define Model Name and Directories
modelName = 'stage1_motor_plant';
modelDir = fullfile(projectRoot, 'models');
modelPath = fullfile(modelDir, [modelName '.slx']);
resultsDir = fullfile(projectRoot, 'results', 'stage1');

if ~exist(modelDir, 'dir')
    mkdir(modelDir);
end
if ~exist(resultsDir, 'dir')
    mkdir(resultsDir, 'dir');
end

% 3. Preload Simulink Engine
disp('Preloading Simulink engine...');
load_system('simulink');

% 4. Close system if already loaded/open
if bdIsLoaded(modelName)
    close_system(modelName, 0);
end

% 5. Create new Simulink model
disp('Creating Simulink model structure...');
new_system(modelName);
load_system(modelName);

% Set solver configurations
set_param(modelName, 'SolverType', 'Variable-step');
set_param(modelName, 'Solver', 'ode45');
set_param(modelName, 'StopTime', num2str(t_stop));
set_param(modelName, 'SaveOutput', 'on');
set_param(modelName, 'SignalLogging', 'on');

% 6. Add Blocks to Model
% --- Input: Voltage Step Command ---
add_block('simulink/Sources/Step', [modelName '/Voltage_Input'], ...
    'Time', num2str(t_step), 'Before', '0', 'After', num2str(V_app), ...
    'Position', [50, 100, 80, 130]);

% --- Electrical Dynamics ---
% di/dt = (V - R*i - Ke*w)/L
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

% --- Electromagnetic Torque ---
% Te = Kt * i
add_block('simulink/Math Operations/Gain', [modelName '/Gain_Kt'], ...
    'Gain', 'Kt', ...
    'Position', [340, 100, 380, 130]);

% --- Mechanical Dynamics ---
% dw/dt = (Te - B*w - TL)/J
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

% --- Position Integrator ---
% dtheta/dt = w
add_block('simulink/Continuous/Integrator', [modelName '/Integrator_Position'], ...
    'InitialCondition', '0', ...
    'Position', [640, 100, 670, 130]);

% --- Logging & Scopes ---
add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_V'], ...
    'VariableName', 'sim_V', 'SaveFormat', 'Timeseries', ...
    'Position', [120, 30, 170, 50]);

add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_i'], ...
    'VariableName', 'sim_i', 'SaveFormat', 'Timeseries', ...
    'Position', [320, 30, 370, 50]);

add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_w'], ...
    'VariableName', 'sim_w', 'SaveFormat', 'Timeseries', ...
    'Position', [600, 30, 650, 50]);

add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_theta'], ...
    'VariableName', 'sim_theta', 'SaveFormat', 'Timeseries', ...
    'Position', [700, 30, 750, 50]);

add_block('simulink/Sinks/Scope', [modelName '/Scope_Speed'], ...
    'Position', [610, 170, 640, 200]);

add_block('simulink/Sinks/Scope', [modelName '/Scope_Position'], ...
    'Position', [710, 170, 740, 200]);

% 7. Connect Signal Lines
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
add_line(modelName, 'Integrator_Speed/1', 'Scope_Speed/1', 'autorouting', 'on');

add_line(modelName, 'Integrator_Position/1', 'ToWorkspace_theta/1', 'autorouting', 'on');
add_line(modelName, 'Integrator_Position/1', 'Scope_Position/1', 'autorouting', 'on');

% 8. Save Model
save_system(modelName, modelPath);
disp(['Simulink model successfully saved to: ' modelPath]);

% 9. Run Simulation
disp('Running Simulink simulation...');
simOut = sim(modelName);
disp('Simulation completed successfully.');

% 10. Extract Signals
t_vec = simOut.sim_w.Time;
V_vec = simOut.sim_V.Data;
i_vec = simOut.sim_i.Data;
w_vec = simOut.sim_w.Data;
theta_vec = simOut.sim_theta.Data;

% 11. Perform Validation Checks
disp('====================================================');
disp('VALIDATION CHECKS SUMMARY:');
disp('====================================================');

w_final = w_vec(end);
i_final = i_vec(end);
rel_err_w = abs(w_final - w_ss_theoretical) / w_ss_theoretical * 100;

fprintf('1. Voltage Input Verification:\n');
fprintf('   Applied Voltage Step Amplitude = %.2f V at t = %.3f s\n', V_app, t_step);

fprintf('2. Motor Speed w(t) Verification:\n');
fprintf('   Simulated Steady-State w(t_stop) = %.4f rad/s (%.2f RPM)\n', w_final, w_final * 30 / pi);
fprintf('   Theoretical Steady-State w_ss    = %.4f rad/s (%.2f RPM)\n', w_ss_theoretical, w_ss_theoretical * 30 / pi);
fprintf('   Relative Speed Error             = %.6f%%\n', rel_err_w);

fprintf('3. Armature Current i(t) Verification:\n');
fprintf('   Simulated Steady-State i(t_stop) = %.6f A\n', i_final);
fprintf('   Theoretical Steady-State i_ss    = %.6f A\n', i_ss_theoretical);

% Derivative check dtheta/dt ≈ w
dtheta_dt = gradient(theta_vec, t_vec);
idx_eval = find(t_vec > t_step + 0.005);
mean_deriv_err = mean(abs(dtheta_dt(idx_eval) - w_vec(idx_eval)));
max_deriv_err = max(abs(dtheta_dt(idx_eval) - w_vec(idx_eval)));

fprintf('4. Position Integrator Integrity Check (dtheta/dt vs w):\n');
fprintf('   Mean Absolute Difference |dtheta/dt - w| = %.6e rad/s\n', mean_deriv_err);
fprintf('   Max Absolute Difference  |dtheta/dt - w| = %.6e rad/s\n', max_deriv_err);

assert(rel_err_w < 0.1, 'Speed response discrepancy exceeds 0.1% threshold');
assert(mean_deriv_err < 0.1, 'Position integrator derivative discrepancy detected');
disp('   [PASS] All mathematical plant validation checks satisfied.');
disp('====================================================');

% 12. Save Figures
% Figure 1: Speed vs Time
fig1 = figure('Visible', 'off', 'Position', [100, 100, 800, 500]);
plot(t_vec, w_vec, 'LineWidth', 2, 'Color', [0.8500, 0.3250, 0.0980]);
hold on;
yline(w_ss_theoretical, '--', 'Theoretical \omega_{ss}', 'Color', [0.3, 0.3, 0.3], 'LineWidth', 1.5);
grid on;
xlabel('Time (s)', 'FontSize', 12);
ylabel('Motor Speed \omega (rad/s)', 'FontSize', 12);
title('Stage 1 Step 1: Motor Speed \omega(t) Response to 12V Step Input', 'FontSize', 13);
legend('\omega(t) (Simulink)', '\omega_{ss} (Theoretical)', 'Location', 'southeast');
saveas(fig1, fullfile(resultsDir, 'speed_vs_time.png'));
close(fig1);

% Figure 2: Position vs Time
fig2 = figure('Visible', 'off', 'Position', [100, 100, 800, 500]);
plot(t_vec, theta_vec, 'LineWidth', 2, 'Color', [0, 0.4470, 0.7410]);
grid on;
xlabel('Time (s)', 'FontSize', 12);
ylabel('Motor Position \theta (rad)', 'FontSize', 12);
title('Stage 1 Step 1: Motor Position \theta(t) Response to 12V Step Input', 'FontSize', 13);
legend('\theta(t) (Simulink Integrator Output)', 'Location', 'northwest');
saveas(fig2, fullfile(resultsDir, 'position_vs_time.png'));
close(fig2);

% Figure 3: Full Verification Dashboard
fig3 = figure('Visible', 'off', 'Position', [100, 100, 1000, 750]);

subplot(2,2,1);
plot(t_vec, V_vec, 'LineWidth', 1.8, 'Color', [0.4660, 0.6740, 0.1880]);
grid on; xlabel('Time (s)'); ylabel('Voltage V (V)');
title('Applied Motor Voltage V(t)');

subplot(2,2,2);
plot(t_vec, i_vec, 'LineWidth', 1.8, 'Color', [0.4940, 0.1840, 0.5560]);
grid on; xlabel('Time (s)'); ylabel('Current i (A)');
title('Armature Current i(t)');

subplot(2,2,3);
plot(t_vec, w_vec, 'LineWidth', 1.8, 'Color', [0.8500, 0.3250, 0.0980]);
grid on; xlabel('Time (s)'); ylabel('Speed \omega (rad/s)');
title('Motor Speed \omega(t)');

subplot(2,2,4);
plot(t_vec, theta_vec, 'LineWidth', 1.8, 'Color', [0, 0.4470, 0.7410]);
grid on; xlabel('Time (s)'); ylabel('Position \theta (rad)');
title('Motor Position \theta(t)');

sgtitle('Stage 1 Step 1: DC Motor Plant Mathematical Verification Dashboard', 'FontSize', 15, 'FontWeight', 'bold');
saveas(fig3, fullfile(resultsDir, 'stage1_verification.png'));
close(fig3);

disp(['Saved plot: ' fullfile(resultsDir, 'speed_vs_time.png')]);
disp(['Saved plot: ' fullfile(resultsDir, 'position_vs_time.png')]);
% 13. Export Raw Simulation Data to MAT File
dataFile = fullfile(resultsDir, 'stage1_data.mat');
save(dataFile, 't_vec', 'V_vec', 'i_vec', 'w_vec', 'theta_vec', 'w_ss_theoretical', 'i_ss_theoretical');
disp(['Saved simulation data to: ' dataFile]);
disp('Stage 1 Step 1 build and run completed successfully!');
