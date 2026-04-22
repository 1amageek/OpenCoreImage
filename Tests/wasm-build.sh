#!/usr/bin/env bash
#
# WASM-build smoke test for OpenCoreImage.
#
# OpenCoreImage's WebGPU-backed filters have no headless-browser harness yet
# (most CI* filters are API-only stubs). The compile step itself is the most
# useful signal we can extract without a live GPU: it confirms that the
# OpenCoreGraphics / swift-webgpu / JavaScriptKit transitive graph still
# resolves and that all 180+ CIFilter declarations type-check for wasm32.
#
# Run with: bash OpenCoreImage/tests/wasm-build.sh
# Exits 0 on success, nonzero on any compile failure.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_ROOT="$(cd "$HERE/.." && pwd)"

SDK="${WASM_SDK:-swift-6.3.1-RELEASE_wasm}"

echo "==> WASM-build smoke: OpenCoreImage"
echo "    package: $PACKAGE_ROOT"
echo "    sdk:     $SDK"
cd "$PACKAGE_ROOT"

if ! swift sdk list 2>/dev/null | grep -q "^${SDK}$"; then
    echo "!! Swift WASM SDK '${SDK}' is not installed." >&2
    echo "   Install it with:" >&2
    echo "   swift sdk install https://download.swift.org/swift-6.3.1-release/wasm-sdk/swift-6.3.1-RELEASE/swift-6.3.1-RELEASE_wasm.artifactbundle.tar.gz" >&2
    exit 2
fi

swift build --swift-sdk "$SDK"
echo "==> OK: OpenCoreImage compiles for wasm32-unknown-wasip1"
