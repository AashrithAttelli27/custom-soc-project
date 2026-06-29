# custom-soc-project — Master Specification

> **Claude Code / Claude Chat instructions:**
> This is the canonical project spec. Read this entire file before responding to any request.
> All architectural decisions in this document are LOCKED — do not suggest alternatives unless explicitly asked.
> Your role is advisor and reviewer. Aashrith writes every line of RTL, testbench, and software.
> Never generate production code unprompted. Explain concepts, review work, answer questions.
> When asked about a step, first confirm understanding of the concept before any implementation discussion.

---

## Current State

- **All 14 design decisions locked** (see Locked Design Decisions below)
- **Current phase:** Week 1 — Infrastructure setup (in progress)
- **Summer target:** Steps 1–42 (OoO CPU + AI accelerator + FPGA bring-up + Tiny Tapeout candidate)

### Completed so far
- [x] Step 1: GitHub repo created — https://github.com/AashrithAttelli27/custom-soc-project (public)
- [x] Full folder structure created (see Decision 13)
- [x] `.gitignore` written (Python base + Verilator + Vivado + OS entries)
- [x] `README.md` written
- [x] `docs/CLAUDE.md` placed in repo

### In progress
- [ ] Step 2: Verilator installed and verified ✓ — write `rtl/cpu/fetch/counter.sv` and confirm lint passes
- [ ] Step 3: cocotb installed ✓ — write `tb/cpu/fetch/test-counter.py` and confirm sim passes
- [ ] Step 4: Write `Makefile` and `.github/workflows/ci.yml`, push, confirm CI goes green

### Next action
Write `rtl/cpu/fetch/counter.sv` — 8-bit counter using `logic` and `always_ff`. Run `verilator --lint-only -Wall rtl/cpu/fetch/counter.sv`. Zero warnings = environment proven.

---

## Project Identity

- **Name:** custom-soc-project
- **Team:** 2-person team (Aashrith + collaborator), rising junior ECE at UT Austin
- **Goal:** Custom modular SoC built from scratch as a long-term portfolio project
- **Target companies:** NVIDIA, AMD, Intel, Qualcomm, Google, Apple, Broadcom, Samsung, Micron, Amazon
- **Target roles:** CPU architecture, GPU architecture, cache controllers, memory systems, AI accelerators, SRAM/cache design, clock distribution, high-speed SerDes, DSP, PLLs, TPUs, custom CPUs, PCIe, Ethernet MAC
- **Approach:** Human-led design, one decision at a time with full understanding of the reasoning. Claude assists with explanation and review — NOT code generation.

---

## Decision Summary (Quick Reference)

| # | Topic | Choice |
|---|-------|--------|
| 1 | ISA | RV64IMAC, custom0–custom3 reserved |
| 2 | Microarchitecture | R10K OoO — ROB, RS, free list, map table, arch map table, CDB |
| 3 | Issue width | 4-wide, parameterized (`ISSUE_WIDTH = 4`) |
| 4 | ROB + RF size | 128-entry ROB, 128 physical registers (96 rename + 32 arch) |
| 5 | Branch predictor | TAGE (8 tables, geometric history) — gshare placeholder first |
| 6 | Interconnect | AXI4 crossbar, 128-bit FPGA / 256-bit silicon (one parameter) |
| 7 | Cache hierarchy | L1 I/D 32KB 8-way, L2 256KB, LLC ~1MB — exclusive policy, MESI snooping |
| 8 | AI accelerator | 8×8 systolic array, weight-stationary, INT8, scratchpad SRAM |
| 8e | CPU-accel interface | Hybrid: custom0 instruction (config/trigger) + DMA (data) + interrupt (completion) |
| 9 | GPU vision | SIMT, 32-thread warps, parameterized multi-SM (`NUM_SMS=1` → 4), GPU-private L2 → shared LLC |
| 10 | Peripherals | UART, Timer, PLIC, GPIO, SPI |
| 11 | Software stack | v1a: bare-metal reset stub → v1b: M-mode trap handler → v2: SBI; thin C drivers; `aether_gemm()` C API |
| 12 | Memory controller | Address map: DRAM at `0x8000_0000`; MIG wrapper ~200 lines; graduated boot ROM |
| 13 | Repo structure | `custom-soc-project`, kebab-case, GitHub Flow branching, Verilator CI on every PR |
| 14 | Implementation order | 42 steps summer, 73 steps full roadmap (see Decision 14 below) |

---

## Summer Deliverable (v1 — 8 Weeks)

**Option B inside Option C:** Working OoO RV64 CPU + AI accelerator connected via AXI4, verified in Verilator simulation, synthesized to FPGA.

FPGA is NOT needed to start — Verilator simulation covers ~90% of development. Purchase/borrow FPGA around week 6–7.

### 8-Week Timeline

| Weeks | Work |
|-------|------|
| 1–2 | SystemVerilog env, Verilator setup, AXI4 bus skeleton + cocotb testbench framework |
| 2–4 | OoO CPU core: Fetch, Decode, R10K renaming, ROB, RS, all FUs, in-order commit |
| 4–5 | Memory system: non-blocking L1 I/D cache, MSHRs, store queue |
| 5–6 | Branch predictor (gshare placeholder → TAGE), prefetcher, full pipeline integration |
| 6–7 | AI accelerator: systolic array 8×8, custom instruction interface, DMA engine |
| 7–8 | Full verification suite, FPGA synthesis, Tiny Tapeout candidate polish |

---

## Long-Term SoC Architecture

### Unified Memory Architecture (Apple Silicon style)
CPU, GPU, and AI accelerator share one physical memory pool. No discrete memory per unit.

```
  [CPU Core]    [GPU Shader Array]    [AI Accelerator]
      |                |                     |
   L1/L2           GPU L1/L2             Scratchpad
      |                |                     |
      +----------------+---------------------+
                       |
           [Unified Interconnect (AXI4 Crossbar)]
                       |
           [Shared Last-Level Cache (LLC)]
                       |
           [Memory Controller]
                       |
           [Unified DRAM]
```

