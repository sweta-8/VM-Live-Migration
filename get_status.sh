#!/bin/bash
OUTPUT_FILE="memory_intensive_precopy_no_threshold.txt"
while true; do
    # Redirect both stdout and stderr to the output file
    output=$(virsh domjobinfo ubuntu22.04);
    # If the command fails, the exit code will be non-zero
    if [ -z $output ]; then
        exit 1;
    else 
	echo "$output">>$OUTPUT_FILE;
    fi
done

