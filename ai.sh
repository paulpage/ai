#!/bin/sh
# Build first with ./build-linux.sh.

set -eu

ROOT="$(cd "$(dirname "$0")" && pwd)"
CHAT_MODEL="${CHAT_MODEL:-$ROOT/models/Qwen_Qwen3.5-9B-Q4_K_M.gguf}"
VOICE_MODEL="${VOICE_MODEL:-$ROOT/models/ggml-large-v3-turbo.bin}"

# The RX 6700 XT (gfx1031) runs the gfx1030 kernels ROCm ships.
export HSA_OVERRIDE_GFX_VERSION="${HSA_OVERRIDE_GFX_VERSION:-10.3.0}"

MODE="${1:-}"
if [ $# -gt 0 ]; then shift; fi

case "$MODE" in
    chat)
        exec "$ROOT/llama.cpp/build/bin/llama-server" -m "$CHAT_MODEL" -ngl 99 -c 8192 "$@"
        ;;
    agent)
        exec "$ROOT/llama.cpp/build/bin/llama-server" -m "$CHAT_MODEL" -ngl 99 -c 8192 --agent "$@"
        ;;
    voice)
        exec "$ROOT/whisper.cpp/build/bin/whisper-server" --model "$VOICE_MODEL" --port 8081 "$@"
        ;;
    kev)
        # --no-sync keeps uv from swapping the ROCm torch build-linux.sh installed for the CUDA one.
        # bf16 matmul segfaults in torch's bundled rocBLAS on the 6700 XT, so serve in fp16.
        export KEV_DTYPE="${KEV_DTYPE:-fp16}"
        cd "$ROOT/kev"
        exec uv run --no-sync python -m kev.serve --run jaredpalmer/kev-4b --port 8009 "$@"
        ;;
    *)
        echo "Usage: ai.sh [chat|agent|voice|kev] [extra args...]"
        echo "  chat  - Run LLM in chat mode"
        echo "  agent - Run LLM in agent mode"
        echo "  voice - Run whisper speech recognition server (port: 8081)"
        echo "  kev   - Run kev decision model server (port: 8009)"
        exit 1
        ;;
esac