### Interconnect Roadmap

| Phase | Protocol | Notes |
|-------|----------|-------|
| v1 (Summer) | AXI4 Crossbar | Industry standard, any master to any slave |
| v2 | Ring Interconnect | Fixed latency, better scalability |
| v3 | Mesh NoC | Many-core scaling, NVIDIA/Intel style |

---

## IP Block Roadmap

| IP Block | Domain | Priority |
|----------|--------|----------|
| RV64 OoO CPU | Custom CPUs, pipeline design | Summer core |
| L1/L2/LLC Cache + Controller | SRAM/cache design, memory systems | Summer core |
| AXI4 Crossbar Interconnect | Bus design, networking | Summer core |
| Systolic Array AI Accelerator | TPUs, AI accelerators | Summer stretch |
| SIMT GPU Shader Array | GPU architecture | Post-summer v1 |
| Ethernet MAC | Networking chips | Post-summer v1 |
| DSP Block (FFT/FIR) | DSP, digital wireless baseband | Post-summer v2 |
| PLL (ring oscillator) | PLLs, analog mixed-signal | Post-summer v2 |
| Clock Distribution Network | Clock distribution, gating | Post-summer v2 |
| PCIe Controller | PCIe | Long-term |
| High-Speed SerDes PHY | High-speed SerDes | Long-term |
| RF Digital Baseband | RF transceivers, wireless comms | Long-term |

---

## Locked Design Decisions

### Decision 1 — ISA
**Choice:** RV64IMAC
- 64-bit RISC-V
- Extensions: Integer (I), Multiply/Divide (M), Atomics (A), Compressed (C)
- FP (F/D) deferred to post-summer
- Custom opcode space (custom0–custom3) reserved for accelerator instructions
- **Why:** Open standard, no licensing fees, industry-standard toolchain (GCC, LLVM, Spike), custom opcode space is critical for the accelerator interface

---

### Decision 2 — Microarchitecture Style
**Choice:** R10K-style Out-of-Order Superscalar
- Explicit register renaming
- Reorder Buffer (ROB) for in-order commit and precise exceptions
- Reservation Station (RS) for out-of-order issue
- Free list + map table + architectural map table
- Common Data Bus (CDB) for result broadcast
- **Why:** Industry-standard OoO model. Validated by EECS470 (U. Michigan) — 4 students built a 3-wide RV32IM OoO in 6 weeks with no AI tools.

---

### Decision 3 — Issue Width
**Choice:** 4-wide superscalar, fully parameterized

```systemverilog
parameter int ISSUE_WIDTH = 4;
```

- Wider than EECS470's 3-wide reference
- Can tune to 2 or 1 for debugging without changing architecture
- **Why:** More ambitious than the reference, demonstrates understanding of superscalar scaling, parameterization is an industry best practice

---

### Decision 4 — ROB + Physical Register File Size
**Choice:** 128-entry ROB, 128 physical registers (96 rename + 32 architectural)

| Structure | Size | Rationale |
|-----------|------|-----------|
| ROB | 128 entries | Long memory latency chains for AI workloads |
| Physical Registers | 128 total | 32 arch + 96 rename; sustains 128 in-flight instructions |
| Free List | 96 entries | Tracks available rename registers |
| Map Table | 32 entries | Speculative rename mappings |
| Arch Map Table | 32 entries | Committed state; used on mispredict recovery |

- **Why 128 ROB:** AI accelerator operations have long DMA latency — larger ROB allows CPU to continue executing other work while waiting

---

### Decision 5 — Branch Predictor
**Choice:** Full TAGE predictor (Seznec 2006), graduated implementation

| Phase | Predictor | Notes |
|-------|-----------|-------|
| v1 placeholder | gshare (2-bit saturating counters) | Simple, fast to implement, correct baseline |
| v1 final | TAGE — 8 tables | Tagged Geometric History lengths |
| Long-term | TAGE-SC-L | Full production predictor with Statistical Corrector + Loop predictor |

- TAGE table geometry: history lengths grow geometrically (e.g., 5, 10, 20, 40, 80, 160, 320, 640 bits)
- Each table: tag + 3-bit saturating counter + useful bit
- **Why:** TAGE is what AMD, Intel, ARM use in production. Learning the full predictor (not just the simple version) is the goal.

---

### Decision 6 — Interconnect
**Choice:** AXI4 Crossbar, parameterized bus width

```systemverilog
parameter int AXI_DATA_WIDTH = 128; // FPGA target
// parameter int AXI_DATA_WIDTH = 256; // Silicon target — one line change
```

- 5 channels: AW (address write), W (write data), B (write response), AR (address read), R (read data)
- VALID/READY handshake on every channel
- Burst transactions supported
- 128-bit for FPGA (Nexys Video DDR3 MIG exposes 128-bit max; 256-bit creates width conversion bottleneck)
- 256-bit for silicon (change one parameter)
- **Why:** Industry standard. Any master connects to any slave through the crossbar. Scales to add GPU, more cores without redesigning the bus.

---

### Decision 7 — Cache Hierarchy + Policy
**Choice:** 3-level exclusive hierarchy

| Level | Size | Associativity | Sets | Notes |
|-------|------|---------------|------|-------|
| L1 ICache | 32KB | 8-way | 64 (2⁶) | Per-core, private |
| L1 DCache | 32KB | 8-way | 64 (2⁶) | Per-core, private, non-blocking |
| L2 | 256KB | 8-way | 512 (2⁹) | Per-core, private |
| LLC | ~1MB | 8-way or 16-way | 2048 (2¹¹) | Shared across all agents |

**Cache line size:** 64 bytes (industry standard)

