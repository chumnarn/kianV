# KianV RV32IMA/Sv32 full-chip implementation on IHP SG13G2

This project ports KianV Linux/XV6 SoC from GF180MCU to an IHP SG13G2 pad-ring
ASIC using LibreLane 3.x and YAML configuration. The imported RTL is pinned to
upstream commit `d7370740d2c20cb4b00dd6d043f328290cb48b73`; see `UPSTREAM.lock`.

## Scope and implementation status

The integrated CPU implements RV32IMA with Sv32 address translation and the
Zicntr, Zicsr, Zifencei and Sstc-related machine/supervisor support present in
the pinned KianV RTL. The SoC contains UART, two SPI controllers, SPI-NOR boot,
GPIO, CLINT, PLIC, an SDR SDRAM controller, a two-way I-cache and a D-cache.

This deliverable contains all project RTL, the IHP pad wrapper, cache-SRAM
adapter, explicit macro placement, PDN, SDC, simulation smoke test, preflight
script and LibreLane configuration. It intentionally does not copy PDK files;
LibreLane resolves those from the installed `ihp-sg13g2` PDK.

Validation performed on the delivered tree:

* YAML parsing and LibreLane v3 schema header
* existence of every RTL path in `VERILOG_FILES`
* exactly 60 explicitly placed pads, 15 on each side
* exactly six explicitly placed IHP SRAM instances
* behavioral SRAM test is included and runs automatically when Icarus Verilog
  is installed

An end-to-end GDS run still depends on the user's installed LibreLane/PDK
versions and available RAM/CPU resources. Sign-off DRC/LVS results must never be
claimed until the full run completes in that environment.

## Architecture and physical choices

The external interface uses 54 unified bidirectional pads plus clock and reset.
The index map is kept identical to the pinned upstream `chip_core.sv`:

| Pad indices | Function | Direction |
|---|---|---|
| 0 | UART RX | input |
| 1 | SPI0 MISO | input |
| 2 | SPI-NOR MISO | input |
| 3 | SPI1 MISO | input |
| 4 | UART TX | output |
| 5–7 | SPI0 CS/SCLK/MOSI | output |
| 8–10 | SPI-NOR CS/SCLK/MOSI | output |
| 11–13 | SPI1 CS/SCLK/MOSI | output |
| 14–36 | SDRAM clock/control/address | output |
| 37–52 | SDRAM DQ[15:0] | bidirectional |
| 53 | GPIO0 | bidirectional |

Reset is asserted asynchronously at the pad boundary and released through the
KianV `async_reset_sync` circuit. Output enables are forced low during reset so
the external bus is not driven during reset release.

The GF180 implementation used 21 instances of a 512x8 SRAM. SG13G2 instead uses
six `RM_IHPSG13_1P_1024x32_c2_bm_bist` macros:

* two macros form each logical 512x56 cache store;
* I-cache way 0, I-cache way 1, and D-cache use one logical store each;
* address bit 9 is tied low, so only the lower 512 rows are used;
* eight physical data bits are unused in each 64-bit pair;
* SRAM access remains synchronous with one-cycle macro latency.

The 2800 x 2800 um die and 2070 x 2070 um core are conservative starting
points. They are not a tapeout guarantee; inspect utilization, congestion,
antenna, IR-drop and timing reports before shrinking the floorplan.

## Prerequisites

Recommended environment:

* Linux or WSL2
* Nix with flakes enabled
* LibreLane 3.x
* IHP Open PDK installed under the LibreLane-supported PDK root
* at least 32 GB RAM; 64 GB is preferable for full sign-off

Enter the reproducible environment shipped with the IHP template:

```bash
nix develop
librelane --version
```

The included flake pins LibreLane 3.0.0, which satisfies the requested 3.x
configuration format. To use a locally newer LibreLane 3.x, enter that
environment instead and run `make preflight` before synthesis.

Confirm that the SRAM views exist:

```bash
find "${PDK_ROOT:-$HOME/.ciel}" -name 'RM_IHPSG13_1P_1024x32_c2_bm_bist.lef' -print
find "${PDK_ROOT:-$HOME/.ciel}" -name 'RM_IHPSG13_1P_1024x32_c2_bm_bist*.lib' -print
```

## Directory map

```text
src/                         pinned KianV RTL and IHP integration RTL
src/chip_top.sv              IHP 60-pad top level
src/chip_core.sv             SoC-to-pad function map
src/sram_sp_ihp_512x56.v     two-macro logical cache SRAM
librelane/config.yaml        LibreLane v3 Chip-flow configuration
librelane/chip_top.sdc       clock and external I/O timing constraints
librelane/pdn_cfg.tcl        core ring, rails and SRAM PDN grids
ip/bondpad_70x70_novias/     bond-pad LEF/GDS/model from IHP template
sim/tb_sram.sv               deterministic SRAM adapter smoke test
scripts/preflight.sh         static project checks and optional simulation
```

