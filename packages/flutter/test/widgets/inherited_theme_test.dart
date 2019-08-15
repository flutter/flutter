// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class TestRoute extends PageRouteBuilder<void> {
  TestRoute(Widget child) : super(
    pageBuilder: (BuildContext _, Animation<double> __, Animation<double> ___) => child,
  );
}

class IconTextBox extends StatelessWidget {
  const IconTextBox(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Row(
        children: <Widget>[const Icon(IconData(0x41, fontFamily: 'Roboto')), Text(text)],
      ),
    );
  }
}

void main() {
  testWidgets('InheritedTheme.captureAll()', (WidgetTester tester) async {
    const double fontSize = 32;
    const double iconSize = 48;
    const Color textColor = Color(0xFF00FF00);
    const Color iconColor = Color(0xFF0000FF);
    bool useCaptureAll = false;
    BuildContext navigatorContext;

    Widget buildFrame() {
      return WidgetsApp(
        color: const Color(0xFFFFFFFF),
        onGenerateRoute: (RouteSettings settings) {
          return TestRoute(
            // The outer DefaultTextStyle and IconTheme widgets must have
            // no effect on the test because InheritedTheme.captureAll()
            // is required to only save the closest InheritedTheme ancestors.
            DefaultTextStyle(
              style: const TextStyle(fontSize: iconSize, color: iconColor),
              child: IconTheme(
                data: const IconThemeData(size: fontSize, color: textColor),
                // The inner DefaultTextStyle and IconTheme widgets define
                // InheritedThemes that captureAll() will wrap() around
                // TestRoute's IconTextBox child.
                child: DefaultTextStyle(
                  style: const TextStyle(fontSize: fontSize, color: textColor),
                  child: IconTheme(
                    data: const IconThemeData(size: iconSize, color: iconColor),
                    child: Builder(
                      builder: (BuildContext context) {
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            navigatorContext = context;
                            Navigator.of(context).push(
                              TestRoute(
                                useCaptureAll
                                  ? InheritedTheme.captureAll(context, const IconTextBox('Hello'))
                                  : const IconTextBox('Hello')
                              ),
                            );
                          },
                          child: const IconTextBox('Tap'),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    TextStyle getIconStyle() {
      return tester.widget<RichText>(
        find.descendant(
          of: find.byType(Icon),
          matching: find.byType(RichText),
        ),
      ).text.style;
    }

    TextStyle getTextStyle(String text) {
      return tester.widget<RichText>(
        find.descendant(
          of: find.text(text),
          matching: find.byType(RichText),
        ),
      ).text.style;
    }

    useCaptureAll = false;
    await tester.pumpWidget(buildFrame());
    expect(find.text('Tap'), findsOneWidget);
    expect(find.text('Hello'), findsNothing);
    expect(getTextStyle('Tap').color, textColor);
    expect(getTextStyle('Tap').fontSize, fontSize);
    expect(getIconStyle().color, iconColor);
    expect(getIconStyle().fontSize, iconSize);

    // Tap to show the TestRoute
    await tester.tap(find.text('Tap'));
    await tester.pumpAndSettle(); // route transition
    expect(find.text('Tap'), findsNothing);
    expect(find.text('Hello'), findsOneWidget);
    // The new route's text and icons will NOT inherit the DefaultTextStyle or
    // IconTheme values.
    expect(getTextStyle('Hello').color, isNot(textColor));
    expect(getTextStyle('Hello').fontSize, isNot(fontSize));
    expect(getIconStyle().color, isNot(iconColor));
    expect(getIconStyle().fontSize, isNot(iconSize));

    // Return to the home route
    useCaptureAll = true;
    Navigator.of(navigatorContext).pop();
    await tester.pumpAndSettle(); // route transition

    // Verify that all is the same as it was when the test started
    expect(find.text('Tap'), findsOneWidget);
    expect(find.text('Hello'), findsNothing);
    expect(getTextStyle('Tap').color, textColor);
    expect(getTextStyle('Tap').fontSize, fontSize);
    expect(getIconStyle().color, iconColor);
    expect(getIconStyle().fontSize, iconSize);

    // Tap to show the TestRoute. The test route's IconTextBox will have been
    // wrapped with InheritedTheme.captureAll().
    await tester.tap(find.text('Tap'));
    await tester.pumpAndSettle(); // route transition
    expect(find.text('Tap'), findsNothing);
    expect(find.text('Hello'), findsOneWidget);
    // The new route's text and icons will inherit the DefaultTextStyle or
    // IconTheme values because captureAll.
    expect(getTextStyle('Hello').color, textColor);
    expect(getTextStyle('Hello').fontSize, fontSize);
    expect(getIconStyle().color, iconColor);
    expect(getIconStyle().fontSize, iconSize);

  });
}
