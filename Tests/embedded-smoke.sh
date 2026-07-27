#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TOOLCHAIN="${OCI_EMBEDDED_TOOLCHAIN:-org.swift.64202607171a}"
SDK="${OCI_EMBEDDED_SDK:-swift-6.4.x-DEVELOPMENT-SNAPSHOT-2026-07-17-a_wasm-embedded}"

cd "$PACKAGE_DIR"
TOOLCHAINS="$TOOLCHAIN" xcrun swift build \
    --swift-sdk "$SDK" \
    --product OpenCoreImageEmbeddedSmoke

BIN_PATH="$(
    TOOLCHAINS="$TOOLCHAIN" xcrun swift build \
        --swift-sdk "$SDK" \
        --product OpenCoreImageEmbeddedSmoke \
        --show-bin-path
)"
RUNTIME_PATH="$PACKAGE_DIR/.build/checkouts/JavaScriptKit/Plugins/PackageToJS/Templates/runtime.mjs"

node "$SCRIPT_DIR/embedded-smoke.mjs" \
    "$RUNTIME_PATH" \
    "$BIN_PATH/OpenCoreImageEmbeddedSmoke.wasm"
