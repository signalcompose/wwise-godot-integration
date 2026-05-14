#!/usr/bin/env bash
# Pre-build godot-cpp static archives needed by the Android Gradle build.
# Produces: libgodot-cpp.android.{template_debug.dev,template_release}.{arm32,arm64}.a
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"

cd "$PROJECT_ROOT/addons/Wwise/native/godot-cpp"

run_scons() {
    local target="$1" arch="$2"
    local extra=()
    [[ "$target" == "template_debug" ]] && extra+=("dev_build=yes")
    echo ":: godot-cpp android $target $arch ${extra[*]:-} ::"
    "$SCONS" \
        platform=android \
        target="$target" \
        arch="$arch" \
        precision=single \
        "${extra[@]}" \
        -j"$JOBS"
}

for arch in arm32 arm64; do
    for target in template_debug template_release; do
        run_scons "$target" "$arch"
    done
done

echo "godot-cpp Android prebuild complete."
