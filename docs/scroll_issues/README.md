# Flutter Web Scroll Event Handling Fixes

This directory documents the fixes for three related GitHub issues dealing with scroll event handling in Flutter web applications.

## Issues Overview

| Issue | Problem | Key Fix |
|-------|---------|---------|
| [#156985](issue_156985.md) | Scroll events bubble to parent page when Flutter is in iframe | `preventDefault()` in iframe + explicit parent scroll via `postMessage` |
| [#157435](issue_157435.md) | Touch scroll doesn't propagate to host page (embedded mode) | Don't `preventDefault()` on touch + platform channel for scroll propagation |
| [#113196](issue_113196.md) | Mouse scroll blocked over cross-origin iframe in HtmlElementView | Transparent overlay captures wheel events and forwards to Flutter |

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Host/Parent Page                         │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    Flutter Web App                        │   │
│  │  ┌─────────────────────────────────────────────────────┐ │   │
│  │  │              Flutter Scrollables                     │ │   │
│  │  │  ┌───────────────────────────────────────────────┐  │ │   │
│  │  │  │   HtmlElementView (cross-origin iframe)       │  │ │   │
│  │  │  │   + Wheel Overlay (Issue #113196)             │  │ │   │
│  │  │  └───────────────────────────────────────────────┘  │ │   │
│  │  └─────────────────────────────────────────────────────┘ │   │
│  │                                                          │   │
│  │  pointer_binding.dart:                                   │   │
│  │  - Detects iframe embedding (Issue #156985)              │   │
│  │  - preventDefault() to block native scroll chaining       │   │
│  │  - Explicit parent scroll via postMessage                │   │
│  │  - Touch event handling (Issue #157435)                  │   │
│  └──────────────────────────────────────────────────────────┘   │
│                              │                                   │
│                    postMessage('flutter-scroll')                 │
│                              ▼                                   │
│           window.addEventListener('message', scrollBy)           │
└─────────────────────────────────────────────────────────────────┘
```

## Files Modified

### Engine (`engine/src/flutter/lib/web_ui/lib/src/engine/`)

| File | Changes |
|------|---------|
| `pointer_binding.dart` | Iframe detection, preventDefault in iframe, touch event handling, parent scroll |
| `dom.dart` | `scrollParentWindow()` function, `parent` property on DomWindow |
| `platform_dispatcher.dart` | `flutter/scroll` platform channel handler |
| `platform_views/content_manager.dart` | Wheel overlay for HtmlElementView |
| `view_embedder/embedding_strategy/*.dart` | `overscroll-behavior: contain` CSS |

### Framework (`packages/flutter/lib/src/widgets/`)

| File | Changes |
|------|---------|
| `scrollable.dart` | `respond(allowPlatformDefault: false)` when scroll handled |
| `scroll_position_with_single_context.dart` | Touch scroll propagation via platform channel |

## Demo Apps

| Issue | Before | After |
|-------|--------|-------|
| #156985 | https://issue-156985-before.web.app | https://issue-156985-after.web.app |
| #157435 | https://issue-157435-before.web.app | https://issue-157435-after.web.app |
| #113196 | https://issue-113196-before.web.app | https://issue-113196-after.web.app |

## Host Page Requirements

For iframe embedding (Issue #156985), the host page must listen for scroll messages:

```html
<script>
  window.addEventListener('message', function(event) {
    if (event.data && event.data.type === 'flutter-scroll') {
      window.scrollBy(event.data.deltaX, event.data.deltaY);
    }
  });
</script>
```

## Testing

```bash
# Build engine with changes
cd /Users/zhongliu/dev/flutter/engine/src/flutter/lib/web_ui
felt build

# Test demo app
cd /Users/zhongliu/dev/flutter-apps/issue_156985_after
flutter run -d chrome --local-web-sdk=wasm_release

# Verify:
# 1. Scroll inside Flutter - parent page should NOT scroll
# 2. Scroll to boundary - parent page SHOULD scroll
# 3. Nested scrollables - inner scrolls first, then outer, then parent
```

## Key Design Decisions

1. **`postMessage` for cross-origin safety**: Using `postMessage` instead of direct `window.parent.scrollBy()` ensures the solution works for both same-origin and cross-origin iframes.

2. **Two-flag system for nested scrollables**: The `_lastWheelEventAllowedDefault` and `_lastWheelEventHandledByWidget` flags work together to ensure correct behavior with nested scrollables.

3. **Overlay for cross-origin iframes**: Since cross-origin iframes completely isolate events, an overlay is the only way to capture wheel events without breaking iframe functionality.

4. **Don't block touch events**: Touch scrolling uses browser native behavior, so we don't `preventDefault()` on touch to allow smooth scrolling experience.

