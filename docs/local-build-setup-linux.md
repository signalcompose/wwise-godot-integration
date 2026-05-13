# ローカルビルド環境セットアップ: Linux

[ローカルビルド環境セットアップ](local-build-setup.md) の Linux 版（WSL2 含む）。共通の[バージョン要件](local-build-setup.md#バージョン要件)・[個人環境ファイル](local-build-setup.md#gitignore-に含まれるもの)・[汎用トラブルシュート](local-build-setup.md#トラブルシュート)はインデックス側を参照してください。

CI は **Ubuntu 22.04** で Linux ビルドを実行しているので、同等環境を再現するのが最も互換性が高い構成です。Windows ユーザーは **WSL2** に Ubuntu 22.04 を入れて Linux 用バイナリをビルドできます。

## Windows ユーザー向け: WSL2 のインストール

PowerShell を管理者として起動:

```powershell
wsl --install -d Ubuntu-22.04
```

初回起動で UNIX ユーザー名・パスワードを設定します。以後の Linux 側手順は WSL シェル内で実行してください。

> リポジトリは **WSL のネイティブファイルシステム配下**（例: `~/projects/wwise-godot-integration`）にクローンすることを推奨。`/mnt/c/...` 直マウントは 9P 経由なので I/O が遅く、SCons ビルドが数倍遅くなります。

Wwise SDK は Windows 側のインストールを `/mnt/c/Audiokinetic/Wwise_2025.1.3.9039/SDK` で参照できます（読み取りメインなので実用上問題なし）。WSL 内に別途インストールする必要はありません。

## 1. apt パッケージ

```bash
sudo apt update
sudo apt install -y git build-essential pkg-config libssl-dev libtbb-dev
```

- `build-essential`: gcc / g++ / make
- `libtbb-dev`: Intel Threading Building Blocks — **Wwise SDK の Linux 版がリンクする必須依存**。これが無いと `cannot find -ltbb` でリンク失敗
- `libssl-dev`: 一部の Python パッケージや uv のビルドに必要なケースあり

## 2. mise / Python / uv / venv / SCons

mise を使う場合（推奨）:

```bash
curl https://mise.run | sh
echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc
exec bash
mise install   # .python-version の 3.12.13 を解決
```

uv をインストールして venv を作成:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
uv venv .venv --python 3.12.13
uv pip install --python .venv/bin/python scons==4.7.0
source .venv/bin/activate
```

## Linux ビルドコマンド

`addons/Wwise/native/` 内で実行（CI と完全一致）:

```bash
SDK=/mnt/c/Audiokinetic/Wwise_2025.1.3.9039/SDK   # WSL の場合。native Linux ならインストール先パス

# Editor
scons platform=linux target=editor          wwise_config=profile use_static_cpp=yes wwise_sdk=$SDK build_profile=build_profile_editor.json  precision=single

# Runtime debug
scons platform=linux target=template_debug  wwise_config=profile use_static_cpp=yes wwise_sdk=$SDK build_profile=build_profile_runtime.json precision=single

# Runtime release
scons platform=linux target=template_release wwise_config=release use_static_cpp=yes wwise_sdk=$SDK build_profile=build_profile_runtime.json precision=single
```

出力先:

```text
addons/Wwise/native/lib/linux/
├── editor/profile/libwwise.linux.editor.profile.so
├── template_debug/profile/libwwise.linux.template_debug.profile.so
└── template_release/release/libwwise.linux.template_release.release.so
```

### よくあるエラー: `/usr/bin/ld: cannot find -ltbb`

`libtbb-dev` が未インストールです。上の apt 手順を実行してください。再ビルドは前段のオブジェクトファイルがキャッシュされているのでリンクのみで数秒で完了します。
