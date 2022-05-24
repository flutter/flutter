// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/src/painting/text_span.dart' show TextSpan;
import 'package:flutter/src/painting/text_style.dart' show TextStyle;

import 'text_input.dart';

/// A data structure representing a range of misspelled text and the suggested
/// replacements for this range. For example, one [SuggestionSpan] of the
/// [List<SuggestionSpan> suggestions] of the [SpellCheckResults] corresponding
/// to "Hello, wrold!" may be:
/// ```dart
/// SuggestionSpan(7, 11, List<String>.from["word, world, old"])
/// ```
@immutable
class SuggestionSpan {
  const SuggestionSpan(this.startIndex, this.endIndex, this.suggestions)
      : assert(startIndex != null),
        assert(endIndex != null),
        assert(suggestions != null);

  final int startIndex;

  final int endIndex;

  /// The alternate suggestions for mispelled range of text.
  ///
  /// The maximum length of this list depends on the spell checker used. If
  /// [DefaultSpellCheckService] is used, the maximum length of this list will be
  /// 5 on Android platforms and there will be no maximum length on iOS platforms.
  final List<String> suggestions;

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    return other is SuggestionSpan &&
        other.startIndex == startIndex &&
        other.endIndex == endIndex &&
        listEquals<String>(other.suggestions, suggestions);
  }

  @override
  int get hashCode => Object.hash(startIndex, endIndex, hashList(suggestions));
}

/// A data structure grouping the [SuggestionSpan]s and related text of a
/// result returned by the active spell checker.
///
/// See also:
///
///  * [SuggestionSpan], the ranges of mispelled text and corresponding replacement
///    suggestions.
@immutable
class SpellCheckResults {
  const SpellCheckResults(this.spellCheckedText, this.suggestionSpans);

  final String spellCheckedText;

  final List<SuggestionSpan> suggestionSpans;

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    return other is SpellCheckResults &&
        other.spellCheckedText == spellCheckedText &&
        listEquals<SuggestionSpan>(other.suggestionSpans, suggestionSpans);
  }

  @override
  int get hashCode => Object.hash(spellCheckedText, hashList(suggestionSpans));
}

/// Controls how spell check is performed for text input.
///
/// The spell check configuration determines the [SpellCheckService] used to
/// fetch spell check results of type [List<SuggestionSpan>] and the
/// [SpellCheckSuggestionsHandler] used to mark and display replacement
/// suggestions for mispelled words within text input.
class SpellCheckConfiguration {
  SpellCheckConfiguration(
      {this.spellCheckService, this.spellCheckSuggestionsHandler});

  final SpellCheckService? spellCheckService;

  final SpellCheckSuggestionsHandler? spellCheckSuggestionsHandler;

  /// The most up-to-date spell check results for text input.
  ///
  /// These results will be updated by the
  /// [SpellCheckService] and used by the [SpellCheckSuggestionsHandler] to
  /// build the [TextSpan] tree for text input and menus for replacement
  /// suggestions of mispelled words.
  SpellCheckResults? spellCheckResults;

  /// Configuration that indicates that spell check should not be run on text
  /// input and/or spell check is not implemented on the respective platform.
  static SpellCheckConfiguration disabled = SpellCheckConfiguration();
}

/// Determines how spell check results are received for text input.
///
/// See also:
///
///  * [DefaultSpellCheckService], implementation used on Android and iOS
///    platforms when spell check is enabled for an [EditableText] instance
///    but no [SpellCheckService] implementation is provided.
abstract class SpellCheckService {
  /// Initiates and receives results for a spell check request.
  Future<SpellCheckResults?> fetchSpellCheckSuggestions(
      Locale locale, String text);
}

/// Determines how mispelled words are indicated in text input and how
/// replacement suggestions for misspelled words are displayed via a menu.
///
/// See also:
///
/// * [DefaultSpellCheckSuggestionsHandler], implementation used on Android and
///   iOS platforms when spell check is enabled for an [EditableText] instance
///   but no [SpellCheckSuggestionsHandler] implementation is provided.
abstract class SpellCheckSuggestionsHandler {
  /// Builds [TextSpan] tree given the current state of the text input and spell
  /// check results.
  ///
  /// An implementation should handle any cases concerning the [spellCheckResults]
  /// being out of date with the [value] if the [DefaultSpellCheckService] is
  /// used due to the asynchronous communication between the Android and iOS
  /// engines and the framework.
  TextSpan buildTextSpanWithSpellCheckSuggestions(
      TextEditingValue value,
      bool composingWithinCurrentTextRange,
      TextStyle? style,
      SpellCheckResults spellCheckResults);
}
