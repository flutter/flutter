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

  /// Deletes to the given index.
  ///
  /// Returns a new TextEditingValue representing the state after the deletion.
  ///
  /// If the selection is not collapsed, deletes the selection regardless of the
  /// given index.
  TextEditingValue deleteTo(int index, [bool includeWhitespace = true]) {
    assert(selection != null);

    if (!selection.isValid) {
      return this;
    }

    if (!selection.isCollapsed) {
      return _deleteNonEmptySelection();
    }

    final String textAfter = selection.textAfter(text);
    final String textBefore = selection.textBefore(text);
    if (index == selection.extentOffset) {
      return this;
    } else if (index < selection.extentOffset) {
      if (textBefore.isEmpty) {
        return this;
      }
      return TextEditingValue(
        text: text.substring(0, index) + text.substring(selection.extentOffset, text.length),
        selection: TextSelection.collapsed(offset: index),
      );
    }

    if (selection.textAfter(text).isEmpty) {
      return this;
    }
    final String nextText = text.substring(0, selection.extentOffset) + text.substring(index, text.length);
    return TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: index - text.length + nextText.length),
    );
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
  /// If the given [TextPosition] is inside of [selection], then [selection] is
  /// returned without change.
  ///
  /// The returned selection will always be a strict superset of [selection].
  ///
  /// If extentAtIndex is true, then the [TextSelection.extentOffset] will be
  /// placed at the given index regardless of the original order of it and
  /// [TextSelection.baseOffset]. Otherwise, their order will be preserved.
  ///
  /// See also:
  ///
  ///   * [extendSelectionTo], which is similar but only moves
  ///     [TextSelection.extentOffset].
  TextSelection expandSelectionTo(int index, [bool extentAtIndex = false]) {
    assert(selection != null);

    final int upperOffset = math.min(selection.baseOffset, selection.extentOffset);
    final int lowerOffset = math.max(selection.baseOffset, selection.extentOffset);
    if (index >= upperOffset && index <= lowerOffset) {
      return selection;
    }

    if (selection.baseOffset <= selection.extentOffset) {
      if (index <= selection.baseOffset) {
        if (extentAtIndex) {
          return selection.copyWith(
            baseOffset: selection.extentOffset,
            extentOffset: index,
          );
        }
        return selection.copyWith(
          baseOffset: index,
        );
      }
      return selection.copyWith(
        extentOffset: index,
      );
    }
    if (index <= selection.extentOffset) {
      return selection.copyWith(
        extentOffset: index,
      );
    }
    if (extentAtIndex) {
      return selection.copyWith(
        baseOffset: selection.extentOffset,
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
