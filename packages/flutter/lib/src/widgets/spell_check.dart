// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart'
    show SpellCheckResults, SpellCheckService, SuggestionSpan, TextEditingValue;

////////////////////////////////////////////////////////////////////////////////
///                            START OF PR #1.1                              ///
////////////////////////////////////////////////////////////////////////////////

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

  /// NOTE: NOT INCLUDED IN PR 1.1:
  Widget buildSpellCheckSuggestionsToolbar(
      TextSelectionDelegate delegate,
      List<TextSelectionPoint> endpoints,
      Rect globalEditableRegion,
      Offset selectionMidpoint,
      double textLineHeight,
      SpellCheckResults? spellCheckResults);
}

////////////////////////////////////////////////////////////////////////////////
///                             END OF PR #1.1                               ///
////////////////////////////////////////////////////////////////////////////////

class DefaultSpellCheckSuggestionsHandler with SpellCheckSuggestionsHandler {
  int scssSpans_consumed_index = 0;
  int text_consumed_index = 0;

  final TargetPlatform platform;

  DefaultSpellCheckSuggestionsHandler(this.platform);

  @override
  Widget buildSpellCheckSuggestionsToolbar(
      TextSelectionDelegate delegate,
      List<TextSelectionPoint> endpoints,
      Rect globalEditableRegion,
      Offset selectionMidpoint,
      double textLineHeight,
      SpellCheckResults? spellCheckResults) {
    return _SpellCheckSuggestionsToolbar(
      platform: platform,
      delegate: delegate,
      endpoints: endpoints,
      globalEditableRegion: globalEditableRegion,
      selectionMidpoint: selectionMidpoint,
      textLineHeight: textLineHeight,
      suggestionSpans: spellCheckResults!.suggestionSpans,
    );
  }

  // Provides a generous guesss of the spell check results for the current text if the spell check results for this text has not been received by the framework yet.
  // Assumes order of results matches that of the text
  List<SuggestionSpan> correctSpellCheckResults(
      String newText, String resultsText, List<SuggestionSpan> results) {
    List<SuggestionSpan> correctedSpellCheckResults = <SuggestionSpan>[];

    int span_pointer = 0;
    bool foundBadSpan = false;

    SuggestionSpan currentSpan;
    String oldSpanText;
    String newSpanText;
    int spanLength = 0;
    int newStart = 0;
    int searchStart = 0;

    int? start_index;
    int? end_index;
    bool spanWithinTextRange = true;

    int currentSpanStart = 0;
    int currentSpanEnd = 0;

    while (span_pointer < results.length) {
      currentSpan = results[span_pointer];
      currentSpanStart = currentSpan.range.start;
      currentSpanEnd = currentSpan.range.end;

      start_index = currentSpanStart < newText.length ? currentSpanStart : null;
      end_index = currentSpanEnd < newText.length ? currentSpanEnd : null;

      spanWithinTextRange = start_index != null && end_index != null;

      if (!spanWithinTextRange) {
        // No more of the spell check results will be within the range of the text
        break;
      } else {
        oldSpanText =
            resultsText.substring(currentSpanStart, currentSpanEnd + 1);
        newSpanText = newText.substring(currentSpanStart, currentSpanEnd + 1);

        if (oldSpanText == newSpanText) {
          searchStart = currentSpanEnd + 1;
          correctedSpellCheckResults.add(currentSpan);
        } else {
          spanLength = currentSpanEnd - currentSpanStart;
          RegExp regex = RegExp('\\b$oldSpanText\\b');
          int substring = newText.substring(searchStart).indexOf(regex);
          newStart = substring + searchStart;

          if (substring >= 0) {
            correctedSpellCheckResults.add(SuggestionSpan(TextRange(
                start: newStart, end: newStart + spanLength), currentSpan.suggestions));
            searchStart = newStart + spanLength;
          }
        }
      }

      span_pointer += 1;
    }

    return correctedSpellCheckResults;
  }

