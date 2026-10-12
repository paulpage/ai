# llama.cpp - Windows Installation

These instructions are for Windows/Vulkan, but it's worth keeping an eye on developments with Linux and/or AMD-native approaches.

1. Clone [llama.cpp](https://github.com/ggml-org/llama.cpp).
2. Download and install the [Vulkan SDK](https://vulkan.lunarg.com/sdk/home#windows) with default settings.
3. Run the following commands in a `cl.exe` enabled terminal (portable MSVC is ok):
```
cd llama.cpp
cmake -B build -G Ninja -DGGML_VULKAN=ON
cmake --build build --parallel
```

4. Run with `ai.bat chat` or `ai.bat agent`

# whisper.cpp - Windows Installation

Build it:

```
cd whisper.cpp
cmake --preset x64-windows-vulkan-release
cmake --build build-x64-windows-vulkan-release
```

Run with `ai.bat voice`, then `uv run whisper_demo.py` in another tab.

# To Do
- Look into search - Brave search API: https://api-dashboard.search.brave.com/app/plans?
- Look into System-one based decision models like [kev](https://github.com/jaredpalmer/kev.git)
