// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';

import 'text_editing.dart';
import 'text_input.dart';

/// {@template flutter.services.textFormatter.maxLengthEnforcement}
/// ### [MaxLengthEnforcement.enforced] versus
/// [MaxLengthEnforcement.truncateAfterCompositionEnds]
///
/// Both [MaxLengthEnforcement.enforced] and
/// [MaxLengthEnforcement.truncateAfterCompositionEnds] make sure the final
/// length of the text does not exceed the max length specified. The difference
/// is that [MaxLengthEnforcement.enforced] truncates all text while
/// [MaxLengthEnforcement.truncateAfterCompositionEnds] allows composing text to
/// exceed the limit. Allowing this "placeholder" composing text to exceed the
/// limit may provide a better user experience on some platforms for entering
/// ideographic characters (e.g. CJK characters) via composing on phonetic
/// keyboards.
///
/// Some input methods (Gboard on Android for example) initiate text composition
/// even for Latin characters, in which case the best experience may be to
/// truncate those composing characters with [MaxLengthEnforcement.enforced].
///
/// In fields that strictly support only a small subset of characters, such as
/// verification code fields, [MaxLengthEnforcement.enforced] may provide the
/// best experience.
/// {@endtemplate}
///
/// See also:
///
///  * [TextField.maxLengthEnforcement] which is used in conjunction with
///  [TextField.maxLength] to limit the length of user input. [TextField] also
///  provides a character counter to provide visual feedback.
enum MaxLengthEnforcement {
  /// No enforcement applied to the editing value. It's possible to exceed the
  /// max length.
  none,

  /// Keep the length of the text input from exceeding the max length even when
  /// the text has an unfinished composing region.
  enforced,

  /// Users can still input text if the current value is composing even after
  /// reaching the max length limit. After composing ends, the value will be
  /// truncated.
  truncateAfterCompositionEnds,
}

/// A [TextInputFormatter] can be optionally injected into an [EditableText]
/// to provide as-you-type validation and formatting of the text being edited.
///
/// Text modification should only be applied when text is being committed by the
/// IME and not on text under composition (i.e., only when
/// [TextEditingValue.composing] is collapsed).
///
/// See also the [FilteringTextInputFormatter], a subclass that
/// removes characters that the user tries to enter if they do, or do
/// not, match a given pattern (as applicable).
///
/// To create custom formatters, extend the [TextInputFormatter] class and
/// implement the [formatEditUpdate] method.
///
/// ## Handling emojis and other complex characters
/// {@macro flutter.widgets.EditableText.onChanged}
///
/// See also:
///
///  * [EditableText] on which the formatting apply.
///  * [FilteringTextInputFormatter], a provided formatter for filtering
///    characters.
abstract class TextInputFormatter {
  /// Called when text is being typed or cut/copy/pasted in the [EditableText].
  ///
  /// You can override the resulting text based on the previous text value and
  /// the incoming new text value.
  ///
  /// When formatters are chained, `oldValue` reflects the initial value of
  /// [TextEditingValue] at the beginning of the chain.
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  );

  /// A shorthand to creating a custom [TextInputFormatter] which formats
  /// incoming text input changes with the given function.
  static TextInputFormatter withFunction(
    TextInputFormatFunction formatFunction,
  ) {
    return _SimpleTextInputFormatter(formatFunction);
  }
}

/// Function signature expected for creating custom [TextInputFormatter]
/// shorthands via [TextInputFormatter.withFunction].
typedef TextInputFormatFunction = TextEditingValue Function(
  TextEditingValue oldValue,
  TextEditingValue newValue,
);

/// Wiring for [TextInputFormatter.withFunction].
class _SimpleTextInputFormatter extends TextInputFormatter {
  _SimpleTextInputFormatter(this.formatFunction)
    : assert(formatFunction != null);

  final TextInputFormatFunction formatFunction;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return formatFunction(oldValue, newValue);
  }
}

