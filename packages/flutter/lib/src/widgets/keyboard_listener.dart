// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'focus_manager.dart';
import 'focus_scope.dart';
import 'framework.dart';

export 'package:flutter/services.dart' show KeyEvent;

/// A widget that calls a callback whenever the user presses or releases a key
/// on a keyboard.
///
/// A [KeyboardListener] is useful for listening to key events and
/// hardware buttons that are represented as keys. Typically used by games and
/// other apps that use keyboards for purposes other than text entry.
///
/// For text entry, consider using a [EditableText], which integrates with
/// on-screen keyboards and input method editors (IMEs).
///
/// The [KeyboardListener] is different from [RawKeyboardListener] in that
/// [KeyboardListener] uses the newer [HardwareKeyboard] API, which is
/// preferable.
///
/// See also:
///
///  * [EditableText], which should be used instead of this widget for text
///    entry.
///  * [RawKeyboardListener], a similar widget based on the old [RawKeyboard]
///    API.
class KeyboardListener extends StatelessWidget {
  /// Creates a widget that receives keyboard events.
  ///
  /// For text entry, consider using a [EditableText], which integrates with
  /// on-screen keyboards and input method editors (IMEs).
  ///
  /// The `key` is an identifier for widgets, and is unrelated to keyboards.
  /// See [Widget.key].
  const KeyboardListener({
    super.key,
    required this.focusNode,
    this.autofocus = false,
    this.includeSemantics = true,
    this.onKeyEvent,
    required this.child,
  });

  /// Controls whether this widget has keyboard focus.
  final FocusNode focusNode;

  /// {@macro flutter.widgets.Focus.autofocus}
  final bool autofocus;

  /// {@macro flutter.widgets.Focus.includeSemantics}
  final bool includeSemantics;

  /// Called whenever this widget receives a keyboard event.
  final ValueChanged<KeyEvent>? onKeyEvent;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      autofocus: autofocus,
      includeSemantics: includeSemantics,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        onKeyEvent?.call(event);
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<FocusNode>('focusNode', focusNode));
  }
}
