# Stage 1 Complete Forensic Audit — GitHub Repository Readiness Audit

## 1. Overview
Audit of repository structure, clean file isolation, and reproducibility for public GitHub release.

## 2. File Commit Categorization

### Files to Commit to Git:
- `models/*.slx` (All 6 Stage 1 Simulink models)
- `scripts/*.m` (All 6 programmatic build/run scripts + `params.m`)
- `scripts/*.py` (Plotting scripts)
- `results/stage1/*.mat` & `*.png` (All simulation datasets and high-res figures)
- `docs/STAGE_1_STEP_*.md` (Technical documentation reports)
- `audit/stage1_complete/*` (Audit reports, CSV matrices, test MAT datasets)

### Files NOT to Commit (.gitignore):
- `slprj/` (Simulink compilation cache directories)
- `*.slxc` (Simulink cache files)
- `*.asv` / `*.m~` (MATLAB autosave files)

## 3. Pre-Commit Recommended Polish Checklist
- [x] All build scripts executable headlessly in batch mode.
- [x] Zero hardcoded absolute paths.
- [x] Cryptographic SHA-256 baseline hashes recorded.
- [ ] Add `stage1_data.mat` & `stage2_data.mat` export lines to Step 1 & Step 2 scripts.
