// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;


void main() {
  testWidgets('BottomNavigationBar is themable', (WidgetTester tester) async {
    const Color backgroundColor = Color(0xFF000001);
    const Color selectedItemColor = Color(0xFF000002);
    const Color unselectedItemColor = Color(0xFF000003);
    const IconThemeData selectedIconTheme = IconThemeData(size: 10);
    const IconThemeData unselectedIconTheme = IconThemeData(size: 11);
    const TextStyle selectedTextStyle = TextStyle(fontSize: 22);
    const TextStyle unselectedTextStyle = TextStyle(fontSize: 21);
    const double elevation = 9.0;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: backgroundColor,
            selectedItemColor: selectedItemColor,
            unselectedItemColor: unselectedItemColor,
            selectedIconTheme: selectedIconTheme,
            unselectedIconTheme: unselectedIconTheme,
            elevation: elevation,
            showUnselectedLabels: true,
            showSelectedLabels: true,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: selectedTextStyle,
            unselectedLabelStyle: unselectedTextStyle,
          ),
        ),
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.ac_unit),
                title: Text('AC'),
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.access_alarm),
                title: Text('Alarm'),
              ),
            ],
          ),
        ),
      ),
    );

    final TextStyle selectedFontStyle = tester.renderObject<RenderParagraph>(find.text('AC')).text.style;
    final TextStyle selectedIcon = _iconStyle(tester, Icons.ac_unit);
    final TextStyle unselectedIcon = _iconStyle(tester, Icons.access_alarm);
    expect(selectedFontStyle.fontSize, selectedFontStyle.fontSize);
    // Unselected label has a font size of 22 but is scaled down to be font size 21.
    expect(
      tester.firstWidget<Transform>(find.ancestor(of: find.text('Alarm'), matching: find.byType(Transform))).transform,
      equals(Matrix4.diagonal3(Vector3.all(unselectedTextStyle.fontSize / selectedTextStyle.fontSize))),
    );
    expect(selectedIcon.color, equals(selectedItemColor));
    expect(selectedIcon.fontSize, equals(selectedIconTheme.size));
    expect(unselectedIcon.color, equals(unselectedItemColor));
    expect(unselectedIcon.fontSize, equals(unselectedIconTheme.size));
    // There should not be any [Opacity] or [FadeTransition] widgets
    // since showUnselectedLabels and showSelectedLabels are true.
    final Finder findOpacity = find.descendant(
      of: find.byType(BottomNavigationBar),
      matching: find.byType(Opacity),
    );
    final Finder findFadeTransition = find.descendant(
      of: find.byType(BottomNavigationBar),
      matching: find.byType(FadeTransition),
    );
    expect(findOpacity, findsNothing);
    expect(findFadeTransition, findsNothing);
    expect(_getMaterial(tester).elevation, equals(elevation));
  });
}

TextStyle _iconStyle(WidgetTester tester, IconData icon) {
  final RichText iconRichText = tester.widget<RichText>(
    find.descendant(of: find.byIcon(icon), matching: find.byType(RichText)),
  );
  return iconRichText.text.style;
}

Material _getMaterial(WidgetTester tester) {
  return tester.firstWidget<Material>(
    find.descendant(of: find.byType(BottomNavigationBar), matching: find.byType(Material)),
  );
}
