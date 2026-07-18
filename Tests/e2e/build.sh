#!/usr/bin/env bash
# Build OCISmoke.wasm and stage it next to the HTML/JS loader.
#
# Uses Swift 6.3.1 because 6.2.3 deadlocks inside any @MainActor hop on WASM
# (see root workspace memory: feedback_wasm_swift_version_mainactor).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SMOKE_DIR="$SCRIPT_DIR/../../Examples/SmokeTest"
SDK="${OCI_SMOKE_SDK:-swift-6.3.1-RELEASE_wasm}"
if [[ -n "${OCI_SWIFT_BIN:-}" ]]; then
    SWIFT_COMMAND=("$OCI_SWIFT_BIN")
elif command -v swiftly >/dev/null 2>&1; then
    SWIFT_COMMAND=(swiftly run swift)
else
    SWIFT_COMMAND=(swift)
fi

echo "→ Building OCISmoke against SDK=$SDK"
cd "$SMOKE_DIR"
"${SWIFT_COMMAND[@]}" package resolve
"${SWIFT_COMMAND[@]}" build --product OCISmoke --swift-sdk "$SDK" -c release

BUILT_WASM="$SMOKE_DIR/.build/wasm32-unknown-wasip1/release/OCISmoke.wasm"
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
