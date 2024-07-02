// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart'
    show
        ElevatedButton,
        FilledButton,
        InkWell,
        Material,
        MaterialApp,
        MenuButtonThemeData,
        TextButton,
        ThemeData;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  late CupertinoMenuController controller;
  String? focusedMenu;
  final List<TestMenu> selected = <TestMenu>[];
  final List<TestMenu> opened = <TestMenu>[];
  final List<TestMenu> closed = <TestMenu>[];
  Matcher rectEquals(Rect rect) {
    return rectMoreOrLessEquals(rect, epsilon: 0.1);
  }

  // Generic button that opens a menu. Used insead of a TextButton or
  // CupertinoButton to avoid flaky tests in the future.

  // TODO(davidhicks980): Replace with a CupertinoButton if a
  // FocusNode is added, https://github.com/flutter/flutter/issues/144385
  Widget buildAnchor(
    BuildContext context,
    CupertinoMenuController controller,
    Widget? child,
    [void Function(TestMenu menu)? onPressed]
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints.tightFor(width: 56, height: 56),
      child: Material(
        child: InkWell(
          onTap: () {
            if (controller.menuStatus
                case MenuStatus.opened || MenuStatus.opening) {
              controller.close();
            } else {
              controller.open();
            }
            onPressed?.call(TestMenu.anchorButton);
          },
          child: TestMenu.anchorButton.text,
        ),
      ),
    );
  }

  void onPressed(TestMenu item) {
    selected.add(item);
  }

  void onOpen() {
    opened.add(TestMenu.anchorButton);
  }

  void onClose() {
    opened.remove(TestMenu.anchorButton);
    closed.add(TestMenu.anchorButton);
  }

  void handleFocusChange() {
    focusedMenu = (primaryFocus?.debugLabel ?? primaryFocus).toString();
  }

  setUp(() {
    focusedMenu = null;
    selected.clear();
    opened.clear();
    closed.clear();
    controller = CupertinoMenuController();
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

  Finder findMenuPanel() {
    return find.byWidgetPredicate(
        (Widget widget) => widget.runtimeType.toString() == '_MenuPanel');
  }

  Finder findMenuPanelDescendent<T>() {
    return find.descendant(
      of: findMenuPanel(),
      matching: find.byType(T),
    );
  }

  Widget buildTestApp({
    AlignmentGeometry? alignment,
    AlignmentGeometry? menuAlignment,
    Offset alignmentOffset = Offset.zero,
    TextDirection textDirection = TextDirection.ltr,
    bool consumesOutsideTap = false,
    List<Widget>? children,
    void Function(TestMenu item)? onPressed,
    void Function()? onOpen,
    void Function()? onClose,
    CupertinoThemeData theme = const CupertinoThemeData(),

  }) {
    final FocusNode focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    return CupertinoApp(
      home: CupertinoTheme(
          data: theme,
          child: Directionality(
            textDirection: textDirection,
            child:  Stack(
                children: <Widget>[
                  ElevatedButton(
                      onPressed: () {
                        onPressed?.call(TestMenu.outsideButton);
                      },
                      child: Text(TestMenu.outsideButton.label),),
                  Positioned(
                    top: 200,
                    left: 350,
                    child: CupertinoMenuAnchor(
                      childFocusNode: focusNode,
                      controller: controller,
                      alignmentOffset: alignmentOffset,
                      alignment: alignment,
                      menuAlignment: menuAlignment,
                      consumeOutsideTap: consumesOutsideTap,
                      onOpen: onOpen,
                      onClose: onClose,
                      menuChildren:
                          children ?? createTestMenus(onPressed: onPressed),
                      builder: (BuildContext context, CupertinoMenuController controller, Widget? widget) =>buildAnchor(context, controller, widget, onPressed),
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }

  T findMenuPanelWidget<T extends Widget>(WidgetTester tester) {
    return tester.firstWidget<T>(
      find.descendant(
        of: findMenuPanel(),
        matching: find.byType(T),
      ),
    );
  }

  CupertinoApp buildApp(
    Widget child,
  ) {
    return CupertinoApp(
      home: Stack(children: <Widget>[
        Align(alignment: AlignmentDirectional.topStart, child: child)
      ]),
    );
  }

  group('Interaction', () {
    testWidgets('controller open and close', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildApp(
          CupertinoMenuAnchor(
            builder: buildAnchor,
            controller: controller,
            menuChildren: <Widget>[
              CupertinoMenuItem(
                child: TestMenu.item1.text,
              ),
              CupertinoMenuItem(
                leading: const Icon(CupertinoIcons.ant),
                trailing: const Icon(CupertinoIcons.mail),
                child: TestMenu.item2.text,
              ),
              CupertinoMenuItem(
                child: TestMenu.item4.text,
              ),
            ],
          ),
        ),
      );

      // Create the menu. The menu is closed, so no menu items should be found in
      // the widget tree.
      await tester.pumpAndSettle();
      expect(controller.menuStatus, MenuStatus.closed);
      expect(TestMenu.item1.findText, findsNothing);
      expect(controller.isOpen, isFalse);

      // Open the menu.
      controller.open();
      await tester.pump();

      // The menu is opening => MenuStatus.opening.
      expect(controller.menuStatus, MenuStatus.opening);
      expect(controller.isOpen, isTrue);
      expect(TestMenu.item1.findText, findsOneWidget);

      // After 100 ms, the menu should still be animating open.
      await tester.pump(const Duration(milliseconds: 100));
      expect(controller.menuStatus, MenuStatus.opening);
      expect(controller.isOpen, isTrue);
      expect(TestMenu.item1.findText, findsOneWidget);

      // Interrupt the opening animation by closing the menu.
      controller.close();
      await tester.pump();

      // The menu is closing => MenuStatus.closing.
      expect(controller.menuStatus, MenuStatus.closing);
      expect(controller.isOpen, isTrue);
      expect(TestMenu.item1.findText, findsOneWidget);

      // Open the menu again.
      controller.open();
      await tester.pump();

      // The menu is animating open => MenuStatus.opening.
      expect(controller.menuStatus, MenuStatus.opening);
      expect(controller.isOpen, isTrue);
      expect(TestMenu.item1.findText, findsOneWidget);

      await tester.pumpAndSettle();

      // The menu has finished opening, so it should report it's animation
      // status as MenuStatus.open.
      expect(controller.menuStatus, MenuStatus.opened);
      expect(controller.isOpen, isTrue);
      expect(TestMenu.item1.findText, findsOneWidget);

      // Close the menu.
      controller.close();
      await tester.pump();

      expect(controller.menuStatus, MenuStatus.closing);
      expect(controller.isOpen, isTrue);
      expect(TestMenu.item1.findText, findsOneWidget);

      // After 100 ms, the menu should still be closing.
      await tester.pump(const Duration(milliseconds: 100));
      expect(controller.menuStatus, MenuStatus.closing);
      expect(controller.isOpen, isTrue);
      expect(TestMenu.item1.findText, findsOneWidget);

      // Interrupt the closing animation by opening the menu.
      controller.open();
      await tester.pump();

      // The menu is animating open => MenuStatus.opening.
      expect(controller.menuStatus, MenuStatus.opening);
      expect(controller.isOpen, isTrue);
      expect(TestMenu.item1.findText, findsOneWidget);

      // Close the menu again.
      controller.close();
      await tester.pump();

      // The menu is closing => MenuStatus.closing.
      expect(controller.menuStatus, MenuStatus.closing);
      expect(controller.isOpen, isTrue);
      expect(TestMenu.item1.findText, findsOneWidget);

      await tester.pumpAndSettle();

      // The menu has closed => MenuStatus.closed.
      expect(controller.menuStatus, MenuStatus.closed);
      expect(controller.isOpen, isFalse);
      expect(TestMenu.item1.findText, findsNothing);
    });
    testWidgets('tap open and close', (WidgetTester tester) async {
      // Create the menu.
      await tester.pumpWidget(
        buildApp(
          CupertinoMenuAnchor(
            builder: buildAnchor,
            controller: controller,
            menuChildren: <Widget>[
              CupertinoMenuItem(
                child: TestMenu.item1.text,
              ),
              CupertinoMenuItem(
                leading: const Icon(CupertinoIcons.ant),
                trailing: const Icon(CupertinoIcons.mail),
                child: TestMenu.item2.text,
              ),
              CupertinoMenuItem(
                child: TestMenu.item4.text,
              ),
            ],
          ),
        ),
      );

      // The menu is closed, so no menu items should be found in
      // the widget tree.
      expect(controller.menuStatus, MenuStatus.closed);
      expect(TestMenu.item1.findText, findsNothing);
      expect(controller.isOpen, isFalse);

      // Open the menu.
      await tester.tap(find.byType(CupertinoMenuAnchor));
      await tester.pump();

      // The menu is opening => MenuStatus.opening.
      expect(controller.menuStatus, MenuStatus.opening);
      expect(controller.isOpen, isTrue);
      expect(TestMenu.item1.findText, findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));

      // After 100 ms, the menu should still be animating open.
      expect(controller.menuStatus, MenuStatus.opening);
      expect(controller.isOpen, isTrue);
      expect(TestMenu.item1.findText, findsOneWidget);

      // Interrupt the opening animation by closing the menu.
      await tester.tap(find.byType(CupertinoMenuAnchor));
      await tester.pump();

      // The menu is closing => MenuStatus.closing.
      expect(controller.menuStatus, MenuStatus.closing);
      expect(controller.isOpen, isTrue);
      expect(TestMenu.item1.findText, findsOneWidget);

      // Open the menu again.
      await tester.tap(find.byType(CupertinoMenuAnchor));
      await tester.pump();

      // The menu is animating open => MenuStatus.opening.
      expect(controller.menuStatus, MenuStatus.opening);
      expect(controller.isOpen, isTrue);
      expect(TestMenu.item1.findText, findsOneWidget);

      await tester.pumpAndSettle();

      // The menu has finished opening, so it should report it's animation
      // status as MenuStatus.open.
      expect(controller.menuStatus, MenuStatus.opened);
      expect(controller.isOpen, isTrue);
      expect(TestMenu.item1.findText, findsOneWidget);

      // Close the menu.
      await tester.tap(find.byType(CupertinoMenuAnchor));
      await tester.pump();

      expect(controller.menuStatus, MenuStatus.closing);
      expect(controller.isOpen, isTrue);
      expect(TestMenu.item1.findText, findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));

      // After 100 ms, the menu should still be closing.
      expect(controller.menuStatus, MenuStatus.closing);
      expect(controller.isOpen, isTrue);
      expect(TestMenu.item1.findText, findsOneWidget);

      // Interrupt the closing animation by opening the menu.
      await tester.tap(find.byType(CupertinoMenuAnchor));
      await tester.pump();

      // The menu is animating open => MenuStatus.opening.
      expect(controller.menuStatus, MenuStatus.opening);
      expect(controller.isOpen, isTrue);
      expect(TestMenu.item1.findText, findsOneWidget);

      // Close the menu again.
      await tester.tap(find.byType(CupertinoMenuAnchor));
      await tester.pump();

      // The menu is closing => MenuStatus.closing.
      expect(controller.menuStatus, MenuStatus.closing);
      expect(controller.isOpen, isTrue);
      expect(TestMenu.item1.findText, findsOneWidget);

      await tester.pumpAndSettle();

      // The menu has closed => MenuStatus.closed.
      expect(controller.menuStatus, MenuStatus.closed);
      expect(controller.isOpen, isFalse);
      expect(TestMenu.item1.findText, findsNothing);
    });

    testWidgets('close when Navigator.pop() is called',
        (WidgetTester tester) async {
      final CupertinoMenuController controller = CupertinoMenuController();
      final GlobalKey<State<StatefulWidget>> menuItemGK = GlobalKey();
      await tester.pumpWidget(
        buildApp(
          CupertinoMenuAnchor(
            controller: controller,
            menuChildren: <Widget>[
              CupertinoMenuItem(
                key: menuItemGK,
                child: TestMenu.item1.text,
              ),
              CupertinoMenuItem(
                leading: const Icon(CupertinoIcons.ant),
                trailing: const Icon(CupertinoIcons.mail),
                child: TestMenu.item2.text,
              ),
              CupertinoMenuItem(
                child: TestMenu.item4.text,
              ),
            ],
            child: TestMenu.anchorButton.text,
          ),
        ),
      );
      controller.open();
      await tester.pumpAndSettle();

      expect(TestMenu.item1.findText, findsOneWidget);
      expect(controller.isOpen, isTrue);

      Navigator.pop(menuItemGK.currentContext!);
      await tester.pumpAndSettle();

      expect(TestMenu.item1.findText, findsNothing);
    });
    testWidgets('moving a controller to a new instance works',
        (WidgetTester tester) async {
      final CupertinoMenuController controller = CupertinoMenuController();
      await tester.pumpWidget(
        CupertinoApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: CupertinoMenuAnchor(
                key: UniqueKey(),
                controller: controller,
                menuChildren: <CupertinoMenuItem>[
                  CupertinoMenuItem(
                    child: TestMenu.item0.text,
                    onPressed: () {},
                  )
                ]),
          ),
        ),
      );

      // Open a menu initially.
      controller.open();
      await tester.pumpAndSettle();

      // Now pump a new menu with a different UniqueKey to dispose of the opened
      // menu's node, but keep the existing controller.
      await tester.pumpWidget(
        CupertinoApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: CupertinoMenuAnchor(
                key: UniqueKey(),
                controller: controller,
                menuChildren: <CupertinoMenuItem>[
                  CupertinoMenuItem(
                    child: TestMenu.item0.text,
                    onPressed: () {},
                  )
                ]),
          ),
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('menu closes on ancestor scroll', (WidgetTester tester) async {
      final ScrollController scrollController = ScrollController();
      addTearDown(scrollController.dispose);
      bool opened = false;
      bool closed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: SingleChildScrollView(
              controller: scrollController,
              child: Container(
                height: 1000,
                alignment: Alignment.center,
                child: CupertinoMenuAnchor(
                  builder: buildAnchor,
                  onOpen: () {
                    opened = true;
                    closed = false;
                  },
                  onClose: () {
                    closed = true;
                    opened = false;
                  },
                  menuChildren: createTestMenus(
                    onPressed: onPressed,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CupertinoMenuAnchor));
      await tester.pump();

      expect(opened, isTrue);
      expect(closed, isFalse);

      scrollController.jumpTo(1000);
      await tester.pumpAndSettle();

      expect(opened, isFalse);
      expect(closed, isTrue);
    });

    testWidgets('menu does not close on root menu internal scroll',
        (WidgetTester tester) async {
      final ScrollController scrollController = ScrollController();
      addTearDown(scrollController.dispose);
      bool rootOpened = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            menuButtonTheme: MenuButtonThemeData(
              // Increase menu items height to make root menu scrollable.
              style:
                  TextButton.styleFrom(minimumSize: const Size.fromHeight(200)),
            ),
          ),
          home: Material(
            child: SingleChildScrollView(
              controller: scrollController,
              child: Container(
                height: 1000,
                alignment: Alignment.topLeft,
                child: CupertinoMenuAnchor(
                  onOpen: () {
                    onOpen();
                    rootOpened = true;
                  },
                  onClose: () {
                    onClose();
                    rootOpened = false;
                  },
                  controller: controller,
                  alignmentOffset: const Offset(0, 10),
                  builder: (BuildContext context,
                      CupertinoMenuController controller, Widget? child) {
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
                  menuChildren: createTestMenus(
                    onPressed: onPressed,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show menu'));
      await tester.pumpAndSettle();

      expect(rootOpened, true);

      // Hover the first item.
      final TestPointer pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(
          pointer.hover(tester.getCenter(find.text(TestMenu.item0.label))));
      await tester.pump();

      expect(opened, isNotEmpty);

      // Menus do not close on internal scroll.
      await tester.sendEventToBinding(pointer.scroll(const Offset(0.0, 30.0)));
      await tester.pump();

      expect(rootOpened, true);
      expect(closed, isEmpty);

      // Menus close on external scroll.
      scrollController.jumpTo(1000);
      await tester.pumpAndSettle();
      await tester.pump();

      expect(rootOpened, false);
      expect(closed, isNotEmpty);
    });

    testWidgets('menu closes on view size change', (WidgetTester tester) async {
      final ScrollController scrollController = ScrollController();
      addTearDown(scrollController.dispose);
      final MediaQueryData mediaQueryData =
          MediaQueryData.fromView(tester.view);

      bool opened = false;
      bool closed = false;

      Widget build(Size size) {
        return CupertinoApp(
          home: MediaQuery(
            data: mediaQueryData.copyWith(size: size),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Container(
                height: 1000,
                alignment: Alignment.center,
                child: CupertinoMenuAnchor(
                  builder: buildAnchor,
                  onOpen: () {
                    opened = true;
                    closed = false;
                  },
                  onClose: () {
                    opened = false;
                    closed = true;
                  },
                  controller: controller,
                  menuChildren: createTestMenus(
                    onPressed: onPressed,
                  ),
                ),
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(build(mediaQueryData.size));
      await tester.tap(find.byType(CupertinoMenuAnchor));
      await tester.pump();

      expect(opened, isTrue);
      expect(closed, isFalse);

      const Size smallSize = Size(200, 200);
      await changeSurfaceSize(tester, smallSize);
      await tester.pumpWidget(build(smallSize));

      expect(opened, isFalse);
      expect(closed, isTrue);
    });


    testWidgets('MediaQuery changes do not throw', (WidgetTester tester) async {
      final AnimationController animationController = AnimationController(
        vsync: tester,
        duration: const Duration(
          milliseconds: 1000,
        ),
      );
      addTearDown(tester.view.reset);
      addTearDown(animationController.dispose);
      await tester.pumpWidget(CupertinoApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: AnimatedBuilder(
            animation: animationController,
            builder: (BuildContext context, Widget? child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  padding: const EdgeInsets.all(8) * animationController.value,
                  textScaler: TextScaler.linear(1 + animationController.value),
                  size: MediaQuery.of(context).size *
                      (1 + animationController.value),
                ),
                child: CupertinoMenuAnchor(
                  builder: buildAnchor,
                  onOpen: animationController.forward,
                  onClose: animationController.reverse,
                  menuChildren: createTestMenus(onPressed: (_) {}),
                ),
              );
            },
          ),
        ),
      ));

      final Finder anchor = find.byType(CupertinoMenuAnchor).first;

      expect(anchor, findsOneWidget);

      await tester.tap(anchor);
      await tester.pump();

      expect(TestMenu.item0.findText, findsOneWidget);

      tester.view.physicalSize = const Size(700.0, 700.0);
      await tester.pump();
      tester.view.physicalSize = const Size(250.0, 500.0);
      await tester.pumpAndSettle();
      await tester.tap(anchor);
      await tester.pump();
      tester.view.physicalSize = const Size(500.0, 100.0);
      await tester.pump();
      tester.view.physicalSize = const Size(250.0, 500.0);
      await tester.pumpAndSettle();

      // Go without throw.
    });

    testWidgets('panning scales the menu', (WidgetTester tester) async {
      await changeSurfaceSize(tester, const Size(1000, 1000));
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoMenuAnchor(
              builder: buildAnchor,
              menuChildren: <Widget>[
                const CupertinoLargeMenuDivider(),
                CupertinoMenuItem(
                  onPressed: () {},
                  child: TestMenu.item0.text,
                ),
              ],
            ),
          ),
        ),
      );
      final TestGesture gesture = await tester.createGesture(pointer: 1);

      addTearDown(gesture.removePointer);

      await tester.tap(find.byType(CupertinoMenuAnchor));
      await tester.pumpAndSettle();

      final Offset startPosition = tester.getCenter(find.byType(CupertinoLargeMenuDivider));
      await gesture.down(startPosition);
      await tester.pump();

      final Rect rect = tester
          .getRect(TestMenu.anchorButton.findAncestor<Material>())
          .expandToInclude(
            tester.getRect(
              find.descendant(
                    of: findMenuPanel(),
                    matching: find.byType(CustomScrollView),
                  )
                  .first,
            ),
          );

      double getScale() => findMenuPanelWidget<ScaleTransition>(tester).scale.value;

      // Check that all corners of the menu are not scaled.
      await gesture.moveTo(rect.topLeft);
      await tester.pump();

      expect(getScale(), moreOrLessEquals(1.0, epsilon: 0.01));

      await gesture.moveTo(rect.topRight);
      await tester.pump();

      expect(getScale(), moreOrLessEquals(1.0, epsilon: 0.01));

      await gesture.moveTo(rect.bottomLeft);
      await tester.pump();

      expect(getScale(), moreOrLessEquals(1.0, epsilon: 0.01));

      await gesture.moveTo(rect.bottomRight);
      await tester.pump();

      expect(getScale(), moreOrLessEquals(1.0, epsilon: 0.01));

      await gesture.moveTo(rect.topLeft - const Offset(50, 50));
      await tester.pump();

      final double topLeftScale = getScale();

      expect(topLeftScale, lessThan(1.0));
      expect(topLeftScale, greaterThan(0.7));

      await gesture.moveTo(rect.bottomRight + const Offset(50, 50));
      await tester.pump();

      // Check that scale is roughly the same around the menu.
      expect(getScale(), moreOrLessEquals(topLeftScale, epsilon: 0.05));

      await gesture.moveTo(rect.topLeft - const Offset(200, 200));
      await tester.pump();

      // Check that the minimum scale is 0.7
      expect(getScale(), 0.7);

      await gesture.moveTo(rect.bottomRight + const Offset(200, 200));
      await tester.pump();

      expect(getScale(), 0.7);

      await gesture.up();
    });
    testWidgets('pan can be disabled', (WidgetTester tester) async {
      await changeSurfaceSize(tester, const Size(1000, 1000));
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: CupertinoMenuAnchor(
              builder: buildAnchor,
              controller: controller,
              enablePan: false,
              menuChildren: <Widget>[
                const CupertinoLargeMenuDivider(),
                CupertinoMenuItem(
                  onPressed: () {},
                  pressedColor: const Color.fromRGBO(255, 0, 0, 1),
                  hoveredColor: const Color.fromRGBO(0, 255, 0, 1),
                  panActivationDelay: const Duration(milliseconds: 50),
                  child: TestMenu.item0.text,
                ),
              ],
            ),
          ),
        ),
      );
      final TestGesture gesture = await tester.createGesture(pointer: 1);
      addTearDown(gesture.removePointer);

      await tester.tap(find.byType(CupertinoMenuAnchor));
      await tester.pumpAndSettle();

      final Offset startPosition = tester.getCenter(find.byType(CupertinoLargeMenuDivider));
      await gesture.down(startPosition);
      await tester.pump();

      final Rect rect = tester.getRect(
        find.descendant(
          of: findMenuPanel(),
          matching: find.byType(CustomScrollView),
        )
        .first,
      );

      double getScale() => findMenuPanelWidget<ScaleTransition>(tester).scale.value;
      await gesture.moveTo(rect.topLeft - const Offset(200, 200));
      await tester.pump();

      expect(getScale(), 1.0);

      await gesture.moveTo(rect.bottomRight + const Offset(200, 200));
      await tester.pump();

      expect(getScale(), 1.0);

      await gesture.moveTo(tester.getCenter(TestMenu.item0.findMenuItem));
      await tester.pump(const Duration(milliseconds: 500));

      // Pan is disabled, so panActivationDelay should not be triggered.
      expect(controller.menuStatus, MenuStatus.opened);

      await gesture.up();

    });

    testWidgets('DismissMenuAction closes the menu',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          onPressed: onPressed,
          onOpen: onOpen,
          onClose: onClose,
        ),
      );

      controller.open();
      await tester.pumpAndSettle();

      expect(controller.isOpen, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(controller.isOpen, isFalse);
    });

    testWidgets('Menus close and consume tap when consumesOutsideTap is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
            consumesOutsideTap: true,
            onPressed: onPressed,
            onOpen: onOpen,
            onClose: onClose),
      );

      expect(opened, isEmpty);
      expect(closed, isEmpty);

      // Doesn't consume tap when the menu is closed.
      await tester.tap(find.text(TestMenu.outsideButton.label));
      await tester.pump();

      expect(selected, equals(<TestMenu>[TestMenu.outsideButton]));
      selected.clear();

      await tester.tap(find.text(TestMenu.anchorButton.label));
      await tester.pump();

      expect(opened, equals(<TestMenu>[TestMenu.anchorButton]));
      expect(closed, isEmpty);
      expect(selected, equals(<TestMenu>[TestMenu.anchorButton]));
      opened.clear();
      closed.clear();
      selected.clear();

      // The menu is open until it animates closed.
      await tester.tap(find.text(TestMenu.outsideButton.label));
      await tester.pumpAndSettle();

      expect(opened, isEmpty);
      expect(closed, equals(<TestMenu>[TestMenu.anchorButton]));
      // When the menu is open, don't expect the outside button to be selected:
      // it's supposed to consume the key down.
      expect(selected, isEmpty);
      selected.clear();
      opened.clear();
      closed.clear();
    });

    testWidgets(
        'Menus close and do not consume tap when consumesOutsideTap is false',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          onPressed: onPressed,
          onOpen: onOpen,
          onClose: onClose,
        ),
      );

      expect(opened, isEmpty);
      expect(closed, isEmpty);

      await tester.tap(find.text(TestMenu.outsideButton.label));
      await tester.pump();

      // Doesn't consume tap when the menu is closed.
      expect(selected, equals(<TestMenu>[TestMenu.outsideButton]));

      selected.clear();

      await tester.tap(find.text(TestMenu.anchorButton.label));
      await tester.pump();

      expect(opened, equals(<TestMenu>[TestMenu.anchorButton]));
      expect(closed, isEmpty);
      expect(selected, equals(<TestMenu>[TestMenu.anchorButton]));

      opened.clear();
      closed.clear();
      selected.clear();

      // The menu is open until it animates closed.
      await tester.tap(find.text(TestMenu.outsideButton.label));
      await tester.pumpAndSettle();


      // Because consumesOutsideTap is false, outsideButton is expected to
      // receive its tap.
      expect(opened, isEmpty);
      expect(closed, equals(<TestMenu>[TestMenu.anchorButton]));
      expect(selected, equals(<TestMenu>[TestMenu.outsideButton]));

      selected.clear();
      opened.clear();
      closed.clear();
    });

    testWidgets('onOpen and onClose work', (WidgetTester tester) async {
      bool opened = false;
      bool closed = true;
      CupertinoApp builder() {
        return CupertinoApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: CupertinoMenuAnchor(
              controller: controller,
              builder: buildAnchor,
              onOpen: () {
                opened = true;
                closed = false;
              },
              onClose: () {
                closed = true;
                opened = false;
              },
              menuChildren: createTestMenus(onPressed: (TestMenu menu) {}),
            ),
          ),
        );
      }

      await tester.pumpWidget(builder());
      await tester.tap(find.byType(CupertinoMenuAnchor));
      await tester.pumpFrames(builder(), const Duration(milliseconds: 50));

      expect(opened, isTrue);

      await tester.tap(find.text(TestMenu.item1.label));
      await tester.pump();

      expect(opened, isTrue);

      // Because a simulation is used, an exact number of frames is not guaranteed.
      await tester.pumpAndSettle();

      expect(closed, isTrue);
      expect(find.text(TestMenu.item1.label), findsNothing);

      await tester.tap(find.byType(CupertinoMenuAnchor));
      await tester.pumpAndSettle();

      expect(opened, isTrue);
    });

    testWidgets('diagnostics', (WidgetTester tester) async {
      const CupertinoMenuItem item = CupertinoMenuItem(
        child: Text('Child'),
      );
      final CupertinoMenuAnchor menuAnchor = CupertinoMenuAnchor(
        controller: controller,
        menuChildren: const <Widget>[item],
        consumeOutsideTap: true,
        alignmentOffset: const Offset(10, 10),
        child: const Text('Sample Text'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: menuAnchor,
          ),
        ),
      );

      controller.open();
      await tester.pumpAndSettle();

      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
      menuAnchor.debugFillProperties(builder);
      final List<String> description = builder.properties
          .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
          .map((DiagnosticsNode node) => node.toString())
          .toList();

      expect(
          description,
          equalsIgnoringHashCodes(<String>[
            'AUTO-CLOSE',
            'focusNode: null',
            'clipBehavior: antiAlias',
            'alignmentOffset: Offset(10.0, 10.0)',
            'child: Text("Sample Text")',
          ]));
    });

    testWidgets('keyboard tab traversal works', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Column(
            children: <Widget>[
              CupertinoMenuAnchor(
                controller: controller,
                builder: buildAnchor,
                menuChildren: createTestMenus(
                  onPressed: onPressed,
                ),
              ),
              const Expanded(child: Placeholder()),
            ],
          ),
        ),
      );

      listenForFocusChanges();
      // Have to open a menu initially to start things going.
      // pumpAndSettle is not used here because we should be able to
      // traverse the menu before it is fully open.
      await tester.tap(find.byType(CupertinoMenuAnchor));
      await tester.pump();

      // First focus is set when the menu is opened.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(focusedMenu, equals(TestMenu.item0.debugFocusLabel));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(focusedMenu, equals(TestMenu.item1.debugFocusLabel));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(focusedMenu, equals(TestMenu.item2.debugFocusLabel));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(focusedMenu, equals(TestMenu.item3.debugFocusLabel));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(focusedMenu, equals(TestMenu.item4.debugFocusLabel));

      /* 5 is disabled */

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(focusedMenu, equals(TestMenu.item6.debugFocusLabel));

      // Should cycle back to the beginning.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(focusedMenu, equals(TestMenu.item0.debugFocusLabel));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);

      expect(focusedMenu, equals(TestMenu.item6.debugFocusLabel));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(focusedMenu, equals(TestMenu.item4.debugFocusLabel));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(focusedMenu, equals(TestMenu.item3.debugFocusLabel));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(focusedMenu, equals(TestMenu.item2.debugFocusLabel));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(focusedMenu, equals(TestMenu.item1.debugFocusLabel));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(focusedMenu, equals(TestMenu.item0.debugFocusLabel));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(focusedMenu, equals(TestMenu.item6.debugFocusLabel));
    });

    testWidgets('keyboard directional LTR traversal works',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Align(
            alignment: AlignmentDirectional.topStart,
            child: CupertinoMenuAnchor(
              builder: buildAnchor,
              menuChildren: createTestMenus(
                onPressed: onPressed,
              ),
            ),
          ),
        ),
      );

      listenForFocusChanges();

      // Have to open a menu initially to start things going.
      await tester.tap(find.byType(CupertinoMenuAnchor));
      await tester.pumpAndSettle();

      // TODO(davidhicks980): On web, pressing the down arrow key does not
      // focus the first item. https://github.com/flutter/flutter/issues/147770
      if (isBrowser) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      } else {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      }

      expect(focusedMenu, equals(TestMenu.item0.debugFocusLabel));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals(TestMenu.item1.debugFocusLabel));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals(TestMenu.item2.debugFocusLabel));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals(TestMenu.item3.debugFocusLabel));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals(TestMenu.item4.debugFocusLabel));

      /* 5 is disabled */

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals(TestMenu.item6.debugFocusLabel));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals(TestMenu.item6.debugFocusLabel));
    });

    testWidgets('keyboard directional RTL traversal works',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: CupertinoMenuAnchor(
                builder: buildAnchor,
                menuChildren: createTestMenus(
                  onPressed: onPressed,
                ),
              ),
            ),
          ),
        ),
      );

      listenForFocusChanges();

      // Have to open a menu initially to start things going.
      await tester.tap(find.byType(CupertinoMenuAnchor));
      await tester.pumpAndSettle();


      // https://github.com/flutter/flutter/issues/147770
      if (isBrowser) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      } else {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      }

      expect(focusedMenu, equals(TestMenu.item0.debugFocusLabel));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals(TestMenu.item1.debugFocusLabel));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals(TestMenu.item2.debugFocusLabel));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals(TestMenu.item3.debugFocusLabel));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals(TestMenu.item4.debugFocusLabel));

      /* 5 is disabled */

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals(TestMenu.item6.debugFocusLabel));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equals(TestMenu.item6.debugFocusLabel));
    });


    testWidgets('focus is returned to previous focus before invoking onPressed',
        (WidgetTester tester) async {
      final FocusNode buttonFocus = FocusNode(debugLabel: 'Button Focus');
      addTearDown(buttonFocus.dispose);
      FocusNode? focusInOnPressed;

      void onMenuSelected() {
        focusInOnPressed = FocusManager.instance.primaryFocus;
      }

      await tester.pumpWidget(
        buildApp(
          Column(
            children: <Widget>[
              CupertinoMenuAnchor(
                builder: buildAnchor,
                menuChildren: <Widget>[
                  CupertinoMenuItem(
                    onPressed: onMenuSelected,
                    child: TestMenu.item1.text,
                  ),
                ],
              ),
              ElevatedButton(
                autofocus: true,
                onPressed: () {},
                focusNode: buttonFocus,
                child: TestMenu.outsideButton.text,
              ),
            ],
          ),
        ),
      );

      expect(FocusManager.instance.primaryFocus, equals(buttonFocus));

      await tester.tap(find.byType(CupertinoMenuAnchor));
      await tester.pumpAndSettle();
      await tester.tap(TestMenu.item1.findText);
      await tester.pump();

      expect(focusInOnPressed, equals(buttonFocus));
      expect(FocusManager.instance.primaryFocus, equals(buttonFocus));
    });
  });

  group('Appearance', () {
    testWidgets('background color can be set', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.dark),
          home: Center(
            child: CupertinoMenuAnchor(
              builder: buildAnchor,
              backgroundColor: CupertinoColors.activeGreen.darkColor,
              menuChildren: createTestMenus(onPressed: onPressed),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CupertinoMenuAnchor));
      await tester.pumpAndSettle();

      // Private painter class is used to paint the background color.
      expect(
        '${findMenuPanelWidget<CustomPaint>(tester).painter}'.contains('Color(0xff30d158)'),
        isTrue,
      );
    });

    testWidgets('opaque background color removes backdrop filter',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.dark),
          home: Center(
            child: CupertinoMenuAnchor(
              builder: buildAnchor,
              backgroundColor: CupertinoColors.activeGreen.darkColor,
              menuChildren: createTestMenus(onPressed: onPressed),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CupertinoMenuAnchor));
      await tester.pumpAndSettle();

      // Private painter class is used to paint the background color.
      expect(
        findMenuPanelDescendent<BackdropFilter>(),
        findsNothing,
      );
    });

    testWidgets('surface builder can be changed', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: CupertinoMenuAnchor(
              builder: buildAnchor,
              menuChildren: createTestMenus(onPressed: onPressed),
              backgroundColor: const Color.fromRGBO(255, 0, 0, 1),
              surfaceBuilder: (
                BuildContext context,
                Widget child,
                Animation<double> animation,
                Color backgroundColor,
                Clip clip,
              ) {
                final DecorationTween decorationTween = DecorationTween(
                  begin: BoxDecoration(color: backgroundColor),
                  end: const BoxDecoration(color: Color.fromRGBO(0, 0, 255, 1)),
                );
                return DecoratedBoxTransition(
                  decoration: decorationTween.animate(animation),
                  child: child,
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CupertinoMenuAnchor));
      await tester.pump();

      // Background color should be passed to the surface builder.
      expect(
        findMenuPanelWidget<DecoratedBoxTransition>(tester).decoration.value,
        equals(const BoxDecoration(color: Color.fromRGBO(255, 0, 0, 1))),
      );

      await tester.pumpAndSettle();

      // Animation should change the background color.
      expect(
        findMenuPanelWidget<DecoratedBoxTransition>(tester).decoration.value,
        equals(const BoxDecoration(color: Color.fromRGBO(0, 0, 255, 1))),
      );

      // A custom surface builder should not affect the layout of the menu.
      expect(
        tester.getRect(
          find
              .descendant(
                of: findMenuPanel(),
                matching: find.byType(DecoratedBoxTransition),
              )
              .first,
        ),
        rectEquals(const Rect.fromLTRB(8.0, 56.0, 258.0, 379.0)),
      );
    });

    testWidgets('default surface appearance', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: CupertinoMenuAnchor(
                      builder: buildAnchor,
                      menuChildren: createTestMenus(onPressed: onPressed),
                    ),
                  ),
                ],
              ),
              const Expanded(child: Placeholder()),
            ],
          ),
        ),
      );

      // Open and make sure things are the right size.
      await tester.tap(find.byType(CupertinoMenuAnchor));
      await tester.pumpAndSettle();

      expect(
        tester.getRect(findMenuPanel()),
        equals(const Rect.fromLTRB(0.0, 0.0, 800.0, 600.0))
      );

      final DecoratedBoxTransition decoratedBox =
              findMenuPanelWidget<DecoratedBoxTransition>(tester);
      final CustomPaint customPaint =
              findMenuPanelWidget<CustomPaint>(tester);
      final BackdropFilter backdropFilter =
              findMenuPanelWidget<BackdropFilter>(tester);

      expect(
        decoratedBox.decoration.value,
        equals(
          const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.12),
                spreadRadius: 30,
                blurRadius: 50,
              ),
            ],
          ),
        ),
      );

      expect(
        backdropFilter.filter,
        equals(
          ImageFilter.compose(
            inner: const ColorFilter.matrix(<double>[
              1.74, -0.4, -0.17, 0.0, 0.0, //
              -0.26, 1.6, -0.17, 0.0, 0.0, //
              -0.26, -0.4, 1.83, 0.0, 0.0, //
              0.0, 0.0, 0.0, 1.0, 0.0 //
            ]),
            outer: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          ),
        ),
      );

      expect(
        '${customPaint.painter}'.contains('Color(0xc5f3f3f3)'),
        isTrue,
      );

      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.dark),
          home: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: CupertinoMenuAnchor(
                      builder: buildAnchor,
                      menuChildren: createTestMenus(onPressed: onPressed),
                    ),
                  ),
                ],
              ),
              const Expanded(child: Placeholder()),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      final DecoratedBoxTransition darkDecoratedBox =
          findMenuPanelWidget<DecoratedBoxTransition>(tester);
      final CustomPaint darkCustomPaint =
          findMenuPanelWidget<CustomPaint>(tester);
      final BackdropFilter darkBackdropFilter =
          findMenuPanelWidget<BackdropFilter>(tester);

      expect(
        darkDecoratedBox.decoration.value,
        equals(
          const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.12),
                spreadRadius: 30,
                blurRadius: 50,
              ),
            ],
          ),
        ),
      );

      expect(
        darkBackdropFilter.filter,
        equals(
          ImageFilter.compose(
            inner: const ColorFilter.matrix(<double>[
              1.385, -0.5599999999999999, -0.11199999999999999, 0.0, 0.3, //
              -0.315, 1.1400000000000001, -0.11199999999999999, 0.0, 0.3, //
              -0.315, -0.5599999999999999, 1.588, 0.0, 0.3, //
              0.0, 0.0, 0.0, 1.0, 0.0, //
            ]),
            outer: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          ),
        ),
      );

      expect(
        '${darkCustomPaint.painter}'.contains('Color(0xbb373737)'),
        isTrue,
      );
    }, skip: isBrowser); // https://github.com/flutter/flutter/issues/108688

    testWidgets('[web] default surface appearance', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: CupertinoMenuAnchor(
                      builder: buildAnchor,
                      menuChildren: createTestMenus(onPressed: onPressed),
                    ),
                  ),
                ],
              ),
              const Expanded(child: Placeholder()),
            ],
          ),
        ),
      );

      // Open and make sure things are the right size.
      await tester.tap(find.byType(CupertinoMenuAnchor));
      await tester.pumpAndSettle();

      expect(
        tester.getRect(findMenuPanel()),
        equals(const Rect.fromLTRB(0.0, 0.0, 800.0, 600.0))
      );

      final DecoratedBoxTransition decoratedBox =
              findMenuPanelWidget<DecoratedBoxTransition>(tester);
      final CustomPaint customPaint =
              findMenuPanelWidget<CustomPaint>(tester);
      final BackdropFilter backdropFilter =
              findMenuPanelWidget<BackdropFilter>(tester);

      expect(
        decoratedBox.decoration.value,
        equals(const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.12),
                spreadRadius: 30,
                blurRadius: 50,
              ),
            ],
        )),
      );
      expect(
        backdropFilter.filter,
        equals(ImageFilter.blur(sigmaX: 30, sigmaY: 30))
      );
      expect(
        '${customPaint.painter}'.contains('Color(0xc5f3f3f3)'),
        isTrue,
      );

      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.dark),
          home: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: CupertinoMenuAnchor(
                      builder: buildAnchor,
                      menuChildren: createTestMenus(onPressed: onPressed),
                    ),
                  ),
                ],
              ),
              const Expanded(child: Placeholder()),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      final DecoratedBoxTransition darkDecoratedBox =
          findMenuPanelWidget<DecoratedBoxTransition>(tester);
      final CustomPaint darkCustomPaint =
          findMenuPanelWidget<CustomPaint>(tester);
      final BackdropFilter darkBackdropFilter =
          findMenuPanelWidget<BackdropFilter>(tester);

      expect(
        darkDecoratedBox.decoration.value,
        equals(const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.12),
                spreadRadius: 30,
                blurRadius: 50,
              ),
            ],
        )),
      );

      expect(
        darkBackdropFilter.filter,
        equals(ImageFilter.blur(sigmaX: 30, sigmaY: 30)),
      );

      expect(
        '${darkCustomPaint.painter}'.contains('Color(0xbb373737)'),
        isTrue,
      );
    }, skip: !isBrowser); // https://github.com/flutter/flutter/issues/108688

    testWidgets('panel clip behavior', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Material(
            child: Center(
              child: CupertinoMenuAnchor(
                menuChildren: const <Widget>[
                  CupertinoMenuItem(
                    child: Text('Button 1'),
                  ),
                ],
                builder: (
                  BuildContext context,
                  CupertinoMenuController controller,
                  Widget? child,
                ) {
                  return FilledButton(
                    onPressed: controller.open,
                    child: const Text('Tap me'),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Tap me'));
      await tester.pumpAndSettle();

      // Test default clip behavior.
      expect(findMenuPanelWidget<ClipRRect>(tester).clipBehavior,
          equals(Clip.antiAlias));

      // Close the menu.
      await tester.tapAt(const Offset(10.0, 10.0));
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Center(
              child: CupertinoMenuAnchor(
                clipBehavior: Clip.hardEdge,
                menuChildren: const <Widget>[
                  CupertinoMenuItem(
                    child: Text('Button 1'),
                  ),
                ],
                builder: (BuildContext context,
                    CupertinoMenuController controller, Widget? child) {
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
        ),
      );
      await tester.tap(find.text('Tap me'));
      await tester.pump();

      // Test custom clip behavior.
      expect(findMenuPanelWidget<ClipRRect>(tester).clipBehavior,
          equals(Clip.hardEdge));
    });

    testWidgets('forwardSpring can be set', (WidgetTester tester) async {
      CupertinoApp builder() {
        return CupertinoApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: CupertinoMenuAnchor(
              controller: controller,
              builder: buildAnchor,
              forwardSpring: SpringDescription.withDampingRatio(
                  mass: 0.0001, stiffness: 100),
              menuChildren: createTestMenus(onPressed: (TestMenu menu) {}),
            ),
          ),
        );
      }

      await tester.pumpWidget(builder());
      await tester.tap(find.byType(CupertinoMenuAnchor));
      await tester.pumpFrames(builder(), const Duration(milliseconds: 50));

      expect(controller.menuStatus, MenuStatus.opened);

      await tester.pumpAndSettle();
      controller.close();
      await tester.pumpFrames(builder(), const Duration(milliseconds: 200));

      // Check that the reverse spring is not affected
      expect(controller.menuStatus, MenuStatus.closing);
    });
    testWidgets('reverseSpring can be set', (WidgetTester tester) async {
      CupertinoApp builder() {
        return CupertinoApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: CupertinoMenuAnchor(
              controller: controller,
              builder: buildAnchor,
              reverseSpring: SpringDescription.withDampingRatio(
                  mass: 0.0001, stiffness: 100),
              menuChildren: createTestMenus(onPressed: (TestMenu menu) {}),
            ),
          ),
        );
      }

      await tester.pumpWidget(builder());
      controller.open();
      await tester.pumpFrames(builder(), const Duration(milliseconds: 200));

      // Check that the forward spring is not affected
      expect(controller.menuStatus, MenuStatus.opening);

      await tester.pumpAndSettle();
      controller.close();
      await tester.pumpFrames(builder(), const Duration(milliseconds: 50));

      expect(controller.menuStatus, MenuStatus.closed);
    });

    testWidgets('CupertinoScrollBar is drawn on vertically constrained menus',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Column(
            children: <Widget>[
              CupertinoMenuAnchor(
                  constraints: const BoxConstraints.tightFor(height: 200),
                  builder: buildAnchor,
                  menuChildren: createTestMenus()),
            ],
          ),
        ),
      );

      await tester.tap(find.byType(CupertinoMenuAnchor));
      await tester.pumpAndSettle();

      expect(
        find.ancestor(
          of: find.byType(SliverList),
          matching: find.descendant(
            of: find.byType(DecoratedBoxTransition),
            matching: find.byType(CupertinoScrollbar),
          ),
        ),
        findsOneWidget,
      );
    });
  });

  group('Layout', () {
    List<Rect> collectRects<T>() {
      final List<Rect> menuRects = <Rect>[];
      final List<Element> candidates = find.byType(T).evaluate().toList();
      for (final Element candidate in candidates) {
        final RenderBox box = candidate.renderObject! as RenderBox;
        final Offset topLeft = box.localToGlobal(box.size.topLeft(Offset.zero));
        final Offset bottomRight = box.localToGlobal(box.size.bottomRight(Offset.zero));
        menuRects.add(Rect.fromPoints(topLeft, bottomRight));
      }
      return menuRects;
    }

    testWidgets('unconstrained menus show up in the right place in LTR',
        (WidgetTester tester) async {
      await changeSurfaceSize(tester, const Size(800, 600));
      await tester.pumpWidget(
        CupertinoApp(
          home: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: CupertinoMenuAnchor(
                      builder: buildAnchor,
                      constraints: const BoxConstraints(),
                      menuChildren: createTestMenus(onPressed: onPressed),
                    ),
                  ),
                ],
              ),
              const Expanded(child: Placeholder()),
            ],
          ),
        ),
      );

      await tester.tap(find.byType(CupertinoMenuAnchor));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoMenuItem), findsNWidgets(7));

      final List<Rect> actual = collectRects<CupertinoMenuItem>();
      const List<Rect> expected = <Rect>[
        Rect.fromLTRB(8.0, 56.0, 792.0, 99.7),
        Rect.fromLTRB(8.0, 100.0, 792.0, 143.7),
        Rect.fromLTRB(8.0, 151.7, 792.0, 195.4),
        Rect.fromLTRB(8.0, 195.7, 792.0, 239.4),
        Rect.fromLTRB(8.0, 239.7, 792.0, 283.4),
        Rect.fromLTRB(8.0, 291.4, 792.0, 335.0),
        Rect.fromLTRB(8.0, 335.4, 792.0, 379.0),
      ];

      for (int i = 0; i < actual.length; i++) {
        expect(actual[i], rectEquals(expected[i]));
      }
    });

    testWidgets('unconstrained menus show up in the right place in RTL',
        (WidgetTester tester) async {
      await changeSurfaceSize(tester, const Size(800, 600));
      await tester.pumpWidget(
        CupertinoApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: CupertinoMenuAnchor(
                        builder: buildAnchor,
                        menuChildren: createTestMenus(onPressed: onPressed),
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

      await tester.tap(find.byType(CupertinoMenuAnchor));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoMenuItem), findsNWidgets(7));

      final List<Rect> actual = collectRects<CupertinoMenuItem>();
      const List<Rect> expected = <Rect>[
        Rect.fromLTRB(275.0, 56.0,  525.0, 99.7),
        Rect.fromLTRB(275.0, 100.0, 525.0, 143.7),
        Rect.fromLTRB(275.0, 151.7, 525.0, 195.4),
        Rect.fromLTRB(275.0, 195.7, 525.0, 239.4),
        Rect.fromLTRB(275.0, 239.7, 525.0, 283.4),
        Rect.fromLTRB(275.0, 291.4, 525.0, 335.0),
        Rect.fromLTRB(275.0, 335.4, 525.0, 379.0),
      ];

      for (int i = 0; i < actual.length; i++) {
        expect(actual[i], rectEquals(expected[i]));
      }
    });

    testWidgets('constrained menus show up in the right place in LTR',
        (WidgetTester tester) async {
      await changeSurfaceSize(tester, const Size(220, 200));
      await tester.pumpWidget(
        CupertinoApp(
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              children: <Widget>[
                CupertinoMenuAnchor(
                  builder: buildAnchor,
                  menuChildren: createTestMenus(onPressed: onPressed),
                ),
                const Expanded(child: Placeholder()),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.byType(CupertinoMenuAnchor));
      await tester.pumpAndSettle();

      // Fewer items fit in the constrained menu.
      expect(find.byType(CupertinoMenuItem), findsNWidgets(5));

      final List<Rect> actual = collectRects<CupertinoMenuItem>();
      const List<Rect> expected = <Rect>[
        Rect.fromLTRB(8.0, 8.0, 212.0, 51.7),
        Rect.fromLTRB(8.0, 52.0, 212.0, 95.7),
        Rect.fromLTRB(8.0, 103.7, 212.0, 147.3),
        Rect.fromLTRB(8.0, 147.7, 212.0, 191.3),
        Rect.fromLTRB(8.0, 191.7, 212.0, 235.3),
      ];

      for (int i = 0; i < actual.length; i++) {
        expect(actual[i], rectEquals(expected[i]));
      }
    });

    testWidgets('constrained menus show up in the right place in RTL',
        (WidgetTester tester) async {
      await changeSurfaceSize(tester, const Size(220, 200));
      await tester.pumpWidget(
        CupertinoApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: <Widget>[
                CupertinoMenuAnchor(
                  builder: buildAnchor,
                  menuChildren: createTestMenus(onPressed: onPressed),
                ),
                const Expanded(child: Placeholder()),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CupertinoMenuAnchor));
      await tester.pumpAndSettle();

      // Fewer items fit in the constrained menu.
      expect(find.byType(CupertinoMenuItem), findsNWidgets(5));

      final List<Rect> actual = collectRects<CupertinoMenuItem>();
      const List<Rect> expected = <Rect>[
        Rect.fromLTRB(8.0, 8.0, 212.0, 51.7),
        Rect.fromLTRB(8.0, 52.0, 212.0, 95.7),
        Rect.fromLTRB(8.0, 103.7, 212.0, 147.3),
        Rect.fromLTRB(8.0, 147.7, 212.0, 191.3),
        Rect.fromLTRB(8.0, 191.7, 212.0, 235.3),
      ];

      for (int i = 0; i < actual.length; i++) {
        expect(actual[i], rectEquals(expected[i]));
      }
    });

    testWidgets('parent constraints do not affect menu size',
        (WidgetTester tester) async {
      await changeSurfaceSize(tester, const Size(220, 200));
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: ConstrainedBox(
          constraints: const BoxConstraints.tightFor(width: 5, height: 5),
          child: Column(
            children: <Widget>[
              CupertinoMenuAnchor(
                builder: buildAnchor,
                menuChildren: createTestMenus(onPressed: onPressed),
              ),
              const Expanded(child: Placeholder()),
            ],
          ),
        ),
      ));

      await tester.tap(find.byType(CupertinoMenuAnchor));
      await tester.pumpAndSettle();
      final List<Rect> actual = collectRects<CupertinoMenuItem>();

      // Fewer items fit in the constrained menu.
      expect(find.byType(CupertinoMenuItem), findsNWidgets(5));
      expect(
        actual[0],
        rectEquals(const Rect.fromLTRB(8.0, 8.0, 212.0, 51.7)),
      );

      expect(
        tester.getRect(find.byType(CustomScrollView)),
        rectEquals(const Rect.fromLTRB(8.0, 8.0, 212.0, 192.0)),
      );
    });

    testWidgets(
        'constrained menus show up in the right place with offset in LTR',
        (WidgetTester tester) async {
      await changeSurfaceSize(tester, const Size(220, 200));
      await tester.pumpWidget(
        CupertinoApp(
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: Alignment.topLeft,
              child: CupertinoMenuAnchor(
                alignmentOffset: const Offset(30, 30),
                menuChildren: createTestMenus(onPressed: onPressed),
                builder: buildAnchor,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CupertinoMenuAnchor));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoMenuItem), findsNWidgets(5));

      final List<Rect> actual = collectRects<CupertinoMenuItem>();
      const List<Rect> expected = <Rect>[
        Rect.fromLTRB(8.0, 8.0, 212.0, 51.7),
        Rect.fromLTRB(8.0, 52.0, 212.0, 95.7),
        Rect.fromLTRB(8.0, 103.7, 212.0, 147.3),
        Rect.fromLTRB(8.0, 147.7, 212.0, 191.3),
        Rect.fromLTRB(8.0, 191.7, 212.0, 235.3),
      ];

      for (int i = 0; i < actual.length; i++) {
        expect(actual[i], rectEquals(expected[i]));
      }
    });

    testWidgets(
        'constrained menus show up in the right place with offset in RTL',
        (WidgetTester tester) async {
      await changeSurfaceSize(tester, const Size(220, 200));
      await tester.pumpWidget(
        CupertinoApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Align(
              alignment: Alignment.topRight,
              child: CupertinoMenuAnchor(
                builder: buildAnchor,
                alignmentOffset: const Offset(30, 30),
                menuChildren: createTestMenus(onPressed: onPressed),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(CupertinoMenuAnchor));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoMenuItem), findsNWidgets(5));
      final List<Rect> actual = collectRects<CupertinoMenuItem>();
      const List<Rect> expected = <Rect>[
        Rect.fromLTRB(8.0, 8.0, 212.0, 51.7),
        Rect.fromLTRB(8.0, 52.0, 212.0, 95.7),
        Rect.fromLTRB(8.0, 103.7, 212.0, 147.3),
        Rect.fromLTRB(8.0, 147.7, 212.0, 191.3),
        Rect.fromLTRB(8.0, 191.7, 212.0, 235.3),
      ];

      for (int i = 0; i < actual.length; i++) {
        expect(actual[i], rectEquals(expected[i]));
      }
    });

    testWidgets(
        'menus anchored below the halfway point of the screen grow upwards',
        (WidgetTester tester) async {
      await changeSurfaceSize(tester, const Size(800, 600));
      await tester.pumpWidget(
        CupertinoApp(
          home: Align(
            alignment: const Alignment(0.5, 0.5),
            child: CupertinoMenuAnchor(
                builder: buildAnchor,
                menuChildren: <Widget>[
                  CupertinoMenuItem(child: TestMenu.item0.text),
                ]),
          ),
        ),
      );

      await tester.tap(find.byType(CupertinoMenuAnchor));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoMenuItem), findsOneWidget);
      expect(tester.getRect(find.byType(CupertinoMenuItem)),
          rectEquals(const Rect.fromLTRB(461.0, 364.3, 711.0, 408.0)));
    });

    testWidgets('offset affects the growth direction of the menu',
        (WidgetTester tester) async {
      await changeSurfaceSize(tester, const Size(800, 800));
      await tester.pumpWidget(
        CupertinoApp(
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: Alignment.topLeft,
              child: CupertinoMenuAnchor(
                builder: buildAnchor,
                alignmentOffset: const Offset(0, 450),
                menuChildren: <Widget>[
                  CupertinoMenuItem(
                      child: TestMenu.item0.text, onPressed: () {}),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CupertinoMenuAnchor));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoMenuItem), findsOneWidget);
      expect(
        tester.getRect(TestMenu.item0.findMenuItem),
        rectEquals(const Rect.fromLTRB(8.0, 406.3, 258.0, 450.0)),
      );
    });

    testWidgets('geometry LTR', (WidgetTester tester) async {
      await changeSurfaceSize(tester, const Size(800, 600));
      await tester.pumpWidget(
        CupertinoApp(
          home: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: CupertinoMenuAnchor(
                      builder: buildAnchor,
                      menuChildren: createTestMenus(onPressed: onPressed),
                    ),
                  ),
                ],
              ),
              const Expanded(child: Placeholder()),
            ],
          ),
        ),
      );

      await tester.pump();
      final Finder menuAnchor = find.byType(CupertinoMenuAnchor);

      expect(tester.getRect(menuAnchor),
      rectEquals(const Rect.fromLTRB(0, 0, 800, 56)));

      // Open and make sure things are the right size.
      await tester.tap(menuAnchor);
      await tester.pump();

      expect(tester.getRect(menuAnchor),
      rectEquals(const Rect.fromLTRB(0, 0, 800, 56)));

      // The menu just started opening, therefore menu items should be Size.zero
      expect(tester.getRect(TestMenu.item5Disabled.findMenuItem),
      rectEquals(const Rect.fromLTRB(400.0, 56, 400.0, 56)));

      await tester.pumpAndSettle();

      expect(tester.getRect(menuAnchor),
      rectEquals(const Rect.fromLTRB(0, 0, 800, 56)));

      expect(tester.getRect(TestMenu.item5Disabled.findMenuItem),
      rectEquals(const Rect.fromLTRB(275.0, 291.4, 525.0, 335.0)));

      // Decorative surface sizes should match
      const Rect surfaceSize = Rect.fromLTRB(275.0, 56.0, 525.0, 379.0);
      expect(
        tester.getRect(
          find.ancestor(
                  of: TestMenu.item5Disabled.findMenuItem,
                  matching: find.byType(DecoratedBoxTransition))
              .first,
        ),
        rectEquals(surfaceSize),
      );

      expect(
        tester.getRect(
          find.ancestor(
                  of: TestMenu.item5Disabled.findMenuItem,
                  matching: find.byType(FadeTransition))
              .first,
        ),
        rectEquals(surfaceSize),
      );

      // Test menu bar size when not expanded.
      await tester.pumpWidget(
        CupertinoApp(
          home: Column(
            children: <Widget>[
              CupertinoMenuAnchor(
                builder: buildAnchor,
                menuChildren: createTestMenus(onPressed: onPressed),
              ),
              const Expanded(child: Placeholder()),
            ],
          ),
        ),
      );

      await tester.pump();

      expect(
        tester.getRect(menuAnchor),
        rectEquals(const Rect.fromLTRB(372.0, 0.0, 428.0, 56.0)),
      );
    });

    testWidgets('geometry RTL', (WidgetTester tester) async {
      final UniqueKey menuKey = UniqueKey();
      await tester.pumpWidget(
        CupertinoApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: CupertinoMenuAnchor(
                        key: menuKey,
                        builder: buildAnchor,
                        menuChildren: createTestMenus(onPressed: onPressed),
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

      final Finder menuAnchor = find.byType(CupertinoMenuAnchor);

      expect(tester.getRect(menuAnchor),
          rectEquals(const Rect.fromLTRB(0, 0, 800, 56)));

      // Open and make sure things are the right size.
      await tester.tap(menuAnchor);
      await tester.pump();

      expect(tester.getRect(menuAnchor),
          rectEquals(const Rect.fromLTRB(0, 0, 800, 56)));

      // The menu just started opening, therefore menu items should be Size.zero
      expect(tester.getRect(TestMenu.item5Disabled.findMenuItem),
          rectEquals(const Rect.fromLTRB(400.0, 56.0, 400.0, 56.0)));

      await tester.pumpAndSettle();

      expect(tester.getRect(menuAnchor),
          rectEquals(const Rect.fromLTRB(0, 0, 800, 56)));
      expect(tester.getRect(TestMenu.item5Disabled.findMenuItem),
          rectEquals(const Rect.fromLTRB(275.0, 291.4, 525.0, 335.0)));

      // Decorative surface sizes should match
      const Rect surfaceSize = Rect.fromLTRB(275.0, 56.0, 525.0, 379.0);
      expect(
        tester.getRect(
          find.ancestor(
                of: TestMenu.item5Disabled.findMenuItem,
                matching: find.byType(DecoratedBoxTransition),
              )
              .first,
        ),
        rectEquals(surfaceSize),
      );

      expect(
        tester.getRect(
          find.ancestor(
                of: TestMenu.item5Disabled.findMenuItem,
                matching: find.byType(FadeTransition),
              )
              .first,
        ),
        rectEquals(surfaceSize),
      );

      // Test menu bar size when not expanded.
      await tester.pumpWidget(
        CupertinoApp(
          home: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: <Widget>[
                  CupertinoMenuAnchor(
                    builder: buildAnchor,
                    menuChildren: createTestMenus(onPressed: onPressed),
                  ),
                  const Expanded(child: Placeholder()),
                ],
              )),
        ),
      );

      await tester.pump();
      expect(
        tester.getRect(menuAnchor),
        rectEquals(const Rect.fromLTRB(372.0, 0.0, 428.0, 56.0)),
      );
    });

    testWidgets('menu alignment and offset in LTR',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 800));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(buildTestApp());

      final Finder anchor = TestMenu.anchorButton.findAncestor<Material>();
      final Finder findMenuScope =
              find.ancestor(
                of: TestMenu.item1.findText,
                matching: find.byType(FocusScope),
              )
              .first;

      expect(tester.getRect(anchor),
          rectEquals(const Rect.fromLTRB(350.0, 200.0, 406.0, 256.0)));

      await tester.tap(anchor);
      await tester.pumpAndSettle();

      // Matches the position of the menu given the alignment and menuAlignment.
      Future<void> matchPosition(
        Rect position, [
        AlignmentDirectional? alignment,
        AlignmentDirectional? menuAlignment,
      ]) async {
        await tester.pumpWidget(
          buildTestApp(
            alignment: alignment,
            menuAlignment: menuAlignment,
          ),
        );
        await tester.pump();
        expect(tester.getRect(findMenuScope), rectEquals(position));
      }

      const Rect defaultPosition = Rect.fromLTRB(253.0, 256.0, 503.0, 579.0);

      // Top center alignment (default)
      await matchPosition(defaultPosition);

      // Validate the default menu position matches the alignment and
      // menuAlignment.
      await matchPosition(
        defaultPosition,
        AlignmentDirectional.bottomCenter,
        AlignmentDirectional.topCenter,
      );

      await matchPosition(
        const Rect.fromLTRB(100.0, 200.0, 350.0, 523.0),
        AlignmentDirectional.topStart,
        AlignmentDirectional.topEnd,
      );

      await matchPosition(
        const Rect.fromLTRB(253.0, 66.5, 503.0, 389.5),
        AlignmentDirectional.center,
        AlignmentDirectional.center,
      );

      await matchPosition(
        const Rect.fromLTRB(406.0, 8.0, 656.0, 331.0),
        AlignmentDirectional.bottomEnd,
        AlignmentDirectional.bottomStart,
      );

      await matchPosition(
        const Rect.fromLTRB(100.0, 200.0, 350.0, 523.0),
        AlignmentDirectional.topStart,
        AlignmentDirectional.topEnd,
      );

      final Rect menuRect = tester.getRect(findMenuScope);
      await tester.pumpWidget(
        buildTestApp(
          alignment: AlignmentDirectional.topStart,
          menuAlignment: AlignmentDirectional.topEnd,
          alignmentOffset: const Offset(10, 20),
        ),
      );

      expect(
        tester.getRect(findMenuScope).topLeft - menuRect.topLeft,
        equals(const Offset(10, 20)),
      );
    });

    testWidgets('menu alignment and offset in RTL',
        (WidgetTester tester) async {
     await tester.binding.setSurfaceSize(const Size(800, 800));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(buildTestApp(
        textDirection: TextDirection.rtl,
      ));

      final Finder anchor = TestMenu.anchorButton.findAncestor<Material>();
      final Finder findMenuScope =
              find.ancestor(
                of: TestMenu.item1.findText,
                matching: find.byType(FocusScope),
              )
              .first;

      expect(tester.getRect(anchor),
          rectEquals(const Rect.fromLTRB(350.0, 200.0, 406.0, 256.0)));

      await tester.tap(anchor);
      await tester.pumpAndSettle();

      // Matches the position of the menu given the alignment and menuAlignment.
      Future<void> matchPosition(
        Rect position, [
        AlignmentDirectional? alignment,
        AlignmentDirectional? menuAlignment,
      ]) async {
        await tester.pumpWidget(
          buildTestApp(
            textDirection: TextDirection.rtl,
            alignment: alignment,
            menuAlignment: menuAlignment,
          ),
        );
        await tester.pump();
        expect(tester.getRect(findMenuScope), rectEquals(position));
      }

      const Rect defaultPosition = Rect.fromLTRB(253.0, 256.0, 503.0, 579.0);

      // Top center alignment (default)
      await matchPosition(defaultPosition);

      // Validate the default menu position matches the alignment and
      // menuAlignment.
      await matchPosition(
        defaultPosition,
        AlignmentDirectional.bottomCenter,
        AlignmentDirectional.topCenter,
      );

      await matchPosition(
        const Rect.fromLTRB(406.0, 200.0, 656.0, 523.0),
        AlignmentDirectional.topStart,
        AlignmentDirectional.topEnd,
      );

      await matchPosition(
        const Rect.fromLTRB(253.0, 66.5, 503.0, 389.5),
        AlignmentDirectional.center,
        AlignmentDirectional.center,
      );

      await matchPosition(
        const Rect.fromLTRB(100.0, 8.0, 350.0, 331.0),
        AlignmentDirectional.bottomEnd,
        AlignmentDirectional.bottomStart,
      );

      await matchPosition(
        const Rect.fromLTRB(406.0, 200.0, 656.0, 523.0),
        AlignmentDirectional.topStart,
        AlignmentDirectional.topEnd,
      );

      final Rect menuRect = tester.getRect(findMenuScope);
      await tester.pumpWidget(
        buildTestApp(
          textDirection: TextDirection.rtl,
          alignment: AlignmentDirectional.topStart,
          menuAlignment: AlignmentDirectional.topEnd,
          alignmentOffset: const Offset(10, 20),
        ),
      );

      expect(
        tester.getRect(findMenuScope).topLeft - menuRect.topLeft,
        equals(const Offset(-10, 20)),
      );
    });

    testWidgets('menu position in LTR', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 800));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(buildTestApp());
      final Finder anchor = TestMenu.anchorButton.findAncestor<Material>();
      expect(tester.getRect(anchor),
          rectEquals(const Rect.fromLTRB(350.0, 200.0, 406.0, 256.0)));

      final Finder findMenuScope = find
          .ancestor(
              of: find.text(TestMenu.item1.label),
              matching: find.byType(FocusScope))
          .first;

      // Open the menu and make sure things are positioned correctly.
      await tester.tap(find.text('Press Me'));
      await tester.pumpAndSettle();

      final Rect basePosition = tester.getRect(findMenuScope);

       expect(tester.getRect(findMenuScope),
          rectEquals(const Rect.fromLTRB(253.0, 256.0, 503.0, 579.0)));

      await tester.pumpWidget(
        buildTestApp(alignmentOffset: const Offset(100, 50))
      );

      expect(tester.getRect(findMenuScope),
          rectEquals(basePosition.shift(const Offset(100, 50))));

      // Now move the menu by calling open() again with a local position on the
      // anchor.
      controller.open(position: const Offset(50, 75));

      await tester.pump();

      expect(tester.getRect(findMenuScope),
          rectEquals(basePosition.shift(const Offset(50, 75))));
    });

    testWidgets('menu position in RTL', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 800));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        buildTestApp(textDirection: TextDirection.rtl)
      );
      final Finder anchor = TestMenu.anchorButton.findAncestor<Material>();
      expect(tester.getRect(anchor),
          rectEquals(const Rect.fromLTRB(350.0, 200.0, 406.0, 256.0)));

      final Finder findMenuScope = find
          .ancestor(
              of: find.text(TestMenu.item1.label),
              matching: find.byType(FocusScope))
          .first;

      // Open the menu and make sure things are positioned correctly.
      await tester.tap(find.text('Press Me'));
      await tester.pumpAndSettle();

      final Rect basePosition = tester.getRect(findMenuScope);

      expect(tester.getRect(findMenuScope),
          rectEquals(const Rect.fromLTRB(253.0, 256.0, 503.0, 579.0)));

      await tester.pumpWidget(buildTestApp(
        textDirection: TextDirection.rtl,
        alignmentOffset: const Offset(100, 50),
      ));

      // Because the menu is RTL but no directional alignment is provided, the
      // menu will be positioned as if it were LTR.
      expect(tester.getRect(findMenuScope),
          rectEquals(basePosition.shift(const Offset(100, 50))));

      await tester.pumpWidget(buildTestApp(
        textDirection: TextDirection.rtl,
        alignment: AlignmentDirectional.bottomCenter,
        alignmentOffset: const Offset(100, 50),
      ));

      // Now the menu should be positioned as if it were RTL: the horizontal
      // offset is negative.
      expect(tester.getRect(findMenuScope),
          rectEquals(basePosition.translate(-100, 50)));

      // Now move the menu by calling open() again with a local position on the
      // anchor.
      controller.open(position: const Offset(50, 75));

      await tester.pump();

      expect(tester.getRect(findMenuScope),
          rectEquals(basePosition.shift(const Offset(-50, 75))));
    });

    testWidgets('app and anchor padding LTR', (WidgetTester tester) async {
      // Out of MaterialApp:
      //    - overlay position affected
      //    - anchor position affected

      // In MaterialApp:
      //   - anchor position affected

      // Padding inside MaterialApp DOES NOT affect the overlay position but
      // DOES affect the anchor position
      await tester.pumpWidget(
        Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 10.0,
            bottom: 8.0,
          ),
          child: CupertinoApp(
            home: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(
                    left: 23,
                    right: 13.0,
                    top: 8.0,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: CupertinoMenuAnchor(
                          builder: buildAnchor,
                          menuChildren: createTestMenus(onPressed: onPressed),
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
      );
      await tester.pump();
      final Finder anchor = find.byType(CupertinoMenuAnchor);

      expect(tester.getRect(anchor),
          rectEquals(const Rect.fromLTRB(43.0, 8.0, 777.0, 64.0)));

      // Open and make sure things are the right size.
      await tester.tap(anchor);
      await tester.pumpAndSettle();

      expect(tester.getRect(anchor),
          rectEquals(const Rect.fromLTRB(43.0, 8.0, 777.0, 64.0)));
      expect(tester.getRect(TestMenu.item0.findMenuItem),
          rectEquals(const Rect.fromLTRB(285.0, 64.0, 535.0, 107.7)));

      expect(
        tester.getRect(find
            .ancestor(
                of: TestMenu.item6.findText,
                matching: find.byType(DecoratedBoxTransition))
            .first),
        rectEquals(const Rect.fromLTRB(285.0, 64.0, 535.0, 387.0)),
      );

      // Close and make sure it goes back where it was.
      await tester.tap(TestMenu.item6.findText);
      await tester.pump();

      expect(tester.getRect(find.byType(CupertinoMenuAnchor)),
          rectEquals(const Rect.fromLTRB(43.0, 8.0, 777.0, 64.0)));
    });

    testWidgets('app and anchor padding RTL', (WidgetTester tester) async {
      // Out of MaterialApp:
      //    - overlay position affected
      //    - anchor position affected

      // In MaterialApp:
      //   - anchor position affected
      await tester.pumpWidget(
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 10.0, bottom: 8.0),
          child: CupertinoApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 23, right: 13.0, top: 8.0),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: CupertinoMenuAnchor(
                            builder: buildAnchor,
                            menuChildren: createTestMenus(onPressed: onPressed),
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
      const Rect anchorPosition = Rect.fromLTRB(43.0, 8.0, 777.0, 64.0);
      final Finder anchor = find.byType(CupertinoMenuAnchor);

      expect(tester.getRect(anchor), rectEquals(anchorPosition));

      // Open and make sure things are the right size.
      await tester.tap(anchor);
      await tester.pumpAndSettle();

      expect(tester.getRect(anchor),
          rectEquals(anchorPosition));
      expect(tester.getRect(TestMenu.item6.findMenuItem),
          rectEquals(const Rect.fromLTRB(285.0, 343.3, 535.0, 387.0)));

      expect(
        tester.getRect(
          find
              .ancestor(
                of: TestMenu.item6.findText,
                matching: find.byType(DecoratedBoxTransition),
              )
              .first,
        ),
        rectEquals(const Rect.fromLTRB(285.0, 64.0, 535.0, 387.0)),
      );

      // Close and make sure it goes back where it was.
      await tester.tap(TestMenu.item1.findText);
      await tester.pumpAndSettle();

      expect(tester.getRect(anchor), rectEquals(anchorPosition));
    });
    testWidgets('menu screen insets LTR', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: CupertinoMenuAnchor(
              screenInsets:
                  const EdgeInsetsDirectional.fromSTEB(13, 12, 23, 14),
              controller: controller,
              menuChildren: createTestMenus(onPressed: onPressed),
            ),
          ),
        ),
      );
      controller.open();
      await tester.pumpAndSettle();

      expect(tester.getRect(findMenuPanelDescendent<CustomScrollView>().first),
          rectEquals(const Rect.fromLTRB(13.0, 12.0, 263.0, 335.0)));
    });
    testWidgets('menu screen insets RTL', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Align(
              alignment: Alignment.topLeft,
              child: CupertinoMenuAnchor(
                screenInsets:
                    const EdgeInsetsDirectional.fromSTEB(13, 12, 23, 14),
                controller: controller,
                menuChildren: createTestMenus(onPressed: onPressed),
              ),
            ),
          ),
        ),
      );
      controller.open();
      await tester.pumpAndSettle();

      expect(tester.getRect(findMenuPanelDescendent<CustomScrollView>().first),
          rectEquals(const Rect.fromLTRB(23.0, 12.0, 273.0, 335.0)));
    });
    testWidgets('textScaling over 1.25 increases menu width to 350',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.25)),
              child: Center(
                child: CupertinoMenuAnchor(
                  builder: buildAnchor,
                  menuChildren: <Widget>[
                    CupertinoMenuItem(
                      child: TestMenu.item0.text,
                    ),
                  ],
                ),
              )),
        ),
      );
      await tester.tap(find.byType(CupertinoMenuAnchor));
      await tester.pumpAndSettle();

      // The default menu width is 250.
      expect(tester.getSize(find.byType(BackdropFilter)).width, 250.0);

      await tester.pumpWidget(
        CupertinoApp(
          home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.26)),
              child: Center(
                child: CupertinoMenuAnchor(
                  builder: buildAnchor,
                  menuChildren: <Widget>[
                    CupertinoMenuItem(
                      child: TestMenu.item0.text,
                    ),
                  ],
                ),
              )),
        ),
      );

      expect(tester.getSize(find.byType(BackdropFilter)).width, 350.0);
    });

    testWidgets('shrinkWrap affects menu layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: CupertinoMenuAnchor(
              builder: buildAnchor,
              menuChildren: <Widget>[
                CupertinoMenuItem(
                  child: TestMenu.item0.text,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      // Open menu and make sure it's the right size.
      await tester.tap(find.byType(CupertinoMenuAnchor));
      await tester.pumpAndSettle();

      expect(
        tester.getRect(
          find.descendant(
                of: findMenuPanel(),
                matching: find.byType(DecoratedBoxTransition),
              )
              .first,
        ),
        rectEquals(const Rect.fromLTRB(8.0, 56.0, 258.0, 99.7)),
      );

      await tester.pumpWidget(
        CupertinoApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: CupertinoMenuAnchor(
                shrinkWrap: false,
                builder: buildAnchor,
                menuChildren: <Widget>[
                  CupertinoMenuItem(
                    child: TestMenu.item0.text,
                    onPressed: () {},
                  ),
                ]),
          ),
        ),
      );
      expect(
        tester.getRect(
          find.descendant(
                of: findMenuPanel(),
                matching: find.byType(DecoratedBoxTransition),
              )
              .first,
        ),
        equals(const Rect.fromLTRB(8.0, 8.0, 258.0, 592.0)),
      );
    });
  });
}

