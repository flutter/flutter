// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart'
    show SpellCheckResults, SpellCheckService, SuggestionSpan, TextEditingValue;

/// Controls how spell check is performed for text input.
///
/// This configuration determines the [SpellCheckService] used to fetch the
/// [List<SuggestionSpan>] spell check results and the
/// [SpellCheckSuggestionsHandler] used to mark and display replacement
/// suggestions for misspelled words within text input.
class SpellCheckConfiguration {
  /// Creates a configuration that specifies the service and suggestions handler
  /// for spell check.
  const SpellCheckConfiguration({
    this.spellCheckService,
    this.spellCheckSuggestionsHandler,
    this.misspelledTextStyle,
  });

  /// The service used to fetch spell check results for text input.
  final SpellCheckService? spellCheckService;

  /// The handler used to mark misspelled words in text input and display
  /// a menu of the replacement suggestions for these misspelled words.
  final SpellCheckSuggestionsHandler? spellCheckSuggestionsHandler;

  /// Style used to indicate misspelled words.
  ///
  /// This is nullable to allow style-specific wrappers of [EditableText]
  /// to infer this, but this must be specified if this configuration is
  /// provided directly to [EditableText] or its construction will fail with an
  /// assertion error.
  final TextStyle? misspelledTextStyle;

  /// Returns a copy of the current [SpellCheckConfiguration] instance with
  /// specified overrides.
  SpellCheckConfiguration copyWith({
    SpellCheckService? spellCheckService,
    SpellCheckSuggestionsHandler? spellCheckSuggestionsHandler,
    TextStyle? misspelledTextStyle}) {
    return SpellCheckConfiguration(
      spellCheckService: spellCheckService ?? this.spellCheckService,
      spellCheckSuggestionsHandler:
        spellCheckSuggestionsHandler ?? this.spellCheckSuggestionsHandler,
      misspelledTextStyle: misspelledTextStyle ?? this.misspelledTextStyle,
    );
  }
}

/// Determines how misspelled words are indicated in text input and how
/// replacement suggestions for misspelled words are displayed via menu.
mixin SpellCheckSuggestionsHandler {
  /// Builds the [TextSpan] tree given the current state of the text input and
  /// spell check results.
  TextSpan buildTextSpanWithSpellCheckSuggestions(
    TextEditingValue value,
    bool composingWithinCurrentTextRange,
    TextStyle? style,
    TextStyle misspelledTextStyle,
    SpellCheckResults spellCheckResults
  );
}

/// The handler used by default for spell checking text input.
///
/// Any widget may use this handler to build a [TextSpan] tree with
/// [SpellCheckResults] indicated in a style based on the platform by calling
/// `buildTextSpanWithSpellCheckSuggestions(...)` with an instance of this
/// class.
///
/// See also:
///
///  * [SpellCheckSuggestionsHandler], the handler that this implements and
///    may be overriden for use by [EditableText].
///  * [EditableText], which uses this handler to display spell check results
///     by default if spell check is enabled.
class DefaultSpellCheckSuggestionsHandler with SpellCheckSuggestionsHandler {
  /// Creates a handler to use for spell checking text input based on the
  /// provided platform.
  DefaultSpellCheckSuggestionsHandler() {}

  /// Adjusts spell check results to correspond to [newText] if the only results
  /// that the handler has access to are the [results] corresponding to
  /// [resultsText].
  ///
  /// Used in the case where the request for the spell check results of the
  /// [newText] is lagging in order to avoid display of incorrect results.
  static List<SuggestionSpan> correctSpellCheckResults(
      String newText, String resultsText, List<SuggestionSpan> results) {
    final List<SuggestionSpan> correctedSpellCheckResults = <SuggestionSpan>[];

    int spanPointer = 0;
    int offset = 0;
    int foundIndex;
    int spanLength;
    SuggestionSpan currentSpan;
    SuggestionSpan adjustedSpan;
    String currentSpanText;
    String newSpanText;
    bool foundCurrentSpan = false;
    RegExp regex;

    // Assumes that the order of spans has not been jumbled for optimization
    // purposes, and will only search since the previously found span.
    int searchStart = 0;

    while (spanPointer < results.length) {
      currentSpan = results[spanPointer];
      currentSpanText =
          resultsText.substring(currentSpan.range.start, currentSpan.range.end);

      try {
        newSpanText = newText.substring(
            currentSpan.range.start + offset, currentSpan.range.end + offset);

        if (newSpanText == currentSpanText) {
          foundCurrentSpan = true;
          searchStart = currentSpan.range.end + offset;
          adjustedSpan = SuggestionSpan(
              TextRange(
                  start: currentSpan.range.start + offset, end: searchStart),
              currentSpan.suggestions
          );
          correctedSpellCheckResults.add(adjustedSpan);
        }
      } catch (e) {
        // currentSpan is invalid and needs to be searched for in newText.
      }

      if (!foundCurrentSpan) {
        regex = RegExp('\\b$currentSpanText\\b');
        foundIndex = newText.substring(searchStart).indexOf(regex);

        if (foundIndex >= 0) {
          foundIndex += searchStart;
          spanLength = currentSpan.range.end - currentSpan.range.start;
          searchStart = foundIndex + spanLength;
          adjustedSpan = SuggestionSpan(
              TextRange(start: foundIndex, end: searchStart),
              currentSpan.suggestions
          );
          offset = foundIndex - currentSpan.range.start;

          correctedSpellCheckResults.add(adjustedSpan);
        }
      }
      spanPointer++;
    }

    return correctedSpellCheckResults;
  }

