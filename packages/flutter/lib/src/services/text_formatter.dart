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
/// {@template flutter.services.FilteringTextInputFormatter.filtering}
/// The [filterPattern] parameter splits the input text into interleaving
/// matching and non-matching regions. Some non-matching regions can be emtpy,
/// when they're between 2 consecutive matches.
///
/// The [allow] parameter determines which of these regions should be banned:
/// when [allow] is true, matched regions are kept, and non-matching regions
/// between them are banned. When [allow] is false, non-matching regions are
/// kept and matched regions are banned.
///
/// The [formattingStrategy] parameter will then be applied on each banned
/// region, in their logical order, deciding whether and how the banned words
/// should be replaced. See the [FilteringFormatterFormattingStrategy] class for
/// a list of provided strategies, and how to make custom strategies.
/// {@endtemplate}
///
/// The default constructor, as well as its `FilteringTextInputFormatter.allow`
/// and the `FilteringTextInputFormatter.deny` variants, uses the
/// [FilteringFormatterFormattingStrategy.preserveSelectionAndComposingRegion]
/// strategy with a user-supplied `replacementString`. This means they replace
/// each of the non-empty banned patterns in the input text with the
/// `replacementString`, and move any endpoint of the selection or the composing
/// region to the end of the `replacementString` if it was inside a banned
/// pattern.
///
/// Oftentimes input methods don't expect composing regions changes from text
/// editors. Consider switching to the
/// [FilteringFormatterFormattingStrategy.preserveSelectionAndSkipComposingRegion]
/// strategy if some input methods behave strangely with this input filter, such
/// as having duplicate input. See [TextEditingValue.composing] and
/// [FilteringFormatterFormattingStrategy.preserveSelectionAndSkipComposingRegion]
/// for more details.
class FilteringTextInputFormatter extends TextInputFormatter {
  /// Creates a formatter that prevents the insertion of characters based on a
  /// filter pattern.
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
  /// Instances of filtered characters found in the new [TextEditingValue]s will
  /// be replaced with the `replacementString` which defaults to the empty
  /// string, and attempts to preserve the existing [TextEditingValue.selection]
  /// as well as [TextEditingValue.composing] to values it would now fall at
  /// with the removed characters.
  ///
  /// The [filterPattern], [allow], and `replacementString` arguments must not
  /// be null.
  FilteringTextInputFormatter(
    Pattern filterPattern, {
    required bool allow,
    String replacementString = '',
  })  : this.withFormattingStrategy(
          filterPattern,
          allow: allow,
          formattingStrategy: FilteringFormatterFormattingStrategy.preserveSelectionAndComposingRegion(
            replacementStringBuilder: (TextRange bannedRange) => bannedRange.isCollapsed ? '' : replacementString,
          ),
        );

  /// Creates a formatter that only allows characters matching a pattern.
  ///
  /// The [filterPattern] and `replacementString` arguments must not be null.
  FilteringTextInputFormatter.allow(
    Pattern filterPattern, {
    String replacementString = '',
  })  : this(filterPattern, allow: true, replacementString: replacementString);

  /// Creates a formatter that blocks characters matching a pattern.
  ///
  /// The [filterPattern], `replacementString` arguments must not be null.
  FilteringTextInputFormatter.deny(
    Pattern filterPattern, {
    String replacementString = '',
  })  : this(filterPattern, allow: false, replacementString: replacementString);

  /// Creates a formatter that applies a custom
  /// [FilteringFormatterFormattingStrategy] on each banned pattern in the input
  /// string. A banned pattern is a piece of text in the input string that
  /// matches the [filterPattern] if [allow] is false, or the text surrounded by
  /// matching patterns if [allow] is true.
  ///
  /// The [filterPattern], [allow] and [formattingStrategy] arguments must not
  /// be null.
  FilteringTextInputFormatter.withFormattingStrategy(
    this.filterPattern, {
    required this.allow,
    required this.formattingStrategy,
  });

  /// A [TextInputFormatter] that forces input to be a single line.
  static final TextInputFormatter singleLineFormatter = FilteringTextInputFormatter.deny('\n');

