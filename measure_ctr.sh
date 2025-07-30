#!/bin/bash

# SQLite Multi-Architecture Performance Measurement Script
# Compares pull times between Docker and containerd for different architectures

# Usage check
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <number_of_times>"
    echo "Example: $0 10"
    exit 1
fi

n=$1
output_file="timing_results.csv"

# Image configuration
REPO="matsbror/massive-sqlite"
TAG="latest"
WASM_REPO="matsbror/massive-sqlite-wasm"

# Check dependencies
command -v bc >/dev/null 2>&1 || { echo "Error: bc is required but not installed." >&2; exit 1; }

echo "SQLite Multi-Architecture Performance Measurement"
echo "================================================="
echo "Iterations: $n"
echo "Output file: $output_file"
echo ""

# Create CSV header
echo "Runtime,Image,Platform,Average Pull Time (s)" > $output_file

# Function to measure containerd pulls
pull_image_containerd() {
    local image=$1
    local platform=$2
    local runtime_name="containerd"
    local accumulated_time=0

    echo "Testing $runtime_name: $image ($platform)"
    
    for ((i=1; i<=n; i++))
    do
        echo -n "  Iteration $i/$n... "
        
        # Remove image if present and clear containerd cache
        sudo ctr image rm $image 2>/dev/null
        sudo ctr image prune --all >/dev/null 2>&1

        # Pull and time
        start_time=$(date +%s.%3N)
        if [ -z "$platform" ]; then
            sudo ctr image pull $image >/dev/null 2>&1
        else
            sudo ctr image pull --platform $platform $image >/dev/null 2>&1
        fi
        end_time=$(date +%s.%3N)

        elapsed=$(echo "$end_time - $start_time" | bc)
        accumulated_time=$(echo "$accumulated_time + $elapsed" | bc)
        
        echo "${elapsed}s"
    done

    avg_time=$(echo "scale=3; $accumulated_time / $n" | bc)
    echo "$runtime_name,$image,$platform,$avg_time" >> $output_file
    echo "  Average: ${avg_time}s"
    echo ""
}

# Function to measure Docker pulls
pull_image_docker() {
    local image=$1
    local platform=$2
    local runtime_name="docker"
    local accumulated_time=0

    echo "Testing $runtime_name: $image ($platform)"
    
    for ((i=1; i<=n; i++))
    do
        echo -n "  Iteration $i/$n... "
        
        # Remove image if present
        docker rmi $image >/dev/null 2>&1
        docker system prune -f >/dev/null 2>&1

        # Pull and time
        start_time=$(date +%s.%3N)
        if [ -z "$platform" ]; then
            docker pull $image >/dev/null 2>&1
        else
            docker pull --platform $platform $image >/dev/null 2>&1
        fi
        end_time=$(date +%s.%3N)

        elapsed=$(echo "$end_time - $start_time" | bc)
        accumulated_time=$(echo "$accumulated_time + $elapsed" | bc)
        
        echo "${elapsed}s"
    done

    avg_time=$(echo "scale=3; $accumulated_time / $n" | bc)
    echo "$runtime_name,$image,$platform,$avg_time" >> $output_file
    echo "  Average: ${avg_time}s"
    echo ""
}

# Test images and platforms
echo "Starting performance measurements..."
echo ""

# Native AMD64 builds
if command -v docker >/dev/null 2>&1; then
    pull_image_docker "docker.io/$REPO:$TAG-amd64" "linux/amd64"
fi

if command -v ctr >/dev/null 2>&1; then
    pull_image_containerd "docker.io/$REPO:$TAG-amd64" "linux/amd64"
fi

# Native ARM64 builds
if command -v docker >/dev/null 2>&1; then
    pull_image_docker "docker.io/$REPO:$TAG-arm64" "linux/arm64"
fi

if command -v ctr >/dev/null 2>&1; then
    pull_image_containerd "docker.io/$REPO:$TAG-arm64" "linux/arm64"  
fi

# Native RISC-V builds
if command -v docker >/dev/null 2>&1; then
    pull_image_docker "docker.io/$REPO:$TAG-riscv64" "linux/riscv64"
fi

if command -v ctr >/dev/null 2>&1; then
    pull_image_containerd "docker.io/$REPO:$TAG-riscv64" "linux/riscv64"
fi

# WebAssembly builds
if command -v docker >/dev/null 2>&1; then
    pull_image_docker "docker.io/$WASM_REPO:$TAG" "wasm"
fi

if command -v ctr >/dev/null 2>&1; then
    pull_image_containerd "docker.io/$WASM_REPO:$TAG" "wasm"
fi

echo "Performance measurement completed!"
echo "Results saved to: $output_file"
echo ""
echo "Summary:"
cat $output_file | column -t -s ','
echo ""
echo "To analyze results:"
echo "  cat $output_file"
echo "  python3 -c \"import pandas as pd; df=pd.read_csv('$output_file'); print(df.groupby(['Runtime','Platform']).mean())\""