/// A [TextInputFormatter] that prevents the insertion of characters matching
/// (or not matching) a particular pattern.
///
/// The [allow] parameter and the [filterPattern] parameter determine the
/// regions of banned patterns in the input string, while [formattingStrategy]
/// and [replacementString] determine how these regions should be updated.
///
/// By default, instances of filtered characters found in the new
/// [TextEditingValue]s will be replaced with the [replacementString] which
/// defaults to the empty string, and attempts to preserve the existing
/// [TextEditingValue.selection] as well as [TextEditingValue.composing] to
/// values it would now fall at with the removed characters. See
/// [formattingStrategy] for more details and how this behavior can be
/// overridden.
class FilteringTextInputFormatter extends TextInputFormatter {
  /// Creates a formatter that prevents the insertion of characters
  /// based on a filter pattern.
  ///
  /// If [allow] is true, then the filter pattern is an allow list,
  /// and characters must match the pattern to be accepted. See also
  /// the `FilteringTextInputFormatter.allow` constructor.
  // TODO(goderbauer): Cannot link to the constructor because of https://github.com/dart-lang/dartdoc/issues/2276.
  ///
  /// If [allow] is false, then the filter pattern is a deny list,
  /// and characters that match the pattern are rejected. See also
  /// the [FilteringTextInputFormatter.deny] constructor.
  ///
  /// The [filterPattern], [allow], [replacementString], and [formattingStrategy]
  /// arguments must not be null.
  FilteringTextInputFormatter(
    this.filterPattern, {
    required this.allow,
    this.replacementString = '',
    this.formattingStrategy = FilteringFormatterFormattingStrategy.preserveSelectionAndComposingRegion,
  })  : assert(filterPattern != null),
        assert(allow != null),
        assert(replacementString != null);

  /// Creates a formatter that only allows characters matching a pattern.
  ///
  /// The [filterPattern], [replacementString] and [formattingStrategy] arguments
  /// must not be null.
  FilteringTextInputFormatter.allow(
    this.filterPattern, {
    this.replacementString = '',
    this.formattingStrategy = FilteringFormatterFormattingStrategy.preserveSelectionAndComposingRegion,
  })  : assert(filterPattern != null),
        assert(replacementString != null),
        allow = true;

  /// Creates a formatter that blocks characters matching a pattern.
  ///
  /// The [filterPattern], [replacementString] and [formattingStrategy] arguments
  /// must not be null.
  FilteringTextInputFormatter.deny(
    this.filterPattern, {
    this.replacementString = '',
    this.formattingStrategy = FilteringFormatterFormattingStrategy.preserveSelectionAndComposingRegion,
  })  : assert(filterPattern != null),
        assert(replacementString != null),
        allow = false;

  /// A [Pattern] to match and replace in incoming [TextEditingValue]s.
  ///
  /// The behavior of the pattern depends on the [allow] property. If
  /// it is true, then this is an allow list, specifying a pattern that
  /// characters must match to be accepted. Otherwise, it is a deny list,
  /// specifying a pattern that characters must not match to be accepted.
  ///
  /// In general, the pattern should only match one character at a
  /// time. See the discussion at [replacementString].
  ///
  /// {@tool snippet}
  /// Typically the pattern is a regular expression, as in:
  ///
  /// ```dart
  /// FilteringTextInputFormatter onlyDigits = FilteringTextInputFormatter.allow(RegExp(r'[0-9]'));
  /// ```
  /// {@end-tool}
  ///
  /// {@tool snippet}
  /// If the pattern is a single character, a pattern consisting of a
  /// [String] can be used:
  ///
  /// ```dart
  /// FilteringTextInputFormatter noTabs = FilteringTextInputFormatter.deny('\t');
  /// ```
  /// {@end-tool}
  final Pattern filterPattern;

  /// Whether the pattern is an allow list or not.
  ///
  /// When true, [filterPattern] denotes an allow list: characters
  /// must match the filter to be allowed.
  ///
  /// When false, [filterPattern] denotes a deny list: characters
  /// that match the filter are disallowed.
  final bool allow;

  /// String used to replace banned patterns in the default
  /// [formattingStrategy].
  ///
  /// For deny lists ([allow] is false), each match of the
  /// [filterPattern] is replaced with this string. If [filterPattern]
  /// can match more than one character at a time, then this can
  /// result in multiple characters being replaced by a single
  /// instance of this [replacementString].
  ///
  /// For allow lists ([allow] is true), sequences between matches of
  /// [filterPattern] are replaced as one, regardless of the number of
  /// characters.
  ///
  /// For example, consider a [filterPattern] consisting of just the
  /// letter "o", applied to text field whose initial value is the
  /// string "Into The Woods", with the [replacementString] set to
  /// `*`.
  ///
  /// If [allow] is true, then the result will be "*o*oo*". Each
  /// sequence of characters not matching the pattern is replaced by
  /// its own single copy of the replacement string, regardless of how
  /// many characters are in that sequence.
  ///
  /// If [allow] is false, then the result will be "Int* the W**ds".
  /// Every matching sequence is replaced, and each "o" matches the
  /// pattern separately.
  ///
  /// If the pattern was the [RegExp] `o+`, the result would be the
  /// same in the case where [allow] is true, but in the case where
  /// [allow] is false, the result would be "Int* the W*ds" (with the
  /// two "o"s replaced by a single occurrence of the replacement
  /// string) because both of the "o"s would be matched simultaneously
  /// by the pattern.
  ///
  /// The default [formattingStrategy] also attempts to preserve the original
  /// selection and composing region.
  ///
  /// In the case of the "Into the Woods" example above, if [allow] is false,
  /// and the pattern is "the", and the selection is placed around "the":
  /// "Into |the| Woods", the format result would be "Into |*| Woods", the
  /// range of the selection would be the same as the pre-format text. Composing
  /// regions are handled exactly the same way.
  ///
  /// However, if an endpoint of the selection (or an endpoint of the composing
  /// range) is strictly within a banned pattern, that endpoint will be place at
  /// the end of the [replacementString] after formatting: if [allow] is false,
  /// and the pattern is still "the", the result of formatting
  /// "Into t|he |Woods" would be "Into *| |Woods". See [formattingStrategy] for
  /// how this behavior can be overridden.
  final String replacementString;

  /// Determines how to perform formatting, update the selection and the
  /// composing region, on each matched [filterPattern] in the input string, and
  /// the text regions that are between these matches.
  ///
  /// Once the formatter has split the input text into interleaving regions
  /// according to the [filterPattern] parameter, the [formattingStrategy] will
  /// be applied on each of these regions, in their logical order,  producing a
  /// final [TextEditingValue] output when all text regions are visited.
  ///
  /// The default [FilteringFormatterFormattingStrategy] is
  /// [FilteringFormatterFormattingStrategy.preserveSelectionAndComposingRegion],
  /// which replaces the text within every banned region with
  /// [replacementString], and updates the composing region and the selection
  /// accordingly so they do not fall within the removed regions.
  ///
  /// The framework also provides a
  /// [FilteringFormatterFormattingStrategy.preserveSelectionAndSkipComposingRegion]
  /// strategy, which keeps the content within the current composing region
  /// intact, and otherwise has the same behavior as the default
  /// [FilteringFormatterFormattingStrategy.preserveSelectionAndComposingRegion]
  /// strategy. With this strategy, a banned word will not be immediately
  /// replaced if it's currently being composed. Consider switching to this
  /// strategy if you're having duplicate input problems in a text field with a
  /// [FilteringTextInputFormatter].
  ///
  /// See the [FilteringFormatterFormattingStrategy] class documentation for
  /// how to implement a custom [FilteringFormatterFormattingStrategy].
  final FilteringFormatterFormattingStrategy formattingStrategy;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue, // unused.
    TextEditingValue newValue,
  ) {
    final Object formatState = formattingStrategy.prepareForNewInput(oldValue, newValue);

    final Iterable<Match> matches = filterPattern.allMatches(newValue.text);
    Match? previousMatch;
    for (final Match match in matches) {
      assert(match.end > match.start);
      // Compute the non-match region between this `Match` and the previous
      // `Match`. Depending on the value of `allow`, either the match region or
      // the non-match region is the banned pattern.
      //
      // The non-match region.
      formattingStrategy.processPattern(false, previousMatch?.end ?? 0, match.start, this, formatState);
      // The match region.
      formattingStrategy.processPattern(true, match.start, match.end, this, formatState);

      previousMatch = match;
    }

    // Handle the last non-match region betwee the last match region and the end
    // of the text.
    formattingStrategy.processPattern(false, previousMatch?.end ?? 0, newValue.text.length, this, formatState);
    return formattingStrategy.finalize(formatState);
  }

  /// A [TextInputFormatter] that forces input to be a single line.
  static final TextInputFormatter singleLineFormatter = FilteringTextInputFormatter.deny('\n');

  /// A [TextInputFormatter] that takes in digits `[0-9]` only.
  static final TextInputFormatter digitsOnly = FilteringTextInputFormatter.allow(RegExp(r'[0-9]'));
}

