#=========================================================
# Iris NN Hardware - Yosys Synthesis
# Top Module: fp_network
# Technology: Nangate45
#=========================================================

#---------------------------------------------------------
# Read RTL
#---------------------------------------------------------

read_verilog rtl/fp_adder.v
read_verilog rtl/fp_argmax.v
read_verilog rtl/fp_layer.v
read_verilog rtl/fp_mac.v
read_verilog rtl/fp_multiplier.v
read_verilog rtl/fp_neuron.v
read_verilog rtl/fp_relu.v
read_verilog rtl/fp_network.v

#---------------------------------------------------------
# Set Top Module
#---------------------------------------------------------

hierarchy -check -top fp_network

#---------------------------------------------------------
# RTL Processing
#---------------------------------------------------------

proc
opt

#---------------------------------------------------------
# FSM Optimization
#---------------------------------------------------------

fsm
opt

#---------------------------------------------------------
# Memory Processing
#---------------------------------------------------------

memory
memory_map

#---------------------------------------------------------
# Technology Mapping
#---------------------------------------------------------

techmap
opt

#---------------------------------------------------------
# Flip-Flop Mapping
#---------------------------------------------------------

dfflibmap -liberty /Users/gouthamkrishnan/PDK/OpenROAD-flow-scripts/flow/platforms/nangate45/lib/NangateOpenCellLibrary_typical.lib

#---------------------------------------------------------
# Combinational Logic Mapping
#---------------------------------------------------------

abc -liberty /Users/gouthamkrishnan/PDK/OpenROAD-flow-scripts/flow/platforms/nangate45/lib/NangateOpenCellLibrary_typical.lib

#---------------------------------------------------------
# Final Optimization
#---------------------------------------------------------

clean -purge
opt

#---------------------------------------------------------
# Statistics
#---------------------------------------------------------

stat

stat -liberty /Users/gouthamkrishnan/PDK/OpenROAD-flow-scripts/flow/platforms/nangate45/lib/NangateOpenCellLibrary_typical.lib

#---------------------------------------------------------
# Write Synthesized Netlist
#---------------------------------------------------------

write_verilog -noattr -simple-lhs synthesis/netlist/top_synth.v

#---------------------------------------------------------
# Gate-Level Schematic
#---------------------------------------------------------

select -clear
select fp_network

show -format svg -prefix synthesis/top_gate