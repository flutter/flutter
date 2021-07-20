// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/rendering.dart' show RenderEditable;
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

  TextEditingValue get value;

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
    final TextEditingValue nextValue = value.delete();
    setTextEditingValue(nextValue, cause);
  }

  /// {@macro flutter.rendering.TextEditingValue.deleteByWord}
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
  ///   * [TextEditingValue.deleteByWord], which is used by this method.
  ///   * [deleteForwardByWord], which is same but in the opposite direction.
  void deleteByWord(SelectionChangedCause cause, [bool includeWhitespace = true]) {
    if (readOnly) {
      return;
    }

    final TextEditingValue nextValue = obscureText
        // When the text is obscured, the whole thing is treated as one big line.
        ? value.deleteToStart()
        : value.deleteByWord(renderEditable);

    setTextEditingValue(nextValue, cause);
  }

  /// {@macro flutter.rendering.TextEditingValue.deleteByLine}
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
  ///   * [TextEditingValue.deleteByLine], which is used by this method.
  ///   * [deleteForwardByLine], which is same but in the opposite direction.
  void deleteByLine(SelectionChangedCause cause) {
    if (readOnly) {
      return;
    }

    final TextEditingValue nextValue = obscureText
        // When the text is obscured, the whole thing is treated as one big line.
        ? value.deleteToStart()
        : value.deleteByLine(renderEditable);

    setTextEditingValue(nextValue, cause);
  }

  /// {@macro flutter.rendering.TextEditingValue.deleteForward}
  ///
  /// If [readOnly] is true, does nothing.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingValue.deleteForward], which is used by this method.
  ///   * [delete], which is same but in the opposite direction.
  void deleteForward(SelectionChangedCause cause) {
    if (readOnly) {
      return;
    }

    setTextEditingValue(value.deleteForward(), cause);
  }

  /// {@macro flutter.rendering.TextEditingValue.deleteForwardByWord}
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
  ///   * [TextEditingValue.deleteForwardByWord], which is used by this method.
  ///   * [deleteByWord], which is same but in the opposite direction.
  void deleteForwardByWord(SelectionChangedCause cause, [bool includeWhitespace = true]) {
    if (readOnly) {
      return;
    }

    final TextEditingValue nextValue = obscureText
        // When the text is obscured, the whole thing is treated as one big word.
        ? value.deleteToEnd()
        : value.deleteForwardByWord(renderEditable);

    setTextEditingValue(nextValue, cause);
  }

  /// {@macro flutter.rendering.TextEditingValue.deleteForwardByLine}
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
  ///   * [TextEditingValue.deleteForwardByWord], which is used by this method.
  ///   * [deleteByLine], which is same but in the opposite direction.
  void deleteForwardByLine(SelectionChangedCause cause) {
    if (readOnly) {
      return;
    }

    final TextEditingValue nextValue = obscureText
        // When the text is obscured, the whole thing is treated as one big line.
        ? value.deleteToEnd()
        : value.deleteForwardByLine(renderEditable);

    setTextEditingValue(nextValue, cause);
  }

  /// {@macro flutter.rendering.TextEditingValue.expandSelectionToEnd}
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

    final TextSelection nextSelection = value.expandSelectionToEnd();
    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingValue.expandSelectionToStart}
  ///
  /// If [selectionEnabled] is false, keeps the selection collapsed and moves it
  /// to the start.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingValue.extendSelectionToStart], which is used by this method.
  ///   * [expandSelectionToEnd], which is the same but in the opposite
  ///     direction.
  void expandSelectionToStart(SelectionChangedCause cause) {
    if (!renderEditable.selectionEnabled) {
      return moveSelectionToStart(cause);
    }

    final TextSelection nextSelection = value.expandSelectionToStart();
    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingValue.expandSelectionLeftByLine}
  ///
  /// If [selectionEnabled] is false, keeps the selection collapsed and moves it
  /// left by line.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingValue.extendSelectionLeftByLine], which is used by this method.
  ///   * [expandSelectionRightByLine], which is the same but in the opposite
  ///     direction.
  void expandSelectionLeftByLine(SelectionChangedCause cause) {
    if (!renderEditable.selectionEnabled) {
      return moveSelectionLeftByLine(cause);
    }

    final TextSelection nextSelection = value.expandSelectionLeftByLine(renderEditable);
    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingValue.expandSelectionRightByLine}
  ///
  /// If [selectionEnabled] is false, keeps the selection collapsed and moves it
  /// right by line.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingValue.expandSelectionRightByLine], which is used by this method.
  ///   * [expandSelectionLeftByLine], which is the same but in the opposite
  ///     direction.
  void expandSelectionRightByLine(SelectionChangedCause cause) {
    if (!renderEditable.selectionEnabled) {
      return moveSelectionRightByLine(cause);
    }

    final TextSelection nextSelection = value.expandSelectionRightByLine(renderEditable);

    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingValue.extendSelectionDown}
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

    TextSelection nextSelection = value.extendSelectionDown(renderEditable);

    // When the selection is extended down after selecting all the way to the
    // top, the selection moves back to its previous location.
    if (nextSelection.extentOffset == value.text.length) {
      _wasSelectingVerticallyWithKeyboard = true;
    } else if (_wasSelectingVerticallyWithKeyboard) {
      nextSelection = value.selection.copyWith(
        extentOffset: _cursorResetLocation,
      );
      _wasSelectingVerticallyWithKeyboard = false;
    } else {
      _cursorResetLocation = nextSelection.extentOffset;
    }

    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingValue.extendSelectionLeft}
  ///
  /// If [selectionEnabled] is false, keeps the selection collapsed and moves it
  /// left.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingValue.extendSelectionLeft], which is used by this method.
  ///   * [extendSelectionRight], which is same but in the opposite direction.
  void extendSelectionLeft(SelectionChangedCause cause) {
    // TODO(justinmc): Can I get selectionEnabled from a cleaner place?
    if (!renderEditable.selectionEnabled) {
      return moveSelectionLeft(cause);
    }

    final TextSelection nextSelection = value.extendSelectionLeft();
    if (nextSelection == value.selection) {
      return;
    }
    final int distance = value.selection.extentOffset - nextSelection.extentOffset;
    _cursorResetLocation -= distance;
    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingValue.extendSelectionLeftByLine}
  ///
  /// If [selectionEnabled] is false, keeps the selection collapsed and moves it
  /// left by line.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingValue.extendSelectionLeftByLine], which is used by this method.
  ///   * [extendSelectionRightByLine], which is same but in the opposite
  ///     direction.
  ///   * [expandSelectionRightByLine], which strictly grows the selection
  ///     regardless of the order.
  void extendSelectionLeftByLine(SelectionChangedCause cause) {
    if (!renderEditable.selectionEnabled) {
      return moveSelectionLeftByLine(cause);
    }

    final TextSelection nextSelection = value.extendSelectionLeftByLine(renderEditable);
    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingValue.extendSelectionRight}
  ///
  /// If [selectionEnabled] is false, keeps the selection collapsed and moves it
  /// right.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingValue.extendSelectionRight], which is used by this method.
  ///   * [extendSelectionLeft], which is same but in the opposite direction.
  void extendSelectionRight(SelectionChangedCause cause) {
    if (!renderEditable.selectionEnabled) {
      return moveSelectionRight(cause);
    }

    final TextSelection nextSelection = value.extendSelectionRight();
    if (nextSelection == value.selection) {
      return;
    }
    final int distance = nextSelection.extentOffset - value.selection.extentOffset;
    _cursorResetLocation += distance;
    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingValue.extendSelectionRightByLine}
  ///
  /// If [selectionEnabled] is false, keeps the selection collapsed and moves it
  /// right by line.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingValue.extendSelectionRightByLine], which is used by this method.
  ///   * [extendSelectionLeftByLine], which is same but in the opposite
  ///     direction.
  ///   * [expandSelectionRightByLine], which strictly grows the selection
  ///     regardless of the order.
  void extendSelectionRightByLine(SelectionChangedCause cause) {
    if (!renderEditable.selectionEnabled) {
      return moveSelectionRightByLine(cause);
    }

    setSelection(value.extendSelectionRightByLine(renderEditable), cause);
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

    final TextSelection nextSelection = value.extendSelectionToStart();
    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingValue.extendSelectionLeftByWord}
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
  ///   * [TextEditingValue.extendSelectionLeftByWord], which is used by this method.
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
    final TextSelection nextSelection = TextEditingValue.extendGivenSelectionLeftByWord(
      value.text,
      renderEditable,
      value.selection,
      includeWhitespace,
      stopAtReversal,
    );
    if (nextSelection == value.selection) {
      return;
    }
    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingValue.extendSelectionRightByWord}
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
  ///   * [TextEditingValue.extendSelectionRightByWord], which is used by this method.
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
        ? value.extendSelectionToEnd()
        : TextEditingValue.extendGivenSelectionRightByWord(
          value.text,
          renderEditable,
          value.selection,
          includeWhitespace,
          stopAtReversal,
        );
    if (nextSelection == value.selection) {
      return;
    }
    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingValue.extendSelectionUp}
  ///
  /// If [selectionEnabled] is false, keeps the selection collapsed and moves it
  /// up.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingValue.extendSelectionUp], which is used by this method.
  ///   * [extendSelectionDown], which is the same but in the opposite
  ///     direction.
  void extendSelectionUp(SelectionChangedCause cause) {
    if (!renderEditable.selectionEnabled) {
      return moveSelectionUp(cause);
    }

    TextSelection nextSelection = value.extendSelectionUp(renderEditable);
    if (nextSelection.extentOffset == 0) {
      _wasSelectingVerticallyWithKeyboard = true;
    } else if (_wasSelectingVerticallyWithKeyboard) {
      nextSelection = value.selection.copyWith(
        extentOffset: _cursorResetLocation,
      );
      _wasSelectingVerticallyWithKeyboard = false;
    } else {
      _cursorResetLocation = nextSelection.extentOffset;
    }
    
    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingValue.moveSelectionLeftByLine}
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingValue.moveSelectionLeftByLine], which is used by this
  ///     method.
  ///   * [moveSelectionRightByLine], which is the same but in the opposite
  ///     direction.
  void moveSelectionLeftByLine(SelectionChangedCause cause) {
    final TextSelection nextSelection = value.moveSelectionLeftByLine(renderEditable);
    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingValue.moveSelectionDown}
  ///
  /// Move the current [selection] to the next line.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingValue.moveSelectionDown], which is used by this method.
  ///   * [moveSelectionUp], which is the same but in the opposite direction.
  void moveSelectionDown(SelectionChangedCause cause) {
    final TextSelection nextSelection = value.moveSelectionDown(renderEditable);
    if (value.selection.extentOffset == value.text.length) {
      _wasSelectingVerticallyWithKeyboard = false;
    } else {
      _cursorResetLocation = nextSelection.extentOffset;
    }

    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingValue.moveSelectionLeft}
  ///
  /// Move the current [selection] left by one character.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingValue.moveSelectionLeft], which is used by this method.
  ///   * [moveSelectionRight], which is the same but in the opposite direction.
  void moveSelectionLeft(SelectionChangedCause cause) {
    final TextSelection nextSelection = TextEditingValue.moveGivenSelectionLeft(
      value.selection,
      value.text,
    );
    if (nextSelection == value.selection) {
      return;
    }
    _cursorResetLocation -= value.selection.extentOffset - nextSelection.extentOffset;
    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingValue.moveSelectionLeftByWord}
  ///
  /// Move the current [selection] to the previous start of a word.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// {@macro flutter.rendering.RenderEditable.whiteSpace}
  ///
  /// See also:
  ///
  ///   * [TextEditingValue.moveSelectionLeftByWord], which is used by this method.
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
    final TextSelection nextSelection = TextEditingValue.moveGivenSelectionLeftByWord(
      value.text,
      renderEditable,
      value.selection,
      includeWhitespace,
    );
    if (nextSelection == value.selection) {
      return;
    }
    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingValue.moveSelectionRight}
  ///
  /// Move the current [selection] to the right by one character.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingValue.moveSelectionRight], which is used by this method.
  ///   * [moveSelectionLeft], which is the same but in the opposite direction.
  void moveSelectionRight(SelectionChangedCause cause) {
    final TextSelection nextSelection = TextEditingValue.moveGivenSelectionRight(
      value.selection,
      value.text,
    );
    if (nextSelection == value.selection) {
      return;
    }
    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingValue.moveSelectionRightByLine}
  ///
  /// Move the current [selection] to the rightmost point of the current line.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingValue.moveSelectionRightByLine], which is used by this method.
  ///   * [moveSelectionLeftByLine], which is the same but in the opposite
  ///     direction.
  void moveSelectionRightByLine(SelectionChangedCause cause) {
    final TextSelection nextSelection = value.moveSelectionRightByLine(renderEditable);
    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingValue.moveSelectionRightByWord}
  ///
  /// Move the current [selection] to the next end of a word.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// {@macro flutter.rendering.RenderEditable.whiteSpace}
  ///
  /// See also:
  ///
  ///   * [TextEditingValue.moveSelectionRightByWord], which is used by this
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
    final TextSelection nextSelection = TextEditingValue.moveGivenSelectionRightByWord(
      value.text,
      renderEditable,
      value.selection,
      includeWhitespace,
    );
    if (nextSelection == value.selection) {
      return;
    }
    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingValue.moveSelectionToEnd}
  ///
  /// Move the current [selection] to the end of the field.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingValue.moveSelectionToEnd], which is used by this method.
  ///   * [moveSelectionToStart], which is the same but in the opposite
  ///     direction.
  void moveSelectionToEnd(SelectionChangedCause cause) {
    setSelection(value.moveSelectionToEnd(), cause);
  }

  /// {@macro flutter.rendering.TextEditingValue.moveSelectionToStart}
  ///
  /// Move the current [selection] to the start of the field.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingValue.moveSelectionToStart], which is used by this method.
  ///   * [moveSelectionToEnd], which is the same but in the opposite direction.
  void moveSelectionToStart(SelectionChangedCause cause) {
    setSelection(value.moveSelectionToStart(), cause);
  }

  /// {@macro flutter.rendering.TextEditingValue.moveSelectionUp}
  ///
  /// Move the current [selection] up by one line.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [TextEditingValue.moveSelectionUp], which is used by this method.
  ///   * [moveSelectionDown], which is the same but in the opposite direction.
  void moveSelectionUp(SelectionChangedCause cause) {
    final TextSelection nextSelection = value.moveSelectionUp(renderEditable);

    if (nextSelection.extentOffset == 0) {
      _wasSelectingVerticallyWithKeyboard = false;
    } else {
      _cursorResetLocation = nextSelection.extentOffset;
    }

    setSelection(nextSelection, cause);
  }

  /// {@macro flutter.rendering.TextEditingValue.selectAll}
  ///
  /// Set the current [selection] to contain the entire text value.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  void selectAll(SelectionChangedCause cause) {
    setSelection(
      value.selectAll(),
      cause,
    );
  }

  /// {@macro flutter.rendering.TextEditingValue.copySelection}
  ///
  /// Copy current [selection] to [Clipboard].
  void copySelection() {
    final TextSelection selection = value.selection;
    final String text = value.text;
    assert(selection != null);
    if (!selection.isCollapsed) {
      Clipboard.setData(ClipboardData(text: selection.textInside(text)));
    }
  }

  /// {@macro flutter.rendering.TextEditingValue.cutSelection}
  /// Cut current [selection] to Clipboard.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  void cutSelection(SelectionChangedCause cause) {
    if (readOnly) {
      return;
    }
    final TextSelection selection = value.selection;
    final String text = value.text;
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

  /// {@macro flutter.rendering.TextEditingValue.pasteText}
  /// Paste text from [Clipboard].
  ///
  /// If there is currently a selection, it will be replaced.
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  Future<void> pasteText(SelectionChangedCause cause) async {
    if (readOnly) {
      return;
    }
    final TextSelection selection = value.selection;
    final String text = value.text;
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