## Step-by-step run

### 1. Verify the immutable source baseline

```bash
cat UPSTREAM.lock
```

The original source can be compared independently with:

```bash
git clone https://github.com/splinedrive/gf180mcu-kianv-rv32ima-sv32.git upstream
git -C upstream checkout d7370740d2c20cb4b00dd6d043f328290cb48b73
```

### 2. Run preflight and SRAM simulation

```bash
make preflight
make sim
```

Expected lines include:

```text
PASS: YAML, source paths, 60-pad ring, and six SRAM placements
PASS: IHP 512x56 wrapper behavioral contract
```

The second line appears when `iverilog` is available.

### 3. Synthesize first

Run only through synthesis before spending time on physical design:

```bash
make validate
```

Check the synthesis log for all of the following:

* top module is `chip_top`;
* no unresolved or unmapped KianV module remains;
* exactly six SRAM macro instances remain as black boxes/macros;
* pad instances are preserved;
* no unintended inferred large memory replaces the cache SRAMs;
* clock is found at `clk_pad/p2c` with a 50 ns period.

Useful inspection commands:

```bash
rg -n 'ERROR|unmapped|not found|multiple driver' runs/kianv_ihp_validate
rg -n 'RM_IHPSG13_1P_1024x32' runs/kianv_ihp_validate
```

If the local 3.x release uses a different synthesis step ID, list steps with
`python3 -m librelane.steps` and replace the `--to` target in the Makefile.

### 4. Run the complete Chip flow

```bash
make harden RUN_TAG=kianv_ihp_$(date +%Y%m%d)
```

The equivalent direct command is:

```bash
librelane --pdk ihp-sg13g2 --flow Chip librelane/config.yaml \
  --run-tag kianv_ihp
```

Do not use obsolete OpenLane/LibreLane 2 options such as `--interactive` or
`--override`. For a development run that deliberately skips DRC only:

```bash
librelane --pdk ihp-sg13g2 --flow Chip librelane/config.yaml \
  --run-tag kianv_dev --skip KLayout.DRC --skip Magic.DRC
```

Such a run is not sign-off complete.

### 5. Validate floorplan and macros

At the floorplan/macro-placement stages verify:

* 15 pad cells appear on every side and all four supply pads are present;
* SRAM names exactly match the six paths in `config.yaml`;
* no SRAM overlaps a row, core ring, another macro or pad keepout;
* the I/O ring has continuity for IOVDD/IOVSS and the core has VDD/VSS;
* both `VDD!/VSS!` and `VDDARRAY!/VSS!` connect on every SRAM;
* standard-cell placement has usable channels around all macro edges.

If OpenROAD reports a missing macro instance, stop and copy the synthesized
hierarchical name from the synthesis database into both `MACROS.instances` and
`PDN_MACRO_CONNECTIONS`. Do not weaken macro checking or allow the SRAMs to be
silently flattened.

### 6. Timing closure

The baseline is 20 MHz (`CLOCK_PERIOD: 50.0`). The SDC applies 0.25 ns clock
uncertainty, 0.15 ns transition, 2 ns input delay, 4 ns output delay and
0.033442 pF external load. These are design assumptions, not package-derived
numbers.

Review at least:

```bash
find runs/kianv_ihp -iname '*timing*' -o -iname '*sta*'
rg -n 'slack|violation|unconstrained' runs/kianv_ihp
```

Resolve setup failures by examining the CPU critical path, cache-to-SRAM path,
fanout and routing congestion. Resolve hold at every configured PVT corner.
Changing the target period is an architectural decision and must be recorded.

### 7. Physical sign-off checklist

A tapeout candidate must satisfy all of these independently:

| Check | Acceptance criterion |
|---|---|
| Synthesis | no unresolved modules; six SRAM macros |
| STA | setup/hold clean at all required corners |
| Placement/routing | no overflow or illegal placement |
| Antenna | checker clear or all violations waived with evidence |
| DRC | KLayout and Magic clear under the selected sign-off deck |
| LVS | layout matches powered netlist including pads/SRAMs |
| XOR | stream-out comparison clean where enabled |
| PDN | all four supply domains/pins continuous; no floating SRAM rails |
| IR drop | within project limits using realistic activity/current data |
| GDS | generated from the exact reviewed run tag |

Archive `config.yaml`, SDC, PDK identifier, LibreLane version, run metadata,
reports, final DEF, powered netlist, SPEF and GDS together.

## Common failures

