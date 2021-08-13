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
  // If the selection is currently non-empty, this method deletes the selected
  // text. Otherwise this method does nothing.
  TextEditingValue _deleteNonEmptySelection() {
    assert(selection.isValid);
    assert(!selection.isCollapsed);

    final String textBefore = selection.textBefore(text);
    final String textAfter = selection.textAfter(text);
    final TextSelection newSelection = TextSelection.collapsed(
      offset: selection.start,
      affinity: selection.affinity,
    );
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

  /// Deletes to the given index.
  ///
  /// Returns a new TextEditingValue representing the state after the deletion.
  ///
  /// If the selection is not collapsed, deletes the selection regardless of the
  /// given index.
  TextEditingValue deleteTo(int index) {
    assert(selection != null);

    if (!selection.isValid) {
      return this;
    }

    if (!selection.isCollapsed) {
      return _deleteNonEmptySelection();
    }

    final String textBefore = selection.textBefore(text);
    if (index == selection.extentOffset) {
      return this;
    } else if (index < selection.extentOffset) {
      if (textBefore.isEmpty) {
        return this;
      }
      final TextRange nextComposingRange = !composing.isValid || composing.isCollapsed
        ? TextRange.empty
        : TextRange(
          start: composing.start - (composing.start - index).clamp(0, textBefore.length - index),
          end: composing.end - (composing.end - index).clamp(0, textBefore.length - index),
        );
      return TextEditingValue(
        text: text.substring(0, index) + text.substring(selection.extentOffset, text.length),
        selection: TextSelection.collapsed(offset: index, affinity: selection.affinity),
        composing: nextComposingRange,
      );
    }

    if (selection.textAfter(text).isEmpty) {
      return this;
    }
    final String nextText = text.substring(0, selection.extentOffset) + text.substring(index, text.length);
    final int charactersDeleted = text.length - nextText.length;
    final int selectionToComposingStart = composing.start - selection.baseOffset;
    final int charactersDeletedBeforeComposingStart = selectionToComposingStart.clamp(0, charactersDeleted);
    final int selectionToComposingEnd = composing.end - selection.baseOffset;
    final int charactersDeletedBeforeComposingEnd = selectionToComposingEnd.clamp(0, charactersDeleted);
    final TextRange nextComposingRange = !composing.isValid || composing.isCollapsed
      ? TextRange.empty
      : TextRange(
        start: composing.start - charactersDeletedBeforeComposingStart,
        end: composing.end - charactersDeletedBeforeComposingEnd,
      );
    return TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: index - text.length + nextText.length),
      composing: nextComposingRange,
    );
  }

  /// Return [selection] collapsed and moved to the given [TextPosition].
  TextSelection moveSelectionTo(TextPosition position) {
    assert(selection != null);

    // If the selection is collapsed at the position already, then nothing
    // happens.
    if (selection.isCollapsed && selection.extentOffset == position.offset) {
      return selection;
    }

    return selection.copyWith(
      baseOffset: position.offset,
      extentOffset: position.offset,
      affinity: position.affinity,
    );
  }

  /// Return [selection] expanded to the given [TextPosition].
  ///
  /// If the given [TextPosition] is inside of [selection], then [selection] is
  /// returned without change.
  ///
  /// The returned selection will always be a strict superset of [selection].
  /// In other words, the selection grows to include the given [TextPosition].
  ///
  /// If extentAtIndex is true, then the [TextSelection.extentOffset] will be
  /// placed at the given index regardless of the original order of it and
  /// [TextSelection.baseOffset]. Otherwise, their order will be preserved.
  ///
  /// ## Difference with [extendSelectionTo]
  /// In contrast with this method, [extendSelectionTo] is a pivot; it holds
  /// [TextSelection.baseOffset] fixed while moving [TextSelection.extentOffset]
  /// to the given [TextPosition].  It doesn't strictly grow the selection and
  /// may collapse it or flip its order.
  TextSelection expandSelectionTo(TextPosition position, [bool extentAtIndex = false]) {
    assert(selection != null);

    final int upperOffset = math.min(selection.baseOffset, selection.extentOffset);
    final int lowerOffset = math.max(selection.baseOffset, selection.extentOffset);
    if (position.offset >= upperOffset && position.offset <= lowerOffset) {
      return selection;
    }

    if (selection.baseOffset <= selection.extentOffset) {
      if (position.offset <= selection.baseOffset) {
        if (extentAtIndex) {
          return selection.copyWith(
            baseOffset: selection.extentOffset,
            extentOffset: position.offset,
            affinity: position.affinity,
          );
        }
        return selection.copyWith(
          baseOffset: position.offset,
          affinity: position.affinity,
        );
      }
      return selection.copyWith(
        extentOffset: position.offset,
        affinity: position.affinity,
      );
    }
    if (position.offset <= selection.extentOffset) {
      return selection.copyWith(
        extentOffset: position.offset,
        affinity: position.affinity,
      );
    }
    if (extentAtIndex) {
      return selection.copyWith(
        baseOffset: selection.extentOffset,
        extentOffset: position.offset,
        affinity: position.affinity,
      );
    }
    return selection.copyWith(
      baseOffset: position.offset,
      affinity: position.affinity,
    );
  }

  /// Keeping [selection]'s [TextSelection.baseOffset] fixed, pivot the
  /// [TextSelection.extentOffset] to the given [TextPosition].
  ///
  /// In some cases, the [TextSelection.baseOffset] and
  /// [TextSelection.extentOffset] may flip during this operation, or the size
  /// of the selection may shrink.
  ///
  /// ## Difference with [expandSelectionTo]
  /// In contrast with this method, [expandSelectionTo] is strictly growth; the
  /// selection is grown to include the given [TextPosition] and will never
  /// shrink.
  TextSelection extendSelectionTo(TextPosition position) {
    assert(selection != null);

    // If the selection's extent is at the position already, then nothing
    // happens.
    if (selection.extent == position) {
      return selection;
    }

    return selection.copyWith(
      extentOffset: position.offset,
      affinity: position.affinity,
    );
  }

  /// {@template flutter.services.TextEditingValue.selectAll}
  /// Select the entire text value.
  /// {@endtemplate}
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
