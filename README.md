# 16-bit Multi-Cycle CPU Design

## Overview
This project features a **multi-cycle processor** operating on **16-bit registers**. The entire system is designed and implemented using **VHDL** (Hardware Description Language).

## Architecture
The design is modular and consists of 4 main components:
* **ALU** (Arithmetic Logic Unit)
* **Register File**
* **Memory Interface**
* **Control Unit**

These components are structurally integrated into a single top-level entity within the `processor.vhd` file.

## Verification
To verify the correctness of the work, a ***testbench*** file was added that checks the entire set of added commands.

## Control Unit Strategy
The core of this multi-cycle CPU is its **Control Unit**. Unlike single-cycle designs, this unit manages complex states and transitions. The Finite State Machine (FSM) logic and transitions are illustrated below:

<p align="center">
  <img width="619" alt="Control Unit States" src="https://github.com/user-attachments/assets/90e81bd5-4118-4006-9c4e-203f771b6a4f" />
</p>

<p align="center">
  <img width="940" alt="Waveform Timing" src="https://github.com/user-attachments/assets/e911ccba-3e28-44b3-9622-9dc4d01d6185" />
</p>

## Documentation
You can read more about the project in the full documentation(in Polish): (in Polish):

**[Sprawozdanie z projektu procesora w języku VHDL.pdf](https://github.com/user-attachments/files/26166786/Sprawozdanie.z.projektu.procesora.w.jezyku.VHDL.pdf)**
