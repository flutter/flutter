// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import '../rendering/mock_canvas.dart';

void main() {
  testWidgets('BottomNavigationBar callback test', (WidgetTester tester) async {
    int mutatedIndex;

    await tester.pumpWidget(
      MaterialApp(
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
            onTap: (int index) {
              mutatedIndex = index;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Alarm'));

    expect(mutatedIndex, 1);
  });

  testWidgets('BottomNavigationBar content test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
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

    final RenderBox box = tester.renderObject(find.byType(BottomNavigationBar));
    expect(box.size.height, kBottomNavigationBarHeight);
    expect(find.text('AC'), findsOneWidget);
    expect(find.text('Alarm'), findsOneWidget);
  });

  testWidgets('Fixed BottomNavigationBar defaults', (WidgetTester tester) async {
    const Color primaryColor = Color(0xFF000001);
    const Color captionColor = Color(0xFF000002);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          primaryColor: primaryColor,
          textTheme: const TextTheme(caption: TextStyle(color: captionColor)),
        ),
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
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

    const double selectedFontSize = 14.0;
    const double unselectedFontSize = 12.0;
    final TextStyle selectedFontStyle = tester.renderObject<RenderParagraph>(find.text('AC')).text.style;
    final TextStyle unselectedFontStyle = tester.renderObject<RenderParagraph>(find.text('Alarm')).text.style;
    final TextStyle selectedIcon = _iconStyle(tester, Icons.ac_unit);
    final TextStyle unselectedIcon = _iconStyle(tester, Icons.access_alarm);
    expect(selectedFontStyle.color, equals(primaryColor));
    expect(selectedFontStyle.fontSize, selectedFontSize);
    expect(selectedFontStyle.fontWeight, equals(FontWeight.w400));
    expect(selectedFontStyle.height, isNull);
    expect(unselectedFontStyle.color, equals(captionColor));
    expect(unselectedFontStyle.fontWeight, equals(FontWeight.w400));
    expect(unselectedFontStyle.height, isNull);
    // Unselected label has a font size of 14 but is scaled down to be font size 12.
    expect(
      tester.firstWidget<Transform>(find.ancestor(of: find.text('Alarm'), matching: find.byType(Transform))).transform,
      equals(Matrix4.diagonal3(Vector3.all(unselectedFontSize / selectedFontSize))),
    );
    expect(selectedIcon.color, equals(primaryColor));
    expect(selectedIcon.fontSize, equals(24.0));
    expect(unselectedIcon.color, equals(captionColor));
    expect(unselectedIcon.fontSize, equals(24.0));
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
    expect(_getMaterial(tester).elevation, equals(8.0));
  });

  testWidgets('Custom selected and unselected font styles', (WidgetTester tester) async {
    const TextStyle selectedTextStyle = TextStyle(fontWeight: FontWeight.w200, fontSize: 18.0);
    const TextStyle unselectedTextStyle = TextStyle(fontWeight: FontWeight.w600, fontSize: 12.0);

    await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: selectedTextStyle,
              unselectedLabelStyle: unselectedTextStyle,
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
    final TextStyle unselectedFontStyle = tester.renderObject<RenderParagraph>(find.text('Alarm')).text.style;
    expect(selectedFontStyle.fontSize, equals(selectedTextStyle.fontSize));
    expect(selectedFontStyle.fontWeight, equals(selectedTextStyle.fontWeight));
    expect(
      tester.firstWidget<Transform>(find.ancestor(of: find.text('Alarm'), matching: find.byType(Transform))).transform,
      equals(Matrix4.diagonal3(Vector3.all(unselectedTextStyle.fontSize / selectedTextStyle.fontSize))),
    );
    expect(unselectedFontStyle.fontWeight, equals(unselectedTextStyle.fontWeight));
  });

  testWidgets('font size on text styles overrides font size params', (WidgetTester tester) async {
    const TextStyle selectedTextStyle = TextStyle(fontSize: 18.0);
    const TextStyle unselectedTextStyle = TextStyle(fontSize: 12.0);
    const double selectedFontSize = 17.0;
    const double unselectedFontSize = 11.0;

    await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: selectedTextStyle,
              unselectedLabelStyle: unselectedTextStyle,
              selectedFontSize: selectedFontSize,
              unselectedFontSize: unselectedFontSize,
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
    expect(selectedFontStyle.fontSize, equals(selectedTextStyle.fontSize));
    expect(
      tester.firstWidget<Transform>(find.ancestor(of: find.text('Alarm'), matching: find.byType(Transform))).transform,
      equals(Matrix4.diagonal3(Vector3.all(unselectedTextStyle.fontSize / selectedTextStyle.fontSize))),
    );
  });

  testWidgets('Custom selected and unselected icon themes', (WidgetTester tester) async {
    const IconThemeData selectedIconTheme = IconThemeData(size: 36, color: Color(0x00000001));
    const IconThemeData unselectedIconTheme = IconThemeData(size: 18, color: Color(0x00000002));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            selectedIconTheme: selectedIconTheme,
            unselectedIconTheme: unselectedIconTheme,
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

    final TextStyle selectedIcon = _iconStyle(tester, Icons.ac_unit);
    final TextStyle unselectedIcon = _iconStyle(tester, Icons.access_alarm);
    expect(selectedIcon.color, equals(selectedIconTheme.color));
    expect(selectedIcon.fontSize, equals(selectedIconTheme.size));
    expect(unselectedIcon.color, equals(unselectedIconTheme.color));
    expect(unselectedIcon.fontSize, equals(unselectedIconTheme.size));
  });

  testWidgets('color on icon theme overrides selected and unselected item colors', (WidgetTester tester) async {
    const IconThemeData selectedIconTheme = IconThemeData(size: 36, color: Color(0x00000001));
    const IconThemeData unselectedIconTheme = IconThemeData(size: 18, color: Color(0x00000002));
    const Color selectedItemColor = Color(0x00000003);
    const Color unselectedItemColor = Color(0x00000004);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            selectedIconTheme: selectedIconTheme,
            unselectedIconTheme: unselectedIconTheme,
            selectedItemColor: selectedItemColor,
            unselectedItemColor: unselectedItemColor,
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
    final TextStyle unselectedFontStyle = tester.renderObject<RenderParagraph>(find.text('Alarm')).text.style;
    final TextStyle selectedIcon = _iconStyle(tester, Icons.ac_unit);
    final TextStyle unselectedIcon = _iconStyle(tester, Icons.access_alarm);
    expect(selectedIcon.color, equals(selectedIconTheme.color));
    expect(unselectedIcon.color, equals(unselectedIconTheme.color));
    expect(selectedFontStyle.color, equals(selectedItemColor));
    expect(unselectedFontStyle.color, equals(unselectedItemColor));
  });

  testWidgets('Padding is calculated properly on items - all labels', (WidgetTester tester) async {
    const double selectedFontSize = 16.0;
    const double unselectedFontSize = 12.0;
    const double selectedIconSize = 36.0;
    const double unselectedIconSize = 20.0;
    const IconThemeData selectedIconTheme = IconThemeData(size: selectedIconSize);
    const IconThemeData unselectedIconTheme = IconThemeData(size: unselectedIconSize);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedFontSize: selectedFontSize,
            unselectedFontSize: unselectedFontSize,
            selectedIconTheme: selectedIconTheme,
            unselectedIconTheme: unselectedIconTheme,
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

    final EdgeInsets selectedItemPadding = _itemPadding(tester, Icons.ac_unit);
    expect(selectedItemPadding.top, equals(selectedFontSize / 2.0));
    expect(selectedItemPadding.bottom, equals(selectedFontSize / 2.0));
    final EdgeInsets unselectedItemPadding = _itemPadding(tester, Icons.access_alarm);
    const double expectedUnselectedPadding = (selectedIconSize - unselectedIconSize) / 2.0 + selectedFontSize / 2.0;
    expect(unselectedItemPadding.top, equals(expectedUnselectedPadding));
    expect(unselectedItemPadding.bottom, equals(expectedUnselectedPadding));
  });

  testWidgets('Padding is calculated properly on items - selected labels only', (WidgetTester tester) async {
    const double selectedFontSize = 16.0;
    const double unselectedFontSize = 12.0;
    const double selectedIconSize = 36.0;
    const double unselectedIconSize = 20.0;
    const IconThemeData selectedIconTheme = IconThemeData(size: selectedIconSize);
    const IconThemeData unselectedIconTheme = IconThemeData(size: unselectedIconSize);

    await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: true,
              showUnselectedLabels: false,
              selectedFontSize: selectedFontSize,
              unselectedFontSize: unselectedFontSize,
              selectedIconTheme: selectedIconTheme,
              unselectedIconTheme: unselectedIconTheme,
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

    final EdgeInsets selectedItemPadding = _itemPadding(tester, Icons.ac_unit);
    expect(selectedItemPadding.top, equals(selectedFontSize / 2.0));
    expect(selectedItemPadding.bottom, equals(selectedFontSize / 2.0));
    final EdgeInsets unselectedItemPadding = _itemPadding(tester, Icons.access_alarm);
    expect(unselectedItemPadding.top, equals((selectedIconSize - unselectedIconSize) / 2.0 + selectedFontSize));
    expect(unselectedItemPadding.bottom, equals((selectedIconSize - unselectedIconSize) / 2.0));
  });

  testWidgets('Padding is calculated properly on items - no labels', (WidgetTester tester) async {
    const double selectedFontSize = 16.0;
    const double unselectedFontSize = 12.0;
    const double selectedIconSize = 36.0;
    const double unselectedIconSize = 20.0;
    const IconThemeData selectedIconTheme = IconThemeData(size: selectedIconSize);
    const IconThemeData unselectedIconTheme = IconThemeData(size: unselectedIconSize);

    await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              selectedFontSize: selectedFontSize,
              unselectedFontSize: unselectedFontSize,
              selectedIconTheme: selectedIconTheme,
              unselectedIconTheme: unselectedIconTheme,
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

    final EdgeInsets selectedItemPadding = _itemPadding(tester, Icons.ac_unit);
    expect(selectedItemPadding.top, equals(selectedFontSize));
    expect(selectedItemPadding.bottom, equals(0.0));
    final EdgeInsets unselectedItemPadding = _itemPadding(tester, Icons.access_alarm);
    expect(unselectedItemPadding.top, equals((selectedIconSize - unselectedIconSize) / 2.0 + selectedFontSize));
    expect(unselectedItemPadding.bottom, equals((selectedIconSize - unselectedIconSize) / 2.0));
  });

  testWidgets('Shifting BottomNavigationBar defaults', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.shifting,
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

    const double selectedFontSize = 14.0;
    expect(tester.renderObject<RenderParagraph>(find.text('AC')).text.style.fontSize, selectedFontSize);
    expect(tester.renderObject<RenderParagraph>(find.text('AC')).text.style.color, equals(Colors.white));
    expect(_getOpacity(tester, 'Alarm'), equals(0.0));
    expect(_getMaterial(tester).elevation, equals(8.0));
  });

  testWidgets('Fixed BottomNavigationBar custom font size, color', (WidgetTester tester) async {
    const Color primaryColor = Colors.black;
    const Color captionColor = Colors.purple;
    const Color selectedColor = Colors.blue;
    const Color unselectedColor = Colors.yellow;
    const double selectedFontSize = 18.0;
    const double unselectedFontSize = 14.0;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          primaryColor: primaryColor,
          textTheme: const TextTheme(caption: TextStyle(color: captionColor)),
        ),
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            selectedFontSize: selectedFontSize,
            unselectedFontSize: unselectedFontSize,
            selectedItemColor: selectedColor,
            unselectedItemColor: unselectedColor,
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

    expect(tester.renderObject<RenderParagraph>(find.text('AC')).text.style.fontSize, selectedFontSize);
    // Unselected label has a font size of 18 but is scaled down to be font size 14.
    expect(tester.renderObject<RenderParagraph>(find.text('Alarm')).text.style.fontSize, selectedFontSize);
    expect(
      tester.firstWidget<Transform>(find.ancestor(of: find.text('Alarm'), matching: find.byType(Transform))).transform,
      equals(Matrix4.diagonal3(Vector3.all(unselectedFontSize / selectedFontSize))),
    );
    expect(tester.renderObject<RenderParagraph>(find.text('AC')).text.style.color, equals(selectedColor));
    expect(tester.renderObject<RenderParagraph>(find.text('Alarm')).text.style.color, equals(unselectedColor));
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
  });


  testWidgets('Shifting BottomNavigationBar custom font size, color', (WidgetTester tester) async {
    const Color primaryColor = Colors.black;
    const Color captionColor = Colors.purple;
    const Color selectedColor = Colors.blue;
    const Color unselectedColor = Colors.yellow;
    const double selectedFontSize = 18.0;
    const double unselectedFontSize = 14.0;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          primaryColor: primaryColor,
          textTheme: const TextTheme(caption: TextStyle(color: captionColor)),
        ),
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.shifting,
            selectedFontSize: selectedFontSize,
            unselectedFontSize: unselectedFontSize,
            selectedItemColor: selectedColor,
            unselectedItemColor: unselectedColor,
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

    expect(tester.renderObject<RenderParagraph>(find.text('AC')).text.style.fontSize, selectedFontSize);
    expect(tester.renderObject<RenderParagraph>(find.text('AC')).text.style.color, equals(selectedColor));
    expect(_getOpacity(tester, 'Alarm'), equals(0.0));
  });

  testWidgets('Fixed BottomNavigationBar can hide unselected labels', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            showUnselectedLabels: false,
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

    expect(_getOpacity(tester, 'AC'), equals(1.0));
    expect(_getOpacity(tester, 'Alarm'), equals(0.0));
  });

  testWidgets('Fixed BottomNavigationBar can update background color', (WidgetTester tester) async {
    const Color color = Colors.yellow;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: color,
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

    expect(_getMaterial(tester).color, equals(color));
  });

  testWidgets('Shifting BottomNavigationBar background color is overridden by item color', (WidgetTester tester) async {
    const Color itemColor = Colors.yellow;
    const Color backgroundColor = Colors.blue;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.shifting,
            backgroundColor: backgroundColor,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.ac_unit),
                title: Text('AC'),
                backgroundColor: itemColor,
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

    expect(_getMaterial(tester).color, equals(itemColor));
  });

  testWidgets('Specifying both selectedItemColor and fixedColor asserts', (WidgetTester tester) async {
    expect(
      () {
        return BottomNavigationBar(
          selectedItemColor: Colors.black,
          fixedColor: Colors.black,
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
        );
      },
      throwsAssertionError,
    );
  });

  testWidgets('Fixed BottomNavigationBar uses fixedColor when selectedItemColor not provided', (WidgetTester tester) async {
    const Color fixedColor = Colors.black;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            fixedColor: fixedColor,
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

    expect(tester.renderObject<RenderParagraph>(find.text('AC')).text.style.color, equals(fixedColor));
  });

  testWidgets('setting selectedFontSize to zero hides all labels', (WidgetTester tester) async {
    const double customElevation = 3.0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            elevation: customElevation,
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

    expect(_getMaterial(tester).elevation, equals(customElevation));
  });

  testWidgets('BottomNavigationBar adds bottom padding to height', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(bottom: 40.0)),
          child: Scaffold(
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
      ),
    );

    const double labelBottomMargin = 7.0; // 7 == defaulted selectedFontSize / 2.0.
    const double additionalPadding = 40.0 - labelBottomMargin;
    const double expectedHeight = kBottomNavigationBarHeight + additionalPadding;
    expect(tester.getSize(find.byType(BottomNavigationBar)).height, expectedHeight);
  });

  testWidgets('BottomNavigationBar action size test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.shifting,
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

    Iterable<RenderBox> actions = tester.renderObjectList(find.byType(InkResponse));
    expect(actions.length, 2);
    expect(actions.elementAt(0).size.width, 480.0);
    expect(actions.elementAt(1).size.width, 320.0);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 1,
            type: BottomNavigationBarType.shifting,
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

    await tester.pump(const Duration(milliseconds: 200));

    actions = tester.renderObjectList(find.byType(InkResponse));
    expect(actions.length, 2);
    expect(actions.elementAt(0).size.width, 320.0);
    expect(actions.elementAt(1).size.width, 480.0);
  });

  testWidgets('BottomNavigationBar multiple taps test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.shifting,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.ac_unit),
                title: Text('AC'),
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.access_alarm),
                title: Text('Alarm'),
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.access_time),
                title: Text('Time'),
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.add),
                title: Text('Add'),
              ),
            ],
          ),
        ),
      ),
    );

    // We want to make sure that the last label does not get displaced,
    // irrespective of how many taps happen on the first N - 1 labels and how
    // they grow.

    Iterable<RenderBox> actions = tester.renderObjectList(find.byType(InkResponse));
    final Offset originalOrigin = actions.elementAt(3).localToGlobal(Offset.zero);

    await tester.tap(find.text('AC'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    actions = tester.renderObjectList(find.byType(InkResponse));
    expect(actions.elementAt(3).localToGlobal(Offset.zero), equals(originalOrigin));

    await tester.tap(find.text('Alarm'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    actions = tester.renderObjectList(find.byType(InkResponse));
    expect(actions.elementAt(3).localToGlobal(Offset.zero), equals(originalOrigin));

    await tester.tap(find.text('Time'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    actions = tester.renderObjectList(find.byType(InkResponse));
    expect(actions.elementAt(3).localToGlobal(Offset.zero), equals(originalOrigin));
  });

  testWidgets('BottomNavigationBar inherits shadowed app theme for shifting navbar', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.light),
        home: Theme(
          data: ThemeData(brightness: Brightness.dark),
          child: Scaffold(
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.shifting,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.ac_unit),
                  title: Text('AC'),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.access_alarm),
                  title: Text('Alarm'),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.access_time),
                  title: Text('Time'),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.add),
                  title: Text('Add'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Alarm'));
    await tester.pump(const Duration(seconds: 1));
    expect(Theme.of(tester.element(find.text('Alarm'))).brightness, equals(Brightness.dark));
  });

  testWidgets('BottomNavigationBar inherits shadowed app theme for fixed navbar', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.light),
        home: Theme(
          data: ThemeData(brightness: Brightness.dark),
          child: Scaffold(
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.ac_unit),
                  title: Text('AC'),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.access_alarm),
                  title: Text('Alarm'),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.access_time),
                  title: Text('Time'),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.add),
                  title: Text('Add'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Alarm'));
    await tester.pump(const Duration(seconds: 1));
    expect(Theme.of(tester.element(find.text('Alarm'))).brightness, equals(Brightness.dark));
  });

  testWidgets('BottomNavigationBar iconSize test', (WidgetTester tester) async {
    double builderIconSize;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            iconSize: 12.0,
            items: <BottomNavigationBarItem>[
              const BottomNavigationBarItem(
                title: Text('A'),
                icon: Icon(Icons.ac_unit),
              ),
              BottomNavigationBarItem(
                title: const Text('B'),
                icon: Builder(
                  builder: (BuildContext context) {
                    builderIconSize = IconTheme.of(context).size;
                    return SizedBox(
                      width: builderIconSize,
                      height: builderIconSize,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(Icon));
    expect(box.size.width, equals(12.0));
    expect(box.size.height, equals(12.0));
    expect(builderIconSize, 12.0);
  });

  testWidgets('BottomNavigationBar responds to textScaleFactor', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                title: Text('A'),
                icon: Icon(Icons.ac_unit),
              ),
              BottomNavigationBarItem(
                title: Text('B'),
                icon: Icon(Icons.battery_alert),
              ),
            ],
          ),
        ),
      ),
    );

    final RenderBox defaultBox = tester.renderObject(find.byType(BottomNavigationBar));
    expect(defaultBox.size.height, equals(kBottomNavigationBarHeight));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.shifting,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                title: Text('A'),
                icon: Icon(Icons.ac_unit),
              ),
              BottomNavigationBarItem(
                title: Text('B'),
                icon: Icon(Icons.battery_alert),
              ),
            ],
          ),
        ),
      ),
    );

    final RenderBox shiftingBox = tester.renderObject(find.byType(BottomNavigationBar));
    expect(shiftingBox.size.height, equals(kBottomNavigationBarHeight));

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaleFactor: 2.0),
          child: Scaffold(
            bottomNavigationBar: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  title: Text('A'),
                  icon: Icon(Icons.ac_unit),
                ),
                BottomNavigationBarItem(
                  title: Text('B'),
                  icon: Icon(Icons.battery_alert),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(BottomNavigationBar));
    expect(box.size.height, equals(66.0));
  });

  testWidgets('BottomNavigationBar does not grow with textScaleFactor when labels are provided', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                label: 'A',
                icon: Icon(Icons.ac_unit),
              ),
              BottomNavigationBarItem(
                label: 'B',
                icon: Icon(Icons.battery_alert),
              ),
            ],
          ),
        ),
      ),
    );

    final RenderBox defaultBox = tester.renderObject(find.byType(BottomNavigationBar));
    expect(defaultBox.size.height, equals(kBottomNavigationBarHeight));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.shifting,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                label: 'A',
                icon: Icon(Icons.ac_unit),
              ),
              BottomNavigationBarItem(
                label: 'B',
                icon: Icon(Icons.battery_alert),
              ),
            ],
          ),
        ),
      ),
    );

    final RenderBox shiftingBox = tester.renderObject(find.byType(BottomNavigationBar));
    expect(shiftingBox.size.height, equals(kBottomNavigationBarHeight));

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaleFactor: 2.0),
          child: Scaffold(
            bottomNavigationBar: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  label: 'A',
                  icon: Icon(Icons.ac_unit),
                ),
                BottomNavigationBarItem(
                  label: 'B',
                  icon: Icon(Icons.battery_alert),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(BottomNavigationBar));
    expect(box.size.height, equals(kBottomNavigationBarHeight));
  });

  testWidgets('BottomNavigationBar shows tool tips with text scaling on long press when labels are provided', (WidgetTester tester) async {
    const String label = 'Foo';

    Widget buildApp({ double textScaleFactor }) {
      return MediaQuery(
        data: MediaQueryData(textScaleFactor: textScaleFactor),
        child: Localizations(
          locale: const Locale('en', 'US'),
          delegates: const <LocalizationsDelegate<dynamic>>[
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Navigator(
              onGenerateRoute: (RouteSettings settings) {
                return MaterialPageRoute<void>(
                    builder: (BuildContext context) {
                      return Scaffold(
                        bottomNavigationBar: BottomNavigationBar(
                          items: const <BottomNavigationBarItem>[
                            BottomNavigationBarItem(
                              label: label,
                              icon: Icon(Icons.ac_unit),
                            ),
                            BottomNavigationBarItem(
                              label: 'B',
                              icon: Icon(Icons.battery_alert),
                            ),
                          ],
                        ),
                      );
                    }
                );
              },
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildApp(textScaleFactor: 1.0));
    expect(find.text(label), findsOneWidget);
    await tester.longPress(find.text(label));
    expect(find.text(label), findsNWidgets(2));
    expect(tester.getSize(find.text(label).last), equals(const Size(42.0, 14.0)));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.pumpWidget(buildApp(textScaleFactor: 4.0));
    expect(find.text(label), findsOneWidget);
    await tester.longPress(find.text(label));
    expect(tester.getSize(find.text(label).last), equals(const Size(168.0, 56.0)));
  });

  testWidgets('BottomNavigationBar limits width of tiles with long titles', (WidgetTester tester) async {
    final Text longTextA = Text(''.padLeft(100, 'A'));
    final Text longTextB = Text(''.padLeft(100, 'B'));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                title: longTextA,
                icon: const Icon(Icons.ac_unit),
              ),
              BottomNavigationBarItem(
                title: longTextB,
                icon: const Icon(Icons.battery_alert),
              ),
            ],
          ),
        ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(BottomNavigationBar));
    expect(box.size.height, equals(kBottomNavigationBarHeight));

    final RenderBox itemBoxA = tester.renderObject(find.text(longTextA.data));
    expect(itemBoxA.size, equals(const Size(400.0, 14.0)));
    final RenderBox itemBoxB = tester.renderObject(find.text(longTextB.data));
    expect(itemBoxB.size, equals(const Size(400.0, 14.0)));
  });

  testWidgets('BottomNavigationBar paints circles', (WidgetTester tester) async {
    await tester.pumpWidget(
      boilerplate(
        textDirection: TextDirection.ltr,
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              title: Text('A'),
              icon: Icon(Icons.ac_unit),
            ),
            BottomNavigationBarItem(
              title: Text('B'),
              icon: Icon(Icons.battery_alert),
            ),
          ],
        ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(BottomNavigationBar));
    expect(box, isNot(paints..circle()));

    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(box, paints..circle(x: 200.0));

    await tester.tap(find.text('B'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(box, paints..circle(x: 200.0)..translate(x: 400.0)..circle(x: 200.0));

    // Now we flip the directionality and verify that the circles switch positions.
    await tester.pumpWidget(
      boilerplate(
        textDirection: TextDirection.rtl,
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              title: Text('A'),
              icon: Icon(Icons.ac_unit),
            ),
            BottomNavigationBarItem(
              title: Text('B'),
              icon: Icon(Icons.battery_alert),
            ),
          ],
        ),
      ),
    );

    expect(box, paints..translate()..save()..translate(x: 400.0)..circle(x: 200.0)..restore()..circle(x: 200.0));

    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(
        box,
        paints
          ..translate(x: 0.0, y: 0.0)
          ..save()
          ..translate(x: 400.0)
          ..circle(x: 200.0)
          ..restore()
          ..circle(x: 200.0)
          ..translate(x: 400.0)
          ..circle(x: 200.0),
    );
  });

  testWidgets('BottomNavigationBar inactiveIcon shown', (WidgetTester tester) async {
    const Key filled = Key('filled');
    const Key stroked = Key('stroked');
    int selectedItem = 0;

    await tester.pumpWidget(
      boilerplate(
        textDirection: TextDirection.ltr,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedItem,
          items:  const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              activeIcon: Icon(Icons.favorite, key: filled),
              icon: Icon(Icons.favorite_border, key: stroked),
              title: Text('Favorite'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.access_alarm),
              title: Text('Alarm'),
            ),
          ],
        ),
      ),
    );

    expect(find.byKey(filled), findsOneWidget);
    expect(find.byKey(stroked), findsNothing);
    selectedItem = 1;

    await tester.pumpWidget(
      boilerplate(
        textDirection: TextDirection.ltr,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedItem,
          items:  const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              activeIcon: Icon(Icons.favorite, key: filled),
              icon: Icon(Icons.favorite_border, key: stroked),
              title: Text('Favorite'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.access_alarm),
              title: Text('Alarm'),
            ),
          ],
        ),
      ),
    );

    expect(find.byKey(filled), findsNothing);
    expect(find.byKey(stroked), findsOneWidget);
  });

  testWidgets('BottomNavigationBar.fixed semantics', (WidgetTester tester) async {
    await tester.pumpWidget(
      boilerplate(
        textDirection: TextDirection.ltr,
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
            BottomNavigationBarItem(
              icon: Icon(Icons.hot_tub),
              title: Text('Hot Tub'),
            ),
          ],
        ),
      ),
    );

    expect(
      tester.getSemantics(find.text('AC')),
      matchesSemantics(
        label: 'AC\nTab 1 of 3',
        textDirection: TextDirection.ltr,
        isFocusable: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('Alarm')),
      matchesSemantics(
        label: 'Alarm\nTab 2 of 3',
        textDirection: TextDirection.ltr,
        isFocusable: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('Hot Tub')),
      matchesSemantics(
        label: 'Hot Tub\nTab 3 of 3',
        textDirection: TextDirection.ltr,
        isFocusable: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('BottomNavigationBar.shifting semantics', (WidgetTester tester) async {
    await tester.pumpWidget(
      boilerplate(
        textDirection: TextDirection.ltr,
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.shifting,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.ac_unit),
              title: Text('AC'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.access_alarm),
              title: Text('Alarm'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.hot_tub),
              title: Text('Hot Tub'),
            ),
          ],
        ),
      ),
    );

    expect(
      tester.getSemantics(find.text('AC')),
      matchesSemantics(
        label: 'AC\nTab 1 of 3',
        textDirection: TextDirection.ltr,
        isFocusable: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('Alarm')),
      matchesSemantics(
        label: 'Alarm\nTab 2 of 3',
        textDirection: TextDirection.ltr,
        isFocusable: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('Hot Tub')),
      matchesSemantics(
        label: 'Hot Tub\nTab 3 of 3',
        textDirection: TextDirection.ltr,
        isFocusable: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('BottomNavigationBar handles items.length changes', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/10322

    Widget buildFrame(int itemCount) {
      return MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: 0,
            items: List<BottomNavigationBarItem>.generate(itemCount, (int itemIndex) {
              return BottomNavigationBarItem(
                icon: const Icon(Icons.android),
                title: Text('item $itemIndex'),
              );
            }),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(3));
    expect(find.text('item 0'), findsOneWidget);
    expect(find.text('item 1'), findsOneWidget);
    expect(find.text('item 2'), findsOneWidget);
    expect(find.text('item 3'), findsNothing);

    await tester.pumpWidget(buildFrame(4));
    expect(find.text('item 0'), findsOneWidget);
    expect(find.text('item 1'), findsOneWidget);
    expect(find.text('item 2'), findsOneWidget);
    expect(find.text('item 3'), findsOneWidget);

    await tester.pumpWidget(buildFrame(2));
    expect(find.text('item 0'), findsOneWidget);
    expect(find.text('item 1'), findsOneWidget);
    expect(find.text('item 2'), findsNothing);
    expect(find.text('item 3'), findsNothing);
  });

  testWidgets('BottomNavigationBar change backgroundColor test', (WidgetTester tester) async {
    // Regression test for: https://github.com/flutter/flutter/issues/19653

    Color _backgroundColor = Colors.red;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  child: const Text('green'),
                  onPressed: () {
                    setState(() {
                      _backgroundColor = Colors.green;
                    });
                  },
                ),
              ),
              bottomNavigationBar: BottomNavigationBar(
                type: BottomNavigationBarType.shifting,
                items: <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    title: const Text('Page 1'),
                    backgroundColor: _backgroundColor,
                    icon: const Icon(Icons.dashboard),
                  ),
                  BottomNavigationBarItem(
                    title: const Text('Page 2'),
                    backgroundColor: _backgroundColor,
                    icon: const Icon(Icons.menu),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    final Finder backgroundMaterial = find.descendant(
      of: find.byType(BottomNavigationBar),
      matching: find.byWidgetPredicate((Widget w) {
        if (w is Material)
          return w.type == MaterialType.canvas;
        return false;
      }),
    );

    expect(_backgroundColor, Colors.red);
    expect(tester.widget<Material>(backgroundMaterial).color, Colors.red);
    await tester.tap(find.text('green'));
    await tester.pumpAndSettle();
    expect(_backgroundColor, Colors.green);
    expect(tester.widget<Material>(backgroundMaterial).color, Colors.green);
  });

  group('BottomNavigationBar shifting backgroundColor with transition', () {
    // Regression test for: https://github.com/flutter/flutter/issues/22226
    Widget runTest() {
      int _currentIndex = 0;
      return MaterialApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Scaffold(
              bottomNavigationBar: RepaintBoundary(
                child: BottomNavigationBar(
                  type: BottomNavigationBarType.shifting,
                  currentIndex: _currentIndex,
                  onTap: (int index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      title: Text('Red'),
                      backgroundColor: Colors.red,
                      icon: Icon(Icons.dashboard),
                    ),
                    BottomNavigationBarItem(
                      title: Text('Green'),
                      backgroundColor: Colors.green,
                      icon: Icon(Icons.menu),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }
    for (int pump = 1; pump < 9; pump++) {
      testWidgets('pump $pump', (WidgetTester tester) async {
        await tester.pumpWidget(runTest());
        await tester.tap(find.text('Green'));

        for (int i = 0; i < pump; i++) {
          await tester.pump(const Duration(milliseconds: 30));
        }
        await expectLater(
          find.byType(BottomNavigationBar),
          matchesGoldenFile('bottom_navigation_bar.shifting_transition.${pump - 1}.png'),
        );
      });
    }
  });

  testWidgets('BottomNavigationBar item title should not be nullable', (WidgetTester tester) async {
    expect(() {
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.shifting,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.ac_unit),
                title: Text('AC'),
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.access_alarm),
              ),
            ],
          ),
        ),
      );
    }, throwsAssertionError);
  });

  testWidgets(
    'BottomNavigationBar [showSelectedLabels]=false and [showUnselectedLabels]=false '
    'for shifting navbar, expect that there is no rendered text',
    (WidgetTester tester) async {
      final Widget widget = MaterialApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Scaffold(
              bottomNavigationBar: BottomNavigationBar(
                showSelectedLabels: false,
                showUnselectedLabels: false,
                type: BottomNavigationBarType.shifting,
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    title: Text('Red'),
                    backgroundColor: Colors.red,
                    icon: Icon(Icons.dashboard),
                  ),
                  BottomNavigationBarItem(
                    title: Text('Green'),
                    backgroundColor: Colors.green,
                    icon: Icon(Icons.menu),
                  ),
                ],
              ),
            );
          },
        ),
      );
      await tester.pumpWidget(widget);
      expect(find.text('Red'), findsOneWidget);
      expect(find.text('Green'), findsOneWidget);
      expect(tester.widget<Opacity>(find.byType(Opacity).first).opacity, 0.0);
      expect(tester.widget<Opacity>(find.byType(Opacity).last).opacity, 0.0);
    });

  testWidgets(
    'BottomNavigationBar [showSelectedLabels]=false and [showUnselectedLabels]=false '
    'for fixed navbar, expect that there is no rendered text',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Scaffold(
                bottomNavigationBar: BottomNavigationBar(
                  showSelectedLabels: false,
                  showUnselectedLabels: false,
                  type: BottomNavigationBarType.fixed,
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      title: Text('Red'),
                      backgroundColor: Colors.red,
                      icon: Icon(Icons.dashboard),
                    ),
                    BottomNavigationBarItem(
                      title: Text('Green'),
                      backgroundColor: Colors.green,
                      icon: Icon(Icons.menu),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      expect(find.text('Red'), findsOneWidget);
      expect(find.text('Green'), findsOneWidget);
      expect(tester.widget<Opacity>(find.byType(Opacity).first).opacity, 0.0);
      expect(tester.widget<Opacity>(find.byType(Opacity).last).opacity, 0.0);
    });

  testWidgets('BottomNavigationBar.fixed [showSelectedLabels]=false and [showUnselectedLabels]=false semantics', (WidgetTester tester) async {
    await tester.pumpWidget(
      boilerplate(
        textDirection: TextDirection.ltr,
        bottomNavigationBar: BottomNavigationBar(
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.ac_unit),
              title: Text('Red'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.access_alarm),
              title: Text('Green'),
            ),
          ],
        ),
      ),
    );

    expect(
      tester.getSemantics(find.text('Red')),
      matchesSemantics(
        label: 'Red\nTab 1 of 2',
        textDirection: TextDirection.ltr,
        isFocusable: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('Green')),
      matchesSemantics(
        label: 'Green\nTab 2 of 2',
        textDirection: TextDirection.ltr,
        isFocusable: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('BottomNavigationBar.shifting [showSelectedLabels]=false and [showUnselectedLabels]=false semantics', (WidgetTester tester) async {
    await tester.pumpWidget(
      boilerplate(
        textDirection: TextDirection.ltr,
        bottomNavigationBar: BottomNavigationBar(
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.shifting,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.ac_unit),
              title: Text('Red'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.access_alarm),
              title: Text('Green'),
            ),
          ],
        ),
      ),
    );

    expect(
      tester.getSemantics(find.text('Red')),
      matchesSemantics(
        label: 'Red\nTab 1 of 2',
        textDirection: TextDirection.ltr,
        isFocusable: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('Green')),
      matchesSemantics(
        label: 'Green\nTab 2 of 2',
        textDirection: TextDirection.ltr,
        isFocusable: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('BottomNavigationBar changes mouse cursor when the tile is hovered over', (WidgetTester tester) async {
    // Test BottomNavigationBar() constructor
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: MouseRegion(
            cursor: SystemMouseCursors.forbidden,
            child: BottomNavigationBar(
              mouseCursor: SystemMouseCursors.text,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(icon: Icon(Icons.ac_unit), title: Text('AC')),
                BottomNavigationBarItem(icon: Icon(Icons.access_alarm), title: Text('Alarm')),
              ],
            ),
          ),
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 1);
    await gesture.addPointer(location: tester.getCenter(find.text('AC')));
    addTearDown(gesture.removePointer);

    await tester.pumpAndSettle();

    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.text);

    // Test default cursor
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: MouseRegion(
            cursor: SystemMouseCursors.forbidden,
            child: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(icon: Icon(Icons.ac_unit), title: Text('AC')),
                BottomNavigationBarItem(icon: Icon(Icons.access_alarm), title: Text('Alarm')),
              ],
            ),
          ),
        ),
      ),
    );

    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.click);
  });
}

