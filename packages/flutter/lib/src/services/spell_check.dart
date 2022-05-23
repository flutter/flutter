import 'package:flutter/src/painting/text_span.dart';
import 'package:flutter/src/painting/text_style.dart';
import 'package:flutter/src/services/platform_channel.dart';
import 'package:flutter/src/services/system_channels.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'text_input.dart' show TextInputConnection;

////////////////////////////////////////////////////////////////////////////////
///                            START OF PR #1.1                              ///
////////////////////////////////////////////////////////////////////////////////

/// A data structure representing the spell check results for a misspelled range
/// of text. For example, one [SpellCheckSuggestionSpan] of the spell check
/// results for "Hello, wrold!" may be
/// ```dart
/// SpellCheckSuggestionSpan(7, 11, List<String>.from["word, world, old"])
/// ```
class SpellCheckSuggestionSpan {
  SpellCheckSuggestionSpan(
      this.startIndex, this.endIndex, this.replacementSuggestions) {
    assert(startIndex != null);
    assert(endIndex != null);
    assert(replacementSuggestions != null);
  }

  late final int startIndex;

  late final int endIndex;

  /// The alternate suggestions for mispelled range of text.
  ///
  /// The maximum length of this list depends on the spell checker used. If
  /// [DefaultSpellCheckService] is used, the maximum length of this list will be
  /// 5 on Android platforms and there will be no maximum length on iOS platforms.
  late final List<String> replacementSuggestions;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpellCheckSuggestionSpan &&
        other.startIndex == startIndex &&
        other.endIndex == endIndex &&
        listEquals<String>(
            other.replacementSuggestions, replacementSuggestions);
  }

  @override
  int get hashCode =>
      Object.hash(startIndex, endIndex, hashList(replacementSuggestions));
}

/// Controls how spell check is performed for text input.
///
/// The spell check configuration determines the [SpellCheckService] used to
/// fetch spell check results of type [List<SpellCheckSuggestionSpan>] and the
/// [SpellCheckSuggestionsHandler] used to mark and display replacement
/// suggestions for mispelled words within text input.
class SpellCheckConfiguration {
  SpellCheckConfiguration(
      {this.spellCheckService, this.spellCheckSuggestionsHandler});

  final SpellCheckService? spellCheckService;

  final SpellCheckSuggestionsHandler? spellCheckSuggestionsHandler;

  /// The most up-to-date spell check results for text input.
  ///
  /// These [SpellCheckSuggestionSpan]s will be updated by the
  /// [spellCheckService] and used by the [spellCheckSuggestionsHandler] to
  /// build the [TextSpan] tree for text input and menus for replacement
  /// suggestions of mispelled words.
  List<SpellCheckSuggestionSpan>? spellCheckResults;

  /// The text that corresponds to the [spellCheckResults].
  String? spellCheckResultsText;

  /// Configuration that indicates that spell check should not be run on text
  /// input and/or spell check is not implemented on the respective platform.
  static SpellCheckConfiguration disabled = SpellCheckConfiguration();
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
  Future<List<dynamic>> fetchSpellCheckSuggestions(Locale locale, String text);
}

/// Determines how mispelled words are indicated in text input and how
/// replacement suggestions for misspelled words are displayed via a menu.
///
/// See also:
///
/// * [DefaultSpellCheckSuggestionsHandler], implementation used on Android and
///   iOS platforms when spell check is enabled for an [EditableText] instance
///   but no [SpellCheckSuggestionsHandler] implementation is provided.
abstract class SpellCheckSuggestionsHandler {
  /// Builds [TextSpan] tree given the current state of the text input and spell
  /// check results.
  ///
  /// An implementation should handle any cases concerning the [spellCheckResults]
  /// being out of date with the [value] if the [DefaultSpellCheckService] is
  /// used due to the asynchronous communication between the Android and iOS
  /// engines and the framework.
  TextSpan buildTextSpanWithSpellCheckSuggestions(
      TextEditingValue value,
      bool composingWithinCurrentTextRange,
      TextStyle? style,
      List<SpellCheckSuggestionSpan>? spellCheckResults,
      String? spellCheckResultsText);

  /// NOTE: NOT INCLUDED IN PR 1.1:
  Widget buildSpellCheckSuggestionsToolbar(
      List<SpellCheckSuggestionSpan>? spellCheckResults,
      TextSelectionDelegate delegate,
      List<TextSelectionPoint> endpoints,
      Rect globalEditableRegion,
      Offset selectionMidpoint,
      double textLineHeight);
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
  Future<List<dynamic>> fetchSpellCheckSuggestions(
      Locale locale, String text) async {
    assert(locale != null);
    assert(text != null);

    List<dynamic> spellCheckResults = <dynamic>[];
    final List<dynamic> rawResults;

    //TODO(camillesimon): properly handle exception
    try {
      rawResults = await spellCheckChannel.invokeMethod(
        'SpellCheck.initiateSpellCheck',
        <String>[locale.toLanguageTag(), text],
      );
    } catch (e) {
      return spellCheckResults;
    }

    List<String> results = rawResults.cast<String>();

    String resultsText = results.removeAt(0);
    List<SpellCheckSuggestionSpan> spellCheckSuggestionSpans =
        <SpellCheckSuggestionSpan>[];

    results.forEach((String result) {
      List<String> resultParsed = result.split(".");
      spellCheckSuggestionSpans.add(SpellCheckSuggestionSpan(
          int.parse(resultParsed[0]),
          int.parse(resultParsed[1]),
          resultParsed[2].split("\n")));
    });

    spellCheckResults.add(resultsText);
    spellCheckResults.add(spellCheckSuggestionSpans);

    return spellCheckResults;
  }
}

class DefaultSpellCheckSuggestionsHandler
    implements SpellCheckSuggestionsHandler {
  int scssSpans_consumed_index = 0;
  int text_consumed_index = 0;

  List<SpellCheckSuggestionSpan>? reusableSpellCheckResults;
  String? reusableText;

  final TargetPlatform platform;

  DefaultSpellCheckSuggestionsHandler(this.platform);

  @override
  Widget buildSpellCheckSuggestionsToolbar(
      List<SpellCheckSuggestionSpan>? spellCheckResults,
      TextSelectionDelegate delegate,
      List<TextSelectionPoint> endpoints,
      Rect globalEditableRegion,
      Offset selectionMidpoint,
      double textLineHeight) {
    return _SpellCheckSuggestionsToolbar(
      platform: platform,
      delegate: delegate,
      endpoints: endpoints,
      globalEditableRegion: globalEditableRegion,
      selectionMidpoint: selectionMidpoint,
      textLineHeight: textLineHeight,
      spellCheckSuggestionSpans: spellCheckResults,
    );
  }

  // Provides a generous guesss of the spell check results for the current text if the spell check results for this text has not been received by the framework yet.
  // Assumes order of results matches that of the text
  List<SpellCheckSuggestionSpan> correctSpellCheckResults(String newText,
      String resultsText, List<SpellCheckSuggestionSpan> results) {
    List<SpellCheckSuggestionSpan> correctedSpellCheckResults =
        <SpellCheckSuggestionSpan>[];

    int span_pointer = 0;
    bool foundBadSpan = false;

    SpellCheckSuggestionSpan currentSpan;
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
      currentSpanStart = currentSpan.startIndex;
      currentSpanEnd = currentSpan.endIndex;

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
            correctedSpellCheckResults.add(SpellCheckSuggestionSpan(newStart,
                newStart + spanLength, currentSpan.replacementSuggestions));
            searchStart = newStart + spanLength;
          }
        }
      }

      span_pointer += 1;
    }

    return correctedSpellCheckResults;
  }

  // TODO(camillesimon): Pretty sure this can be replaced with a String method
  int? findBadSpan(String text, String spanText, int spanLength) {
    bool foundSpan = false;
    int text_pointer = 0;

    while (!foundSpan && text_pointer + spanLength < text.length) {
      int end = text_pointer + spanText.length;

      if (text.substring(text_pointer, end) == spanText) {
        return text_pointer;
      }

      text_pointer += 1;
    }
    return null;
  }

  // Temporary way to merge two resutls since set union is not working as expected
  List<SpellCheckSuggestionSpan> mergeResults(
      List<SpellCheckSuggestionSpan> oldResults,
      List<SpellCheckSuggestionSpan> newResults) {
    List<SpellCheckSuggestionSpan> mergedResults = <SpellCheckSuggestionSpan>[];
    ;
    int old_span_pointer = 0;
    int new_span_pointer = 0;

    while (old_span_pointer < oldResults.length &&
        new_span_pointer < newResults.length) {
      SpellCheckSuggestionSpan oldSpan = oldResults[old_span_pointer];
      SpellCheckSuggestionSpan newSpan = newResults[new_span_pointer];

      if (oldSpan.startIndex == newSpan.startIndex) {
        if (!mergedResults.contains(oldSpan)) {
          mergedResults.add(oldSpan);
        }

        old_span_pointer += 1;
        new_span_pointer += 1;
      } else {
        if (oldSpan.startIndex < newSpan.startIndex) {
          // simplifying assumption that spans do not overlap for now
          if (!mergedResults.contains(oldSpan)) {
            mergedResults.add(oldSpan);
          }
          old_span_pointer += 1;
        } else {
          if (!mergedResults.contains(newSpan)) {
            mergedResults.add(newSpan);
          }
          new_span_pointer += 1;
        }
      }
    }

    while (old_span_pointer < oldResults.length) {
      mergedResults.add(oldResults[old_span_pointer]);
      old_span_pointer += 1;
    }

    while (new_span_pointer < newResults.length) {
      mergedResults.add(newResults[new_span_pointer]);
      new_span_pointer += 1;
    }

    return mergedResults;
  }

  @override
  TextSpan buildTextSpanWithSpellCheckSuggestions(
      TextEditingValue value,
      bool composingWithinCurrentTextRange,
      TextStyle? style,
      List<SpellCheckSuggestionSpan>? rawSpellCheckResults,
      String? spellCheckResultsText) {
    scssSpans_consumed_index = 0;
    text_consumed_index = 0;

    List<SpellCheckSuggestionSpan>? spellCheckResults;
    TextStyle misspelledStyle;

    if (spellCheckResultsText != value.text) {
      spellCheckResults = correctSpellCheckResults(
          value.text, spellCheckResultsText!, rawSpellCheckResults!);
    } else if (reusableText != null &&
        reusableText == spellCheckResultsText &&
        reusableSpellCheckResults != null &&
        rawSpellCheckResults != null &&
        !listEquals(reusableSpellCheckResults, rawSpellCheckResults)) {
      spellCheckResults =
          mergeResults(reusableSpellCheckResults!, rawSpellCheckResults);
    } else {
      spellCheckResults = rawSpellCheckResults;
    }

    reusableSpellCheckResults = spellCheckResults;
    reusableText = value.text;

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
              spellCheckResults ?? <SpellCheckSuggestionSpan>[],
              value.text,
              style,
              misspelledStyle,
              false));
    } else {
      return TextSpan(
        style: style,
        children: <TextSpan>[
          TextSpan(
              children: buildSubtreesWithMisspelledWordsIndicated(
                  spellCheckResults ?? <SpellCheckSuggestionSpan>[],
                  value.composing.textBefore(value.text),
                  style,
                  misspelledStyle,
                  false)),
          TextSpan(
              children: buildSubtreesWithMisspelledWordsIndicated(
                  spellCheckResults ?? <SpellCheckSuggestionSpan>[],
                  value.composing.textInside(value.text),
                  style,
                  misspelledStyle,
                  true)),
          TextSpan(
              children: buildSubtreesWithMisspelledWordsIndicated(
                  spellCheckResults ?? <SpellCheckSuggestionSpan>[],
                  value.composing.textAfter(value.text),
                  style,
                  misspelledStyle,
                  false)),
        ],
      );
    }
  }

//TODO(camillesimon): Replace method of building TextSpan tree in three parts with method of building in one part. Attempt started below.
//   @override
//   TextSpan buildTextSpanWithSpellCheckSuggestions(
//       List<SpellCheckSuggestionSpan>? spellCheckResults,
//       TextEditingValue value, TextStyle? style, bool composingWithinCurrentTextRange) {

//       TextStyle misspelledStyle;

//       switch(platform) {
//           case TargetPlatform.android:
//           default:
//             misspelledStyle = TextStyle(decoration: TextDecoration.underline,
//                             decorationColor: Colors.red,
//                             decorationStyle: TextDecorationStyle.wavy);
//             break;
//       }

//     return TextSpan(
//         style: style,
//         children: buildSubtreesWithMisspelledWordsIndicated(spellCheckResults ?? <SpellCheckSuggestionSpan>[], value, style, misspelledStyle, composingWithinCurrentTextRange));
//     }

//     /// Helper method for building TextSpan trees.
//     List<TextSpan> buildSubtreesWithMisspelledWordsIndicated(List<SpellCheckSuggestionSpan> spellCheckSuggestions, TextEditingValue value, TextStyle? style, TextStyle misspelledStyle, bool whatever) {
//       List<TextSpan> tsTreeChildren = <TextSpan>[];
//       String text = value.text;
//       int textLength= text.length;
//       int text_pointer = 0;
//       int scss_pointer = 0;
//       bool isComposing;
//       bool remainingResults = scss_pointer < spellCheckSuggestions.length;

//       bool composingWithinCurrentTextRange = false;

//       TextStyle composingStyle = style?.merge(const TextStyle(decoration: TextDecoration.underline)) ?? TextStyle(decoration: TextDecoration.underline);
//       TextStyle misspelledJointStyle = overrideTextSpanStyle(style, misspelledStyle);

//       SpellCheckSuggestionSpan currScssSpan = spellCheckSuggestions[scss_pointer];

//         // while (i) the text is not totally consumed or (ii) the suggestsion are not totally consumed
//         while (text_pointer < textLength || remainingResults) {
//             int end_index;
//             if (scss_pointer < spellCheckSuggestions.length) {
//                 currScssSpan = spellCheckSuggestions[scss_pointer];
//             } else {
//                 remainingResults = false;
//             }

//             // we either ignore composing entirely to maintain tree integrity or check if where we are in the text is within the composing region
//             // isComposing = composingWithinCurrentTextRange ? false : (text_pointer == value.composing.startIndex);
//             // print(value.composing.startIndex);
//             isComposing = (text_pointer == value.composing.startIndex);

//             // print("BUILDING: ${composingWithinCurrentTextRange} + ${text.substring(text_pointer)}");

//             // we are in composing region...
//             if (isComposing) {
//                 // and are misspelled (meaning results remain) -- we want to draw current word (text_pointer : value.composing.endIndex) with underline and advance scss_pointer
//                 if (remainingResults && text_pointer == currScssSpan.startIndex) {
//                     end_index = value.composing.endIndex;
//                     tsTreeChildren.add(TextSpan(style: composingStyle,
//                             text: text.substring(text_pointer, end_index)));
//                     text_pointer = end_index;
//                     scss_pointer += 1;
//                 }
//                 // and not misspelled -- we want to draw current word (text_pointer : value.composing.endIndex) with underline and not advance scss_pointer
//                 else {
//                     end_index = value.composing.endIndex;
//                     tsTreeChildren.add(TextSpan(style: composingStyle,
//                             text: text.substring(text_pointer, end_index)));
//                     text_pointer = end_index;
//                 }
//             }
//             // we are not in composing region but results remain...
//             else if (remainingResults) {
//                 // and are misspelled -- we want to draw current word (text_pointer : currScssSpan.endIndex) [MAY HAVE TO ADD FIX HERE] and advance scss_pointer
//                 if (text_pointer == currScssSpan.startIndex) {
//                     end_index = currScssSpan.endIndex + 1;
//                     tsTreeChildren.add(TextSpan(style: misspelledJointStyle,
//                             text: text.substring(text_pointer, end_index)));
//                     text_pointer = end_index;
//                     scss_pointer += 1;
//                 }
//                 // and not misspelled -- we want to draw as per usual until we reach (i) the start of the composing region or (ii) the start of the next spell check result
//                 else {
//                     if (!composingWithinCurrentTextRange) {
//                         end_index = value.composing.startIndex >= text_pointer ? ((currScssSpan.startIndex >= value.composing.startIndex) ? value.composing.startIndex : currScssSpan.startIndex) : currScssSpan.startIndex;
//                     } else {
//                         end_index = currScssSpan.startIndex;
//                     }

//                     tsTreeChildren.add(TextSpan(style: style,
//                                                 text: text.substring(text_pointer, end_index)));
//                     text_pointer = end_index;
//                 }

//             }
//             // we are not in composing region and no results remain...
//             else {
//                 if (!composingWithinCurrentTextRange) {
//                 end_index = (value.composing.startIndex >= text_pointer) ? value.composing.startIndex : textLength;
//                 } else {
//                 end_index = textLength;
//                 }
//                 tsTreeChildren.add(TextSpan(style: style,
//                                             text: text.substring(text_pointer, end_index)));
//                 text_pointer = end_index;
//             }
//         }

