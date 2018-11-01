// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

int timesBuilt;
CupertinoThemeData actualTheme;

final Widget child = Builder(
  builder: (BuildContext context) {
    timesBuilt++;
    actualTheme = CupertinoTheme.of(context);
    return const Placeholder();
  },
);

Future<CupertinoThemeData> testTheme(WidgetTester tester, CupertinoThemeData theme) async {
  await tester.pumpWidget(
    CupertinoTheme(
      data: theme,
      child: child,
    ),
  );
  return actualTheme;
}

void main() {
  setUp(() {
    timesBuilt = 0;
    actualTheme = null;
  });

  testWidgets('Default theme has defaults', (WidgetTester tester) async {
    final CupertinoThemeData theme = await testTheme(tester, const CupertinoThemeData());

    expect(theme.brightness, Brightness.light);
    expect(theme.primaryColor, CupertinoColors.activeBlue);
    expect(theme.textTheme.textStyle.fontSize, 17.0);
  });

  testWidgets('Theme attributes cascade', (WidgetTester tester) async {
    final CupertinoThemeData theme = await testTheme(tester, const CupertinoThemeData(
      primaryColor: CupertinoColors.destructiveRed,
    ));

    expect(theme.textTheme.actionTextStyle.color, CupertinoColors.destructiveRed);
  });

  testWidgets('Dependent attribute can be overridden from cascaded value', (WidgetTester tester) async {
    final CupertinoThemeData theme = await testTheme(tester, const CupertinoThemeData(
      brightness: Brightness.dark,
      textTheme: CupertinoTextTheme(
        textStyle: TextStyle(color: CupertinoColors.black),
      )
    ));

    // The brightness still cascaded down to the background color.
    expect(theme.scaffoldBackgroundColor, CupertinoColors.black);
    // But not to the font color which we overrode.
    expect(theme.textTheme.textStyle.color, CupertinoColors.black);
  });

  testWidgets(
    'Theme changes does not trigger any dependent builds if no attributes are read',
    (WidgetTester tester) async {
      await testTheme(tester, const CupertinoThemeData());

      expect(timesBuilt, 1);

      await testTheme(tester, const CupertinoThemeData(
        brightness: Brightness.dark,
      ));

      // The child shouldn't end up rebuilding again because the child doesn't
      // care about the brightness.
      expect(timesBuilt, 1);
    },
  );

  testWidgets(
    'Read attributes create dependencies when attributes change',
    (WidgetTester tester) async {
      CupertinoThemeData theme = await testTheme(tester, const CupertinoThemeData(
        // Default brightness is light,
        barBackgroundColor: Color(0x11223344),
        textTheme: CupertinoTextTheme(
          textStyle: TextStyle(fontFamily: 'Schrödinger'),
        ),
      ));

      expect(timesBuilt, 1);
      // By observing the result, we've changed reality and created a dependency.
      expect(theme.textTheme.textStyle.fontFamily, 'Schrödinger');

      // Changing an implicit value to an explicit value for brightness doesn't
      // actually change anything.
      theme = await testTheme(tester, const CupertinoThemeData(
        brightness: Brightness.light,
        barBackgroundColor: Color(0x11223344),
        textTheme: CupertinoTextTheme(
          textStyle: TextStyle(fontFamily: 'Schrödinger'),
        ),
      ));

      expect(timesBuilt, 1);
      // Re-reading the same value doesn't change anything.
      expect(theme.textTheme.textStyle.fontFamily, 'Schrödinger');

      theme = await testTheme(tester, const CupertinoThemeData(
        brightness: Brightness.light,
        barBackgroundColor: Color(0x11223344),
        textTheme: CupertinoTextTheme(
          textStyle: TextStyle(fontFamily: 'Cat'),
        ),
      ));

      expect(timesBuilt, 2);
      // The builder was called again and got a new inherited value.
      expect(theme.textTheme.textStyle.fontFamily, 'Cat');
    },
  );

  testWidgets(
    'Cascaded value changes also trigger rebuilds',
    (WidgetTester tester) async {
      CupertinoThemeData theme = await testTheme(tester, const CupertinoThemeData());

      expect(timesBuilt, 1);
      expect(theme.primaryColor, CupertinoColors.activeBlue);

      theme = await testTheme(tester, const CupertinoThemeData(
        brightness: Brightness.dark,
      ));

      // We haven't explicitly changed the primary color but implied it with a
      // brightness change.
      expect(timesBuilt, 2);
      expect(theme.primaryColor, CupertinoColors.activeOrange);
    },
  );
}