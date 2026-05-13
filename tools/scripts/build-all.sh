#!/usr/bin/env bash
# Build every platform supported from this machine (macOS, iOS, Android, Web).
# Windows and Linux must be built on their respective hosts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/build-macos.sh"
"$SCRIPT_DIR/build-ios.sh"
"$SCRIPT_DIR/build-android.sh"
"$SCRIPT_DIR/build-web.sh"

echo "All local platforms built."