  /// A [TextInputFormatter] that takes in digits `[0-9]` only.
  static final TextInputFormatter digitsOnly = FilteringTextInputFormatter.allow(RegExp(r'[0-9]'));

  /// A [Pattern] to match or replace in incoming [TextEditingValue]s.
  ///
  /// The behavior of the pattern depends on the [allow] property. If
  /// it is true, then this is an allow list, specifying a pattern that
  /// characters must match to be accepted. Otherwise, it is a deny list,
  /// specifying a pattern that characters must not match to be accepted.
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

  /// Determines how to format, update the selection and the composing region,
  /// on each banned pattern within the input text.
  ///
  /// {@macro flutter.services.FilteringTextInputFormatter.filtering}
  ///
  /// ### The Default Behavior
  ///
  /// The default [FilteringFormatterFormattingStrategy] is a
  /// [FilteringFormatterFormattingStrategy.preserveSelectionAndComposingRegion]
  /// strategy which replaces the text within every banned region with a
  /// (potentially empty) replacement string, and updates the composing region
  /// and the selection accordingly so they do not fall within the removed
  /// regions.
  ///
  /// For deny lists ([allow] is false), the default strategy replaces each
  /// match of the [filterPattern] with the `replacementString`. If
  /// [filterPattern] can match more than one character at a time, then this can
  /// result in multiple characters being replaced by a single instance of the
  /// `replacementString`.
  ///
  /// For allow lists ([FilteringTextInputFormatter.allow] is true), sequences
  /// between matches of `filterPattern` are replaced as one, regardless of the
  /// number of characters.
  ///
  /// For example, consider a `filterPattern` consisting of just the
  /// letter "o", applied to text field whose initial value is the
  /// string "Into The Woods", with the `replacementString` set to
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
  /// same in the case where `allow` is true, but in the case where
  /// `allow` is false, the result would be "Int* the W*ds" (with the
  /// two "o"s replaced by a single occurrence of the replacement
  /// string) because both of the "o"s would be matched simultaneously
  /// by the pattern.
  ///
  /// {@tool snippet}
  /// You can also configure
  /// [FilteringFormatterFormattingStrategy.preserveSelectionAndComposingRegion]
  /// to use different replacement strings for different banned regions. For
  /// instance, to replace each character in banned patterns with an asterisk:
  ///
  /// ```dart
  /// FilteringTextInputFormatter.withFormattingStrategy(
  ///   'bad',
  ///   allow: false,
  ///   formattingStrategy: FilteringFormatterFormattingStrategy.preserveSelectionAndComposingRegion(
  ///     replacementStringBuilder: (TextRange bannedRange) => '*' * (bannedRange.end - bannedRange.start),
  ///   ),
  /// )
  /// ```
  /// {@end-tool}
  ///
  /// [FilteringFormatterFormattingStrategy.preserveSelectionAndComposingRegion]
  /// attempts to preserve the original selection and composing region as much
  /// as possible. In the case of the "Into the Woods" example above, if [allow]
  /// is false, and the pattern is "the", and the selection is placed around
  /// "the": "Into |the| Woods", the format result would be "Into |*| Woods".
  /// Composing regions are handled exactly the same way.
  ///
  /// However, if an endpoint of the selection (or an endpoint of the composing
  /// range) is strictly within a banned pattern, that endpoint will be place at
  /// the end of the `replacementString` after formatting: if [allow] is false,
  /// and the pattern is still "the", the result of formatting
  /// "Into t|he |Woods" would be "Into *| |Woods".
  ///
  /// ### Skip Formatting the Composing Region
  ///
  /// The
  /// [FilteringFormatterFormattingStrategy.preserveSelectionAndSkipComposingRegion]
  /// strategy keeps the content within the current composing region untouched, and
  /// otherwise has the same behavior as the default
  /// [FilteringFormatterFormattingStrategy.preserveSelectionAndComposingRegion]
  /// strategy. With this strategy, a banned word will not be immediately
  /// replaced if it's currently being composed. **Consider switching to this
  /// strategy if you're having duplicate input problems, or seeing other
  /// strange input method interactions in a text field.**
  ///
  /// See also:
  ///  * [FilteringFormatterFormattingStrategy], an interface for implementing
  ///    a custom [formattingStrategy].
  ///  * [TextEditingValue.composing], for best practices regarding handling the
  ///    composing region.
  final FilteringFormatterFormattingStrategy formattingStrategy;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue, // unused.
    TextEditingValue newValue,
  ) {
    final _TextEditingValueAccumulator formatState = _TextEditingValueAccumulator(newValue);
    assert(!formatState.debugFinalized);

    final Iterable<Match> matches = filterPattern.allMatches(newValue.text);
    Match? previousMatch;
    for (final Match match in matches) {
      assert(match.end > match.start);
      // Compute the non-match region between this `Match` and the previous
      // `Match`. Depending on the value of `allow`, either the match region or
      // the non-match region is the banned pattern.
      //
      // The non-matching region.
      _processRegion(allow, previousMatch?.end ?? 0, match.start, formatState, formattingStrategy);
      assert(!formatState.debugFinalized);
      // The matched region.
      _processRegion(!allow, match.start, match.end, formatState, formattingStrategy);
      assert(!formatState.debugFinalized);

      previousMatch = match;
    }

    // Handle the last non-matching region betwee the last match region and the
    // end of the text.
    _processRegion(allow, previousMatch?.end ?? 0, newValue.text.length, formatState, formattingStrategy);
    assert(!formatState.debugFinalized);
    return formatState.finalize();
  }

  void _processRegion(bool isBannedRegion, int regionStart, int regionEnd, _TextEditingValueAccumulator state, FilteringFormatterFormattingStrategy strategy) {
    if (isBannedRegion) {
      final TextRange bannedRange = TextRange(start: regionStart, end: regionEnd);
      final TextEditingValueAdjustments update = strategy.processBannedPattern(bannedRange, state.inputValue);
      update._debugAssertOOB(bannedRange);
      state.stringBuffer.write(update.replacementString ?? bannedRange.textInside(state.inputValue.text));
      state.selection?.base += update.selectionBaseOffsetAdjustment;
      state.selection?.extent += update.selectionExtentOffsetAdjustment;
      state.composingRegion?.base += update.composingStartAdjustment;
      state.composingRegion?.extent += update.composingEndAdjustment;
    } else {
      state.stringBuffer.write(state.inputValue.text.substring(regionStart, regionEnd));
    }
  }

}

/// An immutable data structure that specifies what adjustments to make to a
/// [TextEditingValue].
///
/// This class is used by
/// [FilteringFormatterFormattingStrategy.processBannedPattern] implementations
/// to describes the changes needed for a given banned [TextRange] in the
/// [TextEditingValue].
///
/// To indicate no adjustments should to be applied to the given banned
/// [TextRange] (despite it contains the banned pattern), use
/// [TextEditingValueAdjustments.noAdjustments].
class TextEditingValueAdjustments {
  /// Creates a [TextEditingValueAdjustments].
  const TextEditingValueAdjustments({
    required String replacementString,
    int composingStartAdjustment = 0,
    int composingEndAdjustment = 0,
    int selectionBaseOffsetAdjustment = 0,
    int selectionExtentOffsetAdjustment = 0,
  }) : this._(
    replacementString: replacementString,
    composingStartAdjustment: composingStartAdjustment,
    composingEndAdjustment: composingEndAdjustment,
    selectionBaseOffsetAdjustment: selectionBaseOffsetAdjustment,
    selectionExtentOffsetAdjustment: selectionExtentOffsetAdjustment,
  );

  const TextEditingValueAdjustments._({
    this.replacementString,
    this.composingStartAdjustment = 0,
    this.composingEndAdjustment = 0,
    this.selectionBaseOffsetAdjustment = 0,
    this.selectionExtentOffsetAdjustment = 0,
  });

