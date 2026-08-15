read_liberty /Users/gouthamkrishnan/PDK/OpenROAD-flow-scripts/flow/platforms/nangate45/lib/NangateOpenCellLibrary_typical.lib

read_verilog synthesis/netlist/top_synth.v

link_design fp_network

read_sdc constraints/constraints.sdc

check_setup

report_checks -path_delay max -fields {slew cap input_pin net fanout} -digits 4

report_checks -path_delay min -fields {slew cap input_pin net fanout} -digits 4

report_wns
report_tns

report_clock_properties

report_checks -slack_min 0

report_checks -unconstrained

exit