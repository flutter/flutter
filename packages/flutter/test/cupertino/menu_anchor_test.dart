// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/semantics_tester.dart';

void main() {
  const Duration kMenuOpenDuration = Duration(milliseconds: 900);
  const Duration kMenuCloseDuration = Duration(milliseconds: 700);
  late MenuController controller;
  final List<Tag> selected = <Tag>[];
  final List<Tag> opened = <Tag>[];
  final List<Tag> closed = <Tag>[];

  void onPressed(Tag item) {
    selected.add(item);
  }

  void onOpen(Tag item) {
    opened.add(item);
  }

  void onClose(Tag item) {
    opened.remove(item);
    closed.add(item);
  }

  setUp(() {
    selected.clear();
    opened.clear();
    closed.clear();
    controller = MenuController();
  });

  Future<void> Function(int frames) createFramePumper(WidgetTester tester) {
    return (int frames) async {
      for (int i = 0; i < frames; i += 1) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    };
  }

  Future<void> changeSurfaceSize(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
  }

  T findMenuPanelAncestor<T extends Widget>(WidgetTester tester) {
    return tester.firstWidget<T>(
      find.ancestor(of: find.byType(CupertinoPopupSurface), matching: find.byType(T)),
    );
  }

  double getScale(WidgetTester tester) {
    return findMenuPanelAncestor<ScaleTransition>(tester).scale.value;
  }

  List<Widget> findMenuChildren(WidgetTester tester) {
    return tester
        .firstWidget<Column>(
          find.descendant(of: find.byType(CupertinoPopupSurface), matching: find.byType(Column)),
        )
        .children;
  }

  List<RenderObject> findAncestorRenderTheaters(RenderObject child) {
    final List<RenderObject> results = <RenderObject>[];
    RenderObject? node = child;
    while (node != null) {
      if (node.runtimeType.toString() == '_RenderTheater') {
        results.add(node);
      }
      final RenderObject? parent = node.parent;
      node = parent is RenderObject ? parent : null;
    }
    return results;
  }

  Matcher sizeCloseTo(Size size, num distance) {
    return within(
      distance: distance,
      from: size,
      distanceFunction: (Size a, Size b) {
        final double deltaWidth = (a.width - b.width).abs();
        final double deltaHeight = (a.height - b.height).abs();
        return math.max<double>(deltaWidth, deltaHeight);
      },
    );
  }

  RenderParagraph? findDescendantParagraph(WidgetTester tester, Finder finder) {
    return find
            .descendant(of: finder, matching: find.byType(RichText))
            .evaluate()
            .first
            .renderObject
        as RenderParagraph?;
  }

  testWidgets("MenuController.isOpen is true when a menu's overlay is shown", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      App(
        CupertinoMenuAnchor(
          controller: controller,
          menuChildren: <Widget>[Text(Tag.a.text)],
          child: const AnchorButton(Tag.anchor),
        ),
      ),
    );

    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();

    expect(controller.isOpen, isTrue);
    expect(find.text(Tag.a.text), findsOneWidget);

    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();

    expect(controller.isOpen, isFalse);
    expect(find.text(Tag.a.text), findsNothing);
  });

  testWidgets('MenuController.open() and .close() toggle overlay visibility', (
    WidgetTester tester,
  ) async {
    final MenuController nestedController = MenuController();
    await tester.pumpWidget(
      App(
        CupertinoMenuAnchor(
          controller: controller,
          menuChildren: <Widget>[Text(Tag.a.text)],
          child: const AnchorButton(Tag.anchor),
        ),
      ),
    );

    // Create the menu. The menu is closed, so no menu items should be found in
    // the widget tree.
    expect(controller.isOpen, isFalse);
    expect(find.text(Tag.anchor.text), findsOne);
    expect(find.text(Tag.a.text), findsNothing);

    // Open the menu.
    controller.open();
    await tester.pump();
    await tester.pump(kMenuOpenDuration);

    expect(controller.isOpen, isTrue);
    expect(nestedController.isOpen, isFalse);
    expect(find.text(Tag.a.text), findsOneWidget);
    expect(find.text(Tag.b.a.text), findsNothing);

    // Close the menu
    controller.close();
    await tester.pump();
    await tester.pump(kMenuCloseDuration);

    // All menus should be closed.
    expect(controller.isOpen, isFalse);
    expect(find.text(Tag.a.text), findsNothing);
    expect(find.text(Tag.b.a.text), findsNothing);
  });

  testWidgets('MenuController can be changed', (WidgetTester tester) async {
    final MenuController controller = MenuController();
    final MenuController groupController = MenuController();

    final MenuController newController = MenuController();
    final MenuController newGroupController = MenuController();

    await tester.pumpWidget(
      App(
        RawMenuAnchorGroup(
          controller: controller,
          child: CupertinoMenuAnchor(
            controller: groupController,
            menuChildren: <Widget>[Text(Tag.a.text)],
            child: const AnchorButton(Tag.anchor),
          ),
        ),
      ),
    );

    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();

    expect(find.text(Tag.a.text), findsOneWidget);
    expect(controller.isOpen, isTrue);
    expect(groupController.isOpen, isTrue);
    expect(newController.isOpen, isFalse);
    expect(newGroupController.isOpen, isFalse);

    // Swap the controllers.
    await tester.pumpWidget(
      App(
        RawMenuAnchorGroup(
          controller: newController,
          child: CupertinoMenuAnchor(
            controller: newGroupController,
            menuChildren: <Widget>[Text(Tag.a.text)],
            child: const AnchorButton(Tag.anchor),
          ),
        ),
      ),
    );

    expect(find.text(Tag.a.text), findsOneWidget);
    expect(controller.isOpen, isFalse);
    expect(groupController.isOpen, isFalse);
    expect(newController.isOpen, isTrue);
    expect(newGroupController.isOpen, isTrue);

    // Close the new controller.
    newController.close();
    await tester.pump();

    expect(newController.isOpen, isFalse);
    expect(newGroupController.isOpen, isFalse);
    expect(find.text(Tag.a.text), findsNothing);
  });

  testWidgets('MenuController is detached on update', (WidgetTester tester) async {
    await tester.pumpWidget(
      App(
        CupertinoMenuAnchor(
          controller: controller,
          menuChildren: const <Widget>[SizedBox.shrink()],
          child: const SizedBox.shrink(),
        ),
      ),
    );

    // Should not throw because the controller is attached to the menu.
    controller.closeChildren();

    await tester.pumpWidget(
      const App(
        CupertinoMenuAnchor(menuChildren: <Widget>[SizedBox.shrink()], child: SizedBox.shrink()),
      ),
    );

    String serializedException = '';
    runZonedGuarded(controller.closeChildren, (Object exception, StackTrace stackTrace) {
      serializedException = exception.toString();
    });

    expect(serializedException, contains('_anchor != null'));
  });

  testWidgets('MenuController is detached on dispose', (WidgetTester tester) async {
    await tester.pumpWidget(
      App(
        CupertinoMenuAnchor(
          controller: controller,
          menuChildren: const <SizedBox>[],
          child: const SizedBox(),
        ),
      ),
    );

    // Should not throw because the controller is attached to the menu.
    controller.closeChildren();

    await tester.pumpWidget(const App(SizedBox()));

    String serializedException = '';
    runZonedGuarded(controller.closeChildren, (Object exception, StackTrace stackTrace) {
      serializedException = exception.toString();
    });

    expect(serializedException, contains('_anchor != null'));
  });

  // Credit to Closure library for the test idea.
  testWidgets('Intents are not blocked by closed anchor', (WidgetTester tester) async {
    final List<Intent> invokedIntents = <Intent>[];
    final FocusNode anchorFocusNode = FocusNode();
    addTearDown(anchorFocusNode.dispose);

    await tester.pumpWidget(
      App(
        Actions(
          actions: <Type, Action<Intent>>{
            DirectionalFocusIntent: CallbackAction<DirectionalFocusIntent>(
              onInvoke: (DirectionalFocusIntent intent) {
                invokedIntents.add(intent);
                return;
              },
            ),
            NextFocusIntent: CallbackAction<NextFocusIntent>(
              onInvoke: (NextFocusIntent intent) {
                invokedIntents.add(intent);
                return;
              },
            ),
            PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(
              onInvoke: (PreviousFocusIntent intent) {
                invokedIntents.add(intent);
                return;
              },
            ),
            DismissIntent: CallbackAction<DismissIntent>(
              onInvoke: (DismissIntent intent) {
                invokedIntents.add(intent);
                return;
              },
            ),
          },
          child: CupertinoMenuAnchor(
            controller: controller,
            menuChildren: <Widget>[Text(Tag.a.text)],
            child: AnchorButton(Tag.anchor, focusNode: anchorFocusNode),
          ),
        ),
      ),
    );

    anchorFocusNode.requestFocus();
    await tester.pump();
    Actions.invoke(anchorFocusNode.context!, const DirectionalFocusIntent(TraversalDirection.up));
    Actions.invoke(anchorFocusNode.context!, const DirectionalFocusIntent(TraversalDirection.down));
    Actions.invoke(anchorFocusNode.context!, const DirectionalFocusIntent(TraversalDirection.left));
    Actions.invoke(
      anchorFocusNode.context!,
      const DirectionalFocusIntent(TraversalDirection.right),
    );
    Actions.invoke(anchorFocusNode.context!, const NextFocusIntent());
    Actions.invoke(anchorFocusNode.context!, const PreviousFocusIntent());
    Actions.invoke(anchorFocusNode.context!, const DismissIntent());
    await tester.pump();

    expect(
      invokedIntents,
      equals(const <Intent>[
        DirectionalFocusIntent(TraversalDirection.up),
        DirectionalFocusIntent(TraversalDirection.down),
        DirectionalFocusIntent(TraversalDirection.left),
        DirectionalFocusIntent(TraversalDirection.right),
        NextFocusIntent(),
        PreviousFocusIntent(),
        DismissIntent(),
      ]),
    );
  });

  testWidgets('Actions that wrap Menu are invoked by the anchor and the overlay', (
    WidgetTester tester,
  ) async {
    final FocusNode anchorFocusNode = FocusNode();
    final FocusNode aFocusNode = FocusNode();
    addTearDown(anchorFocusNode.dispose);
    addTearDown(aFocusNode.dispose);

    bool invokedAnchor = false;
    bool invokedOverlay = false;

    await tester.pumpWidget(
      App(
        Actions(
          actions: <Type, Action<Intent>>{
            VoidCallbackIntent: CallbackAction<VoidCallbackIntent>(
              onInvoke: (VoidCallbackIntent intent) {
                intent.callback();
                return null;
              },
            ),
          },
          child: CupertinoMenuAnchor(
            childFocusNode: anchorFocusNode,
            menuChildren: <Widget>[MenuItem.tag(Tag.a, focusNode: aFocusNode)],
            child: AnchorButton(Tag.anchor, focusNode: anchorFocusNode),
          ),
        ),
      ),
    );

    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();

    Actions.invoke(
      anchorFocusNode.context!,
      VoidCallbackIntent(() {
        invokedAnchor = true;
      }),
    );
    Actions.invoke(
      aFocusNode.context!,
      VoidCallbackIntent(() {
        invokedOverlay = true;
      }),
    );

    await tester.pump();

    expect(invokedAnchor, isTrue);
    expect(invokedOverlay, isTrue);
  });

  testWidgets('DismissMenuAction closes menu', (WidgetTester tester) async {
    final FocusNode anchorFocusNode = FocusNode();
    final FocusNode aFocusNode = FocusNode();
    addTearDown(anchorFocusNode.dispose);
    addTearDown(aFocusNode.dispose);

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoMenuAnchor(
          controller: controller,
          menuChildren: <Widget>[MenuItem.tag(Tag.a, focusNode: aFocusNode)],
          child: AnchorButton(Tag.anchor, focusNode: anchorFocusNode),
        ),
      ),
    );

    // Test from the anchor.
    controller.open();
    await tester.pump();

    expect(controller.isOpen, isTrue);

    anchorFocusNode.requestFocus();
    await tester.pump();

    const ActionDispatcher().invokeAction(
      DismissMenuAction(controller: controller),
      const DismissIntent(),
      anchorFocusNode.context,
    );
    await tester.pump();

    expect(controller.isOpen, isFalse);

    // Test from the menu item.
    controller.open();
    await tester.pump();

    expect(controller.isOpen, isTrue);

    aFocusNode.requestFocus();
    await tester.pump();

    const ActionDispatcher().invokeAction(
      DismissMenuAction(controller: controller),
      const DismissIntent(),
      aFocusNode.context,
    );

    await tester.pump();

    expect(controller.isOpen, isFalse);
  });

  testWidgets('Menus close and consume tap when consumeOutsideTap is true', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: Column(
          children: <Widget>[
            MenuItem.tag(
              Tag.outside,
              onPressed: () {
                selected.add(Tag.outside);
              },
            ),
            CupertinoMenuAnchor(
              consumeOutsideTaps: true,
              onOpen: () {
                onOpen(Tag.anchor);
              },
              onClose: () {
                onClose(Tag.anchor);
              },
              menuChildren: <Widget>[MenuItem.tag(Tag.a)],
              child: AnchorButton(Tag.anchor, onPressed: onPressed),
            ),
          ],
        ),
      ),
    );

    expect(opened, isEmpty);
    expect(closed, isEmpty);

    // Doesn't consume tap when the menu is closed.
    await tester.tap(find.text(Tag.outside.text));
    await tester.pump();

    expect(selected, equals(<NestedTag>[Tag.outside]));
    selected.clear();

    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();

    expect(opened, equals(<NestedTag>[Tag.anchor]));

    expect(closed, isEmpty);
    expect(selected, equals(<NestedTag>[Tag.anchor]));
    opened.clear();
    closed.clear();
    selected.clear();

    await tester.tap(find.text(Tag.outside.text));
    await tester.pump();

    // When the menu is open, outside taps are consumed. As a result, tapping
    // outside the menu will close it and not select the outside button.
    expect(selected, isEmpty);
    expect(opened, isEmpty);
    expect(closed, equals(<NestedTag>[Tag.anchor]));

    selected.clear();
    opened.clear();
    closed.clear();
  });

  testWidgets('Menus close and do not consume tap when consumeOutsideTaps is false', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: Column(
          children: <Widget>[
            CupertinoButton(
              child: Text(Tag.outside.text),
              onPressed: () {
                selected.add(Tag.outside);
              },
            ),
            CupertinoMenuAnchor(
              onOpen: () {
                onOpen(Tag.anchor);
              },
              onClose: () {
                onClose(Tag.anchor);
              },
              menuChildren: <Widget>[MenuItem.tag(Tag.a)],
              child: AnchorButton(Tag.anchor, onPressed: onPressed),
            ),
          ],
        ),
      ),
    );

    expect(opened, isEmpty);
    expect(closed, isEmpty);

    await tester.tap(find.text(Tag.outside.text));
    await tester.pump();

    // Doesn't consume tap when the menu is closed.
    expect(selected, equals(<Tag>[Tag.outside]));

    selected.clear();

    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(opened, equals(<Tag>[Tag.anchor]));
    expect(closed, isEmpty);
    expect(selected, equals(<Tag>[Tag.anchor]));

    opened.clear();
    closed.clear();
    selected.clear();

    await tester.tap(find.text(Tag.outside.text));
    await tester.pump();
    await tester.pumpAndSettle();

    // Because consumeOutsideTaps is false, outsideButton is expected to
    // receive a tap.
    expect(opened, isEmpty);
    expect(closed, equals(<Tag>[Tag.anchor]));
    expect(selected, equals(<Tag>[Tag.outside]));

    selected.clear();
    opened.clear();
    closed.clear();
  });

  testWidgets('onOpen is called when the menu starts opening', (WidgetTester tester) async {
    int opened = 0;
    int closed = 0;
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoMenuAnchor(
          controller: controller,
          onOpen: () {
            opened += 1;
          },
          onClose: () {
            closed += 1;
          },
          menuChildren: const <Widget>[],
          child: const AnchorButton(Tag.anchor),
        ),
      ),
    );

    // onOpen is called immediately when the menu starts opening.
    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();

    expect(opened, equals(1));

    await tester.pump(const Duration(milliseconds: 50));

    // Start closing the menu.
    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();

    // Menu is still open because closing animation hasn't finished.
    expect(opened, equals(1));
    expect(closed, equals(0));

    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();

    // onOpen doesn't get called again because the menu never closed.
    expect(opened, equals(1));
    expect(closed, equals(0));

    await tester.tap(find.text(Tag.anchor.text));
    await tester.pumpAndSettle();

    expect(opened, equals(1));
    expect(closed, equals(1));

    controller.open();
    await tester.pump();

    expect(opened, equals(2));
    expect(closed, equals(1));

    await tester.pumpAndSettle();

    expect(opened, equals(2));
    expect(closed, equals(1));
  });

  testWidgets('onClose is called when the menu finishes closing', (WidgetTester tester) async {
    bool closed = true;
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoMenuAnchor(
          controller: controller,
          onOpen: () {
            closed = false;
          },
          onClose: () {
            closed = true;
          },
          menuChildren: const <Widget>[],
          child: const AnchorButton(Tag.anchor),
        ),
      ),
    );

    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();

    expect(closed, isFalse);

    await tester.pumpAndSettle();
    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();

    expect(closed, isFalse);

    await tester.pump(kMenuCloseDuration);

    expect(closed, isTrue);

    controller.open();
    await tester.pump();

    expect(closed, isFalse);

    controller.close();
    await tester.pump();

    expect(closed, isTrue);
  });
  test('debugFillProperties', () {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    final CupertinoMenuAnchor menuAnchor = CupertinoMenuAnchor(
      menuChildren: const <Text>[Text('Menu Item')],
      alignment: Alignment.center,
      alignmentOffset: const Offset(10, 20),
      constraints: const BoxConstraints.tightFor(width: 200),
      menuAlignment: Alignment.bottomRight,
      overlayPadding: const EdgeInsets.all(12),
      useRootOverlay: true,
      enableSwipe: false,
      consumeOutsideTaps: true,
      controller: MenuController(),
      onOpen: () {},
      onClose: () {},
      constrainCrossAxis: true,
      child: const Text('Anchor Child'),
    );

    menuAnchor.debugFillProperties(builder);

    final List<String> descriptions = builder.properties
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(
      descriptions,
      containsAll(<dynamic>[
        'constraints: BoxConstraints(w=200.0, 0.0<=h<=Infinity)',
        'menuAlignment: Alignment.bottomRight',
        'alignment: Alignment.center',
        'alignmentOffset: Offset(10.0, 20.0)',
        'constrains cross axis',
        'swipe disabled',
        'consumes outside taps',
        'uses root overlay',
        'overlayPadding: EdgeInsets.all(12.0)',
      ]),
    );
  });

  testWidgets('Tab traversal is not handled', (WidgetTester tester) async {
    final FocusNode bFocusNode = FocusNode();
    final FocusNode bbFocusNode = FocusNode();
    addTearDown(bFocusNode.dispose);
    addTearDown(bbFocusNode.dispose);
    final List<Intent> invokedIntents = <Intent>[];
    final Map<ShortcutActivator, Intent> defaultTraversalShortcuts = <ShortcutActivator, Intent>{
      LogicalKeySet(LogicalKeyboardKey.tab): const NextFocusIntent(),
      LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.tab): const PreviousFocusIntent(),
    };

    await tester.pumpWidget(
      App(
        Row(
          children: <Widget>[
            Actions(
              actions: <Type, Action<Intent>>{
                NextFocusIntent: CallbackAction<NextFocusIntent>(
                  onInvoke: (NextFocusIntent intent) {
                    invokedIntents.add(intent);
                    return null;
                  },
                ),
                PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(
                  onInvoke: (PreviousFocusIntent intent) {
                    invokedIntents.add(intent);
                    return null;
                  },
                ),
              },
              child: Column(
                children: <Widget>[
                  MenuItem.tag(Tag.a),
                  CupertinoMenuAnchor(
                    menuChildren: <Widget>[
                      MenuItem.tag(Tag.b.a),
                      Shortcuts(
                        shortcuts: defaultTraversalShortcuts,
                        child: MenuItem.tag(Tag.b.b, focusNode: bbFocusNode),
                      ),
                      MenuItem.tag(Tag.b.c),
                    ],
                    child: Shortcuts(
                      shortcuts: defaultTraversalShortcuts,
                      child: AnchorButton(Tag.b, focusNode: bFocusNode),
                    ),
                  ),
                  MenuItem.tag(Tag.c),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    bFocusNode.requestFocus();
    await tester.pump();

    expect(primaryFocus, equals(bFocusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(primaryFocus, equals(bFocusNode));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pump();

    expect(primaryFocus, equals(bFocusNode));

    // Open and move focus to nested menu
    await tester.tap(find.text(Tag.b.text));
    await tester.pump();
    await tester.pump(kMenuOpenDuration);

    bbFocusNode.requestFocus();
    await tester.pump();

    expect(primaryFocus, equals(bbFocusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(primaryFocus, equals(bbFocusNode));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pump();

    expect(primaryFocus, equals(bbFocusNode));
    expect(
      invokedIntents,
      equals(const <Intent>[
        NextFocusIntent(),
        PreviousFocusIntent(),
        NextFocusIntent(),
        PreviousFocusIntent(),
      ]),
    );
  });

  testWidgets('Menu closes on view size change', (WidgetTester tester) async {
    bool opened = false;
    bool closed = false;

    Widget build(Size size) {
      return Builder(
        builder: (BuildContext context) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(size: size),
            child: App(
              CupertinoMenuAnchor(
                onOpen: () {
                  opened = true;
                  closed = false;
                },
                onClose: () {
                  opened = false;
                  closed = true;
                },
                controller: controller,
                menuChildren: <Widget>[Text(Tag.a.text)],
                child: const AnchorButton(Tag.anchor),
              ),
            ),
          );
        },
      );
    }

    await tester.pumpWidget(build(const Size(800, 600)));
    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();

    expect(opened, isTrue);
    expect(closed, isFalse);

    const Size smallSize = Size(200, 200);
    await tester.pumpWidget(build(smallSize));
    await tester.pump();

    expect(opened, isFalse);
    expect(closed, isTrue);
  });

  testWidgets('Menu closes on ancestor scroll', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      App(
        SingleChildScrollView(
          controller: scrollController,
          child: CupertinoMenuAnchor(
            onOpen: () {
              onOpen(Tag.anchor);
            },
            onClose: () {
              onClose(Tag.anchor);
            },
            menuChildren: <Widget>[
              MenuItem.tag(Tag.a),
              MenuItem.tag(Tag.b),
              MenuItem.tag(Tag.c),
              MenuItem.tag(Tag.d),
            ],
            child: const AnchorButton(Tag.anchor),
          ),
        ),
      ),
    );

    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();

    expect(opened, isNotEmpty);
    expect(closed, isEmpty);
    opened.clear();

    scrollController.jumpTo(1000);
    await tester.pump();

    expect(opened, isEmpty);
    expect(closed, isNotEmpty);
  });

  testWidgets('Menus do not close on root menu internal scroll', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/122168.
    final ScrollController scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    bool rootOpened = false;
    const BoxConstraints largeButtonConstraints = BoxConstraints.tightFor(width: 200, height: 300);

    await tester.pumpWidget(
      App(
        SingleChildScrollView(
          controller: scrollController,
          child: Container(
            height: 900,
            alignment: Alignment.topLeft,
            child: CupertinoMenuAnchor(
              onOpen: () {
                rootOpened = true;
              },
              onClose: () {
                rootOpened = false;
              },
              menuChildren: <Widget>[
                MenuItem.tag(Tag.a, constraints: largeButtonConstraints),
                MenuItem.tag(Tag.b, constraints: largeButtonConstraints),
                MenuItem.tag(Tag.c, constraints: largeButtonConstraints),
                MenuItem.tag(Tag.d, constraints: largeButtonConstraints),
              ],
              child: const AnchorButton(Tag.anchor),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();
    await tester.pump(kMenuOpenDuration);

    expect(rootOpened, true);

    // Hover the first submenu anchor.
    final TestPointer pointer = TestPointer(1, ui.PointerDeviceKind.mouse);
    await tester.sendEventToBinding(pointer.hover(tester.getCenter(find.text(Tag.a.text))));
    await tester.pump();

    // Menus do not close on internal scroll.
    await tester.sendEventToBinding(pointer.scroll(const Offset(0.0, 30.0)));
    await tester.pump();
    expect(rootOpened, true);

    // Menus close on external scroll.
    scrollController.jumpTo(700);
    await tester.pump();
    await tester.pump(kMenuOpenDuration);
    expect(rootOpened, false);
  });

  // Copied from MenuAnchor tests.
  //
  // Regression test for https://github.com/flutter/flutter/issues/157606.
  testWidgets('Menu builder rebuilds when isOpen state changes', (WidgetTester tester) async {
    bool isOpen = false;
    int openCount = 0;
    int closeCount = 0;

    await tester.pumpWidget(
      App(
        CupertinoMenuAnchor(
          menuChildren: <Widget>[MenuItem.text('Menu Item')],
          builder: (BuildContext context, MenuController controller, Widget? child) {
            isOpen = controller.isOpen;
            return CupertinoButton.filled(
              child: Text(isOpen ? 'close' : 'open'),
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
            );
          },
          onOpen: () => openCount++,
          onClose: () => closeCount++,
        ),
      ),
    );

    expect(find.text('open'), findsOneWidget);
    expect(isOpen, false);
    expect(openCount, 0);
    expect(closeCount, 0);

    await tester.tap(find.text('open'));
    await tester.pump();

    expect(find.text('close'), findsOneWidget);
    expect(isOpen, true);
    expect(openCount, 1);
    expect(closeCount, 0);

    await tester.tap(find.text('close'));
    await tester.pump();

    expect(find.text('open'), findsOneWidget);
    expect(isOpen, false);
    expect(openCount, 1);
    expect(closeCount, 1);
  });

  // Copied from [MenuAnchor] tests.
  //
  // Regression test for https://github.com/flutter/flutter/issues/155034.
  testWidgets('Content is shown in the root overlay when useRootOverlay is true', (
    WidgetTester tester,
  ) async {
    final MenuController controller = MenuController();
    final UniqueKey overlayKey = UniqueKey();
    late final OverlayEntry overlayEntry;

    addTearDown(() {
      overlayEntry.remove();
      overlayEntry.dispose();
    });

    await tester.pumpWidget(
      App(
        Overlay(
          key: overlayKey,
          initialEntries: <OverlayEntry>[
            overlayEntry = OverlayEntry(
              builder: (BuildContext context) {
                return Center(
                  child: CupertinoMenuAnchor(
                    useRootOverlay: true,
                    controller: controller,
                    menuChildren: <Widget>[MenuItem.tag(Tag.a)],
                    child: const AnchorButton(Tag.anchor),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );

    expect(find.text(Tag.a.text), findsNothing);

    // Open the menu.
    controller.open();
    await tester.pump();
    await tester.pump(kMenuOpenDuration);

    expect(find.text(Tag.a.text), findsOneWidget);

    // Expect two overlays: the root overlay created by WidgetsApp and the
    // overlay created by the boilerplate code.
    expect(find.byType(Overlay), findsNWidgets(2));

    final Iterable<Overlay> overlays = tester.widgetList<Overlay>(find.byType(Overlay));
    final Overlay nonRootOverlay = tester.widget(find.byKey(overlayKey));
    final Overlay rootOverlay = overlays.firstWhere((Overlay overlay) => overlay != nonRootOverlay);

    final RenderObject menuTheater = findAncestorRenderTheaters(
      tester.renderObject(find.text(Tag.a.text)),
    ).first;

    // Check that the ancestor _RenderTheater for the menu item is the one
    // from the root overlay.
    expect(menuTheater, tester.renderObject(find.byWidget(rootOverlay)));
  });

  testWidgets('Content is shown in the nearest ancestor overlay when useRootOverlay is false', (
    WidgetTester tester,
  ) async {
    final MenuController controller = MenuController();
    final UniqueKey overlayKey = UniqueKey();

    late final OverlayEntry overlayEntry;
    addTearDown(() {
      overlayEntry.remove();
      overlayEntry.dispose();
    });

    await tester.pumpWidget(
      App(
        Overlay(
          key: overlayKey,
          initialEntries: <OverlayEntry>[
            overlayEntry = OverlayEntry(
              builder: (BuildContext context) {
                return Center(
                  child: CupertinoMenuAnchor(
                    controller: controller,
                    menuChildren: <Widget>[MenuItem.tag(Tag.a)],
                    child: const AnchorButton(Tag.anchor),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );

    expect(find.text(Tag.a.text), findsNothing);

    // Open the menu.
    controller.open();
    await tester.pump();
    await tester.pump(kMenuOpenDuration);

    expect(find.text(Tag.a.text), findsOneWidget);

    // Expect two overlays: the root overlay created by WidgetsApp and the
    // overlay created by the boilerplate code.
    expect(find.byType(Overlay), findsNWidgets(2));

    final Overlay nonRootOverlay = tester.widget(find.byKey(overlayKey));
    final RenderObject menuTheater = findAncestorRenderTheaters(
      tester.renderObject(find.text(Tag.a.text)),
    ).first;

    // Check that the ancestor _RenderTheater for the menu item is the one
    // from the nearest overlay.
    expect(menuTheater, tester.renderObject(find.byWidget(nonRootOverlay)));
  });

  testWidgets('Swiping scales the menu', (WidgetTester tester) async {
    final Future<void> Function(int frames) pumpFrames = createFramePumper(tester);
    await changeSurfaceSize(tester, const Size(2000, 2000));
    await tester.pumpWidget(
      App(
        CupertinoMenuAnchor(
          controller: controller,
          menuChildren: <Widget>[MenuItem.tag(Tag.a)],
          child: const AnchorButton(Tag.anchor),
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(pointer: 0);
    addTearDown(gesture.removePointer);

    controller.open();
    await tester.pump();
    await tester.pump(kMenuOpenDuration);

    final Offset startPosition = tester.getCenter(find.text(Tag.a.text));
    await gesture.down(startPosition);
    await tester.pump();

    final Rect menuRect = tester.getRect(find.byType(CupertinoPopupSurface));

    // Check that all corners of the menu are not scaled
    await gesture.moveTo(menuRect.topLeft);
    await tester.pump();
    await pumpFrames(10);
    expect(getScale(tester), closeTo(1.0, 0.01));

    await gesture.moveTo(menuRect.topRight);
    await tester.pump();
    await pumpFrames(10);
    expect(getScale(tester), closeTo(1.0, 0.01));

    await gesture.moveTo(menuRect.bottomLeft);
    await tester.pump();
    await pumpFrames(10);
    expect(getScale(tester), closeTo(1.0, 0.01));

    await gesture.moveTo(menuRect.bottomRight);
    await tester.pump();
    await pumpFrames(10);
    expect(getScale(tester), closeTo(1.0, 0.01));

    // Move outside the menu bounds to trigger scaling
    await gesture.moveTo(menuRect.topLeft - const Offset(50, 50));
    await pumpFrames(3);

    double topLeftScale = getScale(tester);
    expect(topLeftScale, closeTo(0.98, 0.1));

    await pumpFrames(3);

    topLeftScale = getScale(tester);
    expect(topLeftScale, closeTo(0.96, 0.1));

    await pumpFrames(3);

    topLeftScale = getScale(tester);
    expect(topLeftScale, closeTo(0.94, 0.1));

    await gesture.moveTo(menuRect.bottomRight + const Offset(50, 50));
    await pumpFrames(10);

    // Check that scale is roughly the same around the menu
    expect(getScale(tester), closeTo(topLeftScale, 0.05));

    // Test maximum distance scaling
    await gesture.moveTo(menuRect.topLeft - const Offset(200, 200));
    await pumpFrames(20);

    // Check that the minimum scale is 0.8 (20% reduction)
    expect(getScale(tester), closeTo(0.8, 0.1));

    await gesture.moveTo(menuRect.bottomRight + const Offset(200, 200));
    await pumpFrames(10);

    expect(getScale(tester), closeTo(0.8, 0.1));

    await gesture.up();
    await tester.pump();
  });

  testWidgets('Swiping minimum scale is 80 percent', (WidgetTester tester) async {
    final Future<void> Function(int frames) pumpFrames = createFramePumper(tester);
    await changeSurfaceSize(tester, const Size(2000, 2000));
    await tester.pumpWidget(
      App(
        CupertinoMenuAnchor(
          controller: controller,
          menuChildren: <Widget>[MenuItem.tag(Tag.a)],
          child: const AnchorButton(Tag.anchor),
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(pointer: 0);
    addTearDown(gesture.removePointer);

    controller.open();
    await tester.pump();
    await tester.pump(kMenuOpenDuration);

    final Offset startPosition = tester.getCenter(find.text(Tag.a.text));
    await gesture.down(startPosition);
    await tester.pump();

    final Rect menuRect = tester.getRect(find.byType(CupertinoPopupSurface));

    // Move far outside menu bounds to scale to minimum
    await gesture.moveTo(menuRect.topLeft - const Offset(500, 500));
    await pumpFrames(30);

    // Verify minimum scale is exactly 0.8 (80%)
    expect(getScale(tester), moreOrLessEquals(0.8, epsilon: 0.01));

    // Try different far positions to ensure consistent minimum scale
    await gesture.moveTo(menuRect.bottomRight + const Offset(1000, 1000));
    await pumpFrames(30);

    expect(getScale(tester), moreOrLessEquals(0.8, epsilon: 0.01));

    await gesture.up();
    await tester.pump();
  });

  testWidgets('Menu scale rebounds to full size when swipe returns to menu bounds', (
    WidgetTester tester,
  ) async {
    final Future<void> Function(int frames) pumpFrames = createFramePumper(tester);

    await changeSurfaceSize(tester, const Size(2000, 2000));
    await tester.pumpWidget(
      App(
        CupertinoMenuAnchor(
          controller: controller,
          menuChildren: <Widget>[MenuItem.tag(Tag.a)],
          child: const AnchorButton(Tag.anchor),
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);

    controller.open();
    await tester.pump();
    await tester.pumpAndSettle();

    final Rect child = tester.getRect(find.byType(CupertinoPopupSurface));

    await gesture.down(child.bottomRight - const Offset(5, 5));
    await pumpFrames(15);

    expect(getScale(tester), moreOrLessEquals(1.0, epsilon: 0.01));

    await gesture.moveBy(const Offset(100, 100));
    await pumpFrames(40);

    expect(getScale(tester), closeTo(0.85, 0.1));

    await gesture.moveBy(-const Offset(100, 100));
    await pumpFrames(40);

    expect(getScale(tester), closeTo(1.0, 0.01));

    await gesture.moveTo(child.topLeft + const Offset(5, 5));
    await pumpFrames(15);

    expect(getScale(tester), moreOrLessEquals(1.0, epsilon: 0.01));

    await gesture.moveBy(const Offset(-100, -100));
    await pumpFrames(15);

    expect(getScale(tester), closeTo(0.85, 0.1));

    await gesture.moveTo(child.center);
    await pumpFrames(40);

    expect(getScale(tester), closeTo(1.0, 0.01));
  });

  testWidgets('Menu scale rebounds to full size when swipe gesture ends', (
    WidgetTester tester,
  ) async {
    final Future<void> Function(int frames) pumpFrames = createFramePumper(tester);

    await changeSurfaceSize(tester, const Size(2000, 2000));
    await tester.pumpWidget(
      App(
        CupertinoMenuAnchor(
          controller: controller,
          menuChildren: <Widget>[MenuItem.tag(Tag.a)],
          child: const AnchorButton(Tag.anchor),
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(pointer: 0);
    addTearDown(gesture.removePointer);

    controller.open();
    await tester.pump();
    await tester.pump(kMenuOpenDuration);

    final Offset startPosition = tester.getCenter(find.text(Tag.a.text));
    await gesture.down(startPosition);
    await tester.pump();

    final Rect menuRect = tester.getRect(find.byType(CupertinoPopupSurface));

    // Start with full scale
    expect(getScale(tester), moreOrLessEquals(1.0, epsilon: 0.01));

    // Move outside menu bounds to trigger scaling
    await gesture.moveTo(menuRect.topLeft - const Offset(100, 100));
    await pumpFrames(15);

    final double scaledValue = getScale(tester);
    expect(scaledValue, lessThan(1.0));
    expect(scaledValue, greaterThan(0.8));

    // End the gesture while still outside menu bounds
    await gesture.up();
    await pumpFrames(25);

    // Verify scale rebounds back to full size after gesture ends
    expect(getScale(tester), moreOrLessEquals(1.0, epsilon: 0.01));

    // Test from a different scaled position
    final TestGesture gesture2 = await tester.createGesture(pointer: 1);
    addTearDown(gesture2.removePointer);

    await gesture2.down(startPosition);
    await tester.pump();

    // Move to maximum scale distance
    await gesture2.moveTo(menuRect.bottomRight + const Offset(200, 200));
    await pumpFrames(30);

    // Should be at minimum scale
    expect(getScale(tester), closeTo(0.8, 0.01));

    // End gesture at maximum distance
    await gesture2.up();
    await tester.pump();

    // Allow rebound animation to complete
    await pumpFrames(25);

    // Should rebound to full scale
    expect(getScale(tester), moreOrLessEquals(1.0, epsilon: 0.01));
  });

  testWidgets('Swipe can be disabled', (WidgetTester tester) async {
    await changeSurfaceSize(tester, const Size(1000, 1000));
    Widget buildWidget({required bool enableSwipe}) {
      return App(
        CupertinoMenuAnchor(
          controller: controller,
          enableSwipe: enableSwipe,
          menuChildren: <Widget>[MenuItem.tag(Tag.a)],
          child: const AnchorButton(Tag.anchor),
        ),
      );
    }

    await tester.pumpWidget(buildWidget(enableSwipe: false));

    final TestGesture gesture = await tester.createGesture(pointer: 0);
    addTearDown(gesture.removePointer);

    controller.open();
    await tester.pump();
    await tester.pumpAndSettle();

    final Offset startPosition = tester.getCenter(find.text(Tag.a.text));
    await gesture.down(startPosition);
    await tester.pump();

    final Rect menuRect = tester.getRect(find.byType(CupertinoPopupSurface));
    // Move far outside the menu bounds
    await gesture.moveTo(menuRect.topLeft - const Offset(200, 200));
    await tester.pump();

    // Scale should remain 1.0 when swiping is disabled
    expect(getScale(tester), moreOrLessEquals(1.0, epsilon: 0.001));

    await gesture.moveTo(menuRect.bottomRight + const Offset(200, 200));
    await tester.pump();

    // Scale should still remain 1.0
    expect(getScale(tester), moreOrLessEquals(1.0, epsilon: 0.001));

    // Move to menu item and verify no special swipe behavior occurs
    await gesture.moveTo(tester.getCenter(find.text(Tag.a.text)));
    await tester.pump(const Duration(milliseconds: 500));

    // Menu should still be open since swipe is disabled
    expect(controller.isOpen, isTrue);

    await gesture.up();
    await tester.pump();
  });

  testWidgets('Mobile menu width (< 768 px)', (WidgetTester tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(765, 900)),
        child: App(
          CupertinoMenuAnchor(
            controller: controller,
            menuChildren: <Widget>[MenuItem.tag(Tag.a)],
            child: const AnchorButton(Tag.anchor),
          ),
        ),
      ),
    );

    controller.open();
    await tester.pump();
    await tester.pumpAndSettle();

    final Size popupSize = tester.getSize(find.byType(CupertinoPopupSurface));
    expect(popupSize.width, moreOrLessEquals(250, epsilon: 0.1));
  });

  testWidgets('Tablet menu width (>= 768 px)', (WidgetTester tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(768, 400)),
        child: App(
          CupertinoMenuAnchor(
            controller: controller,
            menuChildren: <Widget>[MenuItem.tag(Tag.a)],
            child: const AnchorButton(Tag.anchor),
          ),
        ),
      ),
    );

    controller.open();
    await tester.pump();
    await tester.pumpAndSettle();

    final Size popupSize = tester.getSize(find.byType(CupertinoPopupSurface));
    expect(popupSize.width, moreOrLessEquals(262, epsilon: 0.1));
  });

  testWidgets('Accessible mobile menu width (< 768 px)', (WidgetTester tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(765, 900), textScaleFactor: 1 + 11 / 17),
        child: App(
          CupertinoMenuAnchor(
            controller: controller,
            menuChildren: <Widget>[MenuItem.tag(Tag.a)],
            child: const AnchorButton(Tag.anchor),
          ),
        ),
      ),
    );

    controller.open();
    await tester.pump();
    await tester.pumpAndSettle();

    final Size popupSize = tester.getSize(find.byType(CupertinoPopupSurface));
    expect(popupSize.width, moreOrLessEquals(370, epsilon: 0.1));
  });

  testWidgets('Accessible tablet menu width (>= 768 px)', (WidgetTester tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(768, 400), textScaleFactor: 1 + 11 / 17),
        child: App(
          CupertinoMenuAnchor(
            controller: controller,
            menuChildren: <Widget>[MenuItem.tag(Tag.a)],
            child: const AnchorButton(Tag.anchor),
          ),
        ),
      ),
    );

    controller.open();
    await tester.pump();
    await tester.pumpAndSettle();

    final Size popupSize = tester.getSize(find.byType(CupertinoPopupSurface));
    expect(popupSize.width, moreOrLessEquals(343, epsilon: 0.1));
  });

  testWidgets('Menu scale animation respects reduceMotion', (WidgetTester tester) async {
    await tester.pumpWidget(
      App(
        CupertinoMenuAnchor(
          controller: controller,
          menuChildren: <Widget>[MenuItem.tag(Tag.a)],
          child: const AnchorButton(Tag.anchor),
        ),
      ),
    );

    controller.open();
    await tester.pump();

    final double baselineScale = getScale(tester);
    expect(baselineScale, lessThan(1));

    controller.close();
    await tester.pumpAndSettle();

    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(reduceMotion: true);
    addTearDown(tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pump();

    controller.open();
    await tester.pump();

    final double reducedScale = getScale(tester);
    expect(reducedScale, moreOrLessEquals(1, epsilon: 0.01));
  });

  testWidgets('Menu fade animation is disabled when animations are off', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      App(
        CupertinoMenuAnchor(
          controller: controller,
          menuChildren: <Widget>[MenuItem.tag(Tag.a)],
          child: const AnchorButton(Tag.anchor),
        ),
      ),
    );

    controller.open();
    await tester.pump();

    final FadeTransition baselineFade = tester.widget<FadeTransition>(
      find.ancestor(of: find.byType(CupertinoPopupSurface), matching: find.byType(FadeTransition)),
    );

    expect(baselineFade.opacity.value, lessThan(0.5));

    controller.close();
    await tester.pump();

    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pump();

    controller.open();
    await tester.pump();

    final FadeTransition disabledFade = tester.widget<FadeTransition>(
      find.ancestor(of: find.byType(CupertinoPopupSurface), matching: find.byType(FadeTransition)),
    );
    expect(disabledFade.opacity.value, moreOrLessEquals(1, epsilon: 0.01));
  });

  group('Focus', () {
    testWidgets(
      'Focus wraps when traversing with arrow keys on non-Apple platforms',
      (WidgetTester tester) async {
        final FocusNode anchorFocusNode = FocusNode();
        final FocusNode firstItemFocusNode = FocusNode();
        final FocusNode lastItemFocusNode = FocusNode();
        addTearDown(anchorFocusNode.dispose);
        addTearDown(firstItemFocusNode.dispose);
        addTearDown(lastItemFocusNode.dispose);

        await tester.pumpWidget(
          App(
            CupertinoMenuAnchor(
              controller: controller,
              menuChildren: <Widget>[
                MenuItem.tag(Tag.a, focusNode: firstItemFocusNode),
                MenuItem.tag(Tag.b),
                MenuItem.tag(Tag.c, focusNode: lastItemFocusNode),
              ],
              child: AnchorButton(Tag.anchor, focusNode: anchorFocusNode),
            ),
          ),
        );

        controller.open();
        await tester.pump();
        await tester.pump(kMenuOpenDuration);

        firstItemFocusNode.requestFocus();
        await tester.pump();

        expect(FocusManager.instance.primaryFocus, firstItemFocusNode);

        // Arrow up from first item should wrap to last item
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump();

        expect(FocusManager.instance.primaryFocus, lastItemFocusNode);

        // Arrow down from last item should wrap to first item
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();

        expect(FocusManager.instance.primaryFocus, firstItemFocusNode);
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.android,
        TargetPlatform.fuchsia,
        TargetPlatform.linux,
        TargetPlatform.windows,
      }),
    );

    testWidgets(
      'Focus does not wrap when traversing with arrow keys on Apple platforms',
      (WidgetTester tester) async {
        final FocusNode anchorFocusNode = FocusNode();
        final FocusNode firstItemFocusNode = FocusNode();
        final FocusNode lastItemFocusNode = FocusNode();
        addTearDown(anchorFocusNode.dispose);
        addTearDown(firstItemFocusNode.dispose);
        addTearDown(lastItemFocusNode.dispose);

        await tester.pumpWidget(
          App(
            CupertinoMenuAnchor(
              controller: controller,
              menuChildren: <Widget>[
                MenuItem.tag(Tag.a, focusNode: firstItemFocusNode),
                MenuItem.tag(Tag.b),
                MenuItem.tag(Tag.c, focusNode: lastItemFocusNode),
              ],
              child: AnchorButton(Tag.anchor, focusNode: anchorFocusNode),
            ),
          ),
        );

        controller.open();
        await tester.pump();
        await tester.pump(kMenuOpenDuration);

        firstItemFocusNode.requestFocus();
        await tester.pump();

        expect(FocusManager.instance.primaryFocus, firstItemFocusNode);

        // Arrow up from first item should not move focus on Apple platforms
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump();

        expect(FocusManager.instance.primaryFocus, firstItemFocusNode);

        lastItemFocusNode.requestFocus();
        await tester.pump();

        // Arrow down from last item should not move focus on Apple platforms
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();

        expect(FocusManager.instance.primaryFocus, lastItemFocusNode);
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      }),
    );

    testWidgets('Menu items can be activated with enter key', (WidgetTester tester) async {
      final FocusNode anchorFocusNode = FocusNode();
      final FocusNode aFocusNode = FocusNode();
      bool itemActivated = false;
      addTearDown(anchorFocusNode.dispose);
      addTearDown(aFocusNode.dispose);

      await tester.pumpWidget(
        App(
          CupertinoMenuAnchor(
            controller: controller,
            menuChildren: <Widget>[
              MenuItem.tag(
                Tag.a,
                focusNode: aFocusNode,
                onPressed: () {
                  itemActivated = true;
                },
              ),
            ],
            child: AnchorButton(Tag.anchor, focusNode: anchorFocusNode),
          ),
        ),
      );

      controller.open();
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      aFocusNode.requestFocus();
      await tester.pump();

      expect(FocusManager.instance.primaryFocus, aFocusNode);
      expect(itemActivated, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(itemActivated, isTrue);
    });

    testWidgets('Menu closes with escape key', (WidgetTester tester) async {
      final FocusNode anchorFocusNode = FocusNode();
      final FocusNode aFocusNode = FocusNode();
      addTearDown(anchorFocusNode.dispose);
      addTearDown(aFocusNode.dispose);

      await tester.pumpWidget(
        App(
          CupertinoMenuAnchor(
            controller: controller,
            menuChildren: <Widget>[MenuItem.tag(Tag.a, focusNode: aFocusNode)],
            child: AnchorButton(Tag.anchor, focusNode: anchorFocusNode),
          ),
        ),
      );

      controller.open();
      await tester.pump();
      await tester.pumpAndSettle();

      aFocusNode.requestFocus();
      await tester.pump();

      expect(controller.isOpen, isTrue);
      expect(FocusManager.instance.primaryFocus, aFocusNode);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      expect(controller.isOpen, isFalse);
    });

    testWidgets('Up and down arrow keys move focus between menu items', (
      WidgetTester tester,
    ) async {
      final FocusNode anchorFocusNode = FocusNode();
      final FocusNode aFocusNode = FocusNode();
      final FocusNode bFocusNode = FocusNode();
      final FocusNode cFocusNode = FocusNode();
      addTearDown(anchorFocusNode.dispose);
      addTearDown(aFocusNode.dispose);
      addTearDown(bFocusNode.dispose);
      addTearDown(cFocusNode.dispose);

      await tester.pumpWidget(
        App(
          CupertinoMenuAnchor(
            controller: controller,
            menuChildren: <Widget>[
              MenuItem.tag(Tag.a, focusNode: aFocusNode),
              MenuItem.tag(Tag.b, focusNode: bFocusNode),
              MenuItem.tag(Tag.c, focusNode: cFocusNode),
            ],
            child: AnchorButton(Tag.anchor, focusNode: anchorFocusNode),
          ),
        ),
      );

      controller.open();
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      aFocusNode.requestFocus();
      await tester.pump();

      expect(FocusManager.instance.primaryFocus, aFocusNode);

      // Arrow down should move to next item
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(FocusManager.instance.primaryFocus, bFocusNode);

      // Arrow down should move to next item
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(FocusManager.instance.primaryFocus, cFocusNode);

      // Arrow up should move to previous item
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      expect(FocusManager.instance.primaryFocus, bFocusNode);

      // Arrow up should move to previous item
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      expect(FocusManager.instance.primaryFocus, aFocusNode);
    });

    testWidgets('Focus returns to button after menu closes', (WidgetTester tester) async {
      final FocusNode anchorFocusNode = FocusNode();
      final FocusNode aFocusNode = FocusNode();
      addTearDown(anchorFocusNode.dispose);
      addTearDown(aFocusNode.dispose);

      await tester.pumpWidget(
        App(
          CupertinoMenuAnchor(
            controller: controller,
            childFocusNode: anchorFocusNode,
            menuChildren: <Widget>[MenuItem.tag(Tag.a, focusNode: aFocusNode)],
            child: AnchorButton(Tag.anchor, focusNode: anchorFocusNode),
          ),
        ),
      );

      anchorFocusNode.requestFocus();
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      controller.open();
      await tester.pump();

      aFocusNode.requestFocus();
      await tester.pump();

      expect(FocusManager.instance.primaryFocus, aFocusNode);

      // Close menu with escape
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(controller.isOpen, isFalse);
      expect(FocusManager.instance.primaryFocus, anchorFocusNode);
    });

    testWidgets('Left and right arrow keys do not move focus in menu', (WidgetTester tester) async {
      final FocusNode anchorFocusNode = FocusNode();
      final FocusNode aFocusNode = FocusNode();
      final FocusNode bFocusNode = FocusNode();
      addTearDown(anchorFocusNode.dispose);
      addTearDown(aFocusNode.dispose);
      addTearDown(bFocusNode.dispose);

      await tester.pumpWidget(
        App(
          CupertinoMenuAnchor(
            controller: controller,
            menuChildren: <Widget>[
              MenuItem.tag(Tag.a, focusNode: aFocusNode),
              MenuItem.tag(Tag.b, focusNode: bFocusNode),
            ],
            child: AnchorButton(Tag.anchor, focusNode: anchorFocusNode),
          ),
        ),
      );

      controller.open();
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      aFocusNode.requestFocus();
      await tester.pump();

      expect(FocusManager.instance.primaryFocus, aFocusNode);

      // Left arrow should not change focus
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      expect(FocusManager.instance.primaryFocus, aFocusNode);

      // Right arrow should not change focus
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(FocusManager.instance.primaryFocus, aFocusNode);
    });

    testWidgets('Down key after menu opens focuses the first menu item', (
      WidgetTester tester,
    ) async {
      final FocusNode anchorFocusNode = FocusNode();
      final FocusNode firstItemFocusNode = FocusNode();
      final FocusNode secondItemFocusNode = FocusNode();
      addTearDown(anchorFocusNode.dispose);
      addTearDown(firstItemFocusNode.dispose);
      addTearDown(secondItemFocusNode.dispose);

      await tester.pumpWidget(
        App(
          CupertinoMenuAnchor(
            controller: controller,
            menuChildren: <Widget>[
              MenuItem.tag(Tag.a, focusNode: firstItemFocusNode),
              MenuItem.tag(Tag.b, focusNode: secondItemFocusNode),
            ],
            child: AnchorButton(Tag.anchor, focusNode: anchorFocusNode),
          ),
        ),
      );

      // Focus the anchor button first
      anchorFocusNode.requestFocus();
      await tester.pump();

      expect(FocusManager.instance.primaryFocus, anchorFocusNode);

      // Open the menu
      controller.open();
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      // Press down arrow key - should focus first menu item
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(FocusManager.instance.primaryFocus, firstItemFocusNode);
    });

    testWidgets('Up key after open focuses the last menu item', (WidgetTester tester) async {
      final FocusNode anchorFocusNode = FocusNode();
      final FocusNode firstItemFocusNode = FocusNode();
      final FocusNode lastItemFocusNode = FocusNode();
      addTearDown(anchorFocusNode.dispose);
      addTearDown(firstItemFocusNode.dispose);
      addTearDown(lastItemFocusNode.dispose);

      await tester.pumpWidget(
        App(
          CupertinoMenuAnchor(
            controller: controller,
            menuChildren: <Widget>[
              MenuItem.tag(Tag.a, focusNode: firstItemFocusNode),
              MenuItem.tag(Tag.b),
              MenuItem.tag(Tag.c, focusNode: lastItemFocusNode),
            ],
            child: AnchorButton(Tag.anchor, focusNode: anchorFocusNode),
          ),
        ),
      );

      // Focus the anchor button first
      anchorFocusNode.requestFocus();
      await tester.pump();

      expect(FocusManager.instance.primaryFocus, anchorFocusNode);

      // Open the menu
      controller.open();
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      // Press up arrow key - should focus last menu item
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      expect(FocusManager.instance.primaryFocus, lastItemFocusNode);
    });

    testWidgets('Home key moves focus to first menu item', (WidgetTester tester) async {
      final FocusNode anchorFocusNode = FocusNode();
      final FocusNode firstItemFocusNode = FocusNode();
      final FocusNode middleItemFocusNode = FocusNode();
      final FocusNode lastItemFocusNode = FocusNode();
      addTearDown(anchorFocusNode.dispose);
      addTearDown(firstItemFocusNode.dispose);
      addTearDown(middleItemFocusNode.dispose);
      addTearDown(lastItemFocusNode.dispose);

      await tester.pumpWidget(
        App(
          CupertinoMenuAnchor(
            controller: controller,
            menuChildren: <Widget>[
              MenuItem.tag(Tag.a, focusNode: firstItemFocusNode),
              MenuItem.tag(Tag.b, focusNode: middleItemFocusNode),
              MenuItem.tag(Tag.c, focusNode: lastItemFocusNode),
            ],
            child: AnchorButton(Tag.anchor, focusNode: anchorFocusNode),
          ),
        ),
      );

      controller.open();
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      lastItemFocusNode.requestFocus();
      await tester.pump();

      expect(FocusManager.instance.primaryFocus, lastItemFocusNode);

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();

      expect(FocusManager.instance.primaryFocus, firstItemFocusNode);
    });

    testWidgets('End key moves focus to last menu item', (WidgetTester tester) async {
      final FocusNode anchorFocusNode = FocusNode();
      final FocusNode firstItemFocusNode = FocusNode();
      final FocusNode middleItemFocusNode = FocusNode();
      final FocusNode lastItemFocusNode = FocusNode();
      addTearDown(anchorFocusNode.dispose);
      addTearDown(firstItemFocusNode.dispose);
      addTearDown(middleItemFocusNode.dispose);
      addTearDown(lastItemFocusNode.dispose);

      await tester.pumpWidget(
        App(
          CupertinoMenuAnchor(
            controller: controller,
            menuChildren: <Widget>[
              MenuItem.tag(Tag.a, focusNode: firstItemFocusNode),
              MenuItem.tag(Tag.b, focusNode: middleItemFocusNode),
              MenuItem.tag(Tag.c, focusNode: lastItemFocusNode),
            ],
            child: AnchorButton(Tag.anchor, focusNode: anchorFocusNode),
          ),
        ),
      );

      controller.open();
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      firstItemFocusNode.requestFocus();
      await tester.pump();

      expect(FocusManager.instance.primaryFocus, firstItemFocusNode);

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();

      expect(FocusManager.instance.primaryFocus, lastItemFocusNode);
    });
  });

  group('Layout', () {
    final List<AlignmentGeometry> alignments = <AlignmentGeometry>[
      for (double x = -2; x <= 2; x += 1)
        for (double y = -2; y <= 2; y += 1) Alignment(x, y),
      for (double x = -2; x <= 2; x += 1)
        for (double y = -2; y <= 2; y += 1) AlignmentDirectional(x, y),
    ];

    /// Returns the rects of the menu's contents. If [clipped] is true, the
    /// rect is taken after UnconstrainedBox clips its contents.
    List<Rect> collectOverlays({bool clipped = true}) {
      final List<Rect> menuRects = <Rect>[];
      final Finder finder = clipped
          ? find.byType(UnconstrainedBox)
          : find.byType(CupertinoPopupSurface);
      for (final Element candidate in finder.evaluate().toList()) {
        final RenderBox box = candidate.renderObject! as RenderBox;
        final Offset topLeft = box.localToGlobal(box.size.topLeft(Offset.zero));
        menuRects.add(topLeft & box.size);
      }
      return menuRects;
    }

    testWidgets('LTR alignment', (WidgetTester tester) async {
      Widget buildApp({AlignmentGeometry? alignment}) {
        return App(
          CupertinoMenuAnchor(
            alignment: alignment,
            overlayPadding: EdgeInsets.zero,
            menuAlignment: Alignment.center,
            menuChildren: <Widget>[
              Container(
                width: 250,
                height: 50,
                color: const Color(0xFF0000FF),
                child: Text(Tag.a.text),
              ),
            ],
            child: const AnchorButton(Tag.anchor),
          ),
        );
      }

      await tester.pumpWidget(buildApp());
      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      // Anchor position is fixed.
      final ui.Rect anchorRect = tester.getRect(
        find.widgetWithText(CupertinoButton, Tag.anchor.text),
      );

      for (final AlignmentGeometry alignment in alignments) {
        await tester.pumpWidget(buildApp(alignment: alignment));
        final ui.Rect overlay = tester.getRect(find.widgetWithText(Container, Tag.a.text).first);
        expect(
          alignment.resolve(TextDirection.ltr).withinRect(anchorRect),
          offsetMoreOrLessEquals(overlay.center, epsilon: 0.01),
          reason:
              'Anchor alignment: $alignment \n'
              'Menu rect: $overlay \n',
        );
      }
    });

    testWidgets('RTL alignment', (WidgetTester tester) async {
      Widget buildApp({AlignmentGeometry? alignment}) {
        return App(
          textDirection: TextDirection.rtl,
          CupertinoMenuAnchor(
            overlayPadding: EdgeInsets.zero,
            alignment: alignment,
            menuAlignment: Alignment.center,
            menuChildren: <Widget>[
              Container(
                width: 100,
                height: 50,
                color: const Color(0xFF0000FF),
                child: Text(Tag.a.text),
              ),
            ],
            child: const AnchorButton(Tag.anchor),
          ),
        );
      }

      await tester.pumpWidget(buildApp());
      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      // Anchor position is fixed.
      final ui.Rect anchorRect = tester.getRect(
        find.widgetWithText(CupertinoButton, Tag.anchor.text),
      );

      for (final AlignmentGeometry alignment in alignments) {
        await tester.pumpWidget(buildApp(alignment: alignment));
        final ui.Rect overlay = tester.getRect(find.widgetWithText(Container, Tag.a.text).first);
        expect(
          alignment.resolve(TextDirection.rtl).withinRect(anchorRect),
          offsetMoreOrLessEquals(overlay.center, epsilon: 0.01),
          reason:
              'Anchor alignment: $alignment \n'
              'Menu rect: $overlay \n',
        );
      }
    });

    testWidgets('LTR menu alignment', (WidgetTester tester) async {
      const Size size = Size(800, 600);
      await changeSurfaceSize(tester, size);

      Widget buildApp({AlignmentGeometry? alignment}) {
        return App(
          CupertinoMenuAnchor(
            alignment: Alignment.center,
            menuAlignment: alignment,
            overlayPadding: EdgeInsets.zero,
            menuChildren: <Widget>[
              Container(
                width: 350,
                height: 50,
                alignment: Alignment.center,
                color: const Color(0xFF0000FF),
                child: Text(Tag.a.text),
              ),
            ],
            child: const AnchorButton(Tag.anchor),
          ),
        );
      }

      await tester.pumpWidget(buildApp());
      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      for (final AlignmentGeometry alignment in alignments) {
        for (double y = -2; y <= 2; y += 1) {
          await tester.pumpWidget(buildApp(alignment: alignment));
          final ui.Rect overlay = tester.getRect(find.widgetWithText(Container, Tag.a.text).first);

          expect(
            alignment.resolve(TextDirection.ltr).withinRect(overlay),
            offsetMoreOrLessEquals(size.center(Offset.zero), epsilon: 0.01),
            reason:
                'Menu alignment: $alignment \n'
                'Menu rect: $overlay \n',
          );
        }
      }
    });

    testWidgets('RTL menu alignment', (WidgetTester tester) async {
      const Size size = Size(800, 600);
      await changeSurfaceSize(tester, size);
      Widget buildApp({AlignmentGeometry? alignment}) {
        return App(
          textDirection: TextDirection.rtl,
          CupertinoMenuAnchor(
            alignment: Alignment.center,
            menuAlignment: alignment,
            overlayPadding: EdgeInsets.zero,
            menuChildren: <Widget>[
              Container(
                width: 350,
                height: 50,
                color: const Color(0xFF0000FF),
                child: Text(Tag.a.text),
              ),
            ],
            child: const AnchorButton(Tag.anchor),
          ),
        );
      }

      await tester.pumpWidget(buildApp());
      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      for (final AlignmentGeometry alignment in alignments) {
        await tester.pumpWidget(buildApp(alignment: alignment));
        final ui.Rect overlay = tester.getRect(find.widgetWithText(Container, Tag.a.text).first);
        expect(
          alignment.resolve(TextDirection.rtl).withinRect(overlay),
          offsetMoreOrLessEquals(size.center(Offset.zero), epsilon: 0.01),
          reason:
              'Menu alignment: $alignment \n'
              'Menu rect: $overlay \n',
        );
      }
    });

    testWidgets('default alignment', (WidgetTester tester) async {
      const Size size = Size(2000, 2000);
      await changeSurfaceSize(tester, size);

      Widget buildApp({required AlignmentGeometry alignment}) {
        return App(
          CupertinoMenuAnchor(
            overlayPadding: EdgeInsets.zero,
            menuAlignment: Alignment.center,
            constraints: BoxConstraints.tight(const Size(50, 50)),
            menuChildren: <Widget>[
              Container(
                width: 50,
                height: 50,
                color: const Color(0xFF0000FF),
                child: Text(Tag.a.text),
              ),
            ],
            child: const AnchorButton(
              Tag.anchor,
              constraints: BoxConstraints.tightFor(width: 50, height: 50),
            ),
          ),
          alignment: alignment,
        );
      }

      await tester.pumpWidget(buildApp(alignment: Alignment.topCenter));
      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      for (double horizontal = -0.8; horizontal <= 0.8; horizontal += 0.15) {
        for (double vertical = -0.8; vertical <= 0.8; vertical += 0.15) {
          await tester.pumpWidget(buildApp(alignment: Alignment(horizontal, vertical)));
          final double x = switch (horizontal) {
            < -0.2 => -1.0,
            > 0.2 => 1.0,
            _ => 0.0,
          };

          final double y = vertical < 0.2 ? 1.0 : -1.0;
          final Alignment alignment = Alignment(x, y);
          final ui.Rect anchorRect = tester.getRect(
            find.widgetWithText(CupertinoButton, Tag.anchor.text),
          );

          final ui.Rect surface = tester.getRect(find.widgetWithText(Container, Tag.a.text));
          final ui.Offset position = alignment.resolve(TextDirection.ltr).withinRect(anchorRect);

          expect(
            position,
            offsetMoreOrLessEquals(surface.center, epsilon: 0.01),
            reason:
                'Anchor alignment: ${Alignment(horizontal, vertical)} \n'
                'Menu rect: $surface \n',
          );
        }
      }
    });

    testWidgets('RTL menu top-center attaches to anchor bottom-center by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          alignment: Alignment.topCenter,
          textDirection: TextDirection.rtl,
          CupertinoMenuAnchor(
            overlayPadding: EdgeInsets.zero,
            menuChildren: <Widget>[
              Container(width: 100, height: 100, color: const Color(0xFF00FF00)),
            ],
            child: const AnchorButton(Tag.anchor),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      final Offset anchorBottomCenter = tester
          .getRect(find.widgetWithText(CupertinoButton, Tag.anchor.text))
          .bottomCenter;

      expect(
        anchorBottomCenter,
        offsetMoreOrLessEquals(collectOverlays().first.topCenter, epsilon: 0.01),
      );
    });

    testWidgets('alignmentOffset is not directional by default', (WidgetTester tester) async {
      const ui.Offset offset = Offset(24, 33);

      Widget buildApp({
        Offset alignmentOffset = Offset.zero,
        ui.TextDirection textDirection = ui.TextDirection.ltr,
      }) {
        return App(
          textDirection: textDirection,
          CupertinoMenuAnchor(
            overlayPadding: EdgeInsets.zero,
            alignmentOffset: alignmentOffset,
            menuChildren: <Widget>[
              Container(
                width: 250,
                height: 66,
                alignment: Alignment.center,
                color: const Color(0xFF0000FF),
                child: Text(Tag.a.text),
              ),
            ],
            child: const AnchorButton(Tag.anchor),
          ),
        );
      }

      await tester.pumpWidget(buildApp());
      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      final Rect ltrPosition = collectOverlays().first;

      await tester.pumpWidget(buildApp(alignmentOffset: offset));

      final Rect ltrPositionTwo = collectOverlays().first;

      expect(ltrPositionTwo, rectMoreOrLessEquals(ltrPosition.shift(offset), epsilon: 0.01));

      await tester.pumpWidget(buildApp(textDirection: ui.TextDirection.rtl));

      final Rect rtlPosition = collectOverlays().first;

      await tester.pumpWidget(
        buildApp(alignmentOffset: offset, textDirection: ui.TextDirection.rtl),
      );

      final Rect rtlPositionTwo = collectOverlays().first;

      expect(rtlPositionTwo, rectMoreOrLessEquals(rtlPosition.shift(offset), epsilon: 0.01));
    });

    testWidgets('LTR alignmentOffset', (WidgetTester tester) async {
      const ui.Offset offset = Offset(24, 33);

      Widget buildApp({
        Offset alignmentOffset = Offset.zero,
        AlignmentGeometry anchorAlignment = Alignment.center,
      }) {
        return App(
          CupertinoMenuAnchor(
            overlayPadding: EdgeInsets.zero,
            alignmentOffset: alignmentOffset,
            alignment: anchorAlignment,
            menuAlignment: Alignment.center,
            menuChildren: <Widget>[
              Container(
                width: 125,
                height: 66,
                alignment: Alignment.center,
                color: const Color(0xFF0000FF),
                child: Text(Tag.a.text),
              ),
            ],
            child: const AnchorButton(Tag.anchor),
          ),
        );
      }

      await tester.pumpWidget(buildApp());

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      final Rect center = collectOverlays().first;

      await tester.pumpWidget(buildApp(alignmentOffset: offset));

      expect(center.shift(offset), rectMoreOrLessEquals(collectOverlays().first, epsilon: 0.01));

      await tester.pumpWidget(buildApp(alignmentOffset: -offset));

      expect(center.shift(-offset), rectMoreOrLessEquals(collectOverlays().first, epsilon: 0.01));
    });

    testWidgets('RTL alignmentOffset', (WidgetTester tester) async {
      // Should be the same as LTR alignmentOffset test.
      const ui.Offset offset = Offset(24, 33);

      Widget buildApp({
        Offset alignmentOffset = Offset.zero,
        AlignmentGeometry anchorAlignment = Alignment.center,
      }) {
        return App(
          textDirection: ui.TextDirection.rtl,
          CupertinoMenuAnchor(
            overlayPadding: EdgeInsets.zero,
            alignmentOffset: alignmentOffset,
            alignment: anchorAlignment,
            menuAlignment: Alignment.center,
            menuChildren: <Widget>[
              Container(
                width: 125,
                height: 66,
                alignment: Alignment.center,
                color: const Color(0xFF0000FF),
                child: Text(Tag.a.text),
              ),
            ],
            child: const AnchorButton(Tag.anchor),
          ),
        );
      }

      await tester.pumpWidget(buildApp());

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      final Rect center = collectOverlays().first;

      await tester.pumpWidget(buildApp(alignmentOffset: offset));

      expect(center.shift(offset), rectMoreOrLessEquals(collectOverlays().first, epsilon: 0.01));

      await tester.pumpWidget(buildApp(alignmentOffset: -offset));

      expect(center.shift(-offset), rectMoreOrLessEquals(collectOverlays().first, epsilon: 0.01));
    });

    testWidgets(
      'LTR alignmentOffset.dx does not change when menuAlignment is an AlignmentDirectional',
      (WidgetTester tester) async {
        const ui.Offset offset = Offset(24, 33);

        Widget buildApp({
          AlignmentGeometry alignment = Alignment.center,
          Offset alignmentOffset = Offset.zero,
        }) {
          return App(
            CupertinoMenuAnchor(
              overlayPadding: EdgeInsets.zero,
              alignmentOffset: alignmentOffset,
              alignment: alignment,
              menuAlignment: Alignment.center,
              menuChildren: <Widget>[
                Container(
                  width: 50,
                  height: 66,
                  color: const Color(0xFF0000FF),
                  child: Text(Tag.a.text),
                ),
              ],
              child: const AnchorButton(
                Tag.anchor,
                constraints: BoxConstraints.tightFor(width: 125, height: 66),
              ),
            ),
          );
        }

        await tester.pumpWidget(buildApp());

        await tester.tap(find.text(Tag.anchor.text));
        await tester.pump();
        await tester.pump(kMenuOpenDuration);

        final Rect center = collectOverlays().first;

        await tester.pumpWidget(buildApp(alignmentOffset: offset));

        final Rect centerOffset = collectOverlays().first;

        // Switching from Alignment.center to AlignmentDirectional.center won't
        // relayout the menu, so pump an empty offset to trigger a relayout.
        await tester.pumpWidget(buildApp());

        await tester.pumpWidget(
          buildApp(alignmentOffset: offset, alignment: AlignmentDirectional.center),
        );

        final Rect centerDirectionalOffset = collectOverlays().first;

        expect(centerOffset, rectMoreOrLessEquals(center.shift(offset), epsilon: 0.01));
        expect(centerDirectionalOffset, rectMoreOrLessEquals(centerOffset, epsilon: 0.01));
      },
    );

    testWidgets('RTL alignmentOffset.dx is negated when alignment is an AlignmentDirectional', (
      WidgetTester tester,
    ) async {
      const ui.Offset offset = Offset(24, 33);

      Widget buildApp({
        AlignmentGeometry alignment = Alignment.center,
        Offset alignmentOffset = Offset.zero,
      }) {
        return App(
          textDirection: ui.TextDirection.rtl,
          CupertinoMenuAnchor(
            controller: controller,
            overlayPadding: EdgeInsets.zero,
            alignmentOffset: alignmentOffset,
            alignment: alignment,
            menuAlignment: Alignment.center,
            menuChildren: <Widget>[
              Container(
                width: 50,
                height: 66,
                color: const Color(0xFF0000FF),
                child: Text(Tag.a.text),
              ),
            ],
            child: const AnchorButton(Tag.anchor),
          ),
        );
      }

      await tester.pumpWidget(buildApp());
      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      final Rect center = collectOverlays().first;

      await tester.pumpWidget(buildApp(alignmentOffset: offset));

      final Rect centerOffset = collectOverlays().first;

      // Switching from Alignment.center to AlignmentDirectional.center won't
      // relayout the menu, so pump an empty offset to trigger a relayout.
      await tester.pumpWidget(buildApp());

      await tester.pumpWidget(
        buildApp(alignmentOffset: offset, alignment: AlignmentDirectional.center),
      );

      final Rect centerDirectionalOffset = collectOverlays().first;

      expect(centerOffset, rectMoreOrLessEquals(center.shift(offset), epsilon: 0.01));
      expect(
        centerDirectionalOffset,
        rectMoreOrLessEquals(center.shift(Offset(-offset.dx, offset.dy)), epsilon: 0.01),
      );
    });

    testWidgets(
      'RTL alignmentOffset.dx is not negated when menuAlignment is an AlignmentDirectional',
      (WidgetTester tester) async {
        const ui.Offset offset = Offset(24, 33);

        Widget buildApp({
          AlignmentGeometry alignment = Alignment.center,
          Offset alignmentOffset = Offset.zero,
        }) {
          return App(
            textDirection: ui.TextDirection.rtl,
            CupertinoMenuAnchor(
              overlayPadding: EdgeInsets.zero,
              menuAlignment: alignment,
              alignmentOffset: alignmentOffset,
              alignment: Alignment.center,
              menuChildren: <Widget>[
                Container(
                  width: 50,
                  height: 66,
                  color: const Color(0xFF0000FF),
                  child: Text(Tag.a.text),
                ),
              ],
              child: const AnchorButton(Tag.anchor),
            ),
          );
        }

        await tester.pumpWidget(buildApp());
        await tester.tap(find.text(Tag.anchor.text));
        await tester.pump();
        await tester.pump(kMenuOpenDuration);

        final Rect center = collectOverlays().first;

        await tester.pumpWidget(buildApp(alignmentOffset: offset));

        final Rect centerOffset = collectOverlays().first;

        // Switching from Alignment.center to AlignmentDirectional.center won't
        // relayout the menu, so pump an empty offset to trigger a relayout.
        await tester.pumpWidget(buildApp());

        await tester.pumpWidget(
          buildApp(alignmentOffset: offset, alignment: AlignmentDirectional.center),
        );

        final Rect centerDirectionalOffset = collectOverlays().first;

        expect(centerOffset, rectMoreOrLessEquals(center.shift(offset), epsilon: 0.01));
        expect(centerDirectionalOffset, rectMoreOrLessEquals(centerOffset, epsilon: 0.01));
      },
    );

    testWidgets('LTR constrained and offset menu placement', (WidgetTester tester) async {
      await changeSurfaceSize(tester, const Size(200, 200));
      const BoxConstraints constraints = BoxConstraints.tightFor(width: 100, height: 100);

      await tester.pumpWidget(
        App(
          CupertinoMenuAnchor(
            overlayPadding: EdgeInsets.zero,
            alignmentOffset: const Offset(-100, 100),
            constraints: constraints,
            menuChildren: <Widget>[
              Container(color: const Color(0xFF0000FF), constraints: constraints),
            ],
            child: const AnchorButton(Tag.anchor, constraints: constraints),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      expect(
        collectOverlays().first,
        rectMoreOrLessEquals(const Rect.fromLTRB(0, 100, 100, 200), epsilon: 0.01),
      );
    });

    testWidgets('RTL constrained and offset menu placement', (WidgetTester tester) async {
      await changeSurfaceSize(tester, const Size(200, 200));
      const BoxConstraints constraints = BoxConstraints.tightFor(width: 100, height: 100);

      await tester.pumpWidget(
        App(
          textDirection: TextDirection.rtl,
          CupertinoMenuAnchor(
            overlayPadding: EdgeInsets.zero,
            alignmentOffset: const Offset(-100, 100),
            constraints: constraints,
            menuChildren: <Widget>[
              Container(color: const Color(0xFF0000FF), constraints: constraints),
            ],
            child: const AnchorButton(Tag.anchor, constraints: constraints),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.pump(kMenuOpenDuration);
      final List<ui.Rect> overlays = collectOverlays();
      expect(overlays, hasLength(1));
      expect(
        overlays.first,
        rectMoreOrLessEquals(const Rect.fromLTRB(0.0, 100.0, 100.0, 200.0), epsilon: 0.01),
      );
    });

    testWidgets('LTR constrained menu placement with unconstrained crossaxis', (
      WidgetTester tester,
    ) async {
      await changeSurfaceSize(tester, const Size(200, 200));

      await tester.pumpWidget(
        App(
          CupertinoMenuAnchor(
            overlayPadding: EdgeInsets.zero,
            menuChildren: <Widget>[Container(color: const Color(0xFFFF0000), height: 40)],
            child: const AnchorButton(Tag.anchor),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      final List<ui.Rect> overlays = collectOverlays(clipped: false);
      expect(overlays, hasLength(1));

      // The unclipped menu surface can grow beyond the screen. Since this
      // example is LTR, the left edge of the screen should be flush with the
      // left edge of the menu surface.
      //
      // In this demo, the screen width is 200, the surface width is 250, and
      // the content width is 300. The surface width should equal 250, starting
      // the left edge (0px).
      expect(
        overlays.first,
        rectMoreOrLessEquals(const Rect.fromLTRB(-0.0, 124.5, 262.0, 164.5), epsilon: 0.01),
      );
    });

    testWidgets('RTL constrained menu placement with unconstrained crossaxis', (
      WidgetTester tester,
    ) async {
      await changeSurfaceSize(tester, const Size(200, 200));

      await tester.pumpWidget(
        App(
          textDirection: TextDirection.rtl,
          CupertinoMenuAnchor(
            overlayPadding: EdgeInsets.zero,
            menuChildren: <Widget>[Container(color: const Color(0xFFFF0000), height: 40)],
            child: const AnchorButton(Tag.anchor),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      final List<ui.Rect> overlays = collectOverlays(clipped: false);
      expect(overlays, hasLength(1));

      // The unclipped menu surface can grow beyond the screen. Since we are
      // RTL, the right edge of the screen should be flush with the right edge
      // of the menu surface.
      //
      // In this demo, the screen width is 200, the surface width is 250, and
      // the content width is 300. The surface width should equal 250, ending
      // at the right edge (200px).
      expect(
        overlays.first,
        rectMoreOrLessEquals(const Rect.fromLTRB(-62.0, 124.5, 200.0, 164.5), epsilon: 0.01),
      );
    });

    testWidgets('LTR constrained menu placement with constrained crossaxis', (
      WidgetTester tester,
    ) async {
      await changeSurfaceSize(tester, const Size(200, 200));
      const BoxConstraints constraints = BoxConstraints.tightFor(width: 300, height: 40);

      await tester.pumpWidget(
        App(
          CupertinoMenuAnchor(
            constrainCrossAxis: true,
            overlayPadding: EdgeInsets.zero,
            menuChildren: <Widget>[MenuItem.tag(Tag.a, constraints: constraints)],
            child: const AnchorButton(Tag.anchor, constraints: constraints),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      final List<ui.Rect> overlays = collectOverlays(clipped: false);

      expect(overlays, hasLength(1));

      // The unclipped menu surface will not grow beyond the screen.
      expect(
        overlays.first,
        rectMoreOrLessEquals(const Rect.fromLTRB(0.0, 124.5, 200.0, 164.5), epsilon: 0.01),
      );
    });

    testWidgets('RTL constrained menu placement with constrained crossaxis', (
      WidgetTester tester,
    ) async {
      await changeSurfaceSize(tester, const Size(200, 200));
      const BoxConstraints constraints = BoxConstraints.tightFor(width: 300, height: 40);

      await tester.pumpWidget(
        App(
          textDirection: TextDirection.rtl,
          CupertinoMenuAnchor(
            constrainCrossAxis: true,
            overlayPadding: EdgeInsets.zero,
            menuChildren: <Widget>[MenuItem.tag(Tag.a, constraints: constraints)],
            child: const AnchorButton(Tag.anchor, constraints: constraints),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pumpAndSettle();

      final List<ui.Rect> overlays = collectOverlays(clipped: false);

      expect(overlays, hasLength(1));

      // The unclipped menu surface will not grow beyond the screen.
      expect(
        overlays.first,
        rectMoreOrLessEquals(const Rect.fromLTRB(0.0, 124.5, 200.0, 164.5), epsilon: 0.01),
      );
    });

    testWidgets('Constraints applied to anchor do not affect overlay', (WidgetTester tester) async {
      await tester.pumpWidget(
        App(
          alignment: Alignment.topLeft,
          ConstrainedBox(
            constraints: const BoxConstraints.tightFor(width: 60, height: 60),
            child: CupertinoMenuAnchor(
              overlayPadding: EdgeInsets.zero,
              menuChildren: <Widget>[Container(color: const Color(0xFFFF0000), height: 100)],
              child: const AnchorButton(Tag.anchor),
            ),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pumpAndSettle();

      expect(collectOverlays().first.size, sizeCloseTo(const Size(262.0, 100.0), 0.01));
    });

    testWidgets('LTR menu position flips to left when overflowing screen right', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          alignment: const Alignment(0.5, 0),
          CupertinoMenuAnchor(
            overlayPadding: EdgeInsets.zero,
            alignment: Alignment.topRight,
            menuAlignment: const Alignment(-0.75, -0.75),
            menuChildren: <Widget>[
              Container(width: 350, height: 100, color: const Color(0x86FF00FF)),
            ],
            child: const AnchorButton(Tag.anchor),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      final [ui.Rect menu] = collectOverlays();
      final ui.Rect anchor = tester.getRect(find.widgetWithText(CupertinoButton, Tag.anchor.text));
      expect(
        const Alignment(0.75, -0.75).withinRect(menu),
        offsetMoreOrLessEquals(anchor.topLeft, epsilon: 0.1),
      );
    });

    testWidgets('RTL menu position flips to left when overflowing screen right', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          textDirection: TextDirection.rtl,
          alignment: const Alignment(0.5, 0),
          CupertinoMenuAnchor(
            overlayPadding: EdgeInsets.zero,
            alignment: Alignment.topRight,
            menuAlignment: const Alignment(-0.75, -0.75),
            menuChildren: <Widget>[
              Container(width: 350, height: 100, color: const Color(0x86FF00FF)),
            ],
            child: const AnchorButton(Tag.anchor),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      final [ui.Rect menu] = collectOverlays();
      final Offset anchorTopLeft = tester.getTopLeft(
        find.widgetWithText(CupertinoButton, Tag.anchor.text),
      );
      expect(
        const Alignment(0.75, -0.75).withinRect(menu),
        offsetMoreOrLessEquals(anchorTopLeft, epsilon: 0.1),
      );
    });

    testWidgets('LTR menu position flips to right when overflowing screen left', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          alignment: const Alignment(-0.5, 0),
          CupertinoMenuAnchor(
            overlayPadding: EdgeInsets.zero,
            alignment: Alignment.topLeft,
            menuAlignment: const Alignment(0.75, -0.75),
            menuChildren: <Widget>[
              Container(width: 350, height: 100, color: const Color(0x86FF00FF)),
            ],
            child: const AnchorButton(Tag.anchor),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      final [ui.Rect menu] = collectOverlays();
      final ui.Offset anchorTopRight = tester.getTopRight(
        find.widgetWithText(CupertinoButton, Tag.anchor.text),
      );
      expect(
        const Alignment(-0.75, -0.75).withinRect(menu),
        offsetMoreOrLessEquals(anchorTopRight, epsilon: 0.01),
      );
    });

    testWidgets('RTL menu position flips to right when overflowing screen left', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          textDirection: TextDirection.rtl,
          alignment: const Alignment(-0.5, 0),
          CupertinoMenuAnchor(
            overlayPadding: EdgeInsets.zero,
            alignment: Alignment.topLeft,
            menuAlignment: const Alignment(0.75, -0.75),
            menuChildren: <Widget>[
              Container(width: 350, height: 100, color: const Color(0x86FF00FF)),
            ],
            child: const AnchorButton(Tag.anchor),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      final [ui.Rect menu] = collectOverlays();
      final ui.Offset anchorTopRight = tester.getTopRight(
        find.widgetWithText(CupertinoButton, Tag.anchor.text),
      );
      expect(
        const Alignment(-0.75, -0.75).withinRect(menu),
        offsetMoreOrLessEquals(anchorTopRight, epsilon: 0.01),
      );
    });

    testWidgets(
      'Menus that overflow the same screen edge when flipped are placed against that edge',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          App(
            CupertinoMenuAnchor(
              overlayPadding: EdgeInsets.zero,
              controller: controller,
              menuAlignment: Alignment.center,
              constraints: const BoxConstraints.tightFor(width: 100, height: 100),
              menuChildren: <Widget>[
                Container(width: 100, height: 100, color: const Color(0x86FF00FF)),
              ],
              child: const Stack(
                children: <Widget>[Positioned.fill(child: ColoredBox(color: Color(0xff00ff00)))],
              ),
            ),
          ),
        );

        controller.open(position: const Offset(750, 50));
        await tester.pump();
        await tester.pump(kMenuOpenDuration);

        // Overflow top and right, so the menu should be placed against the top
        // right corner.
        expect(
          collectOverlays().first,
          rectMoreOrLessEquals(const Rect.fromLTRB(700, 0, 800, 100), epsilon: 0.01),
        );

        controller.open(position: const Offset(50, 550));
        await tester.pump();

        // Overflow bottom and left, so the menu should be placed against the bottom
        // left corner.
        expect(
          collectOverlays().first,
          rectMoreOrLessEquals(const Rect.fromLTRB(0, 500, 100, 600), epsilon: 0.01),
        );
      },
    );

    testWidgets(
      'Menu attaches to closest vertical edge of anchor when overflowing screen left and right',
      (WidgetTester tester) async {
        await changeSurfaceSize(tester, const Size(200, 200));
        await tester.pumpWidget(
          App(
            // Overlaps the bottom of the anchor by 4px.
            CupertinoMenuAnchor(
              overlayPadding: EdgeInsets.zero,
              alignmentOffset: const Offset(0, -4),
              alignment: AlignmentDirectional.bottomEnd,
              menuAlignment: AlignmentDirectional.topStart,
              menuChildren: <Widget>[
                Container(
                  key: const Key('menu'),
                  width: 250,
                  height: 30,
                  color: const Color(0xFFFF00FF),
                ),
              ],
              child: const AnchorButton(
                Tag.anchor,
                constraints: BoxConstraints.tightFor(width: 125, height: 30),
              ),
            ),
          ),
        );

        await tester.tap(find.text(Tag.anchor.text));
        await tester.pump();
        await tester.pump(kMenuOpenDuration);

        final Rect anchor = tester.getRect(find.widgetWithText(CupertinoButton, Tag.anchor.text));
        final Rect panel = tester.getRect(find.byKey(const Key('menu')));

        expect(anchor.bottom, moreOrLessEquals(panel.top, epsilon: 0.01));
      },
    );

    testWidgets('Menu flips above anchor when overflowing screen bottom', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          alignment: const Alignment(0, 0.5),
          CupertinoMenuAnchor(
            overlayPadding: EdgeInsets.zero,
            alignmentOffset: const Offset(0, -8),
            alignment: Alignment.bottomCenter,
            menuAlignment: Alignment.topCenter,
            menuChildren: <Widget>[
              Container(width: 225, height: 230, color: const Color(0xFFFF00FF)),
            ],
            child: const AnchorButton(Tag.anchor),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      final Rect anchor = tester.getRect(find.widgetWithText(CupertinoButton, Tag.anchor.text));
      expect(collectOverlays().first.bottom, moreOrLessEquals(anchor.top + 8, epsilon: 0.01));
    });

    testWidgets('Menu flips below anchor when overflowing screen top', (WidgetTester tester) async {
      await tester.pumpWidget(
        App(
          alignment: const Alignment(0, -0.8),
          CupertinoMenuAnchor(
            overlayPadding: EdgeInsets.zero,
            alignment: AlignmentDirectional.topCenter,
            menuAlignment: AlignmentDirectional.bottomCenter,
            alignmentOffset: const Offset(0, -8),
            menuChildren: <Widget>[
              Container(width: 225, height: 230, color: const Color(0xFFFF00FF)),
            ],
            child: const AnchorButton(Tag.anchor),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      final Rect anchor = tester.getRect(find.widgetWithText(CupertinoButton, Tag.anchor.text));
      expect(collectOverlays().first.top, moreOrLessEquals(anchor.bottom + 8, epsilon: 0.01));
    });

    testWidgets('alignmentOffset is reflected across anchor when menu flips', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          alignment: const Alignment(0.8, 0.8),
          CupertinoMenuAnchor(
            overlayPadding: EdgeInsets.zero,
            alignment: Alignment.center,
            menuAlignment: Alignment.center,
            alignmentOffset: const Offset(200, 200),
            constraints: const BoxConstraints.tightFor(width: 50, height: 50),
            menuChildren: <Widget>[
              Container(width: 50, height: 50, color: const Color(0xFFFF00FF)),
            ],
            child: const AnchorButton(
              Tag.anchor,
              constraints: BoxConstraints.tightFor(width: 50, height: 50),
            ),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      final Offset anchorCenter = tester.getCenter(
        find.widgetWithText(CupertinoButton, Tag.anchor.text),
      );
      expect(
        collectOverlays().first.center,
        offsetMoreOrLessEquals(anchorCenter - const Offset(200, 200), epsilon: 0.01),
      );
    });

    testWidgets('Alignment is reflected across anchor when menu flips', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          alignment: const AlignmentDirectional(0.95, 0.95),
          CupertinoMenuAnchor(
            overlayPadding: EdgeInsets.zero,
            alignment: AlignmentDirectional.bottomEnd,
            menuAlignment: Alignment.center,
            menuChildren: <Widget>[
              Container(width: 50, height: 50, color: const Color(0xFFFF00FF)),
            ],
            child: const AnchorButton(Tag.anchor),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      final Offset anchorTopLeft = tester.getTopLeft(
        find.widgetWithText(CupertinoButton, Tag.anchor.text),
      );
      expect(collectOverlays().first.center, offsetMoreOrLessEquals(anchorTopLeft, epsilon: 0.01));
    });

    testWidgets('The menuAlignment of a flipped menu is reflected across the anchor midpoint', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          alignment: const AlignmentDirectional(0.95, 0.95),
          CupertinoMenuAnchor(
            overlayPadding: EdgeInsets.zero,
            alignment: Alignment.center,
            menuAlignment: AlignmentDirectional.topStart,
            constraints: const BoxConstraints.tightFor(width: 50, height: 50),
            menuChildren: <Widget>[
              Container(width: 50, height: 50, color: const Color(0xFFFF00FF)),
            ],
            child: const AnchorButton(Tag.anchor),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      final Offset anchorCenter = tester.getCenter(
        find.widgetWithText(CupertinoButton, Tag.anchor.text),
      );
      expect(
        collectOverlays().first.bottomLeft,
        offsetMoreOrLessEquals(anchorCenter, epsilon: 0.01),
      );
    });

    testWidgets(
      'Menus opened with a position apply the positional offset relative to the top left corner of the anchor',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 600));

        Widget buildApp([TextDirection textDirection = TextDirection.ltr]) {
          return App(
            textDirection: textDirection,
            CupertinoMenuAnchor(
              controller: controller,
              overlayPadding: EdgeInsets.zero,
              alignment: Alignment.topLeft,
              menuAlignment: Alignment.topCenter,
              menuChildren: <Widget>[
                Container(color: const Color(0xFFFF0000), height: 100, width: 100),
              ],
              child: Container(width: 100, height: 100, color: const ui.Color(0xFF00FF00)),
            ),
          );
        }

        await tester.pumpWidget(buildApp());

        controller.open();
        await tester.pump();
        await tester.pump(kMenuOpenDuration);

        final ui.Rect control = collectOverlays().first;

        controller.open(position: const Offset(33, 45));
        await tester.pump();

        expect(
          collectOverlays().first,
          rectMoreOrLessEquals(control.shift(const Offset(33, 45)), epsilon: 0.01),
        );

        // Should not be affected by text direction.
        await tester.pumpWidget(buildApp(TextDirection.rtl));

        expect(
          collectOverlays().first,
          rectMoreOrLessEquals(control.shift(const Offset(33, 45)), epsilon: 0.01),
        );

        controller.open(position: const Offset(45, 75));
        await tester.pump();

        expect(
          collectOverlays().first,
          rectMoreOrLessEquals(control.shift(const Offset(45, 75)), epsilon: 0.01),
        );
      },
    );

    testWidgets('Menus opened with a position ignore `alignmentOffset`', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));

      await tester.pumpWidget(
        App(
          CupertinoMenuAnchor(
            controller: controller,
            overlayPadding: EdgeInsets.zero,
            alignmentOffset: const Offset(33, 45),
            alignment: Alignment.topLeft,
            menuAlignment: Alignment.topCenter,
            constraints: const BoxConstraints(),
            menuChildren: <Widget>[
              Container(color: const Color(0xFFFF0000), height: 100, width: 100),
            ],
            child: Container(width: 100, height: 100, color: const ui.Color(0xFF00FF00)),
          ),
        ),
      );

      controller.open();
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      // Get position with alignmentOffset.
      final ui.Rect control = collectOverlays().first;

      controller.open(position: Offset.zero);
      await tester.pump();

      // Alignment offset should be removed.
      expect(
        collectOverlays().first,
        rectMoreOrLessEquals(control.shift(const Offset(-33, -45)), epsilon: 0.01),
      );
    });

    testWidgets('Menus opened with a position ignore `alignment`', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));

      await tester.pumpWidget(
        App(
          CupertinoMenuAnchor(
            controller: controller,
            overlayPadding: EdgeInsets.zero,
            alignment: Alignment.bottomRight,
            menuAlignment: Alignment.topLeft,
            constraints: const BoxConstraints(),
            menuChildren: <Widget>[
              Container(color: const Color(0xFFFF0000), height: 100, width: 100),
            ],
            child: Container(width: 100, height: 100, color: const ui.Color(0xFF00FF00)),
          ),
        ),
      );
      controller.open();
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      // Get position with alignmentOffset.
      final ui.Rect control = collectOverlays().first;

      controller.open(position: Offset.zero);
      await tester.pump();

      // A positioned menu is placed relative to the top left corner of the
      // anchor. The anchor is 100x100, and the alignment is set to
      // bottom-right, so setting the position to
      // Offset.zero should offset the menu by -100 x -100.
      expect(
        collectOverlays().first,
        rectMoreOrLessEquals(control.shift(const Offset(-100, -100)), epsilon: 0.1),
      );
    });

    testWidgets('Menus opened with a position respect the menuAlignment property', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          CupertinoMenuAnchor(
            controller: controller,
            overlayPadding: EdgeInsets.zero,
            alignment: Alignment.topLeft,
            menuAlignment: Alignment.center,
            constraints: const BoxConstraints(),
            menuChildren: <Widget>[
              Container(color: const Color(0xFFFF0000), height: 100, width: 100),
            ],
            child: Container(width: 100, height: 100, color: const ui.Color(0xFF00FF00)),
          ),
        ),
      );
      controller.open();
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      // Get position with alignmentOffset.
      final ui.Rect control = collectOverlays().first;

      controller.open(position: const Offset(100, 100));
      await tester.pump();

      // A positioned menu is placed relative to the top left corner of the
      // anchor. The anchor is 100x100, and the alignment is set to
      // bottom-right, so setting the position to
      // Offset.zero should offset the menu by -100 x -100.
      expect(
        collectOverlays().first,
        rectMoreOrLessEquals(control.shift(const Offset(100, 100)), epsilon: 0.01),
      );
    });

    testWidgets('Menus opened with a position flip relative to an empty rect at `position`', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        App(
          CupertinoMenuAnchor(
            controller: controller,
            overlayPadding: EdgeInsets.zero,
            menuAlignment: Alignment.topLeft,
            constraints: const BoxConstraints(maxHeight: 100),
            menuChildren: <Widget>[
              Container(color: const ui.Color(0xFF2200FF), height: 100, width: 100),
            ],
            child: const Stack(
              fit: StackFit.expand,
              children: <Widget>[ColoredBox(color: ui.Color(0xFFFFC800))],
            ),
          ),
        ),
      );

      controller.open(position: const Offset(700, 500));
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      // The menu should be placed at the `position` argument, and should
      // fit within the overlay without flipping.
      expect(
        collectOverlays().first,
        rectMoreOrLessEquals(const Offset(700, 500) & const Size(100, 100), epsilon: 0.01),
      );

      // Overflow right and bottom by 50 pixels.
      controller.open(position: const Offset(750, 550));
      await tester.pump();

      // The menu should horizontally and vertically overflow the overlay,
      // leading to the menu surface flipping across the menu position.
      expect(
        collectOverlays().first,
        rectMoreOrLessEquals(const Offset(650, 450) & const Size(100, 100), epsilon: 0.01),
      );
    });

    testWidgets('LTR app and anchor padding', (WidgetTester tester) async {
      // Out of App:
      //    - overlay position affected
      //    - anchor position affected
      // In App:
      //    - anchor position affected
      //
      // Padding inside App DOES NOT affect the overlay position but
      // DOES affect the anchor position.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(31, 7, 43, 0),
            child: App(
              alignment: Alignment.topLeft,
              Padding(
                padding: const EdgeInsets.fromLTRB(21, 11, 17, 0),
                child: CupertinoMenuAnchor(
                  overlayPadding: EdgeInsets.zero,
                  alignment: Alignment.center,
                  menuAlignment: Alignment.center,
                  menuChildren: <Widget>[
                    Container(color: const Color(0xFF0000FF), height: 200, width: 200),
                  ],
                  child: const AnchorButton(Tag.anchor),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pumpAndSettle();

      final Offset overlay = collectOverlays().single.topLeft;
      final Offset anchor = tester.getTopLeft(find.widgetWithText(AnchorButton, Tag.anchor.text));

      expect(anchor, offsetMoreOrLessEquals(const Offset(31 + 21, 7 + 11), epsilon: 0.01));
      expect(overlay, offsetMoreOrLessEquals(const Offset(31, 7), epsilon: 0.01));
    });

    testWidgets('Menu is positioned around display features', (WidgetTester tester) async {
      // A 20-pixel wide vertical display feature, similar to a
      // foldable with a visible hinge. Splits the display into two
      // "virtual screens".
      const ui.DisplayFeature displayFeature = ui.DisplayFeature(
        bounds: Rect.fromLTRB(390, 0, 410, 1000),
        type: ui.DisplayFeatureType.cutout,
        state: ui.DisplayFeatureState.unknown,
      );

      await tester.pumpWidget(
        App(
          MediaQuery(
            data: const MediaQueryData(
              platformBrightness: Brightness.dark,
              displayFeatures: <ui.DisplayFeature>[displayFeature],
            ),
            child: ColoredBox(
              color: const Color(0xFF004CFF),
              child: Stack(
                children: <Widget>[
                  // Pink box for visualizing the display feature.
                  Positioned.fromRect(
                    rect: displayFeature.bounds,
                    child: const ColoredBox(color: Color(0xF7FF2190)),
                  ),
                  const Positioned(
                    left: 400,
                    top: 0,
                    child: CupertinoMenuAnchor(
                      overlayPadding: EdgeInsets.zero,
                      alignment: Alignment.center,
                      menuAlignment: Alignment.center,
                      menuChildren: <Widget>[SizedBox(width: 100, height: 50)],
                      child: AnchorButton(Tag.anchor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      final double menuLeft = collectOverlays().first.left;

      // Since the display feature splits the display into 2 sub-screens, the
      // menu should be positioned to fit against the second virtual screen. The
      // menu is positioned with its left edge at the right edge of the display
      // feature, which is at 410 pixels.
      expect(menuLeft, moreOrLessEquals(410, epsilon: 0.01));
    });

    testWidgets('Menu constraints are applied to menu surface', (WidgetTester tester) async {
      await tester.pumpWidget(
        App(
          CupertinoMenuAnchor(
            overlayPadding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 75, maxHeight: 100),
            menuChildren: <Widget>[
              Container(key: Tag.a.key, color: const Color(0xFFFF0000), height: 150, width: 50),
            ],
            child: const AnchorButton(Tag.anchor),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.pump(kMenuOpenDuration);
      final ui.Rect overlay = collectOverlays().first;
      expect(overlay.size, sizeCloseTo(const Size(75, 100), 1));

      // Width and height should be maintained
      expect(tester.getSize(find.byKey(Tag.a.key)), sizeCloseTo(const Size(50, 150), 1));

      // The container should be centered in the overlay.
      expect(
        tester.getTopLeft(find.byKey(Tag.a.key)),
        offsetMoreOrLessEquals(overlay.topLeft + const Offset(12.5, 0), epsilon: 0.01),
      );
    });

    testWidgets('Menu is positioned in the root overlay when useRootOverlay is true', (
      WidgetTester tester,
    ) async {
      // The menu should not overflow the bottom of the root overlay, so the
      // menu should be placed below the anchor button.
      final OverlayEntry entry = OverlayEntry(
        builder: (BuildContext context) {
          return Positioned(
            bottom: 0,
            child: CupertinoMenuAnchor(
              overlayPadding: EdgeInsets.zero,
              useRootOverlay: true,
              menuChildren: <Widget>[Container(height: 100, color: const Color(0xFF00FF00))],
              child: const AnchorButton(Tag.anchor),
            ),
          );
        },
      );

      // Overlay entries leak if they are not disposed.
      addTearDown(() {
        entry.remove();
        entry.dispose();
      });

      await tester.pumpWidget(
        App(
          Stack(
            children: <Widget>[
              Positioned(
                height: 200,
                width: 200,
                child: ColoredBox(
                  color: const Color(0xFFFF0000),
                  child: Overlay(initialEntries: <OverlayEntry>[entry]),
                ),
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      final [ui.Rect menu] = collectOverlays();
      final Rect anchor = tester.getRect(find.widgetWithText(CupertinoButton, Tag.anchor.text));

      expect(menu.topLeft, offsetMoreOrLessEquals(anchor.bottomLeft, epsilon: 0.01));
    });

    testWidgets(
      'Menu is positioned within the closest ancestor overlay when useRootOverlay is false',
      (WidgetTester tester) async {
        // The menu should overflow the bottom of the nearest ancestor overlay, so
        // the menu should be placed above the anchor button.
        final OverlayEntry entry = OverlayEntry(
          builder: (BuildContext context) {
            return Positioned(
              bottom: 0,
              child: CupertinoMenuAnchor(
                overlayPadding: EdgeInsets.zero,
                menuChildren: <Widget>[Container(height: 100, color: const Color(0xFF00FF00))],
                child: const AnchorButton(Tag.anchor),
              ),
            );
          },
        );

        // Overlay entries leak if they are not disposed.
        addTearDown(() {
          entry.remove();
          entry.dispose();
        });

        await tester.pumpWidget(
          App(
            Stack(
              children: <Widget>[
                Positioned(
                  height: 200,
                  width: 200,
                  child: ColoredBox(
                    color: const Color(0xFFFF0000),
                    child: Overlay(initialEntries: <OverlayEntry>[entry]),
                  ),
                ),
              ],
            ),
          ),
        );

        await tester.tap(find.text(Tag.anchor.text));
        await tester.pump();
        await tester.pump(kMenuOpenDuration);

        final [ui.Rect menu] = collectOverlays();
        final Rect anchor = tester.getRect(find.widgetWithText(CupertinoButton, Tag.anchor.text));

        expect(menu.bottomLeft, offsetMoreOrLessEquals(anchor.topLeft, epsilon: 0.01));
      },
    );
  });

  group('CupertinoMenuEntryMixin', () {
    App buildApp(List<Widget> children) {
      return App(
        CupertinoMenuAnchor(
          controller: controller,
          menuChildren: children,
          child: const AnchorButton(Tag.anchor),
        ),
      );
    }

    testWidgets('dividers respect allowLeadingSeparator and allowTrailingSeparator', (
      WidgetTester tester,
    ) async {
      Widget entry({required bool leading, required bool trailing, Widget? child}) {
        return _DebugCupertinoMenuEntryMixin(
          allowLeadingSeparator: leading,
          allowTrailingSeparator: trailing,
          child: child ?? const SizedBox(),
        );
      }

      await tester.pumpWidget(
        buildApp(<Widget>[
          entry(leading: true, trailing: true, child: Text(Tag.a.text)),
          entry(leading: true, trailing: true, child: Text(Tag.b.text)),
          entry(leading: true, trailing: true, child: Text(Tag.c.text)),
        ]),
      );

      controller.open();
      await tester.pumpAndSettle();

      // Borders are drawn below menu items.
      List<Widget> children = findMenuChildren(tester);
      expect(children.length, 5);
      expect(children[0], isA<_DebugCupertinoMenuEntryMixin>());
      expect(children[2], isA<_DebugCupertinoMenuEntryMixin>());
      expect(children[4], isA<_DebugCupertinoMenuEntryMixin>());

      // First item should never have a leading separator and bottom item should
      // never have a trailing separator.
      await tester.pumpWidget(
        buildApp(<Widget>[
          entry(leading: false, trailing: true, child: Text(Tag.a.text)),
          entry(leading: true, trailing: true, child: Text(Tag.b.text)),
          entry(leading: true, trailing: false, child: Text(Tag.c.text)),
        ]),
      );

      children = findMenuChildren(tester);
      expect(children.length, 5);
      expect(children[0], isA<_DebugCupertinoMenuEntryMixin>());
      expect(children[2], isA<_DebugCupertinoMenuEntryMixin>());
      expect(children[4], isA<_DebugCupertinoMenuEntryMixin>());

      await tester.pumpWidget(
        buildApp(<Widget>[
          entry(leading: true, trailing: false, child: Text(Tag.a.text)),
          entry(leading: true, trailing: true, child: Text(Tag.b.text)),
          entry(leading: true, trailing: true, child: Text(Tag.c.text)),
        ]),
      );

      children = findMenuChildren(tester);
      // item 0: trailing == false so no separator is drawn after
      expect(children.length, 4);
      expect(children[0], isA<_DebugCupertinoMenuEntryMixin>());
      expect(children[1], isA<_DebugCupertinoMenuEntryMixin>());
      expect(children[3], isA<_DebugCupertinoMenuEntryMixin>());

      await tester.pumpWidget(
        buildApp(<Widget>[
          entry(leading: true, trailing: true, child: Text(Tag.a.text)),
          entry(leading: false, trailing: true, child: Text(Tag.b.text)),
          entry(leading: true, trailing: true, child: Text(Tag.c.text)),
        ]),
      );

      children = findMenuChildren(tester);
      // item 1: leading == false so no separator should be drawn before it
      expect(children.length, 4);
      expect(children[0], isA<_DebugCupertinoMenuEntryMixin>());
      expect(children[1], isA<_DebugCupertinoMenuEntryMixin>());
      expect(children[3], isA<_DebugCupertinoMenuEntryMixin>());

      await tester.pumpWidget(
        buildApp(<Widget>[
          entry(leading: true, trailing: true, child: Text(Tag.a.text)),
          entry(leading: true, trailing: false, child: Text(Tag.b.text)),
          entry(leading: true, trailing: true, child: Text(Tag.c.text)),
        ]),
      );

      children = findMenuChildren(tester);
      // item 1: trailing == false so no separator should be drawn after it
      expect(children.length, 4);
      expect(children[0], isA<_DebugCupertinoMenuEntryMixin>());
      expect(children[2], isA<_DebugCupertinoMenuEntryMixin>());
      expect(children[3], isA<_DebugCupertinoMenuEntryMixin>());
    });

    testWidgets('hasLeading aligns sibling CupertinoMenuItems', (WidgetTester tester) async {
      Widget buildApp({bool hasLeading = false}) {
        return App(
          CupertinoMenuAnchor(
            controller: controller,
            menuChildren: <Widget>[
              CupertinoMenuItem(key: Tag.a.key, child: Text(Tag.a.text)),
              _DebugCupertinoMenuEntryMixin(hasLeading: hasLeading),
            ],
          ),
        );
      }

      await tester.pumpWidget(buildApp());

      controller.open();
      await tester.pumpAndSettle();

      expect(tester.widget<CupertinoMenuItem>(find.byKey(Tag.a.key)).hasLeading, isFalse);

      final Offset childOffsetWithoutLeading = tester.getTopLeft(find.text(Tag.a.text));

      await tester.pumpWidget(buildApp(hasLeading: true));

      expect(tester.widget<CupertinoMenuItem>(find.byKey(Tag.a.key)).hasLeading, isFalse);

      final Offset childOffsetWithLeading = tester.getTopLeft(find.text(Tag.a.text));

      expect(
        childOffsetWithLeading - childOffsetWithoutLeading,
        offsetMoreOrLessEquals(const Offset(16, 0.0), epsilon: 0.01),
      );
    });
  });

  group('CupertinoMenuLargeDivider', () {
    testWidgets('dimensions', (WidgetTester tester) async {
      await tester.pumpWidget(const App(alignment: Alignment.topLeft, CupertinoLargeMenuDivider()));

      expect(
        tester.getRect(find.byType(CupertinoLargeMenuDivider)),
        rectMoreOrLessEquals(const Rect.fromLTRB(0.0, 0.0, 800.0, 8.0), epsilon: 0.01),
      );

      await tester.pumpWidget(
        App(
          CupertinoMenuAnchor(
            controller: controller,
            menuChildren: <Widget>[
              CupertinoMenuItem(key: Tag.a.key, child: Text(Tag.a.text)),
              const CupertinoLargeMenuDivider(),
            ],
          ),
        ),
      );

      controller.open();
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      final ui.Rect menuItemRect = tester.getRect(find.byType(CupertinoMenuItem));

      expect(
        tester.getRect(find.byType(CupertinoLargeMenuDivider)),
        rectMoreOrLessEquals(
          ui.Rect.fromLTWH(menuItemRect.left, menuItemRect.bottom, menuItemRect.width, 8.0),
          epsilon: 0.01,
        ),
      );
    });

    testWidgets('color', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.light),
          home: CupertinoLargeMenuDivider(key: Tag.a.key),
        ),
      );

      final Finder coloredBoxFinder = find.descendant(
        of: find.byKey(Tag.a.key),
        matching: find.byType(ColoredBox),
      );

      expect(
        tester.widget<ColoredBox>(coloredBoxFinder).color,
        isSameColorAs(const Color.fromRGBO(0, 0, 0, 0.08)),
      );

      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.dark),
          home: CupertinoLargeMenuDivider(key: Tag.a.key),
        ),
      );

      expect(
        tester.widget<ColoredBox>(coloredBoxFinder).color,
        isSameColorAs(const Color.fromRGBO(0, 0, 0, 0.16)),
      );
    });

    testWidgets('no adjacent borders are drawn', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.light),
          home: CupertinoMenuAnchor(
            controller: controller,
            menuChildren: const <Widget>[
              _DebugCupertinoMenuEntryMixin(allowTrailingSeparator: true),
              CupertinoLargeMenuDivider(),
              _DebugCupertinoMenuEntryMixin(allowLeadingSeparator: true),
            ],
          ),
        ),
      );

      controller.open();
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoLargeMenuDivider), findsOneWidget);
      expect(findMenuChildren(tester), hasLength(3));
    });
  });

  group('CupertinoMenuItem', () {
    const ui.Color defaultLightTextColor = ui.Color.from(alpha: 0.96, red: 0, green: 0, blue: 0);
    const ui.Color defaultDarkTextColor = ui.Color.from(alpha: 0.96, red: 1, green: 1, blue: 1);
    const ui.Color defaultSubtitleTextColor = ui.Color.from(alpha: 0.55, red: 0, green: 0, blue: 0);
    const ui.Color defaultSubtitleDarkTextColor = ui.Color.from(
      alpha: 0.4,
      red: 1,
      green: 1,
      blue: 1,
    );

    group('Appearance', () {
      testWidgets('leading style', (WidgetTester tester) async {
        RenderParagraph? findIcon() =>
            findDescendantParagraph(tester, find.byIcon(CupertinoIcons.check_mark));
        RenderParagraph? findText() => findDescendantParagraph(tester, find.text(Tag.a.text));

        Widget buildApp({
          TextScaler textScaler = TextScaler.noScaling,
          ui.Brightness brightness = ui.Brightness.light,
        }) {
          return CupertinoApp(
            theme: CupertinoThemeData(brightness: brightness),
            home: Builder(
              builder: (BuildContext context) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: textScaler),
                  child: CupertinoMenuAnchor(
                    controller: controller,
                    menuChildren: <Widget>[
                      CupertinoMenuItem(
                        leading: Stack(
                          children: <Widget>[
                            Text(Tag.a.text),
                            const Icon(CupertinoIcons.check_mark),
                          ],
                        ),
                        child: const Text('Menu Item'),
                        onPressed: () {},
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }

        await tester.pumpWidget(buildApp());
        controller.open();
        await tester.pumpAndSettle();

        final RenderParagraph? icon = findIcon();
        final RenderParagraph? text = findText();
        final TextStyle iconStyle = icon!.text.style!;
        final TextStyle textStyle = text!.text.style!;

        expect(icon.textSize, equals(const Size(15.0, 15.0)));
        expect(icon.textDirection, equals(TextDirection.ltr));
        expect(icon.maxLines, isNull);
        expect(iconStyle.color, isSameColorAs(defaultLightTextColor));
        expect(iconStyle.fontSize, equals(15.0));
        expect(iconStyle.leadingDistribution, equals(TextLeadingDistribution.even));
        expect(
          iconStyle.fontVariations,
          equals(<FontVariation>[
            const FontVariation('FILL', 0.0),
            const FontVariation.weight(600.0),
            const FontVariation('GRAD', 0.0),
            const FontVariation.opticalSize(48.0),
          ]),
        );

        expect(text.textScaler, equals(TextScaler.noScaling));
        expect(text.textDirection, equals(TextDirection.ltr));
        expect(text.maxLines, equals(2));
        expect(textStyle.fontSize, equals(15));
        expect(textStyle.color, isSameColorAs(defaultLightTextColor));
        expect(textStyle.fontWeight, equals(FontWeight.w600));

        await tester.pumpWidget(
          buildApp(textScaler: AccessibilityTextSize.xxxLarge, brightness: ui.Brightness.dark),
        );

        final RenderParagraph? icon6x = findIcon();
        final RenderParagraph? text6x = findText();
        final TextStyle iconStyle6x = icon6x!.text.style!;
        final TextStyle textStyle6x = text.text.style!;

        expect(iconStyle6x.fontSize, closeTo(20, 0.5));
        expect(iconStyle6x.color, isSameColorAs(defaultDarkTextColor));
        expect(text6x!.textScaler, equals(AccessibilityTextSize.xxxLarge));
        expect(textStyle6x.fontSize, equals(15));
        expect(textStyle6x.color, isSameColorAs(defaultDarkTextColor));

        await tester.pumpWidget(buildApp(textScaler: AccessibilityTextSize.ax1));

        expect(find.byIcon(CupertinoIcons.check_mark), findsOneWidget);
        expect(find.text(Tag.a.text), findsOneWidget);
      });

      testWidgets('trailing style', (WidgetTester tester) async {
        RenderParagraph? findIcon() =>
            findDescendantParagraph(tester, find.byIcon(CupertinoIcons.trash));
        RenderParagraph? findText() => findDescendantParagraph(tester, find.text(Tag.a.text));

        Widget buildApp({
          TextScaler textScaler = TextScaler.noScaling,
          ui.Brightness brightness = ui.Brightness.light,
        }) {
          return CupertinoApp(
            theme: CupertinoThemeData(brightness: brightness),
            home: Builder(
              builder: (BuildContext context) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: textScaler),
                  child: CupertinoMenuAnchor(
                    controller: controller,
                    menuChildren: <Widget>[
                      CupertinoMenuItem(
                        trailing: Stack(
                          children: <Widget>[Text(Tag.a.text), const Icon(CupertinoIcons.trash)],
                        ),
                        child: const Text('Menu Item'),
                        onPressed: () {},
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }

        await tester.pumpWidget(buildApp());

        controller.open();
        await tester.pumpAndSettle();

        final RenderParagraph? icon = findIcon();
        final RenderParagraph? text = findText();
        final TextStyle iconStyle = icon!.text.style!;
        final TextStyle textStyle = text!.text.style!;

        expect(icon.textDirection, equals(TextDirection.ltr));
        expect(icon.maxLines, isNull);
        expect(iconStyle.color, isSameColorAs(defaultLightTextColor));
        expect(iconStyle.fontSize, closeTo(21, 0.5));
        expect(iconStyle.leadingDistribution, equals(TextLeadingDistribution.even));
        expect(
          iconStyle.fontVariations,
          equals(<FontVariation>[
            const FontVariation('FILL', 0.0),
            const FontVariation.weight(400.0),
            const FontVariation('GRAD', 0.0),
            const FontVariation.opticalSize(48.0),
          ]),
        );

        expect(
          Offset.zero & text.textSize,
          rectMoreOrLessEquals(Offset.zero & const Size(20.6, 21), epsilon: 0.1),
        );
        expect(text.textScaler, equals(TextScaler.linear(AccessibilityTextSize.large.scale(1.24))));
        expect(text.textDirection, equals(TextDirection.ltr));
        expect(text.maxLines, equals(2));
        expect(textStyle.fontSize, closeTo(17, 0.5));
        expect(textStyle.color, isSameColorAs(defaultLightTextColor));
        expect(textStyle.fontWeight, equals(null));

        await tester.pumpWidget(
          buildApp(textScaler: AccessibilityTextSize.xxxLarge, brightness: ui.Brightness.dark),
        );

        final RenderParagraph? icon6x = findIcon();
        final RenderParagraph? text6x = findText();
        final TextStyle iconStyle6x = icon6x!.text.style!;
        final TextStyle textStyle6x = text.text.style!;

        expect(iconStyle6x.fontSize, closeTo(28.5, 0.5));
        expect(iconStyle6x.color, isSameColorAs(defaultDarkTextColor));
        expect(
          text6x!.textScaler,
          equals(TextScaler.linear(AccessibilityTextSize.xxxLarge.scale(1.24))),
        );
        expect(textStyle6x.fontSize, equals(17));
        expect(textStyle6x.color, isSameColorAs(defaultDarkTextColor));

        await tester.pumpWidget(
          buildApp(textScaler: AccessibilityTextSize.ax1, brightness: ui.Brightness.dark),
        );

        expect(find.byIcon(CupertinoIcons.trash), findsNothing);
        expect(find.text(Tag.a.text), findsNothing);
      });

      testWidgets('child style', (WidgetTester tester) async {
        RenderParagraph? findText() => findDescendantParagraph(tester, find.text(Tag.a.text));

        Widget buildApp({
          TextScaler textScaler = TextScaler.noScaling,
          ui.Brightness brightness = ui.Brightness.light,
        }) {
          return CupertinoApp(
            theme: CupertinoThemeData(brightness: brightness),
            home: Builder(
              builder: (BuildContext context) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: textScaler),
                  child: CupertinoMenuAnchor(
                    controller: controller,
                    menuChildren: <Widget>[
                      CupertinoMenuItem(child: Text(Tag.a.text), onPressed: () {}),
                    ],
                  ),
                );
              },
            ),
          );
        }

        await tester.pumpWidget(buildApp());

        controller.open();
        await tester.pumpAndSettle();

        final RenderParagraph? text = findText();
        final TextStyle textStyle = text!.text.style!;

        expect(text.textScaler, equals(TextScaler.noScaling));
        expect(text.textDirection, equals(TextDirection.ltr));
        expect(text.maxLines, equals(2));
        expect(textStyle.fontSize, equals(17));
        expect(textStyle.color, isSameColorAs(defaultLightTextColor));
        expect(textStyle.fontWeight, equals(null));

        for (final TextScaler size in AccessibilityTextSize.values) {
          await tester.pumpWidget(buildApp(textScaler: size));

          final TextStyle expectedTextStyle = _DynamicTypeStyle.body.resolveTextStyle(
            size,
            round: true,
          );
          final RenderParagraph textSized = findText()!;
          final TextStyle textStyle = textSized.text.style!;
          expect(textSized.textScaler, equals(size));
          expect(textStyle.fontSize, equals(17));
          expect(textStyle.letterSpacing, equals(expectedTextStyle.letterSpacing));
          expect(textStyle.height, equals(expectedTextStyle.height));
          expect(textStyle.fontFamily, equals(expectedTextStyle.fontFamily));
        }

        await tester.pumpWidget(buildApp(brightness: ui.Brightness.dark));

        expect(findText()!.text.style!.color, isSameColorAs(defaultDarkTextColor));
      });

      testWidgets('subtitle style', (WidgetTester tester) async {
        RenderParagraph? findText() => findDescendantParagraph(tester, find.text(Tag.a.text));

        Widget buildApp({
          TextScaler textScaler = TextScaler.noScaling,
          ui.Brightness brightness = ui.Brightness.light,
        }) {
          return CupertinoApp(
            theme: CupertinoThemeData(brightness: brightness),
            home: Builder(
              builder: (BuildContext context) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: textScaler),
                  child: CupertinoMenuAnchor(
                    controller: controller,
                    menuChildren: <Widget>[
                      CupertinoMenuItem(
                        subtitle: Text(Tag.a.text),
                        onPressed: () {},
                        child: const Text('Menu Item'),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }

        await tester.pumpWidget(buildApp());

        controller.open();
        await tester.pumpAndSettle();

        final RenderParagraph? text = findText();
        final TextStyle textStyle = text!.text.style!;

        expect(text.textScaler, equals(TextScaler.noScaling));
        expect(text.textDirection, equals(TextDirection.ltr));
        expect(text.maxLines, equals(2));
        expect(textStyle.fontSize, equals(15));
        expect(textStyle.fontWeight, isNull);
        expect(textStyle.color, isNull);
        expect(
          textStyle.foreground,
          isA<ui.Paint>()
              .having(
                (ui.Paint paint) => paint.color,
                'color',
                isSameColorAs(defaultSubtitleTextColor),
              )
              .having(
                (ui.Paint paint) => paint.blendMode,
                'blendMode',
                equals(BlendMode.hardLight),
              ),
        );

        for (final TextScaler size in AccessibilityTextSize.values) {
          await tester.pumpWidget(buildApp(textScaler: size));

          final TextStyle expectedTextStyle = _DynamicTypeStyle.subhead.resolveTextStyle(
            size,
            round: true,
          );
          final RenderParagraph textSized = findText()!;
          final TextStyle textStyle = textSized.text.style!;
          expect(textSized.textScaler, equals(size));
          expect(textStyle.fontSize, equals(15));
          expect(textStyle.letterSpacing, equals(expectedTextStyle.letterSpacing));
          expect(textStyle.height, equals(expectedTextStyle.height));
          expect(textStyle.fontFamily, equals(expectedTextStyle.fontFamily));
        }

        await tester.pumpWidget(buildApp(brightness: ui.Brightness.dark));

        final RenderParagraph? darkText = findText();
        final TextStyle darkTextStyle = darkText!.text.style!;

        expect(
          darkTextStyle.foreground,
          isA<ui.Paint>()
              .having(
                (ui.Paint paint) => paint.color,
                'color',
                isSameColorAs(defaultSubtitleDarkTextColor),
              )
              .having((ui.Paint paint) => paint.blendMode, 'blendMode', equals(BlendMode.plus)),
        );
      });

      testWidgets('isDestructiveAction style', (WidgetTester tester) async {
        RenderParagraph? findLeading() {
          return findDescendantParagraph(tester, find.byIcon(CupertinoIcons.left_chevron));
        }

        RenderParagraph? findTrailing() {
          return findDescendantParagraph(tester, find.byIcon(CupertinoIcons.right_chevron));
        }

        RenderParagraph? findChild() {
          return findDescendantParagraph(tester, find.text(Tag.a.text));
        }

        RenderParagraph? findSubtitle() {
          return findDescendantParagraph(tester, find.text(Tag.b.text));
        }

        Widget buildApp([ui.Brightness brightness = ui.Brightness.light]) {
          return CupertinoApp(
            home: CupertinoTheme(
              data: CupertinoThemeData(brightness: brightness),
              child: CupertinoMenuAnchor(
                controller: controller,
                menuChildren: <Widget>[
                  CupertinoMenuItem(
                    isDestructiveAction: true,
                    subtitle: Text(Tag.b.text),
                    leading: const Icon(CupertinoIcons.left_chevron),
                    trailing: const Icon(CupertinoIcons.right_chevron),
                    child: Text(Tag.a.text),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          );
        }

        await tester.pumpWidget(buildApp());

        controller.open();
        await tester.pumpAndSettle();

        expect(findTrailing()!.text.style!.color, isSameColorAs(CupertinoColors.systemRed));
        expect(findLeading()!.text.style!.color, isSameColorAs(CupertinoColors.systemRed));
        expect(findChild()!.text.style!.color, isSameColorAs(CupertinoColors.systemRed));
        expect(
          findSubtitle()!.text.style!.foreground!.color,
          isSameColorAs(defaultSubtitleTextColor),
        );

        await tester.pumpWidget(buildApp(ui.Brightness.dark));

        expect(
          findTrailing()!.text.style!.color,
          isSameColorAs(CupertinoColors.systemRed.darkColor),
        );
        expect(
          findLeading()!.text.style!.color,
          isSameColorAs(CupertinoColors.systemRed.darkColor),
        );
        expect(findChild()!.text.style!.color, isSameColorAs(CupertinoColors.systemRed.darkColor));
        expect(
          findSubtitle()!.text.style!.foreground!.color,
          isSameColorAs(defaultSubtitleDarkTextColor),
        );
      });

      testWidgets('allows adjacent borders', (WidgetTester tester) async {
        await tester.pumpWidget(
          App(
            CupertinoTheme(
              data: const CupertinoThemeData(brightness: Brightness.dark),
              child: CupertinoMenuAnchor(
                controller: controller,
                menuChildren: <Widget>[
                  const _DebugCupertinoMenuEntryMixin(allowTrailingSeparator: true),
                  CupertinoMenuItem(child: Text(Tag.a.text)),
                  const _DebugCupertinoMenuEntryMixin(allowLeadingSeparator: true),
                ],
              ),
            ),
          ),
        );

        controller.open();
        await tester.pumpAndSettle();

        expect(findMenuChildren(tester), hasLength(5));
      });

      testWidgets('disabled items should not interact', (WidgetTester tester) async {
        // Test various interactions to ensure that disabled items do not
        // respond.
        int interactions = 0;
        final FocusNode focusNode = FocusNode();
        focusNode.addListener(() {
          interactions++;
        });

        addTearDown(focusNode.dispose);

        BoxDecoration getItemDecoration() {
          return tester
                  .widget<DecoratedBox>(
                    find.descendant(
                      of: find.byType(CupertinoMenuItem),
                      matching: find.byType(DecoratedBox),
                    ),
                  )
                  .decoration
              as BoxDecoration;
        }

        RenderParagraph? findChild() {
          return findDescendantParagraph(tester, find.text(Tag.a.text));
        }

        await tester.pumpWidget(
          CupertinoApp(
            home: CupertinoMenuAnchor(
              controller: controller,
              menuChildren: <Widget>[
                CupertinoMenuItem(
                  focusNode: focusNode,
                  onFocusChange: (bool value) {
                    interactions++;
                  },
                  onHover: (bool value) {
                    interactions++;
                  },
                  child: Text(Tag.a.text),
                ),
              ],
            ),
          ),
        );

        controller.open();
        await tester.pumpAndSettle();

        final TestGesture gesture = await tester.createGesture(pointer: 1);

        addTearDown(gesture.removePointer);

        // Test focus
        focusNode.requestFocus();
        await tester.pump();

        void checkAppearance() {
          expect(getItemDecoration(), equals(const BoxDecoration()));
          expect(findChild()!.text.style!.color, isSameColorAs(CupertinoColors.systemGrey));
        }

        // Test hover
        await gesture.moveTo(tester.getCenter(find.text(Tag.a.text)));
        await tester.pump();

        checkAppearance();

        // Test press
        await gesture.down(tester.getCenter(find.text(Tag.a.text)));
        await tester.pump();

        checkAppearance();

        // Test pan
        await tester.pumpAndSettle(const Duration(milliseconds: 200));
        await gesture.up();
        await tester.pump();

        checkAppearance();
        expect(controller.isOpen, isTrue);
        expect(interactions, 0);
      });

      testWidgets('hover color', (WidgetTester tester) async {
        const CupertinoDynamicColor hoverColor = CupertinoDynamicColor.withBrightnessAndContrast(
          color: Color.fromRGBO(50, 50, 50, 0.05),
          darkColor: Color.fromRGBO(255, 255, 255, 0.05),
          highContrastColor: Color.fromRGBO(50, 50, 50, 0.1),
          darkHighContrastColor: Color.fromRGBO(255, 255, 255, 0.1),
        );
        const CupertinoDynamicColor customHoverColor = CupertinoDynamicColor.withBrightness(
          color: Color.fromRGBO(75, 0, 0, 1),
          darkColor: Color.fromRGBO(150, 0, 0, 1),
        );

        const WidgetStateProperty<BoxDecoration> decoration =
            WidgetStateProperty<BoxDecoration>.fromMap(<WidgetStatesConstraint, BoxDecoration>{
              WidgetState.hovered: BoxDecoration(color: customHoverColor),
              WidgetState.any: BoxDecoration(),
            });

        BoxDecoration getItemDecoration(Tag tag) {
          return tester
                  .widget<DecoratedBox>(
                    find.descendant(
                      of: find.widgetWithText(CupertinoMenuItem, tag.text),
                      matching: find.byType(DecoratedBox),
                    ),
                  )
                  .decoration
              as BoxDecoration;
        }

        Widget buildApp(ui.Brightness brightness) {
          return CupertinoApp(
            theme: CupertinoThemeData(brightness: brightness),
            home: CupertinoMenuAnchor(
              controller: controller,
              menuChildren: <Widget>[
                CupertinoMenuItem(
                  requestFocusOnHover: false,
                  child: Text(Tag.a.text),
                  onPressed: () {},
                ),
                CupertinoMenuItem(
                  requestFocusOnHover: false,
                  onPressed: () {},
                  decoration: decoration,
                  child: Text(Tag.b.text),
                ),
              ],
            ),
          );
        }

        await tester.pumpWidget(buildApp(ui.Brightness.light));
        controller.open();
        await tester.pumpAndSettle();

        final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
        addTearDown(gesture.removePointer);

        expect(getItemDecoration(Tag.a), equals(const BoxDecoration()));
        expect(getItemDecoration(Tag.b), equals(const BoxDecoration()));

        await gesture.moveTo(tester.getCenter(find.text(Tag.a.text)));
        await tester.pump();

        expect(getItemDecoration(Tag.a).color, isSameColorAs(hoverColor.color));

        expect(getItemDecoration(Tag.b), equals(const BoxDecoration()));

        await gesture.moveTo(tester.getCenter(find.text(Tag.b.text)));
        await tester.pump();

        expect(getItemDecoration(Tag.a), equals(const BoxDecoration()));

        expect(getItemDecoration(Tag.b).color, isSameColorAs(customHoverColor.color));

        await tester.pumpWidget(buildApp(ui.Brightness.dark));

        expect(getItemDecoration(Tag.a), equals(const BoxDecoration()));

        expect(getItemDecoration(Tag.b).color, isSameColorAs(customHoverColor.darkColor));

        await gesture.moveTo(tester.getCenter(find.text(Tag.a.text)));
        await tester.pump();

        expect(getItemDecoration(Tag.a).color, isSameColorAs(hoverColor.darkColor));

        expect(getItemDecoration(Tag.b), equals(const BoxDecoration()));
      });

      testWidgets('pressed color', (WidgetTester tester) async {
        const CupertinoDynamicColor pressedColor = CupertinoDynamicColor.withBrightnessAndContrast(
          color: Color.fromRGBO(50, 50, 50, 0.1),
          darkColor: Color.fromRGBO(255, 255, 255, 0.1),
          highContrastColor: Color.fromRGBO(50, 50, 50, 0.2),
          darkHighContrastColor: Color.fromRGBO(255, 255, 255, 0.2),
        );

        const CupertinoDynamicColor customPressedColor = CupertinoDynamicColor.withBrightness(
          color: Color.fromRGBO(75, 0, 0, 1),
          darkColor: Color.fromRGBO(150, 0, 0, 1),
        );

        const WidgetStateProperty<BoxDecoration> decoration =
            WidgetStateProperty<BoxDecoration>.fromMap(<WidgetStatesConstraint, BoxDecoration>{
              WidgetState.pressed: BoxDecoration(color: customPressedColor),
              WidgetState.any: BoxDecoration(),
            });

        BoxDecoration getItemDecoration(Tag tag) {
          return tester
                  .widget<DecoratedBox>(
                    find.descendant(
                      of: find.widgetWithText(CupertinoMenuItem, tag.text),
                      matching: find.byType(DecoratedBox),
                    ),
                  )
                  .decoration
              as BoxDecoration;
        }

        Widget buildApp(ui.Brightness brightness) {
          return CupertinoApp(
            theme: CupertinoThemeData(brightness: brightness),
            home: CupertinoMenuAnchor(
              controller: controller,
              menuChildren: <Widget>[
                CupertinoMenuItem(
                  requestFocusOnHover: false,
                  requestCloseOnActivate: false,
                  onPressed: () {},
                  child: Text(Tag.a.text),
                ),
                CupertinoMenuItem(
                  requestFocusOnHover: false,
                  requestCloseOnActivate: false,
                  onPressed: () {},
                  decoration: decoration,
                  child: Text(Tag.b.text),
                ),
              ],
            ),
          );
        }

        await tester.pumpWidget(buildApp(ui.Brightness.light));
        controller.open();
        await tester.pumpAndSettle();

        final TestGesture gesture = await tester.createGesture();
        addTearDown(gesture.removePointer);

        expect(getItemDecoration(Tag.a), equals(const BoxDecoration()));
        expect(getItemDecoration(Tag.b), equals(const BoxDecoration()));

        await gesture.down(tester.getCenter(find.text(Tag.a.text)));
        await tester.pumpAndSettle();

        expect(getItemDecoration(Tag.a).color, isSameColorAs(pressedColor.color));
        expect(getItemDecoration(Tag.b), equals(const BoxDecoration()));

        // Release the press
        await gesture.up();
        await tester.pumpAndSettle();

        expect(getItemDecoration(Tag.a), equals(const BoxDecoration()));
        expect(getItemDecoration(Tag.b), equals(const BoxDecoration()));

        // Press the second item with a custom pressed color
        await gesture.down(tester.getCenter(find.text(Tag.b.text)));
        await tester.pumpAndSettle();

        expect(getItemDecoration(Tag.a), equals(const BoxDecoration()));
        expect(getItemDecoration(Tag.b).color, isSameColorAs(customPressedColor.color));

        await gesture.up();
        await tester.pumpAndSettle();

        controller.close();
        await tester.pumpAndSettle();

        await tester.pumpWidget(buildApp(ui.Brightness.dark));

        controller.open();
        await tester.pumpAndSettle();

        expect(controller.isOpen, isTrue);

        await gesture.down(tester.getCenter(find.text(Tag.a.text)));
        await tester.pumpAndSettle();

        expect(getItemDecoration(Tag.a).color, isSameColorAs(pressedColor.darkColor));
      });

      testWidgets('focused color', (WidgetTester tester) async {
        const CupertinoDynamicColor focusedColor = CupertinoDynamicColor.withBrightnessAndContrast(
          color: Color.fromRGBO(50, 50, 50, 0.075),
          darkColor: Color.fromRGBO(255, 255, 255, 0.075),
          highContrastColor: Color.fromRGBO(50, 50, 50, 0.15),
          darkHighContrastColor: Color.fromRGBO(255, 255, 255, 0.15),
        );

        const CupertinoDynamicColor customFocusedColor = CupertinoDynamicColor.withBrightness(
          color: Color.fromRGBO(0, 75, 0, 1),
          darkColor: Color.fromRGBO(0, 150, 0, 1),
        );

        const WidgetStateProperty<BoxDecoration> decoration =
            WidgetStateProperty<BoxDecoration>.fromMap(<WidgetStatesConstraint, BoxDecoration>{
              WidgetState.focused: BoxDecoration(color: customFocusedColor),
              WidgetState.any: BoxDecoration(),
            });

        BoxDecoration getItemDecoration(Tag tag) {
          return tester
                  .widget<DecoratedBox>(
                    find.descendant(
                      of: find.widgetWithText(CupertinoMenuItem, tag.text),
                      matching: find.byType(DecoratedBox),
                    ),
                  )
                  .decoration
              as BoxDecoration;
        }

        final FocusNode focusNodeA = FocusNode();
        final FocusNode focusNodeB = FocusNode();
        addTearDown(() {
          focusNodeA.dispose();
          focusNodeB.dispose();
        });

        Widget buildApp(ui.Brightness brightness) {
          return CupertinoApp(
            theme: CupertinoThemeData(brightness: brightness),
            home: CupertinoMenuAnchor(
              controller: controller,
              menuChildren: <Widget>[
                CupertinoMenuItem(focusNode: focusNodeA, child: Text(Tag.a.text), onPressed: () {}),
                CupertinoMenuItem(
                  focusNode: focusNodeB,
                  onPressed: () {},
                  decoration: decoration,
                  child: Text(Tag.b.text),
                ),
              ],
            ),
          );
        }

        await tester.pumpWidget(buildApp(ui.Brightness.light));
        controller.open();
        await tester.pumpAndSettle();

        // Verify initial state
        expect(getItemDecoration(Tag.a), equals(const BoxDecoration()));
        expect(getItemDecoration(Tag.b), equals(const BoxDecoration()));

        // Focus the first item
        focusNodeA.requestFocus();
        await tester.pump();
        await tester.pump();

        expect(getItemDecoration(Tag.a).color, isSameColorAs(focusedColor.color));
        expect(getItemDecoration(Tag.b), equals(const BoxDecoration()));

        // Focus the second item with a custom focused color
        focusNodeB.requestFocus();
        await tester.pump();
        await tester.pump();

        expect(getItemDecoration(Tag.a), equals(const BoxDecoration()));
        expect(getItemDecoration(Tag.b).color, isSameColorAs(customFocusedColor.color));

        await tester.pumpWidget(buildApp(ui.Brightness.dark));

        // Verify dark mode focused colors
        focusNodeA.requestFocus();
        await tester.pump();
        await tester.pump();

        expect(getItemDecoration(Tag.a).color, isSameColorAs(focusedColor.darkColor));
        expect(getItemDecoration(Tag.b), equals(const BoxDecoration()));

        focusNodeB.requestFocus();
        await tester.pump();
        await tester.pump();

        expect(getItemDecoration(Tag.b).color, isSameColorAs(customFocusedColor.darkColor));
      });

      testWidgets('mouse cursor can be set and is inherited', (WidgetTester tester) async {
        await tester.pumpWidget(
          CupertinoApp(
            home: Align(
              alignment: Alignment.topLeft,
              child: MouseRegion(
                cursor: SystemMouseCursors.forbidden,
                child: CupertinoMenuItem(
                  mouseCursor: const WidgetStatePropertyAll<MouseCursor>(SystemMouseCursors.text),
                  child: Text(Tag.a.text),
                  onPressed: () {},
                ),
              ),
            ),
          ),
        );

        final TestGesture gesture = await tester.createGesture(
          kind: ui.PointerDeviceKind.mouse,
          pointer: 1,
        );

        await gesture.addPointer(location: tester.getCenter(find.text(Tag.a.text)));
        addTearDown(gesture.removePointer);

        await tester.pump();

        expect(
          RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
          SystemMouseCursors.text,
        );

        // Test default cursor when disabled
        await tester.pumpWidget(
          CupertinoApp(
            home: Align(
              alignment: Alignment.topLeft,
              child: CupertinoMenuItem(
                child: MouseRegion(cursor: SystemMouseCursors.basic, child: Container()),
              ),
            ),
          ),
        );

        // The cursor should defer to it's child.
        expect(
          RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
          SystemMouseCursors.basic,
        );
      });
    });

    group('Layout', () {
      Alignment offsetAlongSize(ui.Offset offset, ui.Size size) {
        final double x = (offset.dx / size.width) * 2 - 1;
        final double y = (offset.dy / size.height) * 2 - 1;
        return Alignment(x, y);
      }

      double lineHeight(TextStyle style) {
        return style.height! * style.fontSize!;
      }

      testWidgets('LTR hasLeading shift', (WidgetTester tester) async {
        // When no menu item has a leading widget, leadingWidth defaults to 16.
        // If leadingWidth is set, the default is ignored.
        await tester.pumpWidget(
          App(
            CupertinoMenuAnchor(
              controller: controller,
              menuChildren: <Widget>[
                CupertinoMenuItem(onPressed: () {}, child: Text(Tag.a.text)),
                CupertinoMenuItem(onPressed: () {}, child: Text(Tag.b.text)),
                CupertinoMenuItem(onPressed: () {}, leadingWidth: 3, child: Text(Tag.c.text)),
              ],
            ),
          ),
        );

        controller.open();
        await tester.pumpAndSettle();

        final Rect a1 = tester.getRect(find.text(Tag.a.text));
        final Rect b1 = tester.getRect(find.text(Tag.b.text));
        final Rect c1 = tester.getRect(find.text(Tag.c.text));

        expect(a1.left, b1.left);
        expect(a1.left - c1.left, closeTo(16 - 3, 0.01));

        // When any menu item has a leading widget, leadingWidth defaults to 32
        // for all menu items on this menu layer. If leadingWidth is set on an
        // item, that item ignores the default leading width.
        await tester.pumpWidget(
          App(
            CupertinoMenuAnchor(
              controller: controller,
              menuChildren: <Widget>[
                CupertinoMenuItem(onPressed: () {}, child: Text(Tag.a.text)),
                CupertinoMenuItem(
                  onPressed: () {},
                  leading: const Icon(CupertinoIcons.left_chevron),
                  child: Text(Tag.b.text),
                ),
                CupertinoMenuItem(onPressed: () {}, leadingWidth: 3, child: Text(Tag.c.text)),
              ],
            ),
          ),
        );

        final Rect a2 = tester.getRect(find.text(Tag.a.text));
        final Rect b2 = tester.getRect(find.text(Tag.b.text));
        final Rect c2 = tester.getRect(find.text(Tag.c.text));

        expect(a2.left, b2.left);
        expect(a2.left - c2.left, closeTo(32 - 3, 0.01));
        expect(a2.left - a1.left, closeTo(32 - 16, 0.01));
      });
      testWidgets('RTL hasLeading shift', (WidgetTester tester) async {
        // When no menu item has a leading widget, leadingWidth defaults to 16.
        // If leadingWidth is set, the default is ignored.
        await tester.pumpWidget(
          App(
            textDirection: TextDirection.rtl,
            CupertinoMenuAnchor(
              controller: controller,
              menuChildren: <Widget>[
                CupertinoMenuItem(onPressed: () {}, child: Text(Tag.a.text)),
                CupertinoMenuItem(onPressed: () {}, child: Text(Tag.b.text)),
                CupertinoMenuItem(onPressed: () {}, leadingWidth: 3, child: Text(Tag.c.text)),
              ],
            ),
          ),
        );

        controller.open();
        await tester.pumpAndSettle();

        final Rect a1 = tester.getRect(find.text(Tag.a.text));
        final Rect b1 = tester.getRect(find.text(Tag.b.text));
        final Rect c1 = tester.getRect(find.text(Tag.c.text));

        expect(a1.right, b1.right);
        expect(a1.right - c1.right, closeTo(-16 + 3, 0.01));

        // When any menu item has a leading widget, leadingWidth defaults to 32
        // for all menu items on this menu layer. If leadingWidth is set on an
        // item, that item ignores the default leading width.
        await tester.pumpWidget(
          App(
            textDirection: TextDirection.rtl,
            CupertinoMenuAnchor(
              controller: controller,
              menuChildren: <Widget>[
                CupertinoMenuItem(onPressed: () {}, child: Text(Tag.a.text)),
                CupertinoMenuItem(
                  onPressed: () {},
                  leading: const Icon(CupertinoIcons.left_chevron),
                  child: Text(Tag.b.text),
                ),
                CupertinoMenuItem(onPressed: () {}, leadingWidth: 3, child: Text(Tag.c.text)),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        final Rect a2 = tester.getRect(find.text(Tag.a.text));
        final Rect b2 = tester.getRect(find.text(Tag.b.text));
        final Rect c2 = tester.getRect(find.text(Tag.c.text));

        expect(a2.right, b2.right);
        expect(a2.right - c2.right, closeTo(-32 + 3, 0.01));
        expect(a2.right - a1.right, closeTo(-32 + 16, 0.01));
      });

      group('Child ', () {
        testWidgets('LTR child layout', (WidgetTester tester) async {
          await tester.pumpWidget(
            App(
              CupertinoMenuAnchor(
                controller: controller,
                menuChildren: <Widget>[
                  CupertinoMenuItem(onPressed: () {}, child: Text(Tag.child.text)),
                ],
              ),
            ),
          );

          controller.open();
          await tester.pumpAndSettle();

          final double childLineHeight = lineHeight(_DynamicTypeStyle.body.large);
          final Rect childRect = tester.getRect(find.text(Tag.child.text));
          final Rect menuItemRect = tester.getRect(find.byType(CupertinoMenuItem));

          expect(childRect.height, closeTo(childLineHeight, 0.1));
          expect(childRect.top, closeTo(menuItemRect.top + 10.83, 0.1));
          expect(childRect.left, closeTo(menuItemRect.left + 16, 0.1));
        });

        testWidgets('RTL child layout', (WidgetTester tester) async {
          await tester.pumpWidget(
            App(
              Directionality(
                textDirection: TextDirection.rtl,
                child: CupertinoMenuAnchor(
                  controller: controller,
                  menuChildren: <Widget>[
                    CupertinoMenuItem(onPressed: () {}, child: Text(Tag.child.text)),
                  ],
                ),
              ),
            ),
          );

          controller.open();
          await tester.pumpAndSettle();

          final double childLineHeight = lineHeight(_DynamicTypeStyle.body.large);
          final Rect childRect = tester.getRect(find.text(Tag.child.text));
          final Rect menuItemRect = tester.getRect(find.byType(CupertinoMenuItem));

          expect(childRect.height, closeTo(childLineHeight, 0.1));
          expect(childRect.top, closeTo(menuItemRect.top + 10.83, 0.1));
          expect(childRect.right, closeTo(menuItemRect.right - 16, 0.1));
        });

        testWidgets('child text overflow', (WidgetTester tester) async {
          final String longText = 'Very long subtitle ' * 100;

          await tester.pumpWidget(
            App(
              CupertinoMenuAnchor(
                controller: controller,
                menuChildren: <Widget>[CupertinoMenuItem(onPressed: () {}, child: Text(longText))],
              ),
            ),
          );

          controller.open();
          await tester.pumpAndSettle();

          final Size childText = tester.getSize(find.text(longText));
          final TextStyle childStyle = _DynamicTypeStyle.body.large;
          expect(childText.height, closeTo(lineHeight(childStyle) * 2, 1)); // 2 lines of text
        });

        testWidgets('child text overflow in accessibility mode', (WidgetTester tester) async {
          final String longText = 'Very long text ' * 1000;

          await tester.pumpWidget(
            App(
              MediaQuery(
                data: const MediaQueryData(textScaler: AccessibilityTextSize.ax1),
                child: CupertinoMenuAnchor(
                  controller: controller,
                  menuChildren: <Widget>[
                    CupertinoMenuItem(onPressed: () {}, child: Text(longText)),
                  ],
                ),
              ),
            ),
          );

          controller.open();
          await tester.pumpAndSettle();

          final RenderParagraph paragraph = findDescendantParagraph(tester, find.text(longText))!;
          final double childLineHeight = lineHeight(_DynamicTypeStyle.body.ax1);

          expect(paragraph.maxLines, equals(CupertinoMenuItem.defaultAccessibilityModeMaxLines));
          expect(tester.getSize(find.text(longText)).height, closeTo(childLineHeight * 100, 1));
        });

        testWidgets('LTR child with leading and trailing', (WidgetTester tester) async {
          await tester.pumpWidget(
            App(
              CupertinoMenuAnchor(
                controller: controller,
                menuChildren: <Widget>[
                  CupertinoMenuItem(
                    leadingWidth: 33,
                    trailingWidth: 47,
                    leading: Icon(CupertinoIcons.star, key: Tag.leading.key),
                    trailing: Icon(CupertinoIcons.heart, key: Tag.trailing.key),
                    onPressed: () {},
                    child: Text(Tag.child.text),
                  ),
                ],
              ),
            ),
          );

          controller.open();
          await tester.pumpAndSettle();

          final Rect leading = tester.getRect(find.byKey(Tag.leading.key));
          final Rect trailing = tester.getRect(find.byKey(Tag.trailing.key));
          final Rect child = tester.getRect(find.text(Tag.child.text));
          final Rect menuItem = tester.getRect(find.byType(CupertinoMenuItem));

          expect(child.left, closeTo(menuItem.left + 33, 0.1));
          expect(child.right, lessThanOrEqualTo(menuItem.right - 47));
          expect(child.left, greaterThan(leading.right));
          expect(child.right, lessThan(trailing.left));
          expect(leading.center.dy, closeTo(child.center.dy, 0.1));
          expect(trailing.center.dy, closeTo(child.center.dy, 0.1));
        });

        testWidgets('RTL child with leading and trailing', (WidgetTester tester) async {
          await tester.pumpWidget(
            App(
              Directionality(
                textDirection: TextDirection.rtl,
                child: CupertinoMenuAnchor(
                  controller: controller,
                  menuChildren: <Widget>[
                    CupertinoMenuItem(
                      leadingWidth: 33,
                      trailingWidth: 47,
                      leading: Icon(CupertinoIcons.star, key: Tag.leading.key),
                      trailing: Icon(CupertinoIcons.heart, key: Tag.trailing.key),
                      onPressed: () {},
                      child: Text(Tag.child.text),
                    ),
                  ],
                ),
              ),
            ),
          );

          controller.open();
          await tester.pumpAndSettle();

          final Rect leading = tester.getRect(find.byKey(Tag.leading.key));
          final Rect trailing = tester.getRect(find.byKey(Tag.trailing.key));
          final Rect child = tester.getRect(find.text(Tag.child.text));
          final Rect menuItem = tester.getRect(find.byType(CupertinoMenuItem));

          expect(child.right, closeTo(menuItem.right - 33, 0.1));
          expect(child.right, lessThan(leading.right));
          expect(child.left, greaterThan(trailing.left));
          expect(leading.center.dy, closeTo(child.center.dy, 0.1));
          expect(trailing.center.dy, closeTo(child.center.dy, 0.1));
        });

        testWidgets('child text overflow with maxLines', (WidgetTester tester) async {
          final String longText = 'Very long text ' * 1000;

          await tester.pumpWidget(
            App(
              MediaQuery(
                data: const MediaQueryData(textScaler: AccessibilityTextSize.xxxLarge),
                child: CupertinoMenuAnchor(
                  controller: controller,
                  menuChildren: <Widget>[
                    CupertinoMenuItem(
                      onPressed: () {},
                      child: Text(longText, key: Tag.a.key),
                    ),
                  ],
                ),
              ),
            ),
          );

          controller.open();
          await tester.pumpAndSettle();

          final RenderParagraph paragraph = findDescendantParagraph(tester, find.byKey(Tag.a.key))!;
          expect(paragraph.maxLines, equals(CupertinoMenuItem.defaultMaxLines));
          expect(paragraph.size.height, closeTo(58, 1)); // 2 lines of text
          expect(tester.getSize(find.byType(CupertinoMenuItem)).height, closeTo(87, 1));
        });

        testWidgets('child text overflow with accessibility mode', (WidgetTester tester) async {
          final String longText = 'Very long text ' * 1000;

          await tester.pumpWidget(
            App(
              MediaQuery(
                data: const MediaQueryData(textScaler: AccessibilityTextSize.ax1),
                child: CupertinoMenuAnchor(
                  controller: controller,
                  menuChildren: <Widget>[
                    CupertinoMenuItem(
                      onPressed: () {},
                      child: Text(longText, key: Tag.a.key),
                    ),
                  ],
                ),
              ),
            ),
          );

          controller.open();
          await tester.pumpAndSettle();

          final RenderParagraph paragraph = findDescendantParagraph(tester, find.byKey(Tag.a.key))!;
          expect(paragraph.maxLines, equals(CupertinoMenuItem.defaultAccessibilityModeMaxLines));
          expect(paragraph.size.height, closeTo(3400, 1)); // 100 lines of text
          expect(tester.getSize(find.byType(CupertinoMenuItem)).height, closeTo(3433, 1));
        });

        testWidgets('child adjusts to dynamic type', (WidgetTester tester) async {
          Widget buildApp({TextScaler textScaler = AccessibilityTextSize.large}) {
            return App(
              Builder(
                builder: (BuildContext context) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(textScaler: textScaler),
                    child: CupertinoMenuAnchor(
                      controller: controller,
                      menuChildren: <Widget>[
                        CupertinoMenuItem(
                          onPressed: () {},
                          leading: Icon(CupertinoIcons.left_chevron, key: Tag.leading.key),
                          trailing: Icon(CupertinoIcons.right_chevron, key: Tag.trailing.key),
                          subtitle: Text(Tag.subtitle.text),
                          child: Text(Tag.child.text),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }

          await tester.pumpWidget(buildApp(textScaler: AccessibilityTextSize.undersized));
          controller.open();
          await tester.pumpAndSettle();

          final double undersizedLineHeight = lineHeight(_DynamicTypeStyle.body.xSmall);
          Size childSize = tester.getSize(find.text(Tag.child.text));

          expect(childSize.height, closeTo(undersizedLineHeight, 0.1));

          await tester.pumpWidget(buildApp(textScaler: AccessibilityTextSize.xSmall));

          final double xSmallLineHeight = lineHeight(_DynamicTypeStyle.body.xSmall);
          childSize = tester.getSize(find.text(Tag.child.text));

          expect(childSize.height, closeTo(xSmallLineHeight, 0.1));

          await tester.pumpWidget(buildApp());

          final double largeLineHeight = lineHeight(_DynamicTypeStyle.body.large);
          childSize = tester.getSize(find.text(Tag.child.text));

          expect(childSize.height, closeTo(largeLineHeight, 0.1));

          await tester.pumpWidget(buildApp(textScaler: AccessibilityTextSize.ax5));

          final double ax5LineHeight = lineHeight(_DynamicTypeStyle.body.ax5);
          childSize = tester.getSize(find.text(Tag.child.text));

          expect(childSize.height, closeTo(ax5LineHeight * 2, 0.1));

          await tester.pumpWidget(buildApp(textScaler: AccessibilityTextSize.oversized));

          final double oversizedLineHeight = lineHeight(_DynamicTypeStyle.body.ax5);
          childSize = tester.getSize(find.text(Tag.child.text));

          expect(childSize.height, closeTo(oversizedLineHeight * 2, 0.1));
        });
      });

      group('Leading ', () {
        testWidgets('LTR leading position', (WidgetTester tester) async {
          await tester.pumpWidget(
            App(
              textDirection: TextDirection.ltr,
              CupertinoMenuAnchor(
                controller: controller,
                menuChildren: <Widget>[
                  CupertinoMenuItem(
                    onPressed: () {},
                    leading: Icon(CupertinoIcons.left_chevron, key: Tag.leading.key),
                    trailing: Icon(CupertinoIcons.right_chevron, key: Tag.trailing.key),
                    subtitle: const Text('Subtitle'),
                    child: Text(Tag.child.text),
                  ),
                ],
              ),
            ),
          );

          controller.open();
          await tester.pumpAndSettle();

          final ui.Rect leadingRect = tester.getRect(find.byKey(Tag.leading.key));
          final ui.Rect menuItemRect = tester.getRect(find.byType(CupertinoMenuItem));
          final ui.Rect childRect = tester.getRect(find.text(Tag.child.text));
          final double leadingWidth = childRect.left - menuItemRect.left;
          final Size leadingSize = ui.Size(leadingWidth, menuItemRect.height);
          final Rect leadingWidgetRect = tester
              .getRect(find.byKey(Tag.leading.key))
              .translate(-menuItemRect.left, -menuItemRect.top);
          final Alignment leadingAlignment = offsetAlongSize(leadingWidgetRect.center, leadingSize);

          expect(leadingAlignment.x, closeTo(0.1680, 0.01));
          expect(leadingAlignment.y, closeTo(0, 0.01));
          expect(leadingRect.left, greaterThan(menuItemRect.left));
          expect(leadingRect.right, lessThan(childRect.right));
        });

        testWidgets('RTL leading position', (WidgetTester tester) async {
          await tester.pumpWidget(
            App(
              textDirection: TextDirection.rtl,
              CupertinoMenuAnchor(
                controller: controller,
                menuChildren: <Widget>[
                  CupertinoMenuItem(
                    onPressed: () {},
                    leading: Icon(CupertinoIcons.left_chevron, key: Tag.leading.key),
                    trailing: Icon(CupertinoIcons.right_chevron, key: Tag.trailing.key),
                    subtitle: Text(Tag.subtitle.text),
                    child: Text(Tag.child.text),
                  ),
                ],
              ),
            ),
          );
          controller.open();
          await tester.pumpAndSettle();

          final ui.Rect leadingRect = tester.getRect(find.byKey(Tag.leading.key));
          final ui.Rect menuItemRect = tester.getRect(find.byType(CupertinoMenuItem));
          final ui.Rect childRect = tester.getRect(find.text(Tag.child.text));
          final double leadingWidth = menuItemRect.right - childRect.right;
          final Size leadingSize = ui.Size(leadingWidth, menuItemRect.height);
          final Rect leadingWidgetRect = tester
              .getRect(find.byKey(Tag.leading.key))
              .translate(-childRect.right, -menuItemRect.top);
          final Alignment leadingAlignment = offsetAlongSize(leadingWidgetRect.center, leadingSize);

          expect(leadingAlignment.x, closeTo(-0.168, 0.01));
          expect(leadingAlignment.y, closeTo(0, 0.01));
          expect(leadingRect.right, lessThan(menuItemRect.right));
          expect(leadingRect.left, greaterThan(childRect.left));
        });

        testWidgets('leadingMidpointAlignment adjusts to dynamic type', (
          WidgetTester tester,
        ) async {
          Widget buildApp({TextScaler textScaler = AccessibilityTextSize.large}) {
            return App(
              Builder(
                builder: (BuildContext context) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(textScaler: textScaler),
                    child: CupertinoMenuAnchor(
                      controller: controller,
                      menuChildren: <Widget>[
                        CupertinoMenuItem(
                          onPressed: () {},
                          leading: Icon(CupertinoIcons.left_chevron, key: Tag.leading.key),
                          trailing: Icon(CupertinoIcons.right_chevron, key: Tag.trailing.key),
                          subtitle: Text(Tag.subtitle.text),
                          child: Text(Tag.child.text),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }

          await tester.pumpWidget(buildApp(textScaler: AccessibilityTextSize.undersized));
          controller.open();
          await tester.pumpAndSettle();

          Alignment leadingAlignment() {
            final ui.Rect menuItemRect = tester.getRect(find.byType(CupertinoMenuItem));
            final ui.Rect childRect = tester.getRect(find.text(Tag.child.text));
            final double leadingWidth = childRect.left - menuItemRect.left;
            final Size leadingSize = ui.Size(leadingWidth, menuItemRect.height);
            final Rect leadingWidgetRect = tester
                .getRect(find.byKey(Tag.leading.key))
                .translate(-menuItemRect.left, -menuItemRect.top);
            return offsetAlongSize(leadingWidgetRect.center, leadingSize);
          }

          Alignment alignment = leadingAlignment();
          expect(alignment.x, closeTo(0.1673, 0.01));
          expect(alignment.y, closeTo(0, 0.01));

          await tester.pumpWidget(buildApp(textScaler: AccessibilityTextSize.xSmall));

          alignment = leadingAlignment();
          expect(alignment.x, closeTo(0.1673, 0.01));
          expect(alignment.y, closeTo(0, 0.01));

          await tester.pumpWidget(buildApp(textScaler: AccessibilityTextSize.ax5));

          alignment = leadingAlignment();
          expect(alignment.x, closeTo(0.1765, 0.01));
          expect(alignment.y, closeTo(0, 0.01));

          await tester.pumpWidget(buildApp(textScaler: AccessibilityTextSize.oversized));

          alignment = leadingAlignment();
          expect(alignment.x, closeTo(0.1765, 0.01));
          expect(alignment.y, closeTo(0, 0.01));
        });

        testWidgets('leadingWidth adjusts to dynamic type', (WidgetTester tester) async {
          Widget buildApp({TextScaler textScaler = AccessibilityTextSize.large}) {
            return App(
              Builder(
                builder: (BuildContext context) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(textScaler: textScaler),
                    child: CupertinoMenuAnchor(
                      controller: controller,
                      menuChildren: <Widget>[
                        CupertinoMenuItem(
                          onPressed: () {},
                          leading: Icon(CupertinoIcons.left_chevron, key: Tag.leading.key),
                          trailing: Icon(CupertinoIcons.right_chevron, key: Tag.trailing.key),
                          subtitle: Text(Tag.subtitle.text),
                          child: Text(Tag.child.text),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }

          await tester.pumpWidget(buildApp(textScaler: AccessibilityTextSize.undersized));
          controller.open();
          await tester.pumpAndSettle();

          Rect childRect() => tester.getRect(find.text(Tag.child.text));
          Rect menuItemRect() => tester.getRect(find.byType(CupertinoMenuItem));
          double leadingWidth() => childRect().left - menuItemRect().left;

          expect(leadingWidth(), closeTo(30.0, 0.1));

          await tester.pumpWidget(buildApp(textScaler: AccessibilityTextSize.xSmall));

          expect(leadingWidth(), closeTo(30.0, 0.1));

          await tester.pumpWidget(buildApp());

          expect(leadingWidth(), closeTo(32.0, 0.1));

          await tester.pumpWidget(buildApp(textScaler: AccessibilityTextSize.ax5));

          expect(leadingWidth(), closeTo(61.0, 0.5));

          await tester.pumpWidget(buildApp(textScaler: AccessibilityTextSize.oversized));

          expect(leadingWidth(), closeTo(61.0, 0.5));
        });
        testWidgets('leadingWidth is quantized to pixel ratio', (WidgetTester tester) async {
          Rect childRect() => tester.getRect(find.text(Tag.child.text));
          Rect menuItemRect() => tester.getRect(find.byType(CupertinoMenuItem));

          Widget buildApp({
            TextScaler textScaler = AccessibilityTextSize.large,
            double devicePixelRatio = 2.0,
          }) {
            return App(
              Builder(
                builder: (BuildContext context) {
                  return MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: textScaler, devicePixelRatio: devicePixelRatio),
                    child: CupertinoMenuAnchor(
                      controller: controller,
                      menuChildren: <Widget>[
                        CupertinoMenuItem(
                          onPressed: () {},
                          leading: Icon(CupertinoIcons.left_chevron, key: Tag.leading.key),
                          trailing: Icon(CupertinoIcons.right_chevron, key: Tag.trailing.key),
                          subtitle: Text(Tag.subtitle.text),
                          child: Text(Tag.child.text),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }

          await tester.pumpWidget(buildApp(textScaler: AccessibilityTextSize.medium));
          controller.open();
          await tester.pumpAndSettle();

          final double leadingWidth2x = childRect().left - menuItemRect().left;
          expect(leadingWidth2x - leadingWidth2x.floorToDouble(), closeTo(1 / 2, 0.01));

          await tester.pumpWidget(
            buildApp(devicePixelRatio: 3.0, textScaler: AccessibilityTextSize.medium),
          );

          final double leadingWidth3x = childRect().left - menuItemRect().left;
          expect(leadingWidth3x - leadingWidth3x.floorToDouble(), closeTo(1 / 3, 0.01));
        });

        testWidgets('custom leadingWidth', (WidgetTester tester) async {
          await tester.pumpWidget(
            App(
              CupertinoMenuAnchor(
                controller: controller,
                menuChildren: <Widget>[
                  CupertinoMenuItem(
                    leadingWidth: 60,
                    child: Text(Tag.child.text, key: Tag.child.key),
                  ),
                ],
              ),
            ),
          );

          controller.open();
          await tester.pumpAndSettle();

          final Rect child = tester.getRect(find.byKey(Tag.child.key));
          final Rect menuItemRect = tester.getRect(find.byType(CupertinoMenuItem));

          final double leadingSpace = child.left - menuItemRect.left;
          expect(leadingSpace, moreOrLessEquals(60, epsilon: 1));
        });

        testWidgets('custom leadingMidpointAlignment', (WidgetTester tester) async {
          await tester.pumpWidget(
            App(
              CupertinoMenuAnchor(
                controller: controller,
                menuChildren: <Widget>[
                  CupertinoMenuItem(
                    padding: EdgeInsets.zero,
                    leadingWidth: 60,
                    leadingMidpointAlignment: const Alignment(0.5, 0.5),
                    leading: Container(
                      color: CupertinoColors.systemBlue,
                      width: 5,
                      height: 5,
                      key: Tag.leading.key,
                    ),
                    onPressed: () {},
                    child: Text('TTT', key: Tag.child.key),
                  ),
                ],
              ),
            ),
          );

          controller.open();
          await tester.pumpAndSettle();

          final ui.Rect menuItemRect = tester.getRect(find.byType(CupertinoMenuItem));
          final ui.Rect childRect = tester.getRect(find.byKey(Tag.child.key));
          final double leadingWidth = childRect.left - menuItemRect.left;
          final Size leadingSize = ui.Size(leadingWidth, menuItemRect.height);
          final Rect leadingWidgetRect = tester
              .getRect(find.byKey(Tag.leading.key))
              .shift(-menuItemRect.topLeft);

          final Alignment alignment = offsetAlongSize(leadingWidgetRect.center, leadingSize);

          expect(alignment.x, closeTo(0.5, 0.01));
          expect(alignment.y, closeTo(0.5, 0.01));
        });
      });

      group('Trailing ', () {
        testWidgets('LTR trailing position', (WidgetTester tester) async {
          await tester.pumpWidget(
            App(
              Directionality(
                textDirection: TextDirection.ltr,
                child: CupertinoMenuAnchor(
                  controller: controller,
                  menuChildren: <Widget>[
                    CupertinoMenuItem(
                      onPressed: () {},
                      leading: Icon(CupertinoIcons.left_chevron, key: Tag.leading.key),
                      trailing: Icon(CupertinoIcons.right_chevron, key: Tag.trailing.key),
                      subtitle: Text(Tag.subtitle.text),
                      child: Text(Tag.child.text),
                    ),
                  ],
                ),
              ),
            ),
          );

          controller.open();
          await tester.pumpAndSettle();

          final ui.Rect trailingRect = tester.getRect(find.byKey(Tag.trailing.key));
          final ui.Rect menuItemRect = tester.getRect(find.byType(CupertinoMenuItem));
          final ui.Rect childRect = tester.getRect(find.text(Tag.child.text));
          final double trailingWidth = menuItemRect.right - childRect.right;
          final Size trailingSize = ui.Size(trailingWidth, menuItemRect.height);
          final Rect trailingWidgetRect = tester
              .getRect(find.byKey(Tag.trailing.key))
              .translate(-childRect.right, -menuItemRect.top);
          final Alignment trailingAlignment = offsetAlongSize(
            trailingWidgetRect.center,
            trailingSize,
          );

          expect(trailingAlignment.x, closeTo(-0.2727, 0.01));
          expect(trailingAlignment.y, closeTo(0, 0.01));
          expect(trailingRect.right, lessThan(menuItemRect.right));
          expect(trailingRect.left, greaterThan(childRect.left));
        });

        testWidgets('RTL trailing position', (WidgetTester tester) async {
          await tester.pumpWidget(
            App(
              Directionality(
                textDirection: TextDirection.rtl,
                child: CupertinoMenuAnchor(
                  controller: controller,
                  menuChildren: <Widget>[
                    CupertinoMenuItem(
                      onPressed: () {},
                      leading: Icon(CupertinoIcons.left_chevron, key: Tag.leading.key),
                      trailing: Icon(CupertinoIcons.right_chevron, key: Tag.trailing.key),
                      subtitle: Text(Tag.subtitle.text),
                      child: Text(Tag.child.text),
                    ),
                  ],
                ),
              ),
            ),
          );

          controller.open();
          await tester.pumpAndSettle();

          final ui.Rect trailingRect = tester.getRect(find.byKey(Tag.trailing.key));
          final ui.Rect menuItemRect = tester.getRect(find.byType(CupertinoMenuItem));
          final ui.Rect childRect = tester.getRect(find.text(Tag.child.text));
          final double trailingWidth = childRect.left - menuItemRect.left;
          final Size trailingSize = ui.Size(trailingWidth, menuItemRect.height);
          final Rect trailingWidgetRect = tester
              .getRect(find.byKey(Tag.trailing.key))
              .translate(-menuItemRect.left, -menuItemRect.top);
          final Alignment trailingAlignment = offsetAlongSize(
            trailingWidgetRect.center,
            trailingSize,
          );

          expect(trailingAlignment.x, closeTo(0.2727, 0.01));
          expect(trailingAlignment.y, closeTo(0, 0.01));
          expect(trailingRect.left, greaterThan(menuItemRect.left));
          expect(trailingRect.right, lessThan(childRect.right));
        });

        testWidgets('trailingMidpointAlignment adjusts to dynamic type', (
          WidgetTester tester,
        ) async {
          Widget buildApp({TextScaler textScaler = AccessibilityTextSize.large}) {
            return App(
              Builder(
                builder: (BuildContext context) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(textScaler: textScaler),
                    child: CupertinoMenuAnchor(
                      controller: controller,
                      menuChildren: <Widget>[
                        CupertinoMenuItem(
                          onPressed: () {},
                          leading: Icon(CupertinoIcons.left_chevron, key: Tag.leading.key),
                          trailing: Icon(CupertinoIcons.right_chevron, key: Tag.trailing.key),
                          subtitle: Text(Tag.subtitle.text),
                          child: Text(Tag.child.text),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }

          await tester.pumpWidget(buildApp(textScaler: AccessibilityTextSize.undersized));
          controller.open();
          await tester.pumpAndSettle();

          Alignment getTrailingAlignment() {
            final ui.Rect menuItemRect = tester.getRect(find.byType(CupertinoMenuItem));
            final ui.Rect childRect = tester.getRect(find.text(Tag.child.text));
            final double trailingWidth = menuItemRect.right - childRect.right;
            final Size trailingSize = ui.Size(trailingWidth, menuItemRect.height);
            final Rect trailingWidgetRect = tester
                .getRect(find.byKey(Tag.trailing.key))
                .translate(-childRect.right, -menuItemRect.top);
            return offsetAlongSize(trailingWidgetRect.center, trailingSize);
          }

          Alignment alignment = getTrailingAlignment();
          expect(alignment.x, closeTo(-0.2963, 0.01));
          expect(alignment.y, closeTo(0, 0.01));

          await tester.pumpWidget(buildApp(textScaler: AccessibilityTextSize.xSmall));

          alignment = getTrailingAlignment();
          expect(alignment.x, closeTo(-0.2963, 0.01));
          expect(alignment.y, closeTo(0, 0.01));

          await tester.pumpWidget(buildApp());

          alignment = getTrailingAlignment();
          expect(alignment.x, closeTo(-0.2727, 0.01));
          expect(alignment.y, closeTo(0, 0.01));

          await tester.pumpWidget(buildApp(textScaler: AccessibilityTextSize.ax5));

          expect(find.byKey(Tag.trailing.key), findsNothing);

          await tester.pumpWidget(buildApp(textScaler: AccessibilityTextSize.oversized));

          expect(find.byKey(Tag.trailing.key), findsNothing);
        });

        testWidgets('trailingWidth adjusts to dynamic type', (WidgetTester tester) async {
          Widget buildApp({TextScaler textScaler = AccessibilityTextSize.large}) {
            return App(
              Builder(
                builder: (BuildContext context) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(textScaler: textScaler),
                    child: CupertinoMenuAnchor(
                      controller: controller,
                      menuChildren: <Widget>[
                        CupertinoMenuItem(
                          onPressed: () {},
                          leading: Icon(CupertinoIcons.left_chevron, key: Tag.leading.key),
                          trailing: Icon(CupertinoIcons.right_chevron, key: Tag.trailing.key),
                          subtitle: Text(Tag.subtitle.text),
                          child: Text(Tag.child.text),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }

          await tester.pumpWidget(buildApp(textScaler: AccessibilityTextSize.undersized));
          controller.open();
          await tester.pumpAndSettle();

          Rect childRect() => tester.getRect(find.text(Tag.child.text));
          Rect menuItemRect() => tester.getRect(find.byType(CupertinoMenuItem));
          double trailingWidth() => menuItemRect().right - childRect().right;

          expect(trailingWidth(), closeTo(40.5, 0.25));

          await tester.pumpWidget(buildApp(textScaler: AccessibilityTextSize.xSmall));

          expect(trailingWidth(), closeTo(40.5, 0.25));

          await tester.pumpWidget(buildApp());

          expect(trailingWidth(), closeTo(44.0, 0.1));

          await tester.pumpWidget(buildApp(textScaler: AccessibilityTextSize.ax5));

          expect(trailingWidth(), closeTo(16.0, 0.5));

          await tester.pumpWidget(buildApp(textScaler: AccessibilityTextSize.oversized));

          expect(trailingWidth(), closeTo(16.0, 0.5));
        });

        testWidgets('trailingWidth is quantized to pixel ratio', (WidgetTester tester) async {
          Widget buildApp({
            TextScaler textScaler = AccessibilityTextSize.large,
            double devicePixelRatio = 2.0,
          }) {
            return App(
              Builder(
                builder: (BuildContext context) {
                  return MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: textScaler, devicePixelRatio: devicePixelRatio),
                    child: CupertinoMenuAnchor(
                      controller: controller,
                      menuChildren: <Widget>[
                        CupertinoMenuItem(
                          onPressed: () {},
                          leading: Icon(CupertinoIcons.left_chevron, key: Tag.leading.key),
                          trailing: Icon(CupertinoIcons.right_chevron, key: Tag.trailing.key),
                          subtitle: Text(Tag.subtitle.text),
                          child: Text(Tag.child.text),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }

          await tester.pumpWidget(buildApp(textScaler: AccessibilityTextSize.xSmall));
          controller.open();
          await tester.pumpAndSettle();

          Rect childRect() => tester.getRect(find.text(Tag.child.text));
          Rect menuItemRect() => tester.getRect(find.byType(CupertinoMenuItem));

          final double trailingWidth2x = menuItemRect().right - childRect().right;
          expect(trailingWidth2x - trailingWidth2x.floorToDouble(), closeTo(1 / 2, 0.01));

          await tester.pumpWidget(
            buildApp(devicePixelRatio: 3.0, textScaler: AccessibilityTextSize.xSmall),
          );

          final double trailingWidth3x = menuItemRect().right - childRect().right;
          expect(trailingWidth3x - trailingWidth3x.floorToDouble(), closeTo(2 / 3, 0.01));
        });

        testWidgets('custom trailingWidth', (WidgetTester tester) async {
          await tester.pumpWidget(
            App(
              CupertinoMenuAnchor(
                controller: controller,
                menuChildren: <Widget>[
                  CupertinoMenuItem(
                    trailingWidth: 60,
                    trailing: Icon(CupertinoIcons.right_chevron, key: Tag.trailing.key),
                    child: Center(key: Tag.child.key, child: Text(Tag.child.text)),
                  ),
                ],
              ),
            ),
          );

          controller.open();
          await tester.pumpAndSettle();

          final Rect child = tester.getRect(find.byKey(Tag.child.key));
          final Rect menuItemRect = tester.getRect(find.byType(CupertinoMenuItem));
          final double trailingSpace = menuItemRect.right - child.right;

          expect(trailingSpace, moreOrLessEquals(60, epsilon: 1));
        });

        testWidgets('custom trailingMidpointAlignment', (WidgetTester tester) async {
          await tester.pumpWidget(
            App(
              CupertinoMenuAnchor(
                controller: controller,
                menuChildren: <Widget>[
                  CupertinoMenuItem(
                    padding: EdgeInsets.zero,
                    trailingWidth: 60,
                    trailingMidpointAlignment: const Alignment(0.5, 0.5),
                    trailing: Container(
                      color: CupertinoColors.systemRed,
                      width: 5,
                      height: 5,
                      key: Tag.trailing.key,
                    ),
                    onPressed: () {},
                    child: Center(key: Tag.child.key, child: Text(Tag.child.text)),
                  ),
                ],
              ),
            ),
          );

          controller.open();
          await tester.pumpAndSettle();

          final ui.Rect menuItemRect = tester.getRect(find.byType(CupertinoMenuItem));
          final ui.Rect childRect = tester.getRect(find.byKey(Tag.child.key));
          final double trailingWidth = menuItemRect.right - childRect.right;
          final Size trailingSize = ui.Size(trailingWidth, menuItemRect.height);
          final Rect trailingWidgetRect = tester
              .getRect(find.byKey(Tag.trailing.key))
              .translate(-childRect.right, -menuItemRect.top);
          final Alignment trailingAlignment = offsetAlongSize(
            trailingWidgetRect.center,
            trailingSize,
          );

          expect(trailingAlignment.x, closeTo(0.5, 0.01));
          expect(trailingAlignment.y, closeTo(0.5, 0.01));
        });
      });
      group('Subtitle ', () {
        testWidgets('default layout', (WidgetTester tester) async {
          await tester.pumpWidget(
            App(
              CupertinoMenuAnchor(
                controller: controller,
                menuChildren: <Widget>[
                  CupertinoMenuItem(
                    onPressed: () {},
                    leading: Icon(CupertinoIcons.left_chevron, key: Tag.leading.key),
                    trailing: Icon(CupertinoIcons.right_chevron, key: Tag.trailing.key),
                    subtitle: Text(Tag.subtitle.text),
                    child: Text(Tag.child.text),
                  ),
                ],
              ),
            ),
          );

          controller.open();
          await tester.pumpAndSettle();

          final double largeSubtitleLineHeight = lineHeight(_DynamicTypeStyle.subhead.large);
          final Rect subtitleRect = tester.getRect(find.text(Tag.subtitle.text));
          final Rect childRect = tester.getRect(find.text(Tag.child.text));

          expect(subtitleRect.height, closeTo(largeSubtitleLineHeight, 0.1));
          expect(subtitleRect.width, equals(childRect.width));
          expect(subtitleRect.top, closeTo(childRect.bottom + 1, 0.1));
          expect(subtitleRect.left, equals(childRect.left));
          expect(subtitleRect.right, equals(childRect.right));
        });

        testWidgets('subtitle text overflow', (WidgetTester tester) async {
          final String longText = 'Very long subtitle ' * 100;

          await tester.pumpWidget(
            App(
              CupertinoMenuAnchor(
                controller: controller,
                menuChildren: <Widget>[
                  CupertinoMenuItem(
                    onPressed: () {},
                    subtitle: Text(longText),
                    child: Text(Tag.child.text),
                  ),
                ],
              ),
            ),
          );

          controller.open();
          await tester.pumpAndSettle();

          final Size subtitleText = tester.getSize(find.text(longText));
          final TextStyle subtitleStyle = _DynamicTypeStyle.subhead.large;
          expect(subtitleText.height, closeTo(lineHeight(subtitleStyle) * 2, 1)); // 2 lines of text
        });

        testWidgets('subtitle text overflow in accessibility mode', (WidgetTester tester) async {
          final String longText = 'Very long text ' * 100;

          await tester.pumpWidget(
            App(
              MediaQuery(
                data: const MediaQueryData(textScaler: AccessibilityTextSize.ax1),
                child: CupertinoMenuAnchor(
                  controller: controller,
                  menuChildren: <Widget>[
                    CupertinoMenuItem(
                      onPressed: () {},
                      subtitle: Text(longText),
                      child: Text(Tag.child.text),
                    ),
                  ],
                ),
              ),
            ),
          );

          controller.open();
          await tester.pumpAndSettle();

          final RenderParagraph paragraph = findDescendantParagraph(tester, find.text(longText))!;
          expect(paragraph.maxLines, equals(CupertinoMenuItem.defaultAccessibilityModeMaxLines));
          expect(tester.getSize(find.text(longText)).height, closeTo(3100, 1));
        });

        testWidgets('subtitle adjusts to dynamic type', (WidgetTester tester) async {
          Widget buildApp({TextScaler textScaler = AccessibilityTextSize.large}) {
            return App(
              Builder(
                builder: (BuildContext context) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(textScaler: textScaler),
                    child: CupertinoMenuAnchor(
                      controller: controller,
                      menuChildren: <Widget>[
                        CupertinoMenuItem(
                          onPressed: () {},
                          leading: Icon(CupertinoIcons.left_chevron, key: Tag.leading.key),
                          trailing: Icon(CupertinoIcons.right_chevron, key: Tag.trailing.key),
                          subtitle: Text(Tag.subtitle.text),
                          child: Text(Tag.child.text),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }

          await tester.pumpWidget(buildApp(textScaler: AccessibilityTextSize.undersized));
          controller.open();
          await tester.pumpAndSettle();

          Rect subtitleRect = tester.getRect(find.text(Tag.subtitle.text));
          Rect childRect = tester.getRect(find.text(Tag.child.text));
          final double undersizedSubtitleLineHeight = lineHeight(_DynamicTypeStyle.subhead.xSmall);
          expect(subtitleRect.height, closeTo(undersizedSubtitleLineHeight, 0.1));
          expect(subtitleRect.top, closeTo(childRect.bottom + 1, 0.1));
          expect(subtitleRect.left, equals(childRect.left));
          expect(subtitleRect.right, equals(childRect.right));

          await tester.pumpWidget(buildApp(textScaler: AccessibilityTextSize.xSmall));

          childRect = tester.getRect(find.text(Tag.child.text));
          subtitleRect = tester.getRect(find.text(Tag.subtitle.text));
          final double xSmallSubtitleLineHeight = lineHeight(_DynamicTypeStyle.subhead.xSmall);
          expect(subtitleRect.height, closeTo(xSmallSubtitleLineHeight, 0.1));
          expect(subtitleRect.top, closeTo(childRect.bottom + 1, 0.1));
          expect(subtitleRect.left, equals(childRect.left));
          expect(subtitleRect.right, equals(childRect.right));

          await tester.pumpWidget(buildApp(textScaler: AccessibilityTextSize.ax5));
          await tester.pumpAndSettle();

          childRect = tester.getRect(find.text(Tag.child.text));
          subtitleRect = tester.getRect(find.text(Tag.subtitle.text));
          expect(subtitleRect.height, closeTo(110, 3));
          expect(subtitleRect.top, closeTo(childRect.bottom + 1, 0.1));
          expect(subtitleRect.left, equals(childRect.left));
          expect(subtitleRect.right, equals(childRect.right));

          await tester.pumpWidget(buildApp(textScaler: AccessibilityTextSize.oversized));

          childRect = tester.getRect(find.text(Tag.child.text));
          subtitleRect = tester.getRect(find.text(Tag.subtitle.text));
          expect(subtitleRect.height, closeTo(110, 3));
          expect(subtitleRect.top, closeTo(childRect.bottom + 1, 0.1));
          expect(subtitleRect.left, equals(childRect.left));
          expect(subtitleRect.right, equals(childRect.right));
        });
      });

      group('Padding', () {
        testWidgets('default padding', (WidgetTester tester) async {
          await tester.pumpWidget(
            App(
              CupertinoMenuAnchor(
                controller: controller,
                menuChildren: <Widget>[
                  CupertinoMenuItem(
                    onPressed: () {},
                    leadingWidth: 0,
                    trailingWidth: 0,
                    subtitle: Text(Tag.subtitle.text),
                    child: Text(Tag.child.text),
                  ),
                ],
              ),
            ),
          );

          controller.open();
          await tester.pumpAndSettle();

          final Rect menuItemRect = tester.getRect(find.byType(CupertinoMenuItem));
          final Rect childRect = tester.getRect(find.text(Tag.child.text));
          final Rect subtitleRect = tester.getRect(find.text(Tag.subtitle.text));

          expect(childRect.top - menuItemRect.top, closeTo(10.8, 0.1));
          expect(menuItemRect.bottom - subtitleRect.bottom, closeTo(10.8, 0.1));
          expect(childRect.left - menuItemRect.left, closeTo(0.0, 0.1));
          expect(menuItemRect.right - childRect.right, closeTo(0.0, 0.1));
        });

        testWidgets('padding adjusts to dynamic type', (WidgetTester tester) async {
          Widget buildApp({TextScaler textScaler = AccessibilityTextSize.large}) {
            return App(
              Builder(
                builder: (BuildContext context) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(textScaler: textScaler),
                    child: CupertinoMenuAnchor(
                      controller: controller,
                      menuChildren: <Widget>[
                        CupertinoMenuItem(
                          onPressed: () {},
                          subtitle: Text(Tag.subtitle.text),
                          child: Text(Tag.child.text),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }

          await tester.pumpWidget(buildApp(textScaler: AccessibilityTextSize.undersized));
          controller.open();
          await tester.pumpAndSettle();

          Rect getMenuItemRect() => tester.getRect(find.byType(CupertinoMenuItem));
          Rect getChildRect() => tester.getRect(find.text(Tag.child.text));
          Rect getSubtitleRect() => tester.getRect(find.text(Tag.subtitle.text));

          Rect childRect = getChildRect();
          Rect menuItemRect = getMenuItemRect();
          Rect subtitleRect = getSubtitleRect();

          expect(childRect.top - menuItemRect.top, closeTo(9.3, 0.1));
          expect(menuItemRect.bottom - subtitleRect.bottom, closeTo(9.3, 0.1));
          expect(childRect.left - menuItemRect.left, closeTo(16.0, 0.1));
          expect(menuItemRect.right - childRect.right, closeTo(16.0, 0.1));

          await tester.pumpWidget(buildApp(textScaler: AccessibilityTextSize.xSmall));

          childRect = getChildRect();
          menuItemRect = getMenuItemRect();
          subtitleRect = getSubtitleRect();

          expect(childRect.top - menuItemRect.top, closeTo(9.3, 0.1));
          expect(menuItemRect.bottom - subtitleRect.bottom, closeTo(9.3, 0.1));
          expect(childRect.left - menuItemRect.left, closeTo(16.0, 0.1));
          expect(menuItemRect.right - childRect.right, closeTo(16.0, 0.1));

          await tester.pumpWidget(buildApp(textScaler: AccessibilityTextSize.ax5));

          childRect = getChildRect();
          menuItemRect = getMenuItemRect();
          subtitleRect = getSubtitleRect();

          expect(childRect.top - menuItemRect.top, closeTo(30.5, 0.1));
          expect(menuItemRect.bottom - subtitleRect.bottom, closeTo(30.5, 0.1));
          expect(childRect.left - menuItemRect.left, closeTo(16.0, 0.1));
          expect(menuItemRect.right - childRect.right, closeTo(16.0, 0.1));

          await tester.pumpWidget(buildApp(textScaler: AccessibilityTextSize.oversized));

          childRect = getChildRect();
          menuItemRect = getMenuItemRect();
          subtitleRect = getSubtitleRect();

          expect(childRect.top - menuItemRect.top, closeTo(30.5, 0.1));
          expect(menuItemRect.bottom - subtitleRect.bottom, closeTo(30.5, 0.1));
          expect(childRect.left - menuItemRect.left, closeTo(16.0, 0.1));
          expect(menuItemRect.right - childRect.right, closeTo(16.0, 0.1));
        });

        testWidgets('LTR custom padding', (WidgetTester tester) async {
          await tester.pumpWidget(
            App(
              CupertinoMenuAnchor(
                controller: controller,
                menuChildren: <Widget>[
                  CupertinoMenuItem(
                    padding: const EdgeInsets.fromLTRB(7, 17, 13, 11),
                    onPressed: () {},
                    child: Center(key: Tag.child.key, child: Text(Tag.child.text)),
                  ),
                ],
              ),
            ),
          );

          controller.open();
          await tester.pumpAndSettle();

          final Rect child = tester.getRect(find.byKey(Tag.child.key));
          final Rect item = tester.getRect(find.byType(CupertinoMenuItem));

          expect(child.top - item.top, closeTo(17.0, 0.1));
          expect(item.bottom - child.bottom, closeTo(11.0, 0.1));

          // Padding is applied in addition to the leading and trailing width.
          expect(child.left - item.left, closeTo(7.0 + 16, 0.1));
          expect(item.right - child.right, closeTo(13.0 + 16, 0.1));
        });

        testWidgets('RTL custom padding', (WidgetTester tester) async {
          await tester.pumpWidget(
            App(
              Directionality(
                textDirection: TextDirection.rtl,
                child: CupertinoMenuAnchor(
                  controller: controller,
                  menuChildren: <Widget>[
                    CupertinoMenuItem(
                      padding: const EdgeInsetsDirectional.fromSTEB(7, 17, 13, 11),
                      onPressed: () {},
                      child: Center(key: Tag.child.key, child: Text(Tag.child.text)),
                    ),
                  ],
                ),
              ),
            ),
          );

          controller.open();
          await tester.pumpAndSettle();

          final Rect child = tester.getRect(find.byKey(Tag.child.key));
          final Rect item = tester.getRect(find.byType(CupertinoMenuItem));

          expect(child.top - item.top, closeTo(17.0, 0.1));
          expect(item.bottom - child.bottom, closeTo(11.0, 0.1));
          expect(item.right - child.right, closeTo(7.0 + 16, 0.1));
          expect(child.left - item.left, closeTo(13.0 + 16, 0.1));
        });

        testWidgets('LTR custom padding is added to leading and trailing width', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(
            App(
              Directionality(
                textDirection: TextDirection.ltr,
                child: CupertinoMenuAnchor(
                  controller: controller,
                  menuChildren: <Widget>[
                    CupertinoMenuItem(
                      padding: const EdgeInsetsDirectional.only(start: 7, end: 13),
                      leadingWidth: 19,
                      trailingWidth: 23,
                      onPressed: () {},
                      child: Center(key: Tag.child.key, child: Text(Tag.child.text)),
                    ),
                  ],
                ),
              ),
            ),
          );

          controller.open();
          await tester.pumpAndSettle();

          final Rect child = tester.getRect(find.byKey(Tag.child.key));
          final Rect item = tester.getRect(find.byType(CupertinoMenuItem));

          expect(item.right - child.right, closeTo(13.0 + 23, 0.1));
          expect(child.left - item.left, closeTo(7.0 + 19, 0.1));
        });

        testWidgets('RTL custom padding is added to leading and trailing width', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(
            App(
              Directionality(
                textDirection: TextDirection.rtl,
                child: CupertinoMenuAnchor(
                  controller: controller,
                  menuChildren: <Widget>[
                    CupertinoMenuItem(
                      padding: const EdgeInsetsDirectional.only(start: 7, end: 13),
                      leadingWidth: 19,
                      trailingWidth: 23,
                      onPressed: () {},
                      child: Center(key: Tag.child.key, child: Text(Tag.child.text)),
                    ),
                  ],
                ),
              ),
            ),
          );

          controller.open();
          await tester.pumpAndSettle();

          final Rect child = tester.getRect(find.byKey(Tag.child.key));
          final Rect item = tester.getRect(find.byType(CupertinoMenuItem));

          expect(item.right - child.right, closeTo(7.0 + 19, 0.1));
          expect(child.left - item.left, closeTo(13.0 + 23, 0.1));
        });

        testWidgets('padding is applied before constraints', (WidgetTester tester) async {
          await tester.pumpWidget(
            App(
              CupertinoMenuAnchor(
                controller: controller,
                menuChildren: <Widget>[
                  CupertinoMenuItem(
                    padding: const EdgeInsets.fromLTRB(30, 7, 30, 11),
                    constraints: const BoxConstraints(minHeight: 100, maxWidth: 50),
                    onPressed: () {},
                    child: Text(Tag.child.text),
                  ),
                ],
              ),
            ),
          );

          controller.open();
          await tester.pumpAndSettle();

          final Size menuItemRect = tester.getSize(find.byType(CupertinoMenuItem));

          expect(menuItemRect.height, equals(100));
          expect(menuItemRect.width, equals(50));
        });
      });

      group('Constraints', () {
        testWidgets('custom constraints applied', (WidgetTester tester) async {
          await tester.pumpWidget(
            App(
              CupertinoMenuAnchor(
                controller: controller,
                menuChildren: <Widget>[
                  CupertinoMenuItem(
                    constraints: const BoxConstraints(minHeight: 80, maxWidth: 100),
                    onPressed: () {},
                    child: const Text('Child'),
                  ),
                ],
              ),
            ),
          );

          controller.open();
          await tester.pumpAndSettle();

          final Size item = tester.getSize(find.byType(CupertinoMenuItem));

          expect(item.height, greaterThanOrEqualTo(80));
          expect(item.width, greaterThanOrEqualTo(100));
        });

        testWidgets('custom constraints are constrained by menu constraints', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(
            App(
              CupertinoMenuAnchor(
                controller: controller,
                menuChildren: <Widget>[
                  CupertinoMenuItem(
                    constraints: const BoxConstraints(minWidth: 500),
                    onPressed: () {},
                    child: const Text('Child'),
                  ),
                ],
              ),
            ),
          );

          controller.open();
          await tester.pumpAndSettle();

          final Size item = tester.getSize(find.byType(CupertinoMenuItem));

          expect(item.width, equals(262));
        });

        testWidgets('minimum height constraint adjusts to dynamic type', (
          WidgetTester tester,
        ) async {
          Widget buildApp({TextScaler textScaler = AccessibilityTextSize.large}) {
            return App(
              Builder(
                builder: (BuildContext context) {
                  return MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: textScaler, devicePixelRatio: 2.0),
                    child: CupertinoMenuAnchor(
                      controller: controller,
                      menuChildren: <Widget>[
                        CupertinoMenuItem(onPressed: () {}, child: Text(Tag.child.text)),
                      ],
                    ),
                  );
                },
              ),
            );
          }

          await tester.pumpWidget(buildApp(textScaler: AccessibilityTextSize.undersized));
          controller.open();
          await tester.pumpAndSettle();

          Rect menuItemRect = tester.getRect(find.byType(CupertinoMenuItem));
          expect(menuItemRect.height, closeTo(37.5, 0.1));

          await tester.pumpWidget(buildApp(textScaler: AccessibilityTextSize.xSmall));

          menuItemRect = tester.getRect(find.byType(CupertinoMenuItem));
          expect(menuItemRect.height, closeTo(37.5, 0.1));

          await tester.pumpWidget(buildApp());

          menuItemRect = tester.getRect(find.byType(CupertinoMenuItem));
          expect(menuItemRect.height, closeTo(43.5, 0.1));

          await tester.pumpWidget(buildApp(textScaler: AccessibilityTextSize.ax5));

          menuItemRect = tester.getRect(find.byType(CupertinoMenuItem));
          expect(menuItemRect.height, closeTo(123.0, 0.1));

          await tester.pumpWidget(buildApp(textScaler: AccessibilityTextSize.oversized));

          menuItemRect = tester.getRect(find.byType(CupertinoMenuItem));
          expect(menuItemRect.height, closeTo(123.0, 0.1));
        });

        testWidgets('minimum height constraint is quantized to pixel ratio', (
          WidgetTester tester,
        ) async {
          Widget buildApp({
            TextScaler textScaler = AccessibilityTextSize.large,
            required double devicePixelRatio,
          }) {
            return App(
              Builder(
                builder: (BuildContext context) {
                  return MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: textScaler, devicePixelRatio: devicePixelRatio),
                    child: CupertinoMenuAnchor(
                      controller: controller,
                      menuChildren: <Widget>[
                        CupertinoMenuItem(onPressed: () {}, child: Text(Tag.child.text)),
                      ],
                    ),
                  );
                },
              ),
            );
          }

          await tester.pumpWidget(buildApp(devicePixelRatio: 2.0));
          controller.open();
          await tester.pumpAndSettle();

          final double minimumHeight2x = tester.getSize(find.byType(CupertinoMenuItem)).height;

          expect(minimumHeight2x - minimumHeight2x.floorToDouble(), closeTo(1 / 2, 0.01));

          await tester.pumpWidget(buildApp(devicePixelRatio: 3.0));

          final double minimumHeight3x = tester.getSize(find.byType(CupertinoMenuItem)).height;

          expect(minimumHeight3x - minimumHeight3x.floorToDouble(), closeTo(2 / 3, 0.01));
        });

        testWidgets('unconstrained width outside of menu', (WidgetTester tester) async {
          await changeSurfaceSize(tester, const Size(800, 800));
          await tester.pumpWidget(
            App(
              Column(
                children: <Widget>[
                  Center(
                    child: CupertinoMenuItem(onPressed: () {}, child: Text(Tag.child.text)),
                  ),
                ],
              ),
            ),
          );
          final ui.Size size = tester.getSize(find.byType(CupertinoMenuItem));
          expect(size.width, equals(800));
          expect(size.height, closeTo(43.5, 0.25));

          // expect(minimumHeight2x - minimumHeight2x.floorToDouble(), closeTo(1 / 2, 0.01));

          // await tester.pumpWidget(buildApp(devicePixelRatio: 3.0));

          // final double minimumHeight3x = tester.getSize(find.byType(CupertinoMenuItem)).height;

          // expect(minimumHeight3x - minimumHeight3x.floorToDouble(), closeTo(2 / 3, 0.01));
        });
      });
    });

    testWidgets('onFocusChange is called on enabled items', (WidgetTester tester) async {
      final List<bool> focusChanges = <bool>[];
      final List<bool> disabledFocusChanges = <bool>[];
      final FocusNode focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        App(
          CupertinoMenuAnchor(
            controller: controller,
            menuChildren: <Widget>[
              CupertinoMenuItem(
                focusNode: focusNode,
                onFocusChange: focusChanges.add,
                onPressed: () {},
                child: Text(Tag.a.text),
              ),
              CupertinoMenuItem(onFocusChange: disabledFocusChanges.add, child: Text(Tag.b.text)),
              CupertinoMenuItem(child: Text(Tag.c.text), onPressed: () {}),
            ],
            child: const AnchorButton(Tag.anchor),
          ),
        ),
      );

      controller.open();
      await tester.pumpAndSettle();

      // Move focus to first item
      focusNode.requestFocus();
      await tester.pump();

      // Move focus away
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      // Move focus back
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      // Close menu, should lose focus
      controller.close();
      await tester.pumpAndSettle();

      expect(focusChanges, <bool>[true, false, true, false]);
      expect(disabledFocusChanges, isEmpty);
    });
    testWidgets('onHover is called on enabled items', (WidgetTester tester) async {
      final List<(Tag, bool)> hovered = <(Tag, bool)>[];

      await tester.pumpWidget(
        App(
          CupertinoMenuAnchor(
            controller: controller,
            menuChildren: <Widget>[
              CupertinoMenuItem(
                onHover: (bool value) {
                  hovered.add((Tag.a, value));
                },
                onPressed: () {},
                child: Text(Tag.a.text),
              ),

              // Disabled item -- should not request focus
              CupertinoMenuItem(
                onHover: (bool value) {
                  hovered.add((Tag.b, value));
                },
                child: Text(Tag.b.text, key: Tag.b.key),
              ),

              CupertinoMenuItem(
                onHover: (bool value) {
                  hovered.add((Tag.c, value));
                },
                onPressed: () {},
                child: Text(Tag.c.text),
              ),
            ],
          ),
        ),
      );

      controller.open();
      await tester.pumpAndSettle();

      final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);

      // (Tag.a, true)
      await gesture.moveTo(tester.getCenter(find.text(Tag.a.text)));
      await tester.pump();

      await gesture.moveTo(tester.getCenter(find.text(Tag.b.text)));
      await tester.pump();

      // (Tag.a, false)
      // (Tag.c, true)
      await gesture.moveTo(tester.getCenter(find.text(Tag.c.text)));
      await tester.pump();

      // (Tag.c, false)
      // (Tag.a, true)
      await gesture.moveTo(tester.getCenter(find.text(Tag.a.text)));
      await tester.pump();

      expect(hovered, <(Tag, bool)>[
        (Tag.a, true),
        (Tag.a, false),
        (Tag.c, true),
        (Tag.c, false),
        (Tag.a, true),
      ]);
    });

    testWidgets('onPressed is called when set', (WidgetTester tester) async {
      int pressed = 0;
      await tester.pumpWidget(
        App(
          CupertinoMenuAnchor(
            controller: controller,
            menuChildren: <Widget>[
              CupertinoMenuItem(
                onPressed: () {
                  pressed += 1;
                },
                child: Text(Tag.a.text),
              ),
            ],
          ),
        ),
      );

      controller.open();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap when partially open
      await tester.tap(find.text(Tag.a.text));
      await tester.pump();

      expect(pressed, 1);

      controller.open();
      await tester.pumpAndSettle();

      // Tap when fully open
      await tester.tap(find.text(Tag.a.text));
      await tester.pumpAndSettle();

      expect(pressed, 2);

      controller.open();
      await tester.pumpAndSettle();

      controller.close();

      await tester.pump();

      // Do not tap if closing.
      await tester.tap(find.text(Tag.a.text), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(pressed, 2);
    });

    testWidgets('HitTestBehavior can be set', (WidgetTester tester) async {
      await tester.pumpWidget(
        App(
          CupertinoMenuAnchor(
            controller: controller,
            menuChildren: <Widget>[
              CupertinoMenuItem(onPressed: () {}, child: Text(Tag.a.text)),
              CupertinoMenuItem(
                onPressed: () {},
                behavior: HitTestBehavior.translucent,
                child: Text(Tag.b.text),
              ),
            ],
          ),
        ),
      );

      controller.open();
      await tester.pumpAndSettle();

      final RawGestureDetector first = tester.firstWidget(
        find.widgetWithText(RawGestureDetector, Tag.a.text),
      );

      // Test default
      expect(first.behavior, HitTestBehavior.opaque);

      final RawGestureDetector second = tester.firstWidget(
        find.widgetWithText(RawGestureDetector, Tag.b.text),
      );

      // Test custom
      expect(second.behavior, HitTestBehavior.translucent);
    });

    testWidgets('respects requestFocusOnHover property', (WidgetTester tester) async {
      final List<(Tag, bool)> focusChanges = <(Tag, bool)>[];

      await tester.pumpWidget(
        App(
          CupertinoMenuAnchor(
            controller: controller,
            menuChildren: <Widget>[
              CupertinoMenuItem(
                onFocusChange: (bool value) {
                  focusChanges.add((Tag.a, value));
                },
                onPressed: () {},
                child: Text(Tag.a.text),
              ),

              // Disabled item -- should not request focus
              CupertinoMenuItem(
                onFocusChange: (bool value) {
                  focusChanges.add((Tag.b, value));
                },
                child: Text(Tag.b.text, key: Tag.b.key),
              ),

              CupertinoMenuItem(
                onFocusChange: (bool value) {
                  focusChanges.add((Tag.c, value));
                },
                onPressed: () {},
                child: Text(Tag.c.text),
              ),

              // requestFocusOnHover is false -- should not request focus
              CupertinoMenuItem(
                requestFocusOnHover: false,
                onFocusChange: (bool value) {
                  focusChanges.add((Tag.d, value));
                },
                onPressed: () {},
                child: Text(Tag.d.text),
              ),
            ],
          ),
        ),
      );

      controller.open();
      await tester.pumpAndSettle();

      final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);

      // (Tag.a, true)
      await gesture.moveTo(tester.getCenter(find.text(Tag.a.text)));
      await tester.pump();

      await gesture.moveTo(tester.getCenter(find.text(Tag.b.text)));
      await tester.pump();

      // (Tag.a, false)
      // (Tag.c, true)
      await gesture.moveTo(tester.getCenter(find.text(Tag.c.text)));
      await tester.pump();

      await gesture.moveTo(tester.getCenter(find.text(Tag.d.text)));
      await tester.pump();

      // (Tag.c, false)
      // (Tag.a, true)
      await gesture.moveTo(tester.getCenter(find.text(Tag.a.text)));
      await tester.pump();

      expect(focusChanges, <(Tag, bool)>[
        (Tag.a, true),
        (Tag.a, false),
        (Tag.c, true),
        (Tag.c, false),
        (Tag.a, true),
      ]);
    });

    testWidgets('respects closeOnActivate property', (WidgetTester tester) async {
      await tester.pumpWidget(
        App(
          CupertinoMenuAnchor(
            controller: controller,
            menuChildren: <Widget>[
              CupertinoMenuItem(
                requestCloseOnActivate: false,
                onPressed: () {},
                child: Text(Tag.a.text),
              ),
            ],
          ),
        ),
      );

      controller.open();
      await tester.pumpAndSettle();

      // Taps the CupertinoMenuItem which should close the menu
      await tester.tap(find.text(Tag.a.text));
      await tester.pumpAndSettle();

      expect(controller.isOpen, isTrue);

      await tester.pumpWidget(
        App(
          CupertinoMenuAnchor(
            controller: controller,
            menuChildren: <Widget>[
              CupertinoMenuItem(key: UniqueKey(), onPressed: () {}, child: Text(Tag.a.text)),
            ],
          ),
        ),
      );
      // Taps the CupertinoMenuItem which should close the menu
      await tester.tap(find.byType(CupertinoMenuItem));
      await tester.pumpAndSettle();

      expect(controller.isOpen, isFalse);
    });
  });

  group('Semantics', () {
    testWidgets('CupertinoMenuItem default semantics', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: CupertinoMenuItem(
              onPressed: () {},
              constraints: BoxConstraints.tight(const Size(250, 48.0)),
              child: Text(Tag.a.text),
            ),
          ),
        ),
      );
      final SemanticsHandle handle = tester.ensureSemantics();

      // The flags should not have SemanticsFlag.isButton
      expect(
        tester.getSemantics(find.widgetWithText(CupertinoMenuItem, Tag.a.text)),
        matchesSemantics(
          hasTapAction: true,
          hasDismissAction: true,
          hasFocusAction: true,
          isEnabled: true,
          isFocusable: true,
          hasEnabledState: true,
          textDirection: TextDirection.rtl,
          rect: const Rect.fromLTRB(0.0, 0.0, 250, 48),
        ),
      );
      handle.dispose();
    });

    testWidgets('CupertinoMenuItem disabled semantics', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: CupertinoMenuItem(
              constraints: BoxConstraints.tight(const Size(250, 48.0)),
              child: Text(Tag.a.text),
            ),
          ),
        ),
      );

      final SemanticsHandle handle = tester.ensureSemantics();

      // The flags should not have SemanticsFlag.isButton
      expect(
        tester.getSemantics(find.widgetWithText(CupertinoMenuItem, Tag.a.text)),
        matchesSemantics(
          hasEnabledState: true,
          textDirection: TextDirection.ltr,
          rect: const Rect.fromLTRB(0.0, 0.0, 250, 48),
        ),
      );

      handle.dispose();
    });

    testWidgets('CupertinoMenuAnchor semantics', (WidgetTester tester) async {
      final SemanticsTester semantics = SemanticsTester(tester);
      await tester.pumpWidget(
        App(
          CupertinoMenuAnchor(
            menuChildren: <Widget>[
              CupertinoMenuItem(
                onPressed: () {},
                constraints: BoxConstraints.tight(const Size(250, 48.0)),
                child: Text(Tag.a.text),
              ),
            ],
            child: const AnchorButton(Tag.anchor),
          ),
        ),
      );

      await tester.tap(find.byType(AnchorButton));
      await tester.pumpAndSettle();

      expect(
        semantics,
        hasSemantics(
          ignoreId: true,
          ignoreTransform: true,
          ignoreRect: true,
          ignoreTraversalIdentifier: true,
          TestSemantics.root(
            children: <TestSemantics>[
              TestSemantics(
                id: 1,
                textDirection: TextDirection.ltr,
                children: <TestSemantics>[
                  TestSemantics(
                    id: 2,
                    children: <TestSemantics>[
                      TestSemantics(
                        id: 3,
                        flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                        children: <TestSemantics>[
                          TestSemantics(
                            id: 4,
                            flags: <SemanticsFlag>[
                              SemanticsFlag.isButton,
                              SemanticsFlag.isFocusable,
                            ],
                            actions: <SemanticsAction>[SemanticsAction.tap, SemanticsAction.focus],
                            label: 'anchor',
                            textDirection: TextDirection.ltr,
                            children: <TestSemantics>[
                              TestSemantics(
                                id: 5,
                                children: <TestSemantics>[
                                  TestSemantics(
                                    id: 6,
                                    flags: <SemanticsFlag>[
                                      SemanticsFlag.scopesRoute,
                                      SemanticsFlag.namesRoute,
                                    ],
                                    children: <TestSemantics>[
                                      TestSemantics(
                                        id: 7,
                                        flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
                                        children: <TestSemantics>[
                                          TestSemantics(
                                            id: 8,
                                            flags: <SemanticsFlag>[
                                              SemanticsFlag.hasEnabledState,
                                              SemanticsFlag.isEnabled,
                                              SemanticsFlag.isFocusable,
                                            ],
                                            actions: <SemanticsAction>[
                                              SemanticsAction.tap,
                                              SemanticsAction.dismiss,
                                              SemanticsAction.focus,
                                            ],
                                            label: 'a',
                                            textDirection: TextDirection.ltr,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      semantics.dispose();
    });
  });
}

// ********* UTILITIES *********  //
/// Allows the creation of arbitrarily-nested tags in tests.
abstract class Tag {
  const Tag();

  static const NestedTag anchor = NestedTag('anchor');
  static const NestedTag outside = NestedTag('outside');
  static const NestedTag a = NestedTag('a');
  static const NestedTag b = NestedTag('b');
  static const NestedTag c = NestedTag('c');
  static const NestedTag d = NestedTag('d');

  static const NestedTag child = NestedTag('child');
  static const NestedTag subtitle = NestedTag('subtitle');
  static const NestedTag leading = NestedTag('leading');
  static const NestedTag trailing = NestedTag('trailing');

  String get text;
  int get level;

  @override
  String toString() {
    return 'Tag($text, level: $level)';
  }
}

class NestedTag extends Tag {
  const NestedTag(String name, {Tag? prefix, this.level = 0})
    : assert(
        // Limit the nesting level to prevent stack overflow.
        level < 9,
        'NestedTag.level must be less than 9 (was $level).',
      ),
      _name = name,
      _prefix = prefix;

  final String _name;
  final Tag? _prefix;

  @override
  final int level;

  NestedTag get a => NestedTag('a', prefix: this, level: level + 1);
  NestedTag get b => NestedTag('b', prefix: this, level: level + 1);
  NestedTag get c => NestedTag('c', prefix: this, level: level + 1);

  @override
  String get text {
    if (level == 0 || _prefix == null) {
      return _name;
    }
    return '${_prefix.text}.$_name';
  }

  Key get key => ValueKey<String>('${text}_Key');
}

class MenuItem extends StatelessWidget {
  const MenuItem(
    this.child, {
    super.key,
    this.onPressed = _onPressed,
    this.focusNode,
    this.autofocus = false,
    this.onFocusChange,
    this.constraints,
  });

  factory MenuItem.text(
    String text, {
    Key? key,
    VoidCallback? onPressed = _onPressed,
    FocusNode? focusNode,
    bool autofocus = false,
    BoxConstraints? constraints,
    void Function(bool)? onFocusChange,
  }) {
    return MenuItem(
      Text(text),
      key: key,
      onPressed: onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      constraints: constraints,
      onFocusChange: onFocusChange,
    );
  }

  factory MenuItem.tag(
    Tag tag, {
    Key? key,
    VoidCallback? onPressed = _onPressed,
    FocusNode? focusNode,
    bool autofocus = false,
    BoxConstraints? constraints,
    void Function(bool)? onFocusChange,
  }) {
    return MenuItem(
      Text(tag.text),
      key: key,
      onPressed: onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      constraints: constraints,
      onFocusChange: onFocusChange,
    );
  }

  static void _onPressed() {}

  final Widget child;
  final VoidCallback? onPressed;
  final void Function(bool)? onFocusChange;
  final FocusNode? focusNode;
  final bool autofocus;
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    if (constraints != null) {
      return CupertinoMenuItem(
        constraints: constraints,
        onPressed: onPressed,
        onFocusChange: onFocusChange,
        focusNode: focusNode,
        autofocus: autofocus,
        child: child,
      );
    } else {
      return CupertinoMenuItem(
        onPressed: onPressed,
        onFocusChange: onFocusChange,
        focusNode: focusNode,
        autofocus: autofocus,
        child: child,
      );
    }
  }
}

class AnchorButton extends StatelessWidget {
  const AnchorButton(
    this.tag, {
    super.key,
    this.onPressed,
    this.constraints,
    this.autofocus = false,
    this.focusNode,
  });

  final Tag tag;
  final void Function(Tag)? onPressed;
  final bool autofocus;
  final BoxConstraints? constraints;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final MenuController? controller = MenuController.maybeOf(context);
    return CupertinoButton.filled(
      minimumSize: constraints?.biggest,
      onPressed: () {
        onPressed?.call(tag);
        if (controller != null) {
          if (controller.isOpen) {
            controller.close();
          } else {
            controller.open();
          }
        }
      },
      focusNode: focusNode,
      autofocus: autofocus,
      child: Text(tag.text),
    );
  }
}

class App extends StatefulWidget {
  const App(this.child, {super.key, this.textDirection, this.alignment = Alignment.center});
  final Widget child;
  final TextDirection? textDirection;
  final AlignmentGeometry alignment;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  TextDirection? _directionality;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _directionality = Directionality.maybeOf(context);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      home: ColoredBox(
        color: const Color(0xff000000),
        child: Directionality(
          textDirection: widget.textDirection ?? _directionality ?? TextDirection.ltr,
          child: Align(alignment: widget.alignment, child: widget.child),
        ),
      ),
    );
  }
}

abstract class AccessibilityTextSize {
  static const TextScaler xSmall = TextScaler.linear(1 - 3 / 17);
  static const TextScaler small = TextScaler.linear(1 - 2 / 17);
  static const TextScaler medium = TextScaler.linear(1 - 1 / 17);
  static const TextScaler large = TextScaler.noScaling;
  static const TextScaler xLarge = TextScaler.linear(1 + 2 / 17);
  static const TextScaler xxLarge = TextScaler.linear(1 + 4 / 17);
  static const TextScaler xxxLarge = TextScaler.linear(1 + 6 / 17);
  static const TextScaler ax1 = TextScaler.linear(1 + 11 / 17);
  static const TextScaler ax2 = TextScaler.linear(1 + 16 / 17);
  static const TextScaler ax3 = TextScaler.linear(1 + 23 / 17);
  static const TextScaler ax4 = TextScaler.linear(1 + 30 / 17);
  static const TextScaler ax5 = TextScaler.linear(1 + 36 / 17);

  // For testing
  static const TextScaler oversized = TextScaler.linear(1 + 46 / 17);
  static const TextScaler undersized = TextScaler.linear(1 - 10 / 17);

  static List<TextScaler> get values => <TextScaler>[
    xSmall,
    small,
    medium,
    large,
    xLarge,
    xxLarge,
    xxxLarge,
    ax1,
    ax2,
    ax3,
    ax4,
    ax5,
  ];
}

/// The font family for menu items at smaller text scales.
const String _kBodyFont = 'CupertinoSystemText';

/// The font family for menu items at larger text scales.
const String _kDisplayFont = 'CupertinoSystemDisplay';

enum _DynamicTypeStyle {
  body(
    xSmall: TextStyle(fontSize: 14, height: 19 / 14, letterSpacing: -0.41, fontFamily: _kBodyFont),
    small: TextStyle(fontSize: 15, height: 20 / 15, letterSpacing: -0.41, fontFamily: _kBodyFont),
    medium: TextStyle(fontSize: 16, height: 21 / 16, letterSpacing: -0.41, fontFamily: _kBodyFont),
    large: TextStyle(fontSize: 17, height: 22 / 17, letterSpacing: -0.41, fontFamily: _kBodyFont),
    xLarge: TextStyle(fontSize: 19, height: 24 / 19, letterSpacing: -0.41, fontFamily: _kBodyFont),
    xxLarge: TextStyle(fontSize: 21, height: 26 / 21, letterSpacing: -0.8, fontFamily: _kBodyFont),
    xxxLarge: TextStyle(
      fontSize: 23,
      height: 29 / 23,
      letterSpacing: 0.38,
      fontFamily: _kDisplayFont,
    ),
    ax1: TextStyle(fontSize: 28, height: 34 / 28, letterSpacing: 0.38, fontFamily: _kDisplayFont),
    ax2: TextStyle(fontSize: 33, height: 40 / 33, letterSpacing: 0.38, fontFamily: _kDisplayFont),
    ax3: TextStyle(fontSize: 40, height: 48 / 40, letterSpacing: 0.38, fontFamily: _kDisplayFont),
    ax4: TextStyle(fontSize: 47, height: 56 / 47, letterSpacing: 0.38, fontFamily: _kDisplayFont),
    ax5: TextStyle(fontSize: 53, height: 62 / 53, letterSpacing: 0.38, fontFamily: _kDisplayFont),
  ),
  subhead(
    xSmall: TextStyle(fontSize: 12, height: 16 / 12, letterSpacing: -0.025, fontFamily: _kBodyFont),
    small: TextStyle(fontSize: 13, height: 18 / 13, letterSpacing: -0.025, fontFamily: _kBodyFont),
    medium: TextStyle(fontSize: 14, height: 19 / 14, letterSpacing: -0.025, fontFamily: _kBodyFont),
    large: TextStyle(fontSize: 15, height: 20 / 15, letterSpacing: -0.2, fontFamily: _kBodyFont),
    xLarge: TextStyle(fontSize: 17, height: 22 / 17, letterSpacing: -0.41, fontFamily: _kBodyFont),
    xxLarge: TextStyle(fontSize: 19, height: 24 / 19, letterSpacing: -0.68, fontFamily: _kBodyFont),
    xxxLarge: TextStyle(
      fontSize: 21,
      height: 28 / 21,
      letterSpacing: -0.68,
      fontFamily: _kBodyFont,
    ),
    ax1: TextStyle(fontSize: 25, height: 31 / 25, letterSpacing: 0.38, fontFamily: _kDisplayFont),
    ax2: TextStyle(fontSize: 30, height: 37 / 30, letterSpacing: 0.38, fontFamily: _kDisplayFont),
    ax3: TextStyle(fontSize: 36, height: 43 / 36, letterSpacing: 0.38, fontFamily: _kDisplayFont),
    ax4: TextStyle(fontSize: 42, height: 50 / 42, letterSpacing: 0.38, fontFamily: _kDisplayFont),
    ax5: TextStyle(fontSize: 49, height: 58 / 49, letterSpacing: 0.38, fontFamily: _kDisplayFont),
  );

  const _DynamicTypeStyle({
    required this.xSmall,
    required this.small,
    required this.medium,
    required this.large,
    required this.xLarge,
    required this.xxLarge,
    required this.xxxLarge,
    required this.ax1,
    required this.ax2,
    required this.ax3,
    required this.ax4,
    required this.ax5,
  });

  final TextStyle xSmall;
  final TextStyle small;
  final TextStyle medium;
  final TextStyle large;
  final TextStyle xLarge;
  final TextStyle xxLarge;
  final TextStyle xxxLarge;
  final TextStyle ax1;
  final TextStyle ax2;
  final TextStyle ax3;
  final TextStyle ax4;
  final TextStyle ax5;

  double _interpolateUnits(double units, int minimum, int maximum) {
    final double t = (units - minimum) / (maximum - minimum);
    return ui.lerpDouble(0, 1, t)!;
  }

  // The following units were measured from the iOS 18.5 simulator in points.
  TextStyle resolveTextStyle(TextScaler textScaler, {bool round = false}) {
    double units = textScaler.scale(17) - 17;
    if (round) {
      units = units.roundToDouble();
    }
    return switch (units) {
      <= -3 => xSmall,
      < -2 => TextStyle.lerp(xSmall, small, _interpolateUnits(units, -3, -2))!,
      < -1 => TextStyle.lerp(small, medium, _interpolateUnits(units, -2, -1))!,
      < 0 => TextStyle.lerp(medium, large, _interpolateUnits(units, -1, 0))!,
      < 2 => TextStyle.lerp(large, xLarge, _interpolateUnits(units, 0, 2))!,
      < 4 => TextStyle.lerp(xLarge, xxLarge, _interpolateUnits(units, 2, 4))!,
      < 6 => TextStyle.lerp(xxLarge, xxxLarge, _interpolateUnits(units, 4, 6))!,
      < 11 => TextStyle.lerp(xxxLarge, ax1, _interpolateUnits(units, 6, 11))!,
      < 16 => TextStyle.lerp(ax1, ax2, _interpolateUnits(units, 11, 16))!,
      < 23 => TextStyle.lerp(ax2, ax3, _interpolateUnits(units, 16, 23))!,
      < 30 => TextStyle.lerp(ax3, ax4, _interpolateUnits(units, 23, 30))!,
      < 36 => TextStyle.lerp(ax4, ax5, _interpolateUnits(units, 30, 36))!,
      _ => ax5,
    };
  }
}

class _DebugCupertinoMenuEntryMixin extends StatelessWidget with CupertinoMenuEntryMixin {
  const _DebugCupertinoMenuEntryMixin({
    this.hasLeading = false,
    this.allowTrailingSeparator = false,
    this.allowLeadingSeparator = false,
    this.child = const SizedBox.shrink(),
  });

  @override
  final bool hasLeading;

  @override
  final bool allowTrailingSeparator;

  @override
  final bool allowLeadingSeparator;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
