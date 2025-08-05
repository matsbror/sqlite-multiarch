#!/bin/bash

# Build script for multi-architecture Docker images

set -e

IMAGE_NAME="matsbror/massive-sqlite-native"
TAG=${TAG:-1.1}

echo "Building multi-architecture Docker images for $IMAGE_NAME:$TAG"

# Build AMD64 image
echo "Building AMD64 image..."
docker buildx build --no-cache --platform linux/amd64 -f Dockerfile.native -t ${IMAGE_NAME}:${TAG}-amd64 --provenance false --output type=image,push=true .

# Build ARM64 image
echo "Building ARM64 image..."
docker buildx build --no-cache --platform linux/arm64 -f Dockerfile.native -t ${IMAGE_NAME}:${TAG}-arm64 --provenance false --output type=image,push=true .

# Build RISCV64 image
echo "Building RISCV64 image..."
docker buildx build --no-cache --platform linux/riscv64 -f Dockerfile.riscv64 -t ${IMAGE_NAME}:${TAG}-riscv64 --provenance false --output type=image,push=true .

# Build WASM image
echo "Building WASM image..."
docker buildx build --no-cache --platform wasm -f Dockerfile.wasm -t matsbror/massive-sqlite-wasm:${TAG} --provenance false --output type=image,push=true .

echo "All builds completed successfully!"
echo "Images created:"
echo "  ${IMAGE_NAME}:${TAG}-amd64"
echo "  ${IMAGE_NAME}:${TAG}-arm64" 
echo "  ${IMAGE_NAME}:${TAG}-riscv64"
echo "  matsbror/massive-sqlite-wasm:${TAG}"

# Optional: Create and push multi-arch manifest
if command -v docker manifest &> /dev/null; then
    echo "Creating multi-architecture manifest..."
    docker manifest create ${IMAGE_NAME}:${TAG} \
        ${IMAGE_NAME}:${TAG}-amd64 \
        ${IMAGE_NAME}:${TAG}-arm64 \
        ${IMAGE_NAME}:${TAG}-riscv64
    
    docker manifest annotate ${IMAGE_NAME}:${TAG} ${IMAGE_NAME}:${TAG}-amd64 --arch amd64
    docker manifest annotate ${IMAGE_NAME}:${TAG} ${IMAGE_NAME}:${TAG}-arm64 --arch arm64
    docker manifest annotate ${IMAGE_NAME}:${TAG} ${IMAGE_NAME}:${TAG}-riscv64 --arch riscv64
    
    echo "Multi-arch manifest created: ${IMAGE_NAME}:${TAG}"
    echo "To push: docker manifest push ${IMAGE_NAME}:${TAG}"
    docker manifest push ${IMAGE_NAME}:${TAG}
fi