List<Widget> createTestMenus({
  void Function(TestMenu)? onPressed,
  Map<TestMenu, MenuSerializableShortcut> shortcuts =
      const <TestMenu, MenuSerializableShortcut>{},
  bool includeExtraGroups = false,
  bool accelerators = false,
  double? leadingWidth,
  double? trailingWidth,
  BoxConstraints? constraints,
}) {
  Widget cupertinoMenuItemButton(
    TestMenu menu, {
    bool enabled = true,
    Widget? leadingIcon,
    Widget? trailingIcon,
    Key? key,
  }) {
    return CupertinoMenuItem(
      requestFocusOnHover: true,
      key: key,
      onPressed: enabled && onPressed != null ? () => onPressed(menu) : null,
      leading: leadingIcon,
      trailing: trailingIcon,
      child: menu.text,

    );
  }

  final List<Widget> result = <Widget>[
    cupertinoMenuItemButton(TestMenu.item0, leadingIcon: const Icon(CupertinoIcons.add)),
    cupertinoMenuItemButton(TestMenu.item1),
    const CupertinoLargeMenuDivider(),
    cupertinoMenuItemButton(TestMenu.item2),
    cupertinoMenuItemButton(TestMenu.item3,
        leadingIcon: const Icon(CupertinoIcons.add),
        trailingIcon: const Icon(CupertinoIcons.add)),
    cupertinoMenuItemButton(TestMenu.item4),
    const CupertinoLargeMenuDivider(),
    cupertinoMenuItemButton(TestMenu.item5Disabled, enabled: false),
    cupertinoMenuItemButton(TestMenu.item6),
  ];
  return result;
}

enum TestMenu {
  item0('Item 0'),
  item1('Item 1'),
  item2('Item 2'),
  item3('Item 3'),
  item4('Item 4'),
  item5Disabled('Item 5'),
  item6('Item 6'),

  anchorButton('Press Me'),
  outsideButton('Outside');

  const TestMenu(this.label);
  final String label;
  Finder get findText => find.text(label);
  Finder get findMenuItem => find.widgetWithText(CupertinoMenuItem, label);
  Finder findAncestor<T>() {
    return find.ancestor(
      of: findText,
      matching: find.byType(T),
    );
  }

  // Override the default font size for web because text layout is different.
  // https://github.com/flutter/flutter/issues/102332
  Text get text =>
      Text(
        label,
        style: kIsWeb ? const TextStyle(fontSize: 16) : null,
      );
  String get debugFocusLabel =>  '$CupertinoMenuItem($text)';
}
