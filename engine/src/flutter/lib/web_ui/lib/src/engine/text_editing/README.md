# Text Editing

This directory contains the implementation of text editing for the Flutter Web Engine. It bridges the Flutter framework's text input model (communicated via the `flutter/textinput` platform channel) with the web browser's native text editing capabilities.

## Purpose

Flutter's web engine uses hidden HTML `<input>` and `<textarea>` elements to capture text input from the user. This approach allows the engine to leverage native browser features such as:
- Virtual keyboards (on mobile devices)
- IME (Input Method Editor) support for complex scripts
- Autofill and password managers
- Context menus (copy/paste/select)
- Accessibility support

The classes in this directory manage the lifecycle of these hidden elements, synchronize their state with the Flutter framework, and handle platform-specific behaviors (e.g., the unique keyboard and viewport behaviors on iOS and Android).

## Files

- **`autofill_hint.dart`**: Provides a mapping between Flutter's `AutofillHints` and the standard HTML `autocomplete` attribute values used by browsers.
- **`composition_aware_mixin.dart`**: A mixin that provides common functionality for listening to and processing browser composition events (`compositionstart`, `compositionupdate`, `compositionend`). This is essential for supporting IMEs where multiple keystrokes combine into a single character.
- **`input_action.dart`**: Defines the `EngineInputAction` classes which map Flutter's `TextInputAction` to the HTML `enterkeyhint` attribute. This informs the browser which action button (e.g., "Go", "Search", "Done") to show on a virtual keyboard.
- **`input_type.dart`**: Defines the `EngineInputType` classes which map Flutter's `TextInputType` to the appropriate HTML element (`<input>` vs `<textarea>`) and the `inputmode` attribute (e.g., `numeric`, `tel`, `email`).
- **`text_capitalization.dart`**: Handles the mapping of Flutter's `TextCapitalization` settings to the HTML `autocapitalize` attribute, primarily affecting virtual keyboards on mobile browsers.
- **`text_editing.dart`**: The core of the text editing implementation. It contains:
  - `EditingState`: Represents the current text, selection, and composition state.
  - `InputConfiguration`: Represents the configuration of a text field (type, action, etc.).
  - `TextEditingStrategy`: An abstraction for managing the DOM elements used for editing.
  - Platform-specific strategies (e.g., `IOSTextEditingStrategy`, `AndroidTextEditingStrategy`) that handle the nuances of positioning and focus for different environments.
  - `HybridTextEditing`: The main coordinator that handles incoming platform messages and delegates to the active strategy.