  /// A [TextEditingValueAdjustments] that represents no adjustments should to
  /// be made to a banned [TextRange], despite it matches the banned pattern.
  static const TextEditingValueAdjustments noAdjustments = TextEditingValueAdjustments._();

  /// The text to replace the banned pattern.
  ///
  /// When [replacementString] is the empty string, the banned pattern will be
  /// entirely removed.
  ///
  /// When [replacementString] is null, the original text within the
  /// `bannedRange` will be used. See the [noAdjustments] constant.
  final String? replacementString;

  /// The int value to add to the [TextEditingValue.composing]'s start offset.
  ///
  /// {@template flutter.services.TextEditingValueSegment.offsetAdjustments}
  /// When text is removed or replaced in a given [TextRange], adjustments must
  /// be made to offsets that represent locations in the original text, for
  /// these offsets to represent the same locations in the changed text. For
  /// [FilteringFormatterFormattingStrategy.processBannedPattern], the exact
  /// adjustment value typically depends on the original offset's relative
  /// position within the `bannedRange` argument:
  ///
  ///  * If the original offset is before the given `bannedRange`, this should
  ///    typically be 0, since adding or removing text after a location in the
  ///    orignal text does not change the offset of that location.
  ///  * If the original offset is after the given `bannedRange`, this should
  ///    typically be the length difference between the [replacementString] and
  ///    the banned pattern.
  ///  * If the original offset is within the given `bannedRange`, the
  ///    adjustment should be the length of the [replacementString] that comes
  ///    before the new text location (it's up to you whether the endpoint
  ///    should be placed before the [replacementString], after the
  ///    [replacementString], or somewhere in between), and the length of the
  ///    part of the removed pattern before the original offset.
  /// {@endtemplate}
  final int composingStartAdjustment;
  /// The int value to add to the [TextEditingValue.composing]'s end offset.
  ///
  /// {@macro flutter.services.TextEditingValueSegment.offsetAdjustments}
  final int composingEndAdjustment;

  /// The int value to add to the [TextEditingValue.selection]'s `baseOffset`.
  ///
  /// {@macro flutter.services.TextEditingValueSegment.offsetAdjustments}
  final int selectionBaseOffsetAdjustment;
  /// The int value to add to the [TextEditingValue.selection]'s `extentOffset`.
  ///
  /// {@macro flutter.services.TextEditingValueSegment.offsetAdjustments}
  final int selectionExtentOffsetAdjustment;

  void _debugAssertOOB(TextRange bannedRegion) {
    assert(() {
      final String? replacementString = this.replacementString;
      if (replacementString == null) {
        return true;
      }
      final int lowerBound = bannedRegion.start - bannedRegion.end;
      final int upperBound = replacementString.length;

      void assertOOB(int index, String name) {
        if (index < lowerBound || index > upperBound) {
          throw FlutterError(
            '$name out of bounds: expect a value in [$lowerBound, $upperBound], but got $index. $replacementString, $bannedRegion',
          );
        }
      }

      assertOOB(composingStartAdjustment, 'composingStartAdjustment');
      assertOOB(composingEndAdjustment, 'composingEndAdjustment');
      assertOOB(selectionBaseOffsetAdjustment, 'selectionBaseOffsetAdjustment');
      assertOOB(selectionExtentOffsetAdjustment, 'selectionExtentOffsetAdjustment');
      return true;
    }());
  }
}

/// An interface for performing formatting operations on banned patterns within
/// the input text of a [FilteringTextInputFormatter].
///
/// A [FilteringTextInputFormatter] splits the input text into interleaving
/// allowed and banned regions, and applie its
/// [FilteringTextInputFormatter.formattingStrategy] on each banned region, in
/// their logical order, deciding whether and how each banned region should be
/// replaced.
abstract class FilteringFormatterFormattingStrategy {
  /// A [FilteringFormatterFormattingStrategy] that removes all banned patterns,
  /// replacing them with a replacement String built by the
  /// `replacementStringBuilder`, and attempts to
  /// preserve the pre-format selection and composing region as much as
  /// possible.
  ///
  /// If the start offset or the end offset of the selection (or the composing
  /// region) is strictly inside a banned pattern described by `bannedRegion`
  /// (meaning, `bannedRegion.start` < index < `bannedRegion.end), the offset
  /// will be placed at the end of the replacement string.
  factory FilteringFormatterFormattingStrategy.preserveSelectionAndComposingRegion({
    required String Function(TextRange) replacementStringBuilder,
  }) = _PreserveSelectionAndComposingRegion;

