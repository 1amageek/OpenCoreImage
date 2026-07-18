import { test, expect, type Page } from "@playwright/test";

// OpenCoreImage E2E — Swift Testing ABI v0 drives the assertions.
//
// The WASM module's `setup()` evaluates a known RGBA source through a
// CIColorInvert WebGPU compute pipeline and stores the readback bytes.
// BrowserTestRunner (from swift-wasm-testing) then spawns
// the Swift Testing ABI v0 entry point; every `@Test` function inspects
// the captured state and streams records into `window.__wasm_tests`.
//
// This spec is a thin driver: wait for completion, dump records for
// diagnostics, fail iff any @Test recorded an issue (or the runner threw).

interface WasmTestsState {
    done: boolean;
    success: boolean;
    error: string | null;
    records: string[];
}

async function waitForWasmTests(page: Page): Promise<WasmTestsState> {
    await page.waitForFunction(
        () => {
            const t = (window as unknown as { __wasm_tests?: { done?: boolean } }).__wasm_tests;
            return !!t && t.done === true;
        },
        null,
        { timeout: 45_000 }
    );
    return await page.evaluate((): WasmTestsState => {
        const t = (window as unknown as { __wasm_tests: WasmTestsState }).__wasm_tests;
        return {
            done: t.done,
            success: t.success,
            error: t.error,
            records: t.records,
        };
    });
}

test("swift-testing: Core Image API and WebGPU filter readback pass", async ({ page }) => {
    page.on("console", (msg) => console.log(`[page:${msg.type()}]`, msg.text()));
    page.on("pageerror", (err) => console.error("[pageerror]", err.message));

    await page.goto("/");
    const state = await waitForWasmTests(page);

    console.log("----- swift-testing records -----");
    const failureMessages: string[] = [];
    for (const raw of state.records) {
        try {
            const rec = JSON.parse(raw);
            console.log(JSON.stringify(rec));
            if (rec.kind === "event" && rec.payload?.kind === "issueRecorded") {
                const msg = rec.payload?.issue?.sourceContext?.message
                    ?? rec.payload?.messages?.map((m: { text: string }) => m.text).join("; ")
                    ?? raw;
                failureMessages.push(typeof msg === "string" ? msg : JSON.stringify(msg));
            }
        } catch {
            console.log("[unparsable]", raw);
        }
    }
    console.log("---------------------------------");
    console.log(`runner: success=${state.success} error=${state.error ?? "null"} records=${state.records.length}`);

    expect(state.error, "runner must not throw").toBeNull();
    expect(
        state.success,
        `swift-testing reported failures. Issues:\n${failureMessages.join("\n")}`
    ).toBe(true);
});
