# Makefile for SQLite multi-architecture builds

# Configuration
CC = gcc
WASI_CC = clang
TARGET_NATIVE = massive_sqlite
TARGET_WASM = massive_sqlite.wasm

# Source files
SOURCES = sqlite3.c comprehensive_sqlite.c
HEADERS = sqlite3.h dictionary_words.h timestamps.h

# SQLite feature flags
SQLITE_FLAGS = -DSQLITE_ENABLE_FTS3 \
               -DSQLITE_ENABLE_FTS4 \
               -DSQLITE_ENABLE_FTS5 \
               -DSQLITE_ENABLE_RTREE \
               -DSQLITE_ENABLE_JSON1 \
               -DSQLITE_ENABLE_GEOPOLY \
               -DSQLITE_ENABLE_MATH_FUNCTIONS \
               -DSQLITE_ENABLE_STAT4 \
               -DSQLITE_ENABLE_UPDATE_DELETE_LIMIT \
               -DSQLITE_ENABLE_COLUMN_METADATA \
               -DSQLITE_ENABLE_DBSTAT_VTAB \
               -DSQLITE_ENABLE_EXPLAIN_COMMENTS \
               -DSQLITE_ENABLE_NORMALIZE \
               -DSQLITE_ENABLE_PREUPDATE_HOOK \
               -DSQLITE_ENABLE_SESSION \
               -DSQLITE_ENABLE_SNAPSHOT \
               -DSQLITE_ENABLE_STMTVTAB \
               -DSQLITE_ENABLE_UNKNOWN_SQL_FUNCTION \
               -DSQLITE_SOUNDEX \
               -DSQLITE_MAX_MEMORY=268435456 \
               -DSQLITE_OMIT_LOAD_EXTENSION

# Compiler flags
CFLAGS_NATIVE = $(SQLITE_FLAGS) -O2 -static -s
CFLAGS_WASM = $(SQLITE_FLAGS) -O2 --target=wasm32-wasi

# Libraries
LIBS = -lm

# WASI SDK configuration
ifndef WASI_SYSROOT
    $(error WASI_SYSROOT environment variable must be set to WASI SDK path)
endif

WASI_FLAGS = --sysroot=$(WASI_SYSROOT)

# Default target
.PHONY: all
all: native wasm

# Native build for current architecture
.PHONY: native
native: $(TARGET_NATIVE)

$(TARGET_NATIVE): $(SOURCES) $(HEADERS)
	$(CC) $(CFLAGS_NATIVE) $(SOURCES) -o $(TARGET_NATIVE) $(LIBS)

# WebAssembly build
.PHONY: wasm
wasm: $(TARGET_WASM)

$(TARGET_WASM): $(SOURCES) $(HEADERS)
	$(WASI_CC) $(CFLAGS_WASM) $(WASI_FLAGS) $(SOURCES) -o $(TARGET_WASM) $(LIBS)

# Generate dictionary header (if needed)
.PHONY: dictionary
dictionary: dictionary_words.h

dictionary_words.h:
	python3 generate_dictionary.py

# Clean build artifacts
.PHONY: clean
clean:
	rm -f $(TARGET_NATIVE) $(TARGET_WASM)

# Test native binary
.PHONY: test-native
test-native: $(TARGET_NATIVE)
	./$(TARGET_NATIVE)

# Test WASM binary (requires wasmtime)
.PHONY: test-wasm
test-wasm: $(TARGET_WASM)
	wasmtime --dir . $(TARGET_WASM)

# Show build info
.PHONY: info
info:
	@echo "SQLite Multi-Architecture Build"
	@echo "==============================="
	@echo "Native target: $(TARGET_NATIVE)"
	@echo "WASM target: $(TARGET_WASM)"
	@echo "Native compiler: $(CC)"
	@echo "WASM compiler: $(WASI_CC)"
	@echo "WASI sysroot: $(WASI_SYSROOT)"
	@echo ""
	@echo "Available targets:"
	@echo "  all        - Build both native and WASM"
	@echo "  native     - Build native binary"
	@echo "  wasm       - Build WebAssembly binary"
	@echo "  dictionary - Generate dictionary header"
	@echo "  clean      - Remove build artifacts"
	@echo "  test-native - Test native binary"
	@echo "  test-wasm   - Test WASM binary (requires wasmtime)"
	@echo "  info       - Show this information"

# Help target
.PHONY: help
help: info