/// An interface for performing formatting operations on matched patterns, and
/// text between each matched patterns, in the input text of a
/// [FilteringTextInputFormatter].
///
/// Every [FilteringTextInputFormatter] has a
/// [FilteringFormatterFormattingStrategy]. Upon user input, the
/// [FilteringTextInputFormatter] calls [prepareForNewInput] to produce a
/// formatting state object for the current input, and splits the new content of
/// the text field into interleaving text regions that match and does not match
/// [FilteringTextInputFormatter.filterPattern]. Each of these regions will be
/// processed by the [processPattern] method in their logical order, to update
/// the formatting state object. After the last region has been processed, the
/// [FilteringTextInputFormatter] calls [finalize] to produce the final
/// [TextEditingValue] that the [FilteringTextInputFormatter] will use as its
/// output.
///
/// ### Tips for Implementing a Custom `FilteringFormatterFormattingStrategy`
///
/// A [FilteringFormatterFormattingStrategy] is typically stateless itself, and
/// stores the states needed for performing the formatting action in a state
/// object, which should be created by the [prepareForNewInput] method.
///
/// In each [processPattern] call, there're typically 3 things in the state
/// object that may need updating: the text, the selection, and the composing
/// region. That is to say, each state object should typically contain at least
/// as much information as a [TextEditingValue], and is usually mutable so it
/// can be updated in-place.
///
/// For concatenating strings efficiently in the state object, a [StringBuffer]
/// should be used to append each formatted text regions, in favor of the
/// [String.+] operator.
abstract class FilteringFormatterFormattingStrategy {
  /// A [FilteringFormatterFormattingStrategy] that removes all banned patterns,
  /// and attempts to preserve the pre-format selection and composing region as
  /// much as possible.
  ///
  /// If the start index or the end index of the selection (or the composing
  /// region) is strictly inside a banned pattern described by `regionStart` and
  /// `regionEnd` (meaning, `regionStart` < index < `regionEndj), the index will
  /// be placed at the end of the replacement string.
  static const FilteringFormatterFormattingStrategy preserveSelectionAndComposingRegion = _PreserveSelectionAndComposingRegion();

  /// A [FilteringFormatterFormattingStrategy] that does not remove a banned
  /// word immediately if part of word is still being composed, and has the same
  /// behavior as [preserveSelectionAndComposingRegion] otherwise.
  ///
  /// This strategy guaratees the [FilteringTextInputFormatter] will never
  /// change the content of the current non-empty composing text region, and
  /// also preserves the pre-format selection as much as possible.
  ///
  /// This is generally more robust than the default strategy for most input
  /// methods. Many input methods only expect composing region changes from the
  /// user, but not from the text editor. Removing or replacing text from within
  /// the composing region may result in duplicated input. The default CJK input
  /// method on iOS 14.2 and many Android IMEs are known to have this problem.
  static const FilteringFormatterFormattingStrategy preserveSelectionAndSkipComposingRegion = _PreserveSelectionAndSkipComposingRegion();

  /// Creates a formatting state object necessary for performing the
  /// formatting logic described by this [FilteringFormatterFormattingStrategy].
  ///
  /// This method should typically return a new state object every time. The
  /// returned state object will later be passed to the [processPattern],
  /// and [finalize].
  Object prepareForNewInput(TextEditingValue oldValue, TextEditingValue newValue);

  /// Processes the given text region and updates the given formatting state
  /// object accordingly.
  ///
  /// The `isMatch` parameter indicates whether the given text region matches
  /// the `formatter`'s `filterPattern`.
  ///
  /// `regionStart` (inclusive) and `regionEnd` (exclusive) represent the
  /// half-open range of the text region being processed, within the original
  /// input text. The value of the `regionStart` parameter is always less than
  /// or equal to that of `regionEnd`.
  ///
  /// The `formatter` parameter is the [FilteringTextInputFormatter] that's
  /// currently performing the formatting action and the caller of this method.
  ///
  /// The `formattingState` is the formatting state object created by a previous
  /// [prepareForNewInput] call. Typically the state object is mutable, and is
  /// updated in-place in each [processPattern] call.
  void processPattern(bool isMatch, int regionStart, int regionEnd, FilteringTextInputFormatter formatter, covariant Object formattingState);

  /// Finishes the current formatting operation, and converts the formatting
  /// state object created by [prepareForNewInput] to a [TextEditingValue] as
  /// the formatter output.
  TextEditingValue finalize(covariant Object formattingState);
}

