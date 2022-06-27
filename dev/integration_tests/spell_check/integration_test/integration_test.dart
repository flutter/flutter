import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

late DefaultSpellCheckService defaultSpellCheckService;
late Locale locale;
late String text;

/// Copy from flutter/test/widgets/editable_text_utils.dart.
RenderEditable findRenderEditable(WidgetTester tester, Type type) {
  final RenderObject root = tester.renderObject(find.byType(type));
  expect(root, isNotNull);

  late RenderEditable renderEditable;
  void recursiveFinder(RenderObject child) {
    if (child is RenderEditable) {
      renderEditable = child;
      return;
    }
    child.visitChildren(recursiveFinder);
  }
  root.visitChildren(recursiveFinder);
  expect(renderEditable, isNotNull);
  return renderEditable;
}

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    defaultSpellCheckService = DefaultSpellCheckService();
    locale = const Locale('en', 'us');
  });

  testWidgets(
      'fetchSpellCheckSuggestions returns null with no misspelled words',
      (WidgetTester tester) async {
    text = 'Hello, world!';

    List<SuggestionSpan>? spellCheckSuggestionSpans =
        await defaultSpellCheckService.fetchSpellCheckSuggestions(locale, text);

    expect(spellCheckSuggestionSpans!.length, equals(0));
    expect(defaultSpellCheckService.lastSavedText, equals(text));
    expect(defaultSpellCheckService.lastSavedSpans,
        equals(spellCheckSuggestionSpans));
  });

  testWidgets(
      'fetchSpellCheckSuggestions returns correct ranges with misspelled words',
      (WidgetTester tester) async {
    text = 'Hlelo, world! Yuou are magnificente';
    List<TextRange> misspelledWordRanges = const [
      TextRange(start: 0, end: 5),
      TextRange(start: 14, end: 18),
      TextRange(start: 23, end: 35)
    ];

    List<SuggestionSpan>? spellCheckSuggestionSpans =
        await defaultSpellCheckService.fetchSpellCheckSuggestions(locale, text);

    expect(spellCheckSuggestionSpans, isNotNull);
    expect(
        spellCheckSuggestionSpans!.length, equals(misspelledWordRanges.length));

    for (int i = 0; i < misspelledWordRanges.length; i += 1) {
      expectSync(
          spellCheckSuggestionSpans![i].range, equals(misspelledWordRanges[i]));
    }

    expect(defaultSpellCheckService.lastSavedText, equals(text));
    expect(defaultSpellCheckService.lastSavedSpans,
        equals(spellCheckSuggestionSpans));
  });

  testWidgets(
      'fetchSpellCheckSuggestions does not correct results when Gboard not ignoring composing region',
      (WidgetTester tester) async {
    text = 'Wwow, whaaett a beautiful day it is!';

    List<SuggestionSpan>? spellCheckSpansWithComposingRegion =
        await defaultSpellCheckService.fetchSpellCheckSuggestions(locale, text);

    expect(spellCheckSpansWithComposingRegion, isNotNull);
    expect(spellCheckSpansWithComposingRegion!.length, equals(2));

    List<SuggestionSpan>? spellCheckSuggestionSpans =
        await defaultSpellCheckService.fetchSpellCheckSuggestions(locale, text);

    expect(
        spellCheckSuggestionSpans, equals(spellCheckSpansWithComposingRegion));
  });

  testWidgets(
      'fetchSpellCheckSuggestions merges results when Gboard ignoring composing region',
      (WidgetTester tester) async {
    text = 'Wooahha it is an amazzinng dayyebf!';

    List<SuggestionSpan>? modifiedSpellCheckSuggestionSpans =
        await defaultSpellCheckService.fetchSpellCheckSuggestions(locale, text);
    List<SuggestionSpan> expectedSpellCheckSuggestionSpans =
        List<SuggestionSpan>.from(modifiedSpellCheckSuggestionSpans!);
    expect(modifiedSpellCheckSuggestionSpans, isNotNull);
    expect(modifiedSpellCheckSuggestionSpans!.length, equals(3));

    /// Remove one span to simulate Gboard attempting to un-ignore the composing region, after tapping away from "Yuou".
    modifiedSpellCheckSuggestionSpans!.removeAt(1);

    defaultSpellCheckService.lastSavedSpans = modifiedSpellCheckSuggestionSpans;
    defaultSpellCheckService.lastSavedText = text;

    List<SuggestionSpan>? spellCheckSuggestionSpans =
        await defaultSpellCheckService.fetchSpellCheckSuggestions(locale, text);

    expect(spellCheckSuggestionSpans, isNotNull);
    expect(spellCheckSuggestionSpans, equals(expectedSpellCheckSuggestionSpans));
  });

  testWidgets('EditableText spell checks when text is entered and spell check enabled', (WidgetTester tester) async {
    TextStyle style = const TextStyle();
    TextStyle misspelledStyle = style.merge(const TextStyle(
        decoration: TextDecoration.underline,
        decorationColor: Colors.red,
        decorationStyle: TextDecorationStyle.wavy));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              EditableText(
                controller: TextEditingController(),
                backgroundCursorColor: Colors.grey,
                focusNode: FocusNode(),
                spellCheckEnabled: true,
                style: style,
                cursorColor: Colors.red,
              )
            ],
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(EditableText), 'Hey wrororld! Hey!');
    await tester.pumpAndSettle();

    final RenderEditable renderEditable = findRenderEditable(tester, EditableText);
    final TextSpan textSpanTree = renderEditable.text! as TextSpan;

    TextSpan expectedTextSpanTree = TextSpan(
        style: style,
        children: <TextSpan>[
          TextSpan(style: style, text: 'Hey '),
          TextSpan(style: misspelledStyle, text: 'wrororld'),
          TextSpan(style: style, text: '! Hey!'),
        ]);

    expect(textSpanTree, equals(expectedTextSpanTree));
  });

  testWidgets(
      'fetchSpellCheckSuggestions returns null when there is a pending request',
      (WidgetTester tester) async {
    text =
        'neaf niofenaifn iofn iefnaoeifn ifneoa finoiafn inf ionfieaon ienf ifn ieonfaiofneionf oieafn oifnaioe nioenfio nefaion oifan' *
            10;

    defaultSpellCheckService.fetchSpellCheckSuggestions(locale, text);

    String modifiedText = text.substring(5);

    List<SuggestionSpan>? spellCheckSuggestionSpans =
        await defaultSpellCheckService.fetchSpellCheckSuggestions(
            locale, modifiedText);

    expect(spellCheckSuggestionSpans, isNull);

    /// The first request has still not completed, so no text should be saved as of now.
    expect(defaultSpellCheckService.lastSavedText, null);
  });
}
