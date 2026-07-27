import { mkdtemp, readFile, rm, stat } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { pathToFileURL } from "node:url";
import { WASI } from "node:wasi";

const [runtimePath, wasmPath] = process.argv.slice(2);
if (!runtimePath || !wasmPath) {
    throw new Error("Usage: node embedded-smoke.mjs <runtime.mjs> <smoke.wasm>");
}

const smokeDirectory = await mkdtemp(join(tmpdir(), "opencoreimage-embedded-"));
try {
    const { SwiftRuntime } = await import(pathToFileURL(runtimePath));
    const runtime = new SwiftRuntime();
    const wasi = new WASI({
        version: "preview1",
        preopens: { "/smoke": smokeDirectory },
    });
    const wasm = await readFile(wasmPath);
    const { instance } = await WebAssembly.instantiate(wasm, {
        ...wasi.getImportObject(),
        javascript_kit: runtime.wasmImports,
    });

    runtime.setInstance(instance);
    wasi.initialize(instance);
    instance.exports.runOpenCoreImageEmbeddedSmoke();

    const roundTrip = await stat(join(smokeDirectory, "opencoreimage-roundtrip.bin"));
    if (roundTrip.size !== 5) {
        throw new Error(`Embedded Data round trip wrote ${roundTrip.size} bytes instead of 5`);
    }
} finally {
    await rm(smokeDirectory, { recursive: true, force: true });
}
