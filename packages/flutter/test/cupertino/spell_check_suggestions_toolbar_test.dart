// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('buildButtonItems builds a "No Replacements Found" button when no suggestions', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: _FakeEditableText(),
      ),
    );
    final _FakeEditableTextState editableTextState =
        tester.state(find.byType(_FakeEditableText));
    final List<ContextMenuButtonItem>? buttonItems =
        CupertinoSpellCheckSuggestionsToolbar.buildButtonItems(editableTextState);

    expect(buttonItems, isNotNull);
    expect(buttonItems!.length, 1);
    expect(buttonItems.first.label, 'No Replacements Found');
  });
}

class _FakeEditableText extends EditableText {
  _FakeEditableText() : super(
    controller: TextEditingController(),
    focusNode: FocusNode(),
    backgroundCursorColor: CupertinoColors.white,
    cursorColor: CupertinoColors.white,
    style: const TextStyle(),
  );

  @override
  _FakeEditableTextState createState() => _FakeEditableTextState();
}

class _FakeEditableTextState extends EditableTextState {
  @override
  TextEditingValue get currentTextEditingValue => TextEditingValue.empty;

  @override
  SuggestionSpan? findSuggestionSpanAtCursorIndex(int cursorIndex) {
    return const SuggestionSpan(
      TextRange(
        start: 0,
        end: 0,
      ),
      <String>[],
    );
  }
}
