# Analysis Strategy

## Task Structure

Use a target-matrix decomposition across Native compatibility, WASM production, and Embedded WASM. Within each target, trace `CIContext` from public initialization through renderer selection, asynchronous result ownership, `CGImage` materialization, cache release, and typed failures.

## Key Layers and Categories

- Context
  - Toolchain and SDK baseline
  - Package dependency capability
- Situation
  - Current build behavior
  - Existing working-tree changes
- Problem
  - Compile and link failures
  - Ownership and Sendable contract mismatches
- Issue
  - Platform selection and unavailable capability modeling
  - Foundation and Objective-C runtime dependencies
- Solution
  - Portable renderer contract
  - Target-specific backend selection at the composition boundary
  - Behavioral and compile-link tests
- Outcome
  - Native focused tests
  - WASM build and browser evidence
  - Embedded WASM compile-link evidence

## Decomposition Strategy

1. Structural decomposition: public API, renderer protocol, concrete backend, result owner, CoreGraphics boundary.
2. Target comparison: Native vs WASM vs Embedded expanded declarations and imports.
3. Causal diagnosis: identify the first failing declaration, then follow callers and dependencies rather than patching later diagnostics.
4. Contract verification: success, failure, ownership, synchronization, and shutdown/release paths.

## Evidence-Report Design

The primary visual is a verification matrix showing, for each target, renderer type, storage/isolation, initialization result, async render result, compile, link, and runtime-test status. A flow diagram will show the corrected selection boundary and typed failure behavior.

## Chartable Data Requirements

- Target name
- Build stage reached
- Exit status
- First failing source location or success artifact
- Test counts and failures
- Renderer capability and failure contract

## Initial Hypotheses

- H1: `CIContext` unconditionally stores Foundation/CoreGraphics reference types that are unavailable or non-Sendable in Embedded.
- H2: `#if arch(wasm32)` incorrectly selects the WebGPU renderer for Embedded WASM even when JavaScriptKit/WebGPU is unavailable.
- H3: the package manifest exposes WebGPU dependencies to Embedded when they should be behind an explicit capability boundary.
- H4: an Embedded backend can preserve API and ownership contracts while returning typed unsupported-renderer failures until a board-specific renderer exists.

## Revision History

- 2026-07-27: Initial target-matrix and causal diagnosis strategy.
