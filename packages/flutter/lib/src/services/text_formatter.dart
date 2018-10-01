// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'text_editing.dart';
import 'text_input.dart';

/// A [TextInputFormatter] can be optionally injected into an [EditableText]
/// to provide as-you-type validation and formatting of the text being edited.
///
/// Text modification should only be applied when text is being committed by the
/// IME and not on text under composition (i.e., only when
/// [TextEditingValue.composing] is collapsed).
///
/// Concrete implementations [BlacklistingTextInputFormatter], which removes
/// blacklisted characters upon edit commit, and
/// [WhitelistingTextInputFormatter], which only allows entries of whitelisted
/// characters, are provided.
///
/// To create custom formatters, extend the [TextInputFormatter] class and
/// implement the [formatEditUpdate] method.
///
/// See also:
///
///  * [EditableText] on which the formatting apply.
///  * [BlacklistingTextInputFormatter], a provided formatter for blacklisting
///    characters.
///  * [WhitelistingTextInputFormatter], a provided formatter for whitelisting
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
    TextEditingValue newValue
  );

  /// A shorthand to creating a custom [TextInputFormatter] which formats
  /// incoming text input changes with the given function.
  static TextInputFormatter withFunction(
    TextInputFormatFunction formatFunction
  ) {
    return _SimpleTextInputFormatter(formatFunction);
  }
}

/// Function signature expected for creating custom [TextInputFormatter]
/// shorthands via [TextInputFormatter.withFunction];
typedef TextInputFormatFunction = TextEditingValue Function(
    TextEditingValue oldValue,
    TextEditingValue newValue,
);

/// Wiring for [TextInputFormatter.withFunction].
class _SimpleTextInputFormatter extends TextInputFormatter {
  _SimpleTextInputFormatter(this.formatFunction) :
    assert(formatFunction != null);

  final TextInputFormatFunction formatFunction;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue
  ) {
    return formatFunction(oldValue, newValue);
  }
}

/// A [TextInputFormatter] that prevents the insertion of blacklisted
/// characters patterns.
///
/// Instances of blacklisted characters found in the new [TextEditingValue]s
/// will be replaced with the [replacementString] which defaults to the empty
/// string.
///
/// Since this formatter only removes characters from the text, it attempts to
/// preserve the existing [TextEditingValue.selection] to values it would now
/// fall at with the removed characters.
///
/// See also:
///
///  * [WhitelistingTextInputFormatter], which uses a whitelist instead of a
///    blacklist.
class BlacklistingTextInputFormatter extends TextInputFormatter {
  /// Creates a formatter that prevents the insertion of blacklisted characters patterns.
  ///
  /// The [blacklistedPattern] must not be null.
  BlacklistingTextInputFormatter(
    this.blacklistedPattern, {
    this.replacementString = '',
  }) : assert(blacklistedPattern != null);

  /// A [Pattern] to match and replace incoming [TextEditingValue]s.
  final Pattern blacklistedPattern;

  /// String used to replace found patterns.
  final String replacementString;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue, // unused.
    TextEditingValue newValue,
  ) {
    return _selectionAwareTextManipulation(
      newValue,
      (String substring) {
        return substring.replaceAll(blacklistedPattern, replacementString);
      },
    );
  }

  /// A [BlacklistingTextInputFormatter] that forces input to be a single line.
  static final BlacklistingTextInputFormatter singleLineFormatter
      = BlacklistingTextInputFormatter(RegExp(r'\n'));
}

/// A [TextInputFormatter] that prevents the insertion of more characters
/// (currently defined as Unicode scalar values) than allowed.
///
/// Since this formatter only prevents new characters from being added to the
/// text, it preserves the existing [TextEditingValue.selection].
///
///  * [maxLength], which discusses the precise meaning of "number of
///    characters" and how it may differ from the intuitive meaning.
class LengthLimitingTextInputFormatter extends TextInputFormatter {
  /// Creates a formatter that prevents the insertion of more characters than a
  /// limit.
  ///
  /// The [maxLength] must be null or greater than zero. If it is null, then no
  /// limit is enforced.
  LengthLimitingTextInputFormatter(this.maxLength)
    : assert(maxLength == null || maxLength > 0);

