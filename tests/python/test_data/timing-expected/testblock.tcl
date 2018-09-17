# This is a script to add all of the tests and required hdl code for the
# testblock module to the vivado project

set_property SOURCE_SET sources_1 [get_filesets sim_1]

array set tests {
	testblock_1_tb 1
	testblock_2_tb 1
}

# remove any simulation files from the project
remove_files -fileset sim_1 {
	../hdl_timing/testblock/timing001/hdl_timing.v
	../hdl_timing/testblock/timing001/1testblockexpected.csv
	../hdl_timing/testblock/timing002/hdl_timing.v
	../hdl_timing/testblock/timing002/2testblockexpected.csv
}

# add the module vhd code
add_files -norecurse {
	../../modules/testblock/hdl
}

add_files -fileset sim_1 -norecurse {
	../hdl_timing/testblock/timing001/hdl_timing.v
	../hdl_timing/testblock/timing001/1testblockexpected.csv
	../hdl_timing/testblock/timing002/hdl_timing.v
	../hdl_timing/testblock/timing002/2testblockexpected.csv
}