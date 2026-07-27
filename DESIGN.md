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
| Embedded WASM | `CIWebGPUContextRenderer` | Owned GPU-readback `Data` | `CIContext` after `await` |

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

| Logical state | Native | WASM | Embedded WASM | Read/mutation entry point | Release |
|---|---|---|---|---|---|
| Filter registration table | `Mutex<[String: FilterRegistration]>` | Same | Same | `registration(named:)` / `registerName` | Process lifetime |
| `CIColor` components | `Mutex<UnsafeMutablePointer<CGFloat>>` | Same | Same | `component(at:)` / initialization only | Exactly once in `deinit` |
| GPU context | Not compiled | `actor GPUContextManager` | Same | `getDevice()` / actor initialization | Process lifetime |
| GPU texture pool | Not compiled | `actor GPUTexturePool` | Same | `acquire` / `release` / `clear` | `destroy()` on eviction or clear |
| GPU pipeline cache | Not compiled | `actor GPUPipelineCache` | Same | `pipeline` / `clear` | Process lifetime or clear |
| Filter graph compiler | Immutable `Sendable` object | Same | Same | Caller-executor `nonsending` methods | ARC |

Embedded WASM compiles the same WebGPU renderer and uses the same actor and
`Mutex` boundaries as ordinary WASM. The runtime smoke instantiates
`CIContext`, checks portable geometry and filter configuration, and verifies
successful and failing file-I/O behavior. It does not prove WebGPU execution in
Node; GPU semantic verification remains the Chromium browser readback suite.

`GPUError` retains `LocalizedError` conformance on Native and ordinary WASM.
Embedded Swift does not provide that Foundation protocol, so the same enum
provides `Error`, `CustomStringConvertible`, and the same `errorDescription`
property there.

Typed factory methods whose per-filter protocol conformance is not implemented
remain failable and return `nil`. Embedded Swift emits a diagnostic warning for
those protocol casts even though the package builds and links. This is an
explicitly marked incomplete API area and is separate from the verified
string-based filter graph and `CIContext` rendering path.

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