**Associativity fix:** Originally wanted Apple's 6-way ICache. 32KB / (6 × 64B) = 85.3 sets — not a power of 2, requires modulo indexing. Fixed to 8-way: 32KB / (8 × 64B) = 64 sets = 2⁶. Apple uses 192KB to get clean power-of-2 sets with 6-way. 8-way is strictly better than 6-way in conflict-miss reduction anyway.

**Inclusion Policy:** Exclusive — no data duplication between levels. An eviction from L1 goes to L2; eviction from L2 goes to LLC. Maximizes effective capacity.

**Write Policy:** Write-back, write-allocate (industry standard for performance).

**MSHRs:** Non-blocking caches with MSHR (Miss Status Holding Registers) for multiple outstanding misses.

---

### Decision 7b — Cache Coherency
**Choice:** MESI snooping protocol (v1), directory-based (v2)

| State | Meaning |
|-------|---------|
| M (Modified) | Dirty, owned exclusively, must write back on eviction |
| E (Exclusive) | Clean, owned exclusively |
| S (Shared) | Clean, may exist in multiple caches |
| I (Invalid) | Not present / stale |

- Reservation sets added to support A-extension atomics (LR/SC)
- v2 upgrades to directory-based coherency when scaling beyond 2–4 cores

---

### Decision 7c — BRAM Budget (Nexys Video FPGA)
**Total BRAM available:** ~1,642KB

| Structure | BRAM Used |
|-----------|-----------|
| L1 ICache (32KB) | 32KB |
| L1 DCache (32KB) | 32KB |
| L2 Cache (256KB) | 256KB |
| LLC (~1MB) | 1,024KB |
| CPU structures (ROB, RS, RF, etc.) | ~75KB |
| GPU reservation | ~30KB |
| **Total used** | **~1,449KB** |
| **Headroom** | **~193KB** |

Fits comfortably. AI accelerator scratchpad uses BRAM too — size TBD during implementation.

---

### Decision 8 — AI Accelerator Architecture
**Choice:** Systolic array, weight-stationary dataflow

| Parameter | v1 | Future |
|-----------|----|----|
| Array size | 8×8 PEs | 32×32 on more powerful FPGA |
| Data type | INT8 | INT8 → INT4 → FP16 → BF16 roadmap |
| Scratchpad | On-chip SRAM | Feeds array without hitting DRAM every cycle |
| Operation | GEMM (matrix multiply) | Convolution, attention (roadmap) |

- Each PE: multiply-accumulate (MAC) unit
- Weight-stationary: weights loaded into PEs once, activations stream through
- Output written back to scratchpad, then DMA'd to memory

---

### Decision 8e — CPU–Accelerator Interface
**Choice:** Hybrid custom instruction + DMA

```
CPU                          Accelerator
 |                               |
 |-- custom0 instruction ------> | (configure: matrix dims, data addr, op type)
 |-- custom0 instruction ------> | (trigger: start GEMM)
 |                               |
 |   CPU continues executing     |
 |                               |
 |          DMA Engine <-------> | (autonomously streams weights + activations)
 |                               |
 |<-- interrupt ----------------| (GEMM complete, result in scratchpad)
```

- **Custom RISC-V instruction** (custom0 opcode space): CPU configures and triggers the accelerator
- **DMA engine**: handles actual weight/activation data movement autonomously
- **Interrupt**: signals completion back to CPU
- CPU enqueues operation and continues — conceptually mirrors NVIDIA's CUDA command-queue model, but fixed-function (systolic array) rather than general-purpose GPU
- **Why hybrid:** Pure memory-mapped I/O is too slow for configuration. Pure DMA misses the low-latency trigger. Custom instruction + DMA is what TPU/Apple Neural Engine style designs use.

---

### Decision 9 — GPU Architecture Vision (Post-Summer Block)

**Choice:** SIMT, parameterized multi-SM, GPU-private L2 → shared LLC

```systemverilog
parameter int NUM_SMS        = 1;   // v1: start with 1, designed to scale to 4
parameter int WARP_SIZE      = 32;  // NVIDIA parity
parameter int WARPS_PER_SM   = 4;   // 4 concurrent warps in flight (latency hiding)
parameter int SHADER_CORES   = 8;   // ALUs per SM
```

**Model:** SIMT (Single Instruction, Multiple Threads) — same granularity as NVIDIA CUDA. 32 threads per warp — exact NVIDIA parity, maps 1:1 to how CUDA programmers think, perfect 128-byte cache line coalescing (32 × 4B).

**SM structure (per SM):**
- Warp scheduler (switches warps when one stalls on memory — key GPU latency-hiding mechanism)
- Register file: 32 threads × 4 warps × 32 registers × 4 bytes = **16KB per SM**
- Shader cores (ALUs, SFUs, load/store units)
- SM-local shared memory / L1

**Shared infrastructure (designed once, serves all SMs):**
- Thread block scheduler — dispatches thread blocks to whichever SM has free warp slots
- GPU-private L2 cache — shared across all SMs via internal crossbar
- Memory coalescing unit (per SM) — merges 32 thread addresses into cache-line-aligned AXI4 requests

**Memory connection (Option B):**
```
GPU SMs → GPU-private L2 → AXI4 crossbar → shared LLC → Memory Controller
```
GPU-private L2 prevents GPU's streaming access pattern (large activation/weight tensors) from evicting CPU data in the shared LLC. CPU and GPU share only LLC and memory controller.

**Scalability:** Design for N SMs, instantiate 1 in v1. Adding SM #2 = change `NUM_SMS = 2`. Thread block scheduler and GPU L2 crossbar handle distribution automatically.

**BRAM budget at 4 SMs:** 4 × 16KB register file = 64KB — fits within headroom.

**Why:** SIMT with 32-thread warps is the architecture behind CUDA, ROCm, and Metal. Interview story at NVIDIA/AMD/Apple covers warp scheduling, divergence handling, memory coalescing — all present even with 1 SM. Scalable design means v2 GPU is additive, not a redesign.

