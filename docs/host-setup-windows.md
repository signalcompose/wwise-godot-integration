# ホスト環境セットアップ: Windows

[ローカルビルド環境セットアップ](local-build-setup.md) の Windows ホスト版。Windows ターゲットのビルドはこのホスト環境が必要です。

共通の[バージョン要件](local-build-setup.md#バージョン要件)・[個人環境ファイル](local-build-setup.md#gitignore-に含まれるもの)・[汎用トラブルシュート](local-build-setup.md#トラブルシュート)はインデックス側を参照してください。

シェルは **PowerShell 7+** (`pwsh`) を前提とします。

## 1. mise と Python のインストール

Windows ネイティブでは `pyenv` / `anyenv` 系より [mise](https://mise.jdx.dev/) のほうが扱いやすいです。

```powershell
winget install --id jdx.mise --silent --accept-source-agreements --accept-package-agreements
```

インストール後、新しい PowerShell を開いて mise を有効化します。`$PROFILE` に以下を追記:

```powershell
mise activate pwsh | Out-String | Invoke-Expression
```

リポジトリルートに `.tool-versions` を置くと、`mise install` で必要なツールが一括導入されます（`.python-version` のみ committed なので、mise を使う場合のみ作成）:

```text
python 3.12.13     # ビルドに必須 (SCons のランタイム)
node 22.22.2       # 任意: Claude Code の Context7 MCP プラグイン等で npx を使う場合のみ。ビルドには不要
```

```powershell
mise install
```

mise の shim を `node` / `python` などのコマンドとして PATH に通すには、ユーザー環境変数 PATH の先頭に `~\AppData\Local\mise\shims` を追加します（VSCode などの非対話シェルから MCP サーバ等を起動する場合は必須）。

## 2. uv のインストール

mise 経由（推奨）:

```powershell
mise use -g uv@latest
```

または winget:

```powershell
winget install --id astral-sh.uv
```

## 3. 仮想環境と SCons

```powershell
uv venv .venv --python 3.12.13
uv pip install --python .\.venv\Scripts\python.exe scons==4.7.0
```

動作確認:

```powershell
.\.venv\Scripts\scons.exe --version
# SCons: v4.7.0... が表示されれば OK
```

## 4. アクティベート

```powershell
.\.venv\Scripts\Activate.ps1
```

以後 `scons` コマンドが直接使えます。

## 5. Wwise SDK のインストール

Wwise Launcher から目的のバージョン (例: `2025.1.3.9039`) をインストールします。**SDK コンポーネントは標準では含まれない**ため、Launcher の「Modify」から以下を有効化:

- **Packages → SDK (C++)**

`%WWISESDK%` 環境変数は Launcher が自動設定します（例: `C:\Audiokinetic\Wwise_2025.1.3.9039\SDK`）。

Deployment Platforms は各ターゲット doc を参照してください（[Windows ターゲット](local-build-setup-windows.md)）。

## トラブルシュート

### 日本語ロケール環境での MSVC ビルドエラー

Visual Studio が日本語表示のままだと、SCons の最終リンク段で `UnicodeEncodeError: 'cp932' codec can't encode character '�'` で失敗することがあります。godot-cpp の `tools/windows.py:spawn_capture` が MSVC の日本語警告を UTF-8 として読み、その結果を cp932 でログに書こうとして衝突するためです。

ビルドコマンド冒頭に以下 2 行を追加してください:

```powershell
$env:VSLANG = '1033'             # MSVC を英語出力に
$env:PYTHONIOENCODING = 'utf-8'  # ログ書き出しの UnicodeEncodeError 回避
```

- `PYTHONIOENCODING=utf-8` がログ書き出しを UTF-8 に切り替え（**こちらが本命**）
- `VSLANG=1033` は MSVC に英語メッセージを要求（VS の言語パックが英語に対応していれば効きます）

これにより警告メッセージは表示されますが、ビルドはエラーになりません。
