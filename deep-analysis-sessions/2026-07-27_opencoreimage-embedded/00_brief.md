# Analysis Brief

- session_id: `2026-07-27_opencoreimage-embedded`
- created: `2026-07-27T13:40:00+09:00`
- task_type: Root-cause diagnosis and implementation
- domain: Swift 6.4, WebAssembly, Embedded Swift, Core Image compatibility
- expected_output: OpenCoreImage source and tests that compile and link for Native, WASM, and Embedded WASM, plus evidence-backed verification
- constraints:
  - Keep the Swift 6.4 development snapshot baseline.
  - Limit product changes to OpenCoreImage and changes strictly required in its declared dependencies.
  - Preserve one synchronization and ownership contract across targets.
  - Use typed failures for unavailable rendering capabilities; do not silently return successful placeholders.
  - Do not use `try?`, `@unchecked Sendable`, `nonisolated(unsafe)`, or no-op synchronization to suppress errors.

## User Request

CIContext appears to have problems. Complete OpenCoreImage so it builds for WASM and Embedded.

## Open Questions

- Which declarations fail first under the fixed Embedded WASM SDK?
- Does Embedded require a functioning pixel renderer for this task, or an explicitly unavailable renderer with a typed failure while preserving API/build compatibility?
- Which Foundation-dependent APIs must be conditionally unavailable or replaced by portable contracts?
- Do OpenCoreGraphics or swift-webgpu currently prevent Embedded linking before OpenCoreImage is reached?
