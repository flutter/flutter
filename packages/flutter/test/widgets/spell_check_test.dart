// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

late String text;
late TextEditingValue value;
late bool composingWithinCurrentTextRange;
late SpellCheckResults spellCheckResults;
late TextStyle composingStyle;
late TextStyle misspelledStyle;
late TextSpan expectedTextSpanTree;
late TextSpan textSpanTree;
late String resultsText;
late DefaultSpellCheckSuggestionsHandler defaultSpellCheckSuggestionsHandler;

void main() {
  setUp(() {
    composingStyle = const TextStyle(decoration: TextDecoration.underline);
    misspelledStyle = misspelledStyle = const TextStyle(
        decoration: TextDecoration.underline,
        decorationColor: Colors.red,
        decorationStyle: TextDecorationStyle.wavy);
    defaultSpellCheckSuggestionsHandler =
        DefaultSpellCheckSuggestionsHandler(TargetPlatform.android);
  });

  testWidgets(
      'buildTextSpanWithSpellCheckSuggestions ignores composing region when composing within current text range',
      (WidgetTester tester) async {
    text = 'Hello, wrold! Hey';
    value = TextEditingValue(text: text);
    composingWithinCurrentTextRange = true;
    spellCheckResults = SpellCheckResults(text, const <SuggestionSpan>[
      SuggestionSpan(
          TextRange(start: 7, end: 12), <String>['world', 'word', 'old'])
    ]);

    expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Hello, '),
      TextSpan(style: misspelledStyle, text: 'wrold'),
      const TextSpan(text: '! Hey')
    ]);
    textSpanTree = defaultSpellCheckSuggestionsHandler
        .buildTextSpanWithSpellCheckSuggestions(
            value, composingWithinCurrentTextRange, null, spellCheckResults);

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  testWidgets(
      'buildTextSpanWithSpellCheckSuggestions, isolated misspelled word with separate composing region example',
      (WidgetTester tester) async {
    text = 'Hello, wrold! Hey';
    value = TextEditingValue(
        text: text, composing: const TextRange(start: 14, end: 17));
    composingWithinCurrentTextRange = false;
    spellCheckResults = SpellCheckResults(text, const <SuggestionSpan>[
      SuggestionSpan(
          TextRange(start: 7, end: 12), <String>['world', 'word', 'old'])
    ]);

    expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Hello, '),
      TextSpan(style: misspelledStyle, text: 'wrold'),
      const TextSpan(text: '! '),
      TextSpan(style: composingStyle, text: 'Hey')
    ]);
    textSpanTree = defaultSpellCheckSuggestionsHandler
        .buildTextSpanWithSpellCheckSuggestions(
            value, composingWithinCurrentTextRange, null, spellCheckResults);

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  testWidgets(
      'buildTextSpanWithSpellCheckSuggestions, composing region and misspelled words overlap example',
      (WidgetTester tester) async {
    text = 'Right worng worng right';
    value = TextEditingValue(
        text: text, composing: const TextRange(start: 12, end: 17));
    composingWithinCurrentTextRange = false;
    spellCheckResults = SpellCheckResults(text, const <SuggestionSpan>[
      SuggestionSpan(
          TextRange(start: 6, end: 11), <String>['wrong', 'worn', 'wrung']),
      SuggestionSpan(
          TextRange(start: 12, end: 17), <String>['wrong', 'worn', 'wrung'])
    ]);

    expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Right '),
      TextSpan(style: misspelledStyle, text: 'worng'),
      const TextSpan(text: ' '),
      TextSpan(style: composingStyle, text: 'worng'),
      const TextSpan(text: ' right'),
    ]);
    textSpanTree = defaultSpellCheckSuggestionsHandler
        .buildTextSpanWithSpellCheckSuggestions(
            value, composingWithinCurrentTextRange, null, spellCheckResults);

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  testWidgets(
      'buildTextSpanWithSpellCheckSuggestions, consecutive misspelled words example',
      (WidgetTester tester) async {
    text = 'Right worng worng right';
    value = TextEditingValue(text: text);
    composingWithinCurrentTextRange = true;
    spellCheckResults = SpellCheckResults(text, const <SuggestionSpan>[
      SuggestionSpan(
          TextRange(start: 6, end: 11), <String>['wrong', 'worn', 'wrung']),
      SuggestionSpan(
          TextRange(start: 12, end: 17), <String>['wrong', 'worn', 'wrung'])
    ]);

    expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Right '),
      TextSpan(style: misspelledStyle, text: 'worng'),
      const TextSpan(text: ' '),
      TextSpan(style: misspelledStyle, text: 'worng'),
      const TextSpan(text: ' right'),
    ]);
    textSpanTree = defaultSpellCheckSuggestionsHandler
        .buildTextSpanWithSpellCheckSuggestions(
            value, composingWithinCurrentTextRange, null, spellCheckResults);

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  testWidgets(
      'buildTextSpanWithSpellCheckSuggestions corrects results when they lag, results text shorter than actual example',
      (WidgetTester tester) async {
    text = 'Hello, wrold! Hey';
    resultsText = 'Hello, wrold!';
    value = TextEditingValue(
        text: text, composing: const TextRange(start: 14, end: 17));
    composingWithinCurrentTextRange = false;
    spellCheckResults = SpellCheckResults(resultsText, const <SuggestionSpan>[
      SuggestionSpan(
          TextRange(start: 7, end: 12), <String>['world', 'word', 'old'])
    ]);

    expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Hello, '),
      TextSpan(style: misspelledStyle, text: 'wrold'),
      const TextSpan(text: '! '),
      TextSpan(style: composingStyle, text: 'Hey')
    ]);
    textSpanTree = defaultSpellCheckSuggestionsHandler
        .buildTextSpanWithSpellCheckSuggestions(
            value, composingWithinCurrentTextRange, null, spellCheckResults);

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  testWidgets(
      'buildTextSpanWithSpellCheckSuggestions corrects results when they lag, results text longer with more misspelled words than actual example',
      (WidgetTester tester) async {
    text = 'Hello, wrold! Hey';
    resultsText = 'Hello, wrold Hey feirnd!';
    value = TextEditingValue(
        text: text, composing: const TextRange(start: 14, end: 17));
    composingWithinCurrentTextRange = false;
    spellCheckResults = SpellCheckResults(resultsText, const <SuggestionSpan>[
      SuggestionSpan(
          TextRange(start: 7, end: 12), <String>['world', 'word', 'old']),
      SuggestionSpan(
          TextRange(start: 17, end: 23), <String>['friend', 'fiend', 'fern'])
    ]);

    expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Hello, '),
      TextSpan(style: misspelledStyle, text: 'wrold'),
      const TextSpan(text: '! '),
      TextSpan(style: composingStyle, text: 'Hey')
    ]);
    textSpanTree = defaultSpellCheckSuggestionsHandler
        .buildTextSpanWithSpellCheckSuggestions(
            value, composingWithinCurrentTextRange, null, spellCheckResults);

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  testWidgets(
      'buildTextSpanWithSpellCheckSuggestions corrects results when they lag, results text mismatched example',
      (WidgetTester tester) async {
    text = 'Hello, wrold! Hey';
    resultsText = 'Hello, wrild! Hey';
    value = TextEditingValue(
        text: text, composing: const TextRange(start: 14, end: 17));
    composingWithinCurrentTextRange = false;
    spellCheckResults = SpellCheckResults(resultsText, const <SuggestionSpan>[
      SuggestionSpan(TextRange(start: 7, end: 12), <String>['wild', 'world']),
    ]);

    expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Hello, wrold! '),
      TextSpan(style: composingStyle, text: 'Hey')
    ]);
    textSpanTree = defaultSpellCheckSuggestionsHandler
        .buildTextSpanWithSpellCheckSuggestions(
            value, composingWithinCurrentTextRange, null, spellCheckResults);

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  testWidgets(
      'buildTextSpanWithSpellCheckSuggestions corrects results when they lag, results shifted forward example',
      (WidgetTester tester) async {
    text = 'Hello, there wrold! Hey';
    resultsText = 'Hello, wrold! Hey';
    value = TextEditingValue(
        text: text, composing: const TextRange(start: 20, end: 23));
    composingWithinCurrentTextRange = false;
    spellCheckResults = SpellCheckResults(resultsText, const <SuggestionSpan>[
      SuggestionSpan(
          TextRange(start: 7, end: 12), <String>['world', 'word', 'old']),
    ]);

    expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Hello, there '),
      TextSpan(style: misspelledStyle, text: 'wrold'),
      const TextSpan(text: '! '),
      TextSpan(style: composingStyle, text: 'Hey')
    ]);
    textSpanTree = defaultSpellCheckSuggestionsHandler
        .buildTextSpanWithSpellCheckSuggestions(
            value, composingWithinCurrentTextRange, null, spellCheckResults);

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  testWidgets(
      'buildTextSpanWithSpellCheckSuggestions corrects results when they lag, results shifted backwards example',
      (WidgetTester tester) async {
    text = 'Hello, wrold! Hey';
    resultsText = 'Hello, great wrold! Hey';
    value = TextEditingValue(
        text: text, composing: const TextRange(start: 14, end: 17));
    composingWithinCurrentTextRange = false;
    spellCheckResults = SpellCheckResults(resultsText, const <SuggestionSpan>[
      SuggestionSpan(
          TextRange(start: 13, end: 18), <String>['world', 'word', 'old']),
    ]);

    expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Hello, '),
      TextSpan(style: misspelledStyle, text: 'wrold'),
      const TextSpan(text: '! '),
      TextSpan(style: composingStyle, text: 'Hey')
    ]);
    textSpanTree = defaultSpellCheckSuggestionsHandler
        .buildTextSpanWithSpellCheckSuggestions(
            value, composingWithinCurrentTextRange, null, spellCheckResults);

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  testWidgets(
      'buildTextSpanWithSpellCheckSuggestions corrects results when they lag, results shifted backwards and forwards example',
      (WidgetTester tester) async {
    text = 'Hello, wrold! And Hye!';
    resultsText = 'Hello, great wrold! Hye!';
    value = TextEditingValue(
        text: text, composing: const TextRange(start: 14, end: 17));
    composingWithinCurrentTextRange = false;
    spellCheckResults = SpellCheckResults(resultsText, const <SuggestionSpan>[
      SuggestionSpan(
          TextRange(start: 13, end: 18), <String>['world', 'word', 'old']),
      SuggestionSpan(TextRange(start: 20, end: 23), <String>['Hey', 'He'])
    ]);

    expectedTextSpanTree = TextSpan(children: <TextSpan>[
      const TextSpan(text: 'Hello, '),
      TextSpan(style: misspelledStyle, text: 'wrold'),
      const TextSpan(text: '! '),
      TextSpan(style: composingStyle, text: 'And'),
      const TextSpan(text: ' '),
      TextSpan(style: misspelledStyle, text: 'Hye'),
      const TextSpan(text: '!')
    ]);
    textSpanTree = defaultSpellCheckSuggestionsHandler
        .buildTextSpanWithSpellCheckSuggestions(
            value, composingWithinCurrentTextRange, null, spellCheckResults);

    expect(textSpanTree, equals(expectedTextSpanTree));
  });
}
