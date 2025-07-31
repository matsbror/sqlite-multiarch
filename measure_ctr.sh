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
TAG="1.0"

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
echo "Runtime,Image,Platform,Iteration,Start Timestamp,Pull Complete Timestamp,Execution Complete Timestamp,Pull Time (s),Container Start to Main Time (s),Main to Elapsed Time (s),Total Execution Time (s),Host Size (MB)" > $output_file

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
        
        # Remove image if present and clear containerd cache thoroughly
        sudo ctr image rm $image 2>/dev/null
        sudo ctr image prune --all >/dev/null 2>&1
        # Also clear content store blobs and snapshots
        sudo ctr content prune >/dev/null 2>&1
        sudo ctr snapshots prune >/dev/null 2>&1
        # Clear any remaining content with force
        sudo ctr content ls -q 2>/dev/null | head -20 | xargs -r sudo ctr content rm 2>/dev/null || true

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
        
        # Execute container and capture output with timestamps
        exec_output=""
        if [[ $image == *"wasm"* ]]; then
            exec_output=$(sudo ctr run --rm --runtime io.containerd.wasmtime.v1 $image test-container-$i 2>&1)
        else
            exec_output=$(sudo ctr run --rm $image test-container-$i 2>&1)
        fi
        
        # Timestamp after execution complete
        exec_complete_timestamp=$(date +%s)
        exec_complete_time=$(date +%s.%3N)

        # Parse timestamps from output
        main_timestamp=""
        elapsed_timestamp=""
        
        # Extract main timestamp (looking for "main, timestamp, <number>")
        main_line=$(echo "$exec_output" | grep "main, timestamp," | head -1)
        if [ -n "$main_line" ]; then
            main_timestamp=$(echo "$main_line" | sed -n 's/.*main, timestamp, \([0-9][0-9]*\).*/\1/p')
            # If sed didn't work, try a simpler approach
            if [ -z "$main_timestamp" ]; then
                main_timestamp=$(echo "$main_line" | awk -F', ' '{print $3}' | tr -d '\r\n ')
            fi
        fi
        
        # Extract elapsed timestamp (looking for "duration, elapsed time, <number>")
        elapsed_line=$(echo "$exec_output" | grep "duration, elapsed time," | head -1)
        if [ -n "$elapsed_line" ]; then
            elapsed_timestamp=$(echo "$elapsed_line" | sed -n 's/.*duration, elapsed time, \([0-9][0-9]*\).*/\1/p')
            # If sed didn't work, try a simpler approach
            if [ -z "$elapsed_timestamp" ]; then
                elapsed_timestamp=$(echo "$elapsed_line" | awk -F', ' '{print $3}' | tr -d '\r\n ')
            fi
        fi

        # Calculate times
        pull_elapsed=$(echo "$pull_complete_time - $start_time" | bc)
        total_exec_elapsed=$(echo "$exec_complete_time - $pull_complete_time" | bc)
        
        # Calculate container start to main time (if main timestamp available)
        container_to_main=""
        if [ -n "$main_timestamp" ]; then
            # main_timestamp is in milliseconds, pull_complete_timestamp is in seconds
            # Convert pull_complete_timestamp to milliseconds and calculate difference in seconds
            container_to_main=$(echo "scale=3; ($main_timestamp - $pull_complete_timestamp * 1000) / 1000" | bc)
        else
            container_to_main="N/A"
        fi
        
        # Calculate main to elapsed time (elapsed_timestamp is duration in milliseconds)
        main_to_elapsed=""
        if [ -n "$elapsed_timestamp" ]; then
            # elapsed_timestamp is duration in milliseconds, convert to seconds
            main_to_elapsed=$(echo "scale=3; $elapsed_timestamp / 1000" | bc)
        else
            main_to_elapsed="N/A"
        fi
        
        accumulated_pull_time=$(echo "$accumulated_pull_time + $pull_elapsed" | bc)
        accumulated_exec_time=$(echo "$accumulated_exec_time + $total_exec_elapsed" | bc)
        
        # Get image sizes
        host_size=$(get_containerd_local_size $image)
        
        # Log to CSV
        echo "$runtime_name,$image,$platform,$i,$start_timestamp,$pull_complete_timestamp,$exec_complete_timestamp,$pull_elapsed,$container_to_main,$main_to_elapsed,$total_exec_elapsed,$host_size" >> $output_file
        
        echo "pull: ${pull_elapsed}s, start->main: ${container_to_main}s, main->elapsed: ${main_to_elapsed}s, total exec: ${total_exec_elapsed}s, host: ${host_size}MB"
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
        
        # Execute container and capture output with timestamps
        exec_output=""
        if [[ $image == *"wasm"* ]]; then
            exec_output=$(docker run --rm --runtime io.containerd.wasmtime.v1 $image 2>&1)
        else
            exec_output=$(docker run --rm $image 2>&1)
        fi
        
        # Timestamp after execution complete
        exec_complete_timestamp=$(date +%s)
        exec_complete_time=$(date +%s.%3N)

        # Parse timestamps from output
        main_timestamp=""
        elapsed_timestamp=""
        
        # Extract main timestamp (looking for "main, timestamp, <number>")
        main_line=$(echo "$exec_output" | grep "main, timestamp," | head -1)
        if [ -n "$main_line" ]; then
            main_timestamp=$(echo "$main_line" | sed -n 's/.*main, timestamp, \([0-9][0-9]*\).*/\1/p')
            # If sed didn't work, try a simpler approach
            if [ -z "$main_timestamp" ]; then
                main_timestamp=$(echo "$main_line" | awk -F', ' '{print $3}' | tr -d '\r\n ')
            fi
        fi
        
        # Extract elapsed timestamp (looking for "duration, elapsed time, <number>")
        elapsed_line=$(echo "$exec_output" | grep "duration, elapsed time," | head -1)
        if [ -n "$elapsed_line" ]; then
            elapsed_timestamp=$(echo "$elapsed_line" | sed -n 's/.*duration, elapsed time, \([0-9][0-9]*\).*/\1/p')
            # If sed didn't work, try a simpler approach
            if [ -z "$elapsed_timestamp" ]; then
                elapsed_timestamp=$(echo "$elapsed_line" | awk -F', ' '{print $3}' | tr -d '\r\n ')
            fi
        fi

        # Calculate times
        pull_elapsed=$(echo "$pull_complete_time - $start_time" | bc)
        total_exec_elapsed=$(echo "$exec_complete_time - $pull_complete_time" | bc)
        
        # Calculate container start to main time (if main timestamp available)
        container_to_main=""
        if [ -n "$main_timestamp" ]; then
            # main_timestamp is in milliseconds, pull_complete_timestamp is in seconds
            # Convert pull_complete_timestamp to milliseconds and calculate difference in seconds
            container_to_main=$(echo "scale=3; ($main_timestamp - $pull_complete_timestamp * 1000) / 1000" | bc)
        else
            container_to_main="N/A"
        fi
        
        # Calculate main to elapsed time (elapsed_timestamp is duration in milliseconds)
        main_to_elapsed=""
        if [ -n "$elapsed_timestamp" ]; then
            # elapsed_timestamp is duration in milliseconds, convert to seconds
            main_to_elapsed=$(echo "scale=3; $elapsed_timestamp / 1000" | bc)
        else
            main_to_elapsed="N/A"
        fi
        
        accumulated_pull_time=$(echo "$accumulated_pull_time + $pull_elapsed" | bc)
        accumulated_exec_time=$(echo "$accumulated_exec_time + $total_exec_elapsed" | bc)
        
        # Get image sizes
        host_size=$(get_docker_local_size $image)
        
        # Log to CSV
        echo "$runtime_name,$image,$platform,$i,$start_timestamp,$pull_complete_timestamp,$exec_complete_timestamp,$pull_elapsed,$container_to_main,$main_to_elapsed,$total_exec_elapsed,$host_size" >> $output_file
        
        echo "pull: ${pull_elapsed}s, start->main: ${container_to_main}s, main->elapsed: ${main_to_elapsed}s, total exec: ${total_exec_elapsed}s, host: ${host_size}MB"
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
    
    # Try to get size from ctr images ls - be more flexible with image name matching
    local size_info=$(sudo ctr images ls 2>/dev/null | grep -E "(${clean_image}|${image})" | head -1 | awk '{print $3}')
    
    if [ -n "$size_info" ] && [ "$size_info" != "-" ]; then
        # Parse size (e.g., "14.5MiB", "1.2GiB")  
        local size_num=$(echo $size_info | sed 's/[A-Za-z]//g')
        local size_unit=$(echo $size_info | sed 's/[0-9.]//g')
        
        case $size_unit in
            "MiB"|"MB")
                echo "$size_num"
                return
                ;;
            "GiB"|"GB")
                echo "scale=2; $size_num * 1024" | bc 2>/dev/null || echo "0"
                return
                ;;
            "KiB"|"KB")
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
    summary = df.groupby(['Runtime', 'Image Type'])[['Pull Time (s)', 'Container Start to Main Time (s)', 'Main to Elapsed Time (s)', 'Total Execution Time (s)', 'Host Size (MB)']].mean()
    print(summary.round(3))
    
    print('\nOverall averages by Image Type:')
    overall = df.groupby('Image Type')[['Pull Time (s)', 'Container Start to Main Time (s)', 'Main to Elapsed Time (s)', 'Total Execution Time (s)', 'Host Size (MB)']].mean()
    print(overall.round(3))
    
    print('\nHost size comparison (Native vs WASM):')
    native_host = df[df['Image Type'] == 'Native']['Host Size (MB)'].mean()
    wasm_host = df[df['Image Type'] == 'WebAssembly']['Host Size (MB)'].mean()
    
    if native_host > 0 and wasm_host > 0:
        host_ratio = wasm_host / native_host  
        print(f'WASM host size is {host_ratio:.2f}x the Native host size ({wasm_host:.1f}MB vs {native_host:.1f}MB)')
    elif native_host > 0:
        print(f'Native host size: {native_host:.1f}MB')
        print(f'WASM host size: {wasm_host:.1f}MB (detection may need improvement)')
    else:
        print('Host size detection needs improvement for both image types')
    
    print('\nPull time comparison (Native vs WASM):')
    native_pull = df[df['Image Type'] == 'Native']['Pull Time (s)'].mean()
    wasm_pull = df[df['Image Type'] == 'WebAssembly']['Pull Time (s)'].mean()
    if native_pull > 0 and wasm_pull > 0:
        pull_ratio = wasm_pull / native_pull
        print(f'WASM pulls are {pull_ratio:.2f}x slower than Native ({wasm_pull:.3f}s vs {native_pull:.3f}s)')
    
    print('\nExecution time comparison (Native vs WASM):')
    native_exec = df[df['Image Type'] == 'Native']['Total Execution Time (s)'].mean()
    wasm_exec = df[df['Image Type'] == 'WebAssembly']['Total Execution Time (s)'].mean()
    if native_exec > 0 and wasm_exec > 0:
        exec_ratio = wasm_exec / native_exec
        print(f'WASM execution is {exec_ratio:.2f}x slower than Native ({wasm_exec:.3f}s vs {native_exec:.3f}s)')
    
    print('\nContainer startup time comparison (Native vs WASM):')
    native_startup = df[df['Image Type'] == 'Native']['Container Start to Main Time (s)'].mean()
    wasm_startup = df[df['Image Type'] == 'WebAssembly']['Container Start to Main Time (s)'].mean()
    if not pd.isna(native_startup) and not pd.isna(wasm_startup) and native_startup > 0 and wasm_startup > 0:
        startup_ratio = wasm_startup / native_startup
        print(f'WASM startup is {startup_ratio:.2f}x slower than Native ({wasm_startup:.3f}s vs {native_startup:.3f}s)')
    else:
        print(f'Native startup time: {native_startup:.3f}s, WASM startup time: {wasm_startup:.3f}s (one or both may be NaN)')
    
    print('\nProgram execution time comparison (main to elapsed):')
    native_prog = df[df['Image Type'] == 'Native']['Main to Elapsed Time (s)'].mean()
    wasm_prog = df[df['Image Type'] == 'WebAssembly']['Main to Elapsed Time (s)'].mean()
    if not pd.isna(native_prog) and not pd.isna(wasm_prog) and native_prog > 0 and wasm_prog > 0:
        prog_ratio = wasm_prog / native_prog
        print(f'WASM program execution is {prog_ratio:.2f}x slower than Native ({wasm_prog:.3f}s vs {native_prog:.3f}s)')
    else:
        print(f'Native program time: {native_prog:.3f}s, WASM program time: {wasm_prog:.3f}s (one or both may be NaN)')
    
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