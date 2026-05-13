#!/usr/bin/env bash
# Build Android (arm64-v8a + armeabi-v7a, debug + release) via Gradle.
# Depends on godot-cpp static archives produced by build-godot-cpp-android.sh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/env.sh"

# Hard requirements that Gradle would otherwise fail on with cryptic errors:
# Gradle 7.5 (bundled wrapper) refuses to start on Java 25 and needs 17, and
# the NDK path is consulted by CMake before any actionable diagnostic prints.
if [[ ! -x "$JAVA_HOME/bin/java" ]]; then
    echo "error: JAVA_HOME=$JAVA_HOME does not point to a usable JDK (need 17)" >&2
    exit 1
fi
if [[ ! -d "$ANDROID_NDK_HOME" ]]; then
    echo "error: ANDROID_NDK_HOME=$ANDROID_NDK_HOME does not exist" >&2
    exit 1
fi

# Ensure godot-cpp prebuilds exist; otherwise Gradle/CMake fails with a
# misleading "no known rule to make" ninja error.
GODOT_CPP_BIN="$PROJECT_ROOT/addons/Wwise/native/godot-cpp/bin"
needs_prebuild=0
for target in template_debug.dev template_release; do
    for arch in arm32 arm64; do
        if [[ ! -f "$GODOT_CPP_BIN/libgodot-cpp.android.$target.$arch.a" ]]; then
            needs_prebuild=1
            break 2
        fi
    done
done

if (( needs_prebuild )); then
    echo ":: godot-cpp Android archives missing — running prebuild ::"
    "$SCRIPT_DIR/build-godot-cpp-android.sh"
fi

cd "$PROJECT_ROOT/addons/Wwise/native/android"
chmod +x gradlew

echo ":: gradle assemble (debug + release) ::"
./gradlew assemble \
    -PWWISE_SDK="$WWISE_SDK" \
    -Pprecision=single \
    --no-daemon

echo "Android build complete."
