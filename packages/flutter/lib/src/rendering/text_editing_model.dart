// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

/// State and logic for transforming that state related to Flutter's text
/// editing.
///
/// Contains only generic text editing logic and purposely excludes specific
/// business logic related to platforms and widgets.
@immutable
class TextEditingModel {
  /// Create an instance of TextEditingModel.
  const TextEditingModel({
    required this.value,
  }) : assert(value != null);

  /// The [TextEditingValue] that this TextEditingModel operates on.
  final TextEditingValue value;

  TextRange get _composing => value.composing;
  TextSelection get _selection => value.selection;
  String get _text => value.text;

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

  /// Return the given [TextSelection] with its [TextSelection.extentOffset]
  /// moved right by one character.
  ///
  /// {@macro flutter.rendering.RenderEditable.whiteSpace}
  static TextSelection extendGivenSelectionRight(TextSelection selection, String text, [bool includeWhitespace = true]) {
    // If the selection is already all the way right, there is nothing to do.
    if (selection.extentOffset >= text.length) {
      return selection;
    }
    final int nextExtent = nextCharacter(selection.extentOffset, text, includeWhitespace);
    return selection.copyWith(extentOffset: nextExtent);
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
  static int getLeftByWord(TextPainter textPainter, int offset, [bool includeWhitespace = true]) {
    // If the offset is already all the way left, there is nothing to do.
    if (offset <= 0) {
      return offset;
    }

    // If we can just return the start of the text without checking for a word.
    if (offset == 1) {
      return 0;
    }

    final String text = textPainter.text!.toPlainText();
    final int startPoint = previousCharacter(offset, text, includeWhitespace);
    final TextRange word = textPainter.getWordBoundary(TextPosition(offset: startPoint));
    return word.start;
  }

  /// Return the offset at the end of the nearest word to the right of the given
  /// offset.
  ///
  /// {@macro flutter.rendering.RenderEditable.stopAtReversal}
  static int getRightByWord(TextPainter textPainter, int offset, [bool includeWhitespace = true]) {
    // If the selection is already all the way right, there is nothing to do.
    final String text = textPainter.text!.toPlainText();
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
    final TextRange nextWord = textPainter.getWordBoundary(TextPosition(offset: startPoint));
    return nextWord.end;
  }

  /// Return the given [TextSelection] extended left to the beginning of the
  /// nearest word.
  ///
  /// {@macro flutter.rendering.RenderEditable.whiteSpace}
  ///
  /// {@macro flutter.rendering.RenderEditable.stopAtReversal}
  static TextSelection extendGivenSelectionLeftByWord(TextPainter textPainter, TextSelection selection, [bool includeWhitespace = true, bool stopAtReversal = false]) {
    // If the selection is already all the way left, there is nothing to do.
    if (selection.isCollapsed && selection.extentOffset <= 0) {
      return selection;
    }

    final int leftOffset = getLeftByWord(textPainter, selection.extentOffset, includeWhitespace);

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
  static TextSelection extendGivenSelectionRightByWord(TextPainter textPainter, TextSelection selection, [bool includeWhitespace = true, bool stopAtReversal = false]) {
    // If the selection is already all the way right, there is nothing to do.
    final String text = textPainter.text!.toPlainText();
    if (selection.isCollapsed && selection.extentOffset == text.length) {
      return selection;
    }

    final int rightOffset = getRightByWord(textPainter, selection.extentOffset, includeWhitespace);

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

  /// Return the given [TextSelection] moved left to the end of the nearest word.
  ///
  /// A TextSelection that isn't collapsed will be collapsed and moved from the
  /// extentOffset.
  ///
  /// {@macro flutter.rendering.RenderEditable.stopAtReversal}
  static TextSelection moveGivenSelectionLeftByWord(TextPainter textPainter, TextSelection selection, [bool includeWhitespace = true]) {
    // If the selection is already all the way left, there is nothing to do.
    if (selection.isCollapsed && selection.extentOffset <= 0) {
      return selection;
    }

    final int leftOffset = getLeftByWord(textPainter, selection.extentOffset, includeWhitespace);
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
  static TextSelection moveGivenSelectionRightByWord(TextPainter textPainter, TextSelection selection, [bool includeWhitespace = true]) {
    // If the selection is already all the way right, there is nothing to do.
    final String text = textPainter.text!.toPlainText();
    if (selection.isCollapsed && selection.extentOffset == text.length) {
      return selection;
    }

    final int rightOffset = getRightByWord(textPainter, selection.extentOffset, includeWhitespace);
    return selection.copyWith(
      baseOffset: rightOffset,
      extentOffset: rightOffset,
    );
  }

  TextSelection expandSelectionLeftByLine(TextMetrics textMetrics) {
    assert(_selection != null);

    final int firstOffset = math.min(_selection.baseOffset, _selection.extentOffset);
    final int startPoint = TextEditingModel.previousCharacter(firstOffset, _text, false);
    final TextSelection selectedLine = textMetrics.getLineAtOffset(
      _text,
      TextPosition(offset: startPoint),
    );

    late final TextSelection nextSelection;
    if (_selection.extentOffset <= _selection.baseOffset) {
      nextSelection = _selection.copyWith(
        extentOffset: selectedLine.baseOffset,
      );
    } else {
      nextSelection = _selection.copyWith(
        baseOffset: selectedLine.baseOffset,
      );
    }

    return nextSelection;
  }

  // TODO(justinmc): copy over code
  TextSelection moveSelectionLeftByLine() {
    return TextSelection.collapsed(offset: 0);
  }

  /// Extend the current selection to the end of the field.
  ///
  /// If selectionEnabled is false, keeps the selection collapsed and moves it to
  /// the end.
  ///
  /// See also:
  ///
  ///   * [extendSelectionToStart]
  TextSelection extendSelectionToEnd() {
    if (_selection.extentOffset == _text.length) {
      return _selection;
    }

    return _selection.copyWith(
      extentOffset: _text.length,
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
  TextEditingValue delete(SelectionChangedCause cause) {
    if (!_selection.isValid) {
      return value;
    }
    if (!_selection.isCollapsed) {
      return _deleteNonEmptySelection();
    }

    final String textBefore = _selection.textBefore(value.text);
    if (textBefore.isEmpty) {
      return value;
    }

    final String textAfter = _selection.textAfter(value.text);

    final int characterBoundary = TextEditingModel.previousCharacter(textBefore.length, textBefore);
    final TextSelection newSelection = TextSelection.collapsed(offset: characterBoundary);
    final TextRange composing = value.composing;
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

  // Deletes the current non-empty selection.
  //
  // Operates on the text/selection contained in textSelectionDelegate, and does
  // not depend on `RenderEditable.selection`.
  //
  // If the selection is currently non-empty, this method deletes the selected
  // text and returns true. Otherwise this method does nothing and returns
  // false.
  TextEditingValue _deleteNonEmptySelection() {
    assert(_selection.isValid);
    assert(!_selection.isCollapsed);

    final String textBefore = _selection.textBefore(_text);
    final String textAfter = _selection.textAfter(_text);
    final TextSelection newSelection = TextSelection.collapsed(offset: _selection.start);
    final TextRange newComposingRange = !_composing.isValid || _composing.isCollapsed
      ? TextRange.empty
      : TextRange(
        start: _composing.start - (_composing.start - _selection.start).clamp(0, _selection.end - _selection.start),
        end: _composing.end - (_composing.end - _selection.start).clamp(0, _selection.end - _selection.start),
      );

    return TextEditingValue(
      text: textBefore + textAfter,
      selection: newSelection,
      composing: newComposingRange,
    );
  }
}

// TODO(justinmc): Document and move to own file.
// TODO(justinmc): Rename to TextEditingMetrics?
/// A read-only interface for accessing information about some editable text.
abstract class TextMetrics {
  TextSelection getLineAtOffset(String text, TextPosition position);
}
