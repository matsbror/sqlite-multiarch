#!/bin/bash

echo "=== WASM Runtime Configuration Diagnosis ==="
echo ""

echo "1. Checking containerd plugins:"
echo "   All plugins:"
sudo ctr plugin ls | head -10
echo ""
echo "   WASM-related plugins:"
sudo ctr plugin ls | grep -i wasm || echo "   No WASM plugins found!"
echo ""

echo "2. Checking containerd configuration:"
containerd_config="/etc/containerd/config.toml"
if [ -f "$containerd_config" ]; then
    echo "   containerd config exists at $containerd_config"
    echo "   WASM runtime configuration:"
    sudo grep -A10 -B5 -i "wasm\|runwasi\|wasmtime" "$containerd_config" || echo "   No WASM runtime configuration found"
else
    echo "   containerd config not found at $containerd_config"
fi
echo ""

echo "3. Checking Docker daemon configuration:"
docker_config="/etc/docker/daemon.json"
if [ -f "$docker_config" ]; then
    echo "   Docker daemon config:"
    sudo cat "$docker_config" | jq '.runtimes // "No custom runtimes configured"' 2>/dev/null || echo "   Config exists but not valid JSON or jq not available"
else
    echo "   No Docker daemon config found at $docker_config"
fi
echo ""

echo "4. Checking available WASM runtimes on system:"
echo "   wasmtime:"
which wasmtime && wasmtime --version || echo "   wasmtime not found in PATH"
echo "   wasmer:"
which wasmer && wasmer --version || echo "   wasmer not found in PATH"
echo "   runwasi (containerd plugin):"
which runwasi || echo "   runwasi not found in PATH"
echo ""

echo "5. Testing what runtime is actually being used:"
echo "   Docker runtime test:"
if timeout 30 docker run --rm --runtime io.containerd.wasmtime.v1 matsbror/massive-sqlite-wasm:1.1 echo "test" 2>&1 | grep -E "(runtime|error|failed)"; then
    echo "   Docker WASM runtime appears to work"
else
    echo "   Docker WASM runtime may not be working properly"
fi
echo ""

echo "   containerd runtime test:"
if timeout 30 sudo ctr run --rm --runtime io.containerd.wasmtime.v1 matsbror/massive-sqlite-wasm:1.1 test-$(date +%s) echo "test" 2>&1 | grep -E "(runtime|error|failed)"; then
    echo "   containerd WASM runtime appears to work"  
else
    echo "   containerd WASM runtime may not be working properly"
fi
echo ""

echo "6. Checking containerd shim processes:"
echo "   Active containerd shims:"
ps aux | grep -E "(containerd|shim|wasm)" | grep -v grep || echo "   No WASM-related processes found"
echo ""

echo "7. Installation recommendations:"
echo ""
echo "   If no WASM plugins found, you need to install runwasi:"
echo "   "
echo "   # Install runwasi (containerd WASM runtime)"
echo "   curl -sSL https://github.com/containerd/runwasi/releases/latest/download/containerd-wasm-shims-v1-linux-x86_64.tar.gz | sudo tar -xzf - -C /usr/local/bin/"
echo ""
echo "   # Configure containerd"
echo "   sudo mkdir -p /etc/containerd"
echo "   sudo containerd config default | sudo tee /etc/containerd/config.toml"
echo "   "
echo "   # Add to /etc/containerd/config.toml:"
echo "   [plugins.\"io.containerd.grpc.v1.cri\".containerd.runtimes.wasmtime]"
echo "     runtime_type = \"io.containerd.wasmtime.v1\""
echo "   "
echo "   # Restart containerd"
echo "   sudo systemctl restart containerd"
echo ""

echo "=== Diagnosis Complete ==="
echo ""
echo "The slow startup is likely because:"
echo "1. containerd doesn't have proper WASM runtime plugin"
echo "2. It's falling back to some inefficient emulation/compatibility mode"
echo "3. The runtime specification 'io.containerd.wasmtime.v1' isn't recognized"