Widget boilerplate({ Widget bottomNavigationBar, @required TextDirection textDirection }) {
  assert(textDirection != null);
  return MaterialApp(
    home: Localizations(
      locale: const Locale('en', 'US'),
      delegates: const <LocalizationsDelegate<dynamic>>[
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      child: Directionality(
        textDirection: textDirection,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: Material(
            child: Scaffold(
              bottomNavigationBar: bottomNavigationBar,
            ),
          ),
        ),
      ),
    ),
  );
}

double _getOpacity(WidgetTester tester, String textValue) {
  final FadeTransition opacityWidget = tester.widget<FadeTransition>(
      find.ancestor(
        of: find.text(textValue),
        matching: find.byType(FadeTransition),
      ).first,
  );
  return opacityWidget.opacity.value;
}

Material _getMaterial(WidgetTester tester) {
  return tester.firstWidget<Material>(
    find.descendant(of: find.byType(BottomNavigationBar), matching: find.byType(Material)),
  );
}

TextStyle _iconStyle(WidgetTester tester, IconData icon) {
  final RichText iconRichText = tester.widget<RichText>(
      find.descendant(of: find.byIcon(icon), matching: find.byType(RichText)),
  );
  return iconRichText.text.style;
}

EdgeInsets _itemPadding(WidgetTester tester, IconData icon) {
  return tester.widget<Padding>(
      find.descendant(
        of: find.ancestor(of: find.byIcon(icon), matching: find.byType(InkResponse)),
        matching: find.byType(Padding),
      ).first,
    ).padding.resolve(TextDirection.ltr);
}
