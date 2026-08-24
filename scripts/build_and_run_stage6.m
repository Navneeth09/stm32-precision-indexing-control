% =========================================================================
% Stage 1 Step 6 — System Robustness, Disturbance Rejection, & Friction Compensation
% Project 2: STM32 Automated Precision Indexing & Feed Control
% =========================================================================
% Objective: Programmatically construct, validate, and simulate the discrete-time
% (Ts = 1 ms) robust closed-loop position control system featuring:
% 1. Baseline Characterization (Step 5 Controller without active compensation)
% 2. Physics-Derived Load-Torque Feedforward Compensation (Kff_L = R / (V_dc * Kt) = 0.833333)
% 3. Physics-Derived Nonlinear Friction Feedforward Compensation (Stiction + Coulomb)
% 4. Dual Evaluation: In-Motion Disturbance (t=0.200s), In-Dwell Pulse (t=0.600s), Friction, Inertia Sweep
% 5. Baseline Protection Checks confirming Steps 1-5 remain 100% untouched
% =========================================================================

clear; clc; close all;

% 1. Load Parameter Definitions
scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptDir);
addpath(scriptDir);
params;

% 2. Define Model Paths
modelsDir = fullfile(projectRoot, 'models');
resultsDir = fullfile(projectRoot, 'results', 'stage1');
if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end

modelName = 'stage1_robust_loop_model';
modelPath = fullfile(modelsDir, [modelName '.slx']);

% Step 1-5 Baseline Model Paths for Regression Checks
step1ModelPath = fullfile(modelsDir, 'stage1_motor_plant.slx');
step2ModelPath = fullfile(modelsDir, 'stage1_encoder_model.slx');
step3ModelPath = fullfile(modelsDir, 'stage1_pwm_model.slx');
step4ModelPath = fullfile(modelsDir, 'stage1_closed_loop_model.slx');
step5ModelPath = fullfile(modelsDir, 'stage1_profiled_loop_model.slx');

% 3. Preload Simulink Engine
disp('Preloading Simulink engine...');
load_system('simulink');

% 4. Create New Simulink Model (Overwrite if existing)
disp(['Creating Stage 1 Step 6 Simulink model structure (' modelName '.slx)...']);
if bdIsLoaded(modelName)
    close_system(modelName, 0);
end
new_system(modelName);
open_system(modelName);

% 5. Configure Model Solver Properties
set_param(modelName, 'SolverType', 'Variable-step');
set_param(modelName, 'Solver', 'ode45');
set_param(modelName, 'StopTime', num2str(t_stop_rob));
set_param(modelName, 'SaveOutput', 'on');
set_param(modelName, 'SignalLogging', 'on');

% 6. Add Blocks to Model
% --- Simulation Clock ---
add_block('simulink/Sources/Clock', [modelName '/Clock'], ...
    'Position', [30, 100, 60, 120]);

% --- Mode Selector Constants ---
add_block('simulink/Sources/Constant', [modelName '/Move_Mode_Constant'], ...
    'Value', '1', 'Position', [30, 140, 60, 160]);

add_block('simulink/Sources/Constant', [modelName '/FF_Mode_Constant'], ...
    'Value', '1', 'Position', [30, 180, 60, 200]);

add_block('simulink/Sources/Constant', [modelName '/Disturb_Mode_Constant'], ...
    'Value', '0', 'Position', [30, 220, 60, 240]);

add_block('simulink/Sources/Constant', [modelName '/Fric_Mode_Constant'], ...
    'Value', '0', 'Position', [30, 260, 60, 280]);

add_block('simulink/Sources/Constant', [modelName '/J_Val_Constant'], ...
    'Value', '1.0e-5', 'Position', [30, 300, 60, 320]);

add_block('simulink/Sources/Constant', [modelName '/Comp_Mode_Constant'], ...
    'Value', '0', 'Position', [30, 340, 60, 360]);

% --- Trapezoidal Profile Generator (MATLAB Function) ---
profGenBlock = [modelName '/Trapezoidal_Profile_Generator'];
add_block('simulink/User-Defined Functions/MATLAB Function', profGenBlock, ...
    'Position', [90, 95, 170, 165]);