/// A `FilteringFormatterFormattingStrategy` class for creating
/// `FilteringFormatterFormattingStrategy.preserveSelectionAndComposingRegion`
class _PreserveSelectionAndComposingRegion implements FilteringFormatterFormattingStrategy {
  const _PreserveSelectionAndComposingRegion();

  @override
  _TextEditingValueAccumulator prepareForNewInput(TextEditingValue oldValue, TextEditingValue newValue) => _TextEditingValueAccumulator(newValue);

  @override
  void processPattern(bool isMatch, int regionStart, int regionEnd, FilteringTextInputFormatter formatter, _TextEditingValueAccumulator formattingState) {
    assert(!formattingState.debugFinalized);
    if (formatter.allow == isMatch) {
      _processAllowedPattern(regionStart, regionEnd, formatter, formattingState);
    } else {
      _processBannedPattern(regionStart, regionEnd, formatter, formattingState);
    }
    assert(!formattingState.debugFinalized);
  }

  void _processAllowedPattern(int regionStart, int regionEnd, FilteringTextInputFormatter formatter, _TextEditingValueAccumulator formattingState) {
    formattingState.stringBuffer.write(formattingState.originalText.substring(regionStart, regionEnd));
  }

  void _processBannedPattern(int regionStart, int regionEnd, FilteringTextInputFormatter formatter, _TextEditingValueAccumulator formattingState) {
    assert(regionEnd >= regionStart);

    // Nothing to do if the region is empty.
    if (regionEnd == regionStart) {
      return;
    }

    // Replace the text with replacementString.
    formattingState.stringBuffer.write(formatter.replacementString);

    // Now adjust the selection and the composing region.

    final _MutableTextRange<TextSelection>? selection = formattingState.selection;
    final _MutableTextRange<TextRange>? composingRegion = formattingState.composingRegion;

    final int replacementLength = formatter.replacementString.length;
    if (composingRegion != null) {
      // All 4 indices are adjusted to account for the string replacement,
      // following the same logic below:
      //
      // - If the index precedes the replace region (i.e., before
      //   [regionStart, regionEnd)), the index does not require adjustment.
      // - Otherwise, add jreplacementLenght` to the index to account for the
      //   replacement text (we're placing the index **after** the replacement
      //   text), and subtract the length of substring within
      //   [regionStart, regionEnd), that's also before the index.
      composingRegion.base += regionStart >= composingRegion.originalRange.start
          ? 0
          : replacementLength - (math.min(composingRegion.originalRange.start, regionEnd) - regionStart);

      composingRegion.extent += regionStart >= composingRegion.originalRange.end
          ? 0
          : replacementLength - (math.min(composingRegion.originalRange.end, regionEnd) - regionStart);
    }
    if (selection != null) {
      selection.base += regionStart >= selection.originalRange.baseOffset
          ? 0
          : replacementLength - (math.min(selection.originalRange.baseOffset, regionEnd) - regionStart);

      selection.extent += regionStart >= selection.originalRange.extentOffset
          ? 0
          : replacementLength - (math.min(selection.originalRange.extentOffset, regionEnd) - regionStart);
    }
  }

  @override
  TextEditingValue finalize(_TextEditingValueAccumulator formattingState) {
    assert(!formattingState.debugFinalized);
    final TextEditingValue result = formattingState.finalize();
    assert(formattingState.debugFinalized);
    return result;
  }
}

// A [FilteringFormatterFormattingStrategy] class for creating
// [FilteringFormatterFormattingStrategy.preserveSelectionAndSkipComposingRegion].
//
// This is generally more robust than [_PreserveSelectionAndComposingRegion],
// See https://github.com/flutter/flutter/issues/79844 for more details.
class _PreserveSelectionAndSkipComposingRegion extends _PreserveSelectionAndComposingRegion {
  const _PreserveSelectionAndSkipComposingRegion();
  @override
  void _processBannedPattern(int regionStart, int regionEnd, FilteringTextInputFormatter formatter, _TextEditingValueAccumulator formattingState) {
    final TextRange? composingRegion = formattingState.composingRegion?.originalRange;
    assert(
      composingRegion == null || composingRegion.isNormalized,
      'The composing region $composingRegion should be normalized',
    );
    if (composingRegion == null || regionEnd <= composingRegion.start || regionStart >= composingRegion.end) {
      super._processBannedPattern(regionStart, regionEnd, formatter, formattingState);
    } else {
      _processAllowedPattern(regionStart, regionEnd, formatter, formattingState);
    }
  }
}

