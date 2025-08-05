#!/bin/bash

echo "=== WASM Startup Time Analysis ==="
echo ""

# First, let's check the binary sizes
echo "1. Binary Size Comparison:"
echo "   Native binary: $(ls -lh massive_sqlite 2>/dev/null | awk '{print $5}' || echo 'not found')"
echo "   WASM binary:   $(ls -lh massive_sqlite.wasm 2>/dev/null | awk '{print $5}' || echo 'not found')"
echo ""

# Check WASM sections if wasm-objdump is available
echo "2. WASM Binary Analysis:"
if command -v wasm-objdump >/dev/null 2>&1; then
    echo "   WASM sections:"
    wasm-objdump -h massive_sqlite.wasm | head -15
    echo ""
    echo "   Data sections (potential startup bottlenecks):"
    wasm-objdump -s massive_sqlite.wasm | grep -A3 -B1 "data\|rodata" | head -20
else
    echo "   wasm-objdump not available - install wabt tools for detailed analysis"
fi
echo ""

# Test with the measurement script to get actual timing
echo "3. Container Startup Time Test:"
echo "   Testing with 1 iteration to isolate startup time..."

# Create a temporary test CSV just for startup analysis
test_csv="startup_test_$(date +%s).csv"
echo "Runtime,Image,Platform,Iteration,Start Timestamp,Pull Complete Timestamp,Execution Complete Timestamp,Pull Time (s),Container Start to Main Time (s),Main to Elapsed Time (s),Total Execution Time (s),Host Size (MB)" > "$test_csv"

echo "   Testing Docker WASM execution..."
start_time=$(date +%s.%3N)
exec_output=$(timeout 120 docker run --rm --runtime io.containerd.wasmtime.v1 matsbror/massive-sqlite-wasm:1.1 2>&1)
end_time=$(date +%s.%3N)

total_time=$(echo "$end_time - $start_time" | bc)
echo "   Total Docker WASM time: ${total_time}s"

# Parse timestamps from output
main_line=$(echo "$exec_output" | grep "main, timestamp," | head -1)
init_line=$(echo "$exec_output" | grep "wasm_init, timestamp," | head -1)

if [ -n "$init_line" ] && [ -n "$main_line" ]; then
    init_ts=$(echo "$init_line" | sed 's/.*wasm_init, timestamp, \([0-9]*\).*/\1/')
    main_ts=$(echo "$main_line" | sed 's/.*main, timestamp, \([0-9]*\).*/\1/')
    
    if [ -n "$init_ts" ] && [ -n "$main_ts" ]; then
        runtime_to_init=$(echo "scale=3; ($init_ts - ($start_time * 1000)) / 1000" | bc)
        init_to_main=$(echo "scale=3; ($main_ts - $init_ts) / 1000" | bc)
        
        echo "   Breakdown:"
        echo "     Container start to WASM init: ${runtime_to_init}s"
        echo "     WASM init to main():          ${init_to_main}s"
        echo "     Total container startup:      ${total_time}s"
    fi
else
    echo "   Could not parse timing data from container output"
    echo "   Output sample: $(echo "$exec_output" | head -3)"
fi

echo ""

# Test containerd as well
echo "   Testing containerd WASM execution..."
start_time=$(date +%s.%3N)
exec_output=$(timeout 120 sudo ctr run --rm --runtime io.containerd.wasmtime.v1 matsbror/massive-sqlite-wasm:1.1 wasm-test-$(date +%s) 2>&1)
end_time=$(date +%s.%3N)

total_time=$(echo "$end_time - $start_time" | bc)
echo "   Total containerd WASM time: ${total_time}s"

echo ""

# Recommendations
echo "4. Analysis & Recommendations:"
echo ""
echo "   If container start to WASM init > 5s:"
echo "     - Container runtime overhead (Docker/containerd + wasmtime startup)"
echo "     - Image pulling/extraction time"
echo "     - WASM runtime initialization"
echo ""
echo "   If WASM init to main() > 10s:"
echo "     - Large static data initialization (your arrays)"
echo "     - WASM module compilation (JIT)"
echo "     - Memory allocation and setup"
echo ""
echo "   Quick fixes to try:"
echo "     1. Lazy initialization of large arrays"
echo "     2. Use smaller datasets for testing"
echo "     3. Profile with different WASM runtimes"
echo "     4. Check if wasmtime pre-compilation helps"
echo ""

# Clean up
rm -f "$test_csv"

echo "=== Analysis Complete ==="