# ターゲットビルド: iOS

GDExtension の **iOS ターゲット** (template_debug + template_release, arm64) をビルドする手順。iOS では editor ビルドは存在しません。

## ホスト要件

macOS ホスト + Xcode が必要です。基本環境（Python / uv / SCons / venv / Wwise SDK）は [ホスト環境セットアップ: macOS](host-setup-macos.md) を参照してください。Xcode は App Store からインストールし、`xcode-select --install` でコマンドラインツールを有効化してください。

## 追加 SDK 要件

Wwise Launcher の「Modify」から以下を有効化:

- **Deployment Platforms → Apple → iOS**

インストール後は `$WWISE_SDK/iOS_Xcode<version>` ディレクトリが存在する状態になります（例: `iOS_Xcode1500`, `iOS_Xcode1600`）。

## ビルド

リポジトリルートから:

```bash
./tools/scripts/build-ios.sh
```

スクリプトは `template_debug` / `template_release` の 2 種をまとめてビルドします。

### 手動で SCons を直接呼ぶ場合

CI 等価コマンド（`addons/Wwise/native/` 内で実行）:

```bash
SDK=/Applications/AudioKinetic/Wwise2025.1.3.9039/SDK

scons platform=ios target=template_debug   wwise_config=profile use_static_cpp=yes wwise_sdk=$SDK build_profile=build_profile_runtime.json precision=single
scons platform=ios target=template_release wwise_config=release use_static_cpp=yes wwise_sdk=$SDK build_profile=build_profile_runtime.json precision=single
```

## 出力先

```text
addons/Wwise/native/lib/ios/arm64/
├── template_debug/profile/libwwise.ios.template_debug.profile.framework
└── template_release/release/libwwise.ios.template_release.release.framework
```

各 framework と同じ階層の `DSP/` 配下に Wwise SDK 由来の DSP プラグインが iOS の慣例どおり静的ライブラリ (`.a`) としてコピーされます（`libAkReflectFX.a` 等）。