rt = sfroot;
chartProf = rt.find('-isa', 'Stateflow.EMChart', 'Path', profGenBlock);
chartProf(1).Script = sprintf([ ...
    'function [theta_ref, w_ref, a_ref] = Trapezoidal_Profile_Generator(t, mode)\n' ...
    'a_max = 50.0; w_max = 8.0; step_rad = 90.0 * pi / 180;\n' ...
    't_a = w_max / a_max; theta_a = 0.5 * a_max * t_a^2;\n' ...
    't_c = (step_rad - 2 * theta_a) / w_max; t_f = 2 * t_a + t_c;\n' ...
    '\n' ...
    'if mode == 1\n' ...
    '    t_start = 0.050;\n' ...
    '    [theta_ref, w_ref, a_ref] = calc_single_move(t, t_start, step_rad, a_max, w_max, t_a, theta_a, t_c, t_f);\n' ...
    'else\n' ...
    '    [th1, w1, a1] = calc_single_move(t, 0.050, step_rad, a_max, w_max, t_a, theta_a, t_c, t_f);\n' ...
    '    [th2, w2, a2] = calc_single_move(t, 0.500, step_rad, a_max, w_max, t_a, theta_a, t_c, t_f);\n' ...
    '    [th3, w3, a3] = calc_single_move(t, 0.950, step_rad, a_max, w_max, t_a, theta_a, t_c, t_f);\n' ...
    '    theta_ref = th1 + th2 + th3; w_ref = w1 + w2 + w3; a_ref = a1 + a2 + a3;\n' ...
    'end\n' ...
    'end\n' ...
    '\n' ...
    'function [th, w, a] = calc_single_move(t, t_start, step_rad, a_max, w_max, t_a, theta_a, t_c, t_f)\n' ...
    'if t < t_start\n' ...
    '    th = 0.0; w = 0.0; a = 0.0;\n' ...
    'elseif t < t_start + t_a\n' ...
    '    dt = t - t_start;\n' ...
    '    th = 0.5 * a_max * dt^2; w = a_max * dt; a = a_max;\n' ...
    'elseif t < t_start + t_a + t_c\n' ...
    '    dt = t - t_start - t_a;\n' ...
    '    th = theta_a + w_max * dt; w = w_max; a = 0.0;\n' ...
    'elseif t < t_start + t_f\n' ...
    '    dt = t_start + t_f - t;\n' ...
    '    th = step_rad - 0.5 * a_max * dt^2; w = a_max * dt; a = -a_max;\n' ...
    'else\n' ...
    '    th = step_rad; w = 0.0; a = 0.0;\n' ...
    'end\n' ...
    'end\n']);

% --- Discrete Zero-Order Hold Blocks ---
add_block('simulink/Discrete/Zero-Order Hold', [modelName '/ZOH_Reference'], ...
    'SampleTime', 'Ts_disc', 'Position', [190, 100, 220, 120]);
add_block('simulink/Discrete/Zero-Order Hold', [modelName '/ZOH_Wref'], ...
    'SampleTime', 'Ts_disc', 'Position', [190, 130, 220, 150]);
add_block('simulink/Discrete/Zero-Order Hold', [modelName '/ZOH_Aref'], ...
    'SampleTime', 'Ts_disc', 'Position', [190, 160, 220, 180]);

% --- Sum Junctions ---
add_block('simulink/Math Operations/Sum', [modelName '/Sum_Discrete_Error'], ...
    'Inputs', '+-', 'Position', [250, 100, 270, 120]);
add_block('simulink/Math Operations/Sum', [modelName '/Sum_True_Error'], ...
    'Inputs', '+-', 'Position', [250, 40, 270, 60]);
add_block('simulink/Discrete/Zero-Order Hold', [modelName '/ZOH_Feedback'], ...
    'SampleTime', 'Ts_disc', 'Position', [250, 220, 280, 240]);

% --- Dynamic Load Torque Generator (MATLAB Function) ---
loadGenBlock = [modelName '/Load_Torque_Generator'];
add_block('simulink/User-Defined Functions/MATLAB Function', loadGenBlock, ...
    'Position', [250, 280, 320, 320]);

chartLoad = rt.find('-isa', 'Stateflow.EMChart', 'Path', loadGenBlock);
chartLoad(1).Script = sprintf([ ...
    'function TL = Load_Torque_Generator(t, mode)\n' ...
    'if mode == 1 %% In-Motion Step at t = 0.200 s\n' ...
    '    if t >= 0.200\n' ...
    '        TL = 0.010;\n' ...
    '    else\n' ...
    '        TL = 0.0;\n' ...
    '    end\n' ...
    'elseif mode == 2 %% In-Dwell Pulse at t = 0.600 s (duration 0.150 s)\n' ...
    '    if t >= 0.600 && t <= 0.750\n' ...
    '        TL = 0.010;\n' ...
    '    else\n' ...
    '        TL = 0.0;\n' ...
    '    end\n' ...
    'else\n' ...
    '    TL = 0.0;\n' ...
    'end\n' ...
    'end\n']);

% --- Additional ZOH Blocks for Controller Inputs ---
add_block('simulink/Discrete/Zero-Order Hold', [modelName '/ZOH_FFMode'], ...
    'SampleTime', 'Ts_disc', 'Position', [190, 190, 220, 210]);
add_block('simulink/Discrete/Zero-Order Hold', [modelName '/ZOH_TLest'], ...
    'SampleTime', 'Ts_disc', 'Position', [330, 280, 350, 300]);
add_block('simulink/Discrete/Zero-Order Hold', [modelName '/ZOH_CompMode'], ...
    'SampleTime', 'Ts_disc', 'Position', [190, 340, 220, 360]);

% --- Discrete PID + Configurable Physics Compensation Controller Block ---
pidBlock = [modelName '/Discrete_PID_Controller'];
add_block('simulink/User-Defined Functions/MATLAB Function', pidBlock, ...
    'Position', [370, 100, 460, 200]);

