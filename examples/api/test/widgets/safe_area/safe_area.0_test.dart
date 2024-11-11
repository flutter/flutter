// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/safe_area/safe_area.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

example.InsetsState get insetsState => example.InsetsState.instance;

void main() {
  testWidgets('SafeArea widget count', (WidgetTester tester) async {
    await tester.pumpWidget(const example.Insets());

    // 1 SafeArea and 2 ListTile widgets.
    expect(find.byType(SafeArea), findsNWidgets(3));

    insetsState.toggle(example.Toggle.appBar, true);
    await tester.pump();
    expect(find.byType(SafeArea), findsNWidgets(4));
  });

  testWidgets('ListTile removes side padding from its content', (WidgetTester tester) async {
    await tester.pumpWidget(const example.Insets());

    late BuildContext context;
    late EdgeInsets padding;

    final Finder findBody = find.byType(example.SafeAreaExample);
    final Finder findListTile = find.text(example.Toggle.appBar.label).first;

    context = tester.element(findBody);
    padding = MediaQuery.paddingOf(context);
    expect(padding.top, greaterThan(0));
    expect(padding.bottom, greaterThan(0));
    expect(padding.left, greaterThan(0));
    expect(padding.right, greaterThan(0));

    context = tester.element(findListTile);
    padding = MediaQuery.paddingOf(context);
    expect(padding.top, greaterThan(0));
    expect(padding.bottom, greaterThan(0));
    expect(padding.left, 0);
    expect(padding.right, 0);
  });

  testWidgets('AppBar removes top padding of Scaffold body', (WidgetTester tester) async {
    await tester.pumpWidget(const example.Insets());
    final BuildContext context = tester.element(find.text('no safe area'));

    // Double-check that side & bottom padding are unchanged.
    void verifySidesAndBottom() {
      final EdgeInsets padding = MediaQuery.paddingOf(context);
      expect(padding.left, example.Inset.sides.of(context));
      expect(padding.right, example.Inset.sides.of(context));
      expect(padding.bottom, example.Inset.bottom.of(context));
    }

    final double topInset = example.Inset.top.of(context);
    expect(topInset, greaterThan(0));
    expect(MediaQuery.paddingOf(context).top, topInset);
    verifySidesAndBottom();

    insetsState.toggle(example.Toggle.appBar, true);
    await tester.pump();

    expect(example.Inset.top.of(context), greaterThan(0));
    expect(MediaQuery.paddingOf(context).top, 0);
    verifySidesAndBottom();
  });

  testWidgets('SafeArea removes all padding', (WidgetTester tester) async {
    await tester.pumpWidget(const example.Insets());

    BuildContext context = tester.element(find.text('no safe area'));
    expect(MediaQuery.paddingOf(context), insetsState.insets);

    insetsState.toggle(example.Toggle.safeArea, true);
    await tester.pump();

    context = tester.element(find.text('safe area!'));
    expect(MediaQuery.paddingOf(context), EdgeInsets.zero);
  });
}
