# Impeller Standalone SDK

## Goals

This Impeller Standalone API is a single-header C API with no external dependencies.

### Full-featured

The library supports all rendering operations supported by Flutter with few exceptions. An optional text-layout and shaping engine is included by default.

### Easy to Embed

The entire library is distributed as a single dynamic library. The public API can be found in a single C header with no dependencies.

For the common platforms, prebuilt artifacts are generated per Flutter Engine commit.

### Easy Interoperability

The C API allows for explicit management of object lifecycle and is well suited for the generation of automated bindings to languages like Rust, Dart, Lua, etc…

### Lightweight

The core rendering engine is less than 200 KB compressed.

The text layout and shaping engine along with the bundled ICU data tables brings the size up to ~2.5 MB. If the application does not need text layout and shaping, or can interface with an existing library on the target platform, it is recommended to generate the SDK without built-in support for typography. Impeller is a rendering engine but typography is really hard to get right and needed by most users of a rendering engine. That is why one is included by default. But it is optional.

> [!CAUTION]
> Users of the prebuilt artifacts should strip the binaries before deployment as these contain debug symbols.

### Performant

Built to perform the best when using a modern graphics API like Metal or Vulkan (not all may be available to start) and when running on mobile tiler GPUs like the ones found in smartphones and AppleSilicon/ARM desktops.

Impeller does need a GPU. Performance will likely be inadequate for interactive use cases when using software rendering. Software rendering can be enabled using projects like SwiftShader, Angle, LLVMPipe, etc… If you are using software rendering in your projects, restrict its use to testing on CI. Impeller will likely never have a dedicated software renderer.

# API Stability

Unlike the Flutter Embedder API which has a stable API as well as ABI, the Impeller API does **not** currently have stability guarantees.

The API does look similar to the one used by Flutter in Dart so major overhauls are not realistically on the horizon.

The API is also versioned and there may be stability guarantees between specific versions in the future.

# Prebuilt Artifacts

Users may plug in any toolchain into the Flutter Engine build system to build the libimpeller.so dynamic library. However, for the common platforms, the CI bots upload a tarball containing the library and headers. This URL for the SDK tarball for a particular platform can be constructed as follows:

```sh
https://storage.googleapis.com/flutter_infra_release/flutter/$FLUTTER_ENGINE_SHA/$PLATFORM_ARCH/impeller_sdk.zip
```

The `$FLUTTER_ENGINE_SHA` is the Git hash in the Flutter Engine repository. To make sure all artifacts for a specific hash have been successfully generated, look up the Flutter Engine SHA currently used by the Flutter Framework in the [engine.version](https://github.com/flutter/flutter/blob/master/bin/internal/engine.version) file.

The `$PLATFORM_ARCH` can be determined from the table below.

|       | macOS        | Linux       | Android        | Windows       |
|:-----:|:------------:|:-----------:|:--------------:|:-------------:|
| armv7 |              |             | android-arm    |               |
| arm64 | darwin-arm64 | linux-arm64 | android-arm64  | windows-arm64 |
| x86   |              |             | android-x86    |               |
| x64   | darwin-x64   | linux-x64   | android-x64    | windows-x64   |


For example, the SDK for `Linux x64` at engine SHA `31aaaaad868743b38ac3b7165f0d58eca94e521b` would be https://storage.googleapis.com/flutter_infra_release/flutter/31aaaaad868743b38ac3b7165f0d58eca94e521b/linux-x64/impeller_sdk.zip

# Example

A fully functional example of using Impeller to draw using GLFW is available in [`example.c`](example.c). This example is also present in the `impeller_sdk.zip` prebuilts along with necessary artifacts.

# API Fundamentals

## Versioning

The current version of the API is denoted by the `IMPELLER_VERSION` macro. This version must be passed to APIs that create top-level objects like graphics contexts. Construction of the context may fail if the API version expected by the caller is not supported by the library.

The version currently supported by the library is returned by a call to `ImpellerGetVersion()`

Since there are no API stability guarantees today, passing a version that is different to the one returned by `ImpellerGetVersion` will always fail.

## Object Model

Users interact with Impeller objects using opaque handles. Impeller objects can be identified by their definition using `IMPELLER_DEFINE_HANDLE` in the SDK.

All Impeller objects are thread-safe reference-counted.

## Reference Management

Methods in the Impeller API follow a very strict convention. This makes it easy to write automated bindings generators that handle object lifecycles to various degrees:

* Methods that end with `Retain` increment the reference count of the object by 1.
* Methods that end with `Release` decrement the reference count of the object by 1. When the reference count of the object reaches 0, the object is collected.
* Methods that end with `New` create a new object with a reference count of 1.
  * This reference must be relinquished by the appropriate call to `Release`.
* The framework may hold strong references to objects internally. When the user releases their last reference, it is not guaranteed that the object will be immediately destructed.
* Reference counts can be incremented and decremented in a thread-safe manner. But, not all objects can be used safely from multiple thread concurrently. The thread safety attributes of the object should be documented in the header.

## Null Safety

The Impeller API passes [nullability completeness](https://clang.llvm.org/docs/DiagnosticsReference.html#wnullability-completeness) checks. All pointer arguments and return values are decorated with `IMPELLER_NULLABLE` and `IMPELLER_NONNULL`. Passing a null pointer to an argument decorated with `IMPELLER_NONNULL` will very likely result in a null pointer dereference. When generating automated bindings to other languages, it is recommended that these decorations be used to inform the API and perform additional checks.