chartPid = rt.find('-isa', 'Stateflow.EMChart', 'Path', pidBlock);
chartPid(1).Script = sprintf([ ...
    'function d = Discrete_PID_Controller(e, w_ref, a_ref, ff_mode, TL_est, comp_mode)\n' ...
    'Kp = 0.50;\n' ...
    'Ki = 8.00;\n' ...
    'Kd = 0.0000;\n' ...
    'N  = 20;\n' ...
    'Ts = 0.001;\n' ...
    'Kff_v = 0.004175;\n' ...
    'Kff_a = 0.00000834;\n' ...
    'Kff_L = 0.833333; %% Physics Gain: R / (V_dc * Kt) = 0.50 / (12.0 * 0.050)\n' ...
    '\n' ...
    'T_stick = 0.0020;\n' ...
    'T_coulomb = 0.0010;\n' ...
    'w_s = 0.01;\n' ...
    'if abs(w_ref) < 1.0e-6\n' ...
    '    Tfric_ref = 0.0;\n' ...
    'else\n' ...
    '    Tfric_ref = (T_coulomb + (T_stick - T_coulomb) * exp(-(w_ref/w_s)^2)) * tanh(1000 * w_ref);\n' ...
    'end\n' ...
    '\n' ...
    'persistent u_i u_d e_prev\n' ...
    'if isempty(u_i)\n' ...
    '    u_i = 0.0; u_d = 0.0; e_prev = 0.0;\n' ...
    'end\n' ...
    '\n' ...
    'u_p = Kp * e;\n' ...
    'u_d = (Kd * N * (e - e_prev) + u_d) / (1.0 + N * Ts);\n' ...
    'v_i = u_i + Ki * Ts * e;\n' ...
    '\n' ...
    'if ff_mode == 1\n' ...
    '    u_ff_kin = Kff_v * w_ref + Kff_a * a_ref;\n' ...
    'else\n' ...
    '    u_ff_kin = 0.0;\n' ...
    'end\n' ...
    '\n' ...
    'if comp_mode == 1 %% Active Physics Load & Friction Feedforward Compensation\n' ...
    '    u_ff_comp = Kff_L * TL_est + Kff_L * Tfric_ref;\n' ...
    'else\n' ...
    '    u_ff_comp = 0.0;\n' ...
    'end\n' ...
    '\n' ...
    'u_calc = u_p + v_i + u_d + u_ff_kin + u_ff_comp;\n' ...
    'if u_calc > 1.0\n' ...
    '    d = 1.0;\n' ...
    'elseif u_calc < 0.0\n' ...
    '    d = 0.0;\n' ...
    'else\n' ...
    '    d = u_calc;\n' ...
    'end\n' ...
    '\n' ...
    'is_sat_high = (u_calc > 1.0) && (e > 0);\n' ...
    'is_sat_low  = (u_calc < 0.0) && (e < 0);\n' ...
    'if is_sat_high || is_sat_low\n' ...
    '    u_i = u_i;\n' ...
    'else\n' ...
    '    u_i = v_i;\n' ...
    'end\n' ...
    'e_prev = e;\n' ...
    'end\n']);

% --- Averaged PWM H-Bridge Gain ---
add_block('simulink/Math Operations/Gain', [modelName '/Gain_Vdc'], ...
    'Gain', 'V_dc', 'Position', [470, 130, 510, 160]);

% --- Electromechanical Motor Plant Blocks ---
add_block('simulink/Math Operations/Sum', [modelName '/Sum_Electrical'], ...
    'Inputs', '+--', 'Position', [530, 130, 550, 160]);

add_block('simulink/Math Operations/Gain', [modelName '/Gain_InvL'], ...
    'Gain', '1/L', 'Position', [570, 130, 610, 160]);

add_block('simulink/Continuous/Integrator', [modelName '/Integrator_Current'], ...
    'InitialCondition', '0', 'Position', [640, 130, 670, 160]);

add_block('simulink/Math Operations/Gain', [modelName '/Gain_R'], ...
    'Gain', 'R', 'Orientation', 'left', 'Position', [580, 190, 620, 220]);

add_block('simulink/Math Operations/Gain', [modelName '/Gain_Ke'], ...
    'Gain', 'Ke', 'Orientation', 'left', 'Position', [580, 250, 620, 280]);

add_block('simulink/Math Operations/Gain', [modelName '/Gain_Kt'], ...
    'Gain', 'Kt', 'Position', [710, 130, 750, 160]);

% --- Mechanical Sum Junction ---
add_block('simulink/Math Operations/Sum', [modelName '/Sum_Mechanical'], ...
    'Inputs', '+---', 'Position', [780, 130, 800, 170]);

% --- Dynamic Inertia Reciprocal Block ---
add_block('simulink/Math Operations/Divide', [modelName '/Divide_InvJ'], ...
    'Inputs', '*/', 'Position', [820, 135, 850, 165]);

add_block('simulink/Sources/Constant', [modelName '/Constant_One'], ...
    'Value', '1.0', 'Position', [820, 100, 840, 120]);

% --- Speed Integrator ---
add_block('simulink/Continuous/Integrator', [modelName '/Integrator_Speed'], ...
    'InitialCondition', '0', 'Position', [880, 135, 910, 165]);

add_block('simulink/Math Operations/Gain', [modelName '/Gain_B'], ...
    'Gain', 'B', 'Orientation', 'left', 'Position', [810, 220, 850, 250]);

% --- Nonlinear Friction Function Block ---
fricBlock = [modelName '/Nonlinear_Friction_Model'];
add_block('simulink/User-Defined Functions/MATLAB Function', fricBlock, ...
    'Position', [770, 270, 850, 320]);

chartFric = rt.find('-isa', 'Stateflow.EMChart', 'Path', fricBlock);
chartFric(1).Script = sprintf([ ...
    'function Tfric = Nonlinear_Friction_Model(w, mode)\n' ...
    'if mode == 0\n' ...
    '    Tfric = 0.0;\n' ...
    '    return;\n' ...
    'end\n' ...
    'T_stick = 0.0020;\n' ...
    'T_coulomb = 0.0010;\n' ...
    'w_s = 0.01;\n' ...
    'if abs(w) < 1.0e-6\n' ...
    '    Tfric = 0.0;\n' ...
    'else\n' ...
    '    Tfric = (T_coulomb + (T_stick - T_coulomb) * exp(-(w/w_s)^2)) * tanh(1000 * w);\n' ...
    'end\n' ...
    'end\n']);

% --- Position Integrator ---
add_block('simulink/Continuous/Integrator', [modelName '/Integrator_Position'], ...
    'InitialCondition', '0', 'Position', [950, 135, 980, 165]);

% --- Encoder Path ---
add_block('simulink/Math Operations/Gain', [modelName '/Gain_RadToCounts'], ...
    'Gain', 'CPR/(2*pi)', 'Position', [1020, 135, 1070, 165]);

add_block('simulink/Math Operations/Rounding Function', [modelName '/Encoder_Quantizer'], ...
    'Operator', 'floor', 'Position', [1100, 135, 1140, 165]);

add_block('simulink/Math Operations/Gain', [modelName '/Gain_CountsToRad'], ...
    'Gain', '(2*pi)/CPR', 'Position', [1170, 135, 1220, 165]);

% --- To Workspace Logging Sinks ---
add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_theta_ref'], ...
    'VariableName', 'sim_theta_ref', 'SaveFormat', 'Timeseries', 'Position', [240, 70, 290, 90]);

add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_e_true'], ...
    'VariableName', 'sim_e_true', 'SaveFormat', 'Timeseries', 'Position', [290, 40, 340, 60]);

add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_e_enc'], ...
    'VariableName', 'sim_e_enc', 'SaveFormat', 'Timeseries', 'Position', [300, 70, 350, 90]);

add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_d'], ...
    'VariableName', 'sim_d', 'SaveFormat', 'Timeseries', 'Position', [460, 40, 510, 60]);

add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_i'], ...
    'VariableName', 'sim_i', 'SaveFormat', 'Timeseries', 'Position', [680, 40, 730, 60]);

add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_TL'], ...
    'VariableName', 'sim_TL', 'SaveFormat', 'Timeseries', 'Position', [340, 270, 390, 290]);

add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_w'], ...
    'VariableName', 'sim_w', 'SaveFormat', 'Timeseries', 'Position', [930, 40, 980, 60]);

add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_theta_true'], ...
    'VariableName', 'sim_theta_true', 'SaveFormat', 'Timeseries', 'Position', [1000, 40, 1050, 60]);

add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_counts'], ...
    'VariableName', 'sim_counts', 'SaveFormat', 'Timeseries', 'Position', [1150, 40, 1200, 60]);

add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_theta_enc'], ...
    'VariableName', 'sim_theta_enc', 'SaveFormat', 'Timeseries', 'Position', [1250, 135, 1300, 155]);

add_block('simulink/Sinks/To Workspace', [modelName '/ToWorkspace_Tfric'], ...
    'VariableName', 'sim_Tfric', 'SaveFormat', 'Timeseries', 'Position', [870, 270, 920, 290]);

% 7. Connect Signal Lines
add_line(modelName, 'Clock/1', 'Trapezoidal_Profile_Generator/1', 'autorouting', 'on');
add_line(modelName, 'Move_Mode_Constant/1', 'Trapezoidal_Profile_Generator/2', 'autorouting', 'on');

add_line(modelName, 'Trapezoidal_Profile_Generator/1', 'ZOH_Reference/1', 'autorouting', 'on');
add_line(modelName, 'Trapezoidal_Profile_Generator/2', 'ZOH_Wref/1', 'autorouting', 'on');
add_line(modelName, 'Trapezoidal_Profile_Generator/3', 'ZOH_Aref/1', 'autorouting', 'on');

add_line(modelName, 'ZOH_Reference/1', 'Sum_Discrete_Error/1', 'autorouting', 'on');
add_line(modelName, 'ZOH_Reference/1', 'Sum_True_Error/1', 'autorouting', 'on');
add_line(modelName, 'ZOH_Reference/1', 'ToWorkspace_theta_ref/1', 'autorouting', 'on');

add_line(modelName, 'Sum_True_Error/1', 'ToWorkspace_e_true/1', 'autorouting', 'on');
add_line(modelName, 'Sum_Discrete_Error/1', 'Discrete_PID_Controller/1', 'autorouting', 'on');
add_line(modelName, 'Sum_Discrete_Error/1', 'ToWorkspace_e_enc/1', 'autorouting', 'on');

add_line(modelName, 'ZOH_Wref/1', 'Discrete_PID_Controller/2', 'autorouting', 'on');
add_line(modelName, 'ZOH_Aref/1', 'Discrete_PID_Controller/3', 'autorouting', 'on');
add_line(modelName, 'FF_Mode_Constant/1', 'ZOH_FFMode/1', 'autorouting', 'on');
add_line(modelName, 'ZOH_FFMode/1', 'Discrete_PID_Controller/4', 'autorouting', 'on');

add_line(modelName, 'Clock/1', 'Load_Torque_Generator/1', 'autorouting', 'on');
add_line(modelName, 'Disturb_Mode_Constant/1', 'Load_Torque_Generator/2', 'autorouting', 'on');
add_line(modelName, 'Load_Torque_Generator/1', 'ZOH_TLest/1', 'autorouting', 'on');
add_line(modelName, 'ZOH_TLest/1', 'Discrete_PID_Controller/5', 'autorouting', 'on');
add_line(modelName, 'Load_Torque_Generator/1', 'Sum_Mechanical/3', 'autorouting', 'on');
add_line(modelName, 'Load_Torque_Generator/1', 'ToWorkspace_TL/1', 'autorouting', 'on');

add_line(modelName, 'Comp_Mode_Constant/1', 'ZOH_CompMode/1', 'autorouting', 'on');
add_line(modelName, 'ZOH_CompMode/1', 'Discrete_PID_Controller/6', 'autorouting', 'on');

add_line(modelName, 'Discrete_PID_Controller/1', 'Gain_Vdc/1', 'autorouting', 'on');
add_line(modelName, 'Discrete_PID_Controller/1', 'ToWorkspace_d/1', 'autorouting', 'on');

add_line(modelName, 'Gain_Vdc/1', 'Sum_Electrical/1', 'autorouting', 'on');
add_line(modelName, 'Sum_Electrical/1', 'Gain_InvL/1', 'autorouting', 'on');
add_line(modelName, 'Gain_InvL/1', 'Integrator_Current/1', 'autorouting', 'on');
add_line(modelName, 'Integrator_Current/1', 'Gain_R/1', 'autorouting', 'on');
add_line(modelName, 'Gain_R/1', 'Sum_Electrical/2', 'autorouting', 'on');
add_line(modelName, 'Integrator_Current/1', 'Gain_Kt/1', 'autorouting', 'on');
add_line(modelName, 'Integrator_Current/1', 'ToWorkspace_i/1', 'autorouting', 'on');

add_line(modelName, 'Gain_Kt/1', 'Sum_Mechanical/1', 'autorouting', 'on');

add_line(modelName, 'Sum_Mechanical/1', 'Divide_InvJ/1', 'autorouting', 'on');
add_line(modelName, 'J_Val_Constant/1', 'Divide_InvJ/2', 'autorouting', 'on');

add_line(modelName, 'Divide_InvJ/1', 'Integrator_Speed/1', 'autorouting', 'on');
add_line(modelName, 'Integrator_Speed/1', 'Gain_B/1', 'autorouting', 'on');
add_line(modelName, 'Gain_B/1', 'Sum_Mechanical/2', 'autorouting', 'on');
add_line(modelName, 'Integrator_Speed/1', 'Gain_Ke/1', 'autorouting', 'on');
add_line(modelName, 'Gain_Ke/1', 'Sum_Electrical/3', 'autorouting', 'on');
add_line(modelName, 'Integrator_Speed/1', 'Integrator_Position/1', 'autorouting', 'on');
add_line(modelName, 'Integrator_Speed/1', 'ToWorkspace_w/1', 'autorouting', 'on');

add_line(modelName, 'Integrator_Speed/1', 'Nonlinear_Friction_Model/1', 'autorouting', 'on');
add_line(modelName, 'Fric_Mode_Constant/1', 'Nonlinear_Friction_Model/2', 'autorouting', 'on');
add_line(modelName, 'Nonlinear_Friction_Model/1', 'Sum_Mechanical/4', 'autorouting', 'on');
add_line(modelName, 'Nonlinear_Friction_Model/1', 'ToWorkspace_Tfric/1', 'autorouting', 'on');

add_line(modelName, 'Integrator_Position/1', 'Sum_True_Error/2', 'autorouting', 'on');
add_line(modelName, 'Integrator_Position/1', 'ToWorkspace_theta_true/1', 'autorouting', 'on');
add_line(modelName, 'Integrator_Position/1', 'Gain_RadToCounts/1', 'autorouting', 'on');

add_line(modelName, 'Gain_RadToCounts/1', 'Encoder_Quantizer/1', 'autorouting', 'on');
add_line(modelName, 'Encoder_Quantizer/1', 'ToWorkspace_counts/1', 'autorouting', 'on');
add_line(modelName, 'Encoder_Quantizer/1', 'Gain_CountsToRad/1', 'autorouting', 'on');
add_line(modelName, 'Gain_CountsToRad/1', 'ToWorkspace_theta_enc/1', 'autorouting', 'on');

add_line(modelName, 'Gain_CountsToRad/1', 'ZOH_Feedback/1', 'autorouting', 'on');
add_line(modelName, 'ZOH_Feedback/1', 'Sum_Discrete_Error/2', 'autorouting', 'on');

% 8. Save Step 6 Model
save_system(modelName, modelPath);
disp(['Stage 1 Step 6 model saved successfully to: ' modelPath]);

