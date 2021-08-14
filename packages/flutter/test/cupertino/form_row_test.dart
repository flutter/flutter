// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Shows prefix', (WidgetTester tester) async {
    const Widget prefix = Text('Enter Value');

    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(
          child: CupertinoFormRow(
            prefix: prefix,
            child: CupertinoTextField(),
          ),
        ),
      ),
    );

    expect(prefix, tester.widget(find.byType(Text)));
  });

  testWidgets('Shows child', (WidgetTester tester) async {
    const Widget child = CupertinoTextField();

    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(
          child: CupertinoFormRow(
            child: child,
          ),
        ),
      ),
    );

    expect(child, tester.widget(find.byType(CupertinoTextField)));
  });

  testWidgets('RTL puts prefix after child', (WidgetTester tester) async {
    const Widget prefix = Text('Enter Value');
    const Widget child = CupertinoTextField();

    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: CupertinoFormRow(
              prefix: prefix,
              child: child,
            ),
          ),
        ),
      ),
    );

    expect(tester.getTopLeft(find.byType(Text)).dx > tester.getTopLeft(find.byType(CupertinoTextField)).dx, true);
  });

  testWidgets('LTR puts child after prefix', (WidgetTester tester) async {
    const Widget prefix = Text('Enter Value');
    const Widget child = CupertinoTextField();

    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: CupertinoFormRow(
              prefix: prefix,
              child: child,
            ),
          ),
        ),
      ),
    );

    expect(tester.getTopLeft(find.byType(Text)).dx > tester.getTopLeft(find.byType(CupertinoTextField)).dx, false);
  });

  testWidgets('Shows error widget', (WidgetTester tester) async {
    const Widget error = Text('Error');

    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(
          child: CupertinoFormRow(
            child: CupertinoTextField(),
            error: error,
          ),
        ),
      ),
    );

    expect(error, tester.widget(find.byType(Text)));
  });

  testWidgets('Shows helper widget', (WidgetTester tester) async {
    const Widget helper = Text('Helper');

    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(
          child: CupertinoFormRow(
            child: CupertinoTextField(),
            helper: helper,
          ),
        ),
      ),
    );

    expect(helper, tester.widget(find.byType(Text)));
  });

  testWidgets('Shows helper text above error text', (WidgetTester tester) async {
    const Widget helper = Text('Helper');
    const Widget error = CupertinoActivityIndicator();

    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(
          child: CupertinoFormRow(
            child: CupertinoTextField(),
            helper: helper,
            error: error,
          ),
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.byType(CupertinoActivityIndicator)).dy > tester.getTopLeft(find.byType(Text)).dy,
      true,
    );
  });

  testWidgets('Shows helper in label color and error text in red color', (WidgetTester tester) async {
    const Widget helper = Text('Helper');
    const Widget error = Text('Error');

    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(
          child: CupertinoFormRow(
            child: CupertinoTextField(),
            helper: helper,
            error: error,
          ),
        ),
      ),
    );

    final DefaultTextStyle helperTextStyle =
        tester.widget(find.byType(DefaultTextStyle).first);

    expect(helperTextStyle.style.color, CupertinoColors.label);

    final DefaultTextStyle errorTextStyle =
        tester.widget(find.byType(DefaultTextStyle).last);

    expect(errorTextStyle.style.color, CupertinoColors.destructiveRed);
  });
}