---

### Decision 10 — Peripheral Set

**Choice:** UART + Timer + PLIC + GPIO + SPI

All five are memory-mapped AXI4 slaves (control/status registers on the bus).

| Peripheral | Purpose | Notes |
|------------|---------|-------|
| UART | Serial console — `printf()` debug output | Mandatory for any useful debugging |
| Timer | Hardware clock — benchmarking, timeouts | RISC-V mtime/mtimecmp registers |
| PLIC | Platform-Level Interrupt Controller | Routes interrupts (timer, DMA, accelerator completion) to CPU. RISC-V standard. |
| GPIO | General-purpose I/O — LEDs, buttons, switches on Nexys Video | Simple status indicators during debug |
| SPI | SD card access — load programs without recompiling bitstream | Master-mode only for v1 |

**Address map (to be finalized during implementation):**
```
0x1000_0000  UART
0x1000_1000  Timer (mtime / mtimecmp)
0x0C00_0000  PLIC  (RISC-V standard base address)
0x1000_2000  GPIO
0x1000_3000  SPI
```

**Post-v1 peripherals (on IP roadmap):** Ethernet MAC, I2C, PCIe.

---

### Decision 11 — Software Stack / Programming Model

**Three-layer stack, each layer built incrementally.**

#### Layer 1: Boot / Runtime — Graduated bare-metal → SBI

Start minimal, build upward only when the hardware foundation is solid:

| Phase | What runs | Complexity |
|-------|-----------|------------|
| v1a | Assembly reset stub at `0x8000_0000` → `main()` | ~20 lines asm |
| v1b | M-mode trap handler (timer interrupts, accelerator completion interrupts) | ~100 lines C |
| v2 | Full SBI-style firmware (M-mode), application in S-mode | Pre-Linux step |

Reset vector: `0x8000_0000`  
Stack pointer init + BSS zeroing + jump to C `main()` — then real code.

#### Layer 2: Peripheral Drivers — Thin C, memory-mapped register wrappers

One file per peripheral, ~50–100 lines each. Memory-mapped register macros:

```c
// uart.c — representative example
#define UART_BASE    0x10000000
#define UART_TX      (*(volatile uint32_t*)(UART_BASE + 0x00))
#define UART_STATUS  (*(volatile uint32_t*)(UART_BASE + 0x04))

void uart_putc(char c) {
    while (!(UART_STATUS & 0x1));
    UART_TX = c;
}
```

Files: `uart.c`, `timer.c`, `gpio.c`, `spi.c`, `plic.c`

These are also the primary hardware verification artifacts — if the driver works, the peripheral RTL is correct.

#### Layer 3: Accelerator API — Thin C (mirrors cuBLAS / Apple ANE model)

```c
// aether_accel.h
void aether_gemm(int8_t* A, int8_t* B, int8_t* C, int M, int N, int K);
void aether_conv2d(int8_t* input, int8_t* weights, int8_t* output,
                   int H, int W, int C_in, int C_out, int ksize);
```

Internally: configures accelerator via custom0 instruction → sets up DMA transfer → waits on interrupt → returns. Programmer never touches hardware directly. This is the demo-able, interview-ready ML inference API.

---

### Decision 12 — Memory Controller Interface

#### 12a: Address Map

```
0x0000_0000 - 0x0000_3FFF   Boot ROM (4KB on-chip BRAM)
0x0C00_0000 - 0x0FFF_FFFF   PLIC (RISC-V standard base address)
0x1000_0000 - 0x1000_0FFF   UART
0x1000_1000 - 0x1000_1FFF   Timer (mtime / mtimecmp)
0x1000_2000 - 0x1000_2FFF   GPIO
0x1000_3000 - 0x1000_3FFF   SPI
0x8000_0000 - 0xFFFF_FFFF   DRAM (Nexys Video: 512MB DDR3, mapped here)
```

Reset vector: `0x8000_0000` (start of DRAM) — compatible with RISC-V Linux convention, address map stays valid when OS is added later.

#### 12b: MIG Interface Wrapper

Nexys Video DDR3 MIG exposes a **128-bit AXI4 slave interface**. Thin wrapper (~200 lines SV) handles:
- AXI4 ID remapping (MIG has limited ID width)
- Transaction queue for outstanding requests
- ECC error reporting (optional)

This is one of the first RTL blocks built — nothing works without memory.

#### 12c: Boot ROM Strategy — Graduated (simulation first, ROM second)

| Phase | Boot mechanism |
|-------|---------------|
| Verilator simulation | Jump directly to `0x8000_0000` — simulator pre-loads DRAM |
| FPGA bring-up | Small 4KB BRAM boot ROM at `0x0000_0000` initializes MIG, loads application from SD card via SPI, jumps to `0x8000_0000` |

Boot ROM needed because SPI load requires something running before DRAM is initialized. Simulation skips it entirely — Verilator loads ELF files directly into memory model.

---

### Decision 13 — Repository Structure & Coding Standards

#### Learning Philosophy
Human-led design throughout. AI (Claude) acts as a trusted engineer/advisor — explains reasoning, reviews work, answers questions. AI does NOT generate RTL, testbenches, or software. Aashrith writes every line.

#### Repository Name
`custom-soc-project` — kebab-case, descriptive, no special characters.

#### Naming Conventions (strictly enforced)
- **Case:** kebab-case everywhere (directories, files). Lowercase first.
- **Characters:** letters, numbers, hyphens only. No underscores in file/dir names (underscores allowed inside SV identifiers).
- **No spaces** in any path component.
- **File extensions:** `.sv` (SystemVerilog RTL), `.py` (cocotb testbenches), `.xdc` (FPGA constraints), `.md` (docs).
- **Test files:** always under `tb/`, prefixed with `tb-` e.g. `tb-fetch-stage.sv` or `test-fetch-stage.py`.

