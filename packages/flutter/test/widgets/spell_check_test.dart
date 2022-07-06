// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

late DefaultSpellCheckSuggestionsHandler defaultSpellCheckSuggestionsHandler;
late TextStyle composingStyle;
late TextStyle misspelledTextStyle;

void main() {
  setUp(() {
    // Using Android handling for testing.
    defaultSpellCheckSuggestionsHandler =
        DefaultSpellCheckSuggestionsHandler(TargetPlatform.android);

    composingStyle = const TextStyle(decoration: TextDecoration.underline);
    misspelledTextStyle = const TextStyle(
        decoration: TextDecoration.underline,
        decorationColor: ColorSwatch<int>(
          0xFFF44336,
          <int, Color>{
            50: Color(0xFFFFEBEE),
            100: Color(0xFFFFCDD2),
            200: Color(0xFFEF9A9A),
            300: Color(0xFFE57373),
            400: Color(0xFFEF5350),
            500: Color(0xFFF44336),
            600: Color(0xFFE53935),
            700: Color(0xFFD32F2F),
            800: Color(0xFFC62828),
            900: Color(0xFFB71C1C),
          },
        ),
        decorationStyle: TextDecorationStyle.wavy);
  });

  test(
      'buildTextSpanWithSpellCheckSuggestions ignores composing region when composing region out of range',
      () {
    String text = 'Hello, wrold! Hey';
    TextEditingValue value = TextEditingValue(text: text);
    bool composingRegionOutOfRange = true;
    SpellCheckResults spellCheckResults =
        SpellCheckResults(text, const <SuggestionSpan>[
      SuggestionSpan(
          TextRange(start: 7, end: 12), <String>['world', 'word', 'old'])
    ]);

    TextSpan expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Hello, '),
      TextSpan(style: misspelledTextStyle, text: 'wrold'),
      const TextSpan(text: '! Hey')
    ]);
    TextSpan textSpanTree = defaultSpellCheckSuggestionsHandler
        .buildTextSpanWithSpellCheckSuggestions(
            value, composingRegionOutOfRange, null, spellCheckResults);

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  test(
      'buildTextSpanWithSpellCheckSuggestions, isolated misspelled word with separate composing region example',
      () {
    String text = 'Hello, wrold! Hey';
    TextEditingValue value = TextEditingValue(
        text: text, composing: const TextRange(start: 14, end: 17));
    bool composingRegionOutOfRange = false;
    SpellCheckResults spellCheckResults =
        SpellCheckResults(text, const <SuggestionSpan>[
      SuggestionSpan(
          TextRange(start: 7, end: 12), <String>['world', 'word', 'old'])
    ]);

    TextSpan expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Hello, '),
      TextSpan(style: misspelledTextStyle, text: 'wrold'),
      const TextSpan(text: '! '),
      TextSpan(style: composingStyle, text: 'Hey')
    ]);
    TextSpan textSpanTree = defaultSpellCheckSuggestionsHandler
        .buildTextSpanWithSpellCheckSuggestions(
            value, composingRegionOutOfRange, null, spellCheckResults);

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  test(
      'buildTextSpanWithSpellCheckSuggestions, composing region and misspelled words overlap example',
      () {
    String text = 'Right worng worng right';
    TextEditingValue value = TextEditingValue(
        text: text, composing: const TextRange(start: 12, end: 17));
    bool composingRegionOutOfRange = false;
    SpellCheckResults spellCheckResults =
        SpellCheckResults(text, const <SuggestionSpan>[
      SuggestionSpan(
          TextRange(start: 6, end: 11), <String>['wrong', 'worn', 'wrung']),
      SuggestionSpan(
          TextRange(start: 12, end: 17), <String>['wrong', 'worn', 'wrung'])
    ]);

    TextSpan expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Right '),
      TextSpan(style: misspelledTextStyle, text: 'worng'),
      const TextSpan(text: ' '),
      TextSpan(style: composingStyle, text: 'worng'),
      const TextSpan(text: ' right'),
    ]);
    TextSpan textSpanTree = defaultSpellCheckSuggestionsHandler
        .buildTextSpanWithSpellCheckSuggestions(
            value, composingRegionOutOfRange, null, spellCheckResults);

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  test(
      'buildTextSpanWithSpellCheckSuggestions, consecutive misspelled words example',
      () {
    String text = 'Right worng worng right';
    TextEditingValue value = TextEditingValue(text: text);
    bool composingRegionOutOfRange = true;
    SpellCheckResults spellCheckResults =
        SpellCheckResults(text, const <SuggestionSpan>[
      SuggestionSpan(
          TextRange(start: 6, end: 11), <String>['wrong', 'worn', 'wrung']),
      SuggestionSpan(
          TextRange(start: 12, end: 17), <String>['wrong', 'worn', 'wrung'])
    ]);

    TextSpan expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Right '),
      TextSpan(style: misspelledTextStyle, text: 'worng'),
      const TextSpan(text: ' '),
      TextSpan(style: misspelledTextStyle, text: 'worng'),
      const TextSpan(text: ' right'),
    ]);
    TextSpan textSpanTree = defaultSpellCheckSuggestionsHandler
        .buildTextSpanWithSpellCheckSuggestions(
            value, composingRegionOutOfRange, null, spellCheckResults);

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  test(
      'buildTextSpanWithSpellCheckSuggestions corrects results when they lag, results text shorter than actual text example',
      () {
    String text = 'Hello, wrold! Hey';
    String resultsText = 'Hello, wrold!';
    TextEditingValue value = TextEditingValue(
        text: text, composing: const TextRange(start: 14, end: 17));
    bool composingRegionOutOfRange = false;
    SpellCheckResults spellCheckResults =
        SpellCheckResults(resultsText, const <SuggestionSpan>[
      SuggestionSpan(
          TextRange(start: 7, end: 12), <String>['world', 'word', 'old'])
    ]);

    TextSpan expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Hello, '),
      TextSpan(style: misspelledTextStyle, text: 'wrold'),
      const TextSpan(text: '! '),
      TextSpan(style: composingStyle, text: 'Hey')
    ]);
    TextSpan textSpanTree = defaultSpellCheckSuggestionsHandler
        .buildTextSpanWithSpellCheckSuggestions(
            value, composingRegionOutOfRange, null, spellCheckResults);

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  test(
      'buildTextSpanWithSpellCheckSuggestions corrects results when they lag, results text longer with more misspelled words than actual text example',
      () {
    String text = 'Hello, wrold! Hey';
    String resultsText = 'Hello, wrold Hey feirnd!';
    TextEditingValue value = TextEditingValue(
        text: text, composing: const TextRange(start: 14, end: 17));
    bool composingRegionOutOfRange = false;
    SpellCheckResults spellCheckResults =
        SpellCheckResults(resultsText, const <SuggestionSpan>[
      SuggestionSpan(
          TextRange(start: 7, end: 12), <String>['world', 'word', 'old']),
      SuggestionSpan(
          TextRange(start: 17, end: 23), <String>['friend', 'fiend', 'fern'])
    ]);

    TextSpan expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Hello, '),
      TextSpan(style: misspelledTextStyle, text: 'wrold'),
      const TextSpan(text: '! '),
      TextSpan(style: composingStyle, text: 'Hey')
    ]);
    TextSpan textSpanTree = defaultSpellCheckSuggestionsHandler
        .buildTextSpanWithSpellCheckSuggestions(
            value, composingRegionOutOfRange, null, spellCheckResults);

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  test(
      'buildTextSpanWithSpellCheckSuggestions corrects results when they lag, results text mismatched example',
      () {
    String text = 'Hello, wrold! Hey';
    String resultsText = 'Hello, wrild! Hey';
    TextEditingValue value = TextEditingValue(
        text: text, composing: const TextRange(start: 14, end: 17));
    bool composingRegionOutOfRange = false;
    SpellCheckResults spellCheckResults =
        SpellCheckResults(resultsText, const <SuggestionSpan>[
      SuggestionSpan(TextRange(start: 7, end: 12), <String>['wild', 'world']),
    ]);

    TextSpan expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Hello, wrold! '),
      TextSpan(style: composingStyle, text: 'Hey')
    ]);
    TextSpan textSpanTree = defaultSpellCheckSuggestionsHandler
        .buildTextSpanWithSpellCheckSuggestions(
            value, composingRegionOutOfRange, null, spellCheckResults);

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  test(
      'buildTextSpanWithSpellCheckSuggestions corrects results when they lag, results shifted forward example',
      () {
    String text = 'Hello, there wrold! Hey';
    String resultsText = 'Hello, wrold! Hey';
    TextEditingValue value = TextEditingValue(
        text: text, composing: const TextRange(start: 20, end: 23));
    bool composingRegionOutOfRange = false;
    SpellCheckResults spellCheckResults =
        SpellCheckResults(resultsText, const <SuggestionSpan>[
      SuggestionSpan(
          TextRange(start: 7, end: 12), <String>['world', 'word', 'old']),
    ]);

    TextSpan expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Hello, there '),
      TextSpan(style: misspelledTextStyle, text: 'wrold'),
      const TextSpan(text: '! '),
      TextSpan(style: composingStyle, text: 'Hey')
    ]);
    TextSpan textSpanTree = defaultSpellCheckSuggestionsHandler
        .buildTextSpanWithSpellCheckSuggestions(
            value, composingRegionOutOfRange, null, spellCheckResults);

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  test(
      'buildTextSpanWithSpellCheckSuggestions corrects results when they lag, results shifted backwards example',
      () {
    String text = 'Hello, wrold! Hey';
    String resultsText = 'Hello, great wrold! Hey';
    TextEditingValue value = TextEditingValue(
        text: text, composing: const TextRange(start: 14, end: 17));
    bool composingRegionOutOfRange = false;
    SpellCheckResults spellCheckResults =
        SpellCheckResults(resultsText, const <SuggestionSpan>[
      SuggestionSpan(
          TextRange(start: 13, end: 18), <String>['world', 'word', 'old']),
    ]);

    TextSpan expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Hello, '),
      TextSpan(style: misspelledTextStyle, text: 'wrold'),
      const TextSpan(text: '! '),
      TextSpan(style: composingStyle, text: 'Hey')
    ]);
    TextSpan textSpanTree = defaultSpellCheckSuggestionsHandler
        .buildTextSpanWithSpellCheckSuggestions(
            value, composingRegionOutOfRange, null, spellCheckResults);

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  test(
      'buildTextSpanWithSpellCheckSuggestions corrects results when they lag, results shifted backwards and forwards example',
      () {
    String text = 'Hello, wrold! And Hye!';
    String resultsText = 'Hello, great wrold! Hye!';
    TextEditingValue value = TextEditingValue(
        text: text, composing: const TextRange(start: 14, end: 17));
    bool composingRegionOutOfRange = false;
    SpellCheckResults spellCheckResults =
        SpellCheckResults(resultsText, const <SuggestionSpan>[
      SuggestionSpan(
          TextRange(start: 13, end: 18), <String>['world', 'word', 'old']),
      SuggestionSpan(TextRange(start: 20, end: 23), <String>['Hey', 'He'])
    ]);

    TextSpan expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Hello, '),
      TextSpan(style: misspelledTextStyle, text: 'wrold'),
      const TextSpan(text: '! '),
      TextSpan(style: composingStyle, text: 'And'),
      const TextSpan(text: ' '),
      TextSpan(style: misspelledTextStyle, text: 'Hye'),
      const TextSpan(text: '!')
    ]);
    TextSpan textSpanTree = defaultSpellCheckSuggestionsHandler
        .buildTextSpanWithSpellCheckSuggestions(
            value, composingRegionOutOfRange, null, spellCheckResults);

    expect(textSpanTree, equals(expectedTextSpanTree));
  });
}
