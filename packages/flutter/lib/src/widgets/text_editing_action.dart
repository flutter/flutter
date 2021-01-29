// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

// TODO(justinmc): Instead of passing in editableTextState like this, should I
// create a hardcoded Intent type that has it?
// Or, should _editableTextState be public but protected?
/// The signature of a callback accepted by [TextEditingAction].
typedef _OnInvokeTextEditingCallback<T extends Intent> = Object? Function(
  T intent,
  EditableTextState editableTextState,
);

/// An [Action] related to editing text.
///
/// If an [EditableText] is currently focused, the given [onInvoke] callback
/// will be called with the [EditableTextState]. If not, then [isEnabled] will
/// be false and [onInvoke] will not be called.
///
/// See also:
///
///  * [CallbackAction], which is a similar Action type but unrelated to text
///    editing.
class TextEditingAction<T extends Intent> extends Action<T> {
  /// A constructor for a [TextEditingAction].
  ///
  /// The [onInvoke] parameter must not be null.
  /// The [onInvoke] parameter is required.
  TextEditingAction({required this.onInvoke}) : assert(onInvoke != null);

  EditableTextState? get _editableTextState {
    // If an EditableText is not focused, then ignore this action.
    if (primaryFocus?.context?.widget is! EditableText) {
      return null;
    }
    final EditableText editableText = primaryFocus!.context!.widget as EditableText;
    // TODO(justinmc): I seem to need the EditableText to have a key for
    // this. Is there another way to get EditableTextState, or should I
    // force EditableText to have a key?
    if (editableText.key == null
        || (editableText.key! as GlobalKey).currentState == null) {
      return null;
    }
    return (editableText.key! as GlobalKey).currentState! as EditableTextState;
  }

  /// The callback to be called when invoked.
  ///
  /// If an EditableText is not focused, then isEnabled will be false, and this
  /// will not be invoked.
  ///
  /// Must not be null.
  @protected
  final _OnInvokeTextEditingCallback<T> onInvoke;

  @override
  Object? invoke(covariant T intent) {
    // _editableTextState shouldn't be null because isEnabled will return false
    // and invoke shouldn't be called if so.
    assert(_editableTextState != null);
    return onInvoke(intent, _editableTextState!);
  }

  @override
  bool isEnabled(Intent intent) {
    return _editableTextState != null;
  }
}
