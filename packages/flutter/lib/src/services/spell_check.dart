// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/src/services/platform_channel.dart';
import 'package:flutter/src/services/system_channels.dart';

////////////////////////////////////////////////////////////////////////////////
///                            START OF PR #1.1                              ///
////////////////////////////////////////////////////////////////////////////////

/// A data structure representing a range of misspelled text and the suggested
/// replacements for this range.
///
/// For example, one [SuggestionSpan] of the
/// [List<SuggestionSpan>] suggestions of the [SpellCheckResults] corresponding
/// to "Hello, wrold!" may be:
/// ```dart
/// SuggestionSpan(TextRange(7, 12), List<String>.from["word, world, old"])
/// ```
@immutable
class SuggestionSpan {
  /// Creates a span representing a misspelled range of text and the replacements
  /// suggested by a spell checker.
  ///
  /// The [range] and replacement [suggestions] must all not
  /// be null.
  const SuggestionSpan(this.range, this.suggestions)
      : assert(range != null),
        assert(suggestions != null);

  /// The misspelled range of text.
  final TextRange range;

  /// The alternate suggestions for the misspelled range of text.
  final List<String> suggestions;

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
        return true;
    return other is SuggestionSpan &&
        other.range.start == range.start &&
        other.range.end == range.end &&
        listEquals<String>(other.suggestions, suggestions);
  }

  @override
  int get hashCode => Object.hash(range.start, range.end, hashList(suggestions));
}

/// A data structure grouping together the [SuggestionSpan]s and related text of
/// results returned by a spell checker.
@immutable
class SpellCheckResults {
  /// Creates results based off those received by spell checking some text input.
  const SpellCheckResults(this.spellCheckedText, this.suggestionSpans)
      : assert(spellCheckedText != null),
        assert(suggestionSpans != null);

  /// The text that the [suggestionSpans] correspond to.
  final String spellCheckedText;

  /// The spell check results of the [spellCheckedText].
  ///
  /// See also:
  ///
  ///  * [SuggestionSpan], the ranges of misspelled text and corresponding
  ///    replacement suggestions.
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

/// Determines how spell check results are received for text input.
abstract class SpellCheckService {
  /// Facilitates a spell check request.
  ///
  /// Returns a [Future] that resolves with a [List] of [SuggestionSpan]s for
  /// all misspelled words in [text] for the given [locale].
  Future<List<SuggestionSpan>?> fetchSpellCheckSuggestions(
    Locale locale, String text
  );
}

////////////////////////////////////////////////////////////////////////////////
///                             END OF PR #1.1                               ///
////////////////////////////////////////////////////////////////////////////////

class DefaultSpellCheckService implements SpellCheckService {
  List<SuggestionSpan>? reusableSpellCheckResults;
  String? reusableText;

  late MethodChannel spellCheckChannel;

  DefaultSpellCheckService() {
    spellCheckChannel = SystemChannels.spellCheck;
  }


  /// Merges two lists of spell check results to account for Gboard's automatic
  /// deletion of results in the composing region.
  List<SuggestionSpan> mergeResults(
      List<SuggestionSpan> oldResults, List<SuggestionSpan> newResults) {
    List<SuggestionSpan> mergedResults = <SuggestionSpan>[];

    int old_span_pointer = 0;
    int new_span_pointer = 0;

    while (old_span_pointer < oldResults.length &&
        new_span_pointer < newResults.length) {
      SuggestionSpan oldSpan = oldResults[old_span_pointer];
      SuggestionSpan newSpan = newResults[new_span_pointer];

      if (oldSpan.range.start == newSpan.range.start) {
        mergedResults.add(oldSpan);
        old_span_pointer += 1;
        new_span_pointer += 1;
      } else {
        if (oldSpan.range.start < newSpan.range.start) {
          mergedResults.add(oldSpan);
          old_span_pointer += 1;
        } else {
          mergedResults.add(newSpan);
          new_span_pointer += 1;
        }
      }
    }

    mergedResults.addAll(oldResults.sublist(old_span_pointer));
    mergedResults.addAll(newResults.sublist(new_span_pointer));

    return mergedResults;
  }

  @override
  Future<List<SuggestionSpan>?> fetchSpellCheckSuggestions(
      Locale locale, String text) async {
    assert(locale != null);
    assert(text != null);

    final List<dynamic> rawResults;

    try {
      rawResults = await spellCheckChannel.invokeMethod(
        'SpellCheck.initiateSpellCheck',
        <String>[locale.toLanguageTag(), text],
      );
    } catch (e) {
      // Spell check request canceled due to ongoing request.
      return null;
    }

    List<String> results = rawResults.cast<String>();

    List<SuggestionSpan> suggestionSpans = <SuggestionSpan>[];

    results.forEach((String result) {
      List<String> resultParsed = result.split(".");
      suggestionSpans.add(SuggestionSpan(TextRange(start: int.parse(resultParsed[0]),
          end: int.parse(resultParsed[1])), resultParsed[2].split("\n")));
    });

    /// Correct results if Gboard is currently trying to ignore the composing region.
    if (reusableText != null &&
        reusableText == text &&
        reusableSpellCheckResults != null &&
        suggestionSpans != null &&
        !listEquals(reusableSpellCheckResults, suggestionSpans)) {
        suggestionSpans =
          mergeResults(reusableSpellCheckResults!, suggestionSpans);
    }

    reusableSpellCheckResults = suggestionSpans;
    reusableText = text; 

    return suggestionSpans;
  }
}