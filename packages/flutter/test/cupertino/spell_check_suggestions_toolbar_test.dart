// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('buildButtonItems builds a "No Replacements Found" button when no suggestions', (WidgetTester tester) async {
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

    final FakeEditableTextState editableTextState = FakeEditableTextState();
    final List<ContextMenuButtonItem>? buttonItems =
        CupertinoSpellCheckSuggestionsToolbar.buildButtonItems(builderContext, editableTextState);

    expect(buttonItems, isNotNull);
    expect(buttonItems!.length, 1);
    expect(buttonItems.first.label, 'No Replacements Found');
    expect(buttonItems.first.onPressed, isNull);
  });
}

class FakeEditableTextState extends EditableTextState {
  final GlobalKey _editableKey = GlobalKey();
  bool showToolbarCalled = false;
  bool toggleToolbarCalled = false;
  bool showSpellCheckSuggestionsToolbarCalled = false;
  bool markCurrentSelectionAsMisspelled = false;

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

  @override
  RenderEditable get renderEditable => _editableKey.currentContext!.findRenderObject()! as RenderEditable;

  @override
  bool showToolbar() {
    showToolbarCalled = true;
    return true;
  }

  @override
  void toggleToolbar([bool hideHandles = true]) {
    toggleToolbarCalled = true;
    return;
  }

  @override
  bool showSpellCheckSuggestionsToolbar() {
    showSpellCheckSuggestionsToolbarCalled = true;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const SizedBox.shrink();
  }
}
