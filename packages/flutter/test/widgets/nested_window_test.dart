// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/src/foundation/_features.dart' show isWindowingEnabled;
import 'package:flutter/src/widgets/_window.dart'
    show
        BaseWindowController,
        NestedWindow,
        NestedWindowController,
        NestedWindowLayoutInfo,
        PopupWindowController,
        WindowEntry;
import 'package:flutter/src/widgets/_window_positioner.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'multi_view_testing.dart';

class _StubPopupWindowController extends PopupWindowController {
  _StubPopupWindowController(WidgetTester tester) : super.empty() {
    rootView = FakeView(tester.view);
  }

  final positionUpdates = <Rect>[];

  int destroyCount = 0;

  @override
  BaseWindowController get parent => throw UnimplementedError();

  @override
  Size get contentSize => Size.zero;

  @override
  Offset get offsetFromParent => Offset.zero;

  @override
  bool get isActivated => true;

  @override
  void activate() {}

  @override
  void setConstraints(BoxConstraints constraints) {}

  @override
  void updatePosition({Rect? anchorRect, WindowPositioner? positioner}) {
    if (anchorRect != null) {
      positionUpdates.add(anchorRect);
    }
  }

  @override
  bool get isDestroyed => _destroyed;
  bool _destroyed = false;

  @override
  void destroy() {
    destroyCount += 1;
    if (_destroyed) {
      return;
    }
    _destroyed = true;
    notifyListeners();
  }
}

class _TestScope extends InheritedWidget {
  const _TestScope({required this.value, required super.child});

  final String value;

  static String of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_TestScope>()!.value;
  }

  @override
  bool updateShouldNotify(_TestScope oldWidget) => value != oldWidget.value;
}

