# Pointer Binding

This directory contains utility functions and classes that help with binding browser pointer events to Flutter's internal event system.

## Purpose

The pointer binding system acts as a bridge between the browser's DOM event model and Flutter's pointer event processing. It is responsible for:
- **Normalizing browser events:** Converting various input types (mouse, touch, stylus, trackpad) into a consistent `PointerData` format.
- **Accurate event positioning:** Computing event coordinates relative to the Flutter view, even when events target elements outside the shadow DOM.
- **Handling platform quirks:** Managing browser-specific behaviors and accessibility-triggered events (e.g., TalkBack).

## Files

- **`event_position_helper.dart`**: Provides utilities for computing accurate event offsets relative to the Flutter view, handling text editing nodes, platform views, and accessibility events.
