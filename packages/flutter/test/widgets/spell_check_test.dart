// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

late DefaultSpellCheckSuggestionsHandler defaultSpellCheckSuggestionsHandler;
late TextStyle composingStyle;
late TextStyle misspelledTextStyle;
late String text;
late String resultsText;
late TextEditingValue value;
late bool composingRegionOutOfRange;
late SpellCheckResults spellCheckResults;
late TextSpan textSpanTree;
late TextSpan expectedTextSpanTree;

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

  testWidgets(
      'buildTextSpanWithSpellCheckSuggestions ignores composing region when composing region out of range',
      (WidgetTester tester) async {
    text = 'Hello, wrold! Hey';
    value = TextEditingValue(text: text);
    composingRegionOutOfRange = true;
    spellCheckResults =
        SpellCheckResults(text, const <SuggestionSpan>[
      SuggestionSpan(
          TextRange(start: 7, end: 12), <String>['world', 'word', 'old'])
    ]);

    expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Hello, '),
      TextSpan(style: misspelledTextStyle, text: 'wrold'),
      const TextSpan(text: '! Hey')
    ]);
    textSpanTree = defaultSpellCheckSuggestionsHandler
        .buildTextSpanWithSpellCheckSuggestions(
            value, composingRegionOutOfRange, null, spellCheckResults);

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  testWidgets(
      'buildTextSpanWithSpellCheckSuggestions, isolated misspelled word with separate composing region example',
      (WidgetTester tester) async {
    text = 'Hello, wrold! Hey';
    value = TextEditingValue(
        text: text, composing: const TextRange(start: 14, end: 17));
    composingRegionOutOfRange = false;
    spellCheckResults =
        SpellCheckResults(text, const <SuggestionSpan>[
      SuggestionSpan(
          TextRange(start: 7, end: 12), <String>['world', 'word', 'old'])
    ]);

    expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Hello, '),
      TextSpan(style: misspelledTextStyle, text: 'wrold'),
      const TextSpan(text: '! '),
      TextSpan(style: composingStyle, text: 'Hey')
    ]);
    textSpanTree = defaultSpellCheckSuggestionsHandler
        .buildTextSpanWithSpellCheckSuggestions(
            value, composingRegionOutOfRange, null, spellCheckResults);

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  testWidgets(
      'buildTextSpanWithSpellCheckSuggestions, composing region and misspelled words overlap example',
      (WidgetTester tester) async {
    text = 'Right worng worng right';
    value = TextEditingValue(
        text: text, composing: const TextRange(start: 12, end: 17));
    composingRegionOutOfRange = false;
    spellCheckResults =
        SpellCheckResults(text, const <SuggestionSpan>[
      SuggestionSpan(
          TextRange(start: 6, end: 11), <String>['wrong', 'worn', 'wrung']),
      SuggestionSpan(
          TextRange(start: 12, end: 17), <String>['wrong', 'worn', 'wrung'])
    ]);

    expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Right '),
      TextSpan(style: misspelledTextStyle, text: 'worng'),
      const TextSpan(text: ' '),
      TextSpan(style: composingStyle, text: 'worng'),
      const TextSpan(text: ' right'),
    ]);
    textSpanTree = defaultSpellCheckSuggestionsHandler
        .buildTextSpanWithSpellCheckSuggestions(
            value, composingRegionOutOfRange, null, spellCheckResults);

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  testWidgets(
      'buildTextSpanWithSpellCheckSuggestions, consecutive misspelled words example',
      (WidgetTester tester) async {
    text = 'Right worng worng right';
    value = TextEditingValue(text: text);
    composingRegionOutOfRange = true;
    spellCheckResults =
        SpellCheckResults(text, const <SuggestionSpan>[
      SuggestionSpan(
          TextRange(start: 6, end: 11), <String>['wrong', 'worn', 'wrung']),
      SuggestionSpan(
          TextRange(start: 12, end: 17), <String>['wrong', 'worn', 'wrung'])
    ]);

    expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Right '),
      TextSpan(style: misspelledTextStyle, text: 'worng'),
      const TextSpan(text: ' '),
      TextSpan(style: misspelledTextStyle, text: 'worng'),
      const TextSpan(text: ' right'),
    ]);
    textSpanTree = defaultSpellCheckSuggestionsHandler
        .buildTextSpanWithSpellCheckSuggestions(
            value, composingRegionOutOfRange, null, spellCheckResults);

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  testWidgets(
      'buildTextSpanWithSpellCheckSuggestions corrects results when they lag, results text shorter than actual example',
      (WidgetTester tester) async {
    text = 'Hello, wrold! Hey';
    resultsText = 'Hello, wrold!';
    value = TextEditingValue(
        text: text, composing: const TextRange(start: 14, end: 17));
    composingRegionOutOfRange = false;
    spellCheckResults =
        SpellCheckResults(resultsText, const <SuggestionSpan>[
      SuggestionSpan(
          TextRange(start: 7, end: 12), <String>['world', 'word', 'old'])
    ]);

    expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Hello, '),
      TextSpan(style: misspelledTextStyle, text: 'wrold'),
      const TextSpan(text: '! '),
      TextSpan(style: composingStyle, text: 'Hey')
    ]);
    textSpanTree = defaultSpellCheckSuggestionsHandler
        .buildTextSpanWithSpellCheckSuggestions(
            value, composingRegionOutOfRange, null, spellCheckResults);

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  testWidgets(
      'buildTextSpanWithSpellCheckSuggestions corrects results when they lag, results text longer with more misspelled words than actual example',
      (WidgetTester tester) async {
    text = 'Hello, wrold! Hey';
    resultsText = 'Hello, wrold Hey feirnd!';
    value = TextEditingValue(
        text: text, composing: const TextRange(start: 14, end: 17));
    composingRegionOutOfRange = false;
    spellCheckResults =
        SpellCheckResults(resultsText, const <SuggestionSpan>[
      SuggestionSpan(
          TextRange(start: 7, end: 12), <String>['world', 'word', 'old']),
      SuggestionSpan(
          TextRange(start: 17, end: 23), <String>['friend', 'fiend', 'fern'])
    ]);

    expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Hello, '),
      TextSpan(style: misspelledTextStyle, text: 'wrold'),
      const TextSpan(text: '! '),
      TextSpan(style: composingStyle, text: 'Hey')
    ]);
    textSpanTree = defaultSpellCheckSuggestionsHandler
        .buildTextSpanWithSpellCheckSuggestions(
            value, composingRegionOutOfRange, null, spellCheckResults);

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  testWidgets(
      'buildTextSpanWithSpellCheckSuggestions corrects results when they lag, results text mismatched example',
      (WidgetTester tester) async {
    text = 'Hello, wrold! Hey';
    resultsText = 'Hello, wrild! Hey';
    value = TextEditingValue(
        text: text, composing: const TextRange(start: 14, end: 17));
    composingRegionOutOfRange = false;
    spellCheckResults =
        SpellCheckResults(resultsText, const <SuggestionSpan>[
      SuggestionSpan(TextRange(start: 7, end: 12), <String>['wild', 'world']),
    ]);

    expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Hello, wrold! '),
      TextSpan(style: composingStyle, text: 'Hey')
    ]);
    textSpanTree = defaultSpellCheckSuggestionsHandler
        .buildTextSpanWithSpellCheckSuggestions(
            value, composingRegionOutOfRange, null, spellCheckResults);

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  testWidgets(
      'buildTextSpanWithSpellCheckSuggestions corrects results when they lag, results shifted forward example',
      (WidgetTester tester) async {
    text = 'Hello, there wrold! Hey';
    resultsText = 'Hello, wrold! Hey';
    value = TextEditingValue(
        text: text, composing: const TextRange(start: 20, end: 23));
    composingRegionOutOfRange = false;
    spellCheckResults =
        SpellCheckResults(resultsText, const <SuggestionSpan>[
      SuggestionSpan(
          TextRange(start: 7, end: 12), <String>['world', 'word', 'old']),
    ]);

    expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Hello, there '),
      TextSpan(style: misspelledTextStyle, text: 'wrold'),
      const TextSpan(text: '! '),
      TextSpan(style: composingStyle, text: 'Hey')
    ]);
    textSpanTree = defaultSpellCheckSuggestionsHandler
        .buildTextSpanWithSpellCheckSuggestions(
            value, composingRegionOutOfRange, null, spellCheckResults);

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  testWidgets(
      'buildTextSpanWithSpellCheckSuggestions corrects results when they lag, results shifted backwards example',
      (WidgetTester tester) async {
    text = 'Hello, wrold! Hey';
    resultsText = 'Hello, great wrold! Hey';
    value = TextEditingValue(
        text: text, composing: const TextRange(start: 14, end: 17));
    composingRegionOutOfRange = false;
    spellCheckResults =
        SpellCheckResults(resultsText, const <SuggestionSpan>[
      SuggestionSpan(
          TextRange(start: 13, end: 18), <String>['world', 'word', 'old']),
    ]);

    expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Hello, '),
      TextSpan(style: misspelledTextStyle, text: 'wrold'),
      const TextSpan(text: '! '),
      TextSpan(style: composingStyle, text: 'Hey')
    ]);
    textSpanTree = defaultSpellCheckSuggestionsHandler
        .buildTextSpanWithSpellCheckSuggestions(
            value, composingRegionOutOfRange, null, spellCheckResults);

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  testWidgets(
      'buildTextSpanWithSpellCheckSuggestions corrects results when they lag, results shifted backwards and forwards example',
      (WidgetTester tester) async {
    text = 'Hello, wrold! And Hye!';
    resultsText = 'Hello, great wrold! Hye!';
    value = TextEditingValue(
        text: text, composing: const TextRange(start: 14, end: 17));
    composingRegionOutOfRange = false;
    spellCheckResults =
        SpellCheckResults(resultsText, const <SuggestionSpan>[
      SuggestionSpan(
          TextRange(start: 13, end: 18), <String>['world', 'word', 'old']),
      SuggestionSpan(TextRange(start: 20, end: 23), <String>['Hey', 'He'])
    ]);

    expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Hello, '),
      TextSpan(style: misspelledTextStyle, text: 'wrold'),
      const TextSpan(text: '! '),
      TextSpan(style: composingStyle, text: 'And'),
      const TextSpan(text: ' '),
      TextSpan(style: misspelledTextStyle, text: 'Hye'),
      const TextSpan(text: '!')
    ]);
    textSpanTree = defaultSpellCheckSuggestionsHandler
        .buildTextSpanWithSpellCheckSuggestions(
            value, composingRegionOutOfRange, null, spellCheckResults);

    expect(textSpanTree, equals(expectedTextSpanTree));
  });
}
