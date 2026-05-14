#!/usr/bin/env bash
# Build Linux editor + template_debug + template_release (x64).
# Intended to run on a Linux host (or WSL2 Ubuntu 22.04).
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"

# Sanity: refuse to run from non-Linux to avoid silently producing wrong-target binaries.
if [[ "$(uname -s)" != "Linux" ]]; then
    echo "error: build-linux.sh must run on a Linux host (uname -s = $(uname -s))" >&2
    echo "       Linux target binaries cannot be cross-compiled from macOS/Windows here." >&2
    exit 1
fi

cd "$PROJECT_ROOT/addons/Wwise/native"

run_scons() {
    local target="$1" config="$2" profile="$3"
    echo ":: linux $target ($config, $profile) ::"
    "$SCONS" \
        platform=linux \
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

echo "Linux build complete."
