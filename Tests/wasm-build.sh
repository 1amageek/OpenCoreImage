#!/usr/bin/env bash
#
# WASM-build smoke test for OpenCoreImage.
#
# This compile check confirms that the OpenCoreGraphics / swift-webgpu /
# JavaScriptKit transitive graph resolves for wasm32. Browser pixel validation
# lives in Tests/e2e.
#
# Run with: bash OpenCoreImage/tests/wasm-build.sh
# Exits 0 on success, nonzero on any compile failure.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_ROOT="$(cd "$HERE/.." && pwd)"

TOOLCHAIN="${WASM_TOOLCHAIN:-org.swift.64202607171a}"
SDK="${WASM_SDK:-swift-6.4.x-DEVELOPMENT-SNAPSHOT-2026-07-17-a_wasm}"
SWIFT_COMMAND=(xcrun swift)

echo "==> WASM-build smoke: OpenCoreImage"
echo "    package: $PACKAGE_ROOT"
echo "    sdk:     $SDK"
cd "$PACKAGE_ROOT"

if ! TOOLCHAINS="$TOOLCHAIN" "${SWIFT_COMMAND[@]}" sdk list 2>/dev/null | grep -q "^${SDK}$"; then
    echo "!! Swift WASM SDK '${SDK}' is not installed." >&2
    exit 2
fi

TOOLCHAINS="$TOOLCHAIN" "${SWIFT_COMMAND[@]}" build --swift-sdk "$SDK"
echo "==> OK: OpenCoreImage compiles for wasm32-unknown-wasip1"
