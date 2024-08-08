// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'TapOutsideConfiguration.of(context) returns default if no '
    'TapOutsideConfiguration widget in tree',
    (WidgetTester tester) async {
      const TextField editableText = TextField();
      TapOutsideBehavior? tapOutsideBehavior;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              tapOutsideBehavior = TapOutsideConfiguration.of(context);
              return editableText;
            },
          ),
        ),
      ));

      expect(tapOutsideBehavior, const TapOutsideBehavior());
    },
  );

  testWidgets('TapOutsideConfiguration changed', (WidgetTester tester) async {
    TapOutsideBehavior? behavior;

    final Widget widget = Builder(
      builder: (BuildContext context) {
        behavior = TapOutsideConfiguration.of(context);
        return const SizedBox();
      },
    );

    await tester.pumpWidget(
      TapOutsideConfiguration(
        behavior: const AlwaysUnfocusTapOutsideBehavior(),
        child: widget,
      ),
    );

    expect(behavior, const AlwaysUnfocusTapOutsideBehavior());

    // Same Widget, different TapOutsideConfiguration
    await tester.pumpWidget(
      TapOutsideConfiguration(
        behavior: const NeverUnfocusTapOutsideBehavior(),
        child: widget,
      ),
    );

    expect(behavior, const NeverUnfocusTapOutsideBehavior());
  });

  testWidgets(
    'TapOutside should be called when tap outside the TextField',
    (WidgetTester tester) async {
      bool tapOutsideCalled = false;
      final FocusNode focusNode = FocusNode();
      final TextField editableText = TextField(
        focusNode: focusNode,
        onTapOutside: (PointerDownEvent event) {
          tapOutsideCalled = true;
        },
      );
      const Key otherWidgetKey = Key('other');

      const Widget otherWidget =
          SizedBox(key: otherWidgetKey, width: 100, height: 100);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: <Widget>[
              editableText,
              otherWidget,
            ],
          ),
        ),
      ));

      focusNode.requestFocus();
      await tester.pump();

      expect(tapOutsideCalled, false);

      await tester.tap(find.byKey(otherWidgetKey), warnIfMissed: false);

      expect(tapOutsideCalled, true);
    },
  );

  testWidgets(
      'Should use behavior logic when tap outside the TextField without onTapOutside',
      (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();
    final TextField editableText = TextField(
      focusNode: focusNode,
    );
    const Key otherWidgetKey = Key('other');

    const Widget otherWidget =
        SizedBox(key: otherWidgetKey, width: 100, height: 100);

    final Scaffold body = Scaffold(
      body: Column(
        children: <Widget>[
          editableText,
          otherWidget,
        ],
      ),
    );

    await tester.pumpWidget(MaterialApp(
      home: TapOutsideConfiguration(
        behavior: const AlwaysUnfocusTapOutsideBehavior(),
        child: body,
      ),
    ));

    focusNode.requestFocus();
    await tester.pump();

    expect(focusNode.hasFocus, true);

    await tester.tap(find.byKey(otherWidgetKey), warnIfMissed: false);
    await tester.pump();

    expect(focusNode.hasFocus, false);

    await tester.pumpWidget(MaterialApp(
      home: TapOutsideConfiguration(
        behavior: const NeverUnfocusTapOutsideBehavior(),
        child: body,
      ),
    ));

    focusNode.requestFocus();
    await tester.pump();

    expect(focusNode.hasFocus, true);

    await tester.tap(find.byKey(otherWidgetKey), warnIfMissed: false);
    await tester.pump();

    expect(focusNode.hasFocus, true);
  });
}