#### Repository Structure

```
custom-soc-project/
├── .github/
│   ├── workflows/               # GitHub Actions: lint, sim, synthesis CI
│   ├── ISSUE_TEMPLATE/          # Bug report, feature request templates
│   └── PULL_REQUEST_TEMPLATE.md
│
├── docs/
│   ├── decisions/               # Architecture Decision Records (ADRs)
│   ├── diagrams/                # Block diagrams, pipeline diagrams
│   └── CLAUDE.md                # This file — design decision log
│
├── rtl/                         # All synthesizable SystemVerilog
│   ├── cpu/
│   │   ├── fetch/               # fetch-stage.sv, branch-predictor.sv, prefetcher.sv
│   │   ├── decode/              # decode-stage.sv
│   │   ├── rename/              # rename-stage.sv, free-list.sv, map-table.sv
│   │   ├── issue/               # reservation-station.sv, wakeup-select.sv
│   │   ├── execute/             # alu.sv, mul-unit.sv, load-store-unit.sv, branch-unit.sv
│   │   ├── commit/              # rob.sv, commit-stage.sv, arch-map-table.sv
│   │   └── top/                 # cpu-top.sv (integrates all stages)
│   ├── cache/
│   │   ├── l1-icache/           # l1-icache.sv, mshr.sv
│   │   ├── l1-dcache/           # l1-dcache.sv, store-queue.sv, mshr.sv
│   │   ├── l2-cache/            # l2-cache.sv
│   │   └── llc/                 # llc.sv
│   ├── interconnect/
│   │   └── axi4/                # axi4-crossbar.sv, axi4-master.sv, axi4-slave.sv
│   ├── accelerator/
│   │   └── systolic-array/      # systolic-array.sv, pe.sv, dma-engine.sv, accel-top.sv
│   ├── gpu/                     # Post-summer: sm.sv, warp-scheduler.sv, shader-core.sv
│   ├── peripherals/
│   │   ├── uart/                # uart.sv
│   │   ├── timer/               # timer.sv
│   │   ├── gpio/                # gpio.sv
│   │   ├── spi/                 # spi.sv
│   │   └── plic/                # plic.sv
│   ├── memory/
│   │   ├── mem-controller/      # mem-controller.sv, mig-wrapper.sv
│   │   └── boot-rom/            # boot-rom.sv
│   └── soc-top.sv               # Top-level integration: wires everything together
│
├── tb/                          # All testbenches (NOT synthesizable)
│   ├── cpu/
│   │   ├── fetch/               # tb-fetch-stage.sv, test-fetch-stage.py
│   │   ├── decode/
│   │   ├── rename/
│   │   ├── issue/
│   │   ├── execute/
│   │   └── commit/
│   ├── cache/
│   │   ├── l1-icache/
│   │   ├── l1-dcache/
│   │   ├── l2-cache/
│   │   └── llc/
│   ├── interconnect/
│   ├── accelerator/
│   ├── peripherals/
│   └── system/                  # Full-system integration tests
│
├── sim/                         # Simulation infrastructure
│   ├── verilator/               # Verilator build scripts, wrappers
│   └── modelsim/                # ModelSim do-files, waveform configs
│
├── sw/                          # Software running ON the SoC
│   ├── boot/                    # boot.S (reset stub), linker.ld
│   ├── drivers/                 # uart.c, timer.c, gpio.c, spi.c, plic.c
│   ├── accel-api/               # aether-accel.h, aether-gemm.c
│   └── tests/                   # Bare-metal C test programs
│
├── fpga/
│   ├── constraints/             # nexys-video.xdc
│   └── vivado/                  # Vivado project files (not committed — in .gitignore)
│
├── tapeout/
│   └── sky130/                  # OpenLane2 config, GDS, timing reports per IP block
│
├── scripts/                     # Build, lint, run-sim helper scripts
│   ├── lint.sh
│   ├── run-sim.sh
│   └── synth.sh
│
├── .gitignore
├── README.md
├── CONTRIBUTING.md
└── LICENSE                      # MIT or Apache 2.0
```

#### SystemVerilog Module Header (every `.sv` file)

```systemverilog
// ================================================================
// Module  : <module-name>
// Project : custom-soc-project
// Author  : <name>
// Date    : YYYY-MM-DD
// Description:
//   <one or two sentences>
// Dependencies:
//   <list any modules this instantiates>
// ================================================================
```

#### Branching Strategy: GitHub Flow
Simple for a 2-person team. One rule: `main` is always working and simulation-passing.

```
main                  ← stable, all tests pass
feature/cpu-fetch     ← per block, branched from main
feature/l1-icache
feature/axi4-crossbar
```
- Work on a feature branch per IP block
- PR → peer review → merge to `main`
- No direct commits to `main`

#### Commit Message Format
```
<block>: <imperative description>

Examples:
cpu/fetch: add PC register and next-PC mux logic
cache/l1-icache: implement MSHR for non-blocking misses
axi4: wire AR channel handshake
```

#### .gitignore (key entries)
```
# Vivado generated files
*.jou, *.log, vivado/
# Simulation artifacts
sim/verilator/obj_dir/
*.vcd, *.fst
# Python cache
__pycache__/, *.pyc
# OS files
.DS_Store, Thumbs.db
```

#### GitHub Actions CI (runs on every PR)
1. **Lint:** Verilator `--lint-only` on all `.sv` files
2. **Simulate:** Run cocotb testbenches for modified blocks
3. **Report:** Post pass/fail summary on PR

#### GitHub Topics (add to repo)
`risc-v`, `system-on-chip`, `systemverilog`, `computer-architecture`, `fpga`, `out-of-order`, `ai-accelerator`, `cache`, `axi4`, `verilator`

---

### Decision 14 — Implementation Order

