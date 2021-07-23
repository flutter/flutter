// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show
  TextAffinity,
  hashValues;

import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';

import 'text_editing.dart';
import 'text_metrics.dart';

TextAffinity? _toTextAffinity(String? affinity) {
  switch (affinity) {
    case 'TextAffinity.downstream':
      return TextAffinity.downstream;
    case 'TextAffinity.upstream':
      return TextAffinity.upstream;
  }
  return null;
}
/// The current text, selection, and composing state for editing a run of text.
@immutable
class TextEditingValue {
  /// Creates information for editing a run of text.
  ///
  /// The selection and composing range must be within the text.
  ///
  /// The [text], [selection], and [composing] arguments must not be null but
  /// each have default values.
  const TextEditingValue({
    this.text = '',
    this.selection = const TextSelection.collapsed(offset: -1),
    this.composing = TextRange.empty,
  }) : assert(text != null),
       assert(selection != null),
       assert(composing != null);

  /// Creates an instance of this class from a JSON object.
  factory TextEditingValue.fromJSON(Map<String, dynamic> encoded) {
    return TextEditingValue(
      text: encoded['text'] as String,
      selection: TextSelection(
        baseOffset: encoded['selectionBase'] as int? ?? -1,
        extentOffset: encoded['selectionExtent'] as int? ?? -1,
        affinity: _toTextAffinity(encoded['selectionAffinity'] as String?) ?? TextAffinity.downstream,
        isDirectional: encoded['selectionIsDirectional'] as bool? ?? false,
      ),
      composing: TextRange(
        start: encoded['composingBase'] as int? ?? -1,
        end: encoded['composingExtent'] as int? ?? -1,
      ),
    );
  }

  /// The current text being edited.
  final String text;

  /// The range of text that is currently selected.
  final TextSelection selection;

  /// The range of text that is still being composed.
  final TextRange composing;

  /// A value that corresponds to the empty string with no selection and no composing range.
  static const TextEditingValue empty = TextEditingValue();

  /// Return the given [TextSelection] with its [TextSelection.extentOffset]
  /// moved left by one character.
  ///
  /// {@macro flutter.rendering.RenderEditable.whiteSpace}
  static TextSelection extendGivenSelectionLeft(TextSelection selection, String text, [bool includeWhitespace = true]) {
    // If the selection is already all the way left, there is nothing to do.
    if (selection.extentOffset <= 0) {
      return selection;
    }
    final int previousExtent = previousCharacter(selection.extentOffset, text, includeWhitespace);
    return selection.copyWith(extentOffset: previousExtent);
  }

  // TODO(gspencergoog): replace when we expose this ICU information.
  /// Check if the given code unit is a white space or separator
  /// character.
  ///
  /// Includes newline characters from ASCII and separators from the
  /// [unicode separator category](https://www.compart.com/en/unicode/category/Zs)
  static bool isWhitespace(int codeUnit) {
    switch (codeUnit) {
      case 0x9: // horizontal tab
      case 0xA: // line feed
      case 0xB: // vertical tab
      case 0xC: // form feed
      case 0xD: // carriage return
      case 0x1C: // file separator
      case 0x1D: // group separator
      case 0x1E: // record separator
      case 0x1F: // unit separator
      case 0x20: // space
      case 0xA0: // no-break space
      case 0x1680: // ogham space mark
      case 0x2000: // en quad
      case 0x2001: // em quad
      case 0x2002: // en space
      case 0x2003: // em space
      case 0x2004: // three-per-em space
      case 0x2005: // four-er-em space
      case 0x2006: // six-per-em space
      case 0x2007: // figure space
      case 0x2008: // punctuation space
      case 0x2009: // thin space
      case 0x200A: // hair space
      case 0x202F: // narrow no-break space
      case 0x205F: // medium mathematical space
      case 0x3000: // ideographic space
        break;
      default:
        return false;
    }
    return true;
  }

  /// Return a new selection that has been moved left once.
  ///
  /// If it can't be moved left, the original TextSelection is returned.
  static TextSelection moveGivenSelectionLeft(TextSelection selection, String text) {
    // If the selection is already all the way left, there is nothing to do.
    if (selection.isCollapsed && selection.extentOffset <= 0) {
      return selection;
    }

    int previousExtent;
    if (selection.start != selection.end) {
      previousExtent = selection.start;
    } else {
      previousExtent = previousCharacter(selection.extentOffset, text);
    }
    final TextSelection newSelection = selection.copyWith(
      extentOffset: previousExtent,
    );

    final int newOffset = newSelection.extentOffset;
    return TextSelection.fromPosition(TextPosition(offset: newOffset));
  }

