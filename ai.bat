@echo off

set CHAT_MODEL=.\\models\\Qwen_Qwen3.5-9B-Q4_K_M.gguf
set VOICE_MODEL=.\\models\\ggml-large-v3-turbo.bin

set "MODE=%~1"

if "%MODE%"=="chat" (
    .\\llama.cpp\\build\\bin\\llama-server.exe -m %CHAT_MODEL% -ngl 99 -c 8192
) else if "%MODE%"=="agent" (
    .\\llama.cpp\\build\\bin\\llama-server.exe -m %CHAT_MODEL% -ngl 99 -c 8192 --agent
) else if "%MODE%"=="voice" (
    .\\whisper.cpp\\build-x64-windows-vulkan-release\\bin\\whisper-server.exe --model %VOICE_MODEL% --port 8081
) else (
    echo Usage: ai.bat [chat|agent|voice]
    echo   chat  - Run LLM in chat mode (default)
    echo   agent - Run LLM in agent mode
    echo   voice - Run whisper speech recognition server (port: 8081)
)
