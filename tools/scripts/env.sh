#!/usr/bin/env bash
# Common environment for GDExtension build scripts.
# Source this from each build-*.sh: `source "$(dirname "${BASH_SOURCE[0]}")/env.sh"`
#
# All variables use ":=" so a value set in the calling shell wins over the
# default. Note: ":=" also substitutes when a variable is set to an empty
# string, not only when unset — exporting VAR="" upstream still triggers the
# default. Override on the command line as needed:
#   WWISE_SDK=/other/path ./tools/scripts/build-macos.sh

# Project root (resolved from this file's location)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${PROJECT_ROOT:=$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Wwise SDK — default depends on host OS:
#   macOS: Wwise Launcher's standard /Applications path
#   Linux: WSL2 mount of a Windows-side Wwise SDK install (typical setup)
#          Native-Linux installs vary; override WWISE_SDK explicitly there.
case "$(uname -s)" in
    Darwin)
        : "${WWISE_SDK:=/Applications/AudioKinetic/Wwise2025.1.3.9039/SDK}"
        ;;
    Linux)
        : "${WWISE_SDK:=/mnt/c/Audiokinetic/Wwise_2025.1.3.9039/SDK}"
        ;;
    *)
        : "${WWISE_SDK:=}"
        ;;
esac

# Python venv SCons
: "${SCONS:=$PROJECT_ROOT/.venv/bin/scons}"

# Build parallelism
if [[ -z "${JOBS:-}" ]]; then
    # nproc first (Linux): sysctl exists on Linux too but lacks hw.ncpu, so
    # probing sysctl first would fail under `set -e` in callers.
    if command -v nproc >/dev/null 2>&1; then
        JOBS=$(nproc)
    elif command -v sysctl >/dev/null 2>&1; then
        JOBS=$(sysctl -n hw.ncpu)
    else
        JOBS=4
    fi
fi

# Android (only required for android builds)
: "${JAVA_HOME:=/Applications/Homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home}"
: "${ANDROID_HOME:=/Applications/Homebrew/share/android-commandlinetools}"
: "${ANDROID_SDK_ROOT:=$ANDROID_HOME}"
: "${ANDROID_NDK_HOME:=$ANDROID_HOME/ndk/23.2.8568313}"

# Web (only required for web builds; sourced lazily by build-web.sh)
: "${EMSDK_DIR:=$PROJECT_ROOT/emsdk}"

export PROJECT_ROOT WWISE_SDK SCONS JOBS \
       JAVA_HOME ANDROID_HOME ANDROID_SDK_ROOT ANDROID_NDK_HOME \
       EMSDK_DIR

# Prepend Java to PATH only if JAVA_HOME points somewhere usable.
if [[ -x "$JAVA_HOME/bin/java" ]]; then
    export PATH="$JAVA_HOME/bin:$PATH"
fi

# Sanity check that doesn't abort sourcing (callers decide what's required).
if [[ ! -x "$SCONS" ]]; then
    echo "warning: SCons not found at $SCONS — run docs/local-build-setup.md steps first" >&2
fi
