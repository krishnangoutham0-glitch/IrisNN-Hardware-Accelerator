#!/bin/bash

echo "=========================================="
echo " Iris NN Hardware - OpenSTA"
echo "=========================================="

# Always run from project root
cd "$(dirname "$0")/.."

# Clean previous STA results
rm -rf timing

# Create clean output directories
mkdir -p timing/reports

# Run OpenSTA
/Users/gouthamkrishnan/OpenSTA/build/sta <<EOF | tee timing/reports/sta_report.rpt
source scripts/sta.tcl
EOF

STATUS=${PIPESTATUS[0]}

echo ""

if [ $STATUS -eq 0 ]; then

    echo "=========================================="
    echo " Static Timing Analysis Finished"
    echo "=========================================="
    echo ""
    echo "STA Report : timing/reports/sta_report.rpt"

else

    echo "=========================================="
    echo " Static Timing Analysis FAILED"
    echo "=========================================="

    exit $STATUS
fi