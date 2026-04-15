# Semantics Tests

This directory contains unit tests for the Flutter Web Engine's accessibility (semantics) implementation. These tests ensure that the engine correctly maps Flutter's semantic tree to a DOM-based representation that can be consumed by assistive technologies like screen readers.

## Purpose

The tests in this directory verify that:
1.  **Semantics Trees are correctly built and updated** in the DOM based on updates from the Flutter framework.
2.  **Semantic Roles and Behaviors** (e.g., buttons, text fields, scrollables) are correctly translated into ARIA roles and attributes.
3.  **Accessibility Announcements** (e.g., `aria-live` regions) function correctly.
4.  **User Interactions** with semantic elements (like clicking, tapping, or typing) are correctly dispatched back to the Flutter framework.
5.  **Multi-view semantics** are independent and correctly handled for applications with multiple root views.

## Files

- **`scrollable_test.dart`**: Tests for `SemanticScrollable` behavior, including transitions between scrollable and non-scrollable states and the management of overflow elements.
- **`selectable_test.dart`**: Verifies `Selectable` behavior, specifically how `aria-current` and `aria-selected` attributes are managed for elements like images and tabs.
- **`semantics_announcement_test.dart`**: Tests the `AccessibilityAnnouncements` system, which handles ARIA live regions for polite and assertive announcements.
- **`semantics_api_test.dart`**: Verifies the internal mapping and consistency of `SemanticsFlag` and `SemanticsAction` definitions.
- **`semantics_auto_enable_test.dart`**: Ensures that the engine automatically enables semantics when a semantics update is received from the framework.
- **`semantics_helper_test.dart`**: Tests the `DesktopSemanticsEnabler` and `MobileSemanticsEnabler`, which provide the initial placeholder elements used to detect and enable semantics on various platforms.
- **`semantics_multi_view_test.dart`**: Verifies that multiple `EngineFlutterView`s can each maintain and render their own independent semantics trees correctly.
- **`semantics_placeholder_enable_test.dart`**: Tests the process of enabling semantics via user interaction (clicks) on the accessibility placeholder.
- **`semantics_test.dart`**: A large, comprehensive test file covering a wide range of semantic roles (e.g., buttons, links, images, headings), lifecycle events, hit testing, and tree transformations.
- **`semantics_tester.dart`**: A utility class (`SemanticsTester`) that provides a simplified API for building and inspecting the semantics tree in unit tests. This is a helper used by most other tests in this directory.
- **`semantics_text_test.dart`**: Tests how text labels and hints are rendered in the DOM, including the use of `<span>` elements and their interaction with focus and pointer events.
- **`tappable_test.dart`**: Verifies `Tappable` behavior, focusing on the addition and removal of the `flt-tappable` attribute and event listeners based on node state.
- **`text_field_test.dart`**: Comprehensive tests for `SemanticTextField`, covering single-line, multi-line, and obscured text inputs, as well as focus handling and synchronization with the framework's text input strategy.
