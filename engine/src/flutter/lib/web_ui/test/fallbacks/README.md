# Fallback Tests

This directory contains tests for the fallback functionality between different build variants of the Flutter Web engine (e.g., Wasm/Skwasm vs. CanvasKit).

These tests ensure that the engine's bootstrapper correctly identifies the browser environment and selects the appropriate renderer and compiler combination.

## Files

- **`fallbacks_test.dart`**: This file contains tests for the bootstrapper logic. It verifies that:
  - On **Blink**-based browsers (like Chrome), the engine selects the **Wasm** and **Skwasm** builds, and correctly identifies if multi-threading should be enabled based on the `crossOriginIsolated` state.
  - On other browsers (like Safari or Firefox), it correctly falls back to the **CanvasKit** renderer.
