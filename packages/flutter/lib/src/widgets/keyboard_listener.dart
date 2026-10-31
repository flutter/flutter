// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'editable_text.dart';
library;

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
/// ## Why a [FocusNode] is required
///
/// Key events are delivered through the focus tree: each event is first sent to
/// the [FocusNode] that has primary focus, and then to each of its ancestors in
/// turn until one of them handles it. A [KeyboardListener] inserts its
/// [focusNode] into the focus tree with a [Focus] widget, so [onKeyEvent] is
/// only called when [focusNode] has focus, either because it has primary focus
/// itself or because one of its descendants does, and no descendant handled
/// the event first.
///
/// To start receiving events, the [focusNode] has to gain focus. Set
/// [autofocus] to true, or call [FocusNode.requestFocus]. The [focusNode] is
/// owned by the caller: create it in a [State] object and dispose of it in
/// [State.dispose].
///
/// [KeyboardListener] never handles the events it sees; it always lets them
/// continue to propagate to its ancestors.
///
/// To receive every key event regardless of focus, register a handler with
/// [HardwareKeyboard.addHandler] instead of using this widget.
///
/// See also:
///
///  * [EditableText], which should be used instead of this widget for text
///    entry.
///  * [Focus], which can also handle key events, and can stop them from
///    propagating further by returning [KeyEventResult.handled].
///  * [HardwareKeyboard], which can notify handlers of every key event,
///    independently of focus.
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
  ///
  /// [onKeyEvent] is only called while this node, or one of its descendants,
  /// has focus. See the class documentation for details.
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
