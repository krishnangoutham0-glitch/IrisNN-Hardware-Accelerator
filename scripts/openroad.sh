#!/bin/bash

echo "=========================================="
echo " FP32 Iris Neural Network - OpenROAD Flow"
echo "=========================================="

#---------------------------------------------------------
# Project paths
#---------------------------------------------------------

PROJECT=$(cd "$(dirname "$0")/.." && pwd)

ORFS="$HOME/OpenROAD-flow-scripts/flow"

DESIGN="iris_nn"

DEST="$PROJECT/physical_design"

DESIGN_DIR="$ORFS/designs/nangate45/$DESIGN"


#---------------------------------------------------------
# Clean previous physical-design outputs
#---------------------------------------------------------

echo
echo "Cleaning previous physical-design results..."

rm -rf "$DEST"

mkdir -p "$DEST/results"
mkdir -p "$DEST/reports"
mkdir -p "$DEST/logs"
mkdir -p "$DEST/gds"


#---------------------------------------------------------
# Update ORFS design files
#---------------------------------------------------------

echo
echo "Updating OpenROAD Design Files..."

mkdir -p "$DESIGN_DIR"

cp "$PROJECT/rtl/fp_network.v" \
   "$DESIGN_DIR/"

cp "$PROJECT/rtl/fp_layer.v" \
   "$DESIGN_DIR/"

cp "$PROJECT/rtl/fp_neuron.v" \
   "$DESIGN_DIR/"

cp "$PROJECT/rtl/fp_adder.v" \
   "$DESIGN_DIR/"

cp "$PROJECT/rtl/fp_multiplier.v" \
   "$DESIGN_DIR/"

cp "$PROJECT/rtl/fp_relu.v" \
   "$DESIGN_DIR/"

cp "$PROJECT/rtl/fp_argmax.v" \
   "$DESIGN_DIR/"

cp "$PROJECT/constraints/constraints.sdc" \
   "$DESIGN_DIR/"


#---------------------------------------------------------
# Run OpenROAD-flow-scripts
#---------------------------------------------------------

echo
echo "Running OpenROAD..."

make -C "$ORFS" \
    OPENROAD_EXE="$HOME/OpenROAD/build/bin/openroad" \
    YOSYS_EXE="/opt/homebrew/bin/yosys" \
    KLAYOUT_CMD="/Applications/KLayout/klayout.app/Contents/MacOS/klayout" \
    DESIGN_CONFIG="./designs/nangate45/$DESIGN/config.mk"


STATUS=$?


#---------------------------------------------------------
# Check result
#---------------------------------------------------------

if [ $STATUS -ne 0 ]; then

    echo
    echo "=========================================="
    echo " OpenROAD Flow FAILED"
    echo "=========================================="

    exit $STATUS

fi


#---------------------------------------------------------
# ORFS output locations
#---------------------------------------------------------

RESULTS="$ORFS/results/nangate45/$DESIGN/base"
REPORTS="$ORFS/reports/nangate45/$DESIGN/base"
LOGS="$ORFS/logs/nangate45/$DESIGN/base"


#---------------------------------------------------------
# Copy results
#---------------------------------------------------------

echo
echo "Copying OpenROAD Outputs..."

cp -r "$RESULTS/"* \
      "$DEST/results/" 2>/dev/null

cp -r "$REPORTS/"* \
      "$DEST/reports/" 2>/dev/null

cp -r "$LOGS/"* \
      "$DEST/logs/" 2>/dev/null


#---------------------------------------------------------
# Copy final GDS
#---------------------------------------------------------

if [ -f "$RESULTS/6_final.gds" ]; then

    cp "$RESULTS/6_final.gds" \
       "$DEST/gds/fp_network.gds"

    echo
    echo "GDS generated:"
    echo "$DEST/gds/fp_network.gds"

else

    echo
    echo "WARNING: Final GDS was not found."

fi


#---------------------------------------------------------
# Finished
#---------------------------------------------------------

echo
echo "=========================================="
echo " OpenROAD Flow Completed Successfully"
echo "=========================================="

echo
echo "Physical Design : $DEST"
echo "Results         : $DEST/results"
echo "Reports         : $DEST/reports"
echo "Logs            : $DEST/logs"
echo "GDS             : $DEST/gds/fp_network.gds"

echo