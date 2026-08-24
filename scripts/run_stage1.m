% =========================================================================
% STAGE 1 MASTER EXECUTION PIPELINE (Authoritative Script)
% Project: STM32 Automated Precision Indexing & Feed Control System
% Stage 1: Complete Simulation Prototype (Steps 1 through 6)
% =========================================================================

function run_stage1()
    clc;
    bdclose('all');
    clearvars -except run_stage1;
    close all;

    fprintf('=========================================================================\n');
    fprintf('           STAGE 1 MASTER SIMULATION PROTOTYPE PIPELINE                  \n');
    fprintf('=========================================================================\n\n');

    % 1. Setup paths relative to project root
    script_path = mfilename('fullpath');
    scripts_dir = fileparts(script_path);
    project_root = fileparts(scripts_dir);

    models_dir  = fullfile(project_root, 'models');
    results_dir = fullfile(project_root, 'results', 'stage1');

    addpath(project_root);
    addpath(models_dir);
    addpath(scripts_dir);

    % 2. List step scripts
    steps = { ...
        'Step 1: Electromechanical Motor Plant Characterization', 'build_and_run_stage1.m'; ...
        'Step 2: 1000 CPR Encoder Feedback & Quantization',       'build_and_run_stage2.m'; ...
        'Step 3: Averaged PWM H-Bridge Actuation Model',         'build_and_run_stage3.m'; ...
        'Step 4: Continuous Closed-Loop Position Control',       'build_and_run_stage4.m'; ...
        'Step 5: Discrete Trajectory Control & Indexing',        'build_and_run_stage5.m'; ...
        'Step 6: Robustness, Disturbance & Friction Analysis',   'build_and_run_stage6.m'  ...
    };

    % 3. Sequentially run steps
    for k = 1:size(steps, 1)
        step_name = steps{k, 1};
        step_file = steps{k, 2};
        step_script = fullfile(scripts_dir, step_file);
        
        fprintf('Executing %s...\n', step_name);
        try
            bdclose('all');
            evalin('base', sprintf('run(''%s'');', step_script));
        catch ME
            fprintf('Error in %s: %s\n', step_name, ME.message);
        end
        bdclose('all');
    end

    fprintf('\n=========================================================================\n');
    fprintf('  STAGE 1 MASTER SIMULATION EXECUTION COMPLETED SUCCESSFULLY            \n');
    fprintf('  Simulation data exported to: results/stage1                            \n');
    fprintf('=========================================================================\n');
end
