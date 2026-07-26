#!/usr/bin/env bash
# Build OCISmoke.wasm and stage it next to the HTML/JS loader.
#
# Pins the compiler and WASM SDK to the same Swift 6.4 development snapshot.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SMOKE_DIR="$SCRIPT_DIR/../../Examples/SmokeTest"
TOOLCHAIN="${OCI_SMOKE_TOOLCHAIN:-org.swift.64202607171a}"
SDK="${OCI_SMOKE_SDK:-swift-6.4.x-DEVELOPMENT-SNAPSHOT-2026-07-17-a_wasm}"

echo "→ Building OCISmoke against TOOLCHAIN=$TOOLCHAIN SDK=$SDK"
cd "$SMOKE_DIR"
TOOLCHAINS="$TOOLCHAIN" xcrun swift package resolve
TOOLCHAINS="$TOOLCHAIN" xcrun swift build \
    --product OCISmoke \
    --swift-sdk "$SDK" \
    -c release

BIN_PATH="$(
    TOOLCHAINS="$TOOLCHAIN" xcrun swift build \
        --product OCISmoke \
        --swift-sdk "$SDK" \
        -c release \
        --show-bin-path
)"
BUILT_WASM="$BIN_PATH/OCISmoke.wasm"
JAVASCRIPTKIT_RUNTIME="$SMOKE_DIR/.build/checkouts/JavaScriptKit/Plugins/PackageToJS/Templates/runtime.mjs"
if [[ ! -f "$BUILT_WASM" ]]; then
    echo "✗ Build succeeded but $BUILT_WASM is missing" >&2
    exit 1
fi
if [[ ! -f "$JAVASCRIPTKIT_RUNTIME" ]]; then
    echo "✗ JavaScriptKit runtime was not found at $JAVASCRIPTKIT_RUNTIME" >&2
    exit 1
fi

cp "$BUILT_WASM" "$SMOKE_DIR/web/OCISmoke.wasm"
cp "$JAVASCRIPTKIT_RUNTIME" "$SMOKE_DIR/web/runtime.mjs"
echo "✓ Staged $(du -h "$SMOKE_DIR/web/OCISmoke.wasm" | awk '{print $1}') at Examples/SmokeTest/web/OCISmoke.wasm"
