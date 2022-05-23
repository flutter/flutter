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
        other.start == start &&
        other.end == end &&
        listEquals<String>(
            other.replacementSuggestions, replacementSuggestions);
  }

  @override
  int get hashCode => Object.hash(start, end, hashList(replacementSuggestions));
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
}