  /// A [FilteringFormatterFormattingStrategy] that does not remove a banned
  /// word immediately if part of word is still being composed, and has the same
  /// behavior as [preserveSelectionAndComposingRegion] otherwise.
  ///
  /// This strategy guaratees the [FilteringTextInputFormatter] will never
  /// change the content within the current non-empty composing text region, and
  /// also preserves the pre-format selection as much as possible.
  ///
  /// This is generally more robust than the default strategy for most input
  /// methods. Many input methods only expect composing region changes from the
  /// user, but not from the text editor. Removing or replacing text from within
  /// the composing region may result in duplicated input. The default CJK input
  /// method on iOS 14.2 and many Android IMEs are known to have this problem.
  factory FilteringFormatterFormattingStrategy.preserveSelectionAndSkipComposingRegion({
    required String Function(TextRange) replacementStringBuilder,
  }) = _PreserveSelectionAndSkipComposingRegion;

  /// Processes the given banned text region given by `bannedRange`, and returns
  /// the necessary adjustments needs to be made for producing the desired
  /// formatting result.
  ///
  /// The `bannedRange` represents the half-open range of the text region being
  /// processed, within the original input text.
  /// The [TextRange] value can be an empty range (i.e.,
  /// [TextRange.isCollapsed] is true), but is guaranteed to be normalized.
  ///
  /// The `inputValue` parameter is the original unformatted [TextEditingValue]
  /// processed by the [FilteringTextInputFormatter].
  ///
  /// This method returns a [TextEditingValueAdjustments] that contains the
  /// replacement text, and the index adjustments needed for the composing range
  /// and the selection of [inputValue]. For instance, to keep the given region
  /// dispite it contains the banned pattern, return
  /// ```dart
  /// TextEditingValueAdjustments.noAdjustments
  /// ```
  /// so the original text is preserved.
  ///
  /// To remove the banned pattern entirely, return
  /// ```dart
  /// TextEditingValueAdjustments(
  ///   replacementString: '',
  ///   composingStartAdjustment: inputValue.composing.start.clamp(bannedRange.start, bannedRange.end) - bannedRange.start,
  ///   composingEndAdjustment: inputValue.composing.end.clamp(bannedRange.start, bannedRange.end) - bannedRange.start,
  ///   selectionBaseOffsetAdjustment: inputValue.selection.baseOffset.clamp(bannedRange.start, bannedRange.end) - bannedRange.start,,
  ///   selectionExtentOffsetAdjustment: inputValue.selection.extentOffset.clamp(bannedRange.start, bannedRange.end) - bannedRange.start,
  /// )
  /// ```
  /// such that the text within the banned range is replaced with an empty
  /// string, and the indices of the composing region and the selection are
  /// shifted towards the start of the string if they were originally placed
  /// after the removed text.
  TextEditingValueAdjustments processBannedPattern(TextRange bannedRange, TextEditingValue inputValue);
}

/// A `FilteringFormatterFormattingStrategy` class for creating
/// `FilteringFormatterFormattingStrategy.preserveSelectionAndComposingRegion`
class _PreserveSelectionAndComposingRegion implements FilteringFormatterFormattingStrategy {
  const _PreserveSelectionAndComposingRegion({
    required this.replacementStringBuilder
  });

  final String Function(TextRange) replacementStringBuilder;

