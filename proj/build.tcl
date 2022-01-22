#! vivado -mode batch -source build.tcl -tclargs ./blinky.bit
# read all design files
foreach f [glob -nocomplain ./*.v] {
    read_verilog ${f}
}
foreach f [glob -nocomplain ./*.vhd] {
    read_vhdl ${f}
}
# read constraints
foreach f [glob -nocomplain ./*.xdc] {
    read_xdc ${f}
}
# Synthesize Design
synth_design -top top -part xc7a35ticsg324-1L
# Opt Design 
opt_design
# Place Design
place_design 
# Route Design
route_design
# Write out bitfile
set index_last [expr [llength ${argv}] - 1]
write_bitstream -force [lindex ${argv} ${index_last}]