# Web Engine Semantics

## Overview

This directory contains the implementation of the Flutter Web Engine's semantics system. The primary purpose of this system is to translate Flutter's internal semantics tree into an accessible DOM structure that can be interpreted by screen readers, web crawlers, and other assistive technologies.

The implementation relies on ARIA (Accessible Rich Internet Applications) roles and attributes to convey the meaning and state of Flutter widgets to the browser. It manages a parallel tree of DOM elements that mirrors the semantic structure of the Flutter application, ensuring that the web experience is accessible to all users.

## Files

- **`accessibility.dart`**: Implements `AccessibilityAnnouncements`, which uses `aria-live` regions to announce messages sent from the Flutter framework (e.g., using `SemanticsService.announce`).
- **`alert.dart`**: Defines `SemanticAlert` and `SemanticStatus`, which map to ARIA `alert` and `status` roles for important or advisory information.
- **`checkable.dart`**: Handles checkable controls like checkboxes, radio buttons, and switches. It also includes the `Selectable` and `Checkable` behaviors for managing `aria-checked` and `aria-selected` states.
- **`disable.dart`**: Provides the `CanDisable` behavior, which manages the `aria-disabled` attribute based on the enabled state of a semantic node.
- **`expandable.dart`**: Provides the `Expandable` behavior for managing the `aria-expanded` attribute on nodes that can be expanded or collapsed.
- **`focusable.dart`**: Implements focus management for semantic nodes via the `Focusable` behavior and `AccessibilityFocusManager`, ensuring correct keyboard navigation and screen reader focus.
- **`form.dart`**: Defines `SemanticForm`, which uses the HTML `<form>` element to represent semantic form containers.
- **`header.dart`**: Defines `SemanticHeader`, representing a group of introductory content using the `<header>` element and ARIA `banner` role.
- **`heading.dart`**: Implements `SemanticHeading`, which renders nodes as HTML heading elements (`h1`-`h6`) based on their heading level.
- **`image.dart`**: Defines `SemanticImage`, used for visual-only elements. It handles ARIA `img` roles and provides auxiliary elements for labels when necessary.
- **`incrementable.dart`**: Implements `SemanticIncrementable`, which uses a hidden `<input type="range">` with an ARIA `slider` role to handle increment and decrement actions.
- **`label_and_value.dart`**: Contains the `LabelAndValue` behavior and logic for representing semantic labels in the DOM using various strategies: `aria-label`, text nodes, or scaled `<span>` elements for precise focus ring sizing.
- **`landmarks.dart`**: Implements various ARIA landmark roles, including `complementary`, `contentinfo`, `main`, `navigation`, and `region`.
- **`link.dart`**: Defines `SemanticLink`, which uses the HTML `<a>` element to provide accessible links with `href` support.
- **`list.dart`**: Defines `SemanticList` and `SemanticListItem`, mapping to ARIA `list` and `listitem` roles.
- **`live_region.dart`**: Provides the `LiveRegion` behavior, ensuring that changes to specific semantic nodes are automatically announced by screen readers.
- **`menus.dart`**: Implements semantic roles for menus (`menu`, `menubar`) and their items (`menuitem`, `menuitemcheckbox`, `menuitemradio`), including support for `aria-owns`.
- **`platform_view.dart`**: Manages `SemanticPlatformView`, which coordinates the accessibility of embedded platform views (like Google Maps or YouTube) within the semantics tree.
- **`progress_bar.dart`**: Defines `SemanticsProgressBar` and `SemanticsLoadingSpinner` for representing progress and activity states.
- **`requirable.dart`**: Provides the `Requirable` behavior for managing the `aria-required` attribute on input-related nodes.
- **`route.dart`**: Handles semantics for application routes and dialogs (`route`, `dialog`, `alertdialog`). It also manages `RouteName` behaviors for describing the current route.
- **`scrollable.dart`**: Implements `SemanticScrollable`, which enables vertical and horizontal scrolling via the DOM, allowing assistive technologies to trigger scroll actions.
- **`semantics_helper.dart`**: Provides utility classes like `SemanticsHelper` and `SemanticsEnabler` to manage the initial activation of semantics (e.g., via a placeholder button for mobile or desktop).
- **`semantics.dart`**: The core of the semantics system. It defines the base `SemanticsObject`, `SemanticRole`, and `SemanticBehavior` classes, as well as the `EngineSemanticsOwner` which manages the tree lifecycle.
- **`table.dart`**: Implements semantic roles for data tables, including `table`, `row`, `cell`, and `columnheader`.
- **`tabs.dart`**: Defines semantic roles for tabbed interfaces: `tab`, `tablist`, and `tabpanel`.
- **`tappable.dart`**: Implements the `Tappable` behavior for handling click and tap events, and defines the `SemanticButton` role.
- **`text_field.dart`**: Implements `SemanticTextField`, using content-editable elements or HTML inputs to provide a native-like editing experience for assistive technologies.
