#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir"
python3 - <<'PY'
from pathlib import Path
import yaml
c = yaml.safe_load(Path('librelane/config.yaml').read_text())
assert c['meta']['version'] == 3
assert c['meta']['flow'] == 'Chip'
assert len(c['PAD_SOUTH']) == len(c['PAD_EAST']) == len(c['PAD_NORTH']) == len(c['PAD_WEST']) == 15
assert len(c['MACROS']['RM_IHPSG13_1P_1024x32_c2_bm_bist']['instances']) == 6
for item in c['VERILOG_FILES']:
    p = Path('librelane') / item.removeprefix('dir::')
    assert p.resolve().exists(), p
print('PASS: YAML, source paths, 60-pad ring, and six SRAM placements')
PY
if command -v iverilog >/dev/null; then
  iverilog -g2012 -DFUNCTIONAL -o sim/sram.vvp sim/tb_sram.sv src/sram_sp_ihp_512x56.v
  vvp sim/sram.vvp
else
  echo 'SKIP: iverilog not installed'
fi