**Core principle:** Aashrith writes every line. Claude explains, reviews, and advises. No step is "done" until its testbench passes and the reasoning behind every design choice is understood.

---

#### Phase 1 — Infrastructure (Week 1)

| Step | Task | Why this order |
|------|------|----------------|
| 1 | Create GitHub repo, branching rules, README, .gitignore, CONTRIBUTING.md | Everything else depends on having a repo |
| 2 | Install Verilator, run `--lint-only` on a hello-world SV module | Confirm toolchain works before writing real RTL |
| 3 | Set up cocotb, write trivial testbench (toggle a counter, check output) | Prove the simulation environment end-to-end |
| 4 | Write Makefile (`make lint`, `make sim`, `make clean`) + GitHub Actions CI YAML | Automated CI from day 1 — broken code can never sneak into main |
| 5 | Define AXI4 SystemVerilog interface (signal bundle only, zero logic) | Every bus-connected module needs this "plug shape" before it's built |

---

#### Phase 2 — CPU Core (Weeks 2–4)

Each stage gets its own cocotb testbench before moving to the next.

| Step | Task | Why this order |
|------|------|----------------|
| 6 | Fetch stage — PC register, PC+4, stall/flush signals | First stage in the pipeline; everything feeds from here |
| 7 | Decode stage — RV64IMAC opcode decode, control signals | Purely combinational; test exhaustively before rename |
| 8 | Free list — circular buffer of available physical register tags | Rename depends on this; build it standalone first |
| 9 | Map table + architectural map table | Rename depends on this; standalone test before integration |
| 10 | Rename stage — wires decode → free list + map table → dispatch | Integrates steps 8–9; test RAW/WAW/WAR elimination |
| 11 | ROB — circular buffer, allocate at dispatch, commit in-order at head | Core of precise state; test fill/drain/out-of-order complete |
| 12 | Reservation station — wakeup (CDB tag match), select (oldest ready) | Depends on ROB tags; test wakeup/select logic in isolation |
| 13 | ALU — all RV64I integer ops | Purely combinational; test every opcode vs Python golden model |
| 14 | Multiply unit — RV64M (MUL, MULH, DIV, REM) | Multi-cycle; test against Python `//` and `%` |
| 15 | Branch unit — condition eval + target calc for all branch types | Test all 6 branch conditions + JAL + JALR |
| 16 | Load/store unit + store queue | Address calc + 8-entry store queue with load forwarding |
| 17 | CDB — result broadcast + arbitration (two FUs complete same cycle) | Wiring + priority logic; test simultaneous broadcast |
| 18 | Commit stage — in-order retire, arch map table update, misprediction recovery (flush + redirect PC) | Hardest CPU piece; test precise exception restoration |

---

#### Phase 3 — Memory System (Weeks 4–5)

| Step | Task | Why this order |
|------|------|----------------|
| 19 | L1 ICache — 32KB, 8-way, 64 sets, BRAM-backed, non-blocking with MSHRs | ICache before DCache — simpler (read-only) |
| 20 | L1 DCache — 32KB, 8-way, write-back/write-allocate, store queue integration, MSHRs | More complex than ICache; builds on the same MSHR pattern |
| 21 | L2 cache — 256KB, 8-way, exclusive (receives L1 evictions) | Sits behind L1; test L1→L2 eviction path |
| 22 | LLC — ~1MB, shared, connects to AXI4 bus | Last in the hierarchy; test full miss path L1→L2→LLC→memory |
| 23 | Replace memory stub in CPU testbench with real caches | First full pipeline simulation with real memory |

---

#### Phase 4 — Branch Predictor + Full CPU Integration (Week 5)

| Step | Task | Why this order |
|------|------|----------------|
| 24 | gshare branch predictor — 2-bit saturating counters, global history | Placeholder predictor; plug into fetch, measure accuracy |
| 25 | Prefetcher — sequential next-line prefetch | Reduces cold-start ICache miss latency |
| 26 | Full CPU pipeline integration — wire all stages, run real RV64 assembly programs end-to-end | First true end-to-end CPU simulation |
| 27 | TAGE predictor — 8 tables, geometric history lengths, replace gshare | Full production predictor; verify accuracy improves on loop-heavy programs |

---

#### Phase 5 — AI Accelerator (Weeks 6–7)

| Step | Task | Why this order |
|------|------|----------------|
| 28 | Single PE — 8-bit MAC unit | Smallest unit; verify arithmetic correctness in isolation |
| 29 | 8×8 systolic array — 64 PEs, weight-stationary dataflow | Scale from single PE; test against numpy GEMM golden model |
| 30 | DMA engine — AXI4 master, streams weights/activations to scratchpad | Data movement before control; test independently |
| 31 | Custom instruction decode (custom0 opcode) | CPU decode recognizes custom0, extracts fields |
| 32 | Accelerator top — array + DMA + interrupt + control registers, wire to AXI4 | Full GEMM path: custom instruction → DMA → array → interrupt |

---

#### Phase 6 — SoC Integration (Week 7)

| Step | Task | Why this order |
|------|------|----------------|
| 33 | AXI4 crossbar — route CPU + DMA masters to caches + peripherals + memory controller slaves | Crossbar built last because all masters/slaves are now defined |
| 34 | Peripherals — UART, Timer, PLIC, GPIO, SPI (each ~100 lines, AXI4 slave) | Small standalone blocks; PLIC last (needs timer to test interrupt routing) |
| 35 | Memory controller + MIG wrapper — thin AXI4 wrapper around Xilinx MIG | Behavioral DDR3 model for sim; real MIG for FPGA |
| 36 | SoC top (`soc-top.sv`) — wire CPU + accelerator + crossbar + peripherals + memory | Full system integration; simulate a program end-to-end |

---

#### Phase 7 — Software + FPGA (Week 8)

