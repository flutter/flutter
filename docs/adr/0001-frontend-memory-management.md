# ADR 0001: Frontend-Centric Memory Management for Engine Primitives

## Context & Problem
The Flutter Web UI engine is split into a shared frontend layer (e.g., `EngineColorFilter`, `EngineMaskFilter`) and backend-specific delegates that wrap the actual native handles (e.g., `CkColorFilter` for CanvasKit, `SkwasmColorFilter` for Skwasm).

Because Web UI interacts heavily with native C++ objects (like Skia handles), we must ensure these native resources are properly deleted (via a `Finalizer` or explicit `dispose`) when their Dart wrappers are garbage collected to prevent memory leaks. 

The core question was: **Where should the `Finalizer` be attached?** Should it be attached to the backend delegates, or should it be attached to the shared frontend wrapper?

## Alternatives Considered
We initially considered attaching finalizers directly to the backend delegates (e.g. `CkColorFilter`).

This approach was **rejected** for the following reasons:
1. **Memory Leaks from Ephemeral Usage**: Dart objects like `ui.Paint` don't have a `dispose()` method. If a backend delegate is created ephemerally and cached locally (e.g., a composed `CkColorFilter` for `invertColors` inside `CkPaint`), it will leak memory because the `ui.Paint` will be garbage collected without cleaning up the cached raw backend filter.
2. **Scattered Logic**: It scatters critical memory management and finalizer logic across multiple backend implementations instead of centralizing it.
3. **Use-After-Free Risks**: If a consumer (like an `ImageFilter`) holds a reference to the backend delegate but drops the reference to the frontend wrapper, the frontend wrapper can be garbage collected. If the finalizer were tied to the frontend, this would prematurely delete the native resource while the backend delegate is still trying to use it.

## The Decision
**Memory management logic, including the attachment of `Finalizer`s for native resources, must remain strictly in the shared frontend `Engine`-classes (e.g., `EngineColorFilter`).**

Backend delegates should be treated as dumb wrappers around native handles. They should expose a `.dispose()` method, but the responsibility of invoking that method (whether explicitly or via a `Finalizer`) belongs to the frontend layer. 

Any consumer of these primitives (such as `CkPaint` or `CkColorFilterImageFilter`) must hold a strong reference to the **frontend `Engine` class**, not the raw backend delegate, to ensure the object is kept alive during garbage collection. 

## Consequences

### Positive
- **Centralized Logic**: Memory management is handled in one place, reducing duplication and edge cases across backends.
- **Safer Garbage Collection**: As long as the framework or a consumer holds a reference to the frontend object, the native resource is guaranteed to remain alive.

### Negative
- **Ephemeral Compositions**: Temporary native modifications (e.g., applying `invertColors` dynamically on a `Paint`) must be handled very carefully. Instead of caching new backend delegates, these compositions must be performed ephemerally during the drawing phase (e.g. inside `toSkPaint()`) and immediately deleted manually before the function returns to avoid leaks.
