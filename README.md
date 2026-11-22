# Single-Cycle RISC-V Processor — CA Lab Project (EE/CE 321L)

Single-cycle RV32I processor in Verilog targeting the **Basys 3 (Artix-7)** FPGA in Vivado.

---

## How to Open & Run (For Team Members)

1. Clone this repo anywhere on your machine.
2. Open **`CA_risc_V_processor.xpr`** in Vivado.
3. All Verilog sources, testbenches, `.mem` files, and `.xdc` constraints use relative paths (`$PSRCDIR/...`), so nothing needs to be re-linked.
4. **To run the counter simulation:**
   - `TopLevelProcessor_counter_tb` is already set as the simulation top.
   - Click **Run Simulation → Run Behavioral Simulation**, then click **Run All (`F3`)** (the default 1000 ns is too short).
   - You should see `ALL DONE` with all 5 tests passing.
5. **To synthesize for Basys 3:**
   - Right-click `top_riscv_fpga` in Design Sources → **Set as Top**.
   - `constraint_oel.xdc` is already registered in Constraints (`constrs_1`).

---

## Project Structure

- `CA_risc_V_processor.xpr` — Vivado project file
- `CA_risc_V_processor.srcs/sources_1/new/` — All Verilog modules (Labs 5–11 + FPGA wrapper) and `.mem` files:
  - **Core CPU:** `TopLevelProcessor.v`, `ProgramCounter.v`, `pcAdder.v`, `branchAdder.v`, `mux2.v`, `immGen.v`, `BranchControl.v`, `instructionMemory.v`, `MainControl.v`, `ALUControl.v`, `Alu.v` (+ sub-modules), `RegisterFile.v`, `DataMemory.v`, `AddressDecoder.v`, `addressDecoderTop.v`, `leds.v`, `switches.v`, `debouncer.v`
  - **FPGA Top (1 MHz):** `top_riscv_fpga.v` (100 MHz → 1 MHz divider + `BUFG` + input synchronizers)
  - **Programs:** `instructions.mem` (Lab 10 counter, 256-byte padded), `instructions_sim.mem` (fast-delay counter for simulation)
- `CA_risc_V_processor.srcs/sim_1/new/` — Testbenches (`TopLevelProcessor_counter_tb.v`, `PCDatapath_tb.v`, `ControlPath_tb.v`, and earlier lab testbenches)
- `CA_risc_V_processor.srcs/constrs_1/new/` — Basys 3 pin & clock constraints (`constraint_oel.xdc`)

> **Note on Lab 5 module names:** `leds.v` reads the switches and `switches.v` drives the LEDs (original Lab 5 naming kept for compatibility).

---

## Status: What Is Done vs. What Is Left

### Done
- [x] **Labs 5–11 single-cycle CPU** integrated in `TopLevelProcessor.v`
- [x] **`.mem`-based instruction memory** (`instructionMemory.v` uses `$readmemh(MEM_FILE, memory)` — no hardcoded instructions)
- [x] **3 extra instructions RTL** already implemented across the proper modules: `lui`, `andi`, `blt` (plus `bge`, `ori`, `xori`)
- [x] **1 MHz FPGA wrapper** (`top_riscv_fpga.v`) and Basys 3 constraints (`constraint_oel.xdc`) registered in `.xpr`
- [x] **RA code-review fixes:** explicit `else` branches added in `RegisterFile.v`, `DataMemory.v`, `switches.v`, and `BranchControl.v`

### Left to Do (Course Project)
- [ ] **Task 1 (FPGA Demo of Lab 10 FSM — 20%):**
  - Update delay constants in `instructions.mem` from 10 MHz (`1250 × 2000`) to **1 MHz** (~1 s/step, e.g., `125 × 2000`)
  - Synthesize/implement `top_riscv_fpga` with 0 errors & 0 critical warnings, verify 1 MHz `cpu_clk` timing, and demo on Basys 3
- [ ] **Task 2a (Assembly Program w/ Stack + 3 Extra Instructions — 10% + 15%):**
  - Write & test the Task 2a `.s` program (e.g., Fibonacci/Factorial using stack + `lui`, `andi`, `blt`) in VS Code
  - Write individual assembly tests verifying `lui`, `andi`, and `blt`
  - Export 256-byte `.mem` and simulate in Vivado with a clean testbench
- [ ] **Task 2b (FPGA Demo of Task 2a — 20%):**
  - Set `MEM_FILE` in `top_riscv_fpga.v` to the Task 2a `.mem`, build bitstream, and demo on Basys 3
- [ ] **Open RA items to decide:**
  - Whether to keep `DataMemory` `initial`-zeroed (LUTRAM) or add a synchronous `rst`
  - Whether to remove the extra `pbrst` (`btnU`) button in `top_riscv_fpga.v` so only `pbin` (`btnC`) is used
- [ ] **Report & Viva (25%):**
  - Concise report (≤ 5 pages: RTL schematic, Task 2a assembly, modified module names, key snippets only)
  - Final Git commits & individual viva prep

---

## Changelog

- **2026-11-22 — Clean baseline for Course Project**
  - Replaced hardcoded programs in `instructionMemory.v` with `$readmemh(MEM_FILE, memory)`
  - Moved `instructions.mem` and `instructions_sim.mem` into `sources_1/new/` (padded to 256 bytes with NOPs) and removed external Downloads paths from `.xpr`
  - Passed `MEM_FILE` through `top_riscv_fpga.v` → `TopLevelProcessor.v` → `instructionMemory.v` and simplified `TopLevelProcessor_counter_tb.v`
  - Registered `constraint_oel.xdc` in `constrs_1` and re-enabled `top_riscv_fpga.v` in `.xpr`
  - Added explicit `else` branches in `RegisterFile.v`, `DataMemory.v`, `switches.v`, and `BranchControl.v`