// A mutable, half-open range [`base`, `extent`) within a string.
//
// The [FilteringFormatterFormattingStrategy] is responsible for providing a
// [MutableTextRange] that has its [base] and [extent] initialized to the
// composing region or the selection's base offset and extent offset.
class _MutableTextRange<T extends TextRange> {
  _MutableTextRange(this.base, this.extent, this.originalRange);

  static _MutableTextRange<TextRange>? fromComposingRange(TextRange range) {
    return range.isValid && !range.isCollapsed
        ? _MutableTextRange<TextRange>(range.start, range.end, range)
        : null;
  }

  static _MutableTextRange<TextSelection>? fromTextSelection(
      TextSelection selection) {
    return selection.isValid
        ? _MutableTextRange<TextSelection>(selection.baseOffset, selection.extentOffset, selection)
        : null;
  }

  /// The start index of the range, inclusive.
  ///
  /// The value of [base] should always be greater than or equal to 0, and can
  /// be larger than, smaller than, or equal to [extent].
  int base;

  /// The end index of the range, exclusive.
  ///
  /// The value of [extent] should always be greater than or equal to 0, and can
  /// be larger than, smaller than, or equal to [base].
  int extent;

  /// The immutable, pre-format [TextRange] that was used to initialize the
  /// [base] and the [extent] of this object.
  final T originalRange;
}

// The intermediate state of a [FilteringFormatterFormattingStrategy] when it's
// formatting a new user input.
//
// This class is used to perform text replacement and update the composing
// region or the selected region in a [FilteringFormatterFormattingStrategy].
class _TextEditingValueAccumulator {
  _TextEditingValueAccumulator(TextEditingValue textEditingValue)
    : selection = _MutableTextRange.fromTextSelection(textEditingValue.selection),
      composingRegion = _MutableTextRange.fromComposingRange(textEditingValue.composing),
      originalText = textEditingValue.text;

  /// The pre-format string that was sent to the [FilteringTextInputFormatter]
  /// as input.
  final String originalText;

  /// The [StringBuffer] that contains the string which has already been
  /// formatted.
  ///
  /// In a [FilteringFormatterFormattingStrategy], typically the replacement
  /// string, instead of the original string within the given range, is written
  /// to this [StringBuffer].
  final StringBuffer stringBuffer = StringBuffer();

  /// The updated selection, as well as the original selection from the input
  /// [TextEditingValue] of the [FilteringTextInputFormatter].
  ///
  /// This parameter will be null if the input [TextEditingValue.selection] is
  /// invalid.
  final _MutableTextRange<TextSelection>? selection;

  /// The updated composing region, as well as the original composing region
  /// from the input [TextEditingValue] of the [FilteringTextInputFormatter].
  ///
  /// This parameter will be null if the input [TextEditingValue.composing] is
  /// invalid or collapsed.
  final _MutableTextRange<TextRange>? composingRegion;

  // Whether this state object has reached its end-of-life.
  bool debugFinalized = false;

  TextEditingValue finalize() {
    debugFinalized = true;
    final _MutableTextRange<TextSelection>? selection = this.selection;
    final _MutableTextRange<TextRange>? composingRegion = this.composingRegion;
    return TextEditingValue(
      text: stringBuffer.toString(),
      composing: composingRegion == null || composingRegion.base == composingRegion.extent
          ? TextRange.empty
          : TextRange(start: composingRegion.base, end: composingRegion.extent),
      // The selection affinity is downstream.
      selection: selection == null
          ? const TextSelection.collapsed(offset: -1)
          : TextSelection(baseOffset: selection.base, extentOffset: selection.extent),
    );
  }
}

/// Old name for [FilteringTextInputFormatter.deny].
@Deprecated(
  'Use FilteringTextInputFormatter.deny instead. '
  'This feature was deprecated after v1.20.0-1.0.pre.',
)
class BlacklistingTextInputFormatter extends FilteringTextInputFormatter {
  /// Old name for [FilteringTextInputFormatter.deny].
  @Deprecated(
    'Use FilteringTextInputFormatter.deny instead. '
    'This feature was deprecated after v1.20.0-1.0.pre.',
  )
  BlacklistingTextInputFormatter(
    Pattern blacklistedPattern, {
    String replacementString = '',
  }) : super.deny(blacklistedPattern, replacementString: replacementString);

