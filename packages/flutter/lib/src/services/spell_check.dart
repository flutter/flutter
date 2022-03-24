import 'package:flutter/src/painting/text_span.dart';
import 'package:flutter/src/painting/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'text_input.dart' show TextInputConnection;

/// Provides representation for the results given by a spell checker for some
/// text.
class SpellCheckerSuggestionSpan {
    /// The index representing the start of a span including all correctly spelled
    /// or all misspelled words.
    late int start;

    /// The index representing the end of this span.
    late int end;

    /// The list of replacements returned from the spell checker for the word
    /// if it was misspelled.
    late List<String> replacementSuggestions;

    /// Responsible for making a SpellCheckerSuggestionSpan object from information
    /// received from the engine.
    SpellCheckerSuggestionSpan(int 
            start, int end, List<String> replacementSuggestions) {
        assert(start != null);
        assert(end != null);
        assert(replacementSuggestions != null);
        this.start = start;
        this.end = end;
        this.replacementSuggestions = replacementSuggestions;
    }
}

/// Creates a configuration that controls how spell check is handled in a subtree of text input related widgets.
class SpellCheckConfiguration {
    /// Service used for spell checking.
    final SpellCheckService? spellCheckService;

    /// Handler used to display spell check results
    final SpellCheckSuggestionsHandler? spellCheckSuggestionsHandler;

    /// Spell check results to pass from spellCheckService to spellCheckSuggestionsHandler
    List<SpellCheckerSuggestionSpan>? spellCheckResults;

    SpellCheckConfiguration({
        this.spellCheckService,
        this.spellCheckSuggestionsHandler
    });

    /// SpellCheckConfiguration that indicates that spell check should not be run on text input.
    static SpellCheckConfiguration disabled = SpellCheckConfiguration();

    static SpellCheckService? getDefaultSpellCheckService(TargetPlatform platform) {
        switch(platform) {
            case TargetPlatform.android:
                return MaterialSpellCheckService();
            default:
                return null;

        }
    }
}

/// Interface that represents the core functionality needed to support spell check on text input.
abstract class SpellCheckService {
    // Initiates spell check. Expected to set spellCheckSuggestions in handler if synchronous.
    Future<List<SpellCheckerSuggestionSpan>> fetchSpellCheckSuggestions(Locale locale, String text);
}

/// Interface that represents the core functionality needed to display results of spell check.
abstract class SpellCheckSuggestionsHandler {
    // Builds toolbar/menu that will display spell check results.
    Widget buildSpellCheckSuggestionsToolbar(
        List<SpellCheckerSuggestionSpan>? spellCheckResults,
        TextSelectionDelegate delegate, 
        List<TextSelectionPoint> endpoints, Rect globalEditableRegion, 
        Offset selectionMidpoint, double textLineHeight);

    // Build TextSpans with misspelled words indicated.
    TextSpan buildTextSpanWithSpellCheckSuggestions(
        List<SpellCheckerSuggestionSpan>? spellCheckResults,
        TextEditingValue value, TextStyle? style, bool ignoreComposing);
}

class DefaultSpellCheckSuggestionsHandler implements SpellCheckSuggestionsHandler {
    int scssSpans_consumed_index = 0;
    int text_consumed_index = 0;

    final TargetPlatform platform;

    DefaultSpellCheckSuggestionsHandler(this.platform);

    @override
    Widget buildSpellCheckSuggestionsToolbar(
        List<SpellCheckerSuggestionSpan>? spellCheckResults,
        TextSelectionDelegate delegate, 
        List<TextSelectionPoint> endpoints, Rect globalEditableRegion, 
        Offset selectionMidpoint, double textLineHeight) {
            return _SpellCheckerSuggestionsToolbar(
            platform: platform,
            delegate: delegate,
            endpoints: endpoints,
            globalEditableRegion: globalEditableRegion,
            selectionMidpoint: selectionMidpoint,
            textLineHeight: textLineHeight,
            spellCheckerSuggestionSpans: spellCheckResults,
            );
        }

