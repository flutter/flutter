// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart'
    show SpellCheckResults, SpellCheckService, SuggestionSpan, TextEditingValue;

////////////////////////////////////////////////////////////////////////////////
///                            START OF PR #1                                ///
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

  /// NOTE: NOT INCLUDED IN PR 1:
  Widget buildSpellCheckSuggestionsToolbar(
      TextSelectionDelegate delegate,
      List<TextSelectionPoint> endpoints,
      Rect globalEditableRegion,
      Offset selectionMidpoint,
      double textLineHeight,
      SpellCheckResults? spellCheckResults);
}

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

    SuggestionSpan currentSpan;
    String currentSpanText;
    String newSpanText;
    int offset = 0;
    int searchStart = 0; // Used for simplifying assumption to avoid searching the whole text each time.
    bool foundCurrentSpan = false;

    while (span_pointer < results.length) {
      currentSpan = results[span_pointer];
      currentSpanText = resultsText.substring(currentSpan.range.start, currentSpan.range.end);

      try {
        newSpanText = newText.substring(currentSpan.range.start + offset, currentSpan.range.end + offset);

        if (newSpanText == currentSpanText) {
          foundCurrentSpan = true;
          searchStart = currentSpan.range.end + offset;
          SuggestionSpan adjustedSpan = 
            SuggestionSpan(TextRange(start: currentSpan.range.start + offset, end: searchStart),
              currentSpan.suggestions);
          correctedSpellCheckResults.add(adjustedSpan);
        }
      } catch(e) {
        // currentSpan was not found and needs to be searched for.
      }

      if (!foundCurrentSpan) {
          RegExp regex = RegExp('\\b$currentSpanText\\b');
          int foundIndex = newText.substring(searchStart).indexOf(regex);

          if (foundIndex >= 0) {
            foundIndex += searchStart;
            int spanLength = currentSpan.range.end - currentSpan.range.start;
            searchStart = foundIndex + spanLength;
            SuggestionSpan adjustedSpan = 
              SuggestionSpan(TextRange(start: foundIndex, end: searchStart), 
                currentSpan.suggestions);
            offset = foundIndex - currentSpan.range.start;

            correctedSpellCheckResults.add(adjustedSpan);
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

    return TextSpan(
      style: style,
      children: buildSubtreesWithMisspelledWordsIndicated(
          correctedSpellCheckResults,
          value,
          style,
          misspelledStyle,
          composingWithinCurrentTextRange));
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
    TextRange composingRegion = value.composing;
    TextStyle composingStyle =
        style?.merge(const TextStyle(decoration: TextDecoration.underline)) ??
            TextStyle(decoration: TextDecoration.underline);
    TextStyle misspelledJointStyle =
        style?.merge(misspelledStyle) ?? misspelledStyle;

    print("STYLE: ${style}");
    print("MISPELLED STYLE: ${misspelledJointStyle}");

    int scss_pointer = 0;

    while (text_pointer < text.length && spellCheckSuggestions != null &&
        scss_pointer < spellCheckSuggestions.length) {
      int end_index;
      SuggestionSpan currScssSpan = spellCheckSuggestions[scss_pointer];

      if (currScssSpan.range.start > text_pointer) {
        end_index = currScssSpan.range.start < text.length
            ? currScssSpan.range.start
            : text.length;
        bool isComposingWithin = composingRegion.start >= text_pointer
          && composingRegion.end <= end_index && !composingWithinCurrentTextRange;

        if (isComposingWithin) {
          addComposingRegionTextSpans(
            tsTreeChildren, text, text_pointer, composingRegion, style, composingStyle);
          tsTreeChildren.add(TextSpan(
            style: style,
            text: text.substring(composingRegion.end, end_index)));
        } else {
            tsTreeChildren.add(TextSpan(
              style: style,
              text: text.substring(text_pointer, end_index)));
        }

        text_pointer = end_index;
      } else {
        end_index = currScssSpan.range.end < text.length
            ? currScssSpan.range.end
            : text.length;
        bool isComposing = text_pointer >= composingRegion.start &&
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
        addComposingRegionTextSpans(
          tsTreeChildren, text, text_pointer, composingRegion, style, composingStyle);
        if (composingRegion.end != text.length) {
        tsTreeChildren.add(TextSpan(
            style: style,
            text: text.substring(composingRegion.end, text.length)));
        }
      } else {
        tsTreeChildren.add(TextSpan(
            style: style, text: text.substring(text_pointer, text.length)));
      }
    }

    return tsTreeChildren;
  }

  /// Helper method to create TextSpan tree children based on the composing region
  void addComposingRegionTextSpans(
    List<TextSpan> treeChildren,
    String text, int start,
    TextRange composingRegion,
    TextStyle? style,
    TextStyle composingStyle) {
    treeChildren.add(TextSpan(
        style: style,
        text: text.substring(start, composingRegion.start)));
    treeChildren.add(TextSpan(
        style: composingStyle,
        text: text.substring(composingRegion.start, composingRegion.end)));
  }
}

////////////////////////////////////////////////////////////////////////////////
///                             END OF PR #1                                 ///
////////////////////////////////////////////////////////////////////////////////

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
          suggestionSpans[mid_index].range.end >= curr_index) {
            return suggestionSpans[mid_index];
      }

      if (suggestionSpans[mid_index].range.start <= curr_index) {
        left_index = left_index;
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
              suggestion, relevantSpan.range.start, relevantSpan.range.end);
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
