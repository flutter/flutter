// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


part of engine;

/// Provides mouse cursor bindings, such as the `flutter/mousecursor` channel.
class MouseCursor {
  /// Initializes the [MouseCursor] singleton.
  ///
  /// Use the [instance] getter to get the singleton after calling this method.
  static void initialize() {
    _instance ??= MouseCursor._();
  }

  /// The [MouseCursor] singleton.
  static MouseCursor? get instance => _instance;
  static MouseCursor? _instance;

  MouseCursor._() {}

  // The kind values must be kept in sync with flutter's
  // rendering/mouse_cursor.dart
  static const Map<String, String> _kindToCssValueMap = <String, String>{
    'none': 'none',
    'basic': 'default',
    'click': 'pointer',
    'text': 'text',
    'forbidden': 'not-allowed',
    'grab': 'grab',
    'grabbing': 'grabbing',
    'horizontalDoubleArrow': 'ew-resize',
    'verticalDoubleArrow': 'ns-resize',
  };
  static String _mapKindToCssValue(String? kind) {
    return _kindToCssValueMap[kind] ?? 'default';
  }

  void activateSystemCursor(String? kind) {
    domRenderer.setElementStyle(
      domRenderer.glassPaneElement!,
      'cursor',
      _mapKindToCssValue(kind),
    );
  }
}
