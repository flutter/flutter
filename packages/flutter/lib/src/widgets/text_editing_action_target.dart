// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show TextAffinity, TextPosition;

import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'
    show Clipboard, ClipboardData, TextLayoutMetrics, TextRange;

import 'editable_text.dart';

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
  /// Whether the characters in the field are obscured from the user.
  ///
  /// When true, the entire contents of the field are treated as one word.
  bool get obscureText;

  /// Whether the field currently in a read-only state.
  ///
  /// When true, [textEditingValue]'s text may not be modified, but its selection can be.
  bool get readOnly;

  /// Whether the [textEditingValue]'s selection can be modified.
  bool get selectionEnabled;

  /// Provides information about the text that is the target of this action.
  ///
  /// See also:
  ///
  /// * [EditableTextState.renderEditable], which overrides this.
  TextLayoutMetrics get textLayoutMetrics;

  /// The [TextEditingValue] expressed in this field.
  TextEditingValue get textEditingValue;

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

  /// Called when assuming that the text layout is in sync with
  /// [textEditingValue].
  ///
  /// Can be overridden to assert that this is a valid assumption.
  void debugAssertLayoutUpToDate();

  /// Returns the index into the string of the next character boundary after the
  /// given index.
  ///
  /// The character boundary is determined by the characters package, so
  /// surrogate pairs and extended grapheme clusters are considered.
  ///
  /// The index must be between 0 and string.length, inclusive. If given
  /// string.length, string.length is returned.
  ///
  /// Setting includeWhitespace to false will only return the index of non-space
  /// characters.
  @visibleForTesting
  static int nextCharacter(int index, String string, [bool includeWhitespace = true]) {
    assert(index >= 0 && index <= string.length);
    if (index == string.length) {
      return string.length;
    }

    final CharacterRange range = CharacterRange.at(string, 0, index);
    // If index is not on a character boundary, return the next character
    // boundary.
    if (range.current.length != index) {
      return range.current.length;
    }

    range.expandNext();
    if (!includeWhitespace) {
      range.expandWhile((String character) {
        return TextLayoutMetrics.isWhitespace(character.codeUnitAt(0));
      });
    }
    return range.current.length;
  }

  /// Returns the index into the string of the previous character boundary
  /// before the given index.
  ///
  /// The character boundary is determined by the characters package, so
  /// surrogate pairs and extended grapheme clusters are considered.
  ///
  /// The index must be between 0 and string.length, inclusive. If index is 0,
  /// 0 will be returned.
  ///
  /// Setting includeWhitespace to false will only return the index of non-space
  /// characters.
  @visibleForTesting
  static int previousCharacter(int index, String string, [bool includeWhitespace = true]) {
    assert(index >= 0 && index <= string.length);
    if (index == 0) {
      return 0;
    }

    final CharacterRange range = CharacterRange.at(string, 0, index);
    // If index is not on a character boundary, return the previous character
    // boundary.
    if (range.current.length != index) {
      range.dropLast();
      return range.current.length;
    }

    range.dropLast();
    if (!includeWhitespace) {
      while (range.currentCharacters.isNotEmpty
          && TextLayoutMetrics.isWhitespace(range.charactersAfter.first.codeUnitAt(0))) {
        range.dropLast();
      }
    }
    return range.current.length;
  }

  /// {@template flutter.widgets.TextEditingActionTarget.setSelection}
  /// Called to update the [TextSelection] in the current [TextEditingValue].
  /// {@endtemplate}
  void setSelection(TextSelection nextSelection, SelectionChangedCause cause) {
    if (nextSelection == textEditingValue.selection) {
      return;
    }
    setTextEditingValue(
      textEditingValue.copyWith(selection: nextSelection),
      cause,
    );
  }

  /// {@template flutter.widgets.TextEditingActionTarget.setTextEditingValue}
  /// Called to update the current [TextEditingValue].
  /// {@endtemplate}
  void setTextEditingValue(TextEditingValue newValue, SelectionChangedCause cause);

  // Extend the current selection to the end of the field.
  //
  // If selectionEnabled is false, keeps the selection collapsed and moves it to
  // the end.
  //
  // See also:
  //
  //   * _extendSelectionToStart
  void _extendSelectionToEnd(SelectionChangedCause cause) {
    if (textEditingValue.selection.extentOffset == textEditingValue.text.length) {
      return;
    }

    final TextSelection nextSelection = textEditingValue.selection.copyWith(
      extentOffset: textEditingValue.text.length,
    );
    return setSelection(nextSelection, cause);
  }

  // Extend the current selection to the start of the field.
  //
  // If selectionEnabled is false, keeps the selection collapsed and moves it to
  // the start.
  //
  // The given [SelectionChangedCause] indicates the cause of this change and
  // will be passed to [setSelection].
  //
  // See also:
  //
  //   * _extendSelectionToEnd
  void _extendSelectionToStart(SelectionChangedCause cause) {
    if (!selectionEnabled) {
      return moveSelectionToStart(cause);
    }

    setSelection(textEditingValue.selection.extendTo(const TextPosition(
      offset: 0,
      affinity: TextAffinity.upstream,
    )), cause);
  }

  // Return the offset at the start of the nearest word to the left of the
  // given offset.
  int _getLeftByWord(int offset, [bool includeWhitespace = true]) {
    // If the offset is already all the way left, there is nothing to do.
    if (offset <= 0) {
      return offset;
    }

    // If we can just return the start of the text without checking for a word.
    if (offset == 1) {
      return 0;
    }

    final int startPoint = previousCharacter(
        offset, textEditingValue.text, includeWhitespace);
    final TextRange word =
        textLayoutMetrics.getWordBoundary(TextPosition(offset: startPoint, affinity: textEditingValue.selection.affinity));
    return word.start;
  }

  /// Return the offset at the end of the nearest word to the right of the given
  /// offset.
  int _getRightByWord(int offset, [bool includeWhitespace = true]) {
    // If the selection is already all the way right, there is nothing to do.
    if (offset == textEditingValue.text.length) {
      return offset;
    }

    // If we can just return the end of the text without checking for a word.
    if (offset == textEditingValue.text.length - 1 || offset == textEditingValue.text.length) {
      return textEditingValue.text.length;
    }

    final int startPoint = includeWhitespace ||
            !TextLayoutMetrics.isWhitespace(textEditingValue.text.codeUnitAt(offset))
        ? offset
        : nextCharacter(offset, textEditingValue.text, includeWhitespace);
    final TextRange nextWord =
        textLayoutMetrics.getWordBoundary(TextPosition(offset: startPoint, affinity: textEditingValue.selection.affinity));
    return nextWord.end;
  }

  // Deletes the current non-empty selection.
  //
  // If the selection is currently non-empty, this method deletes the selected
  // text. Otherwise this method does nothing.
  TextEditingValue _deleteNonEmptySelection() {
    assert(textEditingValue.selection.isValid);
    assert(!textEditingValue.selection.isCollapsed);

    final String textBefore = textEditingValue.selection.textBefore(textEditingValue.text);
    final String textAfter = textEditingValue.selection.textAfter(textEditingValue.text);
    final TextSelection newSelection = TextSelection.collapsed(
      offset: textEditingValue.selection.start,
      affinity: textEditingValue.selection.affinity,
    );
    final TextRange newComposingRange = !textEditingValue.composing.isValid || textEditingValue.composing.isCollapsed
      ? TextRange.empty
      : TextRange(
        start: textEditingValue.composing.start - (textEditingValue.composing.start - textEditingValue.selection.start).clamp(0, textEditingValue.selection.end - textEditingValue.selection.start),
        end: textEditingValue.composing.end - (textEditingValue.composing.end - textEditingValue.selection.start).clamp(0, textEditingValue.selection.end - textEditingValue.selection.start),
      );

    return TextEditingValue(
      text: textBefore + textAfter,
      selection: newSelection,
      composing: newComposingRange,
    );
  }

  /// Returns a new TextEditingValue representing a deletion from the current
  /// [selection] to the given index, inclusively.
  ///
  /// If the selection is not collapsed, deletes the selection regardless of the
  /// given index.
  ///
  /// The composing region, if any, will also be adjusted to remove the deleted
  /// characters.
  TextEditingValue _deleteTo(TextPosition position) {
    assert(textEditingValue.selection != null);

    if (!textEditingValue.selection.isValid) {
      return textEditingValue;
    }
    if (!textEditingValue.selection.isCollapsed) {
      return _deleteNonEmptySelection();
    }
    if (position.offset == textEditingValue.selection.extentOffset) {
      return textEditingValue;
    }

    final TextRange deletion = TextRange(
      start: math.min(position.offset, textEditingValue.selection.extentOffset),
      end: math.max(position.offset, textEditingValue.selection.extentOffset),
    );
    final String deleted = deletion.textInside(textEditingValue.text);
    if (deletion.textInside(textEditingValue.text).isEmpty) {
      return textEditingValue;
    }

    final int charactersDeletedBeforeComposingStart =
        (textEditingValue.composing.start - deletion.start).clamp(0, deleted.length);
    final int charactersDeletedBeforeComposingEnd =
        (textEditingValue.composing.end - deletion.start).clamp(0, deleted.length);
    final TextRange nextComposingRange = !textEditingValue.composing.isValid || textEditingValue.composing.isCollapsed
      ? TextRange.empty
      : TextRange(
        start: textEditingValue.composing.start - charactersDeletedBeforeComposingStart,
        end: textEditingValue.composing.end - charactersDeletedBeforeComposingEnd,
      );

    return TextEditingValue(
      text: deletion.textBefore(textEditingValue.text) + deletion.textAfter(textEditingValue.text),
      selection: TextSelection.collapsed(
        offset: deletion.start,
        affinity: position.affinity,
      ),
      composing: nextComposingRange,
    );
  }

  /// Deletes backwards from the current selection.
  ///
  /// If the selection is collapsed, deletes a single character before the
  /// cursor.
  ///
  /// If the selection is not collapsed, deletes the selection.
  ///
  /// If [readOnly] is true, does nothing.
  ///
  /// {@template flutter.widgets.TextEditingActionTarget.cause}
  /// The given [SelectionChangedCause] indicates the cause of this change and
  /// will be passed to [setSelection].
  /// {@endtemplate}
  ///
  /// See also:
  ///
  ///   * [deleteForward], which is same but in the opposite direction.
  void delete(SelectionChangedCause cause) {
    if (readOnly) {
      return;
    }

    // `delete` does not depend on the text layout, and the boundary analysis is
    // done using the `previousCharacter` method instead of ICU, we can keep
    // deleting without having to layout the text. For this reason, we can
    // directly delete the character before the caret in the controller.
    final String textBefore = textEditingValue.selection.textBefore(textEditingValue.text);
    final int characterBoundary = previousCharacter(
      textBefore.length,
      textBefore,
    );
    final TextPosition position = TextPosition(offset: characterBoundary);
    setTextEditingValue(_deleteTo(position), cause);
  }

  /// Deletes a word backwards from the current selection.
  ///
  /// If the selection is collapsed, deletes a word before the cursor.
  ///
  /// If the selection is not collapsed, deletes the selection.
  ///
  /// If [readOnly] is true, does nothing.
  ///
  /// If [obscureText] is true, it treats the whole text content as a single
  /// word.
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.cause}
  ///
  /// {@template flutter.widgets.TextEditingActionTarget.whiteSpace}
  /// By default, includeWhitespace is set to true, meaning that whitespace can
  /// be considered a word in itself.  If set to false, the selection will be
  /// extended past any whitespace and the first word following the whitespace.
  /// {@endtemplate}
  ///
  /// See also:
  ///
  ///   * [deleteForwardByWord], which is same but in the opposite direction.
  void deleteByWord(SelectionChangedCause cause,
      [bool includeWhitespace = true]) {
    if (readOnly) {
      return;
    }

    if (obscureText) {
      // When the text is obscured, the whole thing is treated as one big line.
      return deleteToStart(cause);
    }

    final String textBefore = textEditingValue.selection.textBefore(textEditingValue.text);
    final int characterBoundary =
        _getLeftByWord(textBefore.length, includeWhitespace);
    final TextEditingValue nextValue = _deleteTo(TextPosition(offset: characterBoundary));

    setTextEditingValue(nextValue, cause);
  }

  /// Deletes a line backwards from the current selection.
  ///
  /// If the selection is collapsed, deletes a line before the cursor.
  ///
  /// If the selection is not collapsed, deletes the selection.
  ///
  /// If [obscureText] is true, it treats the whole text content as
  /// a single word.
  ///
  /// If [readOnly] is true, does nothing.
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.cause}
  ///
  /// See also:
  ///
  ///   * [deleteForwardByLine], which is same but in the opposite direction.
  void deleteByLine(SelectionChangedCause cause) {
    if (readOnly) {
      return;
    }

    // When there is a line break, line delete shouldn't do anything
    final String textBefore = textEditingValue.selection.textBefore(textEditingValue.text);
    final bool isPreviousCharacterBreakLine =
        textBefore.codeUnitAt(textBefore.length - 1) == 0x0A;
    if (isPreviousCharacterBreakLine) {
      return;
    }

    // When the text is obscured, the whole thing is treated as one big line.
    if (obscureText) {
      return deleteToStart(cause);
    }

    final TextSelection line = textLayoutMetrics.getLineAtOffset(
      TextPosition(offset: textBefore.length - 1),
    );

    setTextEditingValue(_deleteTo(TextPosition(offset: line.start)), cause);
  }

  /// Deletes in the forward direction.
  ///
  /// If the selection is collapsed, deletes a single character after the
  /// cursor.
  ///
  /// If the selection is not collapsed, deletes the selection.
  ///
  /// If [readOnly] is true, does nothing.
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.cause}
  ///
  /// See also:
  ///
  ///   * [delete], which is the same but in the opposite direction.
  void deleteForward(SelectionChangedCause cause) {
    if (readOnly) {
      return;
    }

    final String textAfter = textEditingValue.selection.textAfter(textEditingValue.text);
    final int characterBoundary = nextCharacter(0, textAfter);
    setTextEditingValue(_deleteTo(TextPosition(offset: textEditingValue.selection.end + characterBoundary)), cause);
  }

  /// Deletes a word in the forward direction from the current selection.
  ///
  /// If the selection is collapsed, deletes a word after the cursor.
  ///
  /// If the selection is not collapsed, deletes the selection.
  ///
  /// If [readOnly] is true, does nothing.
  ///
  /// If [obscureText] is true, it treats the whole text content as
  /// a single word.
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.cause}
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.whiteSpace}
  ///
  /// See also:
  ///
  ///   * [deleteByWord], which is same but in the opposite direction.
  void deleteForwardByWord(SelectionChangedCause cause,
      [bool includeWhitespace = true]) {
    if (readOnly) {
      return;
    }

    if (obscureText) {
      // When the text is obscured, the whole thing is treated as one big word.
      return deleteToEnd(cause);
    }

    final String textBefore = textEditingValue.selection.textBefore(textEditingValue.text);
    final int characterBoundary = _getRightByWord(textBefore.length, includeWhitespace);
    final TextEditingValue nextValue = _deleteTo(TextPosition(offset: characterBoundary));

    setTextEditingValue(nextValue, cause);
  }

  /// Deletes a line in the forward direction from the current selection.
  ///
  /// If the selection is collapsed, deletes a line after the cursor.
  ///
  /// If the selection is not collapsed, deletes the selection.
  ///
  /// If [readOnly] is true, does nothing.
  ///
  /// If [obscureText] is true, it treats the whole text content as
  /// a single word.
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.cause}
  ///
  /// See also:
  ///
  ///   * [deleteByLine], which is same but in the opposite direction.
  void deleteForwardByLine(SelectionChangedCause cause) {
    if (readOnly) {
      return;
    }

    if (obscureText) {
      // When the text is obscured, the whole thing is treated as one big line.
      return deleteToEnd(cause);
    }


    // When there is a line break, it shouldn't do anything.
    final String textAfter = textEditingValue.selection.textAfter(textEditingValue.text);
    final bool isNextCharacterBreakLine = textAfter.codeUnitAt(0) == 0x0A;
    if (isNextCharacterBreakLine) {
      return;
    }

    final String textBefore = textEditingValue.selection.textBefore(textEditingValue.text);
    final TextSelection line = textLayoutMetrics.getLineAtOffset(
      TextPosition(offset: textBefore.length),
    );

    setTextEditingValue(_deleteTo(TextPosition(offset: line.end)), cause);
  }

  /// Deletes the from the current collapsed selection to the end of the field.
  ///
  /// The given SelectionChangedCause indicates the cause of this change and
  /// will be passed to setSelection.
  ///
  /// See also:
  ///   * [deleteToStart]
  void deleteToEnd(SelectionChangedCause cause) {
    assert(textEditingValue.selection.isCollapsed);

    setTextEditingValue(_deleteTo(TextPosition(offset: textEditingValue.text.length)), cause);
  }

  /// Deletes the from the current collapsed selection to the start of the field.
  ///
  /// The given SelectionChangedCause indicates the cause of this change and
  /// will be passed to setSelection.
  ///
  /// See also:
  ///   * [deleteToEnd]
  void deleteToStart(SelectionChangedCause cause) {
    assert(textEditingValue.selection.isCollapsed);

    setTextEditingValue(_deleteTo(const TextPosition(offset: 0)), cause);
  }

  /// Expand the current selection to the end of the field.
  ///
  /// The selection will never shrink. The [TextSelection.extentOffset] will
  // always be at the end of the field, regardless of the original order of
  /// [TextSelection.baseOffset] and [TextSelection.extentOffset].
  ///
  /// If [selectionEnabled] is false, keeps the selection collapsed and moves it
  /// to the end.
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.cause}
  ///
  /// See also:
  ///
  ///   * [expandSelectionToStart], which is same but in the opposite direction.
  void expandSelectionToEnd(SelectionChangedCause cause) {
    if (!selectionEnabled) {
      return moveSelectionToEnd(cause);
    }

    final TextPosition nextPosition = TextPosition(
      offset: textEditingValue.text.length,
      affinity: TextAffinity.downstream,
    );
    setSelection(textEditingValue.selection.expandTo(nextPosition, true), cause);
  }

  /// Expand the current selection to the start of the field.
  ///
  /// The selection will never shrink. The [TextSelection.extentOffset] will
  /// always be at the start of the field, regardless of the original order of
  /// [TextSelection.baseOffset] and [TextSelection.extentOffset].
  ///
  /// If [selectionEnabled] is false, keeps the selection collapsed and moves it
  /// to the start.
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.cause}
  ///
  /// See also:
  ///
  ///   * [expandSelectionToEnd], which is the same but in the opposite
  ///     direction.
  void expandSelectionToStart(SelectionChangedCause cause) {
    if (!selectionEnabled) {
      return moveSelectionToStart(cause);
    }

    const TextPosition nextPosition = TextPosition(
      offset: 0,
      affinity: TextAffinity.upstream,
    );
    setSelection(textEditingValue.selection.expandTo(nextPosition, true), cause);
  }

  /// Expand the current selection to the smallest selection that includes the
  /// start of the line.
  ///
  /// The selection will never shrink. The upper offset will be expanded to the
  /// beginning of its line, and the original order of baseOffset and
  /// [TextSelection.extentOffset] will be preserved.
  ///
  /// If [selectionEnabled] is false, keeps the selection collapsed and moves it
  /// left by line.
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.cause}
  ///
  /// See also:
  ///
  ///   * [expandSelectionRightByLine], which is the same but in the opposite
  ///     direction.
  void expandSelectionLeftByLine(SelectionChangedCause cause) {
    if (!selectionEnabled) {
      return moveSelectionLeftByLine(cause);
    }

    // If the lowest edge of the selection is at the start of a line, don't do
    // anything.
    // TODO(justinmc): Support selection with multiple TextAffinities.
    // https://github.com/flutter/flutter/issues/88135
    final TextSelection currentLine = textLayoutMetrics.getLineAtOffset(
      TextPosition(
        offset: textEditingValue.selection.start,
        affinity: textEditingValue.selection.isCollapsed
            ? textEditingValue.selection.affinity
            : TextAffinity.downstream,
      ),
    );
    if (currentLine.baseOffset == textEditingValue.selection.start) {
      return;
    }

    setSelection(textEditingValue.selection.expandTo(TextPosition(
      offset: currentLine.baseOffset,
      affinity: textEditingValue.selection.affinity,
    )), cause);
  }

  /// Expand the current selection to the smallest selection that includes the
  /// end of the line.
  ///
  /// The selection will never shrink. The lower offset will be expanded to the
  /// end of its line and the original order of [TextSelection.baseOffset] and
  /// [TextSelection.extentOffset] will be preserved.
  ///
  /// If [selectionEnabled] is false, keeps the selection collapsed and moves it
  /// right by line.
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.cause}
  ///
  /// See also:
  ///
  ///   * [expandSelectionLeftByLine], which is the same but in the opposite
  ///     direction.
  void expandSelectionRightByLine(SelectionChangedCause cause) {
    if (!selectionEnabled) {
      return moveSelectionRightByLine(cause);
    }

    // If greatest edge is already at the end of a line, don't do anything.
    // TODO(justinmc): Support selection with multiple TextAffinities.
    // https://github.com/flutter/flutter/issues/88135
    final TextSelection currentLine = textLayoutMetrics.getLineAtOffset(
      TextPosition(
        offset: textEditingValue.selection.end,
        affinity: textEditingValue.selection.isCollapsed
            ? textEditingValue.selection.affinity
            : TextAffinity.upstream,
      ),
    );
    if (currentLine.extentOffset == textEditingValue.selection.end) {
      return;
    }

    final TextSelection nextSelection = textEditingValue.selection.expandTo(
      TextPosition(
        offset: currentLine.extentOffset,
        affinity: TextAffinity.upstream,
      ),
    );
    setSelection(nextSelection, cause);
  }

  /// Keeping selection's [TextSelection.baseOffset] fixed, move the
  /// [TextSelection.extentOffset] down by one line.
  ///
  /// If selectionEnabled is false, keeps the selection collapsed and just
  /// moves it down.
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.cause}
  ///
  /// See also:
  ///
  ///   * [extendSelectionUp], which is same but in the opposite direction.
  void extendSelectionDown(SelectionChangedCause cause) {
    if (!selectionEnabled) {
      return moveSelectionDown(cause);
    }

    // If the selection is collapsed at the end of the field already, then
    // nothing happens.
    if (textEditingValue.selection.isCollapsed &&
        textEditingValue.selection.extentOffset >= textEditingValue.text.length) {
      return;
    }

    int index =
        textLayoutMetrics.getTextPositionBelow(textEditingValue.selection.extent).offset;

    if (index == textEditingValue.selection.extentOffset) {
      index = textEditingValue.text.length;
      _wasSelectingVerticallyWithKeyboard = true;
    } else if (_wasSelectingVerticallyWithKeyboard) {
      index = _cursorResetLocation;
      _wasSelectingVerticallyWithKeyboard = false;
    } else {
      _cursorResetLocation = index;
    }

    final TextPosition nextPosition = TextPosition(
      offset: index,
      affinity: textEditingValue.selection.affinity,
    );
    setSelection(textEditingValue.selection.extendTo(nextPosition), cause);
  }

  /// If [selectionEnabled] is false, keeps the selection collapsed and moves it
  /// left.
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.cause}
  ///
  /// See also:
  ///
  ///   * [extendSelectionRight], which is same but in the opposite direction.
  void extendSelectionLeft(SelectionChangedCause cause) {
    if (!selectionEnabled) {
      return moveSelectionLeft(cause);
    }

    // If the selection is already all the way left, there is nothing to do.
    if (textEditingValue.selection.extentOffset <= 0) {
      return;
    }

    final int previousExtent = previousCharacter(
      textEditingValue.selection.extentOffset,
      textEditingValue.text,
    );

    final int distance = textEditingValue.selection.extentOffset - previousExtent;
    _cursorResetLocation -= distance;
    setSelection(textEditingValue.selection.extendTo(TextPosition(offset: previousExtent, affinity: textEditingValue.selection.affinity)), cause);
  }

  /// Extend the current selection to the start of
  /// [TextSelection.extentOffset]'s line.
  ///
  /// Uses [TextSelection.baseOffset] as a pivot point and doesn't change it.
  /// If [TextSelection.extentOffset] is right of [TextSelection.baseOffset],
  /// then the selection will be collapsed.
  ///
  /// If [selectionEnabled] is false, keeps the selection collapsed and moves it
  /// left by line.
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.cause}
  ///
  /// See also:
  ///
  ///   * [extendSelectionRightByLine], which is same but in the opposite
  ///     direction.
  ///   * [expandSelectionRightByLine], which strictly grows the selection
  ///     regardless of the order.
  void extendSelectionLeftByLine(SelectionChangedCause cause) {
    if (!selectionEnabled) {
      return moveSelectionLeftByLine(cause);
    }

    // When going left, we want to skip over any whitespace before the line,
    // so we go back to the first non-whitespace before asking for the line
    // bounds, since getLineAtOffset finds the line boundaries without
    // including whitespace (like the newline).
    final int startPoint = previousCharacter(
        textEditingValue.selection.extentOffset, textEditingValue.text, false);
    final TextSelection selectedLine = textLayoutMetrics.getLineAtOffset(
      TextPosition(offset: startPoint),
    );

    late final TextSelection nextSelection;
    // If the extent and base offsets would reverse order, then instead the
    // selection collapses.
    if (textEditingValue.selection.extentOffset > textEditingValue.selection.baseOffset) {
      nextSelection = textEditingValue.selection.copyWith(
        extentOffset: textEditingValue.selection.baseOffset,
      );
    } else {
      nextSelection = textEditingValue.selection.extendTo(TextPosition(
        offset: selectedLine.baseOffset,
        affinity: TextAffinity.downstream,
      ));
    }

    setSelection(nextSelection, cause);
  }

  /// Keeping selection's [TextSelection.baseOffset] fixed, move the
  /// [TextSelection.extentOffset] right.
  ///
  /// If [selectionEnabled] is false, keeps the selection collapsed and moves it
  /// right.
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.cause}
  ///
  /// See also:
  ///
  ///   * [extendSelectionLeft], which is same but in the opposite direction.
  void extendSelectionRight(SelectionChangedCause cause) {
    if (!selectionEnabled) {
      return moveSelectionRight(cause);
    }

    // If the selection is already all the way right, there is nothing to do.
    if (textEditingValue.selection.extentOffset >= textEditingValue.text.length) {
      return;
    }
    final int nextExtent = nextCharacter(
        textEditingValue.selection.extentOffset, textEditingValue.text);

    final int distance = nextExtent - textEditingValue.selection.extentOffset;
    _cursorResetLocation += distance;
    setSelection(textEditingValue.selection.extendTo(TextPosition(offset: nextExtent, affinity: textEditingValue.selection.affinity)), cause);
  }

  /// Extend the current selection to the end of [TextSelection.extentOffset]'s
  /// line.
  ///
  /// Uses [TextSelection.baseOffset] as a pivot point and doesn't change it. If
  /// [TextSelection.extentOffset] is left of [TextSelection.baseOffset], then
  /// collapses the selection.
  ///
  /// If [selectionEnabled] is false, keeps the selection collapsed and moves it
  /// right by line.
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.cause}
  ///
  /// See also:
  ///
  ///   * [extendSelectionLeftByLine], which is same but in the opposite
  ///     direction.
  ///   * [expandSelectionRightByLine], which strictly grows the selection
  ///     regardless of the order.
  void extendSelectionRightByLine(SelectionChangedCause cause) {
    if (!selectionEnabled) {
      return moveSelectionRightByLine(cause);
    }

    final int startPoint = nextCharacter(
        textEditingValue.selection.extentOffset, textEditingValue.text, false);
    final TextSelection selectedLine = textLayoutMetrics.getLineAtOffset(
      TextPosition(offset: startPoint),
    );

    // If the extent and base offsets would reverse order, then instead the
    // selection collapses.
    late final TextSelection nextSelection;
    if (textEditingValue.selection.extentOffset < textEditingValue.selection.baseOffset) {
      nextSelection = textEditingValue.selection.copyWith(
        extentOffset: textEditingValue.selection.baseOffset,
      );
    } else {
      nextSelection = textEditingValue.selection.extendTo(TextPosition(
        offset: selectedLine.extentOffset,
        affinity: TextAffinity.upstream,
      ));
    }

    setSelection(nextSelection, cause);
  }

  /// Extend the current selection to the previous start of a word.
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.cause}
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.whiteSpace}
  ///
  /// {@template flutter.widgets.TextEditingActionTarget.stopAtReversal}
  /// The `stopAtReversal` parameter is false by default, meaning that it's
  /// ok for the base and extent to flip their order here. If set to true, then
  /// the selection will collapse when it would otherwise reverse its order. A
  /// selection that is already collapsed is not affected by this parameter.
  /// {@endtemplate}
  ///
  /// See also:
  ///
  ///   * [extendSelectionRightByWord], which is the same but in the opposite
  ///     direction.
  void extendSelectionLeftByWord(SelectionChangedCause cause,
      [bool includeWhitespace = true, bool stopAtReversal = false]) {
    // When the text is obscured, the whole thing is treated as one big word.
    if (obscureText) {
      return _extendSelectionToStart(cause);
    }

    debugAssertLayoutUpToDate();
    // If the selection is already all the way left, there is nothing to do.
    if (textEditingValue.selection.isCollapsed && textEditingValue.selection.extentOffset <= 0) {
      return;
    }

    final int leftOffset =
        _getLeftByWord(textEditingValue.selection.extentOffset, includeWhitespace);

    late final TextSelection nextSelection;
    if (stopAtReversal &&
        textEditingValue.selection.extentOffset > textEditingValue.selection.baseOffset &&
        leftOffset < textEditingValue.selection.baseOffset) {
      nextSelection = textEditingValue.selection.extendTo(TextPosition(offset: textEditingValue.selection.baseOffset));
    } else {
      nextSelection = textEditingValue.selection.extendTo(TextPosition(offset: leftOffset, affinity: textEditingValue.selection.affinity));
    }

    if (nextSelection == textEditingValue.selection) {
      return;
    }
    setSelection(nextSelection, cause);
  }

  /// Extend the current selection to the next end of a word.
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.cause}
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.whiteSpace}
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.stopAtReversal}
  ///
  /// See also:
  ///
  ///   * [extendSelectionLeftByWord], which is the same but in the opposite
  ///     direction.
  void extendSelectionRightByWord(SelectionChangedCause cause,
      [bool includeWhitespace = true, bool stopAtReversal = false]) {
    debugAssertLayoutUpToDate();
    // When the text is obscured, the whole thing is treated as one big word.
    if (obscureText) {
      return _extendSelectionToEnd(cause);
    }

    // If the selection is already all the way right, there is nothing to do.
    if (textEditingValue.selection.isCollapsed &&
        textEditingValue.selection.extentOffset == textEditingValue.text.length) {
      return;
    }

    final int rightOffset =
        _getRightByWord(textEditingValue.selection.extentOffset, includeWhitespace);

    late final TextSelection nextSelection;
    if (stopAtReversal &&
        textEditingValue.selection.baseOffset > textEditingValue.selection.extentOffset &&
        rightOffset > textEditingValue.selection.baseOffset) {
      nextSelection = TextSelection.fromPosition(
        TextPosition(offset: textEditingValue.selection.baseOffset),
      );
    } else {
      nextSelection = textEditingValue.selection.extendTo(TextPosition(offset: rightOffset, affinity: textEditingValue.selection.affinity));
    }

    if (nextSelection == textEditingValue.selection) {
      return;
    }
    setSelection(nextSelection, cause);
  }

  /// Keeping selection's [TextSelection.baseOffset] fixed, move the
  /// [TextSelection.extentOffset] up by one
  /// line.
  ///
  /// If [selectionEnabled] is false, keeps the selection collapsed and moves it
  /// up.
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.cause}
  ///
  /// See also:
  ///
  ///   * [extendSelectionDown], which is the same but in the opposite
  ///     direction.
  void extendSelectionUp(SelectionChangedCause cause) {
    if (!selectionEnabled) {
      return moveSelectionUp(cause);
    }

    // If the selection is collapsed at the beginning of the field already, then
    // nothing happens.
    if (textEditingValue.selection.isCollapsed && textEditingValue.selection.extentOffset <= 0.0) {
      return;
    }

    final TextPosition positionAbove =
        textLayoutMetrics.getTextPositionAbove(textEditingValue.selection.extent);
    late final TextSelection nextSelection;
    if (positionAbove.offset == textEditingValue.selection.extentOffset) {
      nextSelection = textEditingValue.selection.copyWith(
        extentOffset: 0,
        affinity: TextAffinity.upstream,
      );
      _wasSelectingVerticallyWithKeyboard = true;
    } else if (_wasSelectingVerticallyWithKeyboard) {
      nextSelection = textEditingValue.selection.copyWith(
        baseOffset: textEditingValue.selection.baseOffset,
        extentOffset: _cursorResetLocation,
      );
      _wasSelectingVerticallyWithKeyboard = false;
    } else {
      nextSelection = textEditingValue.selection.copyWith(
        baseOffset: textEditingValue.selection.baseOffset,
        extentOffset: positionAbove.offset,
        affinity: positionAbove.affinity,
      );
      _cursorResetLocation = nextSelection.extentOffset;
    }

    setSelection(nextSelection, cause);
  }

  /// Move the current selection to the leftmost point of the current line.
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.cause}
  ///
  /// See also:
  ///
  ///   * [moveSelectionRightByLine], which is the same but in the opposite
  ///     direction.
  void moveSelectionLeftByLine(SelectionChangedCause cause) {
    // If already at the left edge of the line, do nothing.
    final TextSelection currentLine = textLayoutMetrics.getLineAtOffset(
      textEditingValue.selection.extent,
    );
    if (currentLine.baseOffset == textEditingValue.selection.extentOffset) {
      return;
    }

    // When going left, we want to skip over any whitespace before the line,
    // so we go back to the first non-whitespace before asking for the line
    // bounds, since getLineAtOffset finds the line boundaries without
    // including whitespace (like the newline).
    final int startPoint = previousCharacter(
        textEditingValue.selection.extentOffset, textEditingValue.text, false);
    final TextSelection selectedLine = textLayoutMetrics.getLineAtOffset(
      TextPosition(offset: startPoint),
    );
    final TextSelection nextSelection = TextSelection.fromPosition(TextPosition(
      offset: selectedLine.baseOffset,
      affinity: TextAffinity.downstream,
    ));

    setSelection(nextSelection, cause);
  }

  /// Move the current selection to the next line.
  ///
  /// Move the current selection to the next line.
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.cause}
  ///
  /// See also:
  ///
  ///   * [moveSelectionUp], which is the same but in the opposite direction.
  void moveSelectionDown(SelectionChangedCause cause) {
    // If the selection is collapsed at the end of the field already, then
    // nothing happens.
    if (textEditingValue.selection.isCollapsed &&
        textEditingValue.selection.extentOffset >= textEditingValue.text.length) {
      return;
    }

    final TextPosition positionBelow =
        textLayoutMetrics.getTextPositionBelow(textEditingValue.selection.extent);

    late final TextSelection nextSelection;
    if (positionBelow.offset == textEditingValue.selection.extentOffset) {
      nextSelection = textEditingValue.selection.copyWith(
        baseOffset: textEditingValue.text.length,
        extentOffset: textEditingValue.text.length,
      );
    } else {
      nextSelection = TextSelection.fromPosition(positionBelow);
    }

    if (textEditingValue.selection.extentOffset == textEditingValue.text.length) {
      _wasSelectingVerticallyWithKeyboard = false;
    } else {
      _cursorResetLocation = nextSelection.extentOffset;
    }

    setSelection(nextSelection, cause);
  }

  /// Move the current selection left by one character.
  ///
  /// If it can't be moved left, do nothing.
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.cause}
  ///
  /// See also:
  ///
  ///   * [moveSelectionRight], which is the same but in the opposite direction.
  void moveSelectionLeft(SelectionChangedCause cause) {
    // If the selection is already all the way left, there is nothing to do.
    if (textEditingValue.selection.isCollapsed && textEditingValue.selection.extentOffset <= 0) {
      return;
    }

    int previousExtent;
    if (textEditingValue.selection.start != textEditingValue.selection.end) {
      previousExtent = textEditingValue.selection.start;
    } else {
      previousExtent = previousCharacter(
          textEditingValue.selection.extentOffset, textEditingValue.text);
    }
    final TextSelection nextSelection = TextSelection.fromPosition(
      TextPosition(
        offset: previousExtent,
        affinity: textEditingValue.selection.affinity,
      ),
    );

    if (nextSelection == textEditingValue.selection) {
      return;
    }
    _cursorResetLocation -=
        textEditingValue.selection.extentOffset - nextSelection.extentOffset;
    setSelection(nextSelection, cause);
  }

  /// Move the current selection to the previous start of a word.
  ///
  /// A TextSelection that isn't collapsed will be collapsed and moved from the
  /// extentOffset.
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.cause}
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.whiteSpace}
  ///
  /// See also:
  ///
  ///   * [moveSelectionRightByWord], which is the same but in the opposite
  ///     direction.
  void moveSelectionLeftByWord(SelectionChangedCause cause,
      [bool includeWhitespace = true]) {
    // When the text is obscured, the whole thing is treated as one big word.
    if (obscureText) {
      return moveSelectionToStart(cause);
    }

    debugAssertLayoutUpToDate();
    // If the selection is already all the way left, there is nothing to do.
    if (textEditingValue.selection.isCollapsed && textEditingValue.selection.extentOffset <= 0) {
      return;
    }

    final int leftOffset =
        _getLeftByWord(textEditingValue.selection.extentOffset, includeWhitespace);
    final TextSelection nextSelection = TextSelection.fromPosition(TextPosition(offset: leftOffset, affinity: textEditingValue.selection.affinity));

    if (nextSelection == textEditingValue.selection) {
      return;
    }
    setSelection(nextSelection, cause);
  }

  /// Move the current selection to the right by one character.
  ///
  /// If it can't be moved right, do nothing.
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.cause}
  ///
  /// See also:
  ///
  ///   * [moveSelectionLeft], which is the same but in the opposite direction.
  void moveSelectionRight(SelectionChangedCause cause) {
    // If the selection is already all the way right, there is nothing to do.
    if (textEditingValue.selection.isCollapsed &&
        textEditingValue.selection.extentOffset >= textEditingValue.text.length) {
      return;
    }

    int nextExtent;
    if (textEditingValue.selection.start != textEditingValue.selection.end) {
      nextExtent = textEditingValue.selection.end;
    } else {
      nextExtent = nextCharacter(
          textEditingValue.selection.extentOffset, textEditingValue.text);
    }
    final TextSelection nextSelection = TextSelection.fromPosition(TextPosition(
      offset: nextExtent,
    ));

    if (nextSelection == textEditingValue.selection) {
      return;
    }
    setSelection(nextSelection, cause);
  }

  /// Move the current selection to the rightmost point of the current line.
  ///
  /// Move the current selection to the rightmost point of the current line.
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.cause}
  ///
  /// See also:
  ///
  ///   * [moveSelectionLeftByLine], which is the same but in the opposite
  ///     direction.
  void moveSelectionRightByLine(SelectionChangedCause cause) {
    // If already at the right edge of the line, do nothing.
    final TextSelection currentLine = textLayoutMetrics.getLineAtOffset(
      textEditingValue.selection.extent,
    );
    if (currentLine.extentOffset == textEditingValue.selection.extentOffset) {
      return;
    }

    // When going right, we want to skip over any whitespace after the line,
    // so we go forward to the first non-whitespace character before asking
    // for the line bounds, since getLineAtOffset finds the line
    // boundaries without including whitespace (like the newline).
    final int startPoint = nextCharacter(
        textEditingValue.selection.extentOffset, textEditingValue.text, false);
    final TextSelection selectedLine = textLayoutMetrics.getLineAtOffset(
      TextPosition(
        offset: startPoint,
        affinity: TextAffinity.upstream,
      ),
    );
    final TextSelection nextSelection = TextSelection.fromPosition(TextPosition(
      offset: selectedLine.extentOffset,
      affinity: TextAffinity.upstream,
    ));
    setSelection(nextSelection, cause);
  }

  /// Move the current selection to the next end of a word.
  ///
  /// A TextSelection that isn't collapsed will be collapsed and moved from the
  /// extentOffset.
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.cause}
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.whiteSpace}
  ///
  /// See also:
  ///
  ///   * [moveSelectionLeftByWord], which is the same but in the opposite
  ///     direction.
  void moveSelectionRightByWord(SelectionChangedCause cause,
      [bool includeWhitespace = true]) {
    // When the text is obscured, the whole thing is treated as one big word.
    if (obscureText) {
      return moveSelectionToEnd(cause);
    }

    debugAssertLayoutUpToDate();
    // If the selection is already all the way right, there is nothing to do.
    if (textEditingValue.selection.isCollapsed &&
        textEditingValue.selection.extentOffset == textEditingValue.text.length) {
      return;
    }

    final int rightOffset =
        _getRightByWord(textEditingValue.selection.extentOffset, includeWhitespace);
    final TextSelection nextSelection = TextSelection.fromPosition(TextPosition(offset: rightOffset, affinity: textEditingValue.selection.affinity));

    if (nextSelection == textEditingValue.selection) {
      return;
    }
    setSelection(nextSelection, cause);
  }

  /// Move the current selection to the end of the field.
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.cause}
  ///
  /// See also:
  ///
  ///   * [moveSelectionToStart], which is the same but in the opposite
  ///     direction.
  void moveSelectionToEnd(SelectionChangedCause cause) {
    final TextPosition nextPosition = TextPosition(
      offset: textEditingValue.text.length,
      affinity: TextAffinity.downstream,
    );
    setSelection(TextSelection.fromPosition(nextPosition), cause);
  }

  /// Move the current selection to the start of the field.
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.cause}
  ///
  /// See also:
  ///
  ///   * [moveSelectionToEnd], which is the same but in the opposite direction.
  void moveSelectionToStart(SelectionChangedCause cause) {
    const TextPosition nextPosition = TextPosition(
      offset: 0,
      affinity: TextAffinity.upstream,
    );
    setSelection(TextSelection.fromPosition(nextPosition), cause);
  }

  /// Move the current selection up by one line.
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.cause}
  ///
  /// See also:
  ///
  ///   * [moveSelectionDown], which is the same but in the opposite direction.
  void moveSelectionUp(SelectionChangedCause cause) {
    final int nextIndex =
        textLayoutMetrics.getTextPositionAbove(textEditingValue.selection.extent).offset;

    if (nextIndex == textEditingValue.selection.extentOffset) {
      _wasSelectingVerticallyWithKeyboard = false;
      return moveSelectionToStart(cause);
    }
    _cursorResetLocation = nextIndex;

    setSelection(TextSelection.fromPosition(TextPosition(offset: nextIndex, affinity: textEditingValue.selection.affinity)), cause);
  }

  /// Select the entire text value.
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.cause}
  void selectAll(SelectionChangedCause cause) {
    setSelection(
      textEditingValue.selection.copyWith(
        baseOffset: 0,
        extentOffset: textEditingValue.text.length,
      ),
      cause,
    );
  }

  /// {@template flutter.widgets.TextEditingActionTarget.copySelection}
  /// Copy current selection to [Clipboard].
  /// {@endtemplate}
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.cause}
  void copySelection(SelectionChangedCause cause) {
    final TextSelection selection = textEditingValue.selection;
    final String text = textEditingValue.text;
    assert(selection != null);
    if (selection.isCollapsed) {
      return;
    }
    Clipboard.setData(ClipboardData(text: selection.textInside(text)));
  }

  /// {@template flutter.widgets.TextEditingActionTarget.cutSelection}
  /// Cut current selection to Clipboard.
  /// {@endtemplate}
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.cause}
  void cutSelection(SelectionChangedCause cause) {
    if (readOnly) {
      return;
    }
    final TextSelection selection = textEditingValue.selection;
    final String text = textEditingValue.text;
    assert(selection != null);
    if (selection.isCollapsed) {
      return;
    }
    Clipboard.setData(ClipboardData(text: selection.textInside(text)));
    setTextEditingValue(
      TextEditingValue(
        text: selection.textBefore(text) + selection.textAfter(text),
        selection: TextSelection.collapsed(
          offset: math.min(selection.start, selection.end),
          affinity: selection.affinity,
        ),
      ),
      cause,
    );
  }

  /// {@template flutter.widgets.TextEditingActionTarget.pasteText}
  /// Paste text from [Clipboard].
  /// {@endtemplate}
  ///
  /// If there is currently a selection, it will be replaced.
  ///
  /// {@macro flutter.widgets.TextEditingActionTarget.cause}
  Future<void> pasteText(SelectionChangedCause cause) async {
    if (readOnly) {
      return;
    }
    final TextSelection selection = textEditingValue.selection;
    final String text = textEditingValue.text;
    assert(selection != null);
    if (!selection.isValid) {
      return;
    }
    // Snapshot the input before using `await`.
    // See https://github.com/flutter/flutter/issues/11427
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null) {
      return;
    }
    setTextEditingValue(
      TextEditingValue(
        text: selection.textBefore(text) +
            data.text! +
            selection.textAfter(text),
        selection: TextSelection.collapsed(
          offset:
              math.min(selection.start, selection.end) + data.text!.length,
          affinity: selection.affinity,
        ),
      ),
      cause,
    );
  }
}
