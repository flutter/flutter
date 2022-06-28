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
  SpellCheckConfiguration(
    {this.spellCheckService, this.spellCheckSuggestionsHandler
  });

  /// The service used to fetch spell check results for text input.
  final SpellCheckService? spellCheckService;

  /// The handler used to mark misspelled words in text input and display
  /// a menu of the replacement suggestions for these misspelled words.
  final SpellCheckSuggestionsHandler? spellCheckSuggestionsHandler;

  /// The most up-to-date spell check results for text input.
  ///
  /// These results will be updated by the
  /// [spellCheckService] and used by the [spellCheckSuggestionsHandler] to
  /// build the [TextSpan] tree for text input and menus for replacement
  /// suggestions of misspelled words.
  SpellCheckResults? spellCheckResults;

  /// Configuration that indicates that spell check should not be run on text
  /// input and/or spell check is not implemented on the respective platform.
  static SpellCheckConfiguration disabled = SpellCheckConfiguration();
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
///  * [EditableText], which may use this handler to display results.
class DefaultSpellCheckSuggestionsHandler with SpellCheckSuggestionsHandler {
  /// Creates a handler to use for spell checking text input based on the
  /// provided platform.
  DefaultSpellCheckSuggestionsHandler(this.platform);

  /// The platform that determines the style by which misspelled words will be
  /// indicated in the [TextSpan] tree.
  final TargetPlatform platform;

  /// The style used to indicate misspeleld words on Android.
  final TextStyle materialMisspelledTextStyle = const TextStyle(
      decoration: TextDecoration.underline,
      decorationColor: ColorSwatch<int>(
        0xFFF44336,
        <int, Color>{
          50: Color(0xFFFFEBEE),
          100: Color(0xFFFFCDD2),
          200: Color(0xFFEF9A9A),
          300: Color(0xFFE57373),
          400: Color(0xFFEF5350),
          500: Color(0xFFF44336),
          600: Color(0xFFE53935),
          700: Color(0xFFD32F2F),
          800: Color(0xFFC62828),
          900: Color(0xFFB71C1C),
        },
      ),
      decorationStyle: TextDecorationStyle.wavy);

  /// The style used to indicate misspeleld words on iOS.
  final TextStyle cupertinoMisspelledTextStyle = const TextStyle(
      decoration: TextDecoration.underline,
      decorationColor: Color.fromARGB(255, 255, 59, 48),
      decorationStyle: TextDecorationStyle.dotted);

  /// Adjusts spell check results to correspond to [newText] if the only results
  /// that the handler has access to are the [results] corresponding to
  /// [resultsText].
  ///
  /// Used in the case where the request for the spell check results of the
  /// [newText] is lagging to avoid display of incorrect results.
  List<SuggestionSpan> correctSpellCheckResults(
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
              currentSpan.suggestions);
          correctedSpellCheckResults.add(adjustedSpan);
        }
      } catch (e) {
        // currentSpan is now invalid and needs to be searched for in newText.
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
              currentSpan.suggestions);
          offset = foundIndex - currentSpan.range.start;

          correctedSpellCheckResults.add(adjustedSpan);
        }
      }
      spanPointer += 1;
    }

    return correctedSpellCheckResults;
  }

  @override
  TextSpan buildTextSpanWithSpellCheckSuggestions(
      TextEditingValue value,
      bool composingWithinCurrentTextRange,
      TextStyle? style,
      SpellCheckResults spellCheckResults) {
    List<SuggestionSpan>? correctedSpellCheckResults;
    TextStyle misspelledTextStyle;

    final List<SuggestionSpan> rawSpellCheckResults =
        spellCheckResults.suggestionSpans;
    final String spellCheckResultsText = spellCheckResults.spellCheckedText;

    if (spellCheckResultsText != value.text) {
      correctedSpellCheckResults = correctSpellCheckResults(
          value.text, spellCheckResultsText, rawSpellCheckResults);
    } else {
      correctedSpellCheckResults = rawSpellCheckResults;
    }

    switch (platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        misspelledTextStyle = cupertinoMisspelledTextStyle;
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        misspelledTextStyle = materialMisspelledTextStyle;
        break;
    }

    return TextSpan(
        style: style,
        children: buildSubtreesWithMisspelledWordsIndicated(
            correctedSpellCheckResults,
            value,
            style,
            misspelledTextStyle,
            composingWithinCurrentTextRange));
  }

  /// Builds [TextSpan] subtree for text with misspelled words.
  List<TextSpan> buildSubtreesWithMisspelledWordsIndicated(
      List<SuggestionSpan>? spellCheckSuggestions,
      TextEditingValue value,
      TextStyle? style,
      TextStyle misspelledTextStyle,
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
        style?.merge(misspelledTextStyle) ?? misspelledTextStyle;
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
          addComposingRegionTextSpans(tsTreeChildren, text, textPointer,
              composingRegion, style, composingTextStyle);
          tsTreeChildren.add(TextSpan(
              style: style,
              text: text.substring(composingRegion.end, endIndex)));
        } else {
          tsTreeChildren.add(TextSpan(
              style: style, text: text.substring(textPointer, endIndex)));
        }

        textPointer = endIndex;
      } else {
        endIndex =
            currSpan.range.end < text.length ? currSpan.range.end : text.length;
        currSpanIsComposingRegion = textPointer >= composingRegion.start &&
            endIndex <= composingRegion.end &&
            !composingWithinCurrentTextRange;
        tsTreeChildren.add(TextSpan(
            style: currSpanIsComposingRegion
                ? composingTextStyle
                : misspelledJointStyle,
            text: text.substring(currSpan.range.start, endIndex)));

        textPointer = endIndex;
        currSpanPointer += 1;
      }
    }

    if (textPointer < text.length) {
      if (textPointer < composingRegion.start &&
          !composingWithinCurrentTextRange) {
        addComposingRegionTextSpans(tsTreeChildren, text, textPointer,
            composingRegion, style, composingTextStyle);

        if (composingRegion.end != text.length) {
          tsTreeChildren.add(TextSpan(
              style: style,
              text: text.substring(composingRegion.end, text.length)));
        }
      } else {
        tsTreeChildren.add(TextSpan(
            style: style, text: text.substring(textPointer, text.length)));
      }
    }

    return tsTreeChildren;
  }

  /// Helper method to create [TextSpan] tree children for specified range of
  /// text up to and including the composing region.
  void addComposingRegionTextSpans(
      List<TextSpan> treeChildren,
      String text,
      int start,
      TextRange composingRegion,
      TextStyle? style,
      TextStyle composingTextStyle) {
    treeChildren.add(TextSpan(
        style: style, text: text.substring(start, composingRegion.start)));
    treeChildren.add(TextSpan(
        style: composingTextStyle,
        text: text.substring(composingRegion.start, composingRegion.end)));
  }
}
