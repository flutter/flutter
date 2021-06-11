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

/// A [TextInputFormatter] that prevents the insertion of characters
/// matching (or not matching) a particular pattern.
///
/// Instances of filtered characters found in the new [TextEditingValue]s
/// will be replaced with the [replacementString] which defaults to the empty
/// string.
///
/// Since this formatter only removes characters from the text, it attempts to
/// preserve the existing [TextEditingValue.selection] to values it would now
/// fall at with the removed characters.
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
  /// The [filterPattern], [allow], and [replacementString] arguments
  /// must not be null.
  FilteringTextInputFormatter(
    this.filterPattern, {
    required this.allow,
    this.replacementString = '',
  }) : assert(filterPattern != null),
       assert(allow != null),
       assert(replacementString != null);

  /// Creates a formatter that only allows characters matching a pattern.
  ///
  /// The [filterPattern] and [replacementString] arguments
  /// must not be null.
  FilteringTextInputFormatter.allow(
    this.filterPattern, {
    this.replacementString = '',
  }) : assert(filterPattern != null),
       assert(replacementString != null),
       allow = true;

  /// Creates a formatter that blocks characters matching a pattern.
  ///
  /// The [filterPattern] and [replacementString] arguments
  /// must not be null.
  FilteringTextInputFormatter.deny(
    this.filterPattern, {
    this.replacementString = '',
  }) : assert(filterPattern != null),
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

  /// String used to replace banned patterns.
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
  /// Additionally, each segment of the string before, during, and
  /// after the current selection in the [TextEditingValue] is handled
  /// separately. This means that, in the case of the "Into the Woods"
  /// example above, if the selection ended between the two "o"s in
  /// "Woods", even if the pattern was `RegExp('o+')`, the result
  /// would be "Int* the W**ds", since the two "o"s would be handled
  /// in separate passes.
  ///
  /// See also [String.splitMapJoin], which is used to implement this
  /// behavior in both cases.
  final String replacementString;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue, // unused.
    TextEditingValue newValue,
  ) {
    return _selectionAwareTextManipulation(
      newValue,
      (String substring) {
        return substring.splitMapJoin(
          filterPattern,
          onMatch: !allow ? (Match match) => replacementString : null,
          onNonMatch: allow ? (String nonMatch) => nonMatch.isNotEmpty ? replacementString : '' : null,
        );
      },
    );
  }

  /// A [TextInputFormatter] that forces input to be a single line.
  static final TextInputFormatter singleLineFormatter = FilteringTextInputFormatter.deny('\n');

  /// A [TextInputFormatter] that takes in digits `[0-9]` only.
  static final TextInputFormatter digitsOnly = FilteringTextInputFormatter.allow(RegExp(r'[0-9]'));
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

TextEditingValue _selectionAwareTextManipulation(
  TextEditingValue value,
  String Function(String substring) substringManipulation,
) {
  final int selectionStartIndex = value.selection.start;
  final int selectionEndIndex = value.selection.end;
  String manipulatedText;
  TextSelection? manipulatedSelection;
  if (selectionStartIndex < 0 || selectionEndIndex < 0) {
    manipulatedText = substringManipulation(value.text);
  } else {
    final String beforeSelection = substringManipulation(
      value.text.substring(0, selectionStartIndex),
    );
    final String inSelection = substringManipulation(
      value.text.substring(selectionStartIndex, selectionEndIndex),
    );
    final String afterSelection = substringManipulation(
      value.text.substring(selectionEndIndex),
    );
    manipulatedText = beforeSelection + inSelection + afterSelection;
    if (value.selection.baseOffset > value.selection.extentOffset) {
      manipulatedSelection = value.selection.copyWith(
        baseOffset: beforeSelection.length + inSelection.length,
        extentOffset: beforeSelection.length,
      );
    } else {
      manipulatedSelection = value.selection.copyWith(
        baseOffset: beforeSelection.length,
        extentOffset: beforeSelection.length + inSelection.length,
      );
    }
  }
  return TextEditingValue(
    text: manipulatedText,
    selection: manipulatedSelection ?? const TextSelection.collapsed(offset: -1),
    composing: manipulatedText == value.text
        ? value.composing
        : TextRange.empty,
  );
}
