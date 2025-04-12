// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MenuButtonThemeData lerp special cases', () {
    expect(MenuButtonThemeData.lerp(null, null, 0), null);
    const MenuButtonThemeData data = MenuButtonThemeData();
    expect(identical(MenuButtonThemeData.lerp(data, data, 0.5), data), true);
  });

  testWidgets('MenuButtonTheme.select only rebuilds when the selected property changes', (
    WidgetTester tester,
  ) async {
    int buildCount = 0;
    late ButtonStyle? style;

    // Define two distinct styles to test changes.
    final ButtonStyle style1 = ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.red));
    final ButtonStyle style2 = ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.blue));

    final Widget singletonThemeSubtree = Builder(
      builder: (BuildContext context) {
        buildCount++;
        // Select the style property.
        style = MenuButtonTheme.select(context, (MenuButtonThemeData theme) => theme.style);
        return const Placeholder();
      },
    );

    // Initial build with style1.
    await tester.pumpWidget(
      MaterialApp(
        home: MenuButtonTheme(
          data: MenuButtonThemeData(style: style1),
          child: singletonThemeSubtree,
        ),
      ),
    );

    expect(buildCount, 1);
    expect(style, style1);

    // Rebuild with the same style object but potentially different internal properties
    // (though in this case, ButtonStyle is immutable, so this is just for demonstration).
    // We expect no rebuild because the style object itself hasn't changed identity.
    await tester.pumpWidget(
      MaterialApp(
        home: MenuButtonTheme(
          data: MenuButtonThemeData(style: style1), // Same style object
          child: singletonThemeSubtree,
        ),
      ),
    );
    expect(buildCount, 1);
    expect(style, style1);

    // Rebuild with a different style object.
    await tester.pumpWidget(
      MaterialApp(
        home: MenuButtonTheme(
          data: MenuButtonThemeData(style: style2), // Different style object
          child: singletonThemeSubtree,
        ),
      ),
    );

    // Expect rebuild because the selected property (style object) changed.
    expect(buildCount, 2);
    expect(style, style2);
  });
}
