% =========================================================================
% STAGE 1 AUTOMATED REGRESSION TEST SUITE (Authoritative Script)
% Project: STM32 Automated Precision Indexing & Feed Control System
% Stage 1: Complete Simulation Prototype (Steps 1 through 6)
% =========================================================================

function test_stage1()
    clc;
    bdclose('all');
    clearvars -except test_stage1;
    close all;

    fprintf('=========================================================================\n');
    fprintf('                 STAGE 1 AUTOMATED REGRESSION TEST                      \n');
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

    % 2. List test steps
    steps = { ...
        'Step 1: Electromechanical Motor Plant Characterization', 'build_and_run_stage1.m'; ...
        'Step 2: 1000 CPR Encoder Feedback & Quantization',       'build_and_run_stage2.m'; ...
        'Step 3: Averaged PWM H-Bridge Actuation Model',         'build_and_run_stage3.m'; ...
        'Step 4: Continuous Closed-Loop Position Control',       'build_and_run_stage4.m'; ...
        'Step 5: Discrete Trajectory Control & Indexing',        'build_and_run_stage5.m'; ...
        'Step 6: Robustness, Disturbance & Friction Analysis',   'build_and_run_stage6.m'  ...
    };

    results_struct = struct();

    % 3. Execute step-by-step validation checks
    for k = 1:size(steps, 1)
        step_name = steps{k, 1};
        step_file = steps{k, 2};
        step_script = fullfile(scripts_dir, step_file);
        
        fprintf('Running Regression Checks for %s...\n', step_name);
        try
            bdclose('all');
            evalin('base', sprintf('run(''%s'');', step_script));
            
            % Sanity check generated dataset
            data_mat = fullfile(results_dir, sprintf('stage%d_data.mat', k));
            if ~exist(data_mat, 'file')
                error('Result MAT file missing: %s', data_mat);
            end
            
            mat_info = load(data_mat);
            % Check for NaN or Inf in MAT dataset
            fnames = fieldnames(mat_info);
            has_nan = false;
            for fn = 1:length(fnames)
                val = mat_info.(fnames{fn});
                if isnumeric(val) && (any(isnan(val(:))) || any(isinf(val(:))))
                    has_nan = true;
                    break;
                end
            end
            
            if has_nan
                results_struct.(sprintf('Step%d', k)) = 'FAIL (NaN/Inf detected)';
            else
                results_struct.(sprintf('Step%d', k)) = 'PASS';
            end
        catch ME
            results_struct.(sprintf('Step%d', k)) = sprintf('FAIL (%s)', ME.message);
        end
        bdclose('all');
    end

    % 4. Master Regression Summary Terminal Report
    fprintf('\n====================================\n');
    fprintf('STAGE 1 REGRESSION TEST SUMMARY\n');
    fprintf('====================================\n');
    
    overall_pass = true;
    for k = 1:size(steps, 1)
        status = results_struct.(sprintf('Step%d', k));
        fprintf('Step %d: %s\n', k, status);
        if ~contains(status, 'PASS')
            overall_pass = false;
        end
    end
    fprintf('------------------------------------\n');

    if overall_pass
        fprintf('Overall: PASS\n');
    else
        fprintf('Overall: FAIL\n');
    end
    fprintf('====================================\n');
end
