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
NATIVE_REPO="matsbror/massive-sqlite-native"
WASM_REPO="matsbror/massive-sqlite-wasm"
TAG="latest"

# Cache busting configuration
USE_DIGEST=${USE_DIGEST:-false}

# Detect current architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        PLATFORM="linux/amd64"
        ;;
    aarch64|arm64)
        PLATFORM="linux/arm64"
        ;;
    riscv64)
        PLATFORM="linux/riscv64"
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
echo "Iterations: $n"
echo "Output file: $output_file"
echo ""

# Create CSV header
echo "Runtime,Image,Platform,Iteration,Start Timestamp,Pull Complete Timestamp,Execution Complete Timestamp,Pull Time (s),Execution Time (s),Repo Size (MB),Host Size (MB)" > $output_file

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
        
        # Execute container (with appropriate runtime for WASM)
        if [[ $image == *"wasm"* ]]; then
            sudo ctr run --rm --runtime io.containerd.wasmtime.v1 $image test-container-$i >/dev/null 2>&1
        else
            sudo ctr run --rm $image test-container-$i >/dev/null 2>&1
        fi
        
        # Timestamp after execution complete
        exec_complete_timestamp=$(date +%s)
        exec_complete_time=$(date +%s.%3N)

        # Calculate times
        pull_elapsed=$(echo "$pull_complete_time - $start_time" | bc)
        exec_elapsed=$(echo "$exec_complete_time - $pull_complete_time" | bc)
        
        accumulated_pull_time=$(echo "$accumulated_pull_time + $pull_elapsed" | bc)
        accumulated_exec_time=$(echo "$accumulated_exec_time + $exec_elapsed" | bc)
        
        # Get image sizes
        repo_size=$(get_repo_image_size $image $platform)
        host_size=$(get_containerd_local_size $image)
        
        # Log to CSV
        echo "$runtime_name,$image,$platform,$i,$start_timestamp,$pull_complete_timestamp,$exec_complete_timestamp,$pull_elapsed,$exec_elapsed,$repo_size,$host_size" >> $output_file
        
        echo "pull: ${pull_elapsed}s, exec: ${exec_elapsed}s, repo: ${repo_size}MB, host: ${host_size}MB"
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
        
        # Execute container (with appropriate runtime for WASM)
        if [[ $image == *"wasm"* ]]; then
            docker run --rm --runtime io.containerd.wasmtime.v1 $image >/dev/null 2>&1
        else
            docker run --rm $image >/dev/null 2>&1
        fi
        
        # Timestamp after execution complete
        exec_complete_timestamp=$(date +%s)
        exec_complete_time=$(date +%s.%3N)

        # Calculate times
        pull_elapsed=$(echo "$pull_complete_time - $start_time" | bc)
        exec_elapsed=$(echo "$exec_complete_time - $pull_complete_time" | bc)
        
        accumulated_pull_time=$(echo "$accumulated_pull_time + $pull_elapsed" | bc)
        accumulated_exec_time=$(echo "$accumulated_exec_time + $exec_elapsed" | bc)
        
        # Get image sizes
        repo_size=$(get_repo_image_size $image $platform)
        host_size=$(get_docker_local_size $image)
        
        # Log to CSV
        echo "$runtime_name,$image,$platform,$i,$start_timestamp,$pull_complete_timestamp,$exec_complete_timestamp,$pull_elapsed,$exec_elapsed,$repo_size,$host_size" >> $output_file
        
        echo "pull: ${pull_elapsed}s, exec: ${exec_elapsed}s, repo: ${repo_size}MB, host: ${host_size}MB"
    done

    avg_pull_time=$(echo "scale=3; $accumulated_pull_time / $n" | bc)
    avg_exec_time=$(echo "scale=3; $accumulated_exec_time / $n" | bc)
    echo "  Average - pull: ${avg_pull_time}s, exec: ${avg_exec_time}s"
    echo ""
}

# Function to get image digest
get_image_digest() {
    local image=$1
    local platform=$2
    
    if command -v docker >/dev/null 2>&1; then
        if [ -z "$platform" ]; then
            docker manifest inspect $image 2>/dev/null | grep -o '"digest":"sha256:[^"]*' | head -1 | cut -d'"' -f4
        else
            docker manifest inspect $image 2>/dev/null | jq -r ".manifests[] | select(.platform.architecture==\"$(echo $platform | cut -d'/' -f2)\") | .digest" 2>/dev/null || echo ""
        fi
    else
        echo ""
    fi
}

