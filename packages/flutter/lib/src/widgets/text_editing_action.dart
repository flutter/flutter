// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'actions.dart';
import 'editable_text.dart';
import 'focus_manager.dart';
import 'framework.dart';

/// Similar to [CallbackAction]'s [OnInvokeCallback], but includes
/// [EditableTextState] as a parameter.
typedef OnInvokeTextEditingCallback<T extends Intent> = Object? Function(T intent, EditableTextState editableTextState);

/// An [Action] related to editing text.
///
/// If an [EditableText] is currently focused, then it will be passed to the
/// given [onInvoke] callback. If not, then [isEnabled] will be false and
/// [onInvoke] will not be called.
///
/// See also:
///
///  * [CallbackAction], which is a similar Action type but unrelated to text
///    editing.
class TextEditingAction<T extends Intent> extends ContextAction<T> {
  /// A constructor for a [TextEditingAction].
  ///
  /// The [onInvoke] parameter must not be null.
  TextEditingAction({ required this.onInvoke }) : assert(onInvoke != null);

  EditableTextState? get _editableTextState {
    // If an EditableText is not focused, then ignore this action.
    if (primaryFocus?.context?.widget is! EditableText) {
      return null;
    }
    return (primaryFocus!.context! as StatefulElement).state as EditableTextState;
  }

  /// The callback to be called when invoked.
  ///
  /// If an EditableText is not focused and available at
  /// `primaryFocus.context.widget`, then isEnabled will be false, and this will
  /// not be invoked.
  ///
  /// Must not be null.
  @protected
  final OnInvokeTextEditingCallback<T> onInvoke;

  @override
  Object? invoke(covariant T intent, [BuildContext? context]) {
    // _editableTextState shouldn't be null because isEnabled will return false
    // and invoke shouldn't be called if so.
    assert(_editableTextState != null);
    return onInvoke(intent, _editableTextState!);
  }

  @override
  bool isEnabled(Intent intent) {
    return !kIsWeb && _editableTextState != null;
  }
}
