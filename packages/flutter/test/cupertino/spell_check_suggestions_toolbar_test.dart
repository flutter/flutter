// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Builds test button items for each of the suggestions provided.
  List<ContextMenuButtonItem> buildSuggestionButtons(List<String> suggestions) {
    final List<ContextMenuButtonItem> buttonItems = <ContextMenuButtonItem>[];

    for (final String suggestion in suggestions) {
      buttonItems.add(ContextMenuButtonItem(
        onPressed: () {},
        label: suggestion,
      ));
    }

    return buttonItems;
  }

  testWidgets('more than three suggestions throws an error', (WidgetTester tester) async {
    Future<void> pumpToolbar(List<String> suggestions) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoSpellCheckSuggestionsToolbar(
              anchors: const TextSelectionToolbarAnchors(
                primaryAnchor: Offset.zero,
              ),
              buttonItems: suggestions.map((String string) {
                return ContextMenuButtonItem(
                  onPressed: () {},
                  label: string,
                );
              }).toList(),
            ),
          ),
        ),
      );
    }
    await pumpToolbar(<String>['hello', 'yellow', 'yell']);
    expect(() async {
      await pumpToolbar(<String>['hello', 'yellow', 'yell', 'yeller']);
    }, throwsAssertionError);
  });

  testWidgets('buildSuggestionButtons only considers the first three suggestions', (WidgetTester tester) async {
    late final BuildContext builderContext;
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: Builder(
            builder: (BuildContext context) {
              builderContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    final _FakeEditableTextState editableTextState = _FakeEditableTextState(
      suggestions: <String>[
        'hello',
        'yellow',
        'yell',
        'yeller',
      ],
    );
    final List<ContextMenuButtonItem>? buttonItems =
        CupertinoSpellCheckSuggestionsToolbar.buildButtonItems(
          builderContext,
          editableTextState,
        );
    expect(buttonItems, isNotNull);
    final Iterable<String?> labels = buttonItems!.map((ContextMenuButtonItem buttonItem) {
      return buttonItem.label;
    });
    expect(labels, hasLength(3));
    expect(labels, contains('hello'));
    expect(labels, contains('yellow'));
    expect(labels, contains('yell'));
    expect(labels, isNot(contains('yeller')));
  });
}

class _FakeEditableTextState extends EditableTextState {
  _FakeEditableTextState({
    this.suggestions,
  });

  final List<String>? suggestions;

  @override
  TextEditingValue get currentTextEditingValue => TextEditingValue.empty;

  @override
  SuggestionSpan? findSuggestionSpanAtCursorIndex(int cursorIndex) {
    return SuggestionSpan(
      const TextRange(
        start: 0,
        end: 0,
      ),
      suggestions ?? <String>[],
    );
  }
}