| Step | Task | Why this order |
|------|------|----------------|
| 37 | Boot stub (`boot.S`) — set stack pointer, zero BSS, call `main()`; linker script at `0x8000_0000` | Must run before any C code |
| 38 | Peripheral C drivers — `uart.c`, `timer.c`, `gpio.c`, `spi.c`, `plic.c` | These also verify the hardware (driver works → peripheral RTL correct) |
| 39 | Accelerator C API — `aether_gemm()`, `aether_conv2d()` | High-level interface over custom instruction + DMA |
| 40 | FPGA synthesis in Vivado — fix synthesis issues, meet timing, write XDC constraints | Simulation is clean; FPGA reveals new issues (timing, BRAM mapping) |
| 41 | FPGA bring-up — program Nexys Video, UART hello world, run GEMM test | Final v1 proof |
| 42 | Tiny Tapeout candidate — pick one block (branch predictor or cache controller), full testbench coverage, timing closure, clean docs | First real silicon submission |

---

#### Post-Summer v1 — GPU (after summer foundation is solid)

| Step | Task |
|------|------|
| 43 | GPU architecture study — Stanford CS149 / CMU 15-418 lecture notes |
| 44 | Single shader core — ALU + FP unit, 32-thread SIMD execution |
| 45 | Warp scheduler — tracks 4 warps per SM, switches on stall |
| 46 | Register file — banked, 32 threads × 4 warps × 32 registers |
| 47 | SM top — integrates shader cores + warp scheduler + register file + shared memory |
| 48 | GPU L1 cache (per SM) + GPU L2 (shared across SMs, private to GPU) |
| 49 | Thread block scheduler — dispatches blocks to SM with free warp slots |
| 50 | Memory coalescing unit — merges 32 thread addresses into cache-line-aligned AXI4 requests |
| 51 | GPU top (`NUM_SMS = 1`) — wire SM + L1 + coalescing unit + AXI4 master |
| 52 | Connect GPU to SoC via AXI4 crossbar (GPU → GPU L2 → shared LLC) |
| 53 | GPU driver + simple compute kernel (vector add in "CUDA-style" API) |
| 54 | Scale to `NUM_SMS = 2` — verify thread block scheduler distributes work |

---

#### Post-Summer v1 — Ethernet MAC

| Step | Task |
|------|------|
| 55 | Study IEEE 802.3 Ethernet frame format |
| 56 | MAC TX path — frame assembly, CRC generation, GMII/RGMII interface |
| 57 | MAC RX path — frame parsing, CRC check, error detection |
| 58 | DMA integration — AXI4 master for descriptor-based TX/RX rings |
| 59 | Connect to SoC via AXI4, write a C driver to send/receive frames |
| 60 | Tiny Tapeout submission — Ethernet MAC TX path as standalone IP |

---

#### Post-Summer v2 — DSP Block (FFT / FIR)

| Step | Task |
|------|------|
| 61 | FIR filter — pipelined MAC chain, configurable taps, fixed-point arithmetic |
| 62 | FFT — radix-2 Cooley-Tukey, butterfly unit, twiddle factor ROM |
| 63 | Test against Python scipy.signal golden model |
| 64 | Connect to AXI4 + DMA, write C API (`dsp_fft()`, `dsp_fir()`) |
| 65 | Tiny Tapeout submission — FIR filter as standalone IP |

---

#### Post-Summer v2 — PLL + Clock Distribution

| Step | Task |
|------|------|
| 66 | Study PLL fundamentals — VCO, phase detector, loop filter, divider |
| 67 | Ring oscillator PLL in sky130 (analog design in Xschem + ngspice simulation) |
| 68 | Clock distribution network — H-tree topology, clock gating cells |
| 69 | Integrate PLL output as SoC clock source |
| 70 | Tiny Tapeout submission — ring oscillator PLL |

---

#### Long-Term — PCIe + SerDes + RF

| Step | Task |
|------|------|
| 71 | PCIe controller — TLP parsing, link training, AXI4 bridge |
| 72 | High-speed SerDes PHY — CDR, equalizer, 8b/10b encoding |
| 73 | RF digital baseband — OFDM modulator/demodulator, matched filter |

---

#### v2 SoC Upgrades (parallel to above)

| Step | Task |
|------|------|
| — | Cache coherency upgrade: MESI snooping → directory-based (scales beyond 4 cores) |
| — | Interconnect upgrade: AXI4 crossbar → ring interconnect |
| — | Multi-core: add CPU core #2, verify coherency protocol handles shared data |
| — | Boot upgrade: bare-metal → full SBI firmware (OpenSBI port) |
| — | OS bring-up: Linux boots on the SoC (requires MMU + S-mode + SBI) |
| — | Interconnect v3: ring → mesh NoC (many-core scaling) |

---

## Decisions Still Pending

- Final comprehensive spec document generation (Claude Code-ready)

---

## Background & Learning Philosophy

### Aashrith's Starting Background
| Skill | Level | Relevance |
|-------|-------|-----------|
| C | Strong (OS, computer architecture courses) | Drivers, bootloader, software stack — transfers directly |
| C++ | Beginner | Needed for Verilator testbench harness — simple usage only |
| Verilog | Intermediate (EE316 at UT Austin, Prof. Orshansky — Boolean algebra, combinational/sequential logic, FSMs, datapath components, ALU, register files, RTL design, timing; Labs: decoders/muxes, Basys3 FPGA, sequential logic, calculator, stopwatch/timer processor) | SystemVerilog is a superset — everything transfers |
| Python | Beginner | cocotb testbenches — async/await + basic scripting needed |
| Java | Experience | Largely irrelevant here, but shows language adaptability |

### Key Verilog → SystemVerilog Syntax Changes (reference)
| Verilog (old) | SystemVerilog (use this) | Notes |
|---------------|--------------------------|-------|
| `reg`, `wire` | `logic` | One type for everything |
| `always @(posedge clk)` | `always_ff @(posedge clk)` | Explicit flip-flop intent |
| `always @(*)` | `always_comb` | Explicit combinational intent |
| Positional port connections | Named: `.port(signal)` | Never use positional |
| No parameters | `parameter int WIDTH = 8` | Use for all configurable values |