void main() {
  late bool previousWindowingEnabled;

  setUp(() {
    previousWindowingEnabled = isWindowingEnabled;
    isWindowingEnabled = true;
  });

  tearDown(() {
    isWindowingEnabled = previousWindowingEnabled;
  });

  // Builds a NestedWindow whose child is a 100x50 box whose top left corner is
  // at (30, 20) within the view.
  Widget buildAnchoredWindow({required Widget nestedWindow, Offset offset = const Offset(30, 20)}) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: <Widget>[
          Positioned(left: offset.dx, top: offset.dy, width: 100, height: 50, child: nestedWindow),
        ],
      ),
    );
  }

  testWidgets('NestedWindow.windowLayoutBuilder reports the geometry of its child', (
    WidgetTester tester,
  ) async {
    final controller = NestedWindowController();
    addTearDown(controller.dispose);
    late _StubPopupWindowController windowController;
    NestedWindowLayoutInfo? capturedInfo;

    await tester.pumpWidget(
      buildAnchoredWindow(
        nestedWindow: NestedWindow.windowLayoutBuilder(
          controller: controller,
          entryBuilder: (BuildContext context, NestedWindowLayoutInfo info) {
            capturedInfo = info;
            windowController = _StubPopupWindowController(tester);
            return WindowEntry(
              controller: windowController,
              builder: (BuildContext context) => const SizedBox.shrink(),
            );
          },
          child: const SizedBox.expand(),
        ),
      ),
    );

    expect(capturedInfo, isNull);

    controller.show();
    await tester.pump();

    expect(capturedInfo, isNotNull);
    expect(capturedInfo!.childSize, const Size(100, 50));
    expect(capturedInfo!.anchorRect, const Rect.fromLTWH(30, 20, 100, 50));
    expect(capturedInfo!.viewSize, tester.view.physicalSize / tester.view.devicePixelRatio);
    expect(
      MatrixUtils.transformPoint(capturedInfo!.childPaintTransform, Offset.zero),
      const Offset(30, 20),
    );
    expect(windowController.isDestroyed, isFalse);

    controller.hide();
    await tester.pump();
  });

  testWidgets('NestedWindow.windowLayoutBuilder reports the current geometry on every show', (
    WidgetTester tester,
  ) async {
    final controller = NestedWindowController();
    addTearDown(controller.dispose);
    final anchorRects = <Rect>[];

    Widget build(Offset offset) {
      return buildAnchoredWindow(
        offset: offset,
        nestedWindow: NestedWindow.windowLayoutBuilder(
          controller: controller,
          entryBuilder: (BuildContext context, NestedWindowLayoutInfo info) {
            anchorRects.add(info.anchorRect);
            return WindowEntry(
              controller: _StubPopupWindowController(tester),
              builder: (BuildContext context) => const SizedBox.shrink(),
            );
          },
          child: const SizedBox.expand(),
        ),
      );
    }

    await tester.pumpWidget(build(const Offset(30, 20)));
    controller.show();
    await tester.pump();
    controller.hide();
    await tester.pump();

    await tester.pumpWidget(build(const Offset(300, 200)));
    controller.show();
    await tester.pump();

    expect(anchorRects, <Rect>[
      const Rect.fromLTWH(30, 20, 100, 50),
      const Rect.fromLTWH(300, 200, 100, 50),
    ]);

    controller.hide();
    await tester.pump();
  });

  testWidgets('NestedWindow entry builder receives a context below the NestedWindow', (
    WidgetTester tester,
  ) async {
    final controller = NestedWindowController();
    addTearDown(controller.dispose);
    String? inheritedValue;

    await tester.pumpWidget(
      _TestScope(
        value: 'surrounding',
        child: buildAnchoredWindow(
          nestedWindow: NestedWindow(
            controller: controller,
            entryBuilder: (BuildContext context) {
              inheritedValue = _TestScope.of(context);
              return WindowEntry(
                controller: _StubPopupWindowController(tester),
                builder: (BuildContext context) => const SizedBox.shrink(),
              );
            },
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );

    controller.show();
    await tester.pump();

    expect(inheritedValue, 'surrounding');

    controller.hide();
    await tester.pump();
  });

  testWidgets('NestedWindowController.isShowing tracks show, hide and toggle', (
    WidgetTester tester,
  ) async {
    final controller = NestedWindowController();
    addTearDown(controller.dispose);
    var notifications = 0;
    controller.addListener(() => notifications += 1);
    var buildCount = 0;

    await tester.pumpWidget(
      buildAnchoredWindow(
        nestedWindow: NestedWindow(
          controller: controller,
          entryBuilder: (BuildContext context) {
            buildCount += 1;
            return WindowEntry(
              controller: _StubPopupWindowController(tester),
              builder: (BuildContext context) => const SizedBox.shrink(),
            );
          },
          child: const SizedBox.expand(),
        ),
      ),
    );

    expect(controller.isShowing, isFalse);

    controller.show();
    await tester.pump();
    expect(controller.isShowing, isTrue);
    expect(buildCount, 1);
    expect(notifications, 1);

    // Showing an already showing window is a no-op.
    controller.show();
    await tester.pump();
    expect(buildCount, 1);
    expect(notifications, 1);

    controller.toggle();
    await tester.pump();
    expect(controller.isShowing, isFalse);
    expect(notifications, 2);

    // Hiding an already hidden window is a no-op.
    controller.hide();
    await tester.pump();
    expect(notifications, 2);

    // Showing again creates a brand new entry.
    controller.toggle();
    await tester.pump();
    expect(controller.isShowing, isTrue);
    expect(buildCount, 2);

    controller.hide();
    await tester.pump();
  });

  testWidgets('NestedWindow renders the window content and removes it when hidden', (
    WidgetTester tester,
  ) async {
    final controller = NestedWindowController();
    addTearDown(controller.dispose);
    late _StubPopupWindowController windowController;

    await tester.pumpWidget(
      buildAnchoredWindow(
        nestedWindow: NestedWindow(
          controller: controller,
          entryBuilder: (BuildContext context) {
            windowController = _StubPopupWindowController(tester);
            return WindowEntry(
              controller: windowController,
              builder: (BuildContext context) => const Placeholder(),
            );
          },
          child: const SizedBox.expand(),
        ),
      ),
    );

    expect(find.byType(Placeholder), findsNothing);

    controller.show();
    await tester.pump();
    expect(find.byType(Placeholder), findsOneWidget);

    controller.hide();
    await tester.pump();
    expect(find.byType(Placeholder), findsNothing);
    expect(windowController.isDestroyed, isTrue);
    expect(windowController.destroyCount, 1);
    expect(controller.isShowing, isFalse);
  });

  testWidgets('Removing a showing NestedWindow destroys its native window', (
    WidgetTester tester,
  ) async {
    final controller = NestedWindowController();
    addTearDown(controller.dispose);
    late _StubPopupWindowController windowController;

    await tester.pumpWidget(
      buildAnchoredWindow(
        nestedWindow: NestedWindow(
          controller: controller,
          entryBuilder: (BuildContext context) {
            windowController = _StubPopupWindowController(tester);
            return WindowEntry(
              controller: windowController,
              builder: (BuildContext context) => const Placeholder(),
            );
          },
          child: const SizedBox.expand(),
        ),
      ),
    );

    controller.show();
    await tester.pump();
    expect(windowController.isDestroyed, isFalse);
    expect(controller.isShowing, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());

    expect(windowController.isDestroyed, isTrue);
    expect(windowController.destroyCount, 1);
    expect(controller.isShowing, isFalse);
    expect(find.byType(Placeholder), findsNothing);
  });

  testWidgets('Removing a hidden NestedWindow does not destroy anything twice', (
    WidgetTester tester,
  ) async {
    final controller = NestedWindowController();
    addTearDown(controller.dispose);
    late _StubPopupWindowController windowController;
    var notifications = 0;

    await tester.pumpWidget(
      buildAnchoredWindow(
        nestedWindow: NestedWindow(
          controller: controller,
          entryBuilder: (BuildContext context) {
            windowController = _StubPopupWindowController(tester);
            return WindowEntry(
              controller: windowController,
              builder: (BuildContext context) => const Placeholder(),
            );
          },
          child: const SizedBox.expand(),
        ),
      ),
    );

    controller.show();
    await tester.pump();
    controller.hide();
    await tester.pump();
    expect(windowController.destroyCount, 1);

    controller.addListener(() => notifications += 1);
    await tester.pumpWidget(const SizedBox.shrink());

    expect(windowController.destroyCount, 1);
    expect(controller.isShowing, isFalse);
    expect(notifications, 0);
  });

  testWidgets('Removing a NestedWindow whose window was destroyed by the platform is a no-op', (
    WidgetTester tester,
  ) async {
    final controller = NestedWindowController();
    addTearDown(controller.dispose);
    late _StubPopupWindowController windowController;

    await tester.pumpWidget(
      buildAnchoredWindow(
        nestedWindow: NestedWindow(
          controller: controller,
          entryBuilder: (BuildContext context) {
            windowController = _StubPopupWindowController(tester);
            return WindowEntry(
              controller: windowController,
              builder: (BuildContext context) => const Placeholder(),
            );
          },
          child: const SizedBox.expand(),
        ),
      ),
    );

    controller.show();
    await tester.pump();

    // The platform destroys the window on its own.
    windowController.destroy();
    await tester.pump();
    expect(controller.isShowing, isFalse);
    expect(find.byType(Placeholder), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(windowController.destroyCount, 1);
  });

  testWidgets('NestedWindow forwards anchor movement to PopupWindowController.updatePosition', (
    WidgetTester tester,
  ) async {
    final controller = NestedWindowController();
    addTearDown(controller.dispose);
    late _StubPopupWindowController windowController;

    Widget build(Offset offset) {
      return buildAnchoredWindow(
        offset: offset,
        nestedWindow: NestedWindow(
          controller: controller,
          entryBuilder: (BuildContext context) {
            windowController = _StubPopupWindowController(tester);
            return WindowEntry(
              controller: windowController,
              builder: (BuildContext context) => const SizedBox.shrink(),
            );
          },
          child: const SizedBox.expand(),
        ),
      );
    }

    await tester.pumpWidget(build(const Offset(30, 20)));
    controller.show();
    await tester.pump();
    expect(windowController.positionUpdates, isEmpty);

    await tester.pumpWidget(build(const Offset(80, 90)));
    expect(windowController.positionUpdates, <Rect>[const Rect.fromLTWH(80, 90, 100, 50)]);

    // A frame that does not move the anchor does not report a new position.
    await tester.pump();
    expect(windowController.positionUpdates, hasLength(1));

    controller.hide();
    await tester.pump();
  });

  testWidgets('NestedWindow stops forwarding anchor movement once hidden', (
    WidgetTester tester,
  ) async {
    final controller = NestedWindowController();
    addTearDown(controller.dispose);
    late _StubPopupWindowController windowController;

    Widget build(Offset offset) {
      return buildAnchoredWindow(
        offset: offset,
        nestedWindow: NestedWindow(
          controller: controller,
          entryBuilder: (BuildContext context) {
            windowController = _StubPopupWindowController(tester);
            return WindowEntry(
              controller: windowController,
              builder: (BuildContext context) => const SizedBox.shrink(),
            );
          },
          child: const SizedBox.expand(),
        ),
      );
    }

    await tester.pumpWidget(build(const Offset(30, 20)));
    controller.show();
    await tester.pump();

    controller.hide();
    await tester.pump();

    await tester.pumpWidget(build(const Offset(80, 90)));
    expect(windowController.positionUpdates, isEmpty);
  });
}