### `macro ... not found`

The hierarchy changed or synthesis flattened a cache wrapper. Confirm
`BYPASS_CACHES=1'b0`, keep hierarchy through SRAM wrappers, and update all
macro/PDN paths atomically from the synthesized hierarchy.

### SRAM read data is shifted or stale

The macro is synchronous. The cache wrappers assume one-cycle read behavior.
Do not replace the adapter with an asynchronous inferred array in synthesis.
`FUNCTIONAL` is only for simulation.

### SRAM writes do not work

For this macro `A_MEN` enables the port, `A_WEN` enables writes, `A_REN`
enables reads, and an all-zero `A_BM` selects all bits. Confirm these polarities
against the datasheet delivered with the exact installed PDK revision.

### PDN failure around SRAM

Check that `Metal4`, `Metal5`, `TopMetal1` and `TopMetal2` exist in the selected
SG13G2 tech and that macro orientations match the custom SRAM grid. Inspect
special-wire connectivity visually and with the PDN checker.

### Routing congestion or resizer maximum-buffer error

Increase die/core area or reduce `PL_TARGET_DENSITY_PCT`; do not immediately
raise the maximum buffer count. Recheck macro channels, high-fanout reset nets,
SDRAM control fanout and timing constraints first.

### KLayout seal-ring `psutil` warning

Install `psutil` in the active Python environment. Treat it as a tooling warning
only after confirming that seal-ring generation itself completed and the final
GDS contains the ring.

## Source and license

KianV RTL is derived from the pinned Apache-2.0 upstream repository. The
pad-ring and bond-pad integration follows the Apache-2.0 IHP LibreLane template.
Individual source headers and `LICENSE` remain authoritative.

### Main Links:
1. [KianV pinned commit](https://github.com/splinedrive/gf180mcu-kianv-rv32ima-sv32/tree/d7370740d2c20cb4b00dd6d043f328290cb48b73),
2. [IHP LibreLane template](https://github.com/IHP-GmbH/ihp-sg13g2-librelane-template)
3.  [IHP SRAM library documentation](https://ihp-open-pdk-docs.readthedocs.io/en/latest/contents/reference_libraries/sram.html)



# ชุดโปรเจกต์ KianV SV32 Full-Chip สำหรับ LibreLane 3.x + IHP SG13G2 

สิ่งที่รวมไว้:

* KianV RTL ครบชุด ตรึงที่ commit `d7370740d2c20cb4b00dd6d043f328290cb48b73`
* RV32IMA + Sv32 MMU + Zicntr/Zicsr/Zifencei/Sstc
* IHP SG13G2 full-chip wrapper
* Pad ring 60 pads ด้านละ 15 pads
* UART, SPI0, SPI1, SPI-NOR, GPIO และ SDRAM interface
* I-cache แบบ 2-way และ D-cache
* SRAM adapter 512×56 โดยใช้ IHP SRAM 1024×32 จำนวน 6 macros
* Macro placement และ PDN connections แบบ explicit
* `config.yaml` สำหรับ LibreLane Chip flow
* SDC เป้าหมายเริ่มต้น 20 MHz
* PDN core ring และ SRAM grids
* Bond-pad LEF/GDS จาก IHP template
* SRAM behavioral testbench
* Preflight script และ Makefile
* คู่มือ step-by-step พร้อม troubleshooting และ sign-off checklist

เริ่มใช้งาน:

```bash
tar -xzf kianv-ihp-sg13g2-fullchip-ready.tar.gz
cd kianv-ihp-sg13g2-fullchip
nix develop

make preflight
make sim
make validate
make harden RUN_TAG=kianv_ihp_$(date +%Y%m%d)
```

ผลตรวจสอบในสภาพแวดล้อมนี้:

```text
PASS: YAML, source paths, 60-pad ring, and six SRAM placements
```

สภาพแวดล้อมปัจจุบันไม่มี Icarus Verilog และ LibreLane executable จึงยังไม่สามารถยืนยันผล end-to-end GDSII, STA, DRC, LVS และ antenna ได้ ต้องรัน `make validate` และ `make harden` ในเครื่องที่ติดตั้ง LibreLane/IHP PDK ก่อนถือว่าเป็น tapeout candidate

แหล่งอ้างอิงหลักคือ [KianV pinned commit](https://github.com/splinedrive/gf180mcu-kianv-rv32ima-sv32/tree/d7370740d2c20cb4b00dd6d043f328290cb48b73), [IHP LibreLane template](https://github.com/IHP-GmbH/ihp-sg13g2-librelane-template) และ [IHP SRAM library documentation](https://ihp-open-pdk-docs.readthedocs.io/en/latest/contents/reference_libraries/sram.html)
