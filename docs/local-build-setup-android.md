# ターゲットビルド: Android

GDExtension の **Android ターゲット** (arm64-v8a + armeabi-v7a, debug + release) をビルドする手順。Android では editor ビルドは存在しません。

## ホスト要件

macOS ホストを前提に書いています（`tools/scripts/build-android.sh` および `env.sh` のデフォルトパスは macOS / Homebrew 前提）。基本環境（Python / uv / SCons / venv / Wwise SDK）は [ホスト環境セットアップ: macOS](host-setup-macos.md) を参照してください。Linux / Windows から Android ビルドを行う場合は別途環境変数を上書きしてください。

Android ビルドはこれに加えて **Java 17** と **Android command line tools (NDK + cmake 含む)** が必要です。

## 追加 SDK 要件

### 1. Java 17

Gradle 7.5（リポジトリ同梱の gradle wrapper のバージョン）は Java 18 以降では起動に失敗します。Homebrew formula 版 OpenJDK 17 なら sudo 不要でインストールできます。

```bash
brew install openjdk@17
```

`env.sh` は次のパスを `JAVA_HOME` のデフォルトとして使います:

```text
/Applications/Homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
```

別の場所にインストールした場合は `JAVA_HOME=... ./tools/scripts/build-android.sh` で上書きしてください。

### 2. Android command line tools + NDK

```bash
brew install --cask android-commandlinetools
yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.2" \
           "ndk;23.2.8568313" "cmake;3.22.1"
```

各パッケージの選定根拠は `addons/Wwise/native/android/plugin/build.gradle.kts` のフィールドに対応:

- `compileSdk = 33` → `platforms;android-33`
- `buildToolsVersion = "33.0.2"` → `build-tools;33.0.2`
- `android.ndkVersion = "23.2.8568313"` → `ndk;23.2.8568313`
- `externalNativeBuild.cmake.version = "3.22.1"` → `cmake;3.22.1`

`env.sh` のデフォルト:

- `ANDROID_HOME=/Applications/Homebrew/share/android-commandlinetools`
- `ANDROID_SDK_ROOT=$ANDROID_HOME`
- `ANDROID_NDK_HOME=$ANDROID_HOME/ndk/23.2.8568313`

`build.gradle.kts` の `android.ndkVersion` を変更した場合は `ANDROID_NDK_HOME` も合わせてください。

### 3. Wwise SDK の Android パッケージ

Wwise Launcher の「Modify」から **Deployment Platforms → Google → Android** を有効化してください。インストール後は `$WWISE_SDK/Android_arm64-v8a` と `$WWISE_SDK/Android_armeabi-v7a` が存在する状態になります。

## ビルド

```bash
./tools/scripts/build-android.sh
```

スクリプトは次の処理をまとめて行います:

1. `JAVA_HOME` / `ANDROID_NDK_HOME` の存在チェック（Gradle が cryptic に死ぬ前に止める）
2. `addons/Wwise/native/godot-cpp/bin/libgodot-cpp.android.*.a` が揃っているか確認し、無ければ `build-godot-cpp-android.sh` を自動実行
3. `./gradlew assemble -PWWISE_SDK=... -Pprecision=single --no-daemon` で debug + release × arm64-v8a + armeabi-v7a を一括ビルド

### godot-cpp 静的ライブラリだけ作り直したいとき

```bash
./tools/scripts/build-godot-cpp-android.sh
```

`platform=android target={template_debug,template_release} arch={arm32,arm64}` の 4 組（template_debug は `dev_build=yes`）を順にビルドします。

### パスを変える場合

```bash
JAVA_HOME=/path/to/other/jdk17 \
ANDROID_NDK_HOME=/path/to/other/ndk \
WWISE_SDK=/path/to/other/wwise \
  ./tools/scripts/build-android.sh
```

## 出力先

```text
addons/Wwise/native/lib/android/
├── debug/
│   ├── arm64-v8a/libWwiseAndroidPlugin.so (+ DSP/*.so)
│   ├── armeabi-v7a/libWwiseAndroidPlugin.so (+ DSP/*.so)
│   └── WwiseAndroidPlugin-debug.aar
└── release/
    ├── arm64-v8a/libWwiseAndroidPlugin.so (+ DSP/*.so)
    ├── armeabi-v7a/libWwiseAndroidPlugin.so (+ DSP/*.so)
    └── WwiseAndroidPlugin-release.aar
```

## トラブルシュート

### `JAVA_HOME=... does not point to a usable JDK (need 17)`

`openjdk@17` が未インストールか、別の Java が `JAVA_HOME` に入っています。`brew install openjdk@17` を実行するか、`JAVA_HOME=/path/to/jdk17` で上書き。

### `ANDROID_NDK_HOME=... does not exist`

`sdkmanager "ndk;23.2.8568313"` が未実行か、`build.gradle.kts` で違うバージョンを指定しています。`ls $ANDROID_HOME/ndk/` で実在バージョンを確認し、必要なら `ANDROID_NDK_HOME` を上書き。

### ninja: error: `libgodot-cpp.android.*.a` missing

CMake が godot-cpp 静的アーカイブを見つけられません。通常は `build-android.sh` が前段を自動実行しますが、何らかの理由で skip された場合は `./tools/scripts/build-godot-cpp-android.sh` を手動実行してから再度 `build-android.sh` を呼んでください。

### `lib/android/` にコピーされない

`./gradlew assembleDebug` だけだと Gradle の `assemble` タスクが finalize する `copyAddonsToDemo` が走りません。`build-android.sh` は `assemble`（両 variant + finalizer）を呼んでいるので、スクリプト経由なら問題は発生しません。手動で Gradle を叩く場合は `./gradlew assemble` を使ってください。
