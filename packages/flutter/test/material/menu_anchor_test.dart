// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

void main() {
  late MenuController controller;
  String? focusedMenu;
  final List<TestMenu> selected = <TestMenu>[];
  final List<TestMenu> opened = <TestMenu>[];
  final List<TestMenu> closed = <TestMenu>[];
  final GlobalKey menuItemKey = GlobalKey();

  void onPressed(TestMenu item) {
    selected.add(item);
  }

  void onOpen(TestMenu item) {
    opened.add(item);
  }

  void onClose(TestMenu item) {
    closed.add(item);
  }

  void handleFocusChange() {
    focusedMenu = (primaryFocus?.debugLabel ?? primaryFocus).toString();
  }

  setUp(() {
    focusedMenu = null;
    selected.clear();
    opened.clear();
    closed.clear();
    controller = MenuController();
    focusedMenu = null;
  });

  Future<void> changeSurfaceSize(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
  }

  void listenForFocusChanges() {
    FocusManager.instance.addListener(handleFocusChange);
    addTearDown(() => FocusManager.instance.removeListener(handleFocusChange));
  }

  Finder findMenuPanels() {
    return find.byWidgetPredicate((Widget widget) => widget.runtimeType.toString() == '_MenuPanel');
  }

  Finder findMenuBarItemLabels() {
    return find.byWidgetPredicate((Widget widget) => widget.runtimeType.toString() == '_MenuItemLabel');
  }

  // Finds the mnemonic associated with the menu item that has the given label.
  Finder findMnemonic(String label) {
    return find
        .descendant(
          of: find.ancestor(of: find.text(label), matching: findMenuBarItemLabels()),
          matching: find.byType(Text),
        )
        .last;
  }

  Widget buildTestApp({
    AlignmentGeometry? alignment,
    Offset alignmentOffset = Offset.zero,
    TextDirection textDirection = TextDirection.ltr,
  }) {
    final FocusNode focusNode = FocusNode();
    return MaterialApp(
      home: Material(
        child: Directionality(
          textDirection: textDirection,
          child: Center(
            child: MenuAnchor(
              childFocusNode: focusNode,
              controller: controller,
              alignmentOffset: alignmentOffset,
              style: MenuStyle(alignment: alignment),
              menuChildren: <Widget>[
                MenuItemButton(
                  key: menuItemKey,
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyB,
                    control: true,
                  ),
                  onPressed: () {},
                  child: Text(TestMenu.subMenu00.label),
                ),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.send),
                  trailingIcon: const Icon(Icons.mail),
                  onPressed: () {},
                  child: Text(TestMenu.subMenu01.label),
                ),
              ],
              builder: (BuildContext context, MenuController controller, Widget? child) {
                return ElevatedButton(
                  focusNode: focusNode,
                  onPressed: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                  child: child,
                );
              },
              child: const Text('Press Me'),
            ),
          ),
        ),
      ),
    );
  }

  Future<TestGesture> hoverOver(WidgetTester tester, Finder finder) async {
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.moveTo(tester.getCenter(finder));
    await tester.pumpAndSettle();
    return gesture;
  }

  Material getMenuBarMaterial(WidgetTester tester) {
    return tester.widget<Material>(
      find.descendant(of: findMenuPanels(), matching: find.byType(Material)).first,
    );
  }

  testWidgets('Menu responds to density changes', (WidgetTester tester) async {
    Widget buildMenu({VisualDensity? visualDensity = VisualDensity.standard}) => MaterialApp(
      theme: ThemeData(visualDensity: visualDensity),
      home: Material(
        child: Column(
          children: <Widget>[
            MenuBar(
              children: createTestMenus(onPressed: onPressed),
            ),
            const Expanded(child: Placeholder()),
          ],
        ),
      ),
    );

    await tester.pumpWidget(buildMenu());
    await tester.pump();

    expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(145.0, 0.0, 655.0, 48.0)));

    // Open and make sure things are the right size.
    await tester.tap(find.text(TestMenu.mainMenu1.label));
    await tester.pump();

    expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(145.0, 0.0, 655.0, 48.0)));
    expect(
      tester.getRect(find.widgetWithText(MenuItemButton, TestMenu.subMenu10.label)),
      equals(const Rect.fromLTRB(257.0, 56.0, 471.0, 104.0)),
    );
    expect(
      tester.getRect(
        find.ancestor(of: find.text(TestMenu.subMenu10.label), matching: find.byType(Material)).at(1),
      ),
      equals(const Rect.fromLTRB(257.0, 48.0, 471.0, 208.0)),
    );

    // Test compact visual density (-2, -2)
    await tester.pumpWidget(Container());
    await tester.pumpWidget(buildMenu(visualDensity: VisualDensity.compact));
    await tester.pump();

    // The original horizontal padding with standard visual density for menu buttons are 12 px, and the total length
    // for the menu bar is (655 - 145) = 510.
    // There are 4 buttons in the test menu bar, and with compact visual density,
    // the padding will reduce by abs(2 * (-2)) = 4. So the total length
    // now should reduce by abs(4 * 2 * (-4)) = 32, which would be 510 - 32 = 478, and
    // 478 = 639 - 161
    expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(161.0, 0.0, 639.0, 40.0)));

    // Open and make sure things are the right size.
    await tester.tap(find.text(TestMenu.mainMenu1.label));
    await tester.pump();

    expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(161.0, 0.0, 639.0, 40.0)));
    expect(
      tester.getRect(find.widgetWithText(MenuItemButton, TestMenu.subMenu10.label)),
      equals(const Rect.fromLTRB(265.0, 40.0, 467.0, 80.0)),
    );
    expect(
      tester.getRect(
        find.ancestor(of: find.text(TestMenu.subMenu10.label), matching: find.byType(Material)).at(1),
      ),
      equals(const Rect.fromLTRB(265.0, 40.0, 467.0, 160.0)),
    );

    await tester.pumpWidget(Container());
    await tester.pumpWidget(buildMenu(visualDensity: const VisualDensity(horizontal: 2.0, vertical: 2.0)));
    await tester.pump();

    // Similarly, there are 4 buttons in the test menu bar, and with (2, 2) visual density,
    // the padding will increase by abs(2 * 4) = 8. So the total length for buttons
    // should increase by abs(4 * 2 * 8) = 64. The horizontal padding for the menu bar
    // increases by 2 * 8, so the total width increases to 510 + 64 + 16 = 590, and
    // 590 = 695 - 105
    expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(105.0, 0.0, 695.0, 72.0)));

    // Open and make sure things are the right size.
    await tester.tap(find.text(TestMenu.mainMenu1.label));
    await tester.pump();

    expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(105.0, 0.0, 695.0, 72.0)));
    expect(
      tester.getRect(find.widgetWithText(MenuItemButton, TestMenu.subMenu10.label)),
      equals(const Rect.fromLTRB(249.0, 80.0, 483.0, 136.0)),
    );
    expect(
      tester.getRect(
        find.ancestor(of: find.text(TestMenu.subMenu10.label), matching: find.byType(Material)).at(1),
      ),
      equals(const Rect.fromLTRB(241.0, 64.0, 491.0, 264.0)),
    );
  });

  testWidgets('menu defaults colors', (WidgetTester tester) async {
    final ThemeData themeData = ThemeData();
    await tester.pumpWidget(
      MaterialApp(
        theme: themeData,
        home: Material(
          child: MenuBar(
            controller: controller,
            children: createTestMenus(
              onPressed: onPressed,
              onOpen: onOpen,
              onClose: onClose,
            ),
          ),
        ),
      ),
    );

    // menu bar(horizontal menu)
    Finder menuMaterial = find.ancestor(
      of: find.byType(TextButton),
      matching: find.byType(Material),
    ).first;

    Material material = tester.widget<Material>(menuMaterial);
    expect(opened, isEmpty);
    expect(material.color, themeData.colorScheme.surface);
    expect(material.shadowColor, themeData.colorScheme.shadow);
    expect(material.surfaceTintColor, themeData.colorScheme.surfaceTint);
    expect(material.elevation, 3.0);
    expect(material.shape, const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4.0))));

    Finder buttonMaterial = find.descendant(
      of: find.byType(TextButton),
      matching: find.byType(Material),
    ).first;
    material = tester.widget<Material>(buttonMaterial);
    expect(material.color, Colors.transparent);
    expect(material.elevation, 0.0);
    expect(material.shape, const RoundedRectangleBorder());
    expect(material.textStyle?.color, themeData.colorScheme.onSurface);

    // vertical menu
    await tester.tap(find.text(TestMenu.mainMenu1.label));
    await tester.pump();

    menuMaterial = find.ancestor(
      of: find.widgetWithText(TextButton, TestMenu.subMenu10.label),
      matching: find.byType(Material),
    ).first;

    material = tester.widget<Material>(menuMaterial);
    expect(opened.last, equals(TestMenu.mainMenu1));
    expect(material.color, themeData.colorScheme.surface);
    expect(material.shadowColor, themeData.colorScheme.shadow);
    expect(material.surfaceTintColor, themeData.colorScheme.surfaceTint);
    expect(material.elevation, 3.0);
    expect(material.shape, const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4.0))));

    buttonMaterial = find.descendant(
      of: find.widgetWithText(TextButton, TestMenu.subMenu10.label),
      matching: find.byType(Material),
    ).first;
    material = tester.widget<Material>(buttonMaterial);
    expect(material.color, Colors.transparent);
    expect(material.elevation, 0.0);
    expect(material.shape, const RoundedRectangleBorder());
    expect(material.textStyle?.color, themeData.colorScheme.onSurface);

    await tester.tap(find.text(TestMenu.mainMenu0.label));
    await tester.pump();
    expect(find.byIcon(Icons.add), findsOneWidget);
    final RichText iconRichText = tester.widget<RichText>(
      find.descendant(of: find.byIcon(Icons.add), matching: find.byType(RichText)),
    );
    expect(iconRichText.text.style?.color, themeData.colorScheme.onSurfaceVariant);
  });

  testWidgets('menu defaults - disabled', (WidgetTester tester) async {
    final ThemeData themeData = ThemeData();
    await tester.pumpWidget(
      MaterialApp(
        theme: themeData,
        home: Material(
          child: MenuBar(
            controller: controller,
            children: createTestMenus(
              onPressed: onPressed,
              onOpen: onOpen,
              onClose: onClose,
            ),
          ),
        ),
      ),
    );

    // menu bar(horizontal menu)
    Finder menuMaterial = find.ancestor(
      of: find.widgetWithText(TextButton, TestMenu.mainMenu5.label),
      matching: find.byType(Material),
    ).first;

    Material material = tester.widget<Material>(menuMaterial);
    expect(opened, isEmpty);
    expect(material.color, themeData.colorScheme.surface);
    expect(material.shadowColor, themeData.colorScheme.shadow);
    expect(material.surfaceTintColor, themeData.colorScheme.surfaceTint);
    expect(material.elevation, 3.0);
    expect(material.shape, const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4.0))));

    Finder buttonMaterial = find.descendant(
      of: find.widgetWithText(TextButton, TestMenu.mainMenu5.label),
      matching: find.byType(Material),
    ).first;
    material = tester.widget<Material>(buttonMaterial);
    expect(material.color, Colors.transparent);
    expect(material.elevation, 0.0);
    expect(material.shape, const RoundedRectangleBorder());
    expect(material.textStyle?.color, themeData.colorScheme.onSurface.withOpacity(0.38));

    // vertical menu
    await tester.tap(find.text(TestMenu.mainMenu2.label));
    await tester.pump();

    menuMaterial = find.ancestor(
      of: find.widgetWithText(TextButton, TestMenu.subMenu20.label),
      matching: find.byType(Material),
    ).first;

    material = tester.widget<Material>(menuMaterial);
    expect(material.color, themeData.colorScheme.surface);
    expect(material.shadowColor, themeData.colorScheme.shadow);
    expect(material.surfaceTintColor, themeData.colorScheme.surfaceTint);
    expect(material.elevation, 3.0);
    expect(material.shape, const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4.0))));

    buttonMaterial = find.descendant(
      of: find.widgetWithText(TextButton, TestMenu.subMenu20.label),
      matching: find.byType(Material),
    ).first;
    material = tester.widget<Material>(buttonMaterial);
    expect(material.color, Colors.transparent);
    expect(material.elevation, 0.0);
    expect(material.shape, const RoundedRectangleBorder());
    expect(material.textStyle?.color, themeData.colorScheme.onSurface.withOpacity(0.38));

    expect(find.byIcon(Icons.ac_unit), findsOneWidget);
    final RichText iconRichText = tester.widget<RichText>(
      find.descendant(of: find.byIcon(Icons.ac_unit), matching: find.byType(RichText)),
    );
    expect(iconRichText.text.style?.color, themeData.colorScheme.onSurface.withOpacity(0.38));
  });

  testWidgets('Menu scrollbar inherits ScrollbarTheme', (WidgetTester tester) async {
    const ScrollbarThemeData scrollbarTheme = ScrollbarThemeData(
      thumbColor: MaterialStatePropertyAll<Color?>(Color(0xffff0000)),
      thumbVisibility: MaterialStatePropertyAll<bool?>(true),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(scrollbarTheme: scrollbarTheme),
        home: Material(
          child: MenuBar(
            children: <Widget>[
              SubmenuButton(
                menuChildren: <Widget>[
                  MenuItemButton(
                    style: ButtonStyle(
                      minimumSize: MaterialStateProperty.all<Size>(
                        const Size.fromHeight(1000),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text(
                      'Category',
                    ),
                  ),
                ],
                child: const Text(
                  'Main Menu',
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Main Menu'));
    await tester.pumpAndSettle();

    expect(find.byType(Scrollbar), findsOneWidget);
    // Test Scrollbar thumb color.
    expect(
      find.byType(Scrollbar),
      paints..rrect(color: const Color(0xffff0000)),
    );

    // Close the menu.
    await tester.tapAt(const Offset(10.0, 10.0));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(scrollbarTheme: scrollbarTheme),
        home: Material(
          child: ScrollbarTheme(
            data: scrollbarTheme.copyWith(
              thumbColor: const MaterialStatePropertyAll<Color?>(Color(0xff00ff00)),
            ),
            child: MenuBar(
              children: <Widget>[
                SubmenuButton(
                  menuChildren: <Widget>[
                    MenuItemButton(
                      style: ButtonStyle(
                        minimumSize: MaterialStateProperty.all<Size>(
                          const Size.fromHeight(1000),
                        ),
                      ),
                      onPressed: () {},
                      child: const Text(
                        'Category',
                      ),
                    ),
                  ],
                  child: const Text(
                    'Main Menu',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Main Menu'));
    await tester.pumpAndSettle();

    expect(find.byType(Scrollbar), findsOneWidget);
    // Scrollbar thumb color should be updated.
    expect(
      find.byType(Scrollbar),
      paints..rrect(color: const Color(0xff00ff00)),
    );
  }, variant: TargetPlatformVariant.desktop());

  group('Menu functions', () {
    testWidgets('basic menu structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: createTestMenus(
                onPressed: onPressed,
                onOpen: onOpen,
                onClose: onClose,
              ),
            ),
          ),
        ),
      );

      expect(find.text(TestMenu.mainMenu0.label), findsOneWidget);
      expect(find.text(TestMenu.mainMenu1.label), findsOneWidget);
      expect(find.text(TestMenu.mainMenu2.label), findsOneWidget);
      expect(find.text(TestMenu.subMenu10.label), findsNothing);
      expect(find.text(TestMenu.subSubMenu110.label), findsNothing);
      expect(opened, isEmpty);

      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      expect(find.text(TestMenu.mainMenu0.label), findsOneWidget);
      expect(find.text(TestMenu.mainMenu1.label), findsOneWidget);
      expect(find.text(TestMenu.mainMenu2.label), findsOneWidget);
      expect(find.text(TestMenu.subMenu10.label), findsOneWidget);
      expect(find.text(TestMenu.subMenu11.label), findsOneWidget);
      expect(find.text(TestMenu.subMenu12.label), findsOneWidget);
      expect(find.text(TestMenu.subSubMenu110.label), findsNothing);
      expect(find.text(TestMenu.subSubMenu111.label), findsNothing);
      expect(find.text(TestMenu.subSubMenu112.label), findsNothing);
      expect(opened.last, equals(TestMenu.mainMenu1));
      opened.clear();

      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();

      expect(find.text(TestMenu.mainMenu0.label), findsOneWidget);
      expect(find.text(TestMenu.mainMenu1.label), findsOneWidget);
      expect(find.text(TestMenu.mainMenu2.label), findsOneWidget);
      expect(find.text(TestMenu.subMenu10.label), findsOneWidget);
      expect(find.text(TestMenu.subMenu11.label), findsOneWidget);
      expect(find.text(TestMenu.subMenu12.label), findsOneWidget);
      expect(find.text(TestMenu.subSubMenu110.label), findsOneWidget);
      expect(find.text(TestMenu.subSubMenu111.label), findsOneWidget);
      expect(find.text(TestMenu.subSubMenu112.label), findsOneWidget);
      expect(opened.last, equals(TestMenu.subMenu11));
    });

    testWidgets('geometry', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: MenuBar(
                        children: createTestMenus(onPressed: onPressed),
                      ),
                    ),
                  ],
                ),
                const Expanded(child: Placeholder()),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(0, 0, 800, 48)));

      // Open and make sure things are the right size.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(0, 0, 800, 48)));
      expect(
        tester.getRect(find.text(TestMenu.subMenu10.label)),
        equals(const Rect.fromLTRB(124.0, 73.0, 278.0, 87.0)),
      );
      expect(
        tester.getRect(
          find.ancestor(of: find.text(TestMenu.subMenu10.label), matching: find.byType(Material)).at(1),
        ),
        equals(const Rect.fromLTRB(112.0, 48.0, 326.0, 208.0)),
      );

      // Test menu bar size when not expanded.
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                MenuBar(
                  children: createTestMenus(onPressed: onPressed),
                ),
                const Expanded(child: Placeholder()),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        tester.getRect(find.byType(MenuBar)),
        equals(const Rect.fromLTRB(145.0, 0.0, 655.0, 48.0)),
      );
    });

    testWidgets('geometry with RTL direction', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: MenuBar(
                          children: createTestMenus(onPressed: onPressed),
                        ),
                      ),
                    ],
                  ),
                  const Expanded(child: Placeholder()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(0, 0, 800, 48)));

      // Open and make sure things are the right size.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(0, 0, 800, 48)));
      expect(
        tester.getRect(find.text(TestMenu.subMenu10.label)),
        equals(const Rect.fromLTRB(522.0, 73.0, 676.0, 87.0)),
      );
      expect(
        tester.getRect(
          find.ancestor(of: find.text(TestMenu.subMenu10.label), matching: find.byType(Material)).at(1),
        ),
        equals(const Rect.fromLTRB(474.0, 48.0, 688.0, 208.0)),
      );

      // Close and make sure it goes back where it was.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(0, 0, 800, 48)));

      // Test menu bar size when not expanded.
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: <Widget>[
                  MenuBar(
                    children: createTestMenus(onPressed: onPressed),
                  ),
                  const Expanded(child: Placeholder()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        tester.getRect(find.byType(MenuBar)),
        equals(const Rect.fromLTRB(145.0, 0.0, 655.0, 48.0)),
      );
    });

    testWidgets('menu alignment and offset in LTR', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      final Rect buttonRect = tester.getRect(find.byType(ElevatedButton));
      expect(buttonRect, equals(const Rect.fromLTRB(328.0, 276.0, 472.0, 324.0)));

      final Finder findMenuScope = find.ancestor(of: find.byKey(menuItemKey), matching: find.byType(FocusScope)).first;

      // Open the menu and make sure things are the right size, in the right place.
      await tester.tap(find.text('Press Me'));
      await tester.pump();
      expect(tester.getRect(findMenuScope), equals(const Rect.fromLTRB(328.0, 324.0, 602.0, 436.0)));

      await tester.pumpWidget(buildTestApp(alignment: AlignmentDirectional.topStart));
      await tester.pump();
      expect(tester.getRect(findMenuScope), equals(const Rect.fromLTRB(328.0, 276.0, 602.0, 388.0)));

      await tester.pumpWidget(buildTestApp(alignment: AlignmentDirectional.center));
      await tester.pump();
      expect(tester.getRect(findMenuScope), equals(const Rect.fromLTRB(400.0, 300.0, 674.0, 412.0)));

      await tester.pumpWidget(buildTestApp(alignment: AlignmentDirectional.bottomEnd));
      await tester.pump();
      expect(tester.getRect(findMenuScope), equals(const Rect.fromLTRB(472.0, 324.0, 746.0, 436.0)));

      await tester.pumpWidget(buildTestApp(alignment: AlignmentDirectional.topStart));
      await tester.pump();

      final Rect menuRect = tester.getRect(findMenuScope);
      await tester.pumpWidget(
        buildTestApp(
          alignment: AlignmentDirectional.topStart,
          alignmentOffset: const Offset(10, 20),
        ),
      );
      await tester.pump();
      final Rect offsetMenuRect = tester.getRect(findMenuScope);
      expect(
        offsetMenuRect.topLeft - menuRect.topLeft,
        equals(const Offset(10, 20)),
      );
    });

    testWidgets('menu alignment and offset in RTL', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(textDirection: TextDirection.rtl));

      final Rect buttonRect = tester.getRect(find.byType(ElevatedButton));
      expect(buttonRect, equals(const Rect.fromLTRB(328.0, 276.0, 472.0, 324.0)));

      final Finder findMenuScope =
          find.ancestor(of: find.text(TestMenu.subMenu00.label), matching: find.byType(FocusScope)).first;

      // Open the menu and make sure things are the right size, in the right place.
      await tester.tap(find.text('Press Me'));
      await tester.pump();
      expect(tester.getRect(findMenuScope), equals(const Rect.fromLTRB(198.0, 324.0, 472.0, 436.0)));

      await tester.pumpWidget(buildTestApp(textDirection: TextDirection.rtl, alignment: AlignmentDirectional.topStart));
      await tester.pump();
      expect(tester.getRect(findMenuScope), equals(const Rect.fromLTRB(198.0, 276.0, 472.0, 388.0)));

      await tester.pumpWidget(buildTestApp(textDirection: TextDirection.rtl, alignment: AlignmentDirectional.center));
      await tester.pump();
      expect(tester.getRect(findMenuScope), equals(const Rect.fromLTRB(126.0, 300.0, 400.0, 412.0)));

      await tester
          .pumpWidget(buildTestApp(textDirection: TextDirection.rtl, alignment: AlignmentDirectional.bottomEnd));
      await tester.pump();
      expect(tester.getRect(findMenuScope), equals(const Rect.fromLTRB(54.0, 324.0, 328.0, 436.0)));

      await tester.pumpWidget(buildTestApp(textDirection: TextDirection.rtl, alignment: AlignmentDirectional.topStart));
      await tester.pump();

      final Rect menuRect = tester.getRect(findMenuScope);
      await tester.pumpWidget(
        buildTestApp(
          textDirection: TextDirection.rtl,
          alignment: AlignmentDirectional.topStart,
          alignmentOffset: const Offset(10, 20),
        ),
      );
      await tester.pump();
      expect(tester.getRect(findMenuScope).topLeft - menuRect.topLeft, equals(const Offset(-10, 20)));
    });

    testWidgets('menu position in LTR', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(alignmentOffset: const Offset(100, 50)));

      final Rect buttonRect = tester.getRect(find.byType(ElevatedButton));
      expect(buttonRect, equals(const Rect.fromLTRB(328.0, 276.0, 472.0, 324.0)));

      final Finder findMenuScope =
          find.ancestor(of: find.text(TestMenu.subMenu00.label), matching: find.byType(FocusScope)).first;

      // Open the menu and make sure things are the right size, in the right place.
      await tester.tap(find.text('Press Me'));
      await tester.pump();
      expect(tester.getRect(findMenuScope), equals(const Rect.fromLTRB(428.0, 374.0, 702.0, 486.0)));

      // Now move the menu by calling open() again with a local position on the
      // anchor.
      controller.open(position: const Offset(200, 200));
      await tester.pump();
      expect(tester.getRect(findMenuScope), equals(const Rect.fromLTRB(526.0, 476.0, 800.0, 588.0)));
    });

    testWidgets('menu position in RTL', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(
        alignmentOffset: const Offset(100, 50),
        textDirection: TextDirection.rtl,
      ));

      final Rect buttonRect = tester.getRect(find.byType(ElevatedButton));
      expect(buttonRect, equals(const Rect.fromLTRB(328.0, 276.0, 472.0, 324.0)));
      expect(buttonRect, equals(const Rect.fromLTRB(328.0, 276.0, 472.0, 324.0)));

      final Finder findMenuScope =
          find.ancestor(of: find.text(TestMenu.subMenu00.label), matching: find.byType(FocusScope)).first;

      // Open the menu and make sure things are the right size, in the right place.
      await tester.tap(find.text('Press Me'));
      await tester.pump();
      expect(tester.getRect(findMenuScope), equals(const Rect.fromLTRB(98.0, 374.0, 372.0, 486.0)));

      // Now move the menu by calling open() again with a local position on the
      // anchor.
      controller.open(position: const Offset(400, 200));
      await tester.pump();
      expect(tester.getRect(findMenuScope), equals(const Rect.fromLTRB(526.0, 476.0, 800.0, 588.0)));
    });

    testWidgets('works with Padding around menu and overlay', (WidgetTester tester) async {
      await tester.pumpWidget(
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: MaterialApp(
            home: Material(
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: MenuBar(
                            children: createTestMenus(onPressed: onPressed),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Expanded(child: Placeholder()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(22.0, 22.0, 778.0, 70.0)));

      // Open and make sure things are the right size.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(22.0, 22.0, 778.0, 70.0)));
      expect(
        tester.getRect(find.text(TestMenu.subMenu10.label)),
        equals(const Rect.fromLTRB(146.0, 95.0, 300.0, 109.0)),
      );
      expect(
        tester.getRect(find.ancestor(of: find.text(TestMenu.subMenu10.label), matching: find.byType(Material)).at(1)),
        equals(const Rect.fromLTRB(134.0, 70.0, 348.0, 230.0)),
      );

      // Close and make sure it goes back where it was.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(22.0, 22.0, 778.0, 70.0)));
    });

    testWidgets('works with Padding around menu and overlay with RTL direction', (WidgetTester tester) async {
      await tester.pumpWidget(
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: MaterialApp(
            home: Material(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: MenuBar(
                              children: createTestMenus(onPressed: onPressed),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Expanded(child: Placeholder()),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(22.0, 22.0, 778.0, 70.0)));

      // Open and make sure things are the right size.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(22.0, 22.0, 778.0, 70.0)));
      expect(
        tester.getRect(find.text(TestMenu.subMenu10.label)),
        equals(const Rect.fromLTRB(500.0, 95.0, 654.0, 109.0)),
      );
      expect(
        tester.getRect(find.ancestor(of: find.text(TestMenu.subMenu10.label), matching: find.byType(Material)).at(1)),
        equals(const Rect.fromLTRB(452.0, 70.0, 666.0, 230.0)),
      );

      // Close and make sure it goes back where it was.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(22.0, 22.0, 778.0, 70.0)));
    });

    testWidgets('visual attributes can be set', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: MenuBar(
                        style: MenuStyle(
                          elevation: MaterialStateProperty.all<double?>(10),
                          backgroundColor: const MaterialStatePropertyAll<Color>(Colors.red),
                        ),
                        children: createTestMenus(onPressed: onPressed),
                      ),
                    ),
                  ],
                ),
                const Expanded(child: Placeholder()),
              ],
            ),
          ),
        ),
      );
      expect(tester.getRect(findMenuPanels()), equals(const Rect.fromLTRB(0.0, 0.0, 800.0, 48.0)));
      final Material material = getMenuBarMaterial(tester);
      expect(material.elevation, equals(10));
      expect(material.color, equals(Colors.red));
    });

    testWidgets('MenuAnchor clip behavior', (WidgetTester tester) async {
      await tester.pumpWidget(
          MaterialApp(
              home: Material(
                  child: Center(
                    child: MenuAnchor(
                      menuChildren: const <Widget> [
                        MenuItemButton(
                          child: Text('Button 1'),
                        ),
                      ],
                      builder: (BuildContext context, MenuController controller, Widget? child) {
                        return FilledButton(
                          onPressed: () {
                            controller.open();
                          },
                          child: const Text('Tap me'),
                        );
                      },
                    ),
                  )
              )
          )
      );
      await tester.tap(find.text('Tap me'));
      await tester.pump();
      // Test default clip behavior.
      expect(getMenuBarMaterial(tester).clipBehavior, equals(Clip.hardEdge));
      // Close the menu.
      await tester.tapAt(const Offset(10.0, 10.0));
      await tester.pumpAndSettle();
      await tester.pumpWidget(
          MaterialApp(
              home: Material(
                  child: Center(
                    child: MenuAnchor(
                      clipBehavior: Clip.antiAlias,
                      menuChildren: const <Widget> [
                        MenuItemButton(
                          child: Text('Button 1'),
                        ),
                      ],
                      builder: (BuildContext context, MenuController controller, Widget? child) {
                        return FilledButton(
                          onPressed: () {
                            controller.open();
                          },
                          child: const Text('Tap me'),
                        );
                      },
                    ),
                  )
              )
          )
      );
      await tester.tap(find.text('Tap me'));
      await tester.pump();
      // Test custom clip behavior.
      expect(getMenuBarMaterial(tester).clipBehavior, equals(Clip.antiAlias));
    });

    testWidgets('open and close works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: createTestMenus(
                onPressed: onPressed,
                onOpen: onOpen,
                onClose: onClose,
              ),
            ),
          ),
        ),
      );

      expect(opened, isEmpty);
      expect(closed, isEmpty);

      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();
      expect(opened, equals(<TestMenu>[TestMenu.mainMenu1]));
      expect(closed, isEmpty);
      opened.clear();
      closed.clear();

      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();

      expect(opened, equals(<TestMenu>[TestMenu.subMenu11]));
      expect(closed, isEmpty);
      opened.clear();
      closed.clear();

      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();

      expect(opened, isEmpty);
      expect(closed, equals(<TestMenu>[TestMenu.subMenu11]));
      opened.clear();
      closed.clear();

      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pump();

      expect(opened, equals(<TestMenu>[TestMenu.mainMenu0]));
      expect(closed, equals(<TestMenu>[TestMenu.mainMenu1]));
    });

    testWidgets('select works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: createTestMenus(
                onPressed: onPressed,
                onOpen: onOpen,
                onClose: onClose,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();

      expect(opened, equals(<TestMenu>[TestMenu.mainMenu1, TestMenu.subMenu11]));
      opened.clear();
      await tester.tap(find.text(TestMenu.subSubMenu110.label));
      await tester.pump();

      expect(selected, equals(<TestMenu>[TestMenu.subSubMenu110]));

      // Selecting a non-submenu item should close all the menus.
      expect(opened, isEmpty);
      expect(find.text(TestMenu.subSubMenu110.label), findsNothing);
      expect(find.text(TestMenu.subMenu11.label), findsNothing);
    });

    testWidgets('diagnostics', (WidgetTester tester) async {
      const MenuItemButton item = MenuItemButton(
        shortcut: SingleActivator(LogicalKeyboardKey.keyA),
        child: Text('label2'),
      );
      final MenuBar menuBar = MenuBar(
        controller: controller,
        style: const MenuStyle(
          backgroundColor: MaterialStatePropertyAll<Color>(Colors.red),
          elevation: MaterialStatePropertyAll<double?>(10.0),
        ),
        children: const <Widget>[item],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: menuBar,
          ),
        ),
      );
      await tester.pump();

      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
      menuBar.debugFillProperties(builder);

      final List<String> description = builder.properties
          .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
          .map((DiagnosticsNode node) => node.toString())
          .toList();

      expect(
        description.join('\n'),
        equalsIgnoringHashCodes(
            'style: MenuStyle#00000(backgroundColor: MaterialStatePropertyAll(MaterialColor(primary value: Color(0xfff44336))), elevation: MaterialStatePropertyAll(10.0))\n'
            'clipBehavior: Clip.none'),
      );
    });

    testWidgets('keyboard tab traversal works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                MenuBar(
                  controller: controller,
                  children: createTestMenus(
                    onPressed: onPressed,
                    onOpen: onOpen,
                    onClose: onClose,
                  ),
                ),
                const Expanded(child: Placeholder()),
              ],
            ),
          ),
        ),
      );

      listenForFocusChanges();

      // Have to open a menu initially to start things going.
      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pumpAndSettle();

      expect(focusedMenu, equals('SubmenuButton(Text("Menu 0"))'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Menu 1"))'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Menu 2"))'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Menu 0"))'));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Menu 2"))'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Menu 1"))'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Menu 0"))'));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      opened.clear();
      closed.clear();

      // Test closing a menu with enter.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(opened, isEmpty);
      expect(closed, <TestMenu>[TestMenu.mainMenu0]);
    });

    testWidgets('keyboard directional traversal works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: createTestMenus(
                onPressed: onPressed,
                onOpen: onOpen,
                onClose: onClose,
              ),
            ),
          ),
        ),
      );

      listenForFocusChanges();

      // Have to open a menu initially to start things going.
      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Menu 1"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Menu 10"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('SubmenuButton(Text("Sub Menu 11"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Menu 12"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Menu 12"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Sub Menu 11"))'));

      // Open the next submenu
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 110"))'));

      // Go back, close the submenu.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Sub Menu 11"))'));

      // Move up, should close the submenu.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Menu 10"))'));

      // Move down, should reopen the submenu.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Sub Menu 11"))'));

      // Open the next submenu again.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 110"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 111"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 112"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 113"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 113"))'));
    });

    testWidgets('keyboard directional traversal works in RTL mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Material(
              child: MenuBar(
                controller: controller,
                children: createTestMenus(
                  onPressed: onPressed,
                  onOpen: onOpen,
                  onClose: onClose,
                ),
              ),
            ),
          ),
        ),
      );

      listenForFocusChanges();

      // Have to open a menu initially to start things going.
      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(focusedMenu, equals('SubmenuButton(Text("Menu 1"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Menu 1"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Menu 10"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('SubmenuButton(Text("Sub Menu 11"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Menu 12"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Menu 12"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Sub Menu 11"))'));

      // Open the next submenu
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 110"))'));

      // Go back, close the submenu.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Sub Menu 11"))'));

      // Move up, should close the submenu.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Menu 10"))'));

      // Move down, should reopen the submenu.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Sub Menu 11"))'));

      // Open the next submenu again.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 110"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 111"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 112"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 113"))'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 113"))'));
    });

    testWidgets('hover traversal works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: createTestMenus(
                onPressed: onPressed,
                onOpen: onOpen,
                onClose: onClose,
              ),
            ),
          ),
        ),
      );

      listenForFocusChanges();

      // Hovering when the menu is not yet open does nothing.
      await hoverOver(tester, find.text(TestMenu.mainMenu0.label));
      await tester.pump();
      expect(focusedMenu, isNull);

      // Have to open a menu initially to start things going.
      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Menu 0"))'));

      // Hovering when the menu is already  open does nothing.
      await hoverOver(tester, find.text(TestMenu.mainMenu0.label));
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Menu 0"))'));

      // Hovering over the other main menu items opens them now.
      await hoverOver(tester, find.text(TestMenu.mainMenu2.label));
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Menu 2"))'));

      await hoverOver(tester, find.text(TestMenu.mainMenu1.label));
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Menu 1"))'));

      // Hovering over the menu items focuses them.
      await hoverOver(tester, find.text(TestMenu.subMenu10.label));
      await tester.pump();
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Menu 10"))'));

      await hoverOver(tester, find.text(TestMenu.subMenu11.label));
      await tester.pump();
      expect(focusedMenu, equals('SubmenuButton(Text("Sub Menu 11"))'));

      await hoverOver(tester, find.text(TestMenu.subSubMenu110.label));
      await tester.pump();
      expect(focusedMenu, equals('MenuItemButton(Text("Sub Sub Menu 110"))'));
    });

    testWidgets('menus close on ancestor scroll', (WidgetTester tester) async {
      final ScrollController scrollController = ScrollController();
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: SingleChildScrollView(
              controller: scrollController,
              child: Container(
                height: 1000,
                alignment: Alignment.center,
                child: MenuBar(
                  controller: controller,
                  children: createTestMenus(
                    onPressed: onPressed,
                    onOpen: onOpen,
                    onClose: onClose,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pump();

      expect(opened, isNotEmpty);
      expect(closed, isEmpty);
      opened.clear();

      scrollController.jumpTo(1000);
      await tester.pump();

      expect(opened, isEmpty);
      expect(closed, isNotEmpty);
    });

    testWidgets('menus do not close on root menu internal scroll', (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/122168.
      final ScrollController scrollController = ScrollController();
      bool rootOpened = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            menuButtonTheme: MenuButtonThemeData(
              // Increase menu items height to make root menu scrollable.
              style: TextButton.styleFrom(minimumSize: const Size.fromHeight(200)),
            ),
          ),
          home: Material(
            child: SingleChildScrollView(
              controller: scrollController,
              child: Container(
                height: 1000,
                alignment: Alignment.topLeft,
                child: MenuAnchor(
                  controller: controller,
                  alignmentOffset: const Offset(0, 10),
                  builder: (BuildContext context, MenuController controller, Widget? child) {
                    return FilledButton.tonal(
                      onPressed: () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                      child: const Text('Show menu'),
                    );
                  },
                  onOpen: () { rootOpened = true; },
                  onClose: () { rootOpened = false; },
                  menuChildren: createTestMenus(
                    onPressed: onPressed,
                    onOpen: onOpen,
                    onClose: onClose,
                    includeExtraGroups: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show menu'));
      await tester.pump();
      expect(rootOpened, true);

      // Hover the first item.
      final TestPointer pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(pointer.hover(tester.getCenter(find.text(TestMenu.mainMenu0.label))));
      await tester.pump();
      expect(opened, isNotEmpty);

      // Menus do not close on internal scroll.
      await tester.sendEventToBinding(pointer.scroll(const Offset(0.0, 30.0)));
      await tester.pump();
      expect(rootOpened, true);
      expect(closed, isEmpty);

      // Menus close on external scroll.
      scrollController.jumpTo(1000);
      await tester.pump();
      expect(rootOpened, false);
      expect(closed, isNotEmpty);
    });

    testWidgets('menus close on view size change', (WidgetTester tester) async {
      final ScrollController scrollController = ScrollController();
      final MediaQueryData mediaQueryData = MediaQueryData.fromView(tester.view);

      Widget build(Size size) {
        return MaterialApp(
          home: Material(
            child: MediaQuery(
              data: mediaQueryData.copyWith(size: size),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Container(
                  height: 1000,
                  alignment: Alignment.center,
                  child: MenuBar(
                    controller: controller,
                    children: createTestMenus(
                      onPressed: onPressed,
                      onOpen: onOpen,
                      onClose: onClose,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(build(mediaQueryData.size));

      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pump();

      expect(opened, isNotEmpty);
      expect(closed, isEmpty);
      opened.clear();

      const Size smallSize = Size(200, 200);
      await changeSurfaceSize(tester, smallSize);

      await tester.pumpWidget(build(smallSize));
      await tester.pump();

      expect(opened, isEmpty);
      expect(closed, isNotEmpty);
    });
  });

  group('Accelerators', () {
    const Set<TargetPlatform> apple = <TargetPlatform>{TargetPlatform.macOS, TargetPlatform.iOS};
    final Set<TargetPlatform> nonApple = TargetPlatform.values.toSet().difference(apple);

    test('Accelerator markers are stripped properly', () {
      const Map<String, String> expected = <String, String>{
        'Plain String': 'Plain String',
        '&Simple Accelerator': 'Simple Accelerator',
        '&Multiple &Accelerators': 'Multiple Accelerators',
        'Whitespace & Accelerators': 'Whitespace  Accelerators',
        '&Quoted && Ampersand': 'Quoted & Ampersand',
        'Ampersand at End &': 'Ampersand at End ',
        '&&Multiple Ampersands &&& &&&A &&&&B &&&&': '&Multiple Ampersands & &A &&B &&',
        'Bohrium 𨨏 Code point U+28A0F': 'Bohrium 𨨏 Code point U+28A0F',
      };
      const List<int> expectedIndices = <int>[-1, 0, 0, -1, 0, -1, 24, -1];
      const List<bool> expectedHasAccelerator = <bool>[false, true, true, false, true, false, true, false];
      int acceleratorIndex = -1;
      int count = 0;
      for (final String key in expected.keys) {
        expect(MenuAcceleratorLabel.stripAcceleratorMarkers(key, setIndex: (int index) {
            acceleratorIndex = index;
          }), equals(expected[key]),
          reason: "'$key' label doesn't match ${expected[key]}");
        expect(acceleratorIndex, equals(expectedIndices[count]),
          reason: "'$key' index doesn't match ${expectedIndices[count]}");
        expect(MenuAcceleratorLabel(key).hasAccelerator, equals(expectedHasAccelerator[count]),
          reason: "'$key' hasAccelerator isn't ${expectedHasAccelerator[count]}");
        count += 1;
      }
    });

    testWidgets('can invoke menu items', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              key: UniqueKey(),
              controller: controller,
              children: createTestMenus(
                onPressed: onPressed,
                onOpen: onOpen,
                onClose: onClose,
                accelerators: true,
              ),
            ),
          ),
        ),
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM, character: 'm');
      await tester.pump();
      // Makes sure that identical accelerators in parent menu items don't
      // shadow the ones in the children.
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM, character: 'm');
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pump();

      expect(opened, equals(<TestMenu>[TestMenu.mainMenu0]));
      expect(closed, equals(<TestMenu>[TestMenu.mainMenu0]));
      expect(selected, equals(<TestMenu>[TestMenu.subMenu00]));
      // Selecting a non-submenu item should close all the menus.
      expect(find.text(TestMenu.subMenu00.label), findsNothing);
      opened.clear();
      closed.clear();
      selected.clear();

      // Invoking several levels deep.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM, character: 'e');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM, character: '1');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM, character: '1');
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altRight);
      await tester.pump();

      expect(opened, equals(<TestMenu>[TestMenu.mainMenu1, TestMenu.subMenu11]));
      expect(closed, equals(<TestMenu>[TestMenu.subMenu11, TestMenu.mainMenu1]));
      expect(selected, equals(<TestMenu>[TestMenu.subSubMenu111]));
      opened.clear();
      closed.clear();
      selected.clear();
    }, variant: TargetPlatformVariant(nonApple));

    testWidgets('can combine with regular keyboard navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              key: UniqueKey(),
              controller: controller,
              children: createTestMenus(
                onPressed: onPressed,
                onOpen: onOpen,
                onClose: onClose,
                accelerators: true,
              ),
            ),
          ),
        ),
      );

      // Combining accelerators and regular keyboard navigation works.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM, character: 'e');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM, character: '1');
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(opened, equals(<TestMenu>[TestMenu.mainMenu1, TestMenu.subMenu11]));
      expect(closed, equals(<TestMenu>[TestMenu.subMenu11, TestMenu.mainMenu1]));
      expect(selected, equals(<TestMenu>[TestMenu.subSubMenu110]));
    }, variant: TargetPlatformVariant(nonApple));

    testWidgets('can combine with mouse', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              key: UniqueKey(),
              controller: controller,
              children: createTestMenus(
                onPressed: onPressed,
                onOpen: onOpen,
                onClose: onClose,
                accelerators: true,
              ),
            ),
          ),
        ),
      );

      // Combining accelerators and regular keyboard navigation works.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM, character: 'e');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM, character: '1');
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pump();
      await tester.tap(find.text(TestMenu.subSubMenu112.label));
      await tester.pump();

      expect(opened, equals(<TestMenu>[TestMenu.mainMenu1, TestMenu.subMenu11]));
      expect(closed, equals(<TestMenu>[TestMenu.subMenu11, TestMenu.mainMenu1]));
      expect(selected, equals(<TestMenu>[TestMenu.subSubMenu112]));
    }, variant: TargetPlatformVariant(nonApple));

    testWidgets("disabled items don't respond to accelerators", (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              key: UniqueKey(),
              controller: controller,
              children: createTestMenus(
                onPressed: onPressed,
                onOpen: onOpen,
                onClose: onClose,
                accelerators: true,
              ),
            ),
          ),
        ),
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM, character: '5');
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pump();

      expect(opened, isEmpty);
      expect(closed, isEmpty);
      expect(selected, isEmpty);
      // Selecting a non-submenu item should close all the menus.
      expect(find.text(TestMenu.subMenu00.label), findsNothing);
    }, variant: TargetPlatformVariant(nonApple));

    testWidgets("Apple platforms don't react to accelerators", (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              key: UniqueKey(),
              controller: controller,
              children: createTestMenus(
                onPressed: onPressed,
                onOpen: onOpen,
                onClose: onClose,
                accelerators: true,
              ),
            ),
          ),
        ),
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM, character: 'm');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM, character: 'm');
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pump();

      expect(opened, isEmpty);
      expect(closed, isEmpty);
      expect(selected, isEmpty);

      // Or with the option key equivalents.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM, character: 'µ');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM, character: 'µ');
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pump();

      expect(opened, isEmpty);
      expect(closed, isEmpty);
      expect(selected, isEmpty);
    }, variant: const TargetPlatformVariant(apple));
  });

  group('MenuController', () {
    testWidgets('Moving a controller to a new instance works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              key: UniqueKey(),
              controller: controller,
              children: createTestMenus(),
            ),
          ),
        ),
      );

      // Open a menu initially.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();

      // Now pump a new menu with a different UniqueKey to dispose of the opened
      // menu's node, but keep the existing controller.
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              key: UniqueKey(),
              controller: controller,
              children: createTestMenus(
                includeExtraGroups: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('closing via controller works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: createTestMenus(
                onPressed: onPressed,
                onOpen: onOpen,
                onClose: onClose,
                shortcuts: <TestMenu, MenuSerializableShortcut>{
                  TestMenu.subSubMenu110: const SingleActivator(
                    LogicalKeyboardKey.keyA,
                    control: true,
                  )
                },
              ),
            ),
          ),
        ),
      );

      // Open a menu initially.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();
      expect(opened, unorderedEquals(<TestMenu>[TestMenu.mainMenu1, TestMenu.subMenu11]));
      opened.clear();
      closed.clear();

      // Close menus using the controller
      controller.close();
      await tester.pump();

      // The menu should go away,
      expect(closed, unorderedEquals(<TestMenu>[TestMenu.mainMenu1, TestMenu.subMenu11]));
      expect(opened, isEmpty);
    });
  });

  group('MenuItemButton', () {
    testWidgets('Shortcut mnemonics are displayed', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: createTestMenus(
                shortcuts: <TestMenu, MenuSerializableShortcut>{
                  TestMenu.subSubMenu110: const SingleActivator(LogicalKeyboardKey.keyA, control: true),
                  TestMenu.subSubMenu111: const SingleActivator(LogicalKeyboardKey.keyB, shift: true),
                  TestMenu.subSubMenu112: const SingleActivator(LogicalKeyboardKey.keyC, alt: true),
                  TestMenu.subSubMenu113: const SingleActivator(LogicalKeyboardKey.keyD, meta: true),
                },
              ),
            ),
          ),
        ),
      );

      // Open a menu initially.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();

      Text mnemonic0;
      Text mnemonic1;
      Text mnemonic2;
      Text mnemonic3;

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
          mnemonic0 = tester.widget(findMnemonic(TestMenu.subSubMenu110.label));
          expect(mnemonic0.data, equals('Ctrl+A'));
          mnemonic1 = tester.widget(findMnemonic(TestMenu.subSubMenu111.label));
          expect(mnemonic1.data, equals('Shift+B'));
          mnemonic2 = tester.widget(findMnemonic(TestMenu.subSubMenu112.label));
          expect(mnemonic2.data, equals('Alt+C'));
          mnemonic3 = tester.widget(findMnemonic(TestMenu.subSubMenu113.label));
          expect(mnemonic3.data, equals('Meta+D'));
        case TargetPlatform.windows:
          mnemonic0 = tester.widget(findMnemonic(TestMenu.subSubMenu110.label));
          expect(mnemonic0.data, equals('Ctrl+A'));
          mnemonic1 = tester.widget(findMnemonic(TestMenu.subSubMenu111.label));
          expect(mnemonic1.data, equals('Shift+B'));
          mnemonic2 = tester.widget(findMnemonic(TestMenu.subSubMenu112.label));
          expect(mnemonic2.data, equals('Alt+C'));
          mnemonic3 = tester.widget(findMnemonic(TestMenu.subSubMenu113.label));
          expect(mnemonic3.data, equals('Win+D'));
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          mnemonic0 = tester.widget(findMnemonic(TestMenu.subSubMenu110.label));
          expect(mnemonic0.data, equals('⌃ A'));
          mnemonic1 = tester.widget(findMnemonic(TestMenu.subSubMenu111.label));
          expect(mnemonic1.data, equals('⇧ B'));
          mnemonic2 = tester.widget(findMnemonic(TestMenu.subSubMenu112.label));
          expect(mnemonic2.data, equals('⌥ C'));
          mnemonic3 = tester.widget(findMnemonic(TestMenu.subSubMenu113.label));
          expect(mnemonic3.data, equals('⌘ D'));
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: createTestMenus(
                includeExtraGroups: true,
                shortcuts: <TestMenu, MenuSerializableShortcut>{
                  TestMenu.subSubMenu110: const SingleActivator(LogicalKeyboardKey.arrowRight),
                  TestMenu.subSubMenu111: const SingleActivator(LogicalKeyboardKey.arrowLeft),
                  TestMenu.subSubMenu112: const SingleActivator(LogicalKeyboardKey.arrowUp),
                  TestMenu.subSubMenu113: const SingleActivator(LogicalKeyboardKey.arrowDown),
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      mnemonic0 = tester.widget(findMnemonic(TestMenu.subSubMenu110.label));
      expect(mnemonic0.data, equals('→'));
      mnemonic1 = tester.widget(findMnemonic(TestMenu.subSubMenu111.label));
      expect(mnemonic1.data, equals('←'));
      mnemonic2 = tester.widget(findMnemonic(TestMenu.subSubMenu112.label));
      expect(mnemonic2.data, equals('↑'));
      mnemonic3 = tester.widget(findMnemonic(TestMenu.subSubMenu113.label));
      expect(mnemonic3.data, equals('↓'));

      // Try some weirder ones.
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: createTestMenus(
                shortcuts: <TestMenu, MenuSerializableShortcut>{
                  TestMenu.subSubMenu110: const SingleActivator(LogicalKeyboardKey.escape),
                  TestMenu.subSubMenu111: const SingleActivator(LogicalKeyboardKey.fn),
                  TestMenu.subSubMenu112: const SingleActivator(LogicalKeyboardKey.enter),
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      mnemonic0 = tester.widget(findMnemonic(TestMenu.subSubMenu110.label));
      expect(mnemonic0.data, equals('Esc'));
      mnemonic1 = tester.widget(findMnemonic(TestMenu.subSubMenu111.label));
      expect(mnemonic1.data, equals('Fn'));
      mnemonic2 = tester.widget(findMnemonic(TestMenu.subSubMenu112.label));
      expect(mnemonic2.data, equals('↵'));
    }, variant: TargetPlatformVariant.all());

    testWidgets('leadingIcon is used when set', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: <Widget>[
                SubmenuButton(
                  menuChildren: <Widget>[
                    MenuItemButton(
                      leadingIcon: const Text('leadingIcon'),
                      child: Text(TestMenu.subMenu00.label),
                    ),
                  ],
                  child: Text(TestMenu.mainMenu0.label),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pump();

      expect(find.text('leadingIcon'), findsOneWidget);
    });

    testWidgets('trailingIcon is used when set', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: <Widget>[
                SubmenuButton(
                  menuChildren: <Widget>[
                    MenuItemButton(
                      trailingIcon: const Text('trailingIcon'),
                      child: Text(TestMenu.subMenu00.label),
                    ),
                  ],
                  child: Text(TestMenu.mainMenu0.label),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pump();

      expect(find.text('trailingIcon'), findsOneWidget);
    });

    testWidgets('diagnostics', (WidgetTester tester) async {
      final ButtonStyle style = ButtonStyle(
        shape: MaterialStateProperty.all<OutlinedBorder?>(const StadiumBorder()),
        elevation: MaterialStateProperty.all<double?>(10.0),
        backgroundColor: const MaterialStatePropertyAll<Color>(Colors.red),
      );
      final MenuStyle menuStyle = MenuStyle(
        shape: MaterialStateProperty.all<OutlinedBorder?>(const RoundedRectangleBorder()),
        elevation: MaterialStateProperty.all<double?>(20.0),
        backgroundColor: const MaterialStatePropertyAll<Color>(Colors.green),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: <Widget>[
                SubmenuButton(
                  style: style,
                  menuStyle: menuStyle,
                  menuChildren: <Widget>[
                    MenuItemButton(
                      style: style,
                      child: Text(TestMenu.subMenu00.label),
                    ),
                  ],
                  child: Text(TestMenu.mainMenu0.label),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pump();

      final SubmenuButton submenu = tester.widget(find.byType(SubmenuButton));
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
      submenu.debugFillProperties(builder);

      final List<String> description = builder.properties
          .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
          .map((DiagnosticsNode node) => node.toString())
          .toList();

      expect(
        description,
        equalsIgnoringHashCodes(
          <String>[
            'child: Text("Menu 0")',
            'focusNode: null',
            'menuStyle: MenuStyle#00000(backgroundColor: MaterialStatePropertyAll(MaterialColor(primary value: Color(0xff4caf50))), elevation: MaterialStatePropertyAll(20.0), shape: MaterialStatePropertyAll(RoundedRectangleBorder(BorderSide(width: 0.0, style: none), BorderRadius.zero)))',
            'alignmentOffset: null',
            'clipBehavior: hardEdge',
          ],
        ),
      );
    });
  });

  group('Layout', () {
    List<Rect> collectMenuItemRects() {
      final List<Rect> menuRects = <Rect>[];
      final List<Element> candidates = find.byType(SubmenuButton).evaluate().toList();
      for (final Element candidate in candidates) {
        final RenderBox box = candidate.renderObject! as RenderBox;
        final Offset topLeft = box.localToGlobal(box.size.topLeft(Offset.zero));
        final Offset bottomRight = box.localToGlobal(box.size.bottomRight(Offset.zero));
        menuRects.add(Rect.fromPoints(topLeft, bottomRight));
      }
      return menuRects;
    }

    List<Rect> collectSubmenuRects() {
      final List<Rect> menuRects = <Rect>[];
      final List<Element> candidates = findMenuPanels().evaluate().toList();
      for (final Element candidate in candidates) {
        final RenderBox box = candidate.renderObject! as RenderBox;
        final Offset topLeft = box.localToGlobal(box.size.topLeft(Offset.zero));
        final Offset bottomRight = box.localToGlobal(box.size.bottomRight(Offset.zero));
        menuRects.add(Rect.fromPoints(topLeft, bottomRight));
      }
      return menuRects;
    }

    testWidgets('unconstrained menus show up in the right place in LTR', (WidgetTester tester) async {
      await changeSurfaceSize(tester, const Size(800, 600));
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: MenuBar(
                        children: createTestMenus(onPressed: onPressed),
                      ),
                    ),
                  ],
                ),
                const Expanded(child: Placeholder()),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();
      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();

      expect(find.byType(MenuItemButton), findsNWidgets(6));
      expect(find.byType(SubmenuButton), findsNWidgets(5));
      expect(
        collectMenuItemRects(),
        equals(const <Rect>[
          Rect.fromLTRB(4.0, 0.0, 112.0, 48.0),
          Rect.fromLTRB(112.0, 0.0, 220.0, 48.0),
          Rect.fromLTRB(220.0, 0.0, 328.0, 48.0),
          Rect.fromLTRB(328.0, 0.0, 506.0, 48.0),
          Rect.fromLTRB(112.0, 104.0, 326.0, 152.0),
        ]),
      );
    });

    testWidgets('unconstrained menus show up in the right place in RTL', (WidgetTester tester) async {
      await changeSurfaceSize(tester, const Size(800, 600));
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Material(
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: MenuBar(
                          children: createTestMenus(onPressed: onPressed),
                        ),
                      ),
                    ],
                  ),
                  const Expanded(child: Placeholder()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();
      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();

      expect(find.byType(MenuItemButton), findsNWidgets(6));
      expect(find.byType(SubmenuButton), findsNWidgets(5));
      expect(
        collectMenuItemRects(),
        equals(const <Rect>[
          Rect.fromLTRB(688.0, 0.0, 796.0, 48.0),
          Rect.fromLTRB(580.0, 0.0, 688.0, 48.0),
          Rect.fromLTRB(472.0, 0.0, 580.0, 48.0),
          Rect.fromLTRB(294.0, 0.0, 472.0, 48.0),
          Rect.fromLTRB(474.0, 104.0, 688.0, 152.0),
        ]),
      );
    });

    testWidgets('constrained menus show up in the right place in LTR', (WidgetTester tester) async {
      await changeSurfaceSize(tester, const Size(300, 300));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return Directionality(
                textDirection: TextDirection.ltr,
                child: Material(
                  child: Column(
                    children: <Widget>[
                      MenuBar(
                        children: createTestMenus(onPressed: onPressed),
                      ),
                      const Expanded(child: Placeholder()),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();
      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();

      expect(find.byType(MenuItemButton), findsNWidgets(6));
      expect(find.byType(SubmenuButton), findsNWidgets(5));
      expect(
        collectMenuItemRects(),
        equals(const <Rect>[
          Rect.fromLTRB(4.0, 0.0, 112.0, 48.0),
          Rect.fromLTRB(112.0, 0.0, 220.0, 48.0),
          Rect.fromLTRB(220.0, 0.0, 328.0, 48.0),
          Rect.fromLTRB(328.0, 0.0, 506.0, 48.0),
          Rect.fromLTRB(86.0, 104.0, 300.0, 152.0),
        ]),
      );
    });

    testWidgets('constrained menus show up in the right place in RTL', (WidgetTester tester) async {
      await changeSurfaceSize(tester, const Size(300, 300));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: Material(
                  child: Column(
                    children: <Widget>[
                      MenuBar(
                        children: createTestMenus(onPressed: onPressed),
                      ),
                      const Expanded(child: Placeholder()),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();
      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();

      expect(find.byType(MenuItemButton), findsNWidgets(6));
      expect(find.byType(SubmenuButton), findsNWidgets(5));
      expect(
        collectMenuItemRects(),
        equals(const <Rect>[
          Rect.fromLTRB(188.0, 0.0, 296.0, 48.0),
          Rect.fromLTRB(80.0, 0.0, 188.0, 48.0),
          Rect.fromLTRB(-28.0, 0.0, 80.0, 48.0),
          Rect.fromLTRB(-206.0, 0.0, -28.0, 48.0),
          Rect.fromLTRB(0.0, 104.0, 214.0, 152.0)
        ]),
      );
    });

    testWidgets('constrained menus show up in the right place with offset in LTR', (WidgetTester tester) async {
      await changeSurfaceSize(tester, const Size(800, 600));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return Directionality(
                textDirection: TextDirection.ltr,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: MenuAnchor(
                    menuChildren: const <Widget> [
                      SubmenuButton(
                        alignmentOffset: Offset(10, 0),
                        menuChildren: <Widget> [
                          SubmenuButton(
                            menuChildren: <Widget> [
                              SubmenuButton(
                                alignmentOffset: Offset(10, 0),
                                menuChildren: <Widget> [
                                  SubmenuButton(
                                    menuChildren: <Widget> [
                                    ],
                                    child: Text('SubMenuButton4'),
                                  ),
                                ],
                                child: Text('SubMenuButton3'),
                              ),
                            ],
                            child: Text('SubMenuButton2'),
                          ),
                        ],
                        child: Text('SubMenuButton1'),
                      ),
                    ],
                    builder: (BuildContext context, MenuController controller, Widget? child) {
                      return FilledButton(
                        onPressed: () {
                          if (controller.isOpen) {
                            controller.close();
                          } else {
                            controller.open();
                          }
                        },
                        child: const Text('Tap me'),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Tap me'));
      await tester.pump();
      await tester.tap(find.text('SubMenuButton1'));
      await tester.pump();
      await tester.tap(find.text('SubMenuButton2'));
      await tester.pump();
      await tester.tap(find.text('SubMenuButton3'));
      await tester.pump();

      expect(find.byType(SubmenuButton), findsNWidgets(4));
      expect(
        collectSubmenuRects(),
        equals(const <Rect>[
          Rect.fromLTRB(0.0, 48.0, 256.0, 112.0),
          Rect.fromLTRB(266.0, 48.0, 522.0, 112.0),
          Rect.fromLTRB(522.0, 48.0, 778.0, 112.0),
          Rect.fromLTRB(256.0, 48.0, 512.0, 112.0),
        ]),
      );
    });

    testWidgets('constrained menus show up in the right place with offset in RTL', (WidgetTester tester) async {
      await changeSurfaceSize(tester, const Size(800, 600));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: Align(
                  alignment: Alignment.topRight,
                  child: MenuAnchor(
                    menuChildren: const <Widget> [
                      SubmenuButton(
                        alignmentOffset: Offset(10, 0),
                        menuChildren: <Widget> [
                          SubmenuButton(
                            menuChildren: <Widget> [
                              SubmenuButton(
                                alignmentOffset: Offset(10, 0),
                                menuChildren: <Widget> [
                                  SubmenuButton(
                                    menuChildren: <Widget> [
                                    ],
                                    child: Text('SubMenuButton4'),
                                  ),
                                ],
                                child: Text('SubMenuButton3'),
                              ),
                            ],
                            child: Text('SubMenuButton2'),
                          ),
                        ],
                        child: Text('SubMenuButton1'),
                      ),
                    ],
                    builder: (BuildContext context, MenuController controller, Widget? child) {
                      return FilledButton(
                        onPressed: () {
                          if (controller.isOpen) {
                            controller.close();
                          } else {
                            controller.open();
                          }
                        },
                        child: const Text('Tap me'),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Tap me'));
      await tester.pump();
      await tester.tap(find.text('SubMenuButton1'));
      await tester.pump();
      await tester.tap(find.text('SubMenuButton2'));
      await tester.pump();
      await tester.tap(find.text('SubMenuButton3'));
      await tester.pump();

      expect(find.byType(SubmenuButton), findsNWidgets(4));
      expect(
        collectSubmenuRects(),
        equals(const <Rect>[
          Rect.fromLTRB(544.0, 48.0, 800.0, 112.0),
          Rect.fromLTRB(278.0, 48.0, 534.0, 112.0),
          Rect.fromLTRB(22.0, 48.0, 278.0, 112.0),
          Rect.fromLTRB(288.0, 48.0, 544.0, 112.0),
        ]),
      );
    });

    Future<void> buildDensityPaddingApp(WidgetTester tester, {
      required TextDirection textDirection,
      VisualDensity visualDensity = VisualDensity.standard,
      EdgeInsetsGeometry? menuPadding,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(visualDensity: visualDensity),
          home: Directionality(
            textDirection: textDirection,
            child: Material(
              child: Column(
                children: <Widget>[
                  MenuBar(
                    style: menuPadding != null
                      ? MenuStyle(padding: MaterialStatePropertyAll<EdgeInsetsGeometry>(menuPadding))
                      : null,
                    children: createTestMenus(onPressed: onPressed),
                  ),
                  const Expanded(child: Placeholder()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();
      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();
    }

    testWidgets('submenus account for density in LTR', (WidgetTester tester) async {
      await buildDensityPaddingApp(
        tester,
        textDirection: TextDirection.ltr,
      );
      expect(
        collectSubmenuRects(),
        equals(const <Rect>[
          Rect.fromLTRB(145.0, 0.0, 655.0, 48.0),
          Rect.fromLTRB(257.0, 48.0, 471.0, 208.0),
          Rect.fromLTRB(471.0, 96.0, 719.0, 304.0),
        ]),
      );
    });

    testWidgets('submenus account for menu density in RTL', (WidgetTester tester) async {
      await buildDensityPaddingApp(
        tester,
        textDirection: TextDirection.rtl,
      );
      expect(
        collectSubmenuRects(),
        equals(const <Rect>[
          Rect.fromLTRB(145.0, 0.0, 655.0, 48.0),
          Rect.fromLTRB(329.0, 48.0, 543.0, 208.0),
          Rect.fromLTRB(81.0, 96.0, 329.0, 304.0),
        ]),
      );
    });

    testWidgets('submenus account for compact menu density in LTR', (WidgetTester tester) async {
      await buildDensityPaddingApp(
        tester,
        visualDensity: VisualDensity.compact,
        textDirection: TextDirection.ltr,
      );
      expect(
        collectSubmenuRects(),
        equals(const <Rect>[
          Rect.fromLTRB(161.0, 0.0, 639.0, 40.0),
          Rect.fromLTRB(265.0, 40.0, 467.0, 160.0),
          Rect.fromLTRB(467.0, 72.0, 707.0, 232.0),
        ]),
      );
    });

    testWidgets('submenus account for compact menu density in RTL', (WidgetTester tester) async {
      await buildDensityPaddingApp(
        tester,
        visualDensity: VisualDensity.compact,
        textDirection: TextDirection.rtl,
      );
      expect(
        collectSubmenuRects(),
        equals(const <Rect>[
          Rect.fromLTRB(161.0, 0.0, 639.0, 40.0),
          Rect.fromLTRB(333.0, 40.0, 535.0, 160.0),
          Rect.fromLTRB(93.0, 72.0, 333.0, 232.0),
        ]),
      );
    });

    testWidgets('submenus account for padding in LTR', (WidgetTester tester) async {
      await buildDensityPaddingApp(
        tester,
        menuPadding: const EdgeInsetsDirectional.only(start: 10, end: 11, top: 12, bottom: 13),
        textDirection: TextDirection.ltr,
      );
      expect(
        collectSubmenuRects(),
        equals(const <Rect>[
          Rect.fromLTRB(138.5, 0.0, 661.5, 73.0),
          Rect.fromLTRB(256.5, 60.0, 470.5, 220.0),
          Rect.fromLTRB(470.5, 108.0, 718.5, 316.0),
        ]),
      );
    });

    testWidgets('submenus account for padding in RTL', (WidgetTester tester) async {
      await buildDensityPaddingApp(
        tester,
        menuPadding: const EdgeInsetsDirectional.only(start: 10, end: 11, top: 12, bottom: 13),
        textDirection: TextDirection.rtl,
      );
      expect(
        collectSubmenuRects(),
        equals(const <Rect>[
          Rect.fromLTRB(138.5, 0.0, 661.5, 73.0),
          Rect.fromLTRB(329.5, 60.0, 543.5, 220.0),
          Rect.fromLTRB(81.5, 108.0, 329.5, 316.0),
        ]),
      );
    });
  });

  group('LocalizedShortcutLabeler', () {
    testWidgets('getShortcutLabel returns the right labels', (WidgetTester tester) async {
      String expectedMeta;
      String expectedCtrl;
      String expectedAlt;
      String expectedSeparator;
      String expectedShift;
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          expectedCtrl = 'Ctrl';
          expectedMeta = defaultTargetPlatform == TargetPlatform.windows ? 'Win' : 'Meta';
          expectedAlt = 'Alt';
          expectedShift = 'Shift';
          expectedSeparator = '+';
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          expectedCtrl = '⌃';
          expectedMeta = '⌘';
          expectedAlt = '⌥';
          expectedShift = '⇧';
          expectedSeparator = ' ';
      }

      const SingleActivator allModifiers = SingleActivator(
        LogicalKeyboardKey.keyA,
        control: true,
        meta: true,
        shift: true,
        alt: true,
      );
      final String allExpected = <String>[expectedAlt, expectedCtrl, expectedMeta, expectedShift, 'A'].join(expectedSeparator);
      const CharacterActivator charShortcuts = CharacterActivator('ñ');
      const String charExpected = 'ñ';
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              children: <Widget>[
                SubmenuButton(
                  menuChildren: <Widget>[
                    MenuItemButton(
                      shortcut: allModifiers,
                      child: Text(TestMenu.subMenu10.label),
                    ),
                    MenuItemButton(
                      shortcut: charShortcuts,
                      child: Text(TestMenu.subMenu11.label),
                    ),
                  ],
                  child: Text(TestMenu.mainMenu0.label),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pump();

      expect(find.text(allExpected), findsOneWidget);
      expect(find.text(charExpected), findsOneWidget);
    }, variant: TargetPlatformVariant.all());
  });

  group('CheckboxMenuButton', () {
    testWidgets('tapping toggles checkbox', (WidgetTester tester) async {
      bool? checkBoxValue;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return MenuBar(
                children: <Widget>[
                  SubmenuButton(
                    menuChildren: <Widget>[
                      CheckboxMenuButton(
                        value: checkBoxValue,
                        onChanged: (bool? value) {
                          setState(() {
                            checkBoxValue = value;
                          });
                        },
                        tristate: true,
                        child: const Text('checkbox'),
                      )
                    ],
                    child: const Text('submenu'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(SubmenuButton));
      await tester.pump();

      expect(tester.widget<CheckboxMenuButton>(find.byType(CheckboxMenuButton)).value, null);

      await tester.tap(find.byType(CheckboxMenuButton));
      await tester.pumpAndSettle();
      expect(checkBoxValue, false);

      await tester.tap(find.byType(SubmenuButton));
      await tester.pump();
      await tester.tap(find.byType(CheckboxMenuButton));
      await tester.pumpAndSettle();
      expect(checkBoxValue, true);

      await tester.tap(find.byType(SubmenuButton));
      await tester.pump();
      await tester.tap(find.byType(CheckboxMenuButton));
      await tester.pumpAndSettle();
      expect(checkBoxValue, null);
    });
  });

  group('RadioMenuButton', () {
    testWidgets('tapping toggles radio button', (WidgetTester tester) async {
      int? radioValue;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return MenuBar(
                children: <Widget>[
                  SubmenuButton(
                    menuChildren: <Widget>[
                      RadioMenuButton<int>(
                        value: 0,
                        groupValue: radioValue,
                        onChanged: (int? value) {
                          setState(() {
                            radioValue = value;
                          });
                        },
                        toggleable: true,
                        child: const Text('radio 0'),
                      ),
                      RadioMenuButton<int>(
                        value: 1,
                        groupValue: radioValue,
                        onChanged: (int? value) {
                          setState(() {
                            radioValue = value;
                          });
                        },
                        toggleable: true,
                        child: const Text('radio 1'),
                      )
                    ],
                    child: const Text('submenu'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(SubmenuButton));
      await tester.pump();

      expect(
        tester.widget<RadioMenuButton<int>>(find.byType(RadioMenuButton<int>).first).groupValue,
        null,
      );

      await tester.tap(find.byType(RadioMenuButton<int>).first);
      await tester.pumpAndSettle();
      expect(radioValue, 0);

      await tester.tap(find.byType(SubmenuButton));
      await tester.pump();
      await tester.tap(find.byType(RadioMenuButton<int>).first);
      await tester.pumpAndSettle();
      expect(radioValue, null);

      await tester.tap(find.byType(SubmenuButton));
      await tester.pump();
      await tester.tap(find.byType(RadioMenuButton<int>).last);
      await tester.pumpAndSettle();
      expect(radioValue, 1);
    });
  });

  testWidgets('MenuItemButton respects closeOnActivate property', (WidgetTester tester) async {
    final MenuController controller = MenuController();
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: MenuAnchor(
              controller: controller,
              menuChildren: <Widget> [
                MenuItemButton(
                  onPressed: () {},
                  child: const Text('Button 1'),
                ),
              ],
              builder: (BuildContext context, MenuController controller, Widget? child) {
                return FilledButton(
                  onPressed: () {
                    controller.open();
                  },
                  child: const Text('Tap me'),
                );
              },
            ),
          ),
        ),
      )
    );

    await tester.tap(find.text('Tap me'));
    await tester.pump();
    expect(find.byType(MenuItemButton), findsNWidgets(1));

    // Taps the MenuItemButton which should close the menu
    await tester.tap(find.text('Button 1'));
    await tester.pump();
    expect(find.byType(MenuItemButton), findsNWidgets(0));

    await tester.pumpAndSettle();

    await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Center(
              child: MenuAnchor(
                controller: controller,
                menuChildren: <Widget> [
                  MenuItemButton(
                    closeOnActivate: false,
                    onPressed: () {},
                    child: const Text('Button 1'),
                  ),
                ],
                builder: (BuildContext context, MenuController controller, Widget? child) {
                  return FilledButton(
                    onPressed: () {
                      controller.open();
                    },
                    child: const Text('Tap me'),
                  );
                },
              ),
            ),
          ),
        )
    );

    await tester.tap(find.text('Tap me'));
    await tester.pump();
    expect(find.byType(MenuItemButton), findsNWidgets(1));

    // Taps the MenuItemButton which shouldn't close the menu
    await tester.tap(find.text('Button 1'));
    await tester.pump();
    expect(find.byType(MenuItemButton), findsNWidgets(1));
  });
}

List<Widget> createTestMenus({
  void Function(TestMenu)? onPressed,
  void Function(TestMenu)? onOpen,
  void Function(TestMenu)? onClose,
  Map<TestMenu, MenuSerializableShortcut> shortcuts = const <TestMenu, MenuSerializableShortcut>{},
  bool includeExtraGroups = false,
  bool accelerators = false,
}) {
  Widget submenuButton(
    TestMenu menu, {
    required List<Widget> menuChildren,
  }) {
    return SubmenuButton(
      onOpen: onOpen != null ? () => onOpen(menu) : null,
      onClose: onClose != null ? () => onClose(menu) : null,
      menuChildren: menuChildren,
      child: accelerators ? MenuAcceleratorLabel(menu.acceleratorLabel) : Text(menu.label),
    );
  }

  Widget menuItemButton(
    TestMenu menu, {
    bool enabled = true,
    Widget? leadingIcon,
    Widget? trailingIcon,
    Key? key,
  }) {
    return MenuItemButton(
      key: key,
      onPressed: enabled && onPressed != null ? () => onPressed(menu) : null,
      shortcut: shortcuts[menu],
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      child: accelerators ? MenuAcceleratorLabel(menu.acceleratorLabel) : Text(menu.label),
    );
  }

  final List<Widget> result = <Widget>[
    submenuButton(
      TestMenu.mainMenu0,
      menuChildren: <Widget>[
        menuItemButton(TestMenu.subMenu00, leadingIcon: const Icon(Icons.add)),
        menuItemButton(TestMenu.subMenu01),
        menuItemButton(TestMenu.subMenu02),
      ],
    ),
    submenuButton(
      TestMenu.mainMenu1,
      menuChildren: <Widget>[
        menuItemButton(TestMenu.subMenu10),
        submenuButton(
          TestMenu.subMenu11,
          menuChildren: <Widget>[
            menuItemButton(TestMenu.subSubMenu110, key: UniqueKey()),
            menuItemButton(TestMenu.subSubMenu111),
            menuItemButton(TestMenu.subSubMenu112),
            menuItemButton(TestMenu.subSubMenu113),
          ],
        ),
        menuItemButton(TestMenu.subMenu12),
      ],
    ),
    submenuButton(
      TestMenu.mainMenu2,
      menuChildren: <Widget>[
        menuItemButton(
          TestMenu.subMenu20,
          leadingIcon: const Icon(Icons.ac_unit),
          enabled: false,
        ),
      ],
    ),
    if (includeExtraGroups)
      submenuButton(
        TestMenu.mainMenu3,
        menuChildren: <Widget>[
          menuItemButton(TestMenu.subMenu30, enabled: false),
        ],
      ),
    if (includeExtraGroups)
      submenuButton(
        TestMenu.mainMenu4,
        menuChildren: <Widget>[
          menuItemButton(TestMenu.subMenu40, enabled: false),
          menuItemButton(TestMenu.subMenu41, enabled: false),
          menuItemButton(TestMenu.subMenu42, enabled: false),
        ],
      ),
    submenuButton(TestMenu.mainMenu5, menuChildren: const <Widget>[]),
  ];
  return result;
}

enum TestMenu {
  mainMenu0('&Menu 0'),
  mainMenu1('M&enu &1'),
  mainMenu2('Me&nu 2'),
  mainMenu3('Men&u 3'),
  mainMenu4('Menu &4'),
  mainMenu5('Menu &5 && &6 &'),
  subMenu00('Sub &Menu 0&0'),
  subMenu01('Sub Menu 0&1'),
  subMenu02('Sub Menu 0&2'),
  subMenu10('Sub Menu 1&0'),
  subMenu11('Sub Menu 1&1'),
  subMenu12('Sub Menu 1&2'),
  subMenu20('Sub Menu 2&0'),
  subMenu30('Sub Menu 3&0'),
  subMenu40('Sub Menu 4&0'),
  subMenu41('Sub Menu 4&1'),
  subMenu42('Sub Menu 4&2'),
  subSubMenu110('Sub Sub Menu 11&0'),
  subSubMenu111('Sub Sub Menu 11&1'),
  subSubMenu112('Sub Sub Menu 11&2'),
  subSubMenu113('Sub Sub Menu 11&3');

  const TestMenu(this.acceleratorLabel);
  final String acceleratorLabel;
  // Strip the accelerator markers.
  String get label => MenuAcceleratorLabel.stripAcceleratorMarkers(acceleratorLabel);
  int get acceleratorIndex {
    int index = -1;
    MenuAcceleratorLabel.stripAcceleratorMarkers(acceleratorLabel, setIndex: (int i) => index = i);
    return index;
  }
}
