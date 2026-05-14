#!/usr/bin/env bash
# Build macOS editor + template_debug + template_release.
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"

cd "$PROJECT_ROOT/addons/Wwise/native"

run_scons() {
    local target="$1" config="$2" profile="$3"
    echo ":: macOS $target ($config, $profile) ::"
    "$SCONS" \
        platform=macos \
        target="$target" \
        wwise_config="$config" \
        use_static_cpp=yes \
        wwise_sdk="$WWISE_SDK" \
        build_profile="$profile" \
        precision=single \
        -j"$JOBS"
}

run_scons editor           profile build_profile_editor.json
run_scons template_debug   profile build_profile_runtime.json
run_scons template_release release build_profile_runtime.json

echo "macOS build complete."
