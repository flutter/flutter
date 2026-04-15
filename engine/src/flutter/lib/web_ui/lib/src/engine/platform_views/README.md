# Platform Views

This directory contains the core logic for managing and rendering **Platform Views** in the Flutter Web Engine. Platform Views allow HTML elements to be embedded within the Flutter scene, enabling the use of native web components (like maps, videos, or custom HTML) alongside Flutter widgets.

## Overview

Platform views are implemented using a combination of "contents" and "slots":
- **Contents**: The actual HTML element created by a user-supplied factory. These are placed in a global registry and hidden from view by default.
- **Slots**: Standard HTML `<slot>` elements that are positioned within the Flutter rendering hierarchy. These slots "reveal" the content elements, allowing them to be composited with other Flutter layers.

## Files

- **`content_manager.dart`**: Contains `PlatformViewManager`, which handles the lifecycle of Platform View content. It manages the registry of view factories and the cached HTML elements created for each `viewId`.
- **`embedder.dart`**: Contains `PlatformViewEmbedder`, responsible for compositing Platform Views into the `ui.Scene`. It handles applying transforms, opacity, and clipping to the HTML elements to match the Flutter scene, and optimizes the use of canvases to minimize performance overhead.
- **`message_handler.dart`**: Contains `PlatformViewMessageHandler`, which acts as the bridge between the Flutter framework (via Platform Channels) and the engine's platform view logic. It processes `create` and `dispose` messages.
- **`slots.dart`**: Provides utility functions for creating and naming the "slot" and "wrapper" elements used to inject Platform Views into the DOM at the correct position in the rendering stack.
