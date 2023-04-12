// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('buildButtonItems builds a "No Replacements Found" button when no suggestions', () {
    final _FakeEditableTextState editableTextState = _FakeEditableTextState();
    final List<ContextMenuButtonItem>? buttonItems =
        CupertinoSpellCheckSuggestionsToolbar.buildButtonItems(editableTextState);

    expect(buttonItems, isNotNull);
    expect(buttonItems!.length, 1);
    expect(buttonItems.first.label, 'No Replacements Found');
  });
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
