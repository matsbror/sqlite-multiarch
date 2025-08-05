#!/bin/bash

echo "=== RISC-V Container Performance Diagnosis ==="
echo ""

echo "1. System Information:"
echo "   Architecture: $(uname -m)"
echo "   CPU info:"
grep -E "(processor|model name|cpu MHz)" /proc/cpuinfo | head -10
echo ""
echo "   Memory info:"
free -h
echo ""

echo "2. Container Runtime Performance Test:"

# Test 1: Native binary (if available)
if [ -f "./massive_sqlite" ]; then
    echo "   Direct native binary execution:"
    start_time=$(date +%s.%3N)
    timeout 30 ./massive_sqlite > /dev/null 2>&1 &
    NATIVE_PID=$!
    
    while kill -0 $NATIVE_PID 2>/dev/null; do
        if ps -p $NATIVE_PID >/dev/null 2>&1; then
            first_output_time=$(date +%s.%3N)
            echo "   Native binary startup: $(echo "$first_output_time - $start_time" | bc)s"
            kill $NATIVE_PID 2>/dev/null
            break
        fi
        sleep 0.1
    done
else
    echo "   Native binary not found - run 'make native' first"
fi
echo ""

# Test 2: Container startup overhead
echo "   Testing container startup overhead:"

# Docker native container
echo "   Docker native container startup:"
start_time=$(date +%s.%3N)
timeout 60 docker run --rm matsbror/massive-sqlite-native:1.1 > docker_native.log 2>&1 &
DOCKER_PID=$!

first_output_detected=false
while kill -0 $DOCKER_PID 2>/dev/null; do
    if [ -s docker_native.log ] && [ "$first_output_detected" = false ]; then
        first_output_time=$(date +%s.%3N)
        echo "   Time to first output: $(echo "$first_output_time - $start_time" | bc)s"
        first_output_detected=true
    fi
    sleep 0.5
done
wait $DOCKER_PID
end_time=$(date +%s.%3N)
echo "   Total Docker execution: $(echo "$end_time - $start_time" | bc)s"
echo ""

# Containerd native container  
echo "   containerd native container startup:"
start_time=$(date +%s.%3N)
timeout 60 sudo ctr run --rm matsbror/massive-sqlite-native:1.1 ctr-test-$(date +%s) > ctr_native.log 2>&1 &
CTR_PID=$!

first_output_detected=false  
while kill -0 $CTR_PID 2>/dev/null; do
    if [ -s ctr_native.log ] && [ "$first_output_detected" = false ]; then
        first_output_time=$(date +%s.%3N)
        echo "   Time to first output: $(echo "$first_output_time - $start_time" | bc)s"
        first_output_detected=true
    fi
    sleep 0.5
done
wait $CTR_PID
end_time=$(date +%s.%3N)
echo "   Total containerd execution: $(echo "$end_time - $start_time" | bc)s"
echo ""

echo "3. RISC-V Specific Issues Analysis:"
echo ""

# Check for emulation
echo "   Checking for emulation/compatibility layers:"
if [ -f "/proc/sys/fs/binfmt_misc/qemu-riscv64" ]; then
    echo "   ⚠️  QEMU RISC-V emulation detected - this could cause slowness"
    cat /proc/sys/fs/binfmt_misc/qemu-riscv64 | head -3
else
    echo "   ✓ No QEMU emulation detected"
fi
echo ""

# Check Docker version and runtime
echo "   Docker/containerd versions on RISC-V:"
docker version --format "   Docker: {{.Server.Version}}" 2>/dev/null || echo "   Docker: not available"
sudo ctr version 2>/dev/null | grep -E "Client|Server" | sed 's/^/   /' || echo "   containerd: not available"
echo ""

# Check image architecture
echo "   Checking if pulled images match RISC-V architecture:"
docker inspect matsbror/massive-sqlite-native:1.1 2>/dev/null | jq -r '.[] | .Architecture // "unknown"' | sed 's/^/   Image architecture: /' || echo "   Could not determine image architecture"
echo ""

# System performance indicators
echo "4. System Resource Analysis:"
echo "   Disk I/O performance (quick test):"
start_time=$(date +%s.%3N)
dd if=/dev/zero of=/tmp/test_write bs=1M count=100 2>/dev/null
end_time=$(date +%s.%3N)
rm -f /tmp/test_write
echo "   100MB write test: $(echo "$end_time - $start_time" | bc)s"
echo ""

echo "   Memory bandwidth (quick test):"
start_time=$(date +%s.%3N)
dd if=/dev/zero of=/dev/null bs=1M count=1000 2>/dev/null  
end_time=$(date +%s.%3N)
echo "   Memory throughput test: $(echo "$end_time - $start_time" | bc)s"
echo ""

# Check for CPU frequency scaling
echo "   CPU frequency scaling:"
if [ -f "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor" ]; then
    echo "   Governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
    echo "   Current freq: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq)kHz"
    echo "   Max freq: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq)kHz"
else
    echo "   CPU frequency scaling info not available"
fi
echo ""

echo "5. Container Image Analysis:"
echo "   Checking image layers and size:"
docker images matsbror/massive-sqlite-native:1.1 --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" 2>/dev/null || echo "   Image not found locally"
echo ""
echo "   Image history (layers):"
docker history matsbror/massive-sqlite-native:1.1 2>/dev/null | head -10 || echo "   Could not get image history"
echo ""

echo "6. Recommendations for RISC-V:"
echo ""
if grep -q "qemu" /proc/1/comm 2>/dev/null; then
    echo "   ⚠️  Running under QEMU emulation - expect slower performance"
    echo "   - This is normal for cross-architecture testing"
    echo "   - Native RISC-V hardware would be significantly faster"
fi
echo ""
echo "   Potential optimizations:"
echo "   1. Check if using native RISC-V binary (not emulated)"
echo "   2. Verify Docker daemon performance on RISC-V"
echo "   3. Consider CPU governor settings (performance vs powersave)"
echo "   4. Check for memory/storage bottlenecks"
echo "   5. Test with minimal container images to isolate overhead"
echo ""

# Clean up
rm -f docker_native.log ctr_native.log

echo "=== RISC-V Diagnosis Complete ==="