  /// Old name for [filterPattern].
  @Deprecated(
    'Use filterPattern instead. '
    'This feature was deprecated after v1.20.0-1.0.pre.',
  )
  Pattern get blacklistedPattern => filterPattern;

  /// Old name for [FilteringTextInputFormatter.singleLineFormatter].
  @Deprecated(
    'Use FilteringTextInputFormatter.singleLineFormatter instead. '
    'This feature was deprecated after v1.20.0-1.0.pre.',
  )
  static final BlacklistingTextInputFormatter singleLineFormatter
      = BlacklistingTextInputFormatter(RegExp(r'\n'));
}

/// Old name for [FilteringTextInputFormatter.allow].
@Deprecated(
  'Use FilteringTextInputFormatter.allow instead. '
  'This feature was deprecated after v1.20.0-1.0.pre.',
)
class WhitelistingTextInputFormatter extends FilteringTextInputFormatter {
  /// Old name for [FilteringTextInputFormatter.allow].
  @Deprecated(
    'Use FilteringTextInputFormatter.allow instead. '
    'This feature was deprecated after v1.20.0-1.0.pre.',
  )
  WhitelistingTextInputFormatter(Pattern whitelistedPattern)
    : assert(whitelistedPattern != null),
      super.allow(whitelistedPattern);

  /// Old name for [filterPattern].
  @Deprecated(
    'Use filterPattern instead. '
    'This feature was deprecated after v1.20.0-1.0.pre.',
  )
  Pattern get whitelistedPattern => filterPattern;

  /// Old name for [FilteringTextInputFormatter.digitsOnly].
  @Deprecated(
    'Use FilteringTextInputFormatter.digitsOnly instead. '
    'This feature was deprecated after v1.20.0-1.0.pre.',
  )
  static final WhitelistingTextInputFormatter digitsOnly
      = WhitelistingTextInputFormatter(RegExp(r'\d+'));
}

/// A [TextInputFormatter] that prevents the insertion of more characters
/// than allowed.
///
/// Since this formatter only prevents new characters from being added to the
/// text, it preserves the existing [TextEditingValue.selection].
///
/// Characters are counted as user-perceived characters using the
/// [characters](https://pub.dev/packages/characters) package, so even complex
/// characters like extended grapheme clusters and surrogate pairs are counted
/// as single characters.
///
/// See also:
///  * [maxLength], which discusses the precise meaning of "number of
///    characters".
class LengthLimitingTextInputFormatter extends TextInputFormatter {
  /// Creates a formatter that prevents the insertion of more characters than a
  /// limit.
  ///
  /// The [maxLength] must be null, -1 or greater than zero. If it is null or -1
  /// then no limit is enforced.
  LengthLimitingTextInputFormatter(
    this.maxLength, {
    this.maxLengthEnforcement,
  }) : assert(maxLength == null || maxLength == -1 || maxLength > 0);

  /// The limit on the number of user-perceived characters that this formatter
  /// will allow.
  ///
  /// The value must be null or greater than zero. If it is null or -1, then no
  /// limit is enforced.
  ///
  /// {@template flutter.services.lengthLimitingTextInputFormatter.maxLength}
  /// ## Characters
  ///
  /// For a specific definition of what is considered a character, see the
  /// [characters](https://pub.dev/packages/characters) package on Pub, which is
  /// what Flutter uses to delineate characters. In general, even complex
  /// characters like surrogate pairs and extended grapheme clusters are
  /// correctly interpreted by Flutter as each being a single user-perceived
  /// character.
  ///
  /// For instance, the character "ö" can be represented as '\u{006F}\u{0308}',
  /// which is the letter "o" followed by a composed diaeresis "¨", or it can
  /// be represented as '\u{00F6}', which is the Unicode scalar value "LATIN
  /// SMALL LETTER O WITH DIAERESIS". It will be counted as a single character
  /// in both cases.
  ///
  /// Similarly, some emoji are represented by multiple scalar values. The
  /// Unicode "THUMBS UP SIGN + MEDIUM SKIN TONE MODIFIER", "👍🏽"is counted as
  /// a single character, even though it is a combination of two Unicode scalar
  /// values, '\u{1F44D}\u{1F3FD}'.
  /// {@endtemplate}
  ///
  /// ### Composing text behaviors
  ///
  /// There is no guarantee for the final value before the composing ends.
  /// So while the value is composing, the constraint of [maxLength] will be
  /// temporary lifted until the composing ends.
  ///
  /// In addition, if the current value already reached the [maxLength],
  /// composing is not allowed.
  final int? maxLength;

