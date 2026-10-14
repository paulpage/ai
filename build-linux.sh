#!/usr/bin/env bash
# Build the dependent projects (llama.cpp, whisper.cpp, kev) on Linux.
#
# Targets an AMD RX 6700 XT (RDNA2, gfx1031). ROCm doesn't ship gfx1031 kernels,
# so we build for gfx1030 and run with HSA_OVERRIDE_GFX_VERSION=10.3.0.
# Uses ROCm (HIP) by default; set BACKEND=vulkan or cpu to build without it.
#
# Usage: ./build-linux.sh [llama|whisper|kev ...]   (default: all)
# Env:   BACKEND=hip|vulkan|cpu   force a GPU backend for llama.cpp / whisper.cpp
#        GPU_TARGET=gfx1030       HIP target architecture
#        JOBS=N                   parallel build jobs (default: nproc)
#        TORCH_ROCM=rocm6.4       PyTorch ROCm wheel index for kev

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GPU_TARGET="${GPU_TARGET:-gfx1030}"
JOBS="${JOBS:-$(nproc)}"
TORCH_ROCM="${TORCH_ROCM:-rocm6.4}"

# Arch / AMD packages install ROCm under /opt/rocm without adding it to PATH.
if [[ -d /opt/rocm/bin && ":$PATH:" != *":/opt/rocm/bin:"* ]]; then
    export PATH="/opt/rocm/bin:$PATH"
fi

log() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }

BACKEND="${BACKEND:-hip}"
needs_ggml=0
for t in "${@:-llama whisper}"; do
    [[ "$t" == llama* || "$t" == whisper* ]] && needs_ggml=1
done
if [[ "$BACKEND" == hip && $needs_ggml == 1 ]] && ! command -v hipconfig >/dev/null; then
    echo "ROCm not found (no hipconfig). Install it with:" >&2
    echo "    sudo pacman -S rocm-hip-sdk rocminfo" >&2
    echo "or build with another backend: BACKEND=vulkan|cpu $0 $*" >&2
    exit 1
fi

# CMake flags for the ggml backend shared by llama.cpp and whisper.cpp.
# Every backend is set explicitly so a previous run's CMakeCache can't leave one on.
ggml_backend_flags() {
    case "$BACKEND" in
        # --rocm-path: Arch puts clang in /opt/rocm/lib/llvm, so it guesses /opt/rocm/lib
        # as the ROCm root and misses /opt/rocm/include.
        hip) echo "-DGGML_HIP=ON -DGGML_VULKAN=OFF -DGPU_TARGETS=$GPU_TARGET -DAMDGPU_TARGETS=$GPU_TARGET -DCMAKE_HIP_FLAGS=--rocm-path=$(hipconfig -R)" ;;
        vulkan) echo "-DGGML_HIP=OFF -DGGML_VULKAN=ON" ;;
        cpu) echo "-DGGML_HIP=OFF -DGGML_VULKAN=OFF" ;;
        *) echo "unknown BACKEND: $BACKEND" >&2; exit 1 ;;
    esac
}

# Configure and build a ggml-based CMake project into <dir>/build.
cmake_build() {
    local dir="$1"; shift
    local -a env=()
    if [[ "$BACKEND" == hip ]]; then
        env=(HIPCXX="$(hipconfig -l)/clang" HIP_PATH="$(hipconfig -R)")
    fi
    # shellcheck disable=SC2046
    env "${env[@]}" cmake -S "$ROOT/$dir" -B "$ROOT/$dir/build" -G Ninja \
        -DCMAKE_BUILD_TYPE=Release $(ggml_backend_flags) "$@"
    cmake --build "$ROOT/$dir/build" --config Release -j "$JOBS"
}

build_llama() {
    log "llama.cpp ($BACKEND)"
    cmake_build llama.cpp
}

build_whisper() {
    log "whisper.cpp ($BACKEND)"
    cmake_build whisper.cpp -DWHISPER_BUILD_SERVER=ON
}

build_kev() {
    log "kev (uv)"
    command -v uv >/dev/null || { echo "uv is required: sudo pacman -S uv" >&2; exit 1; }
    cd "$ROOT/kev"
    # The locked Linux torch wheel is the CUDA build; swap in the ROCm wheel.
    # PyTorch's ROCm wheels bundle their own runtime, so system ROCm isn't required.
    uv sync --extra serve --no-install-package torch --no-install-package triton
    local torch_version
    torch_version="$(awk '/^name = "torch"$/ { getline; gsub(/[^0-9.]/, ""); print; exit }' uv.lock)"
    uv pip install --reinstall "torch==$torch_version" \
        --index-url "https://download.pytorch.org/whl/$TORCH_ROCM"
    cd "$ROOT"
}

targets=("$@")
[[ ${#targets[@]} -eq 0 ]] && targets=(llama whisper kev)

git -C "$ROOT" submodule update --init --recursive

for t in "${targets[@]}"; do
    case "$t" in
        llama | llama.cpp) build_llama ;;
        whisper | whisper.cpp) build_whisper ;;
        kev) build_kev ;;
        *) echo "unknown target: $t (expected llama, whisper, kev)" >&2; exit 1 ;;
    esac
done

log "Done"
cat <<EOF
Runtime notes for the RX 6700 XT:
  export HSA_OVERRIDE_GFX_VERSION=10.3.0   # needed for ROCm builds and ROCm torch
  llama.cpp:   llama.cpp/build/bin/llama-server
  whisper.cpp: whisper.cpp/build/bin/whisper-server
  kev:         cd kev && uv run --no-sync python -m kev.serve --run jaredpalmer/kev-4b --port 8009
               (--no-sync keeps uv from reinstalling the CUDA torch wheel)
EOF