  @override
  TextSpan buildTextSpanWithSpellCheckSuggestions(
      TextEditingValue value,
      bool composingWithinCurrentTextRange,
      TextStyle? style,
      SpellCheckResults spellCheckResults) {
    scssSpans_consumed_index = 0;
    text_consumed_index = 0;

    List<SuggestionSpan>? correctedSpellCheckResults;
    TextStyle misspelledStyle;

    List<SuggestionSpan> rawSpellCheckResults =
        spellCheckResults.suggestionSpans;
    String spellCheckResultsText = spellCheckResults.spellCheckedText;

    if (spellCheckResultsText != value.text) {
      correctedSpellCheckResults = correctSpellCheckResults(
          value.text, spellCheckResultsText, rawSpellCheckResults);
    } else {
      correctedSpellCheckResults = rawSpellCheckResults;
    }

    switch (platform) {
      case TargetPlatform.android:
      default:
        misspelledStyle = TextStyle(
            decoration: TextDecoration.underline,
            decorationColor: Colors.red,
            decorationStyle: TextDecorationStyle.wavy);
        break;
    }

    if (composingWithinCurrentTextRange) {
      return TextSpan(
          style: style,
          children: buildSubtreesWithMisspelledWordsIndicated(
              correctedSpellCheckResults, value, style, misspelledStyle, true));
    } else {
      return TextSpan(
          style: style,
          children: buildSubtreesWithMisspelledWordsIndicated(
              correctedSpellCheckResults,
              value,
              style,
              misspelledStyle,
              false));
    }
  }

  /// Helper method for building TextSpan trees.
  List<TextSpan> buildSubtreesWithMisspelledWordsIndicated(
      List<SuggestionSpan>? spellCheckSuggestions,
      TextEditingValue value,
      TextStyle? style,
      TextStyle misspelledStyle,
      bool composingWithinCurrentTextRange) {
    List<TextSpan> tsTreeChildren = <TextSpan>[];
    int text_pointer = 0;

    String text = value.text;
    TextRange composingRegion = value.composing; // here
    TextStyle composingStyle =
        style?.merge(const TextStyle(decoration: TextDecoration.underline)) ??
            TextStyle(decoration: TextDecoration.underline);
    TextStyle misspelledJointStyle =
        overrideTextSpanStyle(style, misspelledStyle);

    int scss_pointer = 0;

    while (text_pointer < text.length && spellCheckSuggestions != null &&
        scss_pointer < spellCheckSuggestions.length) {
      int end_index;
      bool isComposing;
      SuggestionSpan currScssSpan = spellCheckSuggestions[scss_pointer];

      if (currScssSpan.range.start > text_pointer) {
        end_index = currScssSpan.range.start < text.length
            ? currScssSpan.range.start
            : text.length;
        isComposing = text_pointer >= composingRegion.start &&
            end_index <= composingRegion.end &&
            !composingWithinCurrentTextRange;
        tsTreeChildren.add(TextSpan(
            style: isComposing ? composingStyle : style,
            text: text.substring(text_pointer, end_index)));
        text_pointer = end_index;
      } else {
        end_index = currScssSpan.range.end + 1 < text.length
            ? (currScssSpan.range.end + 1)
            : text.length;
        isComposing = text_pointer >= composingRegion.start &&
            end_index <= composingRegion.end &&
            !composingWithinCurrentTextRange;
        tsTreeChildren.add(TextSpan(
            style: isComposing ? composingStyle : misspelledJointStyle,
            text: text.substring(currScssSpan.range.start, end_index)));

        text_pointer = end_index;
        scss_pointer += 1;
      }
    }

    if (text_pointer < text.length) {
      if (text_pointer < composingRegion.start &&
          !composingWithinCurrentTextRange) {
        tsTreeChildren.add(TextSpan(
            style: style,
            text: text.substring(text_pointer, composingRegion.start)));
        tsTreeChildren.add(TextSpan(
            style: composingStyle,
            text: text.substring(composingRegion.start, composingRegion.end)));
        tsTreeChildren.add(TextSpan(
            style: style,
            text: text.substring(composingRegion.end, text.length)));
      } else {
        tsTreeChildren.add(TextSpan(
            style: style, text: text.substring(text_pointer, text.length)));
      }
    }

    return tsTreeChildren;
  }

  /// Responsible for defining the behavior of overriding/merging
  /// the TestStyle specified for a particular TextSpan with the style used to
  /// indicate misspelled words (straight red underline for Android).
  /// Will be used in buildWithMisspelledWordsIndicated(...) method above.
  TextStyle overrideTextSpanStyle(
      TextStyle? currentTextStyle, TextStyle misspelledStyle) {
    return currentTextStyle?.merge(misspelledStyle) ?? misspelledStyle;
  }
}

