% =========================================================================
% STAGE 1 MASTER EXECUTION PIPELINE (Root Entry Point)
% Project: STM32 Automated Precision Indexing & Feed Control System
% Stage 1: Complete Simulation Prototype (Steps 1 through 6)
% =========================================================================

function run_stage1()
    project_root = fileparts(mfilename('fullpath'));
    scripts_dir  = fullfile(project_root, 'scripts');
    addpath(scripts_dir);
    
    % Delegate to authoritative script in scripts/
    run(fullfile(scripts_dir, 'run_stage1.m'));
end