### Learning Philosophy
- **Human-led always.** Aashrith writes every line of RTL, testbench, and software. Claude explains, reviews, and advises — never generates production code.
- **Learn as you do.** Concepts are introduced when they're needed, not front-loaded. The goal is understanding anchored to a real problem.
- **Master the tools.** For every tool used: what it is, why it's used, how to use it properly. No black boxes.
- **Replicable knowledge.** The learning from this project should let Aashrith start a new project independently in the future.

### Tool-by-Tool Learning Roadmap

| Tool | When Needed | Learn Via |
|------|-------------|-----------|
| SystemVerilog (upgrade from Verilog) | Week 1 | ChipVerify (chipverify.com) — free, structured |
| Git + GitHub | Week 1, Day 1 | GitHub "Hello World" guide (30 min) |
| GitHub Actions (CI YAML) | Week 1, Day 2–3 | Explained line-by-line when writing the workflow file |
| Verilator (lint + simulation) | Week 1 | Verilator docs + guided walkthrough on first use |
| Make / Makefile | Week 1–2 | Already familiar from C; 20-line file covers it |
| cocotb (Python testbenches) | Week 2 | cocotb "Getting Started" guide — do once with a counter |
| C++ (Verilator harness) | Week 2+ | LearnCpp.com Chapters 1–9, 15 — 3–4 hours |
| RISC-V GCC toolchain | Week 7 | Covered by existing arch background; linker scripts are new but small |
| RISC-V Assembly (boot stub) | Week 7 | Patterson & Hennessy RISC-V book; LC3 knowledge transfers |
| Vivado (FPGA synthesis) | Week 6–7 | GUI-guided; full walkthrough on first use |
| OpenLane2 (tapeout) | Post-summer | Tiny Tapeout docs + Zero to ASIC course |

**Key insight:** SystemVerilog is a strict superset of Verilog. The stopwatch code would compile in an SV toolchain unchanged. You're upgrading, not starting over.

**Week 1 learning order (exact):**
1. Days 1–2: Git + GitHub (repo setup, branching)
2. Days 2–3: SystemVerilog new constructs (ChipVerify)
3. Days 3–4: Verilator lint on a simple module
4. Days 4–5: cocotb "getting started" with a trivial example
5. Day 5: Write Makefile + GitHub Actions CI

End of week 1: working environment, automated CI, full tool understanding. Week 2: real RTL.

---

## Technology Stack

| Layer | Tool |
|-------|------|
| HDL | SystemVerilog |
| Simulation | Verilator (fast) + ModelSim/QuestaSim (waveform debug) |
| Verification | cocotb (Python-based testbenches) → UVM for complex blocks |
| FPGA Synthesis | Vivado (AMD/Xilinx) |
| Tapeout Flow | OpenLane2 + sky130 PDK (Tiny Tapeout) |
| Analog | Xschem + ngspice |
| PCB | KiCad |

---

## FPGA Target

**Nexys Video (Xilinx Artix-7 XC7A200T)**
- ~1,642KB BRAM
- Sufficient LUT count for full v1 SoC
- DDR3 memory controller (MIG) exposes 128-bit AXI interface
- Recommended purchase: ~$350 range (check UT Austin ECE labs first — may have loaners)

---

## Tiny Tapeout Strategy

- Submit individual verified IP blocks per round (~2–3× per year)
- Round 1 target: small, well-verified block (cache controller, DSP, or PLL)
- Round 2+: CPU subcomponents (branch predictor, ROB, issue queue), then full cores
- sky130 PDK, ~160µm × 100µm per submission
- Full SoC cannot fit in one submission — modular strategy is intentional

---

## Division of Work

| Person A | Person B |
|----------|----------|
| Microarchitecture: CPU pipeline, cache controller, accelerator RTL | Verification: cocotb testbenches, assertion suites, debug infrastructure |
| AXI4 bus and interconnect design | OpenLane flow, Tiny Tapeout submissions |
| GPU shader core (post-summer) | PCB carrier board (post-summer) |

---

## Key Resources

| Topic | Resource |
|-------|----------|
| SystemVerilog | HDLBits (hdlbits.01xz.net), ChipVerify |
| Computer Architecture | Patterson & Hennessy *Computer Org & Design: RISC-V Edition* |
| Cache Coherency | *A Primer on Memory Consistency and Cache Coherence* — Nagarajan et al. (free PDF) |
| AXI4 / Bus Design | ARM AMBA AXI4 spec (free) + ZipCPU.com |
| TAGE Branch Predictor | Seznec 2006 paper ("A case for (partially) TAgged GEometric history length branch prediction") |
| GPU Architecture | Stanford CS149 / CMU 15-418 lecture notes (free online) |
| Verification | cocotb.org documentation |
| Tapeout | Tiny Tapeout docs + Zero to ASIC Course (Matt Venn) |
| Reference OoO Design | EECS470 (U. Michigan) — 3-wide RV32IM OoO, 4 students, 6 weeks, no AI |

---

## Tool Workflow

| Situation | Tool |
|-----------|------|
| Writing RTL, debugging, running lint/sim | Claude Code (`claude` in terminal inside repo) |
| Design decisions, architecture questions, learning new concepts | Claude Chat or Cowork |
| Updating CLAUDE.md after decisions | Claude Code (edits the file directly) or Cowork |

Claude Code reads `docs/CLAUDE.md` automatically at session start — full context restored instantly. No pasting needed.

---

*Last updated: June 28, 2026 — Repo created, folder structure done. Currently on Week 1 infrastructure. Next: counter.sv → lint → cocotb test → Makefile → CI.*
