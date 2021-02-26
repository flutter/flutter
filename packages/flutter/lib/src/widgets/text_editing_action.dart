// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart' show RenderEditable;

import 'actions.dart';
import 'editable_text.dart';
import 'focus_manager.dart';
import 'framework.dart';

/// Similar to [CallbackAction]'s [OnInvokeCallback], but includes a
/// [TextEditingActionTarget] as a parameter.
///
/// Used by [TextEditingAction.onInvoke].
typedef OnInvokeTextEditingCallback<T extends Intent> = Object? Function(T intent, TextEditingActionTarget textEditingActionTarget);

/// An implementor of this must be focused for a [TextEditingAction] to be
/// enabled.
///
/// See also:
///
///   * [EditableText], which implements this and is the most typical target of
///     a TextEditingAction.
abstract class TextEditingActionTarget {
  /// The renderer that handles [TextEditingAction]s.
  ///
  /// See also:
  ///
  /// * [EditableText.renderEditable], which overrides this.
  RenderEditable get renderEditable;
}

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

  TextEditingActionTarget? get _textEditingActionTarget {
    // If an EditableText is not focused, then ignore this action.
    if (primaryFocus?.context?.widget is! EditableText) {
      return null;
    }
    return (primaryFocus!.context! as StatefulElement).state as TextEditingActionTarget;
  }

  /// The callback to be called when invoked.
  ///
  /// If an EditableText is not focused and available at
  /// `primaryFocus.context.widget`, then [isEnabled] will be false, and this
  /// will not be invoked.
  ///
  /// Must not be null.
  @protected
  final OnInvokeTextEditingCallback<T> onInvoke;

  @override
  Object? invoke(covariant T intent, [BuildContext? context]) {
    // _textEditingActionTarget shouldn't be null because isEnabled will return
    // false and invoke shouldn't be called if so.
    assert(_textEditingActionTarget != null);
    return onInvoke(intent, _textEditingActionTarget!);
  }

  @override
  bool isEnabled(Intent intent) {
    // The Action is disabled if there is no focused EditableText, or if the
    // platform is web, because web lets the browser handle text editing.
    return !kIsWeb && _textEditingActionTarget != null;
  }
}
