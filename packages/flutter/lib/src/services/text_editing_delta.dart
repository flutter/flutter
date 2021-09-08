// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'text_editing.dart';
import 'text_input.dart' show TextEditingValue;

TextAffinity? _toTextAffinity(String? affinity) {
  switch (affinity) {
    case 'TextAffinity.downstream':
      return TextAffinity.downstream;
    case 'TextAffinity.upstream':
      return TextAffinity.upstream;
  }
  return null;
}

/// Replaces a range of text in the original string with the text given in the
/// replacement string.
String _replace(String originalText, String replacementText, int start, int end) {
  final String textStart = originalText.substring(0, start);
  final String textEnd = originalText.substring(end, originalText.length);
  final String newText = textStart + replacementText + textEnd;
  return newText;
}

/// A way to disambiguate a [TextEditingDelta] when a delta generated for an insertion
/// and a deletion both contain collapsed [TextEditingDelta.deltaRange]'s.
enum TextEditingDeltaType {
  /// {@template flutter.services.TextEditingDeltaInsertion}
  /// The delta is inserting a single/or contigous sequence of characters.
  /// {@endtemplate}
  insertion,

  /// {@template flutter.services.TextEditingDeltaDeletion}
  /// The delta is deleting a single/or contiguous sequence of characters.
  /// {@endtemplate}
  deletion,

  /// {@template flutter.services.TextEditingDeltaReplacement}
  /// The delta is replacing a range of characters with a new sequence of text.
  ///
  /// The range that is being replaced can either grow or shrink based on the
  /// given replacement text.
  ///
  /// A replacement can occur in cases such as auto-correct, suggestions, and
  /// when a selection is replaced by a single character.
  /// {@endtemplate}
  replacement,

  /// {@template flutter.services.TextEditingDeltaNonTextUpdate}
  /// The delta is not modifying the text. There are potentially selection and
  /// composing region updates in the delta that still need to be applied to your
  /// text model.
  ///
  /// A situation where this delta would be created is when dragging the selection
  /// handles. There are no changes to the text, but there are updates to the selection
  /// and potentially the composing region as well.
  /// {@endtemplate}
  nonTextUpdate,
}

/// A structure representing a granular change that has occurred to the editing
/// state as a result of text editing.
abstract class TextEditingDelta {
  /// Creates a delta for a given change to the editing state.
  ///
  /// {@template flutter.services.TextEditingDelta}
  /// The [oldText], [deltaText], [deltaRange], [selection], and [composing]
  /// arguments must not be null.
  /// {@endtemplate}
  const TextEditingDelta({
    required this.oldText,
    this.deltaText = '',
    this.deltaRange = TextRange.empty,
    required this.selection,
    required this.composing,
  }) : assert(oldText != null),
       assert(deltaText != null),
       assert(deltaRange != null),
       assert(selection != null),
       assert(composing != null);