# Function to get repository image size
get_repo_image_size() {
    local image=$1
    local platform=$2
    
    if command -v docker >/dev/null 2>&1; then
        # Get architecture from platform
        local arch=$(echo $platform | cut -d'/' -f2)
        
        # Try to get size from manifest
        local size_bytes
        if command -v jq >/dev/null 2>&1; then
            size_bytes=$(docker manifest inspect $image 2>/dev/null | jq -r '
                if .manifests then
                    (.manifests[] | select(.platform.architecture=="'$arch'") | 
                     (.size // 0) + (if .platform.architecture=="'$arch'" then ([.. | objects | select(has("size")) | .size] | add // 0) else 0 end))
                else
                    (.config.size // 0) + ([.layers[]?.size] | add // 0)
                end
            ' 2>/dev/null || echo "0")
        else
            # Fallback without jq - get total compressed size estimate
            size_bytes=$(docker manifest inspect $image 2>/dev/null | grep -o '"size":[0-9]*' | head -5 | cut -d':' -f2 | awk '{sum+=$1} END {print sum}' || echo "0")
        fi
        
        if [ "$size_bytes" != "0" ] && [ -n "$size_bytes" ] && [ "$size_bytes" != "null" ]; then
            echo "scale=2; $size_bytes / 1048576" | bc 2>/dev/null || echo "0"
        else
            echo "0"
        fi
    else
        echo "0"
    fi
}

# Function to get local image size (Docker)
get_docker_local_size() {
    local image=$1
    
    # Clean image name for matching
    local clean_image=$(echo $image | sed 's/docker.io\///' | sed 's/@sha256:.*//')
    
    # Try docker images first
    local size_str=$(docker images --format "{{.Repository}}:{{.Tag}} {{.Size}}" | grep "^$clean_image " | head -1 | awk '{print $2}')
    
    if [ -n "$size_str" ] && [ "$size_str" != "0B" ]; then
        # Parse size string (e.g., "14.5MB", "1.2GB")
        local size_num=$(echo $size_str | sed 's/[A-Za-z]//g')
        local size_unit=$(echo $size_str | sed 's/[0-9.]//g')
        
        case $size_unit in
            "MB")
                echo "$size_num"
                return
                ;;
            "GB")
                echo "scale=2; $size_num * 1024" | bc 2>/dev/null || echo "0"
                return
                ;;
            "KB")
                echo "scale=2; $size_num / 1024" | bc 2>/dev/null || echo "0"
                return
                ;;
            "B")
                echo "scale=2; $size_num / 1048576" | bc 2>/dev/null || echo "0"
                return
                ;;
        esac
    fi
    
    # Fallback: use docker inspect
    local size_bytes=$(docker inspect $image 2>/dev/null | jq -r '.[0].Size // 0' 2>/dev/null)
    if [ -n "$size_bytes" ] && [ "$size_bytes" != "0" ] && [ "$size_bytes" != "null" ]; then
        echo "scale=2; $size_bytes / 1048576" | bc 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Function to get local image size (containerd)
get_containerd_local_size() {
    local image=$1
    
    # Clean image name for matching
    local clean_image=$(echo $image | sed 's/docker.io\///' | sed 's/@sha256:.*//')
    
    # Try to get size from ctr images ls
    local size_info=$(sudo ctr images ls 2>/dev/null | grep "$clean_image" | head -1 | awk '{print $3}')
    
    if [ -n "$size_info" ] && [ "$size_info" != "-" ]; then
        # Parse size (e.g., "14.5MiB", "1.2GiB")
        local size_num=$(echo $size_info | sed 's/[A-Za-z]//g')
        local size_unit=$(echo $size_info | sed 's/[0-9.]//g')
        
        case $size_unit in
            "MiB")
                echo "$size_num"
                return
                ;;
            "GiB")
                echo "scale=2; $size_num * 1024" | bc 2>/dev/null || echo "0"
                return
                ;;
            "KiB")
                echo "scale=2; $size_num / 1024" | bc 2>/dev/null || echo "0"
                return
                ;;
            "B")
                echo "scale=2; $size_num / 1048576" | bc 2>/dev/null || echo "0"
                return
                ;;
        esac
    fi
    
    # Alternative: try to get usage from ctr content
    local content_size=$(sudo ctr content ls 2>/dev/null | grep -v "DIGEST" | awk '{sum+=$3} END {if(sum>0) print sum/1048576; else print 0}')
    if [ -n "$content_size" ] && [ "$content_size" != "0" ]; then
        echo "$content_size"
    else
        echo "0"
    fi
}


