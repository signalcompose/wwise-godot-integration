# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GDExtension-based integration of Audiokinetic's Wwise audio middleware with Godot Engine 4.3+. The C++ library wraps the Wwise SDK and exposes it as Godot nodes, resources, and singletons via GDScript.

## Initial Setup

詳細なローカル環境構築（Python / uv / SCons / venv）は [docs/local-build-setup.md](docs/local-build-setup.md) を参照。

`godot-cpp` is the only submodule. Fetch it before building:

```bash
git submodule update --init --recursive
```

**Web (Emscripten) ビルドの準備:**  
`emsdk/` はリポジトリルートに配置済み（`.gitignore` 除外、git 管理外）。
Web ビルド前に以下で環境変数を有効化する:

```bash
source emsdk/emsdk_env.sh   # emcc 4.0.23 が PATH に追加される
```

emsdk が未インストールの場合:

```bash
git clone https://github.com/emscripten-core/emsdk.git emsdk
cd emsdk
./emsdk install 4.0.23
./emsdk activate 4.0.23
```

## Build Commands

ローカルビルドは `tools/scripts/` 配下のラッパースクリプト経由が標準です。`env.sh`（POSIX）/ `env.ps1`（Windows）が `WWISE_SDK` / `JAVA_HOME` / `ANDROID_NDK_HOME` / `EMSDK_DIR` などのデフォルトを集中管理し、必要に応じて環境変数で上書きできます。

```bash
# リポジトリルートから (macOS / Linux)
./tools/scripts/build-macos.sh    # macOS editor + template_debug + template_release
./tools/scripts/build-ios.sh      # iOS template_debug + template_release (arm64)
./tools/scripts/build-android.sh  # godot-cpp Android prebuild + Gradle assemble (arm64-v8a + armeabi-v7a, debug + release)
./tools/scripts/build-web.sh      # Web template_debug (debug + profile) + template_release
./tools/scripts/build-linux.sh    # Linux editor + template_debug + template_release
./tools/scripts/build-all.sh      # macOS / iOS / Android / Web を順次（macOS ホスト想定）
```

```powershell
# Windows (PowerShell)
.\tools\scripts\build-windows.ps1  # Windows editor + template_debug + template_release
```

```bash
# パスを上書き
WWISE_SDK=/other/path ./tools/scripts/build-macos.sh
```

詳細な環境構築・OS 別手順:

- macOS: [docs/local-build-setup-macos.md](docs/local-build-setup-macos.md)
- iOS: [docs/local-build-setup-ios.md](docs/local-build-setup-ios.md)
- Windows: [docs/local-build-setup-windows.md](docs/local-build-setup-windows.md)
- Linux: [docs/local-build-setup-linux.md](docs/local-build-setup-linux.md)
- Android: [docs/local-build-setup-android.md](docs/local-build-setup-android.md)
- Web: [docs/local-build-setup-web.md](docs/local-build-setup-web.md)

ホスト OS 別の基本環境構築（Python / uv / SCons / venv / Wwise SDK）は [docs/host-setup-{macos,windows,linux}.md](docs/local-build-setup.md#ホスト環境セットアップ) を参照。

**Key SCons options** (manual invocation reference):
- `platform`: `windows` | `macos` | `linux` | `ios` | `android` | `web`
- `target`: `editor` | `template_debug` | `template_release`
- `wwise_config`: `debug` | `profile` | `release`
- `wwise_sdk`: path to Wwise SDK root directory
- `plugins`: comma-separated list (`reflect`, `motion`, `convolution`, `soundseed_grain`, `soundseed_air`, `impacter`, `mastering_suite`)
- `dev_build=yes` / `asserts=yes`: enable debug features
- `use_static_cpp=yes` / `precision=single` / `build_profile=...`: standard flag set used by all native (non-Web) targets in CI

**Android (manual)** — Gradle が CMake / NDK を呼ぶため、godot-cpp Android 静的アーカイブの事前ビルドが必要です。`build-android.sh` はこれを自動で行いますが、手動で叩く場合:

```bash
# 1. godot-cpp prebuild (addons/Wwise/native/godot-cpp/)
scons platform=android target=template_debug arch={arm32,arm64} dev_build=yes precision=single
scons platform=android target=template_release arch={arm32,arm64} precision=single

# 2. Gradle assemble (addons/Wwise/native/android/)
./gradlew assemble -PWWISE_SDK=/path/to/SDK -Pprecision=single --no-daemon
```

`./gradlew assembleDebug` 単体では `lib/android/` への成果物コピーが走らないので、必ず `assemble` を使ってください。

## Architecture

### Unity Build Pattern

All C++ source files are `#include`d into a single translation unit via `src/wwise_gdextension_main.cpp`. This file is the sole compilation unit — **do not add `.cpp` files to SCons sources directly**; instead include them in `wwise_gdextension_main.cpp`.

### Class Registration

`wwise_gdextension_main.cpp` also contains `register_wwise_types()` / `unregister_wwise_types()`. Every new Godot-exposed class must be registered there with `ClassDB::register_class<T>()` at the appropriate initialization level (`SCENE` or `EDITOR`).

### Module Layout

```
src/
  core/           — Wwise singleton (Wwise), AkUtils, I/O hook, settings, platform info
  core/types/     — Godot Resource subclasses for Wwise objects (WwiseEvent, WwiseBank, etc.)
  scene/          — Godot Node subclasses (AkEvent2D/3D, AkListener, AkBank, AkGeometry, …)
  editor/         — Editor-only: Wwise Browser, inspector properties, project database
  editor/plugins/ — EditorPlugin subclasses registered via EditorPlugins::add_by_type<>()
  editor/properties/ — Custom inspector property editors for each Wwise type
  platform/       — Platform-specific code (Android JNI)
```

Editor code is gated behind `#if defined(TOOLS_ENABLED)` / `#ifdef TOOLS_ENABLED`.  
WAAPI (authoring API) is gated behind `#if defined(AK_WIN) || defined(AK_MAC_OS_X)`.

### Wwise Type Hierarchy

`WwiseBaseType` (Resource) is the base for all Wwise asset types. Each type (Event, Bank, RTPC, State, Switch, Trigger, AuxBus, AcousticTexture) stores `name`, `id` (short ID), and `guid`. They are saved as `.tres` files under the path configured in `AkEditorSettings`.

### Singletons Registered with the Engine

| C++ class | GDScript name | Init level |
|---|---|---|
| `Wwise` | `Wwise` | SCENE |
| `AkUtils` | `AkUtils` | SCENE |
| `WwiseSettings` | — (internal) | SCENE |
| `Waapi` | `Waapi` | EDITOR (Win/Mac only) |
| `WwiseProjectDatabase` | `WwiseProjectDatabase` | EDITOR |

## C++ Conventions

- **Indentation**: tabs
- **Headers**: `#pragma once`
- **Namespaces**: `using namespace godot;` at file scope
- **Class macros**: `GDCLASS(ClassName, ParentClass)` inside every exposed class
- **Method binding**: `static void _bind_methods()` in `protected:`
- **Singletons**: `static ClassName* singleton = nullptr;` + `ERR_FAIL_COND` guards in constructor/destructor
- **Naming**: PascalCase classes, snake_case methods/members, `UPPER_SNAKE_CASE` enum constants
- **Ak prefix**: Godot scene nodes (e.g., `AkEvent3D`, `AkListener2D`); **Wwise prefix**: Wwise SDK type wrappers (e.g., `WwiseEvent`, `WwiseBank`)
- **Error handling**: `ERR_FAIL_COND(...)` / `ERR_FAIL_COND_V(...)` for precondition checks
- **Formatting**: [.clang-format](addons/Wwise/native/src/.clang-format) defines the style (LLVM base, hard tabs, Allman braces, 120-col, C++20). Not enforced by CI/hooks; run `clang-format -i` manually on touched files

## Adding a New Exposed Class

1. Create `src/<module>/my_class.h` and `src/<module>/my_class.cpp`
2. Include the `.cpp` in `src/wwise_gdextension_main.cpp`
3. Register in `register_wwise_types()` with `ClassDB::register_class<MyClass>()`
4. If editor-only, wrap in `TOOLS_ENABLED` guards
5. Add XML documentation to `doc_classes/MyClass.xml` (triggers doc rebuild in SCons)

## Testing

Tests use GdUnit4. Open `tests/GodotProject/` in the Godot Editor and run `tests/GodotProject/test/test_wwise.gd`. There is no CLI test runner.

## Claude Code MCP (optional)

If your Claude Code setup has the **Context7** and **Serena** MCP plugins available, prefer them: Context7 for fetching current docs of libraries / SDKs / CLI tools (Godot, godot-cpp, Wwise authoring API, etc.), and Serena for semantic symbol navigation and symbol-level edits over reading whole files. Each server provides its own usage instructions when connected, so this is just a pointer — no setup steps live here.