  @override
  TextEditingValueAdjustments processBannedPattern(TextRange bannedRange, TextEditingValue inputValue) {
    assert(bannedRange.isNormalized);

    final String replacementString = replacementStringBuilder(bannedRange);

    // Turn selection / composing region to null if invalid / empty.
    final TextSelection? selection = inputValue.selection.isValid ? inputValue.selection : null;
    final TextRange? composingRegion = inputValue.composing.isCollapsed ? null : inputValue.composing;

    final int replacementLength = replacementString.length;

    int adjustIndex(int? originalIndex) {
      if (originalIndex == null) {
        return 0;
      }
      // Add to the index the length of the replacement if needed.
      // The condition of the ternary operator is chosen such that the index
      // will be placed **after** the replacement text, if the index was
      // strictly inside the banned pattern.
      final int replacedLength = bannedRange.start >= originalIndex ? 0 : replacementLength;
      // Subtract from the index the length of the banned pattern before the index.
      return replacedLength - (originalIndex.clamp(bannedRange.start, bannedRange.end) - bannedRange.start);
    }

    return TextEditingValueAdjustments(
      replacementString: replacementString,
      composingStartAdjustment: adjustIndex(composingRegion?.start),
      composingEndAdjustment: adjustIndex(composingRegion?.end),
      selectionBaseOffsetAdjustment: adjustIndex(selection?.baseOffset),
      selectionExtentOffsetAdjustment: adjustIndex(selection?.extentOffset),
    );
  }
}

// A [FilteringFormatterFormattingStrategy] class for creating
// [FilteringFormatterFormattingStrategy.preserveSelectionAndSkipComposingRegion].
//
// This is generally more robust than [_PreserveSelectionAndComposingRegion],
// See https://github.com/flutter/flutter/issues/79844 for more details.
class _PreserveSelectionAndSkipComposingRegion extends _PreserveSelectionAndComposingRegion {
  const _PreserveSelectionAndSkipComposingRegion({
    required String Function(TextRange) replacementStringBuilder,
  }) : super(replacementStringBuilder: replacementStringBuilder);

  @override
  TextEditingValueAdjustments processBannedPattern(TextRange bannedRange, TextEditingValue inputValue) {
    final TextRange composingRegion = inputValue.composing;
    return composingRegion.isCollapsed
        || bannedRange.end <= composingRegion.start
        || bannedRange.start >= composingRegion.end
      ? super.processBannedPattern(bannedRange, inputValue)
      : TextEditingValueAdjustments.noAdjustments;
  }
}

// A mutable, half-open range [`base`, `extent`) within a string.
class _MutableTextRange {
  _MutableTextRange(this.base, this.extent);

  static _MutableTextRange? fromComposingRange(TextRange range) {
    return range.isValid && !range.isCollapsed
      ? _MutableTextRange(range.start, range.end)
      : null;
  }

  static _MutableTextRange? fromTextSelection(TextSelection selection) {
    return selection.isValid
      ? _MutableTextRange(selection.baseOffset, selection.extentOffset)
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
}

// The intermediate state of a [FilteringFormatterFormattingStrategy] when it's
// formatting a new user input.
//
// This class is used to perform text replacement and update the composing
// region or the selected region in a [FilteringFormatterFormattingStrategy].
class _TextEditingValueAccumulator {
  _TextEditingValueAccumulator(this.inputValue)
    : selection = _MutableTextRange.fromTextSelection(inputValue.selection),
      composingRegion = _MutableTextRange.fromComposingRange(inputValue.composing);

  // The original string that was sent to the [FilteringTextInputFormatter] as
  // input.
  final TextEditingValue inputValue;

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
  final _MutableTextRange? selection;

  /// The updated composing region, as well as the original composing region
  /// from the input [TextEditingValue] of the [FilteringTextInputFormatter].
  ///
  /// This parameter will be null if the input [TextEditingValue.composing] is
  /// invalid or collapsed.
  final _MutableTextRange? composingRegion;

  // Whether this state object has reached its end-of-life.
  bool debugFinalized = false;

  TextEditingValue finalize() {
    debugFinalized = true;
    final _MutableTextRange? selection = this.selection;
    final _MutableTextRange? composingRegion = this.composingRegion;
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
