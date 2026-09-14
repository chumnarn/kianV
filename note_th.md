ชุดโปรเจกต์ KianV SV32 Full-Chip สำหรับ LibreLane 3.x + IHP SG13G2

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

แหล่งอ้างอิงหลักคือ [KianV pinned commit](https://github.com/splinedrive/gf180mcu-kianv-rv32ima-sv32/tree/d7370740d2c20cb4b00dd6d043f328290cb48b73), [IHP LibreLane template](https://github.com/IHP-GmbH/ihp-sg13g2-librelane-template) และ [IHP SRAM library documentation](https://ihp-open-pdk-docs.readthedocs.io/en/latest/contents/reference_libraries/sram.html)
