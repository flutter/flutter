// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart'
    show SpellCheckResults, SpellCheckService, SuggestionSpan, TextEditingValue;

import 'editable_text.dart' show EditableTextContextMenuBuilder;
import 'framework.dart' show immutable;

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
    this.spellCheckSuggestionsToolbarBuilder,
  }) : _spellCheckEnabled = true;

  /// Creates a configuration that disables spell check.
  const SpellCheckConfiguration.disabled()
    :  _spellCheckEnabled = false,
       spellCheckService = null,
       spellCheckSuggestionsToolbarBuilder = null,
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

  /// Builds the toolbar used to display spell check suggestions for misspelled
  /// words.
  final EditableTextContextMenuBuilder? spellCheckSuggestionsToolbarBuilder;

  final bool _spellCheckEnabled;

  /// Whether or not the configuration should enable or disable spell check.
  bool get spellCheckEnabled => _spellCheckEnabled;

  /// Returns a copy of the current [SpellCheckConfiguration] instance with
  /// specified overrides.
  SpellCheckConfiguration copyWith({
    SpellCheckService? spellCheckService,
    TextStyle? misspelledTextStyle,
    EditableTextContextMenuBuilder? spellCheckSuggestionsToolbarBuilder}) {
    if (!_spellCheckEnabled) {
      // A new configuration should be constructed to enable spell check.
      return const SpellCheckConfiguration.disabled();
    }

    return SpellCheckConfiguration(
      spellCheckService: spellCheckService ?? this.spellCheckService,
      misspelledTextStyle: misspelledTextStyle ?? this.misspelledTextStyle,
      spellCheckSuggestionsToolbarBuilder : spellCheckSuggestionsToolbarBuilder ?? this.spellCheckSuggestionsToolbarBuilder,
    );
  }

  @override
  String toString() {
    return '''
  spell check enabled   : $_spellCheckEnabled
  spell check service   : $spellCheckService
  misspelled text style : $misspelledTextStyle
  spell check suggestions toolbar builder: $spellCheckSuggestionsToolbarBuilder
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
      && other.spellCheckSuggestionsToolbarBuilder == spellCheckSuggestionsToolbarBuilder
      && other._spellCheckEnabled == _spellCheckEnabled;
  }

  @override
  int get hashCode => Object.hash(spellCheckService, misspelledTextStyle, spellCheckSuggestionsToolbarBuilder, _spellCheckEnabled);
}

// Methods for displaying spell check results:

  List<SuggestionSpan> _correctSpellCheckResults(
    String newText, String resultsText, List<SuggestionSpan> results) {
  final List<SuggestionSpan> correctedSpellCheckResults = <SuggestionSpan>[];

  int spanPointer = 0;
  int offset = 0; // the cummulative difference between where we are and where we thought we'd be
  int foundIndex;
  int spanLength;
  SuggestionSpan adjustedSpan;
  String currentSpanText;
  RegExp regex;
  bool currentSpanFoundExactly = false;
  bool currentSpanFoundElsewhere = false;

  // Assumes that the order of spans has not been jumbled for optimization
  // purposes, and will only search since the previously found span.
  int searchStart = 0;

  while (spanPointer < results.length) {
    // Try finding SuggestionSpan from old results (currentSpan) in new text.
    SuggestionSpan currentSpan = results[spanPointer];
    currentSpanText =
        resultsText.substring(currentSpan.range.start, currentSpan.range.end);

    regex = RegExp('\\b$currentSpanText\\b');
    foundIndex = newText.substring(searchStart).indexOf(regex);
    currentSpanFoundExactly = currentSpan.range.start == foundIndex + searchStart;
    bool currentSpanFoundExactlyWithOffset = currentSpan.range.start + offset == foundIndex + searchStart;
    currentSpanFoundElsewhere = foundIndex >= 0;

    if (currentSpanFoundExactly || currentSpanFoundExactlyWithOffset) {
      // currentSpan was found at the same index in new text and old text
      // (resultsText), so apply it to new text by adding it to the list of
      // corrected results.
      adjustedSpan = SuggestionSpan(
          TextRange(
              start: currentSpan.range.start + offset, end: currentSpan.range.end + offset),
          currentSpan.suggestions,
      );
      searchStart = currentSpan.range.end + 1 + offset;
      correctedSpellCheckResults.add(adjustedSpan);       
    } else if (currentSpanFoundElsewhere) {
      // Word was pushed forward but not modified.
      spanLength = currentSpan.range.end - currentSpan.range.start;
      int adjustedSpanStart = searchStart + foundIndex;
      int adjustedSpanEnd = adjustedSpanStart + spanLength;
      adjustedSpan = SuggestionSpan(
          TextRange(start: adjustedSpanStart, end: adjustedSpanEnd),
          currentSpan.suggestions,
      );
      searchStart = adjustedSpanEnd + 1;
      offset = adjustedSpanStart - currentSpan.range.start;
      correctedSpellCheckResults.add(adjustedSpan);
    } else {
      // Check if word was modified by extension.
      regex = RegExp('$currentSpanText');
      foundIndex = newText.substring(searchStart).indexOf(regex);

      if (foundIndex >= 0) {
        // Word was extended.
        regex = RegExp(' ');
        spanLength = currentSpan.range.end - currentSpan.range.start;
        int adjustedSearchStartForSpace = foundIndex + searchStart + spanLength;
        int foundEndIndex = newText.substring(adjustedSearchStartForSpace).indexOf(regex);
        
        if (foundEndIndex >= 0) {
          // Word not at end of string.
          int adjustedSpanStart = foundIndex + searchStart;
          int adjustedSpanEnd = adjustedSearchStartForSpace + foundEndIndex;
          adjustedSpan = SuggestionSpan(
            TextRange(start: adjustedSpanStart, end: adjustedSpanEnd),
            currentSpan.suggestions,
          );

          searchStart = adjustedSpanEnd + 1;
          correctedSpellCheckResults.add(adjustedSpan);
          offset = (adjustedSpanEnd - adjustedSpanStart) - (currentSpan.range.end - currentSpan.range.start) + (adjustedSpanStart - currentSpan.range.start);
        } else {
          // Word at end of string. We do not need to update any values.
          int adjustedSpanStart = foundIndex + searchStart;
          adjustedSpan = SuggestionSpan(
          TextRange(start: adjustedSpanStart, end: newText.length),
          currentSpan.suggestions,
          );

          correctedSpellCheckResults.add(adjustedSpan);
          break;
        }
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

  // We will draw the TextSpan tree based on the composing region, if it is
  // available.
  final bool shouldConsiderComposingRegion = defaultTargetPlatform == TargetPlatform.android;
  if (shouldConsiderComposingRegion) {
    return TextSpan(
      style: style,
      children: _buildSubtreesWithComposingRegion(
          spellCheckResultsSpans,
          value,
          style,
          misspelledTextStyle,
          composingWithinCurrentTextRange,
      ),
    );
  }

  return TextSpan(
    style: style,
    children: _buildSubtreesWithoutComposingRegion(
      spellCheckResultsSpans,
      value,
      style,
      misspelledTextStyle,
      value.selection.baseOffset,
    ),
  );
}

/// Builds [TextSpan] subtree for text with misspelled words with no logic based
/// on a valid composing region, and instead, ignoring misspelled words adjacent
/// to the cursor.
List<TextSpan> _buildSubtreesWithoutComposingRegion(
    List<SuggestionSpan>? spellCheckSuggestions,
    TextEditingValue value,
    TextStyle? style,
    TextStyle misspelledStyle,
    int cursorIndex,
) {
  final List<TextSpan> textSpanTreeChildren = <TextSpan>[];

  int textPointer = 0;
  int currentSpanPointer = 0;
  int endIndex;
  final String text = value.text;
  final TextStyle misspelledJointStyle =
      style?.merge(misspelledStyle) ?? misspelledStyle;
  bool cursorInCurrentSpan = false;

  // Add text interwoven with any misspelled words to the tree.
  if (spellCheckSuggestions != null) {
    while (textPointer < text.length &&
      currentSpanPointer < spellCheckSuggestions.length) {
      SuggestionSpan currentSpan = spellCheckSuggestions[currentSpanPointer];

      if (currentSpan.range.start > textPointer) {
        endIndex = currentSpan.range.start < text.length
            ? currentSpan.range.start
            : text.length;
        textSpanTreeChildren.add(
          TextSpan(
            style: style,
            text: text.substring(textPointer, endIndex),
          )
        );
        textPointer = endIndex;
      } else {
        endIndex =
            currentSpan.range.end < text.length ? currentSpan.range.end : text.length;
        cursorInCurrentSpan = currentSpan.range.start <= cursorIndex && currentSpan.range.end >= cursorIndex;
        textSpanTreeChildren.add(
          TextSpan(
            style: cursorInCurrentSpan
                ? style
                : misspelledJointStyle,
            text: text.substring(currentSpan.range.start, endIndex),
          )
        );

        textPointer = endIndex;
        currentSpanPointer++;
      }
    }
  }

  // Add any remaining text to the tree if applicable.
  if (textPointer < text.length) {
    textSpanTreeChildren.add(
      TextSpan(
        style: style,
        text: text.substring(textPointer, text.length),
      )
    );
  }

  return textSpanTreeChildren;
}

/// Builds [TextSpan] subtree for text with misspelled words with logic based on
/// a valid composing region.
List<TextSpan> _buildSubtreesWithComposingRegion(
    List<SuggestionSpan>? spellCheckSuggestions,
    TextEditingValue value,
    TextStyle? style,
    TextStyle misspelledStyle,
    bool composingWithinCurrentTextRange) {
  final List<TextSpan> textSpanTreeChildren = <TextSpan>[];

  int textPointer = 0;
  int currentSpanPointer = 0;
  int endIndex;
  SuggestionSpan currentSpan;
  final String text = value.text;
  final TextRange composingRegion = value.composing;
  final TextStyle composingTextStyle =
      style?.merge(const TextStyle(decoration: TextDecoration.underline)) ??
          const TextStyle(decoration: TextDecoration.underline);
  final TextStyle misspelledJointStyle =
      style?.merge(misspelledStyle) ?? misspelledStyle;
  bool textPointerWithinComposingRegion = false;
  bool currentSpanIsComposingRegion = false;

  // Add text interwoven with any misspelled words to the tree.
  if (spellCheckSuggestions != null) {
    while (textPointer < text.length &&
      currentSpanPointer < spellCheckSuggestions.length) {
      currentSpan = spellCheckSuggestions[currentSpanPointer];

      if (currentSpan.range.start > textPointer) {
        endIndex = currentSpan.range.start < text.length
            ? currentSpan.range.start
            : text.length;
        textPointerWithinComposingRegion =
            composingRegion.start >= textPointer &&
                composingRegion.end <= endIndex &&
                !composingWithinCurrentTextRange;

        if (textPointerWithinComposingRegion) {
          _addComposingRegionTextSpans(textSpanTreeChildren, text, textPointer,
              composingRegion, style, composingTextStyle);
          textSpanTreeChildren.add(
            TextSpan(
              style: style,
              text: text.substring(composingRegion.end, endIndex),
            )
          );
        } else {
          textSpanTreeChildren.add(
            TextSpan(
              style: style,
              text: text.substring(textPointer, endIndex),
            )
          );
        }

        textPointer = endIndex;
      } else {
        endIndex =
            currentSpan.range.end < text.length ? currentSpan.range.end : text.length;
        currentSpanIsComposingRegion = textPointer >= composingRegion.start &&
            endIndex <= composingRegion.end &&
            !composingWithinCurrentTextRange;
        textSpanTreeChildren.add(
          TextSpan(
            style: currentSpanIsComposingRegion
                ? composingTextStyle
                : misspelledJointStyle,
            text: text.substring(currentSpan.range.start, endIndex),
          )
        );

        textPointer = endIndex;
        currentSpanPointer++;
      }
    }
  }

  // Add any remaining text to the tree if applicable.
  if (textPointer < text.length) {
    if (textPointer < composingRegion.start &&
        !composingWithinCurrentTextRange) {
      _addComposingRegionTextSpans(textSpanTreeChildren, text, textPointer,
          composingRegion, style, composingTextStyle);

      if (composingRegion.end != text.length) {
        textSpanTreeChildren.add(
          TextSpan(
            style: style,
            text: text.substring(composingRegion.end, text.length),
          )
        );
      }
    } else {
      textSpanTreeChildren.add(
        TextSpan(
          style: style, text: text.substring(textPointer, text.length),
        )
      );
    }
  }

  return textSpanTreeChildren;
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
      text: text.substring(start, composingRegion.start),
    )
  );
  treeChildren.add(
    TextSpan(
      style: composingTextStyle,
      text: text.substring(composingRegion.start, composingRegion.end),
    )
  );
}