  @override
  TextSpan buildTextSpanWithSpellCheckSuggestions(
      List<SpellCheckerSuggestionSpan>? spellCheckResults,
      TextEditingValue value, TextStyle? style, bool ignoreComposing) {
      scssSpans_consumed_index = 0;
      text_consumed_index = 0;

      TextStyle misspelledStyle;

      switch(platform) {
          case TargetPlatform.android:
          default:
            misspelledStyle = TextStyle(decoration: TextDecoration.underline,
                            decorationColor: Colors.red,
                            decorationStyle: TextDecorationStyle.wavy);
            break;
      }

      if (ignoreComposing) {
          return TextSpan(
              style: style,
              children: buildSubtreesWithMisspelledWordsIndicated(spellCheckResults ?? <SpellCheckerSuggestionSpan>[], value.text, style, misspelledStyle, false)
          );
      } else {
          return TextSpan(
              style: style,
              children: <TextSpan>[
                  TextSpan(children: buildSubtreesWithMisspelledWordsIndicated(spellCheckResults ?? <SpellCheckerSuggestionSpan>[], value.composing.textBefore(value.text), style, misspelledStyle, false)),
                  TextSpan(children: buildSubtreesWithMisspelledWordsIndicated(spellCheckResults ?? <SpellCheckerSuggestionSpan>[], value.composing.textInside(value.text), style, misspelledStyle, true)),
                  TextSpan(children: buildSubtreesWithMisspelledWordsIndicated(spellCheckResults ?? <SpellCheckerSuggestionSpan>[], value.composing.textAfter(value.text), style, misspelledStyle, false)),
              ],
          );
      }
    }

    /// Helper method for building TextSpan trees.
    List<TextSpan> buildSubtreesWithMisspelledWordsIndicated(List<SpellCheckerSuggestionSpan> spellCheckSuggestions, String text, TextStyle? style, TextStyle misspelledStyle, bool isComposing) {
      List<TextSpan> tsTreeChildren = <TextSpan>[];
      int text_pointer = 0;

      if (scssSpans_consumed_index < spellCheckSuggestions.length) {
          int scss_pointer = scssSpans_consumed_index;
          SpellCheckerSuggestionSpan currScssSpan = spellCheckSuggestions[scss_pointer];
          int span_pointer = currScssSpan.start;

          // while (i) the text is not totally consumed, (ii) the suggestsion are not totally consumed, (iii) there is a suggestion within the range of the text
          while (text_pointer < text.length && scss_pointer < spellCheckSuggestions.length && (currScssSpan.start-text_consumed_index) < text.length) {
              int end_index;
              currScssSpan = spellCheckSuggestions[scss_pointer];

              // if the next suggestion is further down the line than the current words
              if ((currScssSpan.start-text_consumed_index) > text_pointer) {
                  end_index = (currScssSpan.start-text_consumed_index) < text.length ? (currScssSpan.start-text_consumed_index) : text.length;
                  tsTreeChildren.add(TextSpan(style: isComposing? style?.merge(const TextStyle(decoration: TextDecoration.underline)) : style,
                                              text: text.substring(text_pointer, end_index)));
                  text_pointer = end_index;
              }
              // if the next suggestion is where the current word is
              else {
                  end_index = (currScssSpan.end - text_consumed_index + 1) < text.length ? (currScssSpan.end - text_consumed_index + 1) : text.length;
                  tsTreeChildren.add(TextSpan(style: isComposing ? style?.merge(const TextStyle(decoration: TextDecoration.underline)) :  TextStyle(color: Color(0xfff44336),),//overrideTextSpanStyle(style, misspelledStyle),
                                              text: text.substring((currScssSpan.start-text_consumed_index), end_index)));

                  text_pointer = end_index;
                  scss_pointer += 1;
              }
          }

          text_consumed_index = text_pointer + text_consumed_index;

          // Add remaining text if there is any
          if (text_pointer < text.length) {
              tsTreeChildren.add(TextSpan(style: style, text: text.substring(text_pointer, text.length)));
              text_consumed_index = text.length + text_consumed_index;
          }
          scssSpans_consumed_index = scss_pointer;
          return tsTreeChildren;
      } else {
          text_consumed_index = text.length;
          return <TextSpan>[TextSpan(text: text, style: style)];
      }
  }

  /// Responsible for defining the behavior of overriding/merging
  /// the TestStyle specified for a particular TextSpan with the style used to
  /// indicate misspelled words (straight red underline for Android).
  /// Will be used in buildWithMisspelledWordsIndicated(...) method above.
  TextStyle overrideTextSpanStyle(TextStyle? currentTextStyle, TextStyle misspelledStyle) {
      return currentTextStyle?.merge(misspelledStyle)
          ?? misspelledStyle;
  }
}

  /****************************** Toolbar logic ******************************/
