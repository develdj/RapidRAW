#!/bin/bash
# CUDA-OPTIMIZED BUILD FOR RAPIDRAW ON JETSON AGX ORIN
# Leverages CUDA 12.8 for GPU-accelerated image processing

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${PURPLE}🚀 RAPIDRAW CUDA-ACCELERATED BUILD FOR AGX ORIN 🚀${NC}"
echo -e "${CYAN}CUDA 12.8 + Ampere GPU + WGPU = Maximum Performance${NC}"

# System check
echo -e "${BLUE}System Check:${NC}"
TOTAL_RAM=$(free -g | grep '^Mem:' | awk '{print $2}')
GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null || echo "Unknown")
CUDA_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null || echo "Unknown")
echo -e "  • RAM: ${TOTAL_RAM}GB"
echo -e "  • GPU: ${GPU_NAME}"
echo -e "  • CUDA Driver: ${CUDA_VERSION}"

# Check for required files
if [ ! -f "package.json" ] || [ ! -f "src-tauri/Cargo.toml" ]; then
    echo -e "${RED}ERROR: This script must be run from the RapidRAW project root${NC}"
    echo "Please ensure you have cloned the RapidRAW repository:"
    echo "  git clone https://github.com/CyberTimon/RapidRAW.git"
    echo "  cd RapidRAW"
    exit 1
fi

# Set maximum performance
echo -e "${BLUE}Setting maximum GPU performance...${NC}"
if command -v nvpmodel &> /dev/null; then
    sudo nvpmodel -m 0 2>/dev/null && echo "✅ Max performance mode" || echo "⚠️  Need sudo for max performance"
fi
if command -v jetson_clocks &> /dev/null; then
    sudo jetson_clocks 2>/dev/null && echo "✅ Max clocks enabled" || echo "⚠️  Need sudo for max clocks"
fi

# Enable Docker BuildKit for better caching
export DOCKER_BUILDKIT=1
export BUILDKIT_PROGRESS=plain

# Build arguments for optimization
BUILD_ARGS=(
    "--build-arg" "BUILDKIT_INLINE_CACHE=1"
    "--build-arg" "RUSTFLAGS=-C target-cpu=cortex-a78 -C opt-level=3"
)

echo -e "${GREEN}Building CUDA-optimized RapidRAW container...${NC}"
echo -e "${BLUE}This will take 15-30 minutes for the first build${NC}"

# Build with progress output
time docker build \
    --progress=plain \
    --platform linux/arm64 \
    "${BUILD_ARGS[@]}" \
    -f Dockerfile.cuda \
    -t rapidraw-cuda:latest \
    -t rapidraw-cuda:agx-orin \
    .

# Check if build succeeded
if [ $? -eq 0 ]; then
    BUILD_SIZE=$(docker images rapidraw-cuda:latest --format "{{.Size}}")
    echo -e "${GREEN}🎉 BUILD COMPLETED! Image size: $BUILD_SIZE${NC}"
else
    echo -e "${RED}❌ Build failed! Check the error messages above.${NC}"
    exit 1
fi

# Create directories for persistent storage
echo -e "${BLUE}Creating directories for persistent storage...${NC}"
mkdir -p ~/rapidraw/{pictures,desktop,config}

echo -e "${PURPLE}📋 DEPLOYMENT INSTRUCTIONS:${NC}"
echo ""
echo -e "${GREEN}1. Run with Docker:${NC}"
echo "docker run -d --name rapidraw-gpu \\"
echo "  --runtime nvidia --restart unless-stopped \\"
echo "  --shm-size=2g \\"
echo "  -p 6080:6080 -p 5901:5901 \\"
echo "  -v ~/rapidraw/pictures:/home/ai/Pictures \\"
echo "  -v ~/rapidraw/desktop:/home/ai/Desktop \\"
echo "  -v ~/rapidraw/config:/home/ai/.config \\"
echo "  -e NVIDIA_VISIBLE_DEVICES=all \\"
echo "  -e NVIDIA_DRIVER_CAPABILITIES=all \\"
echo "  rapidraw-cuda:latest"
echo ""
echo -e "${GREEN}2. Access RapidRAW:${NC}"
echo "  • Web Browser: http://localhost:6080/vnc.html"
echo "  • VNC Client: localhost:5901"
echo "  • No password required!"
echo ""
echo -e "${GREEN}3. Docker Compose (alternative):${NC}"
echo "Create docker-compose.cuda.yml with:"
echo "---"
cat << 'COMPOSE'
version: '3.8'
services:
  rapidraw-gpu:
    image: rapidraw-cuda:latest
    container_name: rapidraw-gpu
    runtime: nvidia
    restart: unless-stopped
    ports:
      - "6080:6080"
      - "5901:5901"
    shm_size: '2gb'
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=all
      - VNC_RESOLUTION=1920x1080
    volumes:
      - ~/rapidraw/pictures:/home/ai/Pictures
      - ~/rapidraw/desktop:/home/ai/Desktop
      - ~/rapidraw/config:/home/ai/.config
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
COMPOSE
echo "---"
echo ""
echo -e "${CYAN}🎯 GPU FEATURES ENABLED:${NC}"
echo "  • WGPU Vulkan backend for GPU compute"
echo "  • CUDA-accelerated image decoding"
echo "  • GPU-based RAW processing pipeline"
echo "  • Hardware-accelerated video codecs"
echo "  • Parallel image processing"
echo ""
echo -e "${PURPLE}🚀 Your AGX Orin is ready for GPU-accelerated photo editing!${NC}"
