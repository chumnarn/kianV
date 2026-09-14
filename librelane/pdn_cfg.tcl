source $::env(SCRIPTS_DIR)/openroad/common/set_global_connections.tcl
set_global_connections

set_voltage_domain -name CORE -power VDD -ground VSS

define_pdn_grid -name stdcell_grid -starts_with POWER -voltage_domain CORE
add_pdn_stripe -grid stdcell_grid -layer Metal1 -width 0.44 -followpins
add_pdn_stripe -grid stdcell_grid -layer Metal2 -width 3.0 -pitch 75.0 -offset 10.0 -spacing 1.0 -starts_with POWER -extend_to_core_ring
add_pdn_stripe -grid stdcell_grid -layer Metal3 -width 3.0 -pitch 75.0 -offset 10.0 -spacing 1.0 -starts_with POWER -extend_to_core_ring
add_pdn_connect -grid stdcell_grid -layers {Metal1 Metal2}
add_pdn_connect -grid stdcell_grid -layers {Metal2 Metal3}

add_pdn_ring -grid stdcell_grid -layers {TopMetal1 TopMetal2} \
  -widths {15 15} -spacings {5 5} -core_offset {20 20} -connect_to_pads
add_pdn_connect -grid stdcell_grid -layers {Metal2 TopMetal1}
add_pdn_connect -grid stdcell_grid -layers {Metal3 TopMetal2}
add_pdn_connect -grid stdcell_grid -layers {TopMetal1 TopMetal2}

set sram_instances {
  i_chip_core.u_soc.cache_I.gen_cached.icache_I.cache_I.u_mem_way0.sram_lo
  i_chip_core.u_soc.cache_I.gen_cached.icache_I.cache_I.u_mem_way0.sram_hi
  i_chip_core.u_soc.cache_I.gen_cached.icache_I.cache_I.u_mem_way1.sram_lo
  i_chip_core.u_soc.cache_I.gen_cached.icache_I.cache_I.u_mem_way1.sram_hi
  i_chip_core.u_soc.cache_I.gen_cached.dcache_I.cache_D.u_mem.sram_lo
  i_chip_core.u_soc.cache_I.gen_cached.dcache_I.cache_D.u_mem.sram_hi
}
define_pdn_grid -macro -instances $sram_instances -name sram_grid -starts_with POWER
add_pdn_stripe -grid sram_grid -layer Metal5 -width 2.81 -pitch 11.24 -offset 2.81 -spacing 2.81 -nets {VSS VDD} -starts_with POWER
add_pdn_connect -grid sram_grid -layers {Metal4 Metal5}
add_pdn_connect -grid sram_grid -layers {Metal5 TopMetal1}

