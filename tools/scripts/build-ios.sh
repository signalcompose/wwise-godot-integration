#!/usr/bin/env bash
# Build iOS template_debug + template_release (arm64).
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"

cd "$PROJECT_ROOT/addons/Wwise/native"

run_scons() {
    local target="$1" config="$2"
    echo ":: iOS $target ($config) ::"
    "$SCONS" \
        platform=ios \
        target="$target" \
        wwise_config="$config" \
        use_static_cpp=yes \
        wwise_sdk="$WWISE_SDK" \
        build_profile=build_profile_runtime.json \
        precision=single \
        -j"$JOBS"
}

run_scons template_debug   profile
run_scons template_release release

echo "iOS build complete."
