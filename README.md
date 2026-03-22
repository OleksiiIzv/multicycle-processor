The CPU is designed as a multi-cycle processor operating on 16-bit registers.
The project is written in the integrated circuit description language VHDL.

The design consists of 4 main components: 
ALU, 
Register file, 
Memory interface, 
Сontrol unit.

These components are structurally integrated into a single top-level file: processor.vhd
To verify the correctness of the work, a testbench file was added that checks the entire set of added commands.

The main feature of a multi-cycle CPU is the design of its control unit, the main states and transitions are given below.
<img width="619" height="571" alt="image" src="https://github.com/user-attachments/assets/90e81bd5-4118-4006-9c4e-203f771b6a4f" />
<img width="940" height="285" alt="image" src="https://github.com/user-attachments/assets/e911ccba-3e28-44b3-9622-9dc4d01d6185" />
You can read more about the project in the full documentation(in Polish): [Sprawozdanie z projektu procesora w języku VHDL](./Sprawozdanie z projektu procesora w języku VHDL.pdf)