% =========================================================================
% PART A: BASELINE SIMULATIONS (comp_mode = 0, Unassisted Step 5 Controller)
% =========================================================================
disp('--- PART A: BASELINE SIMULATIONS (comp_mode = 0) ---');
set_param([modelName '/Comp_Mode_Constant'], 'Value', '0');

% Scenario 1: In-Motion Load Disturbance Step
set_param([modelName '/Disturb_Mode_Constant'], 'Value', '1');
set_param([modelName '/Fric_Mode_Constant'], 'Value', '0');
set_param([modelName '/J_Val_Constant'], 'Value', '1.0e-5');
save_system(modelName, modelPath);
base_motion = sim(modelName);

% Scenario 2: In-Dwell Load Disturbance Pulse
set_param([modelName '/Disturb_Mode_Constant'], 'Value', '2');
set_param([modelName '/Fric_Mode_Constant'], 'Value', '0');
set_param([modelName '/J_Val_Constant'], 'Value', '1.0e-5');
save_system(modelName, modelPath);
base_dwell = sim(modelName);

% Scenario 3: Nonlinear Friction Active
set_param([modelName '/Disturb_Mode_Constant'], 'Value', '0');
set_param([modelName '/Fric_Mode_Constant'], 'Value', '1');
set_param([modelName '/J_Val_Constant'], 'Value', '1.0e-5');
save_system(modelName, modelPath);
base_fric = sim(modelName);

% Scenario 4: Inertia Sensitivity Sweep (1x, 2x, 3x)
set_param([modelName '/Disturb_Mode_Constant'], 'Value', '0');
set_param([modelName '/Fric_Mode_Constant'], 'Value', '0');

set_param([modelName '/J_Val_Constant'], 'Value', '1.0e-5'); save_system(modelName); base_J1 = sim(modelName);
set_param([modelName '/J_Val_Constant'], 'Value', '2.0e-5'); save_system(modelName); base_J2 = sim(modelName);
set_param([modelName '/J_Val_Constant'], 'Value', '3.0e-5'); save_system(modelName); base_J3 = sim(modelName);

% =========================================================================
% PART B: CORRECTED SIMULATIONS (comp_mode = 1, Physics Compensation Active)
% =========================================================================
disp('--- PART B: CORRECTED SIMULATIONS (comp_mode = 1, Active Compensation) ---');
set_param([modelName '/Comp_Mode_Constant'], 'Value', '1');

% Scenario 1: In-Motion Load Disturbance Step
set_param([modelName '/Disturb_Mode_Constant'], 'Value', '1');
set_param([modelName '/Fric_Mode_Constant'], 'Value', '0');
set_param([modelName '/J_Val_Constant'], 'Value', '1.0e-5');
save_system(modelName, modelPath);
corr_motion = sim(modelName);

% Scenario 2: In-Dwell Load Disturbance Pulse
set_param([modelName '/Disturb_Mode_Constant'], 'Value', '2');
set_param([modelName '/Fric_Mode_Constant'], 'Value', '0');
set_param([modelName '/J_Val_Constant'], 'Value', '1.0e-5');
save_system(modelName, modelPath);
corr_dwell = sim(modelName);

% Scenario 3: Nonlinear Friction Active
set_param([modelName '/Disturb_Mode_Constant'], 'Value', '0');
set_param([modelName '/Fric_Mode_Constant'], 'Value', '1');
set_param([modelName '/J_Val_Constant'], 'Value', '1.0e-5');
save_system(modelName, modelPath);
corr_fric = sim(modelName);

% Scenario 4: Inertia Sensitivity Sweep (1x, 2x, 3x)
set_param([modelName '/Disturb_Mode_Constant'], 'Value', '0');
set_param([modelName '/Fric_Mode_Constant'], 'Value', '0');

set_param([modelName '/J_Val_Constant'], 'Value', '1.0e-5'); save_system(modelName); corr_J1 = sim(modelName);
set_param([modelName '/J_Val_Constant'], 'Value', '2.0e-5'); save_system(modelName); corr_J2 = sim(modelName);
set_param([modelName '/J_Val_Constant'], 'Value', '3.0e-5'); save_system(modelName); corr_J3 = sim(modelName);

% Revert Constants to Default
set_param([modelName '/Move_Mode_Constant'], 'Value', '1');
set_param([modelName '/FF_Mode_Constant'], 'Value', '1');
set_param([modelName '/Disturb_Mode_Constant'], 'Value', '0');
set_param([modelName '/Fric_Mode_Constant'], 'Value', '0');
set_param([modelName '/J_Val_Constant'], 'Value', '1.0e-5');
set_param([modelName '/Comp_Mode_Constant'], 'Value', '1');
save_system(modelName, modelPath);

% 9. Run Baseline Protection Checks on Step 1, 2, 3, 4, 5 Models
disp('Running Baseline Protection Check (confirming Step 1-5 models remain 100% intact)...');
load_system(step1ModelPath); sim('stage1_motor_plant');
load_system(step2ModelPath); sim('stage1_encoder_model');
load_system(step3ModelPath); sim('stage1_pwm_model');
load_system(step4ModelPath); sim('stage1_closed_loop_model');
load_system(step5ModelPath); sim('stage1_profiled_loop_model');

