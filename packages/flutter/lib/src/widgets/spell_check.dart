// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show TextEditingValue;

/// A data structure representing a range of misspelled text and the suggested
/// replacements for this range. For example, one [SuggestionSpan] of the
/// [List<SuggestionSpan> suggestions] of the [SpellCheckResults] corresponding
/// to "Hello, wrold!" may be:
/// ```dart
/// SuggestionSpan(7, 11, List<String>.from["word, world, old"])
/// ```
@immutable
class SuggestionSpan {
  /// Creates a span representing a misspelled range of text and the replacements
  /// suggested by a spell checker.
  ///
  /// The [startIndex], [endIndex], and replcaement [suggestions] must all not
  /// be null.
  const SuggestionSpan(this.startIndex, this.endIndex, this.suggestions)
      : assert(startIndex != null),
        assert(endIndex != null),
        assert(suggestions != null);

  /// The start index of the misspelled range of text.
  final int startIndex;

  /// The end index of the misspelled range of text, inclusive.
  final int endIndex;

  /// The alternate suggestions for mispelled range of text.
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
///  * [SuggestionSpan], the ranges of mispelled text and corresponding
///    replacement suggestions.
@immutable
class SpellCheckResults {
  /// Creates results based off those received by spell checking some text input.
  const SpellCheckResults(this.spellCheckedText, this.suggestionSpans);

  /// The text that the [suggestionSpans] correspond to.
  final String spellCheckedText;

  /// The spell check results of the [spellCheckedText].
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
  /// Creates a configuration that specifies the service and suggestions handler
  /// for spell check.
  SpellCheckConfiguration(
      {this.spellCheckService, this.spellCheckSuggestionsHandler});

  /// The service used to fetch spell check results for text input.
  final SpellCheckService? spellCheckService;

  /// The handler used to mark mispelled words in text input and display
  /// a menu of the replcament suggestions for these mispelled words.
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
abstract class SpellCheckService {
  /// Facilitates a spell check request.
  Future<SpellCheckResults?> fetchSpellCheckSuggestions(
      Locale locale, String text);
}

/// Determines how mispelled words are indicated in text input and how
/// replacement suggestions for misspelled words are displayed via menu.
abstract class SpellCheckSuggestionsHandler {
  /// Builds the [TextSpan] tree given the current state of the text input and
  /// spell check results.
  TextSpan buildTextSpanWithSpellCheckSuggestions(
      TextEditingValue value,
      bool composingWithinCurrentTextRange,
      TextStyle? style,
      SpellCheckResults spellCheckResults);
}
