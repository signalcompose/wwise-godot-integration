# ホスト環境セットアップ: macOS

[ローカルビルド環境セットアップ](local-build-setup.md) の macOS ホスト版。macOS / iOS / Android / Web ターゲットのビルドはすべてこのホスト環境を共有します（Windows / Linux ターゲットは別ホストが必要）。

共通の[バージョン要件](local-build-setup.md#バージョン要件)・[個人環境ファイル](local-build-setup.md#gitignore-に含まれるもの)・[汎用トラブルシュート](local-build-setup.md#トラブルシュート)はインデックス側を参照してください。

ターゲット別の追加要件は各ターゲット doc を参照:

- [macOS ターゲット](local-build-setup-macos.md)
- [iOS ターゲット](local-build-setup-ios.md)
- [Android ターゲット](local-build-setup-android.md)
- [Web ターゲット](local-build-setup-web.md)

## 1. Python のインストール

anyenv + pyenv を使う場合:

```bash
anyenv install pyenv          # 未インストールの場合のみ
pyenv install 3.12.13
```

リポジトリルートで:

```bash
pyenv local 3.12.13           # .python-version を作成
```

## 2. uv のインストール

```bash
brew install uv               # 未インストールの場合のみ
```

## 3. 仮想環境と SCons

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

`tools/scripts/build-*.sh` は `.venv/bin/scons` を直接呼ぶため、シェルの activate は不要です。

## 4. Wwise SDK のインストール

Wwise Launcher から目的のバージョン (例: `2025.1.3.9039`) をインストールします。**SDK コンポーネントは標準では含まれない**ため、Launcher の「Modify」から以下を有効化:

- **Packages → SDK (C++)**

デフォルトのインストール先は `/Applications/AudioKinetic/Wwise<version>/SDK` で、`tools/scripts/env.sh` の `WWISE_SDK` デフォルトもこの位置を指しています。

Deployment Platforms（macOS / iOS / Android / Web 等）は各ターゲット doc を参照してください。