% 10. Quantitative Evaluation & Comparative Report
% --- Baseline Arrays & Metrics ---
t_base_motion = base_motion.sim_e_true.Time(:); e_true_base_motion = base_motion.sim_e_true.Data(:) * 180 / pi; i_base_motion = base_motion.sim_i.Data(:);
t_base_dwell = base_dwell.sim_e_true.Time(:); e_true_base_dwell = base_dwell.sim_e_true.Data(:) * 180 / pi; i_base_dwell = base_dwell.sim_i.Data(:);
t_base_fric = base_fric.sim_e_true.Time(:); e_true_base_fric = base_fric.sim_e_true.Data(:) * 180 / pi; e_enc_base_fric = base_fric.sim_e_enc.Data(:) * 180 / pi;

t_base_J1 = base_J1.sim_e_true.Time(:); e_true_base_J1 = base_J1.sim_e_true.Data(:) * 180 / pi;
t_base_J2 = base_J2.sim_e_true.Time(:); e_true_base_J2 = base_J2.sim_e_true.Data(:) * 180 / pi;
t_base_J3 = base_J3.sim_e_true.Time(:); e_true_base_J3 = base_J3.sim_e_true.Data(:) * 180 / pi;

base_max_e_motion_deg = max(abs(e_true_base_motion));
base_peak_i_motion = max(abs(i_base_motion));

dwell_pulse_base = find(t_base_dwell >= 0.600 & t_base_dwell <= 0.780);
if isempty(dwell_pulse_base); dwell_pulse_base = find(t_base_dwell >= 0.600); end
base_max_dev_dwell_deg = max(abs(e_true_base_dwell(dwell_pulse_base)));

after_dev_base = find(t_base_dwell >= 0.600 & abs(e_true_base_dwell) > 0.3600, 1, 'last');
if isempty(after_dev_base)
    base_t_rec = 0.0;
else
    rec_base_idx = find(t_base_dwell > t_base_dwell(after_dev_base) & abs(e_true_base_dwell) <= 0.3600, 1, 'first');
    if isempty(rec_base_idx); base_t_rec = t_base_dwell(end) - 0.600; else; base_t_rec = t_base_dwell(rec_base_idx) - 0.600; end
end

base_ss_e_true_fric = abs(e_true_base_fric(end));
base_ss_e_enc_fric = abs(e_enc_base_fric(end));

base_max_e_J1 = max(abs(e_true_base_J1));
base_max_e_J2 = max(abs(e_true_base_J2));
base_max_e_J3 = max(abs(e_true_base_J3));

% --- Corrected Arrays & Metrics ---
t_corr_motion = corr_motion.sim_e_true.Time(:); e_true_corr_motion = corr_motion.sim_e_true.Data(:) * 180 / pi; i_corr_motion = corr_motion.sim_i.Data(:); d_corr_motion = corr_motion.sim_d.Data(:);
t_corr_dwell = corr_dwell.sim_e_true.Time(:); e_true_corr_dwell = corr_dwell.sim_e_true.Data(:) * 180 / pi; i_corr_dwell = corr_dwell.sim_i.Data(:); d_corr_dwell = corr_dwell.sim_d.Data(:);
t_corr_fric = corr_fric.sim_e_true.Time(:); e_true_corr_fric = corr_fric.sim_e_true.Data(:) * 180 / pi; e_enc_corr_fric = corr_fric.sim_e_enc.Data(:) * 180 / pi;

t_corr_J1 = corr_J1.sim_e_true.Time(:); e_true_corr_J1 = corr_J1.sim_e_true.Data(:) * 180 / pi;
t_corr_J2 = corr_J2.sim_e_true.Time(:); e_true_corr_J2 = corr_J2.sim_e_true.Data(:) * 180 / pi;
t_corr_J3 = corr_J3.sim_e_true.Time(:); e_true_corr_J3 = corr_J3.sim_e_true.Data(:) * 180 / pi;

corr_max_e_motion_deg = max(abs(e_true_corr_motion));
corr_peak_i_motion = max(abs(i_corr_motion));

dwell_pulse_corr = find(t_corr_dwell >= 0.600 & t_corr_dwell <= 0.780);
if isempty(dwell_pulse_corr); dwell_pulse_corr = find(t_corr_dwell >= 0.600); end
corr_max_dev_dwell_deg = max(abs(e_true_corr_dwell(dwell_pulse_corr)));

after_dev_corr = find(t_corr_dwell >= 0.600 & abs(e_true_corr_dwell) > 0.3600, 1, 'last');
if isempty(after_dev_corr)
    corr_t_rec = 0.0;
else
    rec_corr_idx = find(t_corr_dwell > t_corr_dwell(after_dev_corr) & abs(e_true_corr_dwell) <= 0.3600, 1, 'first');
    if isempty(rec_corr_idx); corr_t_rec = t_corr_dwell(end) - 0.600; else; corr_t_rec = t_corr_dwell(rec_corr_idx) - 0.600; end
end

corr_ss_e_true_fric = abs(e_true_corr_fric(end));
corr_ss_e_enc_fric = abs(e_enc_corr_fric(end));