//TODO(camillesimon): Either remove implementation or replace with dropdown menu.
class _SpellCheckerSuggestionsToolbarItemData {
  const _SpellCheckerSuggestionsToolbarItemData({
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

class _SpellCheckerSuggestionsToolbar extends StatefulWidget {
  const _SpellCheckerSuggestionsToolbar({
    Key? key,
    required this.platform,
    required this.delegate,
    required this.endpoints,
    required this.globalEditableRegion,
    required this.selectionMidpoint,
    required this.textLineHeight,
    required this.spellCheckerSuggestionSpans,
  }) : super(key: key);

  final TargetPlatform platform;
  final TextSelectionDelegate delegate;
  final List<TextSelectionPoint> endpoints;
  final Rect globalEditableRegion;
  final Offset selectionMidpoint;
  final double textLineHeight;
  final List<SpellCheckerSuggestionSpan>? spellCheckerSuggestionSpans;

  @override
  _SpellCheckerSuggestionsToolbarState createState() => _SpellCheckerSuggestionsToolbarState();
}

class _SpellCheckerSuggestionsToolbarState extends State<_SpellCheckerSuggestionsToolbar> with TickerProviderStateMixin {

  SpellCheckerSuggestionSpan? findSuggestions(int curr_index, List<SpellCheckerSuggestionSpan> spellCheckerSuggestionSpans) {
    int left_index = 0;
    int right_index = spellCheckerSuggestionSpans.length - 1;
    int mid_index = 0;

    while (left_index <= right_index) {
        mid_index = (left_index + (right_index - left_index) / 2).floor();

        if (spellCheckerSuggestionSpans[mid_index].start <= curr_index && spellCheckerSuggestionSpans[mid_index].end + 1 >= curr_index) { 
            return spellCheckerSuggestionSpans[mid_index];
        }

        if (spellCheckerSuggestionSpans[mid_index].start <= curr_index) {
            left_index = left_index + 1;
        }
        else {
            right_index = right_index - 1;
        }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.spellCheckerSuggestionSpans == null || widget.spellCheckerSuggestionSpans!.length == 0) {
        return const SizedBox.shrink();
    }

    // Calculate the positioning of the menu. It is placed above the selection
    // if there is enough room, or otherwise below.
    final TextSelectionPoint startTextSelectionPoint = widget.endpoints[0];
    final TextSelectionPoint endTextSelectionPoint = widget.endpoints.length > 1
      ? widget.endpoints[1]
      : widget.endpoints[0];
    final Offset anchorAbove = Offset(
      widget.globalEditableRegion.left + widget.selectionMidpoint.dx,
      widget.globalEditableRegion.top + startTextSelectionPoint.point.dy - widget.textLineHeight - _kToolbarContentDistance,
    );
    final Offset anchorBelow = Offset(
      widget.globalEditableRegion.left + widget.selectionMidpoint.dx,
      widget.globalEditableRegion.top + endTextSelectionPoint.point.dy + _kToolbarContentDistanceBelow,
    );

    // Determine which buttons will appear so that the order and total number is
    // known. A button's position in the menu can slightly affect its
    // appearance.
    assert(debugCheckHasMaterialLocalizations(context));
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);

    // Determine which suggestions to show
    TextEditingValue value = widget.delegate.textEditingValue;
    int cursorIndex = value.selection.baseOffset;

    SpellCheckerSuggestionSpan? relevantSpan = findSuggestions(cursorIndex, widget.spellCheckerSuggestionSpans!);

    if (relevantSpan == null) {
        return const SizedBox.shrink();
    }
    final List<_SpellCheckerSuggestionsToolbarItemData> itemDatas = <_SpellCheckerSuggestionsToolbarItemData>[];

    relevantSpan.replacementSuggestions.forEach((String suggestion) {
        itemDatas.add(        
            _SpellCheckerSuggestionsToolbarItemData(
                label: suggestion,
                onPressed: () 
                {
                    widget.delegate.replaceSelection(SelectionChangedCause.toolbar, suggestion, relevantSpan.start, relevantSpan.end + 1);
                },
        ));
    });

    switch(widget.platform) {
        case TargetPlatform.android:
        default:
            return TextSelectionToolbar(
                anchorAbove: anchorAbove,
                anchorBelow: anchorBelow,
                children: itemDatas.asMap().entries.map((MapEntry<int, _SpellCheckerSuggestionsToolbarItemData> entry) {
                    return TextSelectionToolbarTextButton(
                    padding: TextSelectionToolbarTextButton.getPadding(entry.key, itemDatas.length),
                    onPressed: entry.value.onPressed,
                    child: Text(entry.value.label),
                    );
                }).toList(),
                );
                break;
    }
  }
}
