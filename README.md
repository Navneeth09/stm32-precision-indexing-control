# STM32 Precision Indexing & Feed Control

A simulation-first control system for achieving precise angular positioning of a motor-driven indexing mechanism, with a planned transition to STM32 embedded control.

> **Current status:** Stage 1 — Complete  
> **Current implementation:** MATLAB / Simulink  
> **Hardware:** STM32 implementation planned for Stage 2

---

## Why I started this project

Precise positioning sounds simple until the system has to deal with things that exist in the real world:

- motor dynamics
- encoder quantization
- PWM actuation
- discrete-time control
- friction
- load disturbances
- changing payload inertia
- limited positioning resolution

The original goal of this project is to build a control system that can move an indexing mechanism to a commanded angular position and settle within the resolution of a **1000-CPR encoder**.

Instead of jumping directly into STM32 firmware, I decided to first build and validate the complete control concept in simulation.

That became **Stage 1 of the project**.

---

# Project objective

The long-term objective is:

**Command an angular position → generate a controlled motion profile → drive the motor → read the encoder → correct the position → reject disturbances → settle accurately at the required index.**

The complete project is being developed in stages:

```text
                 PROJECT FLOW

        ┌─────────────────────────┐
        │   Motor + Load System   │
        └────────────┬────────────┘
                     │
                     ▼
             Position Command
                     │
                     ▼
          Trajectory / Motion Profile
                     │
                     ▼
              PID Controller
                     │
                     ▼
              PWM / H-Bridge
                     │
                     ▼
                 DC Motor
                     │
                     ▼
                 Encoder
                     │
                     └───────────────┐
                                     │
                                     ▼
                              Position Feedback
