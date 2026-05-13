# ローカルビルド環境セットアップ: macOS

[ローカルビルド環境セットアップ](local-build-setup.md) の macOS 版。共通の[バージョン要件](local-build-setup.md#バージョン要件)・[個人環境ファイル](local-build-setup.md#gitignore-に含まれるもの)・[汎用トラブルシュート](local-build-setup.md#トラブルシュート)はインデックス側を参照してください。

## セットアップ手順

### 1. Python のインストール

anyenv + pyenv を使う場合:

```bash
anyenv install pyenv          # 未インストールの場合のみ
pyenv install 3.12.13
```

リポジトリルートで:

```bash
pyenv local 3.12.13           # .python-version を作成
```

### 2. uv のインストール

```bash
brew install uv               # 未インストールの場合のみ
```

### 3. 仮想環境と SCons

リポジトリルートで:

```bash
uv venv .venv --python 3.12.13
uv pip install --python .venv/bin/python scons==4.7.0
```

動作確認:

```bash
.venv/bin/scons --version
# SCons: v4.7.0... が表示されれば OK
```

### 4. アクティベート

セッションごとに 1 回:

```bash
source .venv/bin/activate
```

以後 `scons` コマンドが直接使えます。

## ビルドコマンド

`addons/Wwise/native/` 内で実行（[CLAUDE.md](../CLAUDE.md) 参照）:

```bash
cd addons/Wwise/native

# macOS エディタビルド
scons platform=macos target=editor wwise_sdk=/Applications/AudioKinetic/Wwise2025.1.3.9039/SDK

# macOS ランタイムビルド
scons platform=macos target=template_debug wwise_sdk=/path/to/SDK wwise_config=debug
scons platform=macos target=template_release wwise_sdk=/path/to/SDK wwise_config=release
```

### Web (Emscripten) ビルド

事前準備 ([CLAUDE.md](../CLAUDE.md) 参照):

```bash
source emsdk/emsdk_env.sh     # リポジトリルートの emsdk/ を読み込む
```

ビルド:

```bash
cd addons/Wwise/native

scons platform=web target=template_debug threads=yes \
  wwise_sdk=/Applications/AudioKinetic/Wwise2025.1.3.9039/SDK \
  wwise_config=debug
```

詳細は [web-export-implementation-plan.md](web-export-implementation-plan.md) を参照。