/****************************** Toolbar logic ******************************/
//TODO(camillesimon): Either remove implementation or replace with dropdown menu.
class _SpellCheckSuggestionsToolbarItemData {
  const _SpellCheckSuggestionsToolbarItemData({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;
}

const double _kHandleSize = 22.0;

// Padding between the toolbar and the anchor.
const double _kToolbarContentDistanceBelow = _kHandleSize - 2.0;
const double _kToolbarContentDistance = 8.0;

class _SpellCheckSuggestionsToolbar extends StatefulWidget {
  const _SpellCheckSuggestionsToolbar({
    Key? key,
    required this.platform,
    required this.delegate,
    required this.endpoints,
    required this.globalEditableRegion,
    required this.selectionMidpoint,
    required this.textLineHeight,
    required this.suggestionSpans,
  }) : super(key: key);

  final TargetPlatform platform;
  final TextSelectionDelegate delegate;
  final List<TextSelectionPoint> endpoints;
  final Rect globalEditableRegion;
  final Offset selectionMidpoint;
  final double textLineHeight;
  final List<SuggestionSpan>? suggestionSpans;

  @override
  _SpellCheckSuggestionsToolbarState createState() =>
      _SpellCheckSuggestionsToolbarState();
}

class _SpellCheckSuggestionsToolbarState
    extends State<_SpellCheckSuggestionsToolbar> with TickerProviderStateMixin {
  SuggestionSpan? findSuggestions(
      int curr_index, List<SuggestionSpan> suggestionSpans) {
    int left_index = 0;
    int right_index = suggestionSpans.length - 1;
    int mid_index = 0;

    while (left_index <= right_index) {
      mid_index = (left_index + (right_index - left_index) / 2).floor();

      if (suggestionSpans[mid_index].range.start <= curr_index &&
          suggestionSpans[mid_index].range.end + 1 >= curr_index) {
            return suggestionSpans[mid_index];
      }

      if (suggestionSpans[mid_index].range.start <= curr_index) {
        left_index = left_index + 1;
      } else {
        right_index = right_index - 1;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.suggestionSpans == null || widget.suggestionSpans!.length == 0) {
      return const SizedBox.shrink();
    }

    // Calculate the positioning of the menu. It is placed above the selection
    // if there is enough room, or otherwise below.
    final TextSelectionPoint startTextSelectionPoint = widget.endpoints[0];
    final TextSelectionPoint endTextSelectionPoint =
        widget.endpoints.length > 1 ? widget.endpoints[1] : widget.endpoints[0];
    final Offset anchorAbove = Offset(
      widget.globalEditableRegion.left + widget.selectionMidpoint.dx,
      widget.globalEditableRegion.top +
          startTextSelectionPoint.point.dy -
          widget.textLineHeight -
          _kToolbarContentDistance,
    );
    final Offset anchorBelow = Offset(
      widget.globalEditableRegion.left + widget.selectionMidpoint.dx,
      widget.globalEditableRegion.top +
          endTextSelectionPoint.point.dy +
          _kToolbarContentDistanceBelow,
    );

    // Determine which buttons will appear so that the order and total number is
    // known. A button's position in the menu can slightly affect its
    // appearance.
    assert(debugCheckHasMaterialLocalizations(context));
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);

    // Determine which suggestions to show
    TextEditingValue value = widget.delegate.textEditingValue;
    int cursorIndex = value.selection.baseOffset;

    SuggestionSpan? relevantSpan =
        findSuggestions(cursorIndex, widget.suggestionSpans!);

    if (relevantSpan == null) {
      return const SizedBox.shrink();
    }
    final List<_SpellCheckSuggestionsToolbarItemData> itemDatas =
        <_SpellCheckSuggestionsToolbarItemData>[];

    relevantSpan.suggestions.forEach((String suggestion) {
      itemDatas.add(_SpellCheckSuggestionsToolbarItemData(
        label: suggestion,
        onPressed: () {
          widget.delegate.replaceSelection(SelectionChangedCause.toolbar,
              suggestion, relevantSpan.range.start, relevantSpan.range.end + 1);
        },
      ));
    });

    switch (widget.platform) {
      case TargetPlatform.android:
      default:
        return TextSelectionToolbar(
          anchorAbove: anchorAbove,
          anchorBelow: anchorBelow,
          children: itemDatas.asMap().entries.map(
              (MapEntry<int, _SpellCheckSuggestionsToolbarItemData> entry) {
            return TextSelectionToolbarTextButton(
              padding: TextSelectionToolbarTextButton.getPadding(
                  entry.key, itemDatas.length),
              onPressed: entry.value.onPressed,
              child: Text(entry.value.label),
            );
          }).toList(),
        );
        break;
    }
  }
}
