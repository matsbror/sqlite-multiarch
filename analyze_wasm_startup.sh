#!/bin/bash

# WASM Startup Analysis Script
# Analyzes the startup time breakdown for WASM containers

echo "=== WASM Startup Analysis ==="

# Test 1: Direct wasmtime execution
echo "1. Testing direct wasmtime execution:"
echo "   Command: wasmtime --dir . massive_sqlite.wasm"
start_time=$(date +%s.%3N)
echo "   Container start time: $(date '+%H:%M:%S.%3N')"

wasmtime --dir . massive_sqlite.wasm > wasm_direct.log 2>&1 &
WASMTIME_PID=$!

# Monitor for early outputs
timeout 30 bash -c '
    while kill -0 '"$WASMTIME_PID"' 2>/dev/null; do
        if grep -q "wasm_init\|main\|STARTUP" wasm_direct.log 2>/dev/null; then
            echo "   First output detected at: $(date "+%H:%M:%S.%3N")"
            break
        fi
        sleep 0.1
    done
' &
MONITOR_PID=$!

wait $WASMTIME_PID
kill $MONITOR_PID 2>/dev/null
end_time=$(date +%s.%3N)

echo "   Container end time: $(date '+%H:%M:%S.%3N')"
echo "   Total execution time: $(echo "$end_time - $start_time" | bc)s"
echo ""

# Test 2: Docker with WASM runtime
echo "2. Testing Docker with WASM runtime:"
echo "   Command: docker run --rm --runtime io.containerd.wasmtime.v1 matsbror/massive-sqlite-wasm:1.0"
start_time=$(date +%s.%3N)
echo "   Container start time: $(date '+%H:%M:%S.%3N')"

timeout 60 docker run --rm --runtime io.containerd.wasmtime.v1 matsbror/massive-sqlite-wasm:1.0 > wasm_docker.log 2>&1
end_time=$(date +%s.%3N)

echo "   Container end time: $(date '+%H:%M:%S.%3N')"
echo "   Total execution time: $(echo "$end_time - $start_time" | bc)s"
echo ""

# Test 3: containerd with WASM runtime
echo "3. Testing containerd with WASM runtime:"
echo "   Command: sudo ctr run --rm --runtime io.containerd.wasmtime.v1 matsbror/massive-sqlite-wasm:1.0 test-wasm"
start_time=$(date +%s.%3N)
echo "   Container start time: $(date '+%H:%M:%S.%3N')"

timeout 60 sudo ctr run --rm --runtime io.containerd.wasmtime.v1 matsbror/massive-sqlite-wasm:1.0 test-wasm > wasm_containerd.log 2>&1
end_time=$(date +%s.%3N)

echo "   Container end time: $(date '+%H:%M:%S.%3N')"
echo "   Total execution time: $(echo "$end_time - $start_time" | bc)s"
echo ""

# Analyze the outputs
echo "=== Timing Analysis ==="
echo ""

for log in wasm_direct.log wasm_docker.log wasm_containerd.log; do
    if [ -f "$log" ]; then
        echo "--- $log ---"
        
        # Extract timestamps
        wasm_init_ts=$(grep "wasm_init, timestamp," "$log" | head -1 | sed 's/.*wasm_init, timestamp, \([0-9]*\).*/\1/')
        main_ts=$(grep "main, timestamp," "$log" | head -1 | sed 's/.*main, timestamp, \([0-9]*\).*/\1/')
        
        if [ -n "$wasm_init_ts" ] && [ -n "$main_ts" ]; then
            init_to_main=$(echo "scale=3; ($main_ts - $wasm_init_ts) / 1000" | bc)
            echo "Time from WASM init to main(): ${init_to_main}s"
        fi
        
        if [ -n "$main_ts" ]; then
            echo "Program main() timestamp: $main_ts ms"
        fi
        
        # Show early startup messages
        echo "Early startup messages:"
        grep -E "(STARTUP|wasm_init|main, timestamp)" "$log" | head -5
        echo ""
    fi
done

# Check for common WASM startup issues
echo "=== Potential Issues Analysis ==="

# Check if wasmtime version supports the binary
echo "Wasmtime version:"
wasmtime --version

echo ""
echo "WASM binary info:"
file massive_sqlite.wasm
ls -lh massive_sqlite.wasm

echo ""
echo "Check for large static data that might slow initialization:"
wasm-objdump -h massive_sqlite.wasm 2>/dev/null | head -20 || echo "wasm-objdump not available"

# Clean up
rm -f wasm_direct.log wasm_docker.log wasm_containerd.log

echo ""
echo "=== Recommendations ==="
echo "1. Check wasmtime/runtime compatibility"
echo "2. Consider reducing static data initialization"
echo "3. Profile WASM module loading vs execution time"
echo "4. Test with different WASM runtimes (wasmer, etc.)"