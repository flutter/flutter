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
    //TODO(camillesimon): Figure out if this should be const or not.
    //TODO(camillesimon): Make platform nullable and add logic to handle.
    const SpellCheckConfiguration({
        required this.platform,
        required this.spellCheckEnabled,
        this.spellCheckService,
    }):
        assert(platform != null),
        assert(spellCheckEnabled != null);

    /// SpellCheckConfiguration that indicates that spell check should not be run on text input.
    static const SpellCheckConfiguration disabled = SpellCheckConfiguration(
        platform: TargetPlatform.android, 
        spellCheckEnabled: false,
        spellCheckService: null,
      );

    /// Determines whether or not spell check is enabled.
    final bool spellCheckEnabled;

    /// Platform spell check needs to be configured for.
    final TargetPlatform platform;

    /// Service used for spell checking.
    final SpellCheckService? spellCheckService;
}

/// Interface that represents the core functionality needed to support spell check on text input.
abstract class SpellCheckService {
    // Initiates spell check. Expected to set spellCheckSuggestions in handler if synchronous.
    void fetchSpellCheckSuggestions(TextInputConnection? textInputConnection, Locale locale, String text);

    // Updates spell check results in handler. May be used in fetchSpellCheckSuggestions if synchronous.
    //TODO(camillesimon): Provide default implementation assuming developers most likely want access to our handlers.
    void updateSpellCheckSuggestions(List<SpellCheckerSuggestionSpan>? suggestions);

    // Relates service to a handler for the results it provides.
    //TODO(camillesimon): Determine whether or not to add getter/setter instead of update method:
    //TODO(camillesimon): Provide default implementation to give developers access?
    SpellCheckSuggestionsHandler? getSpellCheckSuggestionsHandler();
}

/// Interface that represents the core functionality needed to display results of spell check.
abstract class SpellCheckSuggestionsHandler {
    // Relates handler to resutls provided by spell check service.
    set spellCheckSuggestions(List<SpellCheckerSuggestionSpan>? spellCheckSuggestions);
    List<SpellCheckerSuggestionSpan>? get spellCheckSuggestions;

    // Builds toolbar/menu that will display spell check results.
    Widget buildSpellCheckSuggestionsToolbar(TextSelectionDelegate delegate, 
        List<TextSelectionPoint> endpoints, Rect globalEditableRegion, 
        Offset selectionMidpoint, double textLineHeight);

    // Build TextSpans with misspelled words indicated.
    TextSpan buildTextSpanWithSpellCheckSuggestions(
        TextEditingValue value, TextStyle? style, bool ignoreComposing);
}
