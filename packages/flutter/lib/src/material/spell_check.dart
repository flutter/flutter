import 'package:flutter/src/painting/text_span.dart';
import 'package:flutter/src/painting/text_style.dart';
import 'package:flutter/src/widgets/spell_check.dart';
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
    Widget showSpellCheckerSuggestions(
        List<SpellCheckerSuggestionSpan> spellCheckerSuggestionSpans) {
            //TODO(camillesimon): Show suggestions toolbar here.
        }
}
/// Provides logic for indicating misspelled words for Android.
class MaterialMisspelledWordsHandler extends MisspelledWordsHandler {
    /// Responsible for rebuilding the TextSpan with the TextStyle changed for all 
    /// of the misspelled words.
    /// See call in EditableTextState [editable_text.dart]
    TextSpan buildWithMisspelledWordsIndicated(List<SpellCheckerSuggestionSpan> spellCheckerSuggestionSpan, 
        TextEditingValue value) {
        //TODO(camillesimon): Build TextSpan tree here.
    }

    /// Responsible for defining the behavior of overriding/merging
    /// the TestStyle specified for a particular TextSpan with the style used to
    /// indicate misspelled words (straight red underline for Android).
    /// Will be used in buildWithMisspelledWordsIndicated(...) method above.
    TextStyle overrideTextSpanStyle(TextStyle currentTextStyle) {
        //TODO(camillesimon): Define behavior here.

    }
}
