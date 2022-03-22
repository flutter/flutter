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

    bool isSpellCheckEnabled() {
        return this != SpellCheckConfiguration.disabled;
    }

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

    static SpellCheckSuggestionsHandler? getDefaultSpellCheckHandler(TargetPlatform platform) {
        switch(platform) {
            case TargetPlatform.android:
                return MaterialSpellCheckSuggestionsHandler();
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
    Widget buildSpellCheckSuggestionsToolbar(List<SpellCheckerSuggestionSpan>? spellCheckResults,
        TextSelectionDelegate delegate, 
        List<TextSelectionPoint> endpoints, Rect globalEditableRegion, 
        Offset selectionMidpoint, double textLineHeight);

    // Build TextSpans with misspelled words indicated.
    TextSpan buildTextSpanWithSpellCheckSuggestions(
        List<SpellCheckerSuggestionSpan>? spellCheckResults,
        TextEditingValue value, TextStyle? style, bool ignoreComposing);
}
