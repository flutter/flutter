// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart'
    show SpellCheckResults, SpellCheckService, TextEditingValue;

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
}
