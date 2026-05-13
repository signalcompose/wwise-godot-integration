# ターゲットビルド: Windows

GDExtension の **Windows ターゲット** (editor + template_debug + template_release, x64) をビルドする手順。

## ホスト要件

Windows ホスト + Visual Studio 2022 (MSVC) が必要です。基本環境（mise / Python / uv / SCons / venv / Wwise SDK）は [ホスト環境セットアップ: Windows](host-setup-windows.md) を参照してください。

> macOS / Linux からのクロスコンパイルは現状サポートしていません。SConstruct は MSVC 専用フラグ（`/MTd`, `/MT`, `/std:c++20` 等）を使用しており、Wwise SDK の Windows 配布も MSVC ビルド済み `.lib` 形式のため、MinGW ABI と互換性がありません。

## 追加 SDK 要件

Wwise Launcher の「Modify」から以下を有効化:

- **Deployment Platforms → Microsoft → Windows** (Visual Studio 2022 用ライブラリ `x64_vc170` を取得)

## ビルド

PowerShell 7+ をリポジトリルートで起動して:

```powershell
.\tools\scripts\build-windows.ps1
```

スクリプトは `editor` / `template_debug` / `template_release` の 3 種をまとめてビルドします。`$IsWindows` が偽の場合は安全側に倒して即座に exit するため、macOS / Linux 上で誤って実行しても Windows 用のおかしなバイナリは生成されません。

`env.ps1` は以下のデフォルトを設定します（既存の環境変数があればそちらを優先）:

- `WWISE_SDK`: `%WWISESDK%`（Wwise Launcher が自動設定）→ `C:\Audiokinetic\Wwise_2025.1.3.9039\SDK`
- `SCONS`: `<repo>\.venv\Scripts\scons.exe`
- `PYTHONIOENCODING=utf-8` / `VSLANG=1033`（日本語ロケールでの `UnicodeEncodeError` 対策。詳細は [host-setup-windows.md トラブルシュート](host-setup-windows.md#トラブルシュート)）

パスを変えたい場合は環境変数で上書き:

```powershell
$env:WWISE_SDK = 'D:\WwiseSDK\2025.1.3'
.\tools\scripts\build-windows.ps1
```

### 手動で SCons を直接呼ぶ場合

CI 等価コマンド（`addons\Wwise\native\` 内で実行）:

```powershell
$env:VSLANG = '1033'
$env:PYTHONIOENCODING = 'utf-8'

$sdk = 'C:\Audiokinetic\Wwise_2025.1.3.9039\SDK'

scons platform=windows target=editor           wwise_config=profile use_static_cpp=yes wwise_sdk="$sdk" build_profile=build_profile_editor.json  precision=single
scons platform=windows target=template_debug   wwise_config=profile use_static_cpp=yes wwise_sdk="$sdk" build_profile=build_profile_runtime.json precision=single
scons platform=windows target=template_release wwise_config=release use_static_cpp=yes wwise_sdk="$sdk" build_profile=build_profile_runtime.json precision=single
```

## 出力先

```text
addons/Wwise/native/lib/win64/
├── editor/profile/libwwise.windows.editor.profile.dll
├── template_debug/profile/libwwise.windows.template_debug.profile.dll
└── template_release/release/libwwise.windows.template_release.release.dll
```

各 `.dll` と同じ階層の `DSP/` 配下に Wwise SDK 由来の DSP プラグイン（AkReflect.dll, AkSoundSeedAir.dll, iZotope.dll, McDSP.dll, Auro.dll, MasteringSuite.dll 等）がコピーされます。リンク用の `.lib` / `.exp` も生成されますが配布物には不要です。
