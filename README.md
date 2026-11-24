# Single-Cycle RISC-V Processor (FPGA Implementation)

## Completed
- **Base Core (Labs 1–11):** All base RTL modules and datapath/control logic are complete.
- **Extended Instructions (RTL):** Added `lui`, `andi`, and `blt` as 3 new non-base instructions in the RTL for Task 2a *(pending instructor confirmation that these 3 are sufficient)*.
- **FPGA Top & Constraints:** Created `top_riscv_fpga.v` (includes 100 MHz to 1 MHz clock divider, `BUFG`, and 2-flop input synchronizer) and mapped the `.xdc` file in `constrs_1`.

---

## To-Do

### Task 1: Base Processor FPGA Deployment (20%)
- [ ] Adjust delay loop constants in `instructions.mem` from 10 MHz (`1250 × 2000`, ~10s per step) to 1 MHz (`125 × 2000`, ~1s per step).
- [ ] Run Synthesis and Implementation on `top_riscv_fpga.v` to check for errors or critical warnings (ensure explicit `else` branches are present in `RegisterFile.v`, `DataMemory.v`, `switches.v`, and `BranchControl.v` to avoid inferred latches), and verify `cpu_clk` is 1 MHz in the Timing Summary.
- [ ] Generate bitstream and test on the FPGA (verify LED countdown, software reset, and hardware reset).

### Task 2a: Instruction Extensions & Verification — Simulation (25%)
- [ ] Confirm with instructor that `lui`, `andi`, and `blt` meet the Task 2a requirements.
- [ ] Write and assemble the Task 2a `.s` program in VS Code (Fibonacci or factorial utilizing the stack alongside `lui`, `andi`, and `blt`).
- [ ] Write individual assembly test cases to verify `lui`, `andi`, and `blt` independently, export the `.mem` file padded to 256 bytes with NOPs (`00000013`), and run testbench simulations to confirm execution before hardware deployment.

### Task 2b: Extended Processor FPGA Demo (20%)
- [x] Create FPGA top module (`top_riscv_fpga.v`) and `.xdc` pin constraints.
- [ ] Connect the compiled 256-byte `.mem` file generated from Task 2a by passing `MEM_FILE` down (`top_riscv_fpga.v` → `TopLevelProcessor.v` → `instructionMemory.v`).
- [ ] Generate bitstream and run the FPGA hardware demo to verify stack operations and the 3 new instructions on the board.

### Documentation & Viva (25%)
- [ ] Write and finalize the project report (≤ 5 pages: RTL schematic, Task 2a assembly code, modified module names, and key snippets only) and prepare for the viva.
