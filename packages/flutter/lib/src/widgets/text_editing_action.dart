// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/rendering.dart' show RenderEditable, TextEditingModel;
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

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

  bool get obscureText;

  // TODO(justinmc): Could this be made private?
  /// The renderer that handles [TextEditingAction]s.
  ///
  /// See also:
  ///
  /// * [EditableTextState.renderEditable], which overrides this.
  RenderEditable get renderEditable;

  TextEditingModel get textEditingModel;

  // Holds the last cursor location the user selected in the case the user tries
  // to select vertically past the end or beginning of the field. If they do,
  // then we need to keep the old cursor location so that we can go back to it
  // if they change their minds. Only used for moving selection up and down in a
  // multiline text field when selecting using the keyboard.
  int _cursorResetLocation = -1;

  // Whether we should reset the location of the cursor in the case the user
  // tries to select vertically past the end or beginning of the field. If they
  // do, then we need to keep the old cursor location so that we can go back to
  // it if they change their minds. Only used for resetting selection up and
  // down in a multiline text field when selecting using the keyboard.
  bool _wasSelectingVerticallyWithKeyboard = false;

  void setSelection(TextSelection nextState, SelectionChangedCause cause);

  void setTextEditingValue(TextEditingValue newValue, SelectionChangedCause cause);

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
  void delete(SelectionChangedCause cause) {
    if (readOnly) {
      return;
    }
    final TextEditingValue nextValue = textEditingModel.delete();
    setTextEditingValue(nextValue, cause);
  }

  /// {@macro flutter.rendering.TextEditingModel.deleteByWord}
  ///
  /// If [readOnly] is true, does nothing.
  ///
  /// If [obscureText] is true, it treats the whole text content as a single
  /// word.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// {@template flutter.rendering.RenderEditable.whiteSpace}
  /// By default, includeWhitespace is set to true, meaning that whitespace can
  /// be considered a word in itself.  If set to false, the selection will be
  /// extended past any whitespace and the first word following the whitespace.
  /// {@endtemplate}
  ///
  /// See also:
  ///
  ///   * [TextEditingModel.deleteByWord], which is used by this method.
  ///   * [deleteForwardByWord], which is same but in the opposite direction.
  void deleteByWord(SelectionChangedCause cause, [bool includeWhitespace = true]) {
    if (readOnly) {
      return;
    }

    final TextEditingValue nextValue = obscureText
        // When the text is obscured, the whole thing is treated as one big line.
        ? textEditingModel.deleteToStart()
        : textEditingModel.deleteByWord(renderEditable);

    setTextEditingValue(nextValue, cause);
  }

  /// {@macro flutter.rendering.TextEditingModel.deleteByLine}
  ///
  /// If [obscureText] is true, it treats the whole text content as
  /// a single word.
  ///
  /// If [readOnly] is true, does nothing.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingModel.deleteByLine], which is used by this method.
  ///   * [deleteForwardByLine], which is same but in the opposite direction.
  void deleteByLine(SelectionChangedCause cause) {
    if (readOnly) {
      return;
    }

    final TextEditingValue nextValue = obscureText
        // When the text is obscured, the whole thing is treated as one big line.
        ? textEditingModel.deleteToStart()
        : textEditingModel.deleteByLine(renderEditable);

    setTextEditingValue(nextValue, cause);
  }

  /// {@macro flutter.rendering.TextEditingModel.deleteForward}
  ///
  /// If [readOnly] is true, does nothing.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingModel.deleteForward], which is used by this method.
  ///   * [delete], which is same but in the opposite direction.
  void deleteForward(SelectionChangedCause cause) {
    if (readOnly) {
      return;
    }

    setTextEditingValue(textEditingModel.deleteForward(), cause);
  }

  /// {@macro flutter.rendering.TextEditingModel.deleteForwardByWord}
  ///
  /// If [readOnly] is true, does nothing.
  ///
  /// If [obscureText] is true, it treats the whole text content as
  /// a single word.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// {@macro flutter.rendering.RenderEditable.whiteSpace}
  ///
  /// See also:
  ///
  ///   * [TextEditingModel.deleteForwardByWord], which is used by this method.
  ///   * [deleteByWord], which is same but in the opposite direction.
  void deleteForwardByWord(SelectionChangedCause cause, [bool includeWhitespace = true]) {
    if (readOnly) {
      return;
    }

    final TextEditingValue nextValue = obscureText
        // When the text is obscured, the whole thing is treated as one big word.
        ? textEditingModel.deleteToEnd()
        : textEditingModel.deleteForwardByWord(renderEditable);

    setTextEditingValue(nextValue, cause);
  }

  /// {@macro flutter.rendering.TextEditingModel.deleteForwardByLine}
  ///
  /// If [readOnly] is true, does nothing.
  ///
  /// If [obscureText] is true, it treats the whole text content as
  /// a single word.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingModel.deleteForwardByWord], which is used by this method.
  ///   * [deleteByLine], which is same but in the opposite direction.
  void deleteForwardByLine(SelectionChangedCause cause) {
    if (readOnly) {
      return;
    }

    final TextEditingValue nextValue = obscureText
        // When the text is obscured, the whole thing is treated as one big line.
        ? textEditingModel.deleteToEnd()
        : textEditingModel.deleteForwardByLine(renderEditable);

    setTextEditingValue(nextValue, cause);
  }

  /// {@macro flutter.rendering.TextEditingModel.expandSelectionToEnd}
  ///
  /// If [selectionEnabled] is false, keeps the selection collapsed and moves it
  /// to the end.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [expandSelectionToStart], which is same but in the opposite direction.
  void expandSelectionToEnd(SelectionChangedCause cause) {
    if (!renderEditable.selectionEnabled) {
      return moveSelectionToEnd(cause);
    }

    final TextSelection nextSelection = textEditingModel.expandSelectionToEnd();
    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingModel.expandSelectionToStart}
  ///
  /// If [selectionEnabled] is false, keeps the selection collapsed and moves it
  /// to the start.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingModel.extendSelectionToStart], which is used by this method.
  ///   * [expandSelectionToEnd], which is the same but in the opposite
  ///     direction.
  void expandSelectionToStart(SelectionChangedCause cause) {
    if (!renderEditable.selectionEnabled) {
      return moveSelectionToStart(cause);
    }

    final TextSelection nextSelection = textEditingModel.expandSelectionToStart();
    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingModel.expandSelectionLeftByLine}
  ///
  /// If [selectionEnabled] is false, keeps the selection collapsed and moves it
  /// left by line.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingModel.extendSelectionLeftByLine], which is used by this method.
  ///   * [expandSelectionRightByLine], which is the same but in the opposite
  ///     direction.
  void expandSelectionLeftByLine(SelectionChangedCause cause) {
    if (!renderEditable.selectionEnabled) {
      return moveSelectionLeftByLine(cause);
    }

    final TextSelection nextSelection = textEditingModel.expandSelectionLeftByLine(renderEditable);
    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingModel.expandSelectionRightByLine}
  ///
  /// If [selectionEnabled] is false, keeps the selection collapsed and moves it
  /// right by line.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingModel.expandSelectionRightByLine], which is used by this method.
  ///   * [expandSelectionLeftByLine], which is the same but in the opposite
  ///     direction.
  void expandSelectionRightByLine(SelectionChangedCause cause) {
    if (!renderEditable.selectionEnabled) {
      return moveSelectionRightByLine(cause);
    }

    final TextSelection nextSelection = textEditingModel.expandSelectionRightByLine(renderEditable);

    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingModel.extendSelectionDown}
  ///
  /// If selectionEnabled is false, keeps the selection collapsed and just
  /// moves it down.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [extendSelectionUp], which is same but in the opposite direction.
  void extendSelectionDown(SelectionChangedCause cause) {
    if (!renderEditable.selectionEnabled) {
      return moveSelectionDown(cause);
    }

    TextSelection nextSelection = textEditingModel.extendSelectionDown(renderEditable);

    // When the selection is extended down after selecting all the way to the
    // top, the selection moves back to its previous location.
    if (nextSelection.extentOffset == textEditingModel.value.text.length) {
      _wasSelectingVerticallyWithKeyboard = true;
    } else if (_wasSelectingVerticallyWithKeyboard) {
      nextSelection = textEditingModel.value.selection.copyWith(
        extentOffset: _cursorResetLocation,
      );
      _wasSelectingVerticallyWithKeyboard = false;
    } else {
      _cursorResetLocation = nextSelection.extentOffset;
    }

    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingModel.extendSelectionLeft}
  ///
  /// If [selectionEnabled] is false, keeps the selection collapsed and moves it
  /// left.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingModel.extendSelectionLeft], which is used by this method.
  ///   * [extendSelectionRight], which is same but in the opposite direction.
  void extendSelectionLeft(SelectionChangedCause cause) {
    // TODO(justinmc): Can I get selectionEnabled from a cleaner place?
    if (!renderEditable.selectionEnabled) {
      return moveSelectionLeft(cause);
    }

    final TextSelection nextSelection = textEditingModel.extendSelectionLeft();
    if (nextSelection == textEditingModel.value.selection) {
      return;
    }
    final int distance = textEditingModel.value.selection.extentOffset - nextSelection.extentOffset;
    _cursorResetLocation -= distance;
    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingModel.extendSelectionLeftByLine}
  ///
  /// If [selectionEnabled] is false, keeps the selection collapsed and moves it
  /// left by line.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingModel.extendSelectionLeftByLine], which is used by this method.
  ///   * [extendSelectionRightByLine], which is same but in the opposite
  ///     direction.
  ///   * [expandSelectionRightByLine], which strictly grows the selection
  ///     regardless of the order.
  void extendSelectionLeftByLine(SelectionChangedCause cause) {
    if (!renderEditable.selectionEnabled) {
      return moveSelectionLeftByLine(cause);
    }

    final TextSelection nextSelection = textEditingModel.extendSelectionLeftByLine(renderEditable);
    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingModel.extendSelectionRight}
  ///
  /// If [selectionEnabled] is false, keeps the selection collapsed and moves it
  /// right.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingModel.extendSelectionRight], which is used by this method.
  ///   * [extendSelectionLeft], which is same but in the opposite direction.
  void extendSelectionRight(SelectionChangedCause cause) {
    if (!renderEditable.selectionEnabled) {
      return moveSelectionRight(cause);
    }

    final TextSelection nextSelection = textEditingModel.extendSelectionRight();
    if (nextSelection == textEditingModel.value.selection) {
      return;
    }
    final int distance = nextSelection.extentOffset - textEditingModel.value.selection.extentOffset;
    _cursorResetLocation += distance;
    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingModel.extendSelectionRightByLine}
  ///
  /// If [selectionEnabled] is false, keeps the selection collapsed and moves it
  /// right by line.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingModel.extendSelectionRightByLine], which is used by this method.
  ///   * [extendSelectionLeftByLine], which is same but in the opposite
  ///     direction.
  ///   * [expandSelectionRightByLine], which strictly grows the selection
  ///     regardless of the order.
  void extendSelectionRightByLine(SelectionChangedCause cause) {
    if (!renderEditable.selectionEnabled) {
      return moveSelectionRightByLine(cause);
    }

    setSelection(textEditingModel.extendSelectionRightByLine(renderEditable), cause);
  }

  // Extend the current selection to the start of the field.
  //
  // If selectionEnabled is false, keeps the selection collapsed and moves it to
  // the start.
  //
  // The given [SelectionChangedCause] indicates the cause of this change and
  // will be passed to [onSelectionChanged].
  //
  // See also:
  //
  //   * _extendSelectionToEnd
  void _extendSelectionToStart(SelectionChangedCause cause) {
    if (!renderEditable.selectionEnabled) {
      return moveSelectionToStart(cause);
    }

    final TextSelection nextSelection = textEditingModel.extendSelectionToStart();
    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingModel.extendSelectionLeftByWord}
  ///
  /// Extend the current [selection] to the previous start of a word.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// {@macro flutter.rendering.RenderEditable.whiteSpace}
  ///
  /// {@template flutter.rendering.RenderEditable.stopAtReversal}
  /// The `stopAtReversal` parameter is false by default, meaning that it's
  /// ok for the base and extent to flip their order here. If set to true, then
  /// the selection will collapse when it would otherwise reverse its order. A
  /// selection that is already collapsed is not affected by this parameter.
  /// {@endtemplate}
  ///
  /// See also:
  ///
  ///   * [TextEditingModel.extendSelectionLeftByWord], which is used by this method.
  ///   * [extendSelectionRightByWord], which is the same but in the opposite
  ///     direction.
  void extendSelectionLeftByWord(SelectionChangedCause cause, [bool includeWhitespace = true, bool stopAtReversal = false]) {
    // When the text is obscured, the whole thing is treated as one big word.
    if (obscureText) {
      return _extendSelectionToStart(cause);
    }

    // TODO(justinmc): I think this assert has to happen in RenderEditable. If
    // we need it here, I could create an overriding method in EditableTextState
    // that calls some method on RenderEditable that does the assert.
    // Same for other instances of this assertion.
    /*
    assert(
      _textLayoutLastMaxWidth == constraints.maxWidth &&
      _textLayoutLastMinWidth == constraints.minWidth,
      'Last width ($_textLayoutLastMinWidth, $_textLayoutLastMaxWidth) not the same as max width constraint (${constraints.minWidth}, ${constraints.maxWidth}).',
    );
    */
    final TextSelection nextSelection = TextEditingModel.extendGivenSelectionLeftByWord(
      textEditingModel.value.text,
      renderEditable,
      textEditingModel.value.selection,
      includeWhitespace,
      stopAtReversal,
    );
    if (nextSelection == textEditingModel.value.selection) {
      return;
    }
    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingModel.extendSelectionRightByWord}
  ///
  /// Extend the current [selection] to the next end of a word.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// {@macro flutter.rendering.RenderEditable.whiteSpace}
  ///
  /// {@macro flutter.rendering.RenderEditable.stopAtReversal}
  ///
  /// See also:
  ///
  ///   * [TextEditingModel.extendSelectionRightByWord], which is used by this method.
  ///   * [extendSelectionLeftByWord], which is the same but in the opposite
  ///     direction.
  void extendSelectionRightByWord(SelectionChangedCause cause, [bool includeWhitespace = true, bool stopAtReversal = false]) {

    /*
    assert(
      _textLayoutLastMaxWidth == constraints.maxWidth &&
      _textLayoutLastMinWidth == constraints.minWidth,
      'Last width ($_textLayoutLastMinWidth, $_textLayoutLastMaxWidth) not the same as max width constraint (${constraints.minWidth}, ${constraints.maxWidth}).',
    );
    */
    final TextSelection nextSelection = obscureText
        // When the text is obscured, the whole thing is treated as one big word.
        ? textEditingModel.extendSelectionToEnd()
        : TextEditingModel.extendGivenSelectionRightByWord(
          textEditingModel.value.text,
          renderEditable,
          textEditingModel.value.selection,
          includeWhitespace,
          stopAtReversal,
        );
    if (nextSelection == textEditingModel.value.selection) {
      return;
    }
    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingModel.extendSelectionUp}
  ///
  /// If [selectionEnabled] is false, keeps the selection collapsed and moves it
  /// up.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingModel.extendSelectionUp], which is used by this method.
  ///   * [extendSelectionDown], which is the same but in the opposite
  ///     direction.
  void extendSelectionUp(SelectionChangedCause cause) {
    if (!renderEditable.selectionEnabled) {
      return moveSelectionUp(cause);
    }

    TextSelection nextSelection = textEditingModel.extendSelectionUp(renderEditable);
    if (nextSelection.extentOffset == 0) {
      _wasSelectingVerticallyWithKeyboard = true;
    } else if (_wasSelectingVerticallyWithKeyboard) {
      nextSelection = textEditingModel.value.selection.copyWith(
        extentOffset: _cursorResetLocation,
      );
      _wasSelectingVerticallyWithKeyboard = false;
    } else {
      _cursorResetLocation = nextSelection.extentOffset;
    }
    
    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingModel.moveSelectionLeftByLine}
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingModel.moveSelectionLeftByLine], which is used by this
  ///     method.
  ///   * [moveSelectionRightByLine], which is the same but in the opposite
  ///     direction.
  void moveSelectionLeftByLine(SelectionChangedCause cause) {
    final TextSelection nextSelection = textEditingModel.moveSelectionLeftByLine(renderEditable);
    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingModel.moveSelectionDown}
  ///
  /// Move the current [selection] to the next line.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingModel.moveSelectionDown], which is used by this method.
  ///   * [moveSelectionUp], which is the same but in the opposite direction.
  void moveSelectionDown(SelectionChangedCause cause) {
    final TextSelection nextSelection = textEditingModel.moveSelectionDown(renderEditable);
    if (textEditingModel.value.selection.extentOffset == textEditingModel.value.text.length) {
      _wasSelectingVerticallyWithKeyboard = false;
    } else {
      _cursorResetLocation = nextSelection.extentOffset;
    }

    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingModel.moveSelectionLeft}
  ///
  /// Move the current [selection] left by one character.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingModel.moveSelectionLeft], which is used by this method.
  ///   * [moveSelectionRight], which is the same but in the opposite direction.
  void moveSelectionLeft(SelectionChangedCause cause) {
    final TextSelection nextSelection = TextEditingModel.moveGivenSelectionLeft(
      textEditingModel.value.selection,
      textEditingModel.value.text,
    );
    if (nextSelection == textEditingModel.value.selection) {
      return;
    }
    _cursorResetLocation -= textEditingModel.value.selection.extentOffset - nextSelection.extentOffset;
    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingModel.moveSelectionLeftByWord}
  ///
  /// Move the current [selection] to the previous start of a word.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// {@macro flutter.rendering.RenderEditable.whiteSpace}
  ///
  /// See also:
  ///
  ///   * [TextEditingModel.moveSelectionLeftByWord], which is used by this method.
  ///   * [moveSelectionRightByWord], which is the same but in the opposite
  ///     direction.
  void moveSelectionLeftByWord(SelectionChangedCause cause, [bool includeWhitespace = true]) {
    // When the text is obscured, the whole thing is treated as one big word.
    if (obscureText) {
      return moveSelectionToStart(cause);
    }

    /*
    assert(
      _textLayoutLastMaxWidth == constraints.maxWidth &&
      _textLayoutLastMinWidth == constraints.minWidth,
      'Last width ($_textLayoutLastMinWidth, $_textLayoutLastMaxWidth) not the same as max width constraint (${constraints.minWidth}, ${constraints.maxWidth}).',
    );
    */
    final TextSelection nextSelection = TextEditingModel.moveGivenSelectionLeftByWord(
      textEditingModel.value.text,
      renderEditable,
      textEditingModel.value.selection,
      includeWhitespace,
    );
    if (nextSelection == textEditingModel.value.selection) {
      return;
    }
    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingModel.moveSelectionRight}
  ///
  /// Move the current [selection] to the right by one character.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingModel.moveSelectionRight], which is used by this method.
  ///   * [moveSelectionLeft], which is the same but in the opposite direction.
  void moveSelectionRight(SelectionChangedCause cause) {
    final TextSelection nextSelection = TextEditingModel.moveGivenSelectionRight(
      textEditingModel.value.selection,
      textEditingModel.value.text,
    );
    if (nextSelection == textEditingModel.value.selection) {
      return;
    }
    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingModel.moveSelectionRightByLine}
  ///
  /// Move the current [selection] to the rightmost point of the current line.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingModel.moveSelectionRightByLine], which is used by this method.
  ///   * [moveSelectionLeftByLine], which is the same but in the opposite
  ///     direction.
  void moveSelectionRightByLine(SelectionChangedCause cause) {
    final TextSelection nextSelection = textEditingModel.moveSelectionRightByLine(renderEditable);
    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingModel.moveSelectionRightByWord}
  ///
  /// Move the current [selection] to the next end of a word.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// {@macro flutter.rendering.RenderEditable.whiteSpace}
  ///
  /// See also:
  ///
  ///   * [TextEditingModel.moveSelectionRightByWord], which is used by this
  ///     method.
  ///   * [moveSelectionLeftByWord], which is the same but in the opposite
  ///     direction.
  void moveSelectionRightByWord(SelectionChangedCause cause, [bool includeWhitespace = true]) {
    // When the text is obscured, the whole thing is treated as one big word.
    if (obscureText) {
      return moveSelectionToEnd(cause);
    }

    /*
    assert(
      _textLayoutLastMaxWidth == constraints.maxWidth &&
      _textLayoutLastMinWidth == constraints.minWidth,
      'Last width ($_textLayoutLastMinWidth, $_textLayoutLastMaxWidth) not the same as max width constraint (${constraints.minWidth}, ${constraints.maxWidth}).',
    );
    */
    final TextSelection nextSelection = TextEditingModel.moveGivenSelectionRightByWord(
      textEditingModel.value.text,
      renderEditable,
      textEditingModel.value.selection,
      includeWhitespace,
    );
    if (nextSelection == textEditingModel.value.selection) {
      return;
    }
    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingModel.moveSelectionToEnd}
  ///
  /// Move the current [selection] to the end of the field.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingModel.moveSelectionToEnd], which is used by this method.
  ///   * [moveSelectionToStart], which is the same but in the opposite
  ///     direction.
  void moveSelectionToEnd(SelectionChangedCause cause) {
    setSelection(textEditingModel.moveSelectionToEnd(), cause);
  }

  /// {@macro flutter.rendering.TextEditingModel.moveSelectionToStart}
  ///
  /// Move the current [selection] to the start of the field.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingModel.moveSelectionToStart], which is used by this method.
  ///   * [moveSelectionToEnd], which is the same but in the opposite direction.
  void moveSelectionToStart(SelectionChangedCause cause) {
    setSelection(textEditingModel.moveSelectionToStart(), cause);
  }

  /// {@macro flutter.rendering.TextEditingModel.moveSelectionUp}
  ///
  /// Move the current [selection] up by one line.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingModel.moveSelectionUp], which is used by this method.
  ///   * [moveSelectionDown], which is the same but in the opposite direction.
  void moveSelectionUp(SelectionChangedCause cause) {
    final TextSelection nextSelection = textEditingModel.moveSelectionUp(renderEditable);

    if (nextSelection.extentOffset == 0) {
      _wasSelectingVerticallyWithKeyboard = false;
    } else {
      _cursorResetLocation = nextSelection.extentOffset;
    }

    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingModel.selectAll}
  ///
  /// Set the current [selection] to contain the entire text value.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  void selectAll(SelectionChangedCause cause) {
    setSelection(
      textEditingModel.selectAll(),
      cause,
    );
  }

  /// {@macro flutter.rendering.TextEditingModel.copySelection}
  ///
  /// Copy current [selection] to [Clipboard].
  void copySelection() {
    final TextSelection selection = textEditingModel.value.selection;
    final String text = textEditingModel.value.text;
    assert(selection != null);
    if (!selection.isCollapsed) {
      Clipboard.setData(ClipboardData(text: selection.textInside(text)));
    }
  }

  /// {@macro flutter.rendering.TextEditingModel.cutSelection}
  /// Cut current [selection] to Clipboard.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  void cutSelection(SelectionChangedCause cause) {
    if (readOnly) {
      return;
    }
    final TextSelection selection = textEditingModel.value.selection;
    final String text = textEditingModel.value.text;
    assert(selection != null);
    if (!selection.isCollapsed) {
      Clipboard.setData(ClipboardData(text: selection.textInside(text)));
      setTextEditingValue(
        TextEditingValue(
          text: selection.textBefore(text) + selection.textAfter(text),
          selection: TextSelection.collapsed(offset: math.min(selection.start, selection.end)),
        ),
        cause,
      );
    }
  }

  /// {@macro flutter.rendering.TextEditingModel.pasteText}
  /// Paste text from [Clipboard].
  ///
  /// If there is currently a selection, it will be replaced.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  Future<void> pasteText(SelectionChangedCause cause) async {
    if (readOnly) {
      return;
    }
    final TextSelection selection = textEditingModel.value.selection;
    final String text = textEditingModel.value.text;
    assert(selection != null);
    // Snapshot the input before using `await`.
    // See https://github.com/flutter/flutter/issues/11427
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && selection.isValid) {
      setTextEditingValue(
        TextEditingValue(
          text: selection.textBefore(text) + data.text! + selection.textAfter(text),
          selection: TextSelection.collapsed(
              offset: math.min(selection.start, selection.end) + data.text!.length,
          ),
        ),
        cause,
      );
    }
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