  /// Creates an instance of this class from a JSON object by inferring the
  /// type of delta based on values sent from the engine.
  factory TextEditingDelta.fromJSON(Map<String, dynamic> encoded) {
    final String oldText = encoded['oldText'] as String;
    final int start = encoded['deltaStart'] as int;
    final int end = encoded['deltaEnd'] as int;
    final String tb = encoded['deltaText'] as String;
    const int tbStart = 0;
    final int tbEnd = tb.length;

    // This delta is explicitly a non text update.
    final bool isNonTextUpdate = start == -1 && start == end;
    final TextRange newComposing = TextRange(
      start: encoded['composingBase'] as int? ?? -1,
      end: encoded['composingExtent'] as int? ?? -1,
    );
    final TextSelection newSelection = TextSelection(
      baseOffset: encoded['selectionBase'] as int? ?? -1,
      extentOffset: encoded['selectionExtent'] as int? ?? -1,
      affinity: _toTextAffinity(encoded['selectionAffinity'] as String?) ??
          TextAffinity.downstream,
      isDirectional: encoded['selectionIsDirectional'] as bool? ?? false,
    );

    if (isNonTextUpdate) {
      return TextEditingDeltaNonTextUpdate(
        oldText: oldText,
        selection: newSelection,
        composing: newComposing,
      );
    }

    final String textStart = oldText.substring(0, start);
    final String textEnd = oldText.substring(end, oldText.length);
    final String newText = textStart + tb + textEnd;

    final bool isEqual = oldText == newText;

    final bool isDeletionGreaterThanOne = (end - start) - (tbEnd - tbStart) > 1;
    final bool isDeletingByReplacingWithEmpty = tb.isEmpty && tbStart == 0 && tbStart == tbEnd;

    final bool isReplacedByShorter = isDeletionGreaterThanOne && (tbEnd - tbStart < end - start);
    final bool isReplacedByLonger = tbEnd - tbStart > end - start;
    final bool isReplacedBySame = tbEnd - tbStart == end - start;

    final bool isInsertingInsideComposingRegion = start + tbEnd > end;
    final bool isDeletingInsideComposingRegion =
        !isReplacedByShorter && !isDeletingByReplacingWithEmpty && start + tbEnd < end;

    String newComposingText;
    String originalComposingText;

    if (isDeletingByReplacingWithEmpty || isDeletingInsideComposingRegion || isReplacedByShorter) {
      newComposingText = tb.substring(tbStart, tbEnd);
      originalComposingText = oldText.substring(start, start + tbEnd);
    } else {
      newComposingText = tb.substring(tbStart, tbStart + (end - start));
      originalComposingText = oldText.substring(start, end);
    }

    final bool isOriginalComposingRegionTextChanged = !(originalComposingText == newComposingText);
    final bool isReplaced = isOriginalComposingRegionTextChanged ||
        (isReplacedByLonger || isReplacedByShorter || isReplacedBySame);

    if (isEqual) {
      return TextEditingDeltaNonTextUpdate(
        oldText: oldText,
        selection: newSelection,
        composing: newComposing,
      );
    } else if ((isDeletingByReplacingWithEmpty || isDeletingInsideComposingRegion) &&
        !isOriginalComposingRegionTextChanged) {  // Deletion.
      int actualStart = start;

      if (!isDeletionGreaterThanOne) {
        actualStart = end - 1;
      }

      return TextEditingDeltaDeletion(
        oldText: oldText,
        deltaText: tb,
        deltaRange: TextRange(
          start: actualStart,
          end: end,
        ),
        selection: newSelection,
        composing: newComposing,
      );
    } else if ((start == end || isInsertingInsideComposingRegion) &&
        !isOriginalComposingRegionTextChanged) {  // Insertion.
      return TextEditingDeltaInsertion(
        oldText: oldText,
        deltaText: tb.substring(end - start, (end - start) + (tb.length - (end - start))),
        deltaRange: TextRange(
          start: end,
          end: end,
        ),
        selection: newSelection,
        composing: newComposing,
      );
    } else if (isReplaced) {  // Replacement.
      return TextEditingDeltaReplacement(
        oldText: oldText,
        deltaText: tb,
        deltaRange: TextRange(
          start: start,
          end: end,
        ),
        selection: newSelection,
        composing: newComposing,
      );
    }

    assert(false);
    return TextEditingDeltaNonTextUpdate(
      oldText: oldText,
      selection: newSelection,
      composing: newComposing,
    );
  }

  /// The old text state before the delta has occurred.
  final String oldText;

  /// The value represents the text that is being inserted/deleted by this delta.
  ///
  /// This value will slightly vary based on the [TextEditingDeltaType]:
  ///
  ///  * For a [TextEditingDeltaType.insertion] this will be the character/s being
  /// inserted.
  ///
  ///  * For a [TextEditingDeltaType.deletion] this will be an empty string.
  ///
  ///  * For a [TextEditingDeltaType.replacement] this will be the text that is
  /// replacing the [TextEditingDelta.deltaRange].
  ///
  ///  * For a [TextEditingDeltaType.nonTextUpdate] this will be an empty string.
  final String deltaText;

  /// This value can either represent a range of text that the delta is changing
  /// or if is a collapsed range then it represents the point where this delta
  /// began.
  ///
  /// This value will slightly vary based on the [TextEditingDeltaType]:
  ///
  ///  * For a [TextEditingDeltaType.insertion] this will be a collapsed range
  /// representing the cursor position where the insertion began.
  ///
  ///  * For a [TextEditingDeltaType.deletion] this will be the range of text
  /// that was deleted.
  ///
  ///  * For a [TextEditingDeltaType.replacement] this will be the range of
  /// characters that are being replaced.
  ///
  ///  * For a [TextEditingDeltaType.nonTextUpdate] this will be a collapsed range
  /// of (-1,-1).
  final TextRange deltaRange;

  /// {@template flutter.services.TextEditingDelta.deltaType}
  /// The type of delta that has occured.
  ///
  /// See [TextEditingDeltaType] for more information.
  /// {@endtemplate}
  TextEditingDeltaType get deltaType;

  /// The range of text that is currently selected after the delta has been
  /// applied.
  final TextSelection selection;

  /// The range of text that is still being composed after the delta has been
  /// applied.
  final TextRange composing;

