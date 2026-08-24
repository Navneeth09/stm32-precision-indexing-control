---

# 2. Problem Statement

Precision indexing systems are commonly used in applications where a mechanism must repeatedly move to predefined positions.

Examples include:

- Automated feeding mechanisms
- Rotary indexing systems
- Industrial positioning systems
- Material handling equipment
- Automated machine tools
- Robotics
- Pick-and-place mechanisms
- Electromechanical actuators

A simple open-loop motor command is not sufficient when accurate positioning is required.

For example, the same PWM command can produce different motion depending on:

- Motor operating condition
- Mechanical load
- Friction
- Payload inertia
- External disturbances
- Encoder resolution

Therefore, the system needs a **closed-loop control architecture**.

The core problem addressed by this project is:

> **How can a motor-driven indexing mechanism achieve accurate and repeatable angular positioning while remaining robust to encoder quantization, friction, load disturbances, and mechanical parameter variations, and how can the resulting controller eventually be transferred to an STM32-based embedded system?**

---

# 3. Why This Project Is Needed

A controller that works only under ideal simulation conditions is not enough for an embedded control application.

A practical system has a chain of imperfections:

```text
Desired Position
       │
       ▼
 Motion Profile
       │
       ▼
 Controller
       │
       ▼
 PWM / Motor Driver
       │
       ▼
     Motor
       │
       ▼
 Mechanical System
       │
       ▼
    Encoder
       │
       ▼
 Quantized Measurement
       │
       └──────────────► Controller

Every block introduces limitations.

For example:

Encoder limitation

A 1000-CPR encoder provides:

360° / 1000 = 0.36° per count

Therefore, the controller cannot assume infinitely precise position information.

Mechanical disturbance

A change in payload or an external load torque can cause the motor to deviate from the commanded trajectory.

Friction

Static, Coulomb and velocity-dependent friction can produce nonlinear behaviour that is not captured by a simple ideal motor model.

Embedded implementation

A controller designed in continuous time must eventually operate with:

finite sampling frequency
discrete calculations
finite numerical precision
timer-driven execution
encoder measurements
PWM hardware

This is why the project is being developed incrementally.

4. Proposed Solution

The proposed system is a closed-loop precision indexing controller with a staged transition from simulation to embedded hardware.

The complete concept is:

                    COMMAND
                       │
                       ▼
             Desired Angular Position
                       │
                       ▼
              Trajectory Generator
                       │
                       ▼
                Position Controller
                       │
                       ▼
              Feedforward / Control
                       │
                       ▼
                 PWM / H-Bridge
                       │
                       ▼
                    DC Motor
                       │
                       ▼
              Mechanical Load
                       │
                       ▼
                   Encoder
                       │
                       ▼
              Position Measurement
                       │
                       ▼
             Velocity / Disturbance
                  Estimation
                       │
                       ▼
                 Feedback Loop
                       │
                       └──────────────► Controller

The long-term system will progressively replace ideal simulation information with quantities that can actually be measured or estimated on an embedded controller.

5. Complete Project Development Plan

The project is divided into three major stages.

┌──────────────────────────────────────────────┐
│                  STAGE 1                     │
│          Simulation Prototype                │
│                                              │
│ MATLAB + Simulink                            │
│ Motor → Encoder → PWM → PID → Robustness   │
└──────────────────────┬───────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────┐
│                  STAGE 2                     │
│       Embedded Control Architecture          │
│                                              │
│ STM32-oriented discrete implementation      │
│ Encoder velocity estimation                  │
│ Disturbance Observer                         │
│ Embedded control architecture                │
└──────────────────────┬───────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────┐
│                  STAGE 3                     │
│        Hardware Implementation               │
│                                              │
│ STM32 + Motor Driver + Encoder + Motor      │
│ Real-time experiments                        │
│ Disturbance / payload testing                │
│ Experimental validation                      │
└──────────────────────────────────────────────┘
Current progress
Stage	Description	Status
Stage 1	MATLAB/Simulink simulation prototype	Completed
Stage 2	Embedded control architecture	Planned
Stage 3	Physical STM32 hardware implementation and experiments	Planned

Only Stage 1 has been implemented and validated at the moment.

This repository therefore represents the simulation baseline of the complete project, not a claim that the STM32 hardware system has already been completed.

6. Stage 1 — Simulation Prototype

Stage 1 was developed to answer one fundamental question:

Does the proposed control architecture work before moving to embedded hardware?

The simulation was built progressively rather than creating one large model from the beginning.

This makes it possible to isolate and verify each part of the system.

Stage 1 contains six steps.

7. Stage 1 Workflow

The complete Stage 1 workflow is:

                     STAGE 1
                       │
                       ▼
          ┌─────────────────────────┐
          │ Step 1                  │
          │ DC Motor Plant          │
          │ Electromechanical Model │
          └────────────┬────────────┘
                       │
                       ▼
          ┌─────────────────────────┐
          │ Step 2                  │
          │ Encoder Quantization     │
          │ 1000 CPR                │
          └────────────┬────────────┘
                       │
                       ▼
          ┌─────────────────────────┐
          │ Step 3                  │
          │ PWM / H-Bridge          │
          │ Actuator Model          │
          └────────────┬────────────┘
                       │
                       ▼
          ┌─────────────────────────┐
          │ Step 4                  │
          │ Closed-Loop Position    │
          │ Control                 │
          └────────────┬────────────┘
                       │
                       ▼
          ┌─────────────────────────┐
          │ Step 5                  │
          │ 1 kHz Discrete PID      │
          │ + Trajectory Profile    │
          └────────────┬────────────┘
                       │
                       ▼
          ┌─────────────────────────┐
          │ Step 6                  │
          │ Robustness Testing      │
          │ Load + Friction +       │
          │ Inertia Variation       │
          └────────────┬────────────┘
                       │
                       ▼
             STAGE 1 VALIDATED
             SIMULATION BASELINE

Each step adds one layer of realism.

8. Stage 1 — Step-by-Step Development
Step 1 — Electromechanical DC Motor Model

The first step establishes the motor plant.

The motor is represented using its electrical and mechanical dynamics.

The model includes parameters such as:

Armature resistance
Armature inductance
Motor torque constant
Back-EMF constant
Rotor/load inertia
Mechanical friction

The purpose of this step is to make sure the basic plant behaves as expected before introducing the control loop.

Result

The simulated steady-state motor speed was:

239.4710 rad/s

or approximately:

2286.78 RPM

The measured result remained within the defined plant-model tolerance.

Status: PASS

9. Step 2 — Encoder Quantization

A real encoder does not provide continuous position information.

The simulation therefore introduces a:

1000 CPR encoder

with a position resolution of:

360° / 1000
= 0.36° / count

The purpose of this step is to test the controller using a realistic quantized position measurement rather than an ideal continuous position.

Result

Maximum encoder quantization error:

0.3599°

Acceptance limit:

0.3600°

Status: PASS

10. Step 3 — PWM / H-Bridge Model

The controller cannot directly control motor torque.

The control command is converted into an actuator command through the PWM/H-Bridge stage.

The simulation therefore establishes the relationship:

Controller output
       │
       ▼
PWM duty cycle
       │
       ▼
Average H-Bridge voltage
       │
       ▼
Motor

This step checks whether the simulated actuator behaves consistently with the expected motor response.

Example result

For:

Duty cycle = 0.75

the simulated steady-state speed was:

179.6033 rad/s

The measured actuator response remained within the defined linearity tolerance.

Status: PASS

11. Step 4 — Closed-Loop Position Control

The next step closes the position feedback loop.

The architecture becomes:

Target Position
      │
      ▼
    Error
      │
      ▼
 Controller
      │
      ▼
 PWM / Motor
      │
      ▼
 Position
      │
      ▼
 Encoder
      │
      └──────────► Feedback

The purpose is to determine whether the mechanism can reach the commanded position with acceptable transient behaviour and steady-state accuracy.

Measured results
Overshoot: 0.00%
Settling time: 78.4 ms
Steady-state error: 0.0384°

Status: PASS

12. Step 5 — Discrete 1 kHz Controller

A real STM32 controller will not operate using continuous-time mathematics.

The controller therefore needs to operate at a defined sampling frequency.

The Stage 1 controller was converted to a:

1 kHz discrete-time control loop

A trajectory profile is also introduced so that the mechanism does not simply attempt to jump instantaneously to the target position.

The conceptual flow becomes:

Position Command
       │
       ▼
Trajectory Generator
       │
       ▼
Reference Position
       │
       ▼
Discrete PID @ 1 kHz
       │
       ▼
PWM
       │
       ▼
Motor
       │
       ▼
Encoder
       │
       └──────────► Feedback
Measured result

Maximum dynamic tracking error:

0.4456°

The result remained within the defined Stage 1 dynamic error limit.

Status: PASS

13. Step 6 — Robustness Testing

The final Stage 1 step deliberately moves away from ideal conditions.

The controller is tested against several disturbances and parameter variations.

Test 1 — In-motion load disturbance

A load torque of:

0.010 N·m

was introduced during motion.

Measured maximum tracking error:

0.5218°

Peak armature current:

0.2486 A

Test 2 — In-dwell disturbance

A load disturbance was introduced while the mechanism was at its target position.

Measured maximum position deviation:

0.2786°

This corresponds to less than one encoder count:

0.2786° < 0.36°

Measured recovery time:

0 ms

Test 3 — Nonlinear friction

The simulation includes nonlinear Stribeck-type friction.

The final true position error was:

0.1512°

The final encoder position error was:

0.0000°

Test 4 — Payload inertia variation

The payload inertia was varied to:

1 × nominal
2 × nominal
3 × nominal

Measured errors:

Inertia	Maximum/Final Error
1×	0.4706°
2×	0.2848°
3×	0.7201°

All remained within the Stage 1 acceptance requirement.

Step 6 Status: PASS

14. Stage 1 Final Result

The complete Stage 1 regression test covers all six steps.

Step	Description	Result
1	DC motor plant	PASS
2	Encoder quantization	PASS
3	PWM / H-Bridge linearity	PASS
4	Closed-loop position control	PASS
5	1 kHz discrete PID + trajectory	PASS
6	Disturbance, friction & inertia testing	PASS

The Stage 1 automated regression suite completed successfully.

Stage 1 conclusion

The simulation prototype satisfies the defined Stage 1 acceptance criteria.

This provides the baseline for the next phase of the project.

15. What Stage 1 Does — and Does Not — Prove

This distinction is important.

Stage 1 proves

The simulation demonstrates that the proposed control architecture can:

model the motor dynamics
operate with encoder quantization
control the motor through PWM
perform closed-loop position control
operate at a 1 kHz discrete control rate
follow a trajectory
tolerate defined load disturbances
tolerate nonlinear friction
tolerate payload inertia variations
Stage 1 does NOT prove

The current repository does not demonstrate:

STM32 firmware execution
real-time MCU performance
physical motor behaviour
real encoder measurements
real PWM output
motor-driver behaviour
hardware electrical limitations
sensor noise in a physical system
hardware disturbance rejection

Those questions belong to the later stages.

16. Stage 2 — Embedded Control Architecture

Stage 2 will begin the transition from simulation to embedded implementation.

The main challenge is that some information available directly inside a simulation will not be available to an STM32 controller.

For example, Stage 1 can directly use the simulated load torque.

A real controller cannot simply read the actual external load torque.

Therefore Stage 2 will introduce estimation.

The planned architecture includes:

Disturbance Observer

A discrete disturbance observer will estimate the combined disturbance acting on the system.

Conceptually:

PWM Command
     │
     ▼
   Motor
     │
     ├──────────────► Encoder
     │                   │
     │                   ▼
     │             Position / Velocity
     │                   │
     ▼                   ▼
             Disturbance Observer
                     │
                     ▼
              Estimated Disturbance
                     │
                     ▼
                 Controller
Encoder velocity estimation

Stage 2 will also replace ideal/reference velocity information with velocity estimated from encoder measurements.

Embedded implementation

The control algorithm will then be structured for execution on an STM32 microcontroller.

The exact MCU, peripheral configuration and implementation details will be finalized during Stage 2.

17. Stage 3 — Hardware Implementation & Experimentation

After the embedded control architecture has been verified, the project will move to physical experimentation.

The intended hardware chain is:

                 STM32
                   │
          ┌────────┴────────┐
          │                 │
          ▼                 ▼
      PWM Output        Encoder Input
          │                 ▲
          ▼                 │
     Motor Driver           │
          │                 │
          ▼                 │
        DC Motor ───────────┘
          │
          ▼
     Mechanical Load

Stage 3 will investigate the difference between:

Simulation
    vs.
Embedded execution
    vs.
Physical experiment

The hardware experiments are expected to evaluate:

Position accuracy
Settling time
Tracking error
Encoder behaviour
Disturbance rejection
Payload variation
Friction effects
Current response
Controller timing
Real-world repeatability

The final objective is to determine how closely the physical system follows the validated simulation model.

18. Complete Project Workflow

The complete development philosophy can therefore be summarized as:

                 PROJECT START
                      │
                      ▼
              Define Requirements
                      │
                      ▼
              Build Motor Model
                      │
                      ▼
             Add Encoder Effects
                      │
                      ▼
              Add PWM / Actuator
                      │
                      ▼
            Develop Position Loop
                      │
                      ▼
            Discretize Controller
                      │
                      ▼
           Test Robustness
                      │
                      ▼
        ┌──────────────────────────┐
        │        STAGE 1           │
        │  Simulation Validation   │
        └────────────┬─────────────┘
                     │
                     ▼
        ┌──────────────────────────┐
        │        STAGE 2           │
        │ Embedded Architecture    │
        │                          │
        │ DOB + Velocity Estimator │
        │ + MCU Control            │
        └────────────┬─────────────┘
                     │
                     ▼
        ┌──────────────────────────┐
        │        STAGE 3           │
        │ Hardware Implementation  │
        │                          │
        │ STM32 + Motor + Encoder  │
        │ + Driver + Load          │
        └────────────┬─────────────┘
                     │
                     ▼
             Hardware Testing
                     │
                     ▼
        Compare Simulation vs Real
                     │
                     ▼
             Final Validation
19. Repository Structure
stm32-precision-indexing-control/
│
├── models/
│   ├── stage1_motor_plant.slx
│   ├── stage1_encoder_quantization.slx
│   ├── stage1_pwm_model.slx
│   ├── stage1_position_control.slx
│   ├── stage1_discrete_pid.slx
│   └── stage1_robust_loop_model.slx
│
├── scripts/
│   ├── params.m
│   ├── build_and_run_stage1.m
│   ├── build_and_run_stage2.m
│   ├── build_and_run_stage3.m
│   ├── build_and_run_stage4.m
│   ├── build_and_run_stage5.m
│   ├── build_and_run_stage6.m
│   └── test_stage1.m
│
├── results/
│   └── stage1/
│
├── plots/
│   └── stage1/
│
├── docs/
│   ├── STAGE_1_OVERVIEW.md
│   ├── STAGE_1_STEP_1.md
│   ├── STAGE_1_STEP_2.md
│   ├── STAGE_1_STEP_3.md
│   ├── STAGE_1_STEP_4.md
│   ├── STAGE_1_STEP_5.md
│   ├── STAGE_1_STEP_6.md
│   ├── STAGE_1_FINAL_REPORT.md
│   ├── STAGE_1_FINAL_VERIFICATION.md
│   └── STAGE_1_REPRODUCIBILITY.md
│
├── audit/
│   └── Stage 1 verification and audit documents
│
├── requirements/
│   └── python_requirements.txt
│
├── run_stage1.m
├── test_stage1.m
├── README.md
├── LICENSE
└── .gitignore
20. How to Reproduce Stage 1
Requirements

You will need:

MATLAB
Simulink
MATLAB release compatible with the included models
Python for the supporting analysis/plot-generation scripts

Python dependencies are listed in:

requirements/python_requirements.txt
Step 1 — Clone the repository
git clone https://github.com/Navneeth09/stm32-precision-indexing-control.git

Enter the project directory:

cd stm32-precision-indexing-control
Step 2 — Open MATLAB

Set the MATLAB current folder to the project root.

For example:

cd('path/to/stm32-precision-indexing-control')
Step 3 — Run the complete Stage 1 pipeline
run_stage1

This executes the Stage 1 simulation workflow.

Step 4 — Run the regression test

After the simulations have been generated:

test_stage1

The regression test checks the six Stage 1 steps against their defined acceptance criteria.

Step 5 — Inspect the results

Simulation datasets are stored under:

results/stage1/

Generated figures are stored under:

plots/stage1/

Detailed engineering documentation is available under:

docs/
21. Documentation

The repository contains documentation at different levels.

Start here
README.md

High-level explanation of the complete project.

System architecture
docs/STAGE_1_OVERVIEW.md
Individual development steps
docs/STAGE_1_STEP_1.md
docs/STAGE_1_STEP_2.md
docs/STAGE_1_STEP_3.md
docs/STAGE_1_STEP_4.md
docs/STAGE_1_STEP_5.md
docs/STAGE_1_STEP_6.md
Final engineering report
docs/STAGE_1_FINAL_REPORT.md
Verification
docs/STAGE_1_FINAL_VERIFICATION.md
Reproduction guide
docs/STAGE_1_REPRODUCIBILITY.md

The audit/ directory contains additional verification and audit records from the Stage 1 development process.

22. Current Limitations

The current implementation is intentionally limited to the simulation prototype.

Important limitations include:

The motor is represented by a mathematical simulation model.
The encoder is simulated rather than physically measured.
PWM/H-Bridge behaviour is represented by a simulation model.
Load torque is available directly inside the simulation environment.
Some friction/feedforward information is available that would not be directly available to an embedded controller.
No STM32 firmware has been executed yet.
No physical motor or encoder experiment has been performed yet.

These are not hidden limitations — they define the boundary between the completed Stage 1 work and the future stages.

23. Current Project Status
Stage 1 — Simulation Prototype
████████████████████  100%

Stage 2 — Embedded Control
░░░░░░░░░░░░░░░░░░░░    0%

Stage 3 — Hardware Experimentation
░░░░░░░░░░░░░░░░░░░░    0%
Current milestone

Stage 1 completed and verified.

The next development milestone is the transition from the validated Simulink controller to an embedded-oriented control architecture.

24. Why the Project Is Being Developed This Way

The purpose of the staged approach is not simply to make the project longer.

Each stage answers a different engineering question.

Stage 1 asks:

Does the control concept work?

Stage 2 asks:

Can the control concept be implemented using the information and computational resources available to an embedded controller?

Stage 3 asks:

Does the controller still work when connected to real hardware?

This separation makes it possible to identify where a problem originates.

For example:

If Stage 1 fails
      ↓
Control/model problem

If Stage 1 passes but Stage 2 fails
      ↓
Discretization / estimation /
embedded implementation problem

If Stage 2 passes but Stage 3 fails
      ↓
Hardware / modelling /
noise / mechanical problem

This is the main reason for building the project incrementally.

25. Final Note

This repository currently represents the first milestone of a larger embedded control project.

The simulation prototype is not being presented as a replacement for hardware testing.

Instead, it provides a controlled baseline from which the embedded and hardware stages can be developed.

The intended progression is:

Model → Simulate → Verify → Discretize → Embed → Experiment → Compare

Stage 1 completes the first part of that journey.
