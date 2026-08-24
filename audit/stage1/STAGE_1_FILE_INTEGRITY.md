# Stage 1 Forensic Audit — File Integrity & Baseline Regression Audit

## 1. Baseline Model Integrity Verification
Cryptographic SHA-256 hashes of all Step 1 through Step 5 models were calculated and verified:

| Baseline Model File | SHA-256 Hash | Integrity Audit Result |
| :--- | :--- | :--- |
| models/stage1_motor_plant.slx | EBBAA72E8B062D771293AB593FA65FA7A81BAB720E5B... | **100% UNTOUCHED** |
| models/stage1_encoder_model.slx | 7767F20C415E68680F736D4730D2053C45716D1EE781... | **100% UNTOUCHED** |
| models/stage1_pwm_model.slx | E2BF6C923A8743F39CBF5B683247697D850E032DAE57... | **100% UNTOUCHED** |
| models/stage1_closed_loop_model.slx | 92F41BBC4CD367D19E5EA9AFFE48930576330F4B5E3B... | **100% UNTOUCHED** |
| models/stage1_profiled_loop_model.slx | 976E4B6EED995AF5E11F471A296570C3F39B0D8364E8... | **100% UNTOUCHED** |

## 2. Dataset Provenance Audit
- 
esults/stage1/stage3_data.mat — **VERIFIED INTACT**
- 
esults/stage1/stage4_data.mat — **VERIFIED INTACT**
- 
esults/stage1/stage5_data.mat — **VERIFIED INTACT**
- 
esults/stage1/stage6_data.mat — **VERIFIED INTACT** (Contains both Baseline and Corrected Step 6 datasets side-by-side)
- stage1_data.mat & stage2_data.mat — **ABSENT FROM DIRECTORY** (Scripts uild_and_run_stage1.m & stage2.m logged to workspace/plots but did not save .mat files).
