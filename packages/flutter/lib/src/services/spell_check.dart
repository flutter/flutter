// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/src/services/platform_channel.dart';
import 'package:flutter/src/services/system_channels.dart';

import 'text_input.dart';
////////////////////////////////////////////////////////////////////////////////
///                            START OF PR #1.1                              ///
////////////////////////////////////////////////////////////////////////////////

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
    if (identical(this, other)) return true;
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
    if (identical(this, other)) return true;
    return other is SpellCheckResults &&
        other.spellCheckedText == spellCheckedText &&
        listEquals<SuggestionSpan>(other.suggestionSpans, suggestionSpans);
  }

  @override
  int get hashCode => Object.hash(spellCheckedText, hashList(suggestionSpans));
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

////////////////////////////////////////////////////////////////////////////////
///                             END OF PR #1.1                               ///
////////////////////////////////////////////////////////////////////////////////

class DefaultSpellCheckService implements SpellCheckService {
  late MethodChannel spellCheckChannel;

  DefaultSpellCheckService() {
    spellCheckChannel = SystemChannels.spellCheck;
  }

  @override
  Future<SpellCheckResults?> fetchSpellCheckSuggestions(
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

    String resultsText = results.removeAt(0);
    List<SuggestionSpan> suggestionSpans = <SuggestionSpan>[];

    results.forEach((String result) {
      List<String> resultParsed = result.split(".");
      suggestionSpans.add(SuggestionSpan(int.parse(resultParsed[0]),
          int.parse(resultParsed[1]), resultParsed[2].split("\n")));
    });

    return SpellCheckResults(resultsText, suggestionSpans);
  }
}