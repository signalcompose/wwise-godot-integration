# ターゲットビルド: Web (Emscripten)

GDExtension の **Web ターゲット** (template_debug debug+profile + template_release) をビルドする手順。Web では editor ビルドは存在しません。

## ホスト要件

macOS ホストを前提に書いています（`tools/scripts/build-web.sh` および `env.sh` のデフォルトパスは macOS 前提）。基本環境（Python / uv / SCons / venv / Wwise SDK）は [ホスト環境セットアップ: macOS](host-setup-macos.md) を参照してください。Linux / Windows から Web ビルドを行う場合は別途環境変数を上書きしてください。

Web ビルドはこれに加えて **Emscripten SDK (emsdk)** が必要です。

ビルド済み wasm の使い方（Godot Web エクスポート、SharedArrayBuffer 用 HTTP ヘッダ、ローカル配信）は [web-export-guide.md](web-export-guide.md) を参照してください。本ファイルは **ビルド側** のみを扱います。

## 追加 SDK 要件

### 1. Emscripten SDK

リポジトリルートに `emsdk/` を配置します（`.gitignore` 除外、git 管理外）:

```bash
git clone https://github.com/emscripten-core/emsdk.git emsdk
cd emsdk
./emsdk install 4.0.23
./emsdk activate 4.0.23
```

`env.sh` のデフォルト:

- `EMSDK_DIR=$PROJECT_ROOT/emsdk`

`build-web.sh` が内部で `$EMSDK_DIR/emsdk_env.sh` を source するので、シェル側で事前に source しておく必要はありません。

### 2. Wwise SDK の Web パッケージ

Wwise Launcher の「Modify」から **Deployment Platforms → Emscripten** を有効化してください。インストール後は `$WWISE_SDK/Emscripten_mt`（マルチスレッド版）と `$WWISE_SDK/Emscripten_st`（シングルスレッド版）が存在する状態になります。本リポジトリは `threads=yes`（マルチスレッド版）を使います。

## ビルド

```bash
./tools/scripts/build-web.sh
```

スクリプトは次の 3 種を順にビルドします:

| target | wwise_config | 用途 |
|---|---|---|
| template_debug | debug | デバッグ可能なランタイム（プロファイラなし） |
| template_debug | profile | デバッグ + Wwise プロファイラ接続可 |
| template_release | release | 配布用最適化ビルド |

### パスを変える場合

```bash
WWISE_SDK=/path/to/other/wwise \
EMSDK_DIR=/path/to/other/emsdk \
  ./tools/scripts/build-web.sh
```

### 手動で SCons を直接呼ぶ場合

`addons/Wwise/native/` 内で実行:

```bash
source "$PROJECT_ROOT/emsdk/emsdk_env.sh"

SDK=/Applications/AudioKinetic/Wwise2025.1.3.9039/SDK

scons platform=web target=template_debug   threads=yes wwise_config=debug   wwise_sdk=$SDK
scons platform=web target=template_debug   threads=yes wwise_config=profile wwise_sdk=$SDK
scons platform=web target=template_release threads=yes wwise_config=release wwise_sdk=$SDK
```

Web は他プラットフォームと異なり `use_static_cpp` / `build_profile` / `precision=single` を指定しません。Emscripten には静的リンクすべき C++ ランタイムが無いこと、クラスフィルタリングは Godot 本体側のビルドで処理されることが理由です。詳細は `tools/scripts/build-web.sh` 内のコメントを参照。

## 出力先

```text
addons/Wwise/native/lib/web/
├── template_debug/{debug,profile}/libwwise.web.template_debug.*.wasm
├── template_release/release/libwwise.web.template_release.release.wasm
└── WwiseAudioWorklet.processor.js
```

## トラブルシュート

### `emsdk not found at ...`

`emsdk/` ディレクトリが存在しないか、`emsdk_env.sh` が無いパスを指しています。上記の **1. Emscripten SDK** の手順を実行してください。

### `emcc: command not found`

`emsdk_env.sh` の source が失敗しています（stderr に活性化エラーが出ているはずです）。`./emsdk activate 4.0.23` を再実行するか、`emsdk/upstream/emscripten/emcc` が実在するか確認してください。
