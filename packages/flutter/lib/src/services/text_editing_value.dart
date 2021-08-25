// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
      return TextMetrics.isWhitespace(currentString.codeUnitAt(0));
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
          !TextMetrics.isWhitespace(currentString.characters.first.codeUnitAt(0))) {
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

  /// Deletes to the given index, inclusively.
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

  /// Return a new TextSelection with the entire [text] selected.
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
