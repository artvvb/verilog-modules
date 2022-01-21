#! vivado -mode batch -source build.tcl
# read all design files
read_verilog ./counter.v
read_verilog ./register.v
read_verilog ./top.v
# read constraints
read_xdc ./locs.xdc
# Synthesize Design
synth_design -top top -part xc7a35ticsg324-1L
# Opt Design 
opt_design
# Place Design
place_design 
# Route Design
route_design
# Write out bitfile
write_bitstream -force ./blinky.bit