  @override
  TextSpan buildTextSpanWithSpellCheckSuggestions(
      TextEditingValue value,
      bool composingWithinCurrentTextRange,
      TextStyle? style,
      TextStyle misspelledTextStyle,
      SpellCheckResults spellCheckResults) {
    List<SuggestionSpan>? correctedSpellCheckResults;

    final List<SuggestionSpan> rawSpellCheckResults =
        spellCheckResults.suggestionSpans;
    final String spellCheckResultsText = spellCheckResults.spellCheckedText;

    if (spellCheckResultsText != value.text) {
      correctedSpellCheckResults = correctSpellCheckResults(
          value.text, spellCheckResultsText, rawSpellCheckResults);
    } else {
      correctedSpellCheckResults = rawSpellCheckResults;
    }

    return TextSpan(
        style: style,
        children: buildSubtreesWithMisspelledWordsIndicated(
            correctedSpellCheckResults,
            value,
            style,
            misspelledTextStyle,
            composingWithinCurrentTextRange
        )
      );
  }

  /// Builds [TextSpan] subtree for text with misspelled words.
  static List<TextSpan> buildSubtreesWithMisspelledWordsIndicated(
      List<SuggestionSpan>? spellCheckSuggestions,
      TextEditingValue value,
      TextStyle? style,
      TextStyle misspelledStyle,
      bool composingWithinCurrentTextRange) {
    final List<TextSpan> tsTreeChildren = <TextSpan>[];

    int textPointer = 0;
    int currSpanPointer = 0;
    int endIndex;
    SuggestionSpan currSpan;
    final String text = value.text;
    final TextRange composingRegion = value.composing;
    final TextStyle composingTextStyle =
        style?.merge(const TextStyle(decoration: TextDecoration.underline)) ??
            const TextStyle(decoration: TextDecoration.underline);
    final TextStyle misspelledJointStyle =
        style?.merge(misspelledStyle) ?? misspelledStyle;
    bool textPointerWithinComposingRegion = false;
    bool currSpanIsComposingRegion = false;

    while (spellCheckSuggestions != null &&
        textPointer < text.length &&
        currSpanPointer < spellCheckSuggestions.length) {
      currSpan = spellCheckSuggestions[currSpanPointer];

      if (currSpan.range.start > textPointer) {
        endIndex = currSpan.range.start < text.length
            ? currSpan.range.start
            : text.length;
        textPointerWithinComposingRegion =
            composingRegion.start >= textPointer &&
                composingRegion.end <= endIndex &&
                !composingWithinCurrentTextRange;

        if (textPointerWithinComposingRegion) {
          _addComposingRegionTextSpans(tsTreeChildren, text, textPointer,
              composingRegion, style, composingTextStyle);
          tsTreeChildren.add(
            TextSpan(
              style: style,
              text: text.substring(composingRegion.end, endIndex)
            )
          );
        } else {
          tsTreeChildren.add(
            TextSpan(
              style: style,
              text: text.substring(textPointer, endIndex)
            )
          );
        }

        textPointer = endIndex;
      } else {
        endIndex =
            currSpan.range.end < text.length ? currSpan.range.end : text.length;
        currSpanIsComposingRegion = textPointer >= composingRegion.start &&
            endIndex <= composingRegion.end &&
            !composingWithinCurrentTextRange;
        tsTreeChildren.add(
          TextSpan(
            style: currSpanIsComposingRegion
                ? composingTextStyle
                : misspelledJointStyle,
            text: text.substring(currSpan.range.start, endIndex)
          )
        );

        textPointer = endIndex;
        currSpanPointer++;
      }
    }

    if (textPointer < text.length) {
      if (textPointer < composingRegion.start &&
          !composingWithinCurrentTextRange) {
        _addComposingRegionTextSpans(tsTreeChildren, text, textPointer,
            composingRegion, style, composingTextStyle);

        if (composingRegion.end != text.length) {
          tsTreeChildren.add(
            TextSpan(
              style: style,
              text: text.substring(composingRegion.end, text.length)
            )
          );
        }
      } else {
        tsTreeChildren.add(
          TextSpan(
            style: style, text: text.substring(textPointer, text.length)
          )
        );
      }
    }

    return tsTreeChildren;
  }

  /// Helper method to create [TextSpan] tree children for specified range of
  /// text up to and including the composing region.
  static void _addComposingRegionTextSpans(
      List<TextSpan> treeChildren,
      String text,
      int start,
      TextRange composingRegion,
      TextStyle? style,
      TextStyle composingTextStyle) {
    treeChildren.add(
      TextSpan(
        style: style,
        text: text.substring(start, composingRegion.start)
      )
    );
    treeChildren.add(
      TextSpan(
        style: composingTextStyle,
        text: text.substring(composingRegion.start, composingRegion.end)
      )
    );
  }
}
