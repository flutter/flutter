// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const Duration kMenuOpenDuration = Duration(milliseconds: 900);
const Duration kMenuCloseDuration = Duration(milliseconds: 700);

void main() {
  late MenuController controller;
  String? focusedMenu;
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

  T findMenuPanelAncestor<T extends Widget>(WidgetTester tester) {
    return tester.firstWidget<T>(
      find.ancestor(of: find.byType(CupertinoPopupSurface), matching: find.byType(T)),
    );
  }

  double getScale(WidgetTester tester) {
    return findMenuPanelAncestor<ScaleTransition>(tester).scale.value;
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

  testWidgets('MenuOverlayPosition.anchorRect applies transformations to panel', (
    WidgetTester tester,
  ) async {
    final GlobalKey<State<StatefulWidget>> panelKey = GlobalKey();
    final Matrix4 matrix = Matrix4.translationValues(50, 50, 0)..scale(1.2);
    Widget builder(Matrix4 matrix) {
      return App(
        alignment: Alignment.topLeft,
        Transform(
          transform: matrix,
          child: CupertinoMenuAnchor(
            overlayPadding: EdgeInsets.zero,
            alignment: Alignment.topLeft,
            menuAlignment: Alignment.topLeft,
            controller: controller,
            menuChildren: <Widget>[
              Container(key: panelKey, width: 50, height: 50, color: const Color(0xFF0000FF)),
            ],
            child: const AnchorButton(Tag.anchor),
          ),
        ),
      );
    }

    // Get the initial position of the anchor.
    await tester.pumpWidget(builder(Matrix4.identity()));

    controller.open();
    await tester.pump(kMenuOpenDuration);

    final Rect panelPosition = tester.getRect(find.byKey(panelKey));

    controller.close();
    await tester.pump(kMenuOpenDuration);

    await tester.pumpWidget(builder(matrix));

    controller.open();
    await tester.pump(kMenuOpenDuration);

    final Rect transformedPanelPosition = tester.getRect(find.byKey(panelKey));

    expect(transformedPanelPosition, equals(MatrixUtils.transformRect(matrix, panelPosition)));
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
            menuChildren: <Widget>[Button.tag(Tag.a, focusNode: aFocusNode)],
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

    // DismissIntent should not close the menu.
    expect(invokedAnchor, isTrue);
    expect(invokedOverlay, isTrue);
  });

  testWidgets('DismissMenuAction closes menu', (WidgetTester tester) async {
    final FocusNode anchorFocusNode = FocusNode();
    final FocusNode aFocusNode = FocusNode();
    addTearDown(anchorFocusNode.dispose);
    addTearDown(aFocusNode.dispose);

    await tester.pumpWidget(
      App(
        CupertinoMenuAnchor(
          controller: controller,
          menuChildren: <Widget>[Button.tag(Tag.a, focusNode: aFocusNode)],
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

  testWidgets('Menus close and consume tap when consumesOutsideTap is true', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      App(
        Column(
          children: <Widget>[
            Button.tag(
              Tag.outside,
              onPressed: () {
                selected.add(Tag.outside);
              },
            ),
            CupertinoMenuAnchor(
              onOpen: () => onOpen(Tag.anchor),
              onClose: () => onClose(Tag.anchor),
              menuChildren: <Widget>[Button.tag(Tag.a)],
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

  testWidgets('Menus close and do not consume tap when consumesOutsideTap is false', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      App(
        Column(
          children: <Widget>[
            Button.tag(
              Tag.outside,
              onPressed: () {
                selected.add(Tag.outside);
              },
            ),
            CupertinoMenuAnchor(
              consumeOutsideTaps: false,
              onOpen: () => onOpen(Tag.anchor),
              onClose: () => onClose(Tag.anchor),
              menuChildren: <Widget>[Button.tag(Tag.a)],
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

    expect(opened, equals(<Tag>[Tag.anchor]));
    expect(closed, isEmpty);
    expect(selected, equals(<Tag>[Tag.anchor]));

    opened.clear();
    closed.clear();
    selected.clear();

    await tester.tap(find.text(Tag.outside.text));
    await tester.pumpAndSettle();

    // Because consumesOutsideTap is false, outsideButton is expected to
    // receive a tap.
    expect(opened, isEmpty);
    expect(closed, equals(<Tag>[Tag.anchor]));
    expect(selected, equals(<Tag>[Tag.outside]));

    selected.clear();
    opened.clear();
    closed.clear();
  });

  testWidgets('onOpen is called when the menu is opened', (WidgetTester tester) async {
    bool opened = false;
    await tester.pumpWidget(
      App(
        CupertinoMenuAnchor(
          controller: controller,
          onOpen: () {
            opened = true;
          },
          menuChildren: const <Widget>[],
          child: const AnchorButton(Tag.anchor),
        ),
      ),
    );
    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();

    expect(opened, isTrue);

    opened = false;
    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();

    // onOpen should not be called again.
    expect(opened, isFalse);

    controller.open();
    await tester.pump();

    expect(opened, isTrue);
  });

  testWidgets('onClose is called when the menu is closed', (WidgetTester tester) async {
    bool closed = true;
    await tester.pumpWidget(
      App(
        CupertinoMenuAnchor(
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

    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();
    await tester.pump(kMenuCloseDuration);

    expect(closed, isTrue);

    controller.open();
    await tester.pump();

    expect(closed, isFalse);

    controller.close();
    await tester.pump();

    expect(closed, isTrue);
  });

  testWidgets('diagnostics', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    final Widget menuAnchor = CupertinoMenuAnchor(
      controller: controller,
      childFocusNode: focusNode,
      menuChildren: <Widget>[Text(Tag.a.text)],
    );

    await tester.pumpWidget(App(menuAnchor));
    controller.open();
    await tester.pump();

    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    menuAnchor.debugFillProperties(builder);
    final List<String> properties =
        builder.properties
            .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
            .map((DiagnosticsNode node) => node.toString())
            .toList();

    expect(properties, const <String>['has focusNode', 'use nearest overlay']);
  });

  testWidgets('Tab traversal is not handled', (WidgetTester tester) async {
    final FocusNode bFocusNode = FocusNode(debugLabel: Tag.b.focusNode);
    final FocusNode bbFocusNode = FocusNode(debugLabel: Tag.b.b.focusNode);
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
                  Button.tag(Tag.a),
                  CupertinoMenuAnchor(
                    menuChildren: <Widget>[
                      Button.tag(Tag.b.a),
                      Shortcuts(
                        shortcuts: defaultTraversalShortcuts,
                        child: Button.tag(Tag.b.b, focusNode: bbFocusNode),
                      ),
                      Button.tag(Tag.b.c),
                    ],
                    child: Shortcuts(
                      shortcuts: defaultTraversalShortcuts,
                      child: AnchorButton(Tag.b, focusNode: bFocusNode),
                    ),
                  ),
                  Button.tag(Tag.c),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    listenForFocusChanges();

    bFocusNode.requestFocus();
    await tester.pump();

    expect(focusedMenu, equals(Tag.b.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(focusedMenu, equals(Tag.b.focusNode));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pump();

    expect(focusedMenu, equals(Tag.b.focusNode));

    // Open and move focus to nested menu
    await tester.tap(find.text(Tag.b.text));
    await tester.pump();
    await tester.pump(kMenuOpenDuration);

    bbFocusNode.requestFocus();
    await tester.pump();

    expect(focusedMenu, equals(Tag.b.b.focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(focusedMenu, equals(Tag.b.b.focusNode));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pump();

    expect(focusedMenu, equals(Tag.b.b.focusNode));
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
              Button.tag(Tag.a),
              Button.tag(Tag.b),
              Button.tag(Tag.c),
              Button.tag(Tag.d),
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
                Button.tag(Tag.a, constraints: largeButtonConstraints),
                Button.tag(Tag.b, constraints: largeButtonConstraints),
                Button.tag(Tag.c, constraints: largeButtonConstraints),
                Button.tag(Tag.d, constraints: largeButtonConstraints),
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

  // Copied from [MenuAnchor] tests.
  //
  // Regression test for https://github.com/flutter/flutter/issues/157606.
  testWidgets('Menu builder rebuilds when isOpen state changes', (WidgetTester tester) async {
    bool isOpen = false;
    int openCount = 0;
    int closeCount = 0;

    await tester.pumpWidget(
      App(
        CupertinoMenuAnchor(
          menuChildren: <Widget>[Button.text('Menu Item')],
          builder: (BuildContext context, MenuController controller, Widget? child) {
            isOpen = controller.isOpen;
            return Button(
              Text(isOpen ? 'close' : 'open'),
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
                    menuChildren: <Widget>[Button.tag(Tag.a)],
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

    final RenderObject menuTheater =
        findAncestorRenderTheaters(tester.renderObject(find.text(Tag.a.text))).first;

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
                    menuChildren: <Widget>[Button.tag(Tag.a)],
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
    final RenderObject menuTheater =
        findAncestorRenderTheaters(tester.renderObject(find.text(Tag.a.text))).first;

    // Check that the ancestor _RenderTheater for the menu item is the one
    // from the root overlay.
    expect(menuTheater, tester.renderObject(find.byWidget(nonRootOverlay)));
  });

  testWidgets('Parent updates are not triggered during builds', (WidgetTester tester) async {
    Widget build() {
      return App(
        RawMenuAnchorGroup(
          controller: controller,
          child: const CupertinoMenuAnchor(
            menuChildren: <Widget>[],
            child: AnchorButton(Tag.anchor),
          ),
        ),
      );
    }

    await tester.pumpWidget(build());
    await tester.tap(find.text(Tag.anchor.text));
    await tester.pump();

    const Size smallSize = Size(200, 200);
    await changeSurfaceSize(tester, smallSize);

    await tester.pumpWidget(build());
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Panning scales the menu', (WidgetTester tester) async {
    Future<void> pumpFrames(int frames) async {
      for (int i = 0; i < frames; i++) {
        await tester.pump();
      }
    }

    await changeSurfaceSize(tester, const Size(2000, 2000));
    await tester.pumpWidget(
      App(
        CupertinoMenuAnchor(
          controller: controller,
          menuChildren: <Widget>[Button.tag(Tag.a)],
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
    expect(getScale(tester), moreOrLessEquals(1.0, epsilon: 0.01));

    await gesture.moveTo(menuRect.topRight);
    await tester.pump();
    await pumpFrames(10);
    expect(getScale(tester), moreOrLessEquals(1.0, epsilon: 0.01));

    await gesture.moveTo(menuRect.bottomLeft);
    await tester.pump();
    await pumpFrames(10);
    expect(getScale(tester), moreOrLessEquals(1.0, epsilon: 0.01));

    await gesture.moveTo(menuRect.bottomRight);
    await tester.pump();
    await pumpFrames(10);
    expect(getScale(tester), moreOrLessEquals(1.0, epsilon: 0.01));

    // Move outside the menu bounds to trigger scaling
    await gesture.moveTo(menuRect.topLeft - const Offset(50, 50));
    await pumpFrames(3);

    double topLeftScale = getScale(tester);
    expect(topLeftScale, lessThan(0.98));
    expect(topLeftScale, greaterThan(0.95));

    await pumpFrames(3);

    topLeftScale = getScale(tester);
    expect(topLeftScale, lessThan(0.96));
    expect(topLeftScale, greaterThan(0.93));

    await pumpFrames(3);

    topLeftScale = getScale(tester);
    expect(topLeftScale, lessThan(0.94));
    expect(topLeftScale, greaterThan(0.89));

    await gesture.moveTo(menuRect.bottomRight + const Offset(50, 50));
    await pumpFrames(10);

    // Check that scale is roughly the same around the menu
    expect(getScale(tester), moreOrLessEquals(topLeftScale, epsilon: 0.05));

    // Test maximum distance scaling
    await gesture.moveTo(menuRect.topLeft - const Offset(200, 200));
    await pumpFrames(20);

    // Check that the minimum scale is 0.8 (20% reduction)
    expect(getScale(tester), moreOrLessEquals(0.8, epsilon: 0.01));

    await gesture.moveTo(menuRect.bottomRight + const Offset(200, 200));
    await pumpFrames(10);

    expect(getScale(tester), moreOrLessEquals(0.8, epsilon: 0.01));

    await gesture.up();
    await tester.pump();
  });

  testWidgets('Panning minimum scale is 80 percent', (WidgetTester tester) async {
    Future<void> pumpFrames(int frames) async {
      for (int i = 0; i < frames; i++) {
        await tester.pump();
      }
    }

    await changeSurfaceSize(tester, const Size(2000, 2000));
    await tester.pumpWidget(
      App(
        CupertinoMenuAnchor(
          controller: controller,
          menuChildren: <Widget>[Button.tag(Tag.a)],
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

  testWidgets('Menu scale rebounds to full size when pan returns to menu bounds', (
    WidgetTester tester,
  ) async {
    Future<void> pumpFrames(int frames) async {
      for (int i = 0; i < frames; i++) {
        await tester.pump();
      }
    }

    await changeSurfaceSize(tester, const Size(2000, 2000));
    await tester.pumpWidget(
      App(
        CupertinoMenuAnchor(
          controller: controller,
          menuChildren: <Widget>[Button.tag(Tag.a)],
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

    // Move back to menu bounds
    await gesture.moveTo(menuRect.center);
    await pumpFrames(20);

    // Verify scale rebounds back to full size
    expect(getScale(tester), moreOrLessEquals(1.0, epsilon: 0.01));

    // Test rebound from different scaled position
    await gesture.moveTo(menuRect.bottomRight + const Offset(150, 150));
    await pumpFrames(20);

    expect(getScale(tester), lessThan(1.0));

    // Return to menu area again
    await gesture.moveTo(menuRect.topLeft);
    await pumpFrames(100);

    // Should rebound to full scale again
    expect(getScale(tester), moreOrLessEquals(1.0, epsilon: 0.01));

    await gesture.up();
    await tester.pump();
  });

  testWidgets('Menu scale rebounds to full size when pan gesture ends', (
    WidgetTester tester,
  ) async {
    Future<void> pumpFrames(int frames) async {
      for (int i = 0; i < frames; i++) {
        await tester.pump();
      }
    }

    await changeSurfaceSize(tester, const Size(2000, 2000));
    await tester.pumpWidget(
      App(
        CupertinoMenuAnchor(
          controller: controller,
          menuChildren: <Widget>[Button.tag(Tag.a)],
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
    await tester.pump();

    // Allow time for rebound animation to complete
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
    await pumpFrames(20);

    // Should be at minimum scale
    expect(getScale(tester), moreOrLessEquals(0.8, epsilon: 0.01));

    // End gesture at maximum distance
    await gesture2.up();
    await tester.pump();

    // Allow rebound animation to complete
    await pumpFrames(25);

    // Should rebound to full scale
    expect(getScale(tester), moreOrLessEquals(1.0, epsilon: 0.01));
  });

  testWidgets('Pan can be disabled', (WidgetTester tester) async {
    await changeSurfaceSize(tester, const Size(1000, 1000));

    Widget buildWidget({required bool enablePan}) {
      return App(
        CupertinoMenuAnchor(
          controller: controller,
          enablePan: enablePan,
          menuChildren: <Widget>[Button.tag(Tag.a)],
          child: const AnchorButton(Tag.anchor),
        ),
      );
    }

    await tester.pumpWidget(buildWidget(enablePan: false));

    final TestGesture gesture = await tester.createGesture(pointer: 1);
    addTearDown(gesture.removePointer);

    controller.open();
    await tester.pump();
    await tester.pump(kMenuOpenDuration);

    final Offset startPosition = tester.getCenter(find.text(Tag.a.text));
    await gesture.down(startPosition);
    await tester.pump();

    final Rect menuRect = tester.getRect(find.byType(CupertinoPopupSurface));
    // Move far outside the menu bounds
    await gesture.moveTo(menuRect.topLeft - const Offset(200, 200));
    await tester.pump();

    // Scale should remain 1.0 when panning is disabled
    expect(getScale(tester), moreOrLessEquals(1.0, epsilon: 0.001));

    await gesture.moveTo(menuRect.bottomRight + const Offset(200, 200));
    await tester.pump();

    // Scale should still remain 1.0
    expect(getScale(tester), moreOrLessEquals(1.0, epsilon: 0.001));

    // Move to menu item and verify no special pan behavior occurs
    await gesture.moveTo(tester.getCenter(find.text(Tag.a.text)));
    await tester.pump(const Duration(milliseconds: 500));

    // Menu should still be open since pan is disabled
    expect(controller.isOpen, isTrue);

    await gesture.up();
    await tester.pump();
  });

  group('Menu keyboard navigation', () {
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
                Button.tag(Tag.a, focusNode: firstItemFocusNode),
                Button.tag(Tag.b),
                Button.tag(Tag.c, focusNode: lastItemFocusNode),
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
                Button.tag(Tag.a, focusNode: firstItemFocusNode),
                Button.tag(Tag.b),
                Button.tag(Tag.c, focusNode: lastItemFocusNode),
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
              Button.tag(
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
            menuChildren: <Widget>[Button.tag(Tag.a, focusNode: aFocusNode)],
            child: AnchorButton(Tag.anchor, focusNode: anchorFocusNode),
          ),
        ),
      );

      controller.open();
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

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
              Button.tag(Tag.a, focusNode: aFocusNode),
              Button.tag(Tag.b, focusNode: bFocusNode),
              Button.tag(Tag.c, focusNode: cFocusNode),
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
            menuChildren: <Widget>[Button.tag(Tag.a, focusNode: aFocusNode)],
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
              Button.tag(Tag.a, focusNode: aFocusNode),
              Button.tag(Tag.b, focusNode: bFocusNode),
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
              Button.tag(Tag.a, focusNode: firstItemFocusNode),
              Button.tag(Tag.b, focusNode: secondItemFocusNode),
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
              Button.tag(Tag.a, focusNode: firstItemFocusNode),
              Button.tag(Tag.b),
              Button.tag(Tag.c, focusNode: lastItemFocusNode),
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
              Button.tag(Tag.a, focusNode: firstItemFocusNode),
              Button.tag(Tag.b, focusNode: middleItemFocusNode),
              Button.tag(Tag.c, focusNode: lastItemFocusNode),
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
              Button.tag(Tag.a, focusNode: firstItemFocusNode),
              Button.tag(Tag.b, focusNode: middleItemFocusNode),
              Button.tag(Tag.c, focusNode: lastItemFocusNode),
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
      final Finder finder =
          clipped
              ? find.byType(BackdropFilter)
              : find.ancestor(
                of: find.byType(CupertinoPopupSurface),
                matching: find.descendant(
                  of: find.byType(FadeTransition),
                  matching: find.byType(CustomPaint),
                ),
              );
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
      final ui.Rect anchorRect = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));

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
      final ui.Rect anchorRect = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));

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

    testWidgets('LTR default alignment', (WidgetTester tester) async {
      const Size size = Size(2000, 2000);
      await changeSurfaceSize(tester, size);
      Widget buildApp({required AlignmentGeometry alignment}) {
        return App(
          alignment: alignment,
          CupertinoMenuAnchor(
            overlayPadding: EdgeInsets.zero,
            menuAlignment: Alignment.center,
            menuChildren: <Widget>[
              Container(
                width: 50,
                height: 50,
                color: const Color(0xFF0000FF),
                child: Text(Tag.a.text),
              ),
            ],
            child: const AnchorButton(Tag.anchor),
          ),
        );
      }

      await tester.pumpWidget(buildApp(alignment: Alignment.topCenter));
      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      for (double horizontal = -0.8; horizontal <= -0.8; horizontal += 0.1) {
        for (double vertical = -0.8; vertical <= -0.8; vertical += 0.1) {
          final Alignment alignment = Alignment(horizontal, vertical);
          await tester.pumpWidget(buildApp(alignment: alignment));
          final Alignment expectedAnchorAlignment = Alignment(
            switch (alignment.x) {
              < -0.2 => -1.0, // Left
              > 0.2 => 1.0, // Right
              _ => 0.0, // Center
            },
            alignment.y > 0 ? -1.0 : 1.0, // Top or Bottom
          );

          final ui.Rect anchorRect = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));
          final ui.Rect surface = tester.getRect(
            find.widgetWithText(CupertinoPopupSurface, Tag.a.text).first,
          );

          final ui.Offset expectedAnchorOffset = expectedAnchorAlignment
              .resolve(TextDirection.ltr)
              .withinRect(anchorRect);

          expect(
            expectedAnchorOffset,
            offsetMoreOrLessEquals(surface.center, epsilon: 0.01),
            reason:
                'Anchor alignment: $alignment \n'
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

      final Offset anchorBottomCenter =
          tester.getRect(find.widgetWithText(Button, Tag.anchor.text)).bottomCenter;

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
        rectMoreOrLessEquals(const Rect.fromLTRB(0.0, 100.0, 100.0, 200.0), epsilon: 0.01),
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
      const BoxConstraints constraints = BoxConstraints.tightFor(width: 300, height: 40);

      await tester.pumpWidget(
        App(
          CupertinoMenuAnchor(
            overlayPadding: EdgeInsets.zero,
            menuChildren: <Widget>[
              Container(color: const Color(0xFFFF0000), constraints: constraints),
            ],
            child: const AnchorButton(Tag.anchor, constraints: constraints),
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
        rectMoreOrLessEquals(const Rect.fromLTRB(0.0, 120.0, 250.0, 160.0), epsilon: 0.01),
      );
    });

    testWidgets('RTL constrained menu placement with unconstrained crossaxis', (
      WidgetTester tester,
    ) async {
      await changeSurfaceSize(tester, const Size(200, 200));
      const BoxConstraints constraints = BoxConstraints.tightFor(width: 300, height: 40);

      await tester.pumpWidget(
        App(
          textDirection: TextDirection.rtl,
          CupertinoMenuAnchor(
            overlayPadding: EdgeInsets.zero,
            menuChildren: <Widget>[
              Container(color: const Color(0xFFFF0000), constraints: constraints),
            ],
            child: const AnchorButton(Tag.anchor, constraints: constraints),
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
        rectMoreOrLessEquals(const Rect.fromLTRB(-50.0, 120.0, 200.0, 160.0), epsilon: 0.01),
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
            menuChildren: <Widget>[Button.tag(Tag.a, constraints: constraints)],
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
        rectMoreOrLessEquals(const Rect.fromLTRB(0.0, 120.0, 200.0, 160.0), epsilon: 0.01),
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
            menuChildren: <Widget>[Button.tag(Tag.a, constraints: constraints)],
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
        rectMoreOrLessEquals(const Rect.fromLTRB(0.0, 120.0, 200.0, 160.0), epsilon: 0.01),
      );
    });

    testWidgets('Constraints applied to anchor do not affect overlay', (WidgetTester tester) async {
      await tester.pumpWidget(
        App(
          alignment: Alignment.topLeft,
          ConstrainedBox(
            constraints: const BoxConstraints.tightFor(width: 40, height: 40),
            child: CupertinoMenuAnchor(
              overlayPadding: EdgeInsets.zero,
              menuChildren: <Widget>[Container(color: const Color(0xFFFF0000), height: 100)],
              child: const AnchorButton(Tag.anchor),
            ),
          ),
        ),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      expect(
        collectOverlays().first,
        rectMoreOrLessEquals(const Rect.fromLTRB(0.0, 40.0, 250.0, 140.0), epsilon: 0.01),
      );
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
      final ui.Rect anchor = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));
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
      final Offset anchorTopLeft = tester.getTopLeft(find.widgetWithText(Button, Tag.anchor.text));
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
        find.widgetWithText(Button, Tag.anchor.text),
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
        find.widgetWithText(Button, Tag.anchor.text),
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

        final Rect anchor = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));
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

      final Rect anchor = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));
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

      final Rect anchor = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));
      expect(collectOverlays().first.top, moreOrLessEquals(anchor.bottom + 8, epsilon: 0.01));
    });

    testWidgets('AlignmentOffset is reflected across anchor when menu flips', (
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

      final Offset anchorCenter = tester.getCenter(find.widgetWithText(Button, Tag.anchor.text));
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

      final Offset anchorTopLeft = tester.getTopLeft(find.widgetWithText(Button, Tag.anchor.text));
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

      final Offset anchorCenter = tester.getCenter(find.widgetWithText(Button, Tag.anchor.text));
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
      await changeSurfaceSize(tester, const Size(400, 400));

      Widget buildApp({
        required EdgeInsetsGeometry appPadding,
        required EdgeInsetsGeometry anchorPadding,
      }) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Padding(
            padding: appPadding,
            child: App(
              alignment: AlignmentDirectional.topStart,
              Padding(
                padding: anchorPadding,
                child: CupertinoMenuAnchor(
                  overlayPadding: EdgeInsets.zero,
                  alignment: AlignmentDirectional.topStart,
                  menuAlignment: AlignmentDirectional.bottomEnd,
                  menuChildren: <Widget>[
                    Container(
                      color: const Color(0xFF0000FF),
                      height: 100,
                      width: 100,
                      child: Text(Tag.a.text),
                    ),
                  ],
                  child: const AnchorButton(Tag.anchor),
                ),
              ),
            ),
          ),
        );
      }

      // First, collect measurements without padding.
      await tester.pumpWidget(
        buildApp(appPadding: EdgeInsets.zero, anchorPadding: EdgeInsets.zero),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      final Rect anchor = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));
      final [Rect first] = collectOverlays();

      await tester.pumpWidget(
        buildApp(
          appPadding: const EdgeInsetsDirectional.fromSTEB(31, 7, 43, 0),
          anchorPadding: const EdgeInsetsDirectional.fromSTEB(64, 50, 17, 0),
        ),
      );

      final [Rect firstPadded] = collectOverlays();
      final Rect paddedAnchor = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));

      expect(paddedAnchor, equals(anchor.shift(const Offset(31 + 64, 7 + 50))));

      // Hits padding on top/left
      expect(firstPadded, equals(first.shift(const Offset(31, 7))));
    });

    testWidgets('RTL app and anchor padding', (WidgetTester tester) async {
      // Out of App:
      //    - overlay position affected
      //    - anchor position affected
      // In App:
      //    - anchor position affected
      //
      // Padding inside App DOES NOT affect the overlay position but
      // DOES affect the anchor position.

      Widget buildApp({
        required EdgeInsetsGeometry appPadding,
        required EdgeInsetsGeometry anchorPadding,
      }) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: appPadding,
            child: App(
              alignment: AlignmentDirectional.topStart,
              Padding(
                padding: anchorPadding,
                child: CupertinoMenuAnchor(
                  overlayPadding: EdgeInsets.zero,
                  alignment: AlignmentDirectional.topStart,
                  menuAlignment: AlignmentDirectional.bottomEnd,
                  menuChildren: <Widget>[
                    Container(
                      color: const Color(0xFF0000FF),
                      height: 100,
                      width: 100,
                      child: Text(Tag.a.text),
                    ),
                  ],
                  child: const AnchorButton(Tag.anchor),
                ),
              ),
            ),
          ),
        );
      }

      // First, collect measurements without padding.
      await tester.pumpWidget(
        buildApp(appPadding: EdgeInsets.zero, anchorPadding: EdgeInsets.zero),
      );

      await tester.tap(find.text(Tag.anchor.text));
      await tester.pump();
      await tester.pump(kMenuOpenDuration);

      final Rect anchor = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));
      final [Rect first] = collectOverlays();

      // Next, collect measurements with padding.
      await tester.pumpWidget(
        buildApp(
          appPadding: const EdgeInsetsDirectional.fromSTEB(31, 7, 43, 0),
          anchorPadding: const EdgeInsetsDirectional.fromSTEB(64, 50, 17, 0),
        ),
      );

      final [Rect menuPadded] = collectOverlays();
      final Rect anchorPadded = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));

      expect(
        anchorPadded,
        rectMoreOrLessEquals(anchor.shift(const Offset(-31 - 64, 7 + 50)), epsilon: 0.01),
      );
      expect(menuPadded, rectMoreOrLessEquals(first.shift(const Offset(43, 7)), epsilon: 0.01));
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
                    top: 300,
                    child: CupertinoMenuAnchor(
                      overlayPadding: EdgeInsets.zero,
                      alignment: Alignment.bottomLeft,
                      menuAlignment: Alignment.topRight,
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
      expect(overlay.size, equals(const Size(75, 100)));

      // Width and height should be maintained
      expect(tester.getSize(find.byKey(Tag.a.key)), equals(const Size(50, 150)));

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
      final Rect anchor = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));

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
        final Rect anchor = tester.getRect(find.widgetWithText(Button, Tag.anchor.text));

        expect(menu.bottomLeft, offsetMoreOrLessEquals(anchor.topLeft, epsilon: 0.01));
      },
    );
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

  String get text;
  String get focusNode;
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

  @override
  String get focusNode {
    return 'Focus[$text]';
  }

  Key get key => ValueKey<String>('${text}_Key');
}

// A simple, focusable button that calls onPressed when tapped.
//
// The widgets library can't import the material library, so a separate button
// widget has to be created.
class Button extends StatefulWidget {
  const Button(
    this.child, {
    super.key,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
    this.onFocusChange,
    String? focusNodeLabel,
    BoxConstraints? constraints,
  }) : _focusNodeLabel = focusNodeLabel,
       constraints = constraints ?? const BoxConstraints.tightFor(width: 225, height: 32);

  factory Button.text(
    String text, {
    Key? key,
    VoidCallback? onPressed,
    FocusNode? focusNode,
    bool autofocus = false,
    BoxConstraints? constraints,
    void Function(bool)? onFocusChange,
  }) {
    return Button(
      Text(text),
      key: key,
      onPressed: onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      constraints: constraints,
      onFocusChange: onFocusChange,
    );
  }

  factory Button.tag(
    Tag tag, {
    Key? key,
    VoidCallback? onPressed,
    FocusNode? focusNode,
    bool autofocus = false,
    BoxConstraints? constraints,
    void Function(bool)? onFocusChange,
  }) {
    return Button(
      Text(tag.text),
      key: key,
      onPressed: onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      constraints: constraints,
      onFocusChange: onFocusChange,
      focusNodeLabel: tag.focusNode,
    );
  }

  final Widget child;
  final VoidCallback? onPressed;
  final void Function(bool)? onFocusChange;
  final FocusNode? focusNode;
  final bool autofocus;
  final BoxConstraints? constraints;
  final String? _focusNodeLabel;

  @override
  State<Button> createState() => _ButtonState();
}

class _ButtonState extends State<Button> {
  late final Map<Type, Action<Intent>> _actions = <Type, Action<Intent>>{
    ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: _activateOnIntent),
    ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(onInvoke: _activateOnIntent),
  };
  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode!;
  FocusNode? _internalFocusNode;
  final WidgetStatesController _states = WidgetStatesController();
  ui.Brightness _brightness = ui.Brightness.light;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode(debugLabel: widget._focusNodeLabel);
    }
    _states.addListener(() {
      setState(() {
        /* Rebuild on state changes. */
      });
    });
  }

  @override
  void didUpdateWidget(Button oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      if (widget.focusNode == null) {
        _internalFocusNode = FocusNode(debugLabel: widget._focusNodeLabel);
      } else {
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _brightness = MediaQuery.maybePlatformBrightnessOf(context) ?? _brightness;
  }

  @override
  void dispose() {
    _internalFocusNode?.dispose();
    _states.dispose();
    _internalFocusNode = null;
    super.dispose();
  }

  void _activateOnIntent(Intent intent) {
    _handlePressed();
  }

  void _handlePressed() {
    widget.onPressed?.call();
    _states.update(WidgetState.pressed, true);
  }

  void _handleTapDown(TapDownDetails details) {
    _states.update(WidgetState.pressed, true);
  }

  void _handleFocusChange(bool value) {
    _states.update(WidgetState.focused, value);
    widget.onFocusChange?.call(value);
  }

  void _handleExit(PointerExitEvent event) {
    _states.update(WidgetState.hovered, false);
  }

  void _handleHover(PointerHoverEvent event) {
    _states.update(WidgetState.hovered, true);
  }

  void _handleTapUp(TapUpDetails details) {
    _states.update(WidgetState.pressed, false);
    _handlePressed.call();
  }

  void _handleTapCancel() {
    _states.update(WidgetState.pressed, false);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: _textStyle,
      child: MergeSemantics(
        child: Semantics(
          button: true,
          child: Actions(
            actions: _actions,
            child: Focus(
              debugLabel: widget._focusNodeLabel,
              onFocusChange: _handleFocusChange,
              autofocus: widget.autofocus,
              focusNode: _focusNode,
              child: MouseRegion(
                onHover: _handleHover,
                onExit: _handleExit,
                child: GestureDetector(
                  onTapDown: _handleTapDown,
                  onTapCancel: _handleTapCancel,
                  onTapUp: _handleTapUp,
                  child: Container(
                    constraints: widget.constraints,
                    decoration: _decoration,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Align(alignment: AlignmentDirectional.centerStart, child: widget.child),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Used for visualizing tests.
  BoxDecoration? get _decoration {
    if (_states.value.contains(WidgetState.pressed)) {
      return const BoxDecoration(color: Color(0xFF007BFF));
    }
    if (_states.value.contains(WidgetState.focused)) {
      return switch (_brightness) {
        Brightness.dark => const BoxDecoration(color: Color(0x95007BFF)),
        Brightness.light => const BoxDecoration(color: Color(0x95007BFF)),
      };
    }
    if (_states.value.contains(WidgetState.hovered)) {
      return const BoxDecoration(color: Color(0x22BBBBBB));
    }
    return null;
  }

  TextStyle get _textStyle {
    if (_states.value.contains(WidgetState.pressed)) {
      return const TextStyle(color: Color.fromARGB(255, 255, 255, 255));
    }
    return switch (_brightness) {
      Brightness.dark => const TextStyle(color: Color(0xFFFFFFFF)),
      Brightness.light => const TextStyle(color: Color(0xFF000000)),
    };
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
    return Button.tag(
      tag,
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
      constraints: constraints,
      autofocus: autofocus,
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
    return ColoredBox(
      color: const Color(0xff000000),
      child: Directionality(
        textDirection: widget.textDirection ?? _directionality ?? TextDirection.ltr,
        child: Overlay(initialEntries: <OverlayEntry>[OverlayEntry(builder: _buildPage)]),
      ),
    );
  }

  Widget _buildPage(BuildContext context) {
    return Align(alignment: widget.alignment, child: widget.child);
  }
}
