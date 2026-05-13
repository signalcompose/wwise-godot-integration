# ターゲットビルド: macOS

GDExtension の **macOS ターゲット** (editor + template_debug + template_release) をビルドする手順。

## ホスト要件

macOS ホストが必要です。基本環境（Python / uv / SCons / venv / Wwise SDK）は [ホスト環境セットアップ: macOS](host-setup-macos.md) を参照してください。

## 追加 SDK 要件

Wwise Launcher の「Modify」から以下を有効化:

- **Deployment Platforms → Apple → macOS**

## ビルド

リポジトリルートから:

```bash
./tools/scripts/build-macos.sh
```

スクリプトは `editor` / `template_debug` / `template_release` の 3 種をまとめてビルドします。`WWISE_SDK` が `env.sh` のデフォルトと違う場合は環境変数で上書き:

```bash
WWISE_SDK=/Applications/AudioKinetic/Wwise2025.1.3.9039/SDK \
  ./tools/scripts/build-macos.sh
```

### 手動で SCons を直接呼ぶ場合

CI 等価コマンド（`addons/Wwise/native/` 内で実行）:

```bash
SDK=/Applications/AudioKinetic/Wwise2025.1.3.9039/SDK

scons platform=macos target=editor           wwise_config=profile use_static_cpp=yes wwise_sdk=$SDK build_profile=build_profile_editor.json  precision=single
scons platform=macos target=template_debug   wwise_config=profile use_static_cpp=yes wwise_sdk=$SDK build_profile=build_profile_runtime.json precision=single
scons platform=macos target=template_release wwise_config=release use_static_cpp=yes wwise_sdk=$SDK build_profile=build_profile_runtime.json precision=single
```

## 出力先

```text
addons/Wwise/native/lib/macos/
├── editor/profile/libwwise.macos.editor.profile.framework
├── template_debug/profile/libwwise.macos.template_debug.profile.framework
└── template_release/release/libwwise.macos.template_release.release.framework
```

各 framework と同じ階層の `DSP/` 配下に Wwise SDK 由来の DSP プラグイン（AkReflect, AkSoundSeedAir, iZotope, McDSP, Auro, MasteringSuite 等）が `.dylib` 形式でコピーされます。