# Function to test image with both runtimes
test_image() {
    local base_image=$1
    local platform=$2
    local image_type=$3
    
    local IMAGE="$base_image"
    
    # Try to get digest for cache busting
    if [ "$USE_DIGEST" = "true" ]; then
        echo "Attempting to get digest for $image_type image..."
        local DIGEST=$(get_image_digest $base_image $platform)
        if [ -n "$DIGEST" ]; then
            local repo_name=$(echo $base_image | cut -d'/' -f2- | cut -d':' -f1)
            IMAGE="docker.io/$repo_name@$DIGEST"
            echo "Using digest-based image: $IMAGE"
        else
            echo "Could not get digest, falling back to tag-based image: $IMAGE"
        fi
    fi

    echo ""
    echo "Testing $image_type image:"
    echo "Base image: $base_image"
    echo "Testing image: $IMAGE"
    echo "Platform: $platform"
    echo ""

    # Test with Docker (if available)
    if command -v docker >/dev/null 2>&1; then
        pull_image_docker "$IMAGE" "$platform"
    else
        echo "Docker not available, skipping Docker tests for $image_type"
    fi

    # Test with containerd (if available)
    if command -v ctr >/dev/null 2>&1; then
        pull_image_containerd "$IMAGE" "$platform"
    else
        echo "containerd not available, skipping containerd tests for $image_type"
    fi
}

echo "Starting performance measurements: Native vs WebAssembly comparison"
echo "Use digest: $USE_DIGEST"
echo ""

# Test native architecture image (multiarch)
NATIVE_IMAGE="docker.io/$NATIVE_REPO:$TAG"
test_image "$NATIVE_IMAGE" "$PLATFORM" "Native ($ARCH)"

# Test WebAssembly image
WASM_IMAGE="docker.io/$WASM_REPO:$TAG"
test_image "$WASM_IMAGE" "wasm" "WebAssembly"

echo "Performance measurement completed!"
echo "Results saved to: $output_file"
echo ""
echo "Summary:"
echo "Native vs WebAssembly Performance Comparison:"
if command -v python3 >/dev/null 2>&1; then
    python3 -c "
import pandas as pd
try:
    df = pd.read_csv('$output_file')
    
    # Determine image type based on image name
    df['Image Type'] = df['Image'].apply(lambda x: 'WebAssembly' if 'wasm' in x else 'Native')
    
    print('Average Performance by Runtime and Image Type:')
    summary = df.groupby(['Runtime', 'Image Type'])[['Pull Time (s)', 'Execution Time (s)', 'Repo Size (MB)', 'Host Size (MB)']].mean()
    print(summary.round(3))
    
    print('\nOverall averages by Image Type:')
    overall = df.groupby('Image Type')[['Pull Time (s)', 'Execution Time (s)', 'Repo Size (MB)', 'Host Size (MB)']].mean()
    print(overall.round(3))
    
    print('\nSize comparison (Native vs WASM):')
    native_repo = df[df['Image Type'] == 'Native']['Repo Size (MB)'].mean()
    wasm_repo = df[df['Image Type'] == 'WebAssembly']['Repo Size (MB)'].mean()
    native_host = df[df['Image Type'] == 'Native']['Host Size (MB)'].mean()
    wasm_host = df[df['Image Type'] == 'WebAssembly']['Host Size (MB)'].mean()
    
    if native_repo > 0 and wasm_repo > 0:
        repo_ratio = wasm_repo / native_repo
        print(f'WASM repo size is {repo_ratio:.2f}x the Native repo size ({wasm_repo:.1f}MB vs {native_repo:.1f}MB)')
    
    if native_host > 0 and wasm_host > 0:
        host_ratio = wasm_host / native_host  
        print(f'WASM host size is {host_ratio:.2f}x the Native host size ({wasm_host:.1f}MB vs {native_host:.1f}MB)')
    
    print('\nExecution time comparison (Native vs WASM):')
    native_exec = df[df['Image Type'] == 'Native']['Execution Time (s)'].mean()
    wasm_exec = df[df['Image Type'] == 'WebAssembly']['Execution Time (s)'].mean()
    if native_exec > 0 and wasm_exec > 0:
        exec_ratio = wasm_exec / native_exec
        print(f'WebAssembly is {exec_ratio:.2f}x slower than Native for execution ({wasm_exec:.3f}s vs {native_exec:.3f}s)')
    
except Exception as e:
    print(f'Error analyzing CSV file: {e}')
    print('Raw data:')
    with open('$output_file', 'r') as f:
        print(f.read())
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