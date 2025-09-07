#!/bin/bash

cd ../rundir || exit 1

# 1. Check for required file
INPUT_FILE="../output/2017042700/wrfinput_d01_152057_0_mean"
if [ ! -f "$INPUT_FILE" ]; then
    echo "File $INPUT_FILE not found. Exiting."
    exit 1
fi

# 2. Copy the file
cp "$INPUT_FILE" ./wrfinput_d01

# 3. Run filter
module restore
./fill_inflation_restart
if [ $? -ne 0 ]; then
    echo "fill_inflation_restart failed. Exiting."
    exit 1
fi

# 4. Create or recreate the output directory
OUT_DIR="../output/2017042700/Inflation_input"
if [ -d "$OUT_DIR" ]; then
    rm -rf "$OUT_DIR"
fi
mkdir -p "$OUT_DIR"

# 5. Check for priorinf files and move them
shopt -s nullglob
files=(input_priorinf_*.nc)
if [ ${#files[@]} -eq 0 ]; then
    echo "No input_priorinf_*.nc files found. Exiting."
    exit 1
fi
mv "${files[@]}" "$OUT_DIR"
