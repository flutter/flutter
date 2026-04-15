# Pointer Binding Tests

This directory contains unit tests for the helper functions used by the `PointerBinding` class to process pointer events and handle coordinate transformations in the Flutter Web engine.

## Purpose

The primary goal of these tests is to ensure that pointer event coordinates are correctly mapped from the browser's DOM events to Flutter's coordinate system. This includes handling complex scenarios such as:
- Events originating from elements inside or outside the Shadow DOM.
- Events on platform views or text editing nodes that may have their own transformations.
- Adjusting for browser-specific behaviors or accessibility tools (like TalkBack) where standard event offsets might be unreliable.

## Files

- **`event_position_helper_test.dart`**: Tests the `computeEventOffsetToTarget` function and its internal helpers. It verifies that the calculated offsets are correct across various target elements and browser configurations.
