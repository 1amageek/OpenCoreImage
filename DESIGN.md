# OpenCoreImage Design

## Render Result Ownership

`CIContextRenderer` crosses an asynchronous rendering boundary. Its
`CIRenderResult` owns a tightly packed RGBA8 `Data` value, dimensions, and an
immutable `CGColorSpace`. It does not retain or send a `CGImage`.

The result initializer validates positive dimensions, multiplication overflow,
and the exact byte count before publishing the value. `CIContext` materializes
the `CGImage` after awaiting the renderer. The resulting `CGDataProvider`
retains the owned `Data`, so the image does not borrow storage from a render
task.

```text
CIImage graph
    -> renderer
        -> owned RGBA8 bytes + dimensions + color space
            -> async boundary
                -> CIContext materializes CGImage
```

This differs from retaining a mutable Core Graphics object graph inside a
`Sendable` result. Renderer output is a checked value contract; non-`Sendable`
Core Graphics objects remain in the caller's isolation domain.

### Output Format Contract

The asynchronous renderer currently produces tightly packed RGBA8 output.
`CIContext.createCGImageAsync` rejects every other `CIFormat` with
`CIError.unsupportedFormat`; it does not relabel RGBA8 bytes as the requested
layout. A format becomes supported only when both the renderer and
`CIRenderResult` implement its byte layout and behavior tests verify the
resulting channel order and component width.

```text
Requested CIFormat
    -> RGBA8
        -> renderer-owned RGBA8 bytes
    -> any other format
        -> CIError.unsupportedFormat
```

## Platform Matrix

| Target | Renderer | Result crossing | Image materialization |
|---|---|---|---|
| Native compatibility tests | `CIStubContextRenderer` | Owned `CIRenderResult` | `CIContext` after `await` |
| WASM production | `CIWebGPUContextRenderer` | Owned GPU-readback `Data` | `CIContext` after `await` |
| Embedded | Not advertised | Not compiled | Not available |

## Executor and Shared-State Contracts

`CIImage`, `CIFilter`, and the Core Graphics image graph are not `Sendable`.
The asynchronous rendering API is `nonisolated(nonsending)`, so the graph
remains on the caller's executor while renderer-owned values cross suspension
points. The WebGPU renderer does not cache mutable device, queue, task, or
option state. It acquires the current device and queue from
`GPUContextManager` for each render.

```text
caller executor
    -> non-Sendable CIImage/filter graph
        -> compile and submit
            -> actor-owned GPU resource pools
                -> Sendable CIRenderResult
                    -> caller executor materialization
```

| Logical state | Native storage/isolation | WASM storage/isolation | Read/mutation entry point | Release |
|---|---|---|---|---|
| Filter registration table | `Mutex<[String: FilterRegistration]>` | Same | `registration(named:)` / `registerName` | Process lifetime |
| `CIColor` components | `Mutex<UnsafeMutablePointer<CGFloat>>` | Same | `component(at:)` / initialization only | Exactly once in `deinit` |
| GPU texture pool | Not compiled | `actor GPUTexturePool` | `acquire` / `release` / `clear` | `destroy()` on eviction or clear |
| Filter graph compiler | Immutable `Sendable` object | Same | Caller-executor `nonsending` methods | ARC |

OpenCoreImage is not advertised for Embedded Swift, so no Embedded storage
branch exists. A future Embedded target must use the same synchronization and
ownership contracts rather than raw mutable target-specific state.

## Filter Registration

The global custom-filter registry is protected by `Mutex`. Registration takes
an immutable recursive snapshot of class attributes and preserves the concrete
numeric value type. Constructor callbacks execute after leaving the critical
section, preventing callback re-entry from deadlocking the registry.

The portable registration overload requires the constructor to conform to
`Sendable`. Attribute values are limited to strings, booleans, Swift numeric
types, `CGFloat`, `Data`, arrays of supported values, and string-keyed
dictionaries of supported values. The Apple-compatible operation cannot report
an error, so unsupported values fail immediately instead of being silently
dropped or stored across concurrency domains.

## `CIColor` Component Ownership

`CIColor` owns one naturally aligned `CGFloat` allocation. The allocation is
fully initialized before publication and deallocated exactly once. Every
internal pointer read uses the same `Mutex` on Native and WASM. The public
`components` pointer is an immutable borrow and remains valid only while the
`CIColor` owner is retained; callers must not mutate or retain the pointer past
the owner's lifetime.

## WebGPU Texture Pool

Texture compatibility includes device identity, dimensions, format, and usage
flags. Releasing a texture with a different device or usage cannot make it
eligible for an incompatible acquisition. The pool is bounded to four textures
per compatibility key and twenty textures globally; overflow textures are
destroyed immediately.

The pool uses bounded array storage. The fixed capacity makes lookup cost
constant-bounded and avoids the composite-key dictionary release-WASM failure
observed with the fixed Swift 6.4 baseline. Browser release tests exercise
allocation, filter execution, readback, release, and subsequent reuse.

## Known Incomplete API Areas

The verified rendering paths do not establish complete Core Image parity.
Custom Metal/Core Image kernels, image processor execution, plug-in/image-unit
loading, several representation APIs, and many filter semantics remain
incomplete. Callable incomplete branches must use typed failure or `nil`
according to their API contract and carry
`FIXME(INCOMPLETE_IMPLEMENTATION)` until their success and failure behavior is
implemented and tested.
