#!/bin/bash

echo "=== Containerd WASM Shim Overhead Analysis ==="
echo ""

echo "1. Direct Performance Comparison:"
echo ""

# Test 1: Direct wasmtime execution
echo "   Direct wasmtime execution:"
if [ -f "massive_sqlite.wasm" ]; then
    start_time=$(date +%s.%3N)
    timeout 30 wasmtime --dir . massive_sqlite.wasm > wasmtime_direct.log 2>&1 &
    WASMTIME_PID=$!
    
    # Wait for first output (main timestamp)
    while kill -0 $WASMTIME_PID 2>/dev/null; do
        if grep -q "main, timestamp" wasmtime_direct.log 2>/dev/null; then
            main_detected_time=$(date +%s.%3N)
            echo "   Time to main(): $(echo "$main_detected_time - $start_time" | bc)s"
            kill $WASMTIME_PID 2>/dev/null
            break
        fi
        sleep 0.01
    done
    
    # Extract actual program timestamps
    if grep -q "main, timestamp" wasmtime_direct.log; then
        echo "   ✓ Direct wasmtime works quickly"
    fi
else
    echo "   massive_sqlite.wasm not found - run 'make wasm' first"
fi
echo ""

# Test 2: Containerd shim execution
echo "   Containerd shim execution:"
start_time=$(date +%s.%3N)
echo "   Starting containerd shim at: $(date '+%H:%M:%S.%3N')"

# Use unique container name to avoid conflicts
container_name="shim-test-$(date +%s%N)"
timeout 60 sudo ctr run --rm --runtime io.containerd.wasmtime.v1 matsbror/massive-sqlite-wasm:1.1 $container_name > shim_output.log 2>&1 &
SHIM_PID=$!

# Monitor shim startup phases
shim_start_detected=false
main_detected=false

while kill -0 $SHIM_PID 2>/dev/null; do
    current_time=$(date +%s.%3N)
    
    # Check for container creation
    if [ "$shim_start_detected" = false ]; then
        if sudo ctr containers ls | grep -q $container_name 2>/dev/null; then
            shim_create_time=$(date +%s.%3N)
            echo "   Container created: $(echo "$shim_create_time - $start_time" | bc)s"
            shim_start_detected=true
        fi
    fi
    
    # Check for first program output
    if [ "$main_detected" = false ]; then
        if grep -q "main, timestamp\|wasm_init" shim_output.log 2>/dev/null; then
            main_detected_time=$(date +%s.%3N)
            echo "   Program main(): $(echo "$main_detected_time - $start_time" | bc)s"
            main_detected=true
            kill $SHIM_PID 2>/dev/null
            break
        fi
    fi
    
    sleep 0.1
done

wait $SHIM_PID 2>/dev/null
end_time=$(date +%s.%3N)
echo "   Total shim execution: $(echo "$end_time - $start_time" | bc)s"
echo ""

echo "2. Shim Overhead Analysis:"
echo ""

# Check shim binary
echo "   Shim binary info:"
ls -la /usr/local/bin/containerd-shim-wasmtime-v1
echo "   Shim version/info:"
/usr/local/bin/containerd-shim-wasmtime-v1 --version 2>/dev/null || echo "   No version info available"
echo ""

# Check what the shim is actually doing
echo "   Shim process analysis:"
echo "   Checking if shim creates multiple processes..."
ps aux | grep -E "(containerd-shim|wasmtime)" | grep -v grep || echo "   No shim processes currently running"
echo ""

# Check containerd configuration impact
echo "   Containerd WASM runtime config:"
sudo grep -A10 -B2 "wasmtime" /etc/containerd/config.toml || echo "   No WASM config found"
echo ""

echo "3. Potential Bottlenecks:"
echo ""
echo "   Common containerd shim overhead causes:"
echo "   1. **Image extraction**: Shim extracts WASM from container layer"
echo "   2. **Namespace setup**: Container namespaces, cgroups, security contexts"
echo "   3. **File system mounting**: Setting up container filesystem"
echo "   4. **Runtime initialization**: Starting wasmtime process within container context"
echo "   5. **IPC overhead**: Communication between containerd, shim, and wasmtime"
echo ""

# Check for specific delay patterns
if [ -f "shim_output.log" ]; then
    echo "   Shim output analysis:"
    if grep -q "main, timestamp" shim_output.log; then
        echo "   ✓ Program eventually started"
        # Try to extract timing from program output
        main_ts=$(grep "main, timestamp," shim_output.log | head -1 | sed 's/.*main, timestamp, \([0-9]*\).*/\1/')
        if [ -n "$main_ts" ]; then
            echo "   Program reported main timestamp: $main_ts ms"
        fi
    else
        echo "   ✗ Program didn't reach main() or output was lost"
        echo "   First few lines of shim output:"
        head -5 shim_output.log | sed 's/^/     /'
    fi
fi
echo ""

echo "4. Optimization Recommendations:"
echo ""
echo "   To reduce shim overhead:"
echo "   1. **Minimal container image**: Use absolute minimal container (scratch + WASM)"
echo "   2. **Shim alternatives**: Try different WASM runtimes (wasmer, wasmtime versions)"
echo "   3. **Container optimizations**: Reduce security/namespace overhead"
echo "   4. **Pre-compilation**: Use wasmtime's ahead-of-time compilation"
echo "   5. **Direct runtime**: Consider using wasmtime directly instead of containers"
echo ""

echo "   Comparison with alternatives:"
echo "   - **runwasi with wasmer**: Different WASM runtime"
echo "   - **wasm-to-oci**: Different container approach"
echo "   - **Direct wasmtime**: Fastest but no container isolation"
echo ""

# Clean up
rm -f wasmtime_direct.log shim_output.log

echo "=== Shim Overhead Analysis Complete ==="
echo ""
echo "Expected finding: 10-30x slower startup through containerd shim vs direct wasmtime"
echo "This is normal overhead for container isolation + WASM runtime layers"