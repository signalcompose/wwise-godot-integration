# ローカルビルド環境セットアップ

GDExtension (C++) を SCons でビルドするための環境構築・ターゲット別ビルド手順の索引。

ドキュメントは **ホスト OS 別の環境構築** と **ターゲット別のビルド手順** の 2 軸で分かれています。最初に対応するホスト doc を一度だけ済ませ、以後は作りたいターゲットの doc をその都度参照してください。

## ホスト環境セットアップ

ターゲットビルドを始める前に、ホスト OS に応じた基本環境（Python / uv / SCons / venv / Wwise SDK）を 1 度だけ整えます。

| ホスト | doc |
|---|---|
| macOS | [host-setup-macos.md](host-setup-macos.md) |
| Windows | [host-setup-windows.md](host-setup-windows.md) |
| Linux (WSL2 含む) | [host-setup-linux.md](host-setup-linux.md) |

## ターゲット別ビルド

各ターゲットに必要なホスト要件・追加 SDK・ビルドコマンドを示します。

| ターゲット | ホスト | doc |
|---|---|---|
| macOS | macOS | [local-build-setup-macos.md](local-build-setup-macos.md) |
| iOS | macOS | [local-build-setup-ios.md](local-build-setup-ios.md) |
| Windows | Windows | [local-build-setup-windows.md](local-build-setup-windows.md) |
| Linux | Linux / WSL2 | [local-build-setup-linux.md](local-build-setup-linux.md) |
| Android | macOS (or Linux / Windows、本リポでは macOS のみ検証) | [local-build-setup-android.md](local-build-setup-android.md) |
| Web (Emscripten) | macOS (or Linux / Windows、本リポでは macOS のみ検証) | [local-build-setup-web.md](local-build-setup-web.md) |

すべてのターゲットに `tools/scripts/build-*` のラッパーが用意されています。`WWISE_SDK` / `JAVA_HOME` / `ANDROID_NDK_HOME` 等の環境変数を集中管理しており、デフォルト値で問題なければ `./tools/scripts/build-<target>.sh`（Windows のみ `.\tools\scripts\build-windows.ps1`）の 1 行で済みます。各スクリプトは `uname -s` / `$IsWindows` でホストを検出し、想定外のホストでは即座に exit するため、誤実行による不整合バイナリは生成されません。

## バージョン要件

| ツール | バージョン | 備考 |
|---|---|---|
| Python | 3.12.13 | CI は `3.x` だが SCons 4.7.0 公式対応上限が 3.12 |
| SCons | 4.7.0 | `.github/workflows/build_all.yml` でピン留め |
| uv | 0.11+ | venv / パッケージ管理 |
| pyenv | 任意 | anyenv 経由でも可。Windows ユーザーは [mise](https://mise.jdx.dev/) を推奨 |

Android / Web ターゲット用の追加バージョン要件（Java 17, NDK 23.2.8568313, emsdk 4.0.23 等）は各ターゲット doc を参照してください。

## .gitignore に含まれるもの

このセットアップで生成される個人環境ファイル:

- `.venv/` — Python 仮想環境
- `.python-version` — pyenv のバージョン指定（個人運用なら無視、チーム共有なら gitignore から外す）
- `emsdk/` — Emscripten SDK
- `*.code-workspace` — VSCode ワークスペース設定

## トラブルシュート

OS 固有のトラブル（Windows の日本語ロケール、Linux の `libtbb` リンクエラー等）は各ホスト doc / ターゲット doc を参照してください。以下は全 OS 共通の項目です。

### `scons not found`

`.venv` を activate していないか、bin パスを直接呼んでください（macOS / Linux なら `.venv/bin/scons`、Windows なら `.\.venv\Scripts\scons.exe`）。`tools/scripts/build-*.sh` は `.venv/bin/scons` を直接呼ぶため activate 不要です。

### `import SCons` エラー

`uv pip install scons==4.7.0` が `.venv` に対して実行されているか確認:

```bash
.venv/bin/python -m pip list          # macOS / Linux
.\.venv\Scripts\python.exe -m pip list  # Windows
```

### Python バージョンが違う

`.venv` の Python が 3.12.13 になっているか確認し、ズレていれば `.venv` を削除して `uv venv .venv --python 3.12.13` を再実行してください。

### CI との挙動差

CI は `python-version: 3.x` を `actions/setup-python@v5` で resolve するため、将来 3.13 / 3.14 になる可能性があります。ローカルが 3.12.13 で動けば SCons 4.7.0 の公式サポート範囲内のため、ローカルでの再現は基本的に信頼できます。
