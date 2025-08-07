#!/bin/bash

echo "=== Container Runtime vs Direct WASM Analysis ==="
echo ""

# Test 1: Direct wasmtime execution
echo "1. Direct wasmtime execution:"
if [ -f "massive_sqlite.wasm" ]; then
    echo "   Testing: wasmtime --dir . massive_sqlite.wasm"
    start_time=$(date +%s.%3N)
    timeout 30 wasmtime --dir . massive_sqlite.wasm > wasmtime_direct.log 2>&1 &
    WASMTIME_PID=$!
    
    # Wait for first output
    while kill -0 $WASMTIME_PID 2>/dev/null; do
        if grep -q "main, timestamp\|wasm_init" wasmtime_direct.log 2>/dev/null; then
            first_output_time=$(date +%s.%3N)
            echo "   Time to first output: $(echo "$first_output_time - $start_time" | bc)s"
            break
        fi
        sleep 0.1
    done
    
    wait $WASMTIME_PID
    end_time=$(date +%s.%3N)
    echo "   Total wasmtime execution: $(echo "$end_time - $start_time" | bc)s"
    
    # Show timing from the program itself
    if grep -q "main, timestamp" wasmtime_direct.log; then
        echo "   Program reports quick startup - confirms arrays are not the issue"
    fi
else
    echo "   massive_sqlite.wasm not found - run 'make wasm' first"
fi
echo ""

# Test 2: Docker with WASM runtime
echo "2. Docker with WASM runtime:"
echo "   Testing: docker run --runtime io.containerd.wasmtime.v1"
start_time=$(date +%s.%3N)
echo "   Container start time: $(date '+%H:%M:%S.%3N')"

timeout 60 docker run --rm --runtime io.containerd.wasmtime.v1 matsbror/massive-sqlite-wasm:1.1 > docker_wasm.log 2>&1 &
DOCKER_PID=$!

# Monitor for first output
first_output_detected=false
while kill -0 $DOCKER_PID 2>/dev/null; do
    if grep -q "main, timestamp\|wasm_init\|STARTUP" docker_wasm.log 2>/dev/null && [ "$first_output_detected" = false ]; then
        first_output_time=$(date +%s.%3N)
        echo "   Time to first program output: $(echo "$first_output_time - $start_time" | bc)s"
        first_output_detected=true
    fi
    sleep 0.5
done

wait $DOCKER_PID
end_time=$(date +%s.%3N)
echo "   Total Docker execution: $(echo "$end_time - $start_time" | bc)s"
echo ""

# Test 3: containerd with WASM runtime
echo "3. containerd with WASM runtime:"
echo "   Testing: ctr run --runtime io.containerd.wasmtime.v1"
start_time=$(date +%s.%3N)
echo "   Container start time: $(date '+%H:%M:%S.%3N')"

timeout 60 sudo ctr run --rm --runtime io.containerd.wasmtime.v1 matsbror/massive-sqlite-wasm:1.1 ctr-test-$(date +%s) > ctr_wasm.log 2>&1 &
CTR_PID=$!

# Monitor for first output  
first_output_detected=false
while kill -0 $CTR_PID 2>/dev/null; do
    if grep -q "main, timestamp\|wasm_init\|STARTUP" ctr_wasm.log 2>/dev/null && [ "$first_output_detected" = false ]; then
        first_output_time=$(date +%s.%3N)
        echo "   Time to first program output: $(echo "$first_output_time - $start_time" | bc)s"
        first_output_detected=true  
    fi
    sleep 0.5
done

wait $CTR_PID
end_time=$(date +%s.%3N)
echo "   Total containerd execution: $(echo "$end_time - $start_time" | bc)s"
echo ""

# Analysis
echo "4. Container Runtime Overhead Analysis:"
echo ""

# Check what's taking time in container startup
echo "   Potential bottlenecks in container WASM execution:"
echo "   - Image extraction and mounting (scratch image should be fast)"
echo "   - Container runtime initialization" 
echo "   - WASM runtime (wasmtime) startup within container"
echo "   - Container networking/security setup"
echo "   - Volume mounting and filesystem setup"
echo ""

# Check container runtime versions
echo "   Runtime versions:"
docker version --format "   Docker: {{.Server.Version}}" 2>/dev/null || echo "   Docker: not available"
sudo ctr version 2>/dev/null | grep -E "Client|Server" | sed 's/^/   containerd: /' || echo "   containerd: not available"
wasmtime --version 2>/dev/null | sed 's/^/   /' || echo "   wasmtime: not available"
echo ""

# Check if runtime is properly configured
echo "   Checking WASM runtime configuration:"
docker info --format "{{.Runtimes}}" 2>/dev/null | grep -o "wasmtime\|wasm" | sed 's/^/   Docker runtime: /' || echo "   Docker WASM runtime: not configured"
sudo ctr plugin ls 2>/dev/null | grep -i wasm | sed 's/^/   containerd plugin: /' || echo "   containerd WASM plugin: not found"
echo ""

echo "5. Recommendations:"
echo ""
echo "   If direct wasmtime is fast but containers are slow:"
echo "   a) Container runtime overhead - try different runtimes"
echo "   b) Image layer extraction time - check image size/layers"  
echo "   c) Security/namespace setup overhead"
echo "   d) Runtime plugin inefficiency"
echo ""
echo "   Quick tests to try:"
echo "   1. Test with a minimal scratch WASM image"
echo "   2. Try different WASM runtimes (wasmer, wasmtime versions)"
echo "   3. Check container logs for runtime initialization delays"
echo "   4. Profile with 'docker stats' during startup"
echo ""

# Clean up
rm -f wasmtime_direct.log docker_wasm.log ctr_wasm.log

echo "=== Analysis Complete ==="