// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart' show RenderEditable, TextEditingModel;

import 'actions.dart';
import 'editable_text.dart';
import 'focus_manager.dart';
import 'framework.dart';

/// The recipient of a [TextEditingAction].
///
/// TextEditingActions will only be enabled when an implementer of this class is
/// focused.
///
/// See also:
///
///   * [EditableTextState], which implements this and is the most typical
///     target of a TextEditingAction.
abstract class TextEditingActionTarget {
  // TODO(justinmc): Document everything in this class.
  bool get readOnly;

  // TODO(justinmc): Could this be made private?
  /// The renderer that handles [TextEditingAction]s.
  ///
  /// See also:
  ///
  /// * [EditableTextState.renderEditable], which overrides this.
  RenderEditable get renderEditable;

  TextEditingModel get textEditingModel;

  void setSelection(TextSelection nextState, SelectionChangedCause cause);

  void setTextEditingValue(TextEditingValue newValue, SelectionChangedCause cause);

  void expandSelectionLeftByLine() {
    final TextSelection nextSelection = renderEditable.selectionEnabled
        ? textEditingModel.expandSelectionLeftByLine(renderEditable)
        : textEditingModel.moveSelectionLeftByLine();
    setSelection(nextSelection, SelectionChangedCause.keyboard);
  }

  /// Deletes backwards from the selection in [textSelectionDelegate].
  ///
  /// This method operates on the text/selection contained in
  /// [textSelectionDelegate], and does not depend on [selection].
  ///
  /// If the selection is collapsed, deletes a single character before the
  /// cursor.
  ///
  /// If the selection is not collapsed, deletes the selection.
  ///
  /// {@template flutter.rendering.RenderEditable.cause}
  /// The given [SelectionChangedCause] indicates the cause of this change and
  /// will be passed to [onSelectionChanged].
  /// {@endtemplate}
  ///
  /// See also:
  ///
  ///   * [deleteForward], which is same but in the opposite direction.
  void delete() {
    if (readOnly) {
      return;
    }
    final TextEditingValue nextValue = textEditingModel.delete(SelectionChangedCause.keyboard);
    setTextEditingValue(nextValue, SelectionChangedCause.keyboard);
  }
}

/// An [Action] related to editing text.
///
/// Enables itself only when a [TextEditingActionTarget], e.g. [EditableText],
/// is currently focused. The result of this is that when a
/// TextEditingActionTarget is not focused, it will fall through to any
/// non-TextEditingAction that handles the same shortcut. For example,
/// overriding the tab key in [Shortcuts] with a TextEditingAction will only
/// invoke your TextEditingAction when a TextEditingActionTarget is focused,
/// otherwise the default tab behavior will apply.
///
/// The currently focused TextEditingActionTarget is available in the [invoke]
/// method via [textEditingActionTarget].
///
/// See also:
///
///  * [CallbackAction], which is a similar Action type but unrelated to text
///    editing.
abstract class TextEditingAction<T extends Intent> extends ContextAction<T> {
  /// Returns the currently focused [TextEditingAction], or null if none is
  /// focused.
  @protected
  TextEditingActionTarget? get textEditingActionTarget {
    // If a TextEditingActionTarget is not focused, then ignore this action.
    if (primaryFocus?.context == null
        || primaryFocus!.context! is! StatefulElement
        || ((primaryFocus!.context! as StatefulElement).state is! TextEditingActionTarget)) {
      return null;
    }
    return (primaryFocus!.context! as StatefulElement).state as TextEditingActionTarget;
  }

  @override
  bool isEnabled(T intent) {
    // The Action is disabled if there is no focused TextEditingActionTarget.
    return textEditingActionTarget != null;
  }
}
