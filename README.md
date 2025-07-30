# SQLite Multi-Architecture

A comprehensive SQLite build system supporting multiple architectures (AMD64, ARM64, RISC-V) and WebAssembly. This project creates feature-rich SQLite binaries with extensive datasets for testing and benchmarking.

## Features

- **Multi-architecture support**: Native builds for AMD64, ARM64, and RISC-V
- **WebAssembly**: WASI-compatible WebAssembly binaries
- **Comprehensive SQLite features**: Full-Text Search, R-Tree, JSON, mathematical functions, and more
- **Large test datasets**: Mathematical constants, prime numbers, dictionary words, and text samples
- **Container-ready**: Docker builds for all architectures
- **Performance measurement**: Built-in benchmarking tools

## Prerequisites

### For Local Builds
- [clang](https://github.com/llvm/llvm-project) (tested with clang 18)
- [gcc](https://gcc.gnu.org/) for native builds
- [WASI SDK sysroot](https://github.com/WebAssembly/wasi-sdk) (tested with version 24+)
- [wasmtime](https://wasmtime.dev/) for testing WebAssembly binaries

### For Docker Builds
- Docker with buildx support
- Containerd runtime capable of running WebAssembly binaries:
  - [Docker Desktop](https://docs.docker.com/desktop/features/wasm/) on desktops
  - [runwasi](https://github.com/containerd/runwasi) on servers

Set the `WASI_SYSROOT` environment variable to your WASI SDK installation path.

## Building

### Using Make (Recommended)

```bash
# Build both native and WebAssembly binaries
make

# Build only native binary for current architecture
make native

# Build only WebAssembly binary
make wasm

# Show build information and available targets
make info

# Clean build artifacts
make clean
```

### Using Docker

#### Multi-architecture native builds
```bash
# Build all architectures using the build script
./build.sh

# Or build individually:
docker buildx build --platform linux/amd64 -f Dockerfile.native -t your-repo/sqlite-multiarch:latest-amd64 --provenance false --output type=image,push=true .
docker buildx build --platform linux/arm64 -f Dockerfile.native -t your-repo/sqlite-multiarch:latest-arm64 --provenance false --output type=image,push=true .
docker buildx build --platform linux/riscv64 -f Dockerfile.riscv64 -t your-repo/sqlite-multiarch:latest-riscv64 --provenance false --output type=image,push=true .
```

#### WebAssembly build
```bash
docker buildx build --platform wasm -f Dockerfile.wasm -t your-repo/sqlite-wasm:latest --provenance false --output type=image,push=true .
```

## Running

### Local Execution

```bash
# Run native binary
./massive_sqlite

# Run WebAssembly binary
wasmtime --dir . massive_sqlite.wasm
```

### Docker Execution

#### Native containers
```bash
# Run specific architecture
docker run --platform linux/amd64 your-repo/sqlite-multiarch:latest-amd64
docker run --platform linux/arm64 your-repo/sqlite-multiarch:latest-arm64
docker run --platform linux/riscv64 your-repo/sqlite-multiarch:latest-riscv64
```

#### WebAssembly containers
```bash
# With Docker Desktop
docker run --platform wasm --runtime io.containerd.wasmtime.v1 your-repo/sqlite-wasm:latest

# With containerd directly
sudo ctr image pull your-repo/sqlite-wasm:latest
sudo ctr run --rm --platform wasm --runtime io.containerd.wasmtime.v1 your-repo/sqlite-wasm:latest sqlite-test
```

## Testing

```bash
# Test native binary
make test-native

# Test WebAssembly binary
make test-wasm
```

## Performance Measurement

The `measure_ctr.sh` script measures container pull times for benchmarking:

```bash
# Measure pull times (10 iterations)
./measure_ctr.sh 10
```

Results are saved to `timing_results.csv`.

## SQLite Configuration

This build includes comprehensive SQLite features:

- **Full-Text Search**: FTS3, FTS4, FTS5
- **Spatial**: R-Tree indexing, GEOPOLY
- **Data formats**: JSON1 extension
- **Analysis**: STAT4, DBSTAT_VTAB, EXPLAIN_COMMENTS
- **Advanced**: Session/snapshot support, mathematical functions
- **Performance**: Optimized with 256MB memory limit

## Project Structure

```
├── sqlite3.c              # SQLite amalgamation source
├── sqlite3.h              # SQLite header
├── comprehensive_sqlite.c # Main application with test data
├── dictionary_words.h     # Dictionary dataset
├── timestamps.h           # Timestamp utilities
├── generate_dictionary.py # Dictionary generator script
├── Makefile              # Build system
├── build.sh              # Multi-arch Docker build script
├── measure_ctr.sh        # Performance measurement script
├── Dockerfile.native     # Native Docker build
├── Dockerfile.riscv64    # RISC-V Docker build
├── Dockerfile.wasm       # WebAssembly Docker build
└── CLAUDE.md            # Development guidance
```

## Development

The application includes extensive test datasets:
- 50,000 mathematical constants
- 10,000 prime numbers
- 5,000 text samples
- Dictionary word corpus

These datasets enable comprehensive testing of SQLite's capabilities across different architectures and runtime environments.