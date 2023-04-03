// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

late TextStyle composingStyle;
late TextStyle misspelledTextStyle;

void main() {
  setUp(() {
    composingStyle = const TextStyle(decoration: TextDecoration.underline);

    // Using Android handling for testing.
    misspelledTextStyle = TextField.materialMisspelledTextStyle;
  });

  test(
      'buildTextSpanWithSpellCheckSuggestions ignores composing region when composing region out of range',
      () {
    const String text = 'Hello, wrold! Hey';
    const TextEditingValue value = TextEditingValue(text: text);
    const bool composingRegionOutOfRange = true;
    const SpellCheckResults spellCheckResults =
      SpellCheckResults(text, <SuggestionSpan>[
        SuggestionSpan(
            TextRange(start: 7, end: 12), <String>['world', 'word', 'old'])
    ]);

    final TextSpan expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Hello, '),
      TextSpan(style: misspelledTextStyle, text: 'wrold'),
      const TextSpan(text: '! Hey')
    ]);
    final TextSpan textSpanTree =
      buildTextSpanWithSpellCheckSuggestions(
        value,
        composingRegionOutOfRange,
        null,
        misspelledTextStyle,
        spellCheckResults,
    );

      expect(textSpanTree, equals(expectedTextSpanTree));
  });

  test(
      'buildTextSpanWithSpellCheckSuggestions, isolated misspelled word with separate composing region example',
      () {
    const String text = 'Hello, wrold! Hey';
    const TextEditingValue value = TextEditingValue(
        text: text, composing: TextRange(start: 14, end: 17));
    const bool composingRegionOutOfRange = false;
    const SpellCheckResults spellCheckResults =
      SpellCheckResults(text, <SuggestionSpan>[
        SuggestionSpan(
            TextRange(start: 7, end: 12), <String>['world', 'word', 'old'])
    ]);

    final TextSpan expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Hello, '),
      TextSpan(style: misspelledTextStyle, text: 'wrold'),
      const TextSpan(text: '! '),
      TextSpan(style: composingStyle, text: 'Hey')
    ]);
    final TextSpan textSpanTree =
      buildTextSpanWithSpellCheckSuggestions(
        value,
        composingRegionOutOfRange,
        null,
        misspelledTextStyle,
        spellCheckResults,
    );

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  test(
      'buildTextSpanWithSpellCheckSuggestions, composing region and misspelled words overlap example',
      () {
    const String text = 'Right worng worng right';
    const TextEditingValue value = TextEditingValue(
        text: text, composing: TextRange(start: 12, end: 17));
    const bool composingRegionOutOfRange = false;
    const SpellCheckResults spellCheckResults =
      SpellCheckResults(text, <SuggestionSpan>[
        SuggestionSpan(
            TextRange(start: 6, end: 11), <String>['wrong', 'worn', 'wrung']),
        SuggestionSpan(
            TextRange(start: 12, end: 17), <String>['wrong', 'worn', 'wrung'])
    ]);

    final TextSpan expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Right '),
      TextSpan(style: misspelledTextStyle, text: 'worng'),
      const TextSpan(text: ' '),
      TextSpan(style: composingStyle, text: 'worng'),
      const TextSpan(text: ' right'),
    ]);
    final TextSpan textSpanTree =
      buildTextSpanWithSpellCheckSuggestions(
        value,
        composingRegionOutOfRange,
        null,
        misspelledTextStyle,
        spellCheckResults,
    );

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  test(
      'buildTextSpanWithSpellCheckSuggestions, consecutive misspelled words example',
      () {
    const String text = 'Right worng worng right';
    const TextEditingValue value = TextEditingValue(text: text);
    const bool composingRegionOutOfRange = true;
    const SpellCheckResults spellCheckResults =
      SpellCheckResults(text, <SuggestionSpan>[
        SuggestionSpan(
            TextRange(start: 6, end: 11), <String>['wrong', 'worn', 'wrung']),
        SuggestionSpan(
            TextRange(start: 12, end: 17), <String>['wrong', 'worn', 'wrung'])
    ]);

    final TextSpan expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Right '),
      TextSpan(style: misspelledTextStyle, text: 'worng'),
      const TextSpan(text: ' '),
      TextSpan(style: misspelledTextStyle, text: 'worng'),
      const TextSpan(text: ' right'),
    ]);
    final TextSpan textSpanTree =
      buildTextSpanWithSpellCheckSuggestions(
        value,
        composingRegionOutOfRange,
        null,
        misspelledTextStyle,
        spellCheckResults,
    );

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  test(
      'buildTextSpanWithSpellCheckSuggestions corrects results when they lag, results text shorter than actual text example',
      () {
    const String text = 'Hello, wrold! Hey';
    const String resultsText = 'Hello, wrold!';
    const TextEditingValue value = TextEditingValue(
        text: text, composing: TextRange(start: 14, end: 17));
    const bool composingRegionOutOfRange = false;
    const SpellCheckResults spellCheckResults =
      SpellCheckResults(resultsText, <SuggestionSpan>[
        SuggestionSpan(
            TextRange(start: 7, end: 12), <String>['world', 'word', 'old'])
    ]);

    final TextSpan expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Hello, '),
      TextSpan(style: misspelledTextStyle, text: 'wrold'),
      const TextSpan(text: '! '),
      TextSpan(style: composingStyle, text: 'Hey')
    ]);
    final TextSpan textSpanTree =
      buildTextSpanWithSpellCheckSuggestions(
        value,
        composingRegionOutOfRange,
        null,
        misspelledTextStyle,
        spellCheckResults,
    );

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  test(
      'buildTextSpanWithSpellCheckSuggestions corrects results when they lag, results text longer with more misspelled words than actual text example',
      () {
    const String text = 'Hello, wrold! Hey';
    const String resultsText = 'Hello, wrold Hey feirnd!';
    const TextEditingValue value = TextEditingValue(
        text: text, composing: TextRange(start: 14, end: 17));
    const bool composingRegionOutOfRange = false;
    const SpellCheckResults spellCheckResults =
      SpellCheckResults(resultsText, <SuggestionSpan>[
        SuggestionSpan(
            TextRange(start: 7, end: 12), <String>['world', 'word', 'old']),
        SuggestionSpan(
            TextRange(start: 17, end: 23), <String>['friend', 'fiend', 'fern'])
    ]);

    final TextSpan expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Hello, '),
      TextSpan(style: misspelledTextStyle, text: 'wrold'),
      const TextSpan(text: '! '),
      TextSpan(style: composingStyle, text: 'Hey')
    ]);
    final TextSpan textSpanTree =
      buildTextSpanWithSpellCheckSuggestions(
        value,
        composingRegionOutOfRange,
        null,
        misspelledTextStyle,
        spellCheckResults,
    );

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  test(
      'buildTextSpanWithSpellCheckSuggestions corrects results when they lag, results text mismatched example',
      () {
    const String text = 'Hello, wrold! Hey';
    const String resultsText = 'Hello, wrild! Hey';
    const TextEditingValue value = TextEditingValue(
        text: text, composing: TextRange(start: 14, end: 17));
    const bool composingRegionOutOfRange = false;
    const SpellCheckResults spellCheckResults =
      SpellCheckResults(resultsText, <SuggestionSpan>[
        SuggestionSpan(TextRange(start: 7, end: 12), <String>['wild', 'world']),
    ]);

    final TextSpan expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Hello, wrold! '),
      TextSpan(style: composingStyle, text: 'Hey')
    ]);
    final TextSpan textSpanTree =
      buildTextSpanWithSpellCheckSuggestions(
        value,
        composingRegionOutOfRange,
        null,
        misspelledTextStyle,
        spellCheckResults,
    );

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  test(
      'buildTextSpanWithSpellCheckSuggestions corrects results when they lag, results shifted forward example',
      () {
    const String text = 'Hello, there wrold! Hey';
    const String resultsText = 'Hello, wrold! Hey';
    const TextEditingValue value = TextEditingValue(
        text: text, composing: TextRange(start: 20, end: 23));
    const bool composingRegionOutOfRange = false;
    const SpellCheckResults spellCheckResults =
      SpellCheckResults(resultsText, <SuggestionSpan>[
        SuggestionSpan(
            TextRange(start: 7, end: 12), <String>['world', 'word', 'old']),
    ]);

    final TextSpan expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Hello, there '),
      TextSpan(style: misspelledTextStyle, text: 'wrold'),
      const TextSpan(text: '! '),
      TextSpan(style: composingStyle, text: 'Hey')
    ]);
    final TextSpan textSpanTree =
      buildTextSpanWithSpellCheckSuggestions(
        value,
        composingRegionOutOfRange,
        null,
        misspelledTextStyle,
        spellCheckResults,
    );

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  test(
      'buildTextSpanWithSpellCheckSuggestions corrects results when they lag, results shifted backwards example',
      () {
    const String text = 'Hello, wrold! Hey';
    const String resultsText = 'Hello, great wrold! Hey';
    const TextEditingValue value = TextEditingValue(
        text: text, composing: TextRange(start: 14, end: 17));
    const bool composingRegionOutOfRange = false;
    const SpellCheckResults spellCheckResults =
      SpellCheckResults(resultsText, <SuggestionSpan>[
        SuggestionSpan(
            TextRange(start: 13, end: 18), <String>['world', 'word', 'old']),
    ]);

    final TextSpan expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Hello, '),
      TextSpan(style: misspelledTextStyle, text: 'wrold'),
      const TextSpan(text: '! '),
      TextSpan(style: composingStyle, text: 'Hey')
    ]);
    final TextSpan textSpanTree =
      buildTextSpanWithSpellCheckSuggestions(
        value,
        composingRegionOutOfRange,
        null,
        misspelledTextStyle,
        spellCheckResults,
    );

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  test(
      'buildTextSpanWithSpellCheckSuggestions corrects results when they lag, results shifted backwards and forwards example',
      () {
    const String text = 'Hello, wrold! And Hye!';
    const String resultsText = 'Hello, great wrold! Hye!';
    const TextEditingValue value = TextEditingValue(
        text: text, composing: TextRange(start: 14, end: 17));
    const bool composingRegionOutOfRange = false;
    const SpellCheckResults spellCheckResults =
      SpellCheckResults(resultsText, <SuggestionSpan>[
        SuggestionSpan(
            TextRange(start: 13, end: 18), <String>['world', 'word', 'old']),
        SuggestionSpan(TextRange(start: 20, end: 23), <String>['Hey', 'He'])
    ]);

    final TextSpan expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Hello, '),
      TextSpan(style: misspelledTextStyle, text: 'wrold'),
      const TextSpan(text: '! '),
      TextSpan(style: composingStyle, text: 'And'),
      const TextSpan(text: ' '),
      TextSpan(style: misspelledTextStyle, text: 'Hye'),
      const TextSpan(text: '!')
    ]);
    final TextSpan textSpanTree =
      buildTextSpanWithSpellCheckSuggestions(
        value,
        composingRegionOutOfRange,
        null,
        misspelledTextStyle,
        spellCheckResults,
    );

    expect(textSpanTree, equals(expectedTextSpanTree));
  });
}
