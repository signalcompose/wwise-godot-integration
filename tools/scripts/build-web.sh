#!/usr/bin/env bash
# Build Web (Emscripten) template_debug (debug + profile) + template_release.
# Requires emsdk to be available at $EMSDK_DIR (default: ./emsdk).
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"

if [[ ! -f "$EMSDK_DIR/emsdk_env.sh" ]]; then
    echo "error: emsdk not found at $EMSDK_DIR — see CLAUDE.md for setup" >&2
    exit 1
fi

# emsdk_env.sh prints PATH/SDK banner on stdout; keep stderr so activation
# failures surface instead of being masked.
source "$EMSDK_DIR/emsdk_env.sh" >/dev/null

cd "$PROJECT_ROOT/addons/Wwise/native"

# Web build intentionally diverges from macOS/iOS/Android:
# - no use_static_cpp:  Emscripten has no system C++ runtime to link against
# - no build_profile:   class-filtering is handled by Godot's web build
# - no precision flag:  matches docs/web-export-guide.md and the existing
#                       working Web binaries already shipped under lib/web/
run_scons() {
    local target="$1" config="$2"
    echo ":: web $target ($config) ::"
    "$SCONS" \
        platform=web \
        target="$target" \
        threads=yes \
        wwise_config="$config" \
        wwise_sdk="$WWISE_SDK" \
        -j"$JOBS"
}

run_scons template_debug   debug
run_scons template_debug   profile
run_scons template_release release

echo "Web build complete."
