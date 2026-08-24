% =========================================================================
% STAGE 1 AUTOMATED REGRESSION TEST SUITE (Root Entry Point)
% Project: STM32 Automated Precision Indexing & Feed Control System
% Stage 1: Complete Simulation Prototype (Steps 1 through 6)
% =========================================================================

function test_stage1()
    project_root = fileparts(mfilename('fullpath'));
    scripts_dir  = fullfile(project_root, 'scripts');
    addpath(scripts_dir);
    
    % Delegate to authoritative script in scripts/
    run(fullfile(scripts_dir, 'test_stage1.m'));
end