  /// Determines how the [maxLength] limit should be enforced.
  ///
  /// Defaults to [MaxLengthEnforcement.enforced].
  ///
  /// {@macro flutter.services.textFormatter.maxLengthEnforcement}
  final MaxLengthEnforcement? maxLengthEnforcement;

  /// Returns a [MaxLengthEnforcement] that follows the specified [platform]'s
  /// convention.
  ///
  /// {@template flutter.services.textFormatter.effectiveMaxLengthEnforcement}
  /// ### Platform specific behaviors
  ///
  /// Different platforms follow different behaviors by default, according to
  /// their native behavior.
  ///  * Android, Windows: [MaxLengthEnforcement.enforced]. The native behavior
  ///    of these platforms is enforced. The composing will be handled by the
  ///    IME while users are entering CJK characters.
  ///  * iOS: [MaxLengthEnforcement.truncateAfterCompositionEnds]. iOS has no
  ///    default behavior and it requires users implement the behavior
  ///    themselves. Allow the composition to exceed to avoid breaking CJK input.
  ///  * Web, macOS, linux, fuchsia:
  ///    [MaxLengthEnforcement.truncateAfterCompositionEnds]. These platforms
  ///    allow the composition to exceed by default.
  /// {@endtemplate}
  static MaxLengthEnforcement getDefaultMaxLengthEnforcement([
    TargetPlatform? platform,
  ]) {
    if (kIsWeb) {
      return MaxLengthEnforcement.truncateAfterCompositionEnds;
    } else {
      switch (platform ?? defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.windows:
          return MaxLengthEnforcement.enforced;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
        case TargetPlatform.linux:
        case TargetPlatform.fuchsia:
          return MaxLengthEnforcement.truncateAfterCompositionEnds;
      }
    }
  }

  /// Truncate the given TextEditingValue to maxLength user-perceived
  /// characters.
  ///
  /// See also:
  ///  * [Dart's characters package](https://pub.dev/packages/characters).
  ///  * [Dart's documentation on runes and grapheme clusters](https://dart.dev/guides/language/language-tour#runes-and-grapheme-clusters).
  @visibleForTesting
  static TextEditingValue truncate(TextEditingValue value, int maxLength) {
    final CharacterRange iterator = CharacterRange(value.text);
    if (value.text.characters.length > maxLength) {
      iterator.expandNext(maxLength);
    }
    final String truncated = iterator.current;

    return TextEditingValue(
      text: truncated,
      selection: value.selection.copyWith(
        baseOffset: math.min(value.selection.start, truncated.length),
        extentOffset: math.min(value.selection.end, truncated.length),
      ),
      composing: !value.composing.isCollapsed && truncated.length > value.composing.start
        ? TextRange(
            start: value.composing.start,
            end: math.min(value.composing.end, truncated.length),
          )
        : TextRange.empty,
    );
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final int? maxLength = this.maxLength;

    if (maxLength == null ||
      maxLength == -1 ||
      newValue.text.characters.length <= maxLength) {
      return newValue;
    }

    assert(maxLength > 0);

    switch (maxLengthEnforcement ?? getDefaultMaxLengthEnforcement()) {
      case MaxLengthEnforcement.none:
        return newValue;
      case MaxLengthEnforcement.enforced:
        // If already at the maximum and tried to enter even more, and has no
        // selection, keep the old value.
        if (oldValue.text.characters.length == maxLength && oldValue.selection.isCollapsed) {
          return oldValue;
        }

        // Enforced to return a truncated value.
        return truncate(newValue, maxLength);
      case MaxLengthEnforcement.truncateAfterCompositionEnds:
        // If already at the maximum and tried to enter even more, and the old
        // value is not composing, keep the old value.
        if (oldValue.text.characters.length == maxLength &&
          !oldValue.composing.isValid) {
          return oldValue;
        }

        // Temporarily exempt `newValue` from the maxLength limit if it has a
        // composing text going and no enforcement to the composing value, until
        // the composing is finished.
        if (newValue.composing.isValid) {
          return newValue;
        }

        return truncate(newValue, maxLength);
    }
  }
}
