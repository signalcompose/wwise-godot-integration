# ローカルビルド環境セットアップ

GDExtension (C++) を SCons でビルドするためのローカル環境構築手順。OS 別の詳細手順は以下を参照してください:

- [macOS](local-build-setup-macos.md)
- [Windows](local-build-setup-windows.md)
- [Linux](local-build-setup-linux.md)（WSL2 含む）

## バージョン要件

| ツール | バージョン | 備考 |
|---|---|---|
| Python | 3.12.13 | CI は `3.x` だが SCons 4.7.0 公式対応上限が 3.12 |
| SCons | 4.7.0 | `.github/workflows/build_all.yml` でピン留め |
| uv | 0.11+ | venv / パッケージ管理 |
| pyenv | 任意 | anyenv 経由でも可。Windows ユーザーは [mise](https://mise.jdx.dev/) を推奨 |

## .gitignore に含まれるもの

このセットアップで生成される個人環境ファイル:

- `.venv/` — Python 仮想環境
- `.python-version` — pyenv のバージョン指定（個人運用なら無視、チーム共有なら gitignore から外す）
- `emsdk/` — Emscripten SDK
- `*.code-workspace` — VSCode ワークスペース設定

## トラブルシュート

OS 別の固有エラー（Windows の日本語ロケール、Linux の `libtbb` リンクエラー等）は各 OS のドキュメントを参照してください。以下は全 OS 共通の項目です。

### `scons not found`

`.venv` を activate していないか、bin パスを直接呼んでください（macOS / Linux なら `.venv/bin/scons`、Windows なら `.\.venv\Scripts\scons.exe`）。

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
