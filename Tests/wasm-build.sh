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

SDK="${WASM_SDK:-swift-6.3.1-RELEASE_wasm}"
SWIFT_COMMAND=(swift)
if command -v swiftly >/dev/null 2>&1; then
    SWIFT_COMMAND=(swiftly run swift)
fi

echo "==> WASM-build smoke: OpenCoreImage"
echo "    package: $PACKAGE_ROOT"
echo "    sdk:     $SDK"
cd "$PACKAGE_ROOT"

if ! "${SWIFT_COMMAND[@]}" sdk list 2>/dev/null | grep -q "^${SDK}$"; then
    echo "!! Swift WASM SDK '${SDK}' is not installed." >&2
    echo "   Install it with:" >&2
    echo "   swift sdk install https://download.swift.org/swift-6.3.1-release/wasm-sdk/swift-6.3.1-RELEASE/swift-6.3.1-RELEASE_wasm.artifactbundle.tar.gz" >&2
    exit 2
fi

"${SWIFT_COMMAND[@]}" build --swift-sdk "$SDK"
echo "==> OK: OpenCoreImage compiles for wasm32-unknown-wasip1"
