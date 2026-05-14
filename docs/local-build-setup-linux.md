# ターゲットビルド: Linux

GDExtension の **Linux ターゲット** (editor + template_debug + template_release, x64) をビルドする手順。

## ホスト要件

Linux ホスト（または WSL2 上の Ubuntu 22.04）が必要です。基本環境（apt パッケージ / mise / Python / uv / SCons / venv / Wwise SDK）は [ホスト環境セットアップ: Linux](host-setup-linux.md) を参照してください。`libtbb-dev` が Wwise Linux SDK 必須依存です。

CI は Ubuntu 22.04 で実行しているので、同等環境を用意するのが最も互換性が高い構成です。

## 追加 SDK 要件

Wwise Launcher の「Modify」から以下を有効化:

- **Deployment Platforms → Linux**

インストール後は `$WWISE_SDK/Linux_x64` ディレクトリが存在する状態になります。

## ビルド

リポジトリルートから:

```bash
./tools/scripts/build-linux.sh
```

スクリプトは `editor` / `template_debug` / `template_release` の 3 種をまとめてビルドします。`uname -s` が `Linux` でない場合は安全側に倒して即座に `exit 1` するため、macOS 上で誤って実行しても Linux 用のおかしなバイナリは生成されません。

`env.sh` の `WWISE_SDK` デフォルトは Linux ホストでは `/mnt/c/Audiokinetic/Wwise_2025.1.3.9039/SDK`（WSL2 の Windows マウント前提）を指します。Linux ネイティブでインストールしている場合や別パスを使いたい場合は環境変数で上書き:

```bash
WWISE_SDK=/opt/Audiokinetic/Wwise_2025.1.3.9039/SDK \
  ./tools/scripts/build-linux.sh
```

### 手動で SCons を直接呼ぶ場合

CI 等価コマンド（`addons/Wwise/native/` 内で実行）:

```bash
SDK=/mnt/c/Audiokinetic/Wwise_2025.1.3.9039/SDK   # WSL の場合。native Linux ならインストール先パス

scons platform=linux target=editor           wwise_config=profile use_static_cpp=yes wwise_sdk=$SDK build_profile=build_profile_editor.json  precision=single
scons platform=linux target=template_debug   wwise_config=profile use_static_cpp=yes wwise_sdk=$SDK build_profile=build_profile_runtime.json precision=single
scons platform=linux target=template_release wwise_config=release use_static_cpp=yes wwise_sdk=$SDK build_profile=build_profile_runtime.json precision=single
```

## 出力先

```text
addons/Wwise/native/lib/linux/
├── editor/profile/libwwise.linux.editor.profile.so
├── template_debug/profile/libwwise.linux.template_debug.profile.so
└── template_release/release/libwwise.linux.template_release.release.so
```

各 `.so` と同じ階層の `DSP/` 配下に Wwise SDK 由来の DSP プラグイン（`libAkReflect.so`, `libAkSoundSeedAir.so`, `libiZotope.so`, `libMcDSP.so`, `libAuro.so`, `libMasteringSuite.so` 等）がコピーされます。

## トラブルシュート

### `/usr/bin/ld: cannot find -ltbb`

`libtbb-dev` が未インストールです。[host-setup-linux.md](host-setup-linux.md#1-apt-パッケージ) の apt 手順を実行してください。再ビルドは前段のオブジェクトファイルがキャッシュされているのでリンクのみで数秒で完了します。
