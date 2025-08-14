set_global_assignment -entity "LVDSPLL" -library "lib_LVDSPLL" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "LVDSPLL" -library "lib_LVDSPLL" -name IP_TOOL_VERSION "24.1"
set_global_assignment -entity "LVDSPLL" -library "lib_LVDSPLL" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_LVDSPLL" -name SPD_FILE [file join $::quartus(sip_path) "LVDSPLL.spd"]

set_global_assignment -library "lib_LVDSPLL" -name MISC_FILE [file join $::quartus(sip_path) "LVDSPLL_sim/LVDSPLL.vo"]
