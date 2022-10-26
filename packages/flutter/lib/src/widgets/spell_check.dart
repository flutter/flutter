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
/// [List<SuggestionSpan>] spell check results and the [TextStyle] used to
/// mark misspelled words within text input.
@immutable
class SpellCheckConfiguration {
  /// Creates a configuration that specifies the service and suggestions handler
  /// for spell check.
  const SpellCheckConfiguration({
    this.spellCheckService,
    this.misspelledTextStyle,
  }) : _spellCheckEnabled = true;

  /// Creates a configuration that disables spell check.
  const SpellCheckConfiguration.disabled()
    :  _spellCheckEnabled = false,
       spellCheckService = null,
       misspelledTextStyle = null;

  /// The service used to fetch spell check results for text input.
  final SpellCheckService? spellCheckService;

  /// Style used to indicate misspelled words.
  ///
  /// This is nullable to allow style-specific wrappers of [EditableText]
  /// to infer this, but this must be specified if this configuration is
  /// provided directly to [EditableText] or its construction will fail with an
  /// assertion error.
  final TextStyle? misspelledTextStyle;

  final bool _spellCheckEnabled;

  /// Whether or not the configuration should enable or disable spell check.
  bool get spellCheckEnabled => _spellCheckEnabled;

  /// Returns a copy of the current [SpellCheckConfiguration] instance with
  /// specified overrides.
  SpellCheckConfiguration copyWith({
    SpellCheckService? spellCheckService,
    TextStyle? misspelledTextStyle}) {
    if (!_spellCheckEnabled) {
      // A new configuration should be constructed to enable spell check.
      return const SpellCheckConfiguration.disabled();
    }

    return SpellCheckConfiguration(
      spellCheckService: spellCheckService ?? this.spellCheckService,
      misspelledTextStyle: misspelledTextStyle ?? this.misspelledTextStyle,
    );
  }

  @override
  String toString() {
    return '''
  spell check enabled   : $_spellCheckEnabled
  spell check service   : $spellCheckService
  misspelled text style : $misspelledTextStyle
'''
        .trim();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
        return true;
    }

    return other is SpellCheckConfiguration
      && other.spellCheckService == spellCheckService
      && other.misspelledTextStyle == misspelledTextStyle
      && other._spellCheckEnabled == _spellCheckEnabled;
  }

  @override
  int get hashCode => Object.hash(spellCheckService, misspelledTextStyle, _spellCheckEnabled);
}

// Methods for displaying spell check results:

/// Adjusts spell check results to correspond to [newText] if the only results
/// that the handler has access to are the [results] corresponding to
/// [resultsText].
///
/// Used in the case where the request for the spell check results of the
/// [newText] is lagging in order to avoid display of incorrect results.
List<SuggestionSpan> _correctSpellCheckResults(
    String newText, String resultsText, List<SuggestionSpan> results) {
  final List<SuggestionSpan> correctedSpellCheckResults = <SuggestionSpan>[];

  int spanPointer = 0;
  int offset = 0;
  int foundIndex;
  int spanLength;
  SuggestionSpan currentSpan;
  SuggestionSpan adjustedSpan;
  String currentSpanText;
  String newSpanText = '';
  bool currentSpanValid = false;
  RegExp regex;

  // Assumes that the order of spans has not been jumbled for optimization
  // purposes, and will only search since the previously found span.
  int searchStart = 0;

  while (spanPointer < results.length) {
    // Try finding SuggestionSpan from old results (currentSpan) in new text.
    currentSpan = results[spanPointer];
    currentSpanText =
        resultsText.substring(currentSpan.range.start, currentSpan.range.end);

    try {
      // currentSpan was found and can be applied to new text.
      newSpanText = newText.substring(
          currentSpan.range.start + offset, currentSpan.range.end + offset);
      currentSpanValid = true;
    } catch (e) {
      // currentSpan is invalid and needs to be searched for in newText.
      currentSpanValid = false;
    }

    if (currentSpanValid && newSpanText == currentSpanText) {
      // currentSpan was found at the same index in new text and old text
      // (resultsText), so apply it to new text by adding it to the list of
      // corrected results.
      searchStart = currentSpan.range.end + offset;
      adjustedSpan = SuggestionSpan(
          TextRange(
              start: currentSpan.range.start + offset, end: searchStart),
          currentSpan.suggestions
      );
      correctedSpellCheckResults.add(adjustedSpan);
    } else {
      // Search for currentSpan in new text and if found, apply it to new text
      // by adding it to the list of corrected results.
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

/// Builds the [TextSpan] tree given the current state of the text input and
/// spell check results.
///
/// The [value] is the current [TextEditingValue] requested to be rendered
/// by a text input widget. The [composingWithinCurrentTextRange] value
/// represents whether or not there is a valid composing region in the
/// [value]. The [style] is the [TextStyle] to render the [value]'s text with,
/// and the [misspelledTextStyle] is the [TextStyle] to render misspelled
/// words within the [value]'s text with. The [spellCheckResults] are the
/// results of spell checking the [value]'s text.
TextSpan buildTextSpanWithSpellCheckSuggestions(
    TextEditingValue value,
    bool composingWithinCurrentTextRange,
    TextStyle? style,
    TextStyle misspelledTextStyle,
    SpellCheckResults spellCheckResults) {
  List<SuggestionSpan> spellCheckResultsSpans =
      spellCheckResults.suggestionSpans;
  final String spellCheckResultsText = spellCheckResults.spellCheckedText;

  if (spellCheckResultsText != value.text) {
    spellCheckResultsSpans = _correctSpellCheckResults(
        value.text, spellCheckResultsText, spellCheckResultsSpans);
  }

  return TextSpan(
      style: style,
      children: _buildSubtreesWithMisspelledWordsIndicated(
          spellCheckResultsSpans,
          value,
          style,
          misspelledTextStyle,
          composingWithinCurrentTextRange
      )
    );
}

/// Builds [TextSpan] subtree for text with misspelled words.
List<TextSpan> _buildSubtreesWithMisspelledWordsIndicated(
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

  // Add text interwoven with any misspelled words to the tree.
  if (spellCheckSuggestions != null) {
    while (textPointer < text.length &&
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
  }

  // Add any remaining text to the tree if applicable.
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
void _addComposingRegionTextSpans(
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
