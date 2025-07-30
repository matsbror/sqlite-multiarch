#!/bin/bash

# SQLite Native Architecture Performance Measurement Script
# Compares pull times between Docker and containerd for current architecture

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

# Detect current architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        PLATFORM="linux/amd64"
        IMAGE_SUFFIX="amd64"
        ;;
    aarch64|arm64)
        PLATFORM="linux/arm64"
        IMAGE_SUFFIX="arm64"
        ;;
    riscv64)
        PLATFORM="linux/riscv64"
        IMAGE_SUFFIX="riscv64"
        ;;
    *)
        echo "Error: Unsupported architecture: $ARCH"
        echo "Supported architectures: x86_64, aarch64/arm64, riscv64"
        exit 1
        ;;
esac

# Check dependencies
command -v bc >/dev/null 2>&1 || { echo "Error: bc is required but not installed." >&2; exit 1; }

echo "SQLite Native Architecture Performance Measurement"
echo "================================================="
echo "Current architecture: $ARCH"
echo "Platform: $PLATFORM"
echo "Image suffix: $IMAGE_SUFFIX"
echo "Iterations: $n"
echo "Output file: $output_file"
echo ""

# Create CSV header
echo "Runtime,Image,Platform,Iteration,Start Timestamp,Pull Complete Timestamp,Execution Complete Timestamp,Pull Time (s),Execution Time (s)" > $output_file

# Function to measure containerd pulls
pull_image_containerd() {
    local image=$1
    local platform=$2
    local runtime_name="containerd"
    local accumulated_pull_time=0
    local accumulated_exec_time=0

    echo "Testing $runtime_name: $image ($platform)"
    
    for ((i=1; i<=n; i++))
    do
        echo -n "  Iteration $i/$n... "
        
        # Remove image if present and clear containerd cache
        sudo ctr image rm $image 2>/dev/null
        sudo ctr image prune --all >/dev/null 2>&1

        # Timestamp before starting pull
        start_timestamp=$(date +%s)
        start_time=$(date +%s.%3N)
        
        # Pull image
        if [ -z "$platform" ]; then
            sudo ctr image pull $image >/dev/null 2>&1
        else
            sudo ctr image pull --platform $platform $image >/dev/null 2>&1
        fi
        
        # Timestamp after pull complete
        pull_complete_timestamp=$(date +%s)
        pull_complete_time=$(date +%s.%3N)
        
        # Execute container
        sudo ctr run --rm $image test-container-$i >/dev/null 2>&1
        
        # Timestamp after execution complete
        exec_complete_timestamp=$(date +%s)
        exec_complete_time=$(date +%s.%3N)

        # Calculate times
        pull_elapsed=$(echo "$pull_complete_time - $start_time" | bc)
        exec_elapsed=$(echo "$exec_complete_time - $pull_complete_time" | bc)
        
        accumulated_pull_time=$(echo "$accumulated_pull_time + $pull_elapsed" | bc)
        accumulated_exec_time=$(echo "$accumulated_exec_time + $exec_elapsed" | bc)
        
        # Log to CSV
        echo "$runtime_name,$image,$platform,$i,$start_timestamp,$pull_complete_timestamp,$exec_complete_timestamp,$pull_elapsed,$exec_elapsed" >> $output_file
        
        echo "pull: ${pull_elapsed}s, exec: ${exec_elapsed}s"
    done

    avg_pull_time=$(echo "scale=3; $accumulated_pull_time / $n" | bc)
    avg_exec_time=$(echo "scale=3; $accumulated_exec_time / $n" | bc)
    echo "  Average - pull: ${avg_pull_time}s, exec: ${avg_exec_time}s"
    echo ""
}

# Function to measure Docker pulls
pull_image_docker() {
    local image=$1
    local platform=$2
    local runtime_name="docker"
    local accumulated_pull_time=0
    local accumulated_exec_time=0

    echo "Testing $runtime_name: $image ($platform)"
    
    for ((i=1; i<=n; i++))
    do
        echo -n "  Iteration $i/$n... "
        
        # Remove image if present
        docker rmi $image >/dev/null 2>&1
        docker system prune -f >/dev/null 2>&1

        # Timestamp before starting pull
        start_timestamp=$(date +%s)
        start_time=$(date +%s.%3N)
        
        # Pull image
        if [ -z "$platform" ]; then
            docker pull $image >/dev/null 2>&1
        else
            docker pull --platform $platform $image >/dev/null 2>&1
        fi
        
        # Timestamp after pull complete
        pull_complete_timestamp=$(date +%s)
        pull_complete_time=$(date +%s.%3N)
        
        # Execute container
        docker run --rm $image >/dev/null 2>&1
        
        # Timestamp after execution complete
        exec_complete_timestamp=$(date +%s)
        exec_complete_time=$(date +%s.%3N)

        # Calculate times
        pull_elapsed=$(echo "$pull_complete_time - $start_time" | bc)
        exec_elapsed=$(echo "$exec_complete_time - $pull_complete_time" | bc)
        
        accumulated_pull_time=$(echo "$accumulated_pull_time + $pull_elapsed" | bc)
        accumulated_exec_time=$(echo "$accumulated_exec_time + $exec_elapsed" | bc)
        
        # Log to CSV
        echo "$runtime_name,$image,$platform,$i,$start_timestamp,$pull_complete_timestamp,$exec_complete_timestamp,$pull_elapsed,$exec_elapsed" >> $output_file
        
        echo "pull: ${pull_elapsed}s, exec: ${exec_elapsed}s"
    done

    avg_pull_time=$(echo "scale=3; $accumulated_pull_time / $n" | bc)
    avg_exec_time=$(echo "scale=3; $accumulated_exec_time / $n" | bc)
    echo "  Average - pull: ${avg_pull_time}s, exec: ${avg_exec_time}s"
    echo ""
}

# Test native architecture image
IMAGE="docker.io/$REPO:$TAG-$IMAGE_SUFFIX"

echo "Starting performance measurements for native architecture..."
echo "Testing image: $IMAGE"
echo ""

# Test with Docker (if available)
if command -v docker >/dev/null 2>&1; then
    pull_image_docker "$IMAGE" "$PLATFORM"
else
    echo "Docker not available, skipping Docker tests"
fi

# Test with containerd (if available)
if command -v ctr >/dev/null 2>&1; then
    pull_image_containerd "$IMAGE" "$PLATFORM"
else
    echo "containerd not available, skipping containerd tests"
fi

echo "Performance measurement completed!"
echo "Results saved to: $output_file"
echo ""
echo "Summary:"
echo "Average pull and execution times by runtime:"
if command -v python3 >/dev/null 2>&1; then
    python3 -c "
import pandas as pd
try:
    df = pd.read_csv('$output_file')
    summary = df.groupby('Runtime')[['Pull Time (s)', 'Execution Time (s)']].mean()
    print(summary.round(3))
except:
    print('Error reading CSV file')
"
else
    echo "Python3 not available for summary analysis"
    echo "Raw data:"
    cat $output_file | column -t -s ','
fi
echo ""
echo "Full results saved to: $output_file"
echo ""
echo "To analyze results:"
echo "  cat $output_file"
echo "  python3 -c \"import pandas as pd; df=pd.read_csv('$output_file'); print(df.describe())\""