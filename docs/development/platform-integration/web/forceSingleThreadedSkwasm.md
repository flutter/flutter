# forceSingleThreadedSkwasm Configuration Option

The `forceSingleThreadedSkwasm` option is a boolean flag available in Flutter Web's `skwasm` WebAssembly renderer configuration.

## What it does

When enabled (`true`), it forces the `skwasm` renderer to run in a single-threaded mode regardless of the browser’s multi-threading capabilities. Without this option, the renderer attempts to use multi-threaded WebAssembly to improve performance and reduce app startup time.

## When to use

- For environments or browsers that do not support multi-threaded WebAssembly features such as `SharedArrayBuffer`.
- For debugging or troubleshooting rendering issues related to multi-threaded WebAssembly.
- To avoid potential compatibility issues caused by strict browser or server security requirements.

## Additional information

- The multi-threaded mode requires browsers to support `SharedArrayBuffer` and a secure context (HTTPS with proper Cross-Origin-Opener-Policy and Cross-Origin-Embedder-Policy headers).
- If these security requirements are not met, the renderer automatically falls back to single-threaded mode unless this option is forcibly set.
- For known issues related to this setting, see [issue #177974](https://github.com/flutter/flutter/issues/177974).

This configuration option is currently documented only in the Flutter engine source and is not yet described in the official Flutter documentation.
