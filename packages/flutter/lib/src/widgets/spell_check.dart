import 'package:flutter/src/painting/text_span.dart';
import 'package:flutter/src/painting/text_style.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

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

/// Provides logic for displaying spell check suggestions. Defined as an
/// abstract class as the toolbar shown may differ between platforms.
abstract class SpellCheckerControls {
    /// Responsible for causing the SpellCheckerSuggestionsToolbar to appear.
    Widget buildSpellCheckerSuggestionsToolbar(TextSelectionDelegate delegate, List<TextSelectionPoint> endpoints, 
        Rect globalEditableRegion, Offset selectionMidpoint, double textLineHeight, 
        List<SpellCheckerSuggestionSpan>? spellCheckerSuggestionSpans);
}

/// Provides logic for indicating misspelled words. Implemented as an abstract
/// class since the TextStyle used to indicate this may differ between platforms.
abstract class MisspelledWordsHandler {
    /// Responsible for rebuilding the TextSpan with the TextStyle changed for all 
    /// of the misspelled words.
    TextSpan buildWithMisspelledWordsIndicated(List<SpellCheckerSuggestionSpan> spellCheckerSuggestionSpans, 
        TextEditingValue value, TextStyle? style, bool ignoreComposing);

    /// Responsible for defining the behavior of overriding/merging the TestStyle 
    /// specified for a particular TextSpan with the style used to indicate
    /// misspelled words.
    TextStyle overrideTextSpanStyle(TextStyle? currentTextStyle);
}