  /// {@template flutter.services.TextEditingDelta.apply}
  /// This method will take the given [TextEditingValue] and return a new
  /// [TextEditingValue] with that instance of [TextEditingDelta] applied to it.
  /// {@endtemplate}
  TextEditingValue apply(TextEditingValue value) {
    // Verify that the delta we are applying is applicable to the given
    // editing state. If not then we return the original value.
    if (value.text != oldText) {
      return value;
    }

    return apply(value);
  }
}

/// {@macro flutter.services.TextEditingDeltaInsertion}
class TextEditingDeltaInsertion extends TextEditingDelta {
  /// Creates an insertion delta for a given change to the editing state.
  ///
  /// {@macro flutter.services.TextEditingDelta}
  const TextEditingDeltaInsertion({
    required String oldText,
    required String deltaText,
    required TextRange deltaRange,
    required TextSelection selection,
    required TextRange composing,
  }) : super(
      oldText: oldText,
      deltaText: deltaText,
      deltaRange: deltaRange,
      selection: selection,
      composing: composing,
  );

  /// {@macro flutter.services.TextEditingDelta.deltaType}
  @override
  TextEditingDeltaType get deltaType => TextEditingDeltaType.insertion;

  /// {@macro flutter.services.TextEditingDelta.apply}
  @override
  TextEditingValue apply(TextEditingValue value) {
    String newText = value.text;
    newText = _replace(newText, deltaText, deltaRange.start, deltaRange.end);
    return value.copyWith(text: newText, selection: selection, composing: composing);
  }
}

/// {@macro flutter.services.TextEditingDeltaDeletion}
class TextEditingDeltaDeletion extends TextEditingDelta {
  /// Creates a deletion delta for a given change to the editing state.
  ///
  /// {@macro flutter.services.TextEditingDelta}
  const TextEditingDeltaDeletion({
    required String oldText,
    required String deltaText,
    required TextRange deltaRange,
    required TextSelection selection,
    required TextRange composing,
  }) : super(
    oldText: oldText,
    deltaText: deltaText,
    deltaRange: deltaRange,
    selection: selection,
    composing: composing,
  );

  /// {@macro flutter.services.TextEditingDelta.deltaType}
  @override
  TextEditingDeltaType get deltaType => TextEditingDeltaType.deletion;

  /// {@macro flutter.services.TextEditingDelta.apply}
  @override
  TextEditingValue apply(TextEditingValue value) {
    String newText = value.text;
    newText = _replace(newText, '', deltaRange.start, deltaRange.end);
    return value.copyWith(text: newText, selection: selection, composing: composing);
  }
}

/// {@macro flutter.services.TextEditingDeltaReplacement}
class TextEditingDeltaReplacement extends TextEditingDelta {
  /// Creates a replacement delta for a given change to the editing state.
  ///
  /// {@macro flutter.services.TextEditingDelta}
  const TextEditingDeltaReplacement({
    required String oldText,
    required String deltaText,
    required TextRange deltaRange,
    required TextSelection selection,
    required TextRange composing,
  }) : super(
    oldText: oldText,
    deltaText: deltaText,
    deltaRange: deltaRange,
    selection: selection,
    composing: composing,
  );

  /// {@macro flutter.services.TextEditingDelta.deltaType}
  @override
  TextEditingDeltaType get deltaType => TextEditingDeltaType.replacement;

  /// {@macro flutter.services.TextEditingDelta.apply}
  @override
  TextEditingValue apply(TextEditingValue value) {
    String newText = value.text;
    newText = _replace(newText, deltaText, deltaRange.start, deltaRange.end);
    return value.copyWith(text: newText, selection: selection, composing: composing);
  }
}

/// {@macro flutter.services.TextEditingDeltaNonTextUpdate}
class TextEditingDeltaNonTextUpdate extends TextEditingDelta {
  /// Creates a delta representing no changes to the text value of the current
  /// editing state. This delta includes updates to the selection and/or composing
  /// regions.
  ///
  /// {@macro flutter.services.TextEditingDelta}
  const TextEditingDeltaNonTextUpdate({
    required String oldText,
    required TextSelection selection,
    required TextRange composing,
  }) : super(
    oldText: oldText,
    selection: selection,
    composing: composing,
  );

  /// {@macro flutter.services.TextEditingDelta.deltaType}
  @override
  TextEditingDeltaType get deltaType => TextEditingDeltaType.nonTextUpdate;

  /// {@macro flutter.services.TextEditingDelta.deltaType}
  @override
  TextEditingValue apply(TextEditingValue value) {
    return value.copyWith(selection: selection, composing: composing);
  }
}