  /// The limit on the number of characters (i.e. Unicode scalar values) this formatter
  /// will allow.
  ///
  /// The value must be null or greater than zero. If it is null, then no limit
  /// is enforced.
  ///
  /// This formatter does not currently count Unicode grapheme clusters (i.e.
  /// characters visible to the user), it counts Unicode scalar values, which leaves
  /// out a number of useful possible characters (like many emoji and composed
  /// characters), so this will be inaccurate in the presence of those
  /// characters. If you expect to encounter these kinds of characters, be
  /// generous in the maxLength used.
  ///
  /// For instance, the character "ö" can be represented as '\u{006F}\u{0308}',
  /// which is the letter "o" followed by a composed diaeresis "¨", or it can
  /// be represented as '\u{00F6}', which is the Unicode scalar value "LATIN
  /// SMALL LETTER O WITH DIAERESIS". In the first case, the text field will
  /// count two characters, and the second case will be counted as one
  /// character, even though the user can see no difference in the input.
  ///
  /// Similarly, some emoji are represented by multiple scalar values. The
  /// Unicode "THUMBS UP SIGN + MEDIUM SKIN TONE MODIFIER", "👍🏽", should be
  /// counted as a single character, but because it is a combination of two
  /// Unicode scalar values, '\u{1F44D}\u{1F3FD}', it is counted as two
  /// characters.
  final int maxLength;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue, // unused.
    TextEditingValue newValue,
  ) {
    if (maxLength != null && newValue.text.runes.length > maxLength) {
      final TextSelection newSelection = newValue.selection.copyWith(
          baseOffset: math.min(newValue.selection.start, maxLength),
          extentOffset: math.min(newValue.selection.end, maxLength),
      );
      // This does not count grapheme clusters (i.e. characters visible to the user),
      // it counts Unicode runes, which leaves out a number of useful possible
      // characters (like many emoji), so this will be inaccurate in the
      // presence of those characters. The Dart lang bug
      // https://github.com/dart-lang/sdk/issues/28404 has been filed to
      // address this in Dart.
      // TODO(gspencer): convert this to count actual characters when Dart
      // supports that.
      final RuneIterator iterator = RuneIterator(newValue.text);
      if (iterator.moveNext())
        for (int count = 0; count < maxLength; ++count)
          if (!iterator.moveNext())
            break;
      final String truncated = newValue.text.substring(0, iterator.rawIndex);
      return TextEditingValue(
        text: truncated,
        selection: newSelection,
        composing: TextRange.empty,
      );
    }
    return newValue;
  }
}

/// A [TextInputFormatter] that allows only the insertion of whitelisted
/// characters patterns.
///
/// Since this formatter only removes characters from the text, it attempts to
/// preserve the existing [TextEditingValue.selection] to values it would now
/// fall at with the removed characters.
///
/// See also:
///
///  * [BlacklistingTextInputFormatter], which uses a blacklist instead of a
///    whitelist.
class WhitelistingTextInputFormatter extends TextInputFormatter {
  /// Creates a formatter that allows only the insertion of whitelisted characters patterns.
  ///
  /// The [whitelistedPattern] must not be null.
  WhitelistingTextInputFormatter(this.whitelistedPattern) :
    assert(whitelistedPattern != null);

  /// A [Pattern] to extract all instances of allowed characters.
  ///
  /// [RegExp] with multiple groups is not supported.
  final Pattern whitelistedPattern;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue, // unused.
    TextEditingValue newValue,
  ) {
    return _selectionAwareTextManipulation(
      newValue,
      (String substring) {
        return whitelistedPattern
            .allMatches(substring)
            .map<String>((Match match) => match.group(0))
            .join();
      } ,
    );
  }

  /// A [WhitelistingTextInputFormatter] that takes in digits `[0-9]` only.
  static final WhitelistingTextInputFormatter digitsOnly
      = WhitelistingTextInputFormatter(RegExp(r'\d+'));
}

TextEditingValue _selectionAwareTextManipulation(
  TextEditingValue value,
  String substringManipulation(String substring),
) {
  final int selectionStartIndex = value.selection.start;
  final int selectionEndIndex = value.selection.end;
  String manipulatedText;
  TextSelection manipulatedSelection;
  if (selectionStartIndex < 0 || selectionEndIndex < 0) {
    manipulatedText = substringManipulation(value.text);
  } else {
    final String beforeSelection = substringManipulation(
      value.text.substring(0, selectionStartIndex)
    );
    final String inSelection = substringManipulation(
      value.text.substring(selectionStartIndex, selectionEndIndex)
    );
    final String afterSelection = substringManipulation(
      value.text.substring(selectionEndIndex)
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
