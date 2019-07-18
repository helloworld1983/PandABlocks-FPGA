#
# Generate top-level firmware
#

set TOP_DIR    [lindex $argv 0]
set TARGET_DIR [lindex $argv 1]
set BUILD_DIR  [lindex $argv 2]
set AUTOGEN    [lindex $argv 3]
set IP_DIR     [lindex $argv 4]
set PS_CORE    [lindex $argv 5]
# Vivado run mode - gui or batch mode
set MODE       [lindex $argv 6] 


set_param board.repoPaths $TARGET_DIR/configs


# Create project (in-memory if not in gui mode)

if {[string match "gui" [string tolower $MODE]]} {
    create_project -part xc7z020clg484-1 -force \
      carrier_fpga_top $BUILD_DIR/carrier_fpga_top 
} else {
    create_project -part xc7z020clg484-1 -force -in_memory \
      carrier_fpga_top $BUILD_DIR/carrier_fpga_top
}

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Set project properties
set obj [get_projects carrier_fpga_top]
set_property "board_part" "em.avnet.com:zed:part0:1.3" $obj
set_property "default_lib" "xil_defaultlib" $obj
set_property "simulator_language" "Mixed" $obj
set_property "target_language" "VHDL" $obj

#
# Warning suppression
#
# Suppress Verilog file related warnings
set_msg_config -id {[Synth 8-2644]} -suppress

# Elevate critical warnings
set_msg_config -severity "CRITICAL WARNING" -new_severity ERROR

#add_files $TARGET_DIR/const/panda-timing.xdc
add_files $TARGET_DIR/const/ZedBoard-physical.xdc
add_files $TARGET_DIR/const/panda-post_synth.xdc
set_property used_in_synthesis false \
    [get_files $TARGET_DIR/const/ZedBoard-physical.xdc]
set_property used_in_synthesis false \
    [get_files $TARGET_DIR/const/panda-post_synth.xdc]

#
# STEP#1: setup design sources and constraints
#
# Import IPs

source $AUTOGEN/const/constraints.tcl
set_property used_in_synthesis false -quiet [get_files *_impl.xdc]

# Read Zynq block design
read_bd   $PS_CORE

# Read auto generated files
add_files [glob $AUTOGEN/hdl/*.vhd]

# Read design files

add_files [glob $TOP_DIR/common/hdl/defines/*.vhd]
add_files [glob $TOP_DIR/common/hdl/*.vhd]
add_files [glob $TARGET_DIR/hdl/*.vhd]
add_files [glob $TARGET_DIR/hdl/defines/*.vhd]

# Exit script here if gui mode - i.e. if running 'make carrier_fpga_gui'
if {[string match "gui" [string tolower $MODE]]} { return }

#
# STEP#2: run synthesis, report utilization and timing estimates, write
# checkpoint design
#
synth_design -top ZedBoard_top -flatten_hierarchy rebuilt
write_checkpoint -force post_synth
report_timing_summary -file post_synth_timing_summary.rpt

#
# STEP#3: run placement and logic optimisation, report utilisation and timing
# estimates, write checkpoint design
#
opt_design -directive Explore

place_design -directive Explore
phys_opt_design -directive Explore
write_checkpoint -force post_place
report_timing_summary -file post_place_timing_summary.rpt
write_debug_probes -force carrier_fpga_top.ltx

#
# STEP#4: run router, report actual utilization and timing, write checkpoint
# design, run drc, write verilog and xdc out
#
route_design -directive Explore

write_checkpoint -force post_route
report_utilization -file post_route_utilization_summary.rpt

set timingreport \
    [report_timing_summary -no_header -no_detailed_paths -return_string \
        -file post_route_timing_summary.rpt]

if {! [string match -nocase {*timing constraints are met*} $timingreport]} {
    send_msg_id showstopper-0 error "Timing constraints weren't met."
    return -code error
}

# STEP#post5: report IO
report_io -verbose -file post_route_report_io.rpt

#
# STEP#5: generate a bitstream
#
write_bitstream -force panda_top.bit

close_project
exit