  /// Return a new selection that has been moved right once.
  ///
  /// If it can't be moved right, the original TextSelection is returned.
  static TextSelection moveGivenSelectionRight(TextSelection selection, String text) {
    // If the selection is already all the way right, there is nothing to do.
    if (selection.isCollapsed && selection.extentOffset >= text.length) {
      return selection;
    }

    int nextExtent;
    if (selection.start != selection.end) {
      nextExtent = selection.end;
    } else {
      nextExtent = nextCharacter(selection.extentOffset, text);
    }
    final TextSelection nextSelection = selection.copyWith(extentOffset: nextExtent);

    int newOffset = nextSelection.extentOffset;
    newOffset = nextSelection.baseOffset > nextSelection.extentOffset
        ? nextSelection.baseOffset : nextSelection.extentOffset;
    return TextSelection.fromPosition(TextPosition(offset: newOffset));
  }

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
  static int nextCharacter(int index, String string, [bool includeWhitespace = true]) {
    assert(index >= 0 && index <= string.length);
    if (index == string.length) {
      return string.length;
    }

    int count = 0;
    final Characters remaining = string.characters.skipWhile((String currentString) {
      if (count <= index) {
        count += currentString.length;
        return true;
      }
      if (includeWhitespace) {
        return false;
      }
      return isWhitespace(currentString.codeUnitAt(0));
    });
    return string.length - remaining.toString().length;
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
  ///
  /// {@macro flutter.rendering.RenderEditable.stopAtReversal}
  static int previousCharacter(int index, String string, [bool includeWhitespace = true]) {
    assert(index >= 0 && index <= string.length);
    if (index == 0) {
      return 0;
    }

    int count = 0;
    int? lastNonWhitespace;
    for (final String currentString in string.characters) {
      if (!includeWhitespace &&
          !isWhitespace(currentString.characters.first.codeUnitAt(0))) {
        lastNonWhitespace = count;
      }
      if (count + currentString.length >= index) {
        return includeWhitespace ? count : lastNonWhitespace ?? 0;
      }
      count += currentString.length;
    }
    return 0;
  }

  /// Return the offset at the start of the nearest word to the left of the
  /// given offset.
  ///
  /// {@macro flutter.rendering.RenderEditable.stopAtReversal}
  static int getLeftByWord(String text, TextMetrics textMetrics, int offset, [bool includeWhitespace = true]) {
    // If the offset is already all the way left, there is nothing to do.
    if (offset <= 0) {
      return offset;
    }

    // If we can just return the start of the text without checking for a word.
    if (offset == 1) {
      return 0;
    }

    final int startPoint = previousCharacter(offset, text, includeWhitespace);
    final TextRange word = textMetrics.getWordBoundary(TextPosition(offset: startPoint));
    return word.start;
  }

  /// Return the offset at the end of the nearest word to the right of the given
  /// offset.
  ///
  /// {@macro flutter.rendering.RenderEditable.stopAtReversal}
  static int getRightByWord(String text, TextMetrics textMetrics, int offset, [bool includeWhitespace = true]) {
    // If the selection is already all the way right, there is nothing to do.
    if (offset == text.length) {
      return offset;
    }

    // If we can just return the end of the text without checking for a word.
    if (offset == text.length - 1 || offset == text.length) {
      return text.length;
    }

    final int startPoint = includeWhitespace || !isWhitespace(text.codeUnitAt(offset))
        ? offset
        : nextCharacter(offset, text, includeWhitespace);
    final TextRange nextWord = textMetrics.getWordBoundary(TextPosition(offset: startPoint));
    return nextWord.end;
  }

  /// Return the given [TextSelection] extended left to the beginning of the
  /// nearest word.
  ///
  /// {@macro flutter.rendering.RenderEditable.whiteSpace}
  ///
  /// {@macro flutter.rendering.RenderEditable.stopAtReversal}
  static TextSelection extendGivenSelectionLeftByWord(String text, TextMetrics textMetrics, TextSelection selection, [bool includeWhitespace = true, bool stopAtReversal = false]) {
    // If the selection is already all the way left, there is nothing to do.
    if (selection.isCollapsed && selection.extentOffset <= 0) {
      return selection;
    }

    final int leftOffset = getLeftByWord(text, textMetrics, selection.extentOffset, includeWhitespace);

    if (stopAtReversal && selection.extentOffset > selection.baseOffset
        && leftOffset < selection.baseOffset) {
      return selection.copyWith(
        extentOffset: selection.baseOffset,
      );
    }

    return selection.copyWith(
      extentOffset: leftOffset,
    );
  }

  /// Return the given [TextSelection] extended right to the end of the nearest
  /// word.
  ///
  /// {@macro flutter.rendering.RenderEditable.whiteSpace}
  ///
  /// {@macro flutter.rendering.RenderEditable.stopAtReversal}
  static TextSelection extendGivenSelectionRightByWord(String text, TextMetrics textMetrics, TextSelection selection, [bool includeWhitespace = true, bool stopAtReversal = false]) {
    // If the selection is already all the way right, there is nothing to do.
    if (selection.isCollapsed && selection.extentOffset == text.length) {
      return selection;
    }

    final int rightOffset = getRightByWord(text, textMetrics, selection.extentOffset, includeWhitespace);

    if (stopAtReversal && selection.baseOffset > selection.extentOffset
        && rightOffset > selection.baseOffset) {
      return selection.copyWith(
        extentOffset: selection.baseOffset,
      );
    }

    return selection.copyWith(
      extentOffset: rightOffset,
    );
  }

  // TODO(justinmc): These static methods that need both the text and selection
  // should probably just be instance methods.
  /// Return the given [TextSelection] moved left to the end of the nearest word.
  ///
  /// A TextSelection that isn't collapsed will be collapsed and moved from the
  /// extentOffset.
  ///
  /// {@macro flutter.rendering.RenderEditable.stopAtReversal}
  static TextSelection moveGivenSelectionLeftByWord(String text, TextMetrics textMetrics, TextSelection selection, [bool includeWhitespace = true]) {
    // If the selection is already all the way left, there is nothing to do.
    if (selection.isCollapsed && selection.extentOffset <= 0) {
      return selection;
    }

    final int leftOffset = getLeftByWord(text, textMetrics, selection.extentOffset, includeWhitespace);
    return selection.copyWith(
      baseOffset: leftOffset,
      extentOffset: leftOffset,
    );
  }

  /// Return the given [TextSelection] moved right to the end of the nearest word.
  ///
  /// A TextSelection that isn't collapsed will be collapsed and moved from the
  /// extentOffset.
  ///
  /// {@macro flutter.rendering.RenderEditable.stopAtReversal}
  static TextSelection moveGivenSelectionRightByWord(String text, TextMetrics textMetrics, TextSelection selection, [bool includeWhitespace = true]) {
    // If the selection is already all the way right, there is nothing to do.
    if (selection.isCollapsed && selection.extentOffset == text.length) {
      return selection;
    }

    final int rightOffset = getRightByWord(text, textMetrics, selection.extentOffset, includeWhitespace);
    return selection.copyWith(
      baseOffset: rightOffset,
      extentOffset: rightOffset,
    );
  }


  /// Creates a copy of this value but with the given fields replaced with the new values.
  TextEditingValue copyWith({
    String? text,
    TextSelection? selection,
    TextRange? composing,
  }) {
    return TextEditingValue(
      text: text ?? this.text,
      selection: selection ?? this.selection,
      composing: composing ?? this.composing,
    );
  }

  /// Whether the [composing] range is a valid range within [text].
  ///
  /// Returns true if and only if the [composing] range is normalized, its start
  /// is greater than or equal to 0, and its end is less than or equal to
  /// [text]'s length.
  ///
  /// If this property is false while the [composing] range's `isValid` is true,
  /// it usually indicates the current [composing] range is invalid because of a
  /// programming error.
  bool get isComposingRangeValid => composing.isValid && composing.isNormalized && composing.end <= text.length;

  // Deletes the current non-empty selection.
  //
  // Operates on the text/selection contained in textSelectionDelegate, and does
  // not depend on `RenderEditable.selection`.
  //
  // If the selection is currently non-empty, this method deletes the selected
  // text and returns true. Otherwise this method does nothing and returns
  // false.
  TextEditingValue _deleteNonEmptySelection() {
    assert(selection.isValid);
    assert(!selection.isCollapsed);

    final String textBefore = selection.textBefore(text);
    final String textAfter = selection.textAfter(text);
    final TextSelection newSelection = TextSelection.collapsed(offset: selection.start);
    final TextRange newComposingRange = !composing.isValid || composing.isCollapsed
      ? TextRange.empty
      : TextRange(
        start: composing.start - (composing.start - selection.start).clamp(0, selection.end - selection.start),
        end: composing.end - (composing.end - selection.start).clamp(0, selection.end - selection.start),
      );

    return TextEditingValue(
      text: textBefore + textAfter,
      selection: newSelection,
      composing: newComposingRange,
    );
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
  TextEditingValue delete() {
    // `delete` does not depend on the text layout, and the boundary analysis is
    // done using the `previousCharacter` method instead of ICU, we can keep
    // deleting without having to layout the text. For this reason, we can
    // directly delete the character before the caret in the controller.
    if (!selection.isValid) {
      return this;
    }
    if (!selection.isCollapsed) {
      return _deleteNonEmptySelection();
    }

    final String textBefore = selection.textBefore(text);
    if (textBefore.isEmpty) {
      return this;
    }

    final String textAfter = selection.textAfter(text);

    final int characterBoundary = previousCharacter(textBefore.length, textBefore);
    final TextSelection newSelection = TextSelection.collapsed(offset: characterBoundary);
    assert(textBefore.length >= characterBoundary);
    final TextRange newComposingRange = !composing.isValid || composing.isCollapsed
      ? TextRange.empty
      : TextRange(
        start: composing.start - (composing.start - characterBoundary).clamp(0, textBefore.length - characterBoundary),
        end: composing.end - (composing.end - characterBoundary).clamp(0, textBefore.length - characterBoundary),
      );

    return TextEditingValue(
      text: textBefore.substring(0, characterBoundary) + textAfter,
      selection: newSelection,
      composing: newComposingRange,
    );
  }

  /// Deletes the from the current collapsed selection to the start of the field.
  ///
  /// The given SelectionChangedCause indicates the cause of this change and
  /// will be passed to onSelectionChanged.
  ///
  /// See also:
  ///   * [deleteToEnd]
  TextEditingValue deleteToStart() {
    assert(selection.isCollapsed);

    if (!selection.isValid) {
      return this;
    }

    final String textBefore = selection.textBefore(text);

    if (textBefore.isEmpty) {
      return this;
    }

    final String textAfter = selection.textAfter(text);
    const TextSelection newSelection = TextSelection.collapsed(offset: 0);
    return TextEditingValue(text: textAfter, selection: newSelection);
  }

  /// Deletes the from the current collapsed selection to the end of the field.
  ///
  /// The given SelectionChangedCause indicates the cause of this change and
  /// will be passed to onSelectionChanged.
  ///
  /// See also:
  ///   * [deleteToStart]
  TextEditingValue deleteToEnd() {
    assert(selection.isCollapsed);

    if (!selection.isValid) {
      return this;
    }

    final String textAfter = selection.textAfter(text);

    if (textAfter.isEmpty) {
      return this;
    }

    final String textBefore = selection.textBefore(text);
    final TextSelection newSelection = TextSelection.collapsed(offset: textBefore.length);
    return TextEditingValue(text: textBefore, selection: newSelection);
  }

  // TODO(justinmc): Update the references on this whiteSpace template.
  /// {@template flutter.rendering.TextEditingValue.whiteSpace}
  /// Deletes a word backwards from the current selection.
  ///
  /// If the [selection] is collapsed, deletes a word before the cursor.
  ///
  /// If the [selection] is not collapsed, deletes the selection.
  /// {@endtemplate}
  ///
  /// {@template flutter.rendering.RenderEditable.whiteSpace}
  /// By default, includeWhitespace is set to true, meaning that whitespace can
  /// be considered a word in itself.  If set to false, the selection will be
  /// extended past any whitespace and the first word following the whitespace.
  /// {@endtemplate}
  ///
  /// See also:
  ///
  ///   * [deleteForwardByWord], which is same but in the opposite direction.
  TextEditingValue deleteByWord(TextMetrics textMetrics, [bool includeWhitespace = true]) {
    assert(selection != null);

    if (!selection.isValid) {
      return this;
    }

    if (!selection.isCollapsed) {
      return _deleteNonEmptySelection();
    }

    String textBefore = selection.textBefore(text);
    if (textBefore.isEmpty) {
      return this;
    }

    final int characterBoundary = getLeftByWord(text, textMetrics, textBefore.length, includeWhitespace);
    textBefore = textBefore.trimRight().substring(0, characterBoundary);

    final String textAfter = selection.textAfter(text);
    final TextSelection newSelection = TextSelection.collapsed(offset: characterBoundary);
    return TextEditingValue(text: textBefore + textAfter, selection: newSelection);
  }

  /// {@template flutter.rendering.TextEditingValue.deleteByLine}
  /// Deletes a line backwards from the current selection.
  ///
  /// If the [selection] is collapsed, deletes a line before the cursor.
  ///
  /// If the [selection] is not collapsed, deletes the selection.
  /// {@endtemplate}
  ///
  /// See also:
  ///
  ///   * [deleteForwardByLine], which is same but in the opposite direction.
  TextEditingValue deleteByLine(TextMetrics textMetrics) {
    assert(selection != null);

    if (!selection.isValid) {
      return this;
    }

    if (!selection.isCollapsed) {
      return _deleteNonEmptySelection();
    }

    String textBefore = selection.textBefore(text);
    if (textBefore.isEmpty) {
      return this;
    }

    // When there is a line break, line delete shouldn't do anything
    final bool isPreviousCharacterBreakLine = textBefore.codeUnitAt(textBefore.length - 1) == 0x0A;
    if (isPreviousCharacterBreakLine) {
      return this;
    }

    final TextSelection line = textMetrics.getLineAtOffset(text, TextPosition(offset: textBefore.length - 1));
    textBefore = textBefore.substring(0, line.start);

    final String textAfter = selection.textAfter(text);
    final TextSelection newSelection = TextSelection.collapsed(offset: textBefore.length);
    return TextEditingValue(text: textBefore + textAfter, selection: newSelection);
  }

  /// {@template flutter.rendering.TextEditingValue.deleteForward}
  /// Deletes in the forward direction.
  ///
  /// If the selection is collapsed, deletes a single character after the
  /// cursor.
  ///
  /// If the selection is not collapsed, deletes the selection.
  /// {@endtemplate}
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// See also:
  ///
  ///   * [delete], which is the same but in the opposite direction.
  TextEditingValue deleteForward() {
    if (!selection.isValid) {
      return this;
    }
    if (!selection.isCollapsed) {
      return _deleteNonEmptySelection();
    }

    final String textAfter = selection.textAfter(text);
    if (textAfter.isEmpty) {
      return this;
    }

    final String textBefore = selection.textBefore(text);
    final int characterBoundary = nextCharacter(0, textAfter);
    final TextRange newComposingRange = !composing.isValid || composing.isCollapsed
      ? TextRange.empty
      : TextRange(
        start: composing.start - (composing.start - textBefore.length).clamp(0, characterBoundary),
        end: composing.end - (composing.end - textBefore.length).clamp(0, characterBoundary),
      );
    return TextEditingValue(
      text: textBefore + textAfter.substring(characterBoundary),
      selection: selection,
      composing: newComposingRange,
    );
  }

  /// {@template flutter.rendering.TextEditingValue.deleteForward}
  /// Deletes a word in the forward direction from the current selection.
  ///
  /// If the [selection] is collapsed, deletes a word after the cursor.
  ///
  /// If the [selection] is not collapsed, deletes the selection.
  /// {@endtemplate}
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  ///
  /// {@macro flutter.rendering.RenderEditable.whiteSpace}
  ///
  /// See also:
  ///
  ///   * [deleteByWord], which is same but in the opposite direction.
  TextEditingValue deleteForwardByWord(TextMetrics textMetrics, [bool includeWhitespace = true]) {
    assert(selection != null);

    if (!selection.isValid) {
      return this;
    }

    if (!selection.isCollapsed) {
      return _deleteNonEmptySelection();
    }

    String textAfter = selection.textAfter(text);

    if (textAfter.isEmpty) {
      return this;
    }

    final String textBefore = selection.textBefore(text);
    final int characterBoundary = getRightByWord(text, textMetrics, textBefore.length, includeWhitespace);
    textAfter = textAfter.substring(characterBoundary - textBefore.length);

    return TextEditingValue(text: textBefore + textAfter, selection: selection);
  }

  /// {@template flutter.rendering.TextEditingValue.deleteForwardByLine}
  /// Deletes a line in the forward direction from the current selection.
  ///
  /// If the [selection] is collapsed, deletes a line after the cursor.
  ///
  /// If the [selection] is not collapsed, deletes the selection.
  /// {@endtemplate}
  ///
  /// See also:
  ///
  ///   * [deleteByLine], which is same but in the opposite direction.
  TextEditingValue deleteForwardByLine(TextMetrics textMetrics) {
    assert(selection != null);

    if (!selection.isValid) {
      return this;
    }

    if (!selection.isCollapsed) {
      return _deleteNonEmptySelection();
    }

    String textAfter = selection.textAfter(text);
    if (textAfter.isEmpty) {
      return this;
    }

    // When there is a line break, it shouldn't do anything.
    final bool isNextCharacterBreakLine = textAfter.codeUnitAt(0) == 0x0A;
    if (isNextCharacterBreakLine) {
      return this;
    }

    final String textBefore = selection.textBefore(text);
    final TextSelection line = textMetrics.getLineAtOffset(text, TextPosition(offset: textBefore.length));
    textAfter = textAfter.substring(line.end - textBefore.length, textAfter.length);

    return TextEditingValue(text: textBefore + textAfter, selection: selection);
  }

  /// Return [selection] collapsed and moved to the given index.
  TextSelection moveSelectionTo(int index) {
    assert(selection != null);

    // If the selection is collapsed at the position already, then nothing
    // happens.
    if (selection.isCollapsed && selection.extentOffset == index) {
      return selection;
    }

    return selection.copyWith(
      baseOffset: index,
      extentOffset: index,
    );
  }

  /// Return [selection] expanded to the given [TextPosition].
  ///
  /// The given [TextPosition] must be outside of [selection].
  ///
  /// The returned selection will always be a strict superset of [selection].
  ///
  /// If the given position is at the very beginning or end of the text, then
  /// the [TextSelection.extentOffset] will be placed at the position,
  /// regardless of the original order of [TextSelection.extentOffset] and
  /// [TextSelection.baseOffset]. For any other position, the order of the two
  /// offsets will be preserved.
  ///
  /// See also:
  ///
  ///   * [extendSelectionTo], which is similar but only moves
  ///     [TextSelection.extentOffset].
  TextSelection expandSelectionTo(int index) {
    assert(selection != null);

    final int upperOffset = math.min(selection.baseOffset, selection.extentOffset);
    final int lowerOffset = math.max(selection.baseOffset, selection.extentOffset);
    assert(index <= upperOffset || index >= lowerOffset);

    if (index == 0) {
      return selection.copyWith(
        extentOffset: 0,
        baseOffset: lowerOffset,
      );
    } else if (index == text.length) {
      return selection.copyWith(
        extentOffset: text.length,
        baseOffset: upperOffset,
      );
    }

    if (index <= upperOffset) {
      if (selection.baseOffset < selection.extentOffset) {
        return selection.copyWith(
          baseOffset: index,
        );
      }
      return selection.copyWith(
        extentOffset: index,
      );
    }
    if (selection.baseOffset < selection.extentOffset) {
      return selection.copyWith(
        extentOffset: index,
      );
    }
    return selection.copyWith(
      baseOffset: index,
    );
  }

  /// Keeping [selection]'s [TextSelection.baseOffset] fixed, move the
  /// [TextSelection.extentOffset] to the given [TextPosition].
  TextSelection extendSelectionTo(int index) {
    assert(selection != null);

    // If the selection's extent is at the position already, then nothing
    // happens.
    if (selection.extentOffset == index) {
      return selection;
    }

    return selection.copyWith(
      extentOffset: index,
    );
  }

  /// {@template flutter.rendering.TextEditingValue.selectAll}
  /// Set the current [selection] to contain the entire text value.
  /// {@endtemplate}
  ///
  /// {@macro flutter.rendering.RenderEditable.cause}
  TextSelection selectAll() {
    return selection.copyWith(
      baseOffset: 0,
      extentOffset: text.length,
    );
  }

  /// Returns a representation of this object as a JSON object.
  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'text': text,
      'selectionBase': selection.baseOffset,
      'selectionExtent': selection.extentOffset,
      'selectionAffinity': selection.affinity.toString(),
      'selectionIsDirectional': selection.isDirectional,
      'composingBase': composing.start,
      'composingExtent': composing.end,
    };
  }

  @override
  String toString() => '${objectRuntimeType(this, 'TextEditingValue')}(text: \u2524$text\u251C, selection: $selection, composing: $composing)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    return other is TextEditingValue
        && other.text == text
        && other.selection == selection
        && other.composing == composing;
  }

  @override
  int get hashCode => hashValues(
    text.hashCode,
    selection.hashCode,
    composing.hashCode,
  );
}
