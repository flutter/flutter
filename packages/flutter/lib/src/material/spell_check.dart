import 'package:flutter/src/painting/text_span.dart';
import 'package:flutter/src/painting/text_style.dart';
import 'package:flutter/src/widgets/spell_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// Provides logic for displaying spell check suggestions for Android.
class MaterialSpellCheckerControls extends SpellCheckerControls{
    /// Responsible for causing the SpellCheckerSuggestionsToolbar to appear.
    /// This toolbar will allow for tap and replace of suggestions for misspelled 
    /// words.
    /// See calls in
    /// (1) _TextFieldSelectionGestureDetectorBuilder [material/text_field.dart]
    /// (2) EditableTextState [editable_text.dart]
    /// (3) MaterialTextSelectionControls [material/text_selection.dart]
    Widget buildSpellCheckerSuggestionsToolbar(
        List<SpellCheckerSuggestionSpan> spellCheckerSuggestionSpans) {
            //TODO(camillesimon): build spell checker suggestion toolbar here
            print("mama I made it!");
            return SizedBox.shrink();
        }
}
/// Provides logic for indicating misspelled words for Android.
class MaterialMisspelledWordsHandler extends MisspelledWordsHandler {
    //TODO(camillesimon): add comments, clean up code
    int scssSpans_consumed_index = 0;
    int text_consumed_index = 0;

    /// Responsible for rebuilding the TextSpan with the TextStyle changed for all 
    /// of the misspelled words.
    /// See call in EditableTextState [editable_text.dart]
    TextSpan buildWithMisspelledWordsIndicated(List<SpellCheckerSuggestionSpan> spellCheckerSuggestionSpans, 
        TextEditingValue value, TextStyle? style) {
        // print("&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&");
        // print("|" + value.text + "|");
        // print("&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&");
        scssSpans_consumed_index = 0;
        text_consumed_index = 0;
        return TextSpan(
            style: style,
            children: <TextSpan>[
                TextSpan(children: buildSubtreesWithMisspelledWordsIndicated(spellCheckerSuggestionSpans, value.composing.textBefore(value.text), style)),
                TextSpan(children: buildSubtreesWithMisspelledWordsIndicated(spellCheckerSuggestionSpans, value.composing.textInside(value.text), style?.merge(const TextStyle(decoration: TextDecoration.underline)
                    ?? const TextStyle(decoration: TextDecoration.underline)))),
                TextSpan(children: buildSubtreesWithMisspelledWordsIndicated(spellCheckerSuggestionSpans, value.composing.textAfter(value.text), style)),
            ],
        );
    }

    List<TextSpan> buildSubtreesWithMisspelledWordsIndicated(List<SpellCheckerSuggestionSpan> spellCheckerSuggestionSpans, String text, TextStyle? style) {
        // print("-------------------------------------------------START--------------------------------------------------");
        // print("|" + text + "|");
        // print("SCSS CONSUMED IND: " + scssSpans_consumed_index.toString());
        // print("TEXT CONSUMED IND: " + text_consumed_index.toString());
        // print("SCS SPAN LENGTH: " + spellCheckerSuggestionSpans.length.toString());
        List<TextSpan> tsTreeChildren = <TextSpan>[];
        int text_pointer = 0;

        if (scssSpans_consumed_index < spellCheckerSuggestionSpans.length) {
            // print("-------------------------------------------------FIRST CONDITION REACHED--------------------------------------------------");
            int scss_pointer = scssSpans_consumed_index;
            SpellCheckerSuggestionSpan currScssSpan = spellCheckerSuggestionSpans[scss_pointer];
            int span_pointer = currScssSpan.start;

            while (text_pointer < text.length && scss_pointer < spellCheckerSuggestionSpans.length && (currScssSpan.start-text_consumed_index) < text.length) {
                // print("TEXT POINTER: " + text_pointer.toString());
                // print("SCSS POINTER: " + scss_pointer.toString());
                int end_index;
                currScssSpan = spellCheckerSuggestionSpans[scss_pointer];
                // print("SPAN START: " + currScssSpan.start.toString());
                // print("SPAN END: " + currScssSpan.end.toString());
                if ((currScssSpan.start-text_consumed_index) > text_pointer) {
                    // print("-------------------------------------------------CASE 1--------------------------------------------------");
                    end_index = (currScssSpan.start-text_consumed_index) < text.length ? (currScssSpan.start-text_consumed_index) : text.length;
                    // print("END INDEX: " + end_index.toString());
                    tsTreeChildren.add(TextSpan(style: style,
                                                text: text.substring(text_pointer, end_index)));//currScssSpan.start)));
                    // print("TEXT ADDED: |" + text.substring(text_pointer, end_index) + "|");
                    text_pointer = end_index; //(currScssSpan.start-text_consumed_index);
                }
                else {
                    // print("-------------------------------------------------CASE 2--------------------------------------------------");
                    end_index = (currScssSpan.end - text_consumed_index + 1) < text.length ? (currScssSpan.end - text_consumed_index + 1) : text.length;
                    // print("END INDEX: " + end_index.toString());
                    tsTreeChildren.add(TextSpan(style: overrideTextSpanStyle(style),
                                                text: text.substring((currScssSpan.start-text_consumed_index), end_index)));
                    // print("TEXT ADDED: |" + text.substring((currScssSpan.start-text_consumed_index), end_index) + "|");
                    text_pointer = end_index; // (currScssSpan.end-text_consumed_index) + 1;
                    scss_pointer += 1;
                }
                // print("--------------------------------------------------------------------------------------------------------------");
            }

            text_consumed_index = text_pointer + text_consumed_index;

            // Add remaining text
            if (text_pointer < text.length) {
                // print("----------------------------------------------ADDING FINAL TEXT--------------------------------------------------");
                tsTreeChildren.add(TextSpan(style: style, text: text.substring(text_pointer, text.length)));
                // print("TEXT POINTER: " + text_pointer.toString());
                // print(" TEXT ADDED: |" + text.substring(text_pointer, text.length)+ "|");
                text_consumed_index = text.length + text_consumed_index;
            }
            scssSpans_consumed_index = scss_pointer;
            return tsTreeChildren;
        } else {
            // print("-------------------------------------------------NO MORE SUGGESTIONS--------------------------------------------------");
            text_consumed_index = text.length;
            // print(" TEXT ADDED: |" + text + "|");
            return <TextSpan>[TextSpan(text: text, style: style)];
        }
    }

    /// Responsible for defining the behavior of overriding/merging
    /// the TestStyle specified for a particular TextSpan with the style used to
    /// indicate misspelled words (straight red underline for Android).
    /// Will be used in buildWithMisspelledWordsIndicated(...) method above.
    TextStyle overrideTextSpanStyle(TextStyle? currentTextStyle) {
        TextStyle misspelledStyle = TextStyle(decoration: TextDecoration.underline,
                                decorationColor: Colors.red,
                                decorationStyle: TextDecorationStyle.wavy);
        return currentTextStyle?.merge(misspelledStyle)
            ?? misspelledStyle;
    }
}