//         return tsTreeChildren;
//   }

  /// Helper method for building TextSpan trees.
  List<TextSpan> buildSubtreesWithMisspelledWordsIndicated(
      List<SpellCheckSuggestionSpan> spellCheckSuggestions,
      String text,
      TextStyle? style,
      TextStyle misspelledStyle,
      bool isComposing) {
    List<TextSpan> tsTreeChildren = <TextSpan>[];
    int text_pointer = 0;

    TextStyle composingStyle =
        style?.merge(const TextStyle(decoration: TextDecoration.underline)) ??
            TextStyle(decoration: TextDecoration.underline);
    TextStyle misspelledJointStyle =
        overrideTextSpanStyle(style, misspelledStyle);

    if (scssSpans_consumed_index < spellCheckSuggestions.length) {
      int scss_pointer = scssSpans_consumed_index;
      SpellCheckSuggestionSpan currScssSpan =
          spellCheckSuggestions[scss_pointer];
      int span_pointer = currScssSpan.startIndex;

      // while (i) the text is not totally consumed, (ii) the suggestsion are not totally consumed, (iii) there is a suggestion within the range of the text
      while (text_pointer < text.length &&
          scss_pointer < spellCheckSuggestions.length &&
          (currScssSpan.startIndex - text_consumed_index) < text.length) {
        int end_index;
        currScssSpan = spellCheckSuggestions[scss_pointer];

        // if the next suggestion is further down the line than the current words
        if ((currScssSpan.startIndex - text_consumed_index) > text_pointer) {
          end_index =
              (currScssSpan.startIndex - text_consumed_index) < text.length
                  ? (currScssSpan.startIndex - text_consumed_index)
                  : text.length;
          tsTreeChildren.add(TextSpan(
              style: isComposing ? composingStyle : style,
              text: text.substring(text_pointer, end_index)));
          text_pointer = end_index;
        }
        // if the next suggestion is where the current word is
        else {
          //   print((currScssSpan.endIndex - text_consumed_index + 1) < text.length);
          // print(currScssSpan.startIndex);
          // print(text_consumed_index);
          end_index =
              (currScssSpan.endIndex - text_consumed_index + 1) < text.length
                  ? (currScssSpan.endIndex - text_consumed_index + 1)
                  : text.length;
          //   print(end_index);
          tsTreeChildren.add(TextSpan(
              style: isComposing ? composingStyle : misspelledJointStyle,
              text: text.substring(
                  (currScssSpan.startIndex - text_consumed_index), end_index)));

          text_pointer = end_index;
          scss_pointer += 1;
        }
      }

      text_consumed_index = text_pointer + text_consumed_index;

      // Add remaining text if there is any
      if (text_pointer < text.length) {
        tsTreeChildren.add(TextSpan(
            style: isComposing ? composingStyle : style,
            text: text.substring(text_pointer, text.length)));
        text_consumed_index = text.length + text_consumed_index;
      }
      scssSpans_consumed_index = scss_pointer;
      //   print("IF CASE ${tsTreeChildren}");
      return tsTreeChildren;
    } else {
      text_consumed_index = text.length;
      //   print("ELSE CASE: ${ <TextSpan>[TextSpan(text: text, style: isComposing ? composingStyle : style)]}");
      return <TextSpan>[
        TextSpan(text: text, style: isComposing ? composingStyle : style)
      ];
    }
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
    required this.spellCheckSuggestionSpans,
  }) : super(key: key);

  final TargetPlatform platform;
  final TextSelectionDelegate delegate;
  final List<TextSelectionPoint> endpoints;
  final Rect globalEditableRegion;
  final Offset selectionMidpoint;
  final double textLineHeight;
  final List<SpellCheckSuggestionSpan>? spellCheckSuggestionSpans;

  @override
  _SpellCheckSuggestionsToolbarState createState() =>
      _SpellCheckSuggestionsToolbarState();
}

class _SpellCheckSuggestionsToolbarState
    extends State<_SpellCheckSuggestionsToolbar> with TickerProviderStateMixin {
  SpellCheckSuggestionSpan? findSuggestions(int curr_index,
      List<SpellCheckSuggestionSpan> spellCheckSuggestionSpans) {
    int left_index = 0;
    int right_index = spellCheckSuggestionSpans.length - 1;
    int mid_index = 0;

    while (left_index <= right_index) {
      mid_index = (left_index + (right_index - left_index) / 2).floor();

      if (spellCheckSuggestionSpans[mid_index].startIndex <= curr_index &&
          spellCheckSuggestionSpans[mid_index].endIndex + 1 >= curr_index) {
        return spellCheckSuggestionSpans[mid_index];
      }

      if (spellCheckSuggestionSpans[mid_index].startIndex <= curr_index) {
        left_index = left_index + 1;
      } else {
        right_index = right_index - 1;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.spellCheckSuggestionSpans == null ||
        widget.spellCheckSuggestionSpans!.length == 0) {
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

    SpellCheckSuggestionSpan? relevantSpan =
        findSuggestions(cursorIndex, widget.spellCheckSuggestionSpans!);

    if (relevantSpan == null) {
      return const SizedBox.shrink();
    }
    final List<_SpellCheckSuggestionsToolbarItemData> itemDatas =
        <_SpellCheckSuggestionsToolbarItemData>[];

    relevantSpan.replacementSuggestions.forEach((String suggestion) {
      itemDatas.add(_SpellCheckSuggestionsToolbarItemData(
        label: suggestion,
        onPressed: () {
          widget.delegate.replaceSelection(SelectionChangedCause.toolbar,
              suggestion, relevantSpan.startIndex, relevantSpan.endIndex + 1);
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
