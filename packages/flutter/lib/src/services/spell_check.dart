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
    //TODO(camillesimon): Figure out what can be inferred and what can't.
    const SpellCheckConfiguration({
        required TargetPlatform platform,
        required bool spellCheckEnabled,
        SpellCheckService? spellCheckService,
    }) : this._(
        platform: platform,
        spellCheckEnabled: true,
        spellCheckService: spellCheckService,
    );

    //TODO(camillesimon): Determine proper nullity of everything.
    //TODO(camillesimon): Determine if platform is necessary.
    const SpellCheckConfiguration({
        required this.platform,
        required this.spellCheckEnabled,
        this.spellCheckService,
    }) {
        assert(platform != null);
        assert(spellCheckEnabled != null);
        if (spellCheckEnabled) {
            spellCheckService = spellCheckService ?? getDefaultSpellCheckService(platform);
        }
    }

    /// SpellCheckConfiguration that indicates that spell check should not be run on text input.
    static const SpellCheckConfiguration disabled = SpellCheckConfiguration._(
        enabled: false,
        spellCheckService: null,
      );

    /// Determines whether or not spell check is enabled.
    bool spellCheckEnabled;

    /// Platform spell check needs to be configured for.
    TargetPlatform platform;

    /// Service used for spell checking.
    SpellCheckService? spellCheckSerice;

    /// Determines spell check service to be used by default.
    SpellCheckService? getDefaultSpellCheckService(TargetPlatform platform) {
        switch(platform) {
            case TargetPlatform.android:
                return MaterialSpellCheckService();
            default:
                // Null for all cases where a default implementation of spell check has not been provided.
                return null;
        }
    }
}

/// Interface that represents the core functionality needed to support spell check on text input.
abstract class SpellCheckService {
    // Initiates spell check. Expected to set spellCheckSuggestions in handler if synchronous.
    void fetchSpellCheckSuggestions(TextInputConnection? textInputConnection, Locale locale, String text);

    // Updates spell check results in handler. May be used in fetchSpellCheckSuggestions if synchronous.
    //TODO(camillesimon): Provide default implementation assuming developers most likely want access to our handlers.
    void updateSpellCheckSuggestions(List<SpellCheckSuggestionSpan>? suggestions);

    // Relates service to a handler for the results it provides.
    //TODO(camillesimon): Determine exactly which getters and setters are needed.
    //TODO(camillesimon): Provide default implementation to give developers access?
    SpellCheckSuggestionsHandler? get spellCheckSuggestionsHandler;
}

/// Interface that represents the core functionality needed to display results of spell check.
abstract class SpellCheckSuggestionsHandler {
    // Relates handler to resutls provided by spell check service.
    List<SpellCheckSuggestionSpan>? set spellCheckSuggestions;
    List<SpellCheckSuggestionSpan>? get spellCheckSuggestions;

    // Builds toolbar/menu that will display spell check results.
    Toolbar buildSpellCheckSuggestionsToolbar(TextSelectionDelegate delegate, 
        List<TextSelectionPoint> endpoints, Rect globalEditableRegion, 
        Offset selectionMidpoint, double textLineHeight);

    // Build TextSpans with misspelled words indicated.
    TextSpan buildTextSpanWithSpellCheckSuggestions(
        TextEditingValue value, TextStyle? style, bool ignoreComposing);
}