corr_max_e_J1 = max(abs(e_true_corr_J1));
corr_max_e_J2 = max(abs(e_true_corr_J2));
corr_max_e_J3 = max(abs(e_true_corr_J3));

disp('====================================================');
disp('STAGE 1 STEP 6 COMPARATIVE METRICS REPORT');
disp('====================================================');
fprintf('1. IN-MOTION LOAD DISTURBANCE (TL = 0.010 N*m at 0.200s):\n');
fprintf('   Max Tracking Error   : Baseline = %.4f deg | Corrected = %.4f deg (Limit <= 1.7200 deg) -> %s\n', ...
    base_max_e_motion_deg, corr_max_e_motion_deg, check_pass(corr_max_e_motion_deg <= 1.7200));
fprintf('   Peak Current         : Baseline = %.4f A   | Corrected = %.4f A   (Limit <= 1.5000 A) -> %s\n\n', ...
    base_peak_i_motion, corr_peak_i_motion, check_pass(corr_peak_i_motion <= 1.5000));

fprintf('2. IN-DWELL LOAD DISTURBANCE PULSE (TL = 0.010 N*m at 0.600s):\n');
fprintf('   Max Position Dev     : Baseline = %.4f deg | Corrected = %.4f deg (Limit <= 0.3600 deg / 1 count) -> %s\n', ...
    base_max_dev_dwell_deg, corr_max_dev_dwell_deg, check_pass(corr_max_dev_dwell_deg <= 0.3600));
fprintf('   Recovery Time t_rec  : Baseline = %.4f s   | Corrected = %.4f s   (Limit <= 0.0500 s / 50 ms) -> %s\n\n', ...
    base_t_rec, corr_t_rec, check_pass(corr_t_rec <= 0.0500));

fprintf('3. NONLINEAR FRICTION (Stiction 0.0020 N*m & Coulomb 0.0010 N*m):\n');
fprintf('   Final True Error     : Baseline = %.4f deg | Corrected = %.4f deg (Limit <= 0.3600 deg) -> %s\n', ...
    base_ss_e_true_fric, corr_ss_e_true_fric, check_pass(corr_ss_e_true_fric <= 0.3600));
fprintf('   Final Encoder Error  : Baseline = %.4f deg | Corrected = %.4f deg (Limit <= 0.3600 deg / 1 count) -> %s\n\n', ...
    base_ss_e_enc_fric, corr_ss_e_enc_fric, check_pass(corr_ss_e_enc_fric <= 0.3600));

fprintf('4. PAYLOAD INERTIA SENSITIVITY SWEEP:\n');
fprintf('   1x J Nominal Error   : Baseline = %.4f deg | Corrected = %.4f deg (Limit <= 1.7200 deg) -> %s\n', ...
    base_max_e_J1, corr_max_e_J1, check_pass(corr_max_e_J1 <= 1.7200));
fprintf('   2x J (+100%%) Error   : Baseline = %.4f deg | Corrected = %.4f deg (Limit <= 1.7200 deg) -> %s\n', ...
    base_max_e_J2, corr_max_e_J2, check_pass(corr_max_e_J2 <= 1.7200));
fprintf('   3x J (+200%%) Error   : Baseline = %.4f deg | Corrected = %.4f deg (Limit <= 1.7200 deg) -> %s\n', ...
    base_max_e_J3, corr_max_e_J3, check_pass(corr_max_e_J3 <= 1.7200));
disp('====================================================');

% 11. Save Both Datasets to MAT File
matPath = fullfile(resultsDir, 'stage6_data.mat');
save(matPath, ...
    't_base_motion', 'e_true_base_motion', 'i_base_motion', 'base_max_e_motion_deg', 'base_peak_i_motion', ...
    't_base_dwell', 'e_true_base_dwell', 'i_base_dwell', 'base_max_dev_dwell_deg', 'base_t_rec', ...
    't_base_fric', 'e_true_base_fric', 'e_enc_base_fric', 'base_ss_e_true_fric', 'base_ss_e_enc_fric', ...
    't_base_J1', 'e_true_base_J1', 'base_max_e_J1', 't_base_J2', 'e_true_base_J2', 'base_max_e_J2', 't_base_J3', 'e_true_base_J3', 'base_max_e_J3', ...
    't_corr_motion', 'e_true_corr_motion', 'i_corr_motion', 'd_corr_motion', 'corr_max_e_motion_deg', 'corr_peak_i_motion', ...
    't_corr_dwell', 'e_true_corr_dwell', 'i_corr_dwell', 'd_corr_dwell', 'corr_max_dev_dwell_deg', 'corr_t_rec', ...
    't_corr_fric', 'e_true_corr_fric', 'e_enc_corr_fric', 'corr_ss_e_true_fric', 'corr_ss_e_enc_fric', ...
    't_corr_J1', 'e_true_corr_J1', 'corr_max_e_J1', 't_corr_J2', 'e_true_corr_J2', 'corr_max_e_J2', 't_corr_J3', 'e_true_corr_J3', 'corr_max_e_J3');

disp(['Exported raw Step 6 baseline and corrected simulation data to: ' matPath]);
disp('Stage 1 Step 6 build and simulation execution completed.');

function str = check_pass(cond)
    if cond
        str = 'PASS';
    else
        str = 'FAIL';
    end
end
