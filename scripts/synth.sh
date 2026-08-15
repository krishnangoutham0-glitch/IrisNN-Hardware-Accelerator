#!/bin/bash

echo "=========================================="
echo " FP32 Neural Network - Yosys Synthesis"
echo "=========================================="

# Always execute from project root
cd "$(dirname "$0")/.."

# Clean previous synthesis output
rm -rf synthesis

# Create clean output directories
mkdir -p synthesis/netlist
mkdir -p synthesis/reports

# Run Yosys
yosys -s scripts/yosys_synth.tcl \
    | tee synthesis/reports/yosys_synthesis.rpt

STATUS=${PIPESTATUS[0]}

echo ""

if [ $STATUS -eq 0 ]; then

    echo "=========================================="
    echo " Synthesis Finished Successfully"
    echo "=========================================="
    echo ""
    echo "Netlist  : synthesis/netlist/top_synth.v"
    echo "Schematic: synthesis/top_gate.svg"
    echo "Report   : synthesis/reports/yosys_synthesis.rpt"

else

    echo "=========================================="
    echo " Synthesis FAILED"
    echo "=========================================="

    exit $STATUS
fi