// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/src/foundation/_features.dart' show isWindowingEnabled;
import 'package:flutter/src/widgets/_window.dart'
    show
        BaseWindowController,
        NestedWindow,
        NestedWindowLayoutInfo,
        PopupWindowController,
        WindowScope;
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

Widget _placeholderBuilder(BuildContext context, BaseWindowController controller) {
  return const Placeholder();
}

// Destroys [controller] when disposed, as an owner of a NestedWindow's
// controller is expected to.
class _DestroyOnDispose extends StatefulWidget {
  const _DestroyOnDispose({required this.controller, required this.child});

  final BaseWindowController controller;
  final Widget child;

  @override
  State<_DestroyOnDispose> createState() => _DestroyOnDisposeState();
}

class _DestroyOnDisposeState extends State<_DestroyOnDispose> {
  @override
  void dispose() {
    widget.controller.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
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

  void expectAnchorGeometry(WidgetTester tester, NestedWindowLayoutInfo? info) {
    expect(info, isNotNull);
    expect(info!.childSize, const Size(100, 50));
    expect(info.anchorRect, const Rect.fromLTWH(30, 20, 100, 50));
    expect(info.viewSize, tester.view.physicalSize / tester.view.devicePixelRatio);
    expect(MatrixUtils.transformPoint(info.childPaintTransform, Offset.zero), const Offset(30, 20));
  }

  group('NestedWindow.layoutInfoOf', () {
    testWidgets('measures the whole child from a context inside the child', (
      WidgetTester tester,
    ) async {
      late BuildContext innerContext;

      await tester.pumpWidget(
        buildAnchoredWindow(
          nestedWindow: NestedWindow<BaseWindowController>(
            builder: _placeholderBuilder,
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 10,
                height: 10,
                child: Builder(
                  builder: (BuildContext context) {
                    innerContext = context;
                    return const SizedBox.expand();
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expectAnchorGeometry(tester, NestedWindow.layoutInfoOf(innerContext));
      expectAnchorGeometry(tester, NestedWindow.maybeLayoutInfoOf(innerContext));
    });

    testWidgets('measures the child from the context of the NestedWindow itself', (
      WidgetTester tester,
    ) async {
      final GlobalKey key = GlobalKey();

      await tester.pumpWidget(
        buildAnchoredWindow(
          nestedWindow: NestedWindow<BaseWindowController>(
            key: key,
            builder: _placeholderBuilder,
            child: const SizedBox.expand(),
          ),
        ),
      );

      expectAnchorGeometry(tester, NestedWindow.layoutInfoOf(key.currentContext!));
    });

    testWidgets('reports the current geometry of the child', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();

      Widget build(Offset offset) {
        return buildAnchoredWindow(
          offset: offset,
          nestedWindow: NestedWindow<BaseWindowController>(
            key: key,
            builder: _placeholderBuilder,
            child: const SizedBox.expand(),
          ),
        );
      }

      await tester.pumpWidget(build(const Offset(30, 20)));
      expect(
        NestedWindow.layoutInfoOf(key.currentContext!).anchorRect,
        const Rect.fromLTWH(30, 20, 100, 50),
      );

      await tester.pumpWidget(build(const Offset(300, 200)));
      expect(
        NestedWindow.layoutInfoOf(key.currentContext!).anchorRect,
        const Rect.fromLTWH(300, 200, 100, 50),
      );
    });

    testWidgets('does not measure a context above the NestedWindow', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();

      await tester.pumpWidget(
        KeyedSubtree(
          key: key,
          child: buildAnchoredWindow(
            nestedWindow: const NestedWindow<BaseWindowController>(
              builder: _placeholderBuilder,
              child: SizedBox.expand(),
            ),
          ),
        ),
      );

      expect(NestedWindow.maybeLayoutInfoOf(key.currentContext!), isNull);
      expect(
        () => NestedWindow.layoutInfoOf(key.currentContext!),
        throwsA(
          isA<FlutterError>().having(
            (FlutterError error) => error.message,
            'message',
            contains('No NestedWindow found in context.'),
          ),
        ),
      );
    });

    testWidgets('does not report geometry before the child is laid out', (
      WidgetTester tester,
    ) async {
      NestedWindowLayoutInfo? infoDuringFirstBuild;
      Object? errorDuringFirstBuild;

      await tester.pumpWidget(
        buildAnchoredWindow(
          nestedWindow: NestedWindow<BaseWindowController>(
            builder: _placeholderBuilder,
            child: Builder(
              builder: (BuildContext context) {
                infoDuringFirstBuild = NestedWindow.maybeLayoutInfoOf(context);
                try {
                  NestedWindow.layoutInfoOf(context);
                } on FlutterError catch (error) {
                  errorDuringFirstBuild = error;
                }
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );

      expect(infoDuringFirstBuild, isNull);
      expect(
        errorDuringFirstBuild,
        isA<FlutterError>().having(
          (FlutterError error) => error.message,
          'message',
          contains('NestedWindow.child has not been laid out.'),
        ),
      );
    });
  });

  testWidgets('NestedWindow renders no window without a controller', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildAnchoredWindow(
        nestedWindow: const NestedWindow<BaseWindowController>(
          builder: _placeholderBuilder,
          child: SizedBox.expand(),
        ),
      ),
    );

    expect(find.byType(Placeholder), findsNothing);
  });

  testWidgets('NestedWindow renders a window provided in its first build', (
    WidgetTester tester,
  ) async {
    final windowController = _StubPopupWindowController(tester);

    await tester.pumpWidget(
      buildAnchoredWindow(
        nestedWindow: NestedWindow(
          controller: windowController,
          builder: _placeholderBuilder,
          child: const SizedBox.expand(),
        ),
      ),
    );

    expect(find.byType(Placeholder), findsOneWidget);
    expect(windowController.isDestroyed, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('NestedWindow does not render a window that is already destroyed', (
    WidgetTester tester,
  ) async {
    final windowController = _StubPopupWindowController(tester)..destroy();

    await tester.pumpWidget(
      buildAnchoredWindow(
        nestedWindow: NestedWindow(
          controller: windowController,
          builder: _placeholderBuilder,
          child: const SizedBox.expand(),
        ),
      ),
    );

    expect(find.byType(Placeholder), findsNothing);
    expect(windowController.destroyCount, 1);
  });

  testWidgets('NestedWindow passes its typed controller and a scoped context to the builder', (
    WidgetTester tester,
  ) async {
    final windowController = _StubPopupWindowController(tester);
    _StubPopupWindowController? builtController;
    BaseWindowController? scopedController;

    await tester.pumpWidget(
      buildAnchoredWindow(
        nestedWindow: NestedWindow(
          controller: windowController,
          builder: (BuildContext context, _StubPopupWindowController controller) {
            builtController = controller;
            scopedController = WindowScope.of(context);
            return const SizedBox.shrink();
          },
          child: const SizedBox.expand(),
        ),
      ),
    );

    expect(builtController, same(windowController));
    expect(scopedController, same(windowController));

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('NestedWindow only calls the builder while the window is showing', (
    WidgetTester tester,
  ) async {
    final windowController = _StubPopupWindowController(tester);
    var builds = 0;

    Widget build(_StubPopupWindowController? controller) {
      return buildAnchoredWindow(
        nestedWindow: NestedWindow(
          controller: controller,
          builder: (BuildContext context, _StubPopupWindowController controller) {
            builds += 1;
            return const SizedBox.shrink();
          },
          child: const SizedBox.expand(),
        ),
      );
    }

    await tester.pumpWidget(build(null));
    expect(builds, 0);

    await tester.pumpWidget(build(windowController));
    expect(builds, 1);

    windowController.destroy();
    await tester.pump();
    await tester.pumpWidget(build(windowController));
    expect(builds, 1);
  });

  testWidgets('NestedWindow content inherits from widgets surrounding the NestedWindow', (
    WidgetTester tester,
  ) async {
    String? inheritedValue;
    final windowController = _StubPopupWindowController(tester);

    await tester.pumpWidget(
      _TestScope(
        value: 'surrounding',
        child: buildAnchoredWindow(
          nestedWindow: NestedWindow(
            controller: windowController,
            builder: (BuildContext context, _StubPopupWindowController controller) {
              inheritedValue = _TestScope.of(context);
              return const SizedBox.shrink();
            },
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );

    expect(inheritedValue, 'surrounding');

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Destroying the controller removes the window content', (WidgetTester tester) async {
    final windowController = _StubPopupWindowController(tester);

    await tester.pumpWidget(
      buildAnchoredWindow(
        nestedWindow: NestedWindow(
          controller: windowController,
          builder: _placeholderBuilder,
          child: const SizedBox.expand(),
        ),
      ),
    );
    expect(find.byType(Placeholder), findsOneWidget);

    // Destroying the window, whether by the caller or the platform, removes
    // its content without the controller being changed.
    windowController.destroy();
    await tester.pump();
    expect(find.byType(Placeholder), findsNothing);

    // Rebuilding with the destroyed controller does not render it again.
    await tester.pumpWidget(
      buildAnchoredWindow(
        nestedWindow: NestedWindow(
          controller: windowController,
          builder: _placeholderBuilder,
          child: const SizedBox.expand(),
        ),
      ),
    );
    expect(find.byType(Placeholder), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(windowController.destroyCount, 1);
  });

  testWidgets('Removing the controller does not destroy its native window', (
    WidgetTester tester,
  ) async {
    final windowController = _StubPopupWindowController(tester);
    addTearDown(windowController.destroy);

    await tester.pumpWidget(
      buildAnchoredWindow(
        nestedWindow: NestedWindow(
          controller: windowController,
          builder: _placeholderBuilder,
          child: const SizedBox.expand(),
        ),
      ),
    );

    await tester.pumpWidget(
      buildAnchoredWindow(
        nestedWindow: const NestedWindow<BaseWindowController>(
          builder: _placeholderBuilder,
          child: SizedBox.expand(),
        ),
      ),
    );

    expect(find.byType(Placeholder), findsNothing);
    expect(windowController.isDestroyed, isFalse);
    expect(windowController.destroyCount, 0);
  });

  testWidgets('A new builder updates the content without recreating the window', (
    WidgetTester tester,
  ) async {
    final windowController = _StubPopupWindowController(tester);

    Widget build(Widget content) {
      return buildAnchoredWindow(
        nestedWindow: NestedWindow(
          controller: windowController,
          builder: (BuildContext context, _StubPopupWindowController controller) => content,
          child: const SizedBox.expand(),
        ),
      );
    }

    await tester.pumpWidget(build(const Placeholder()));
    expect(find.byType(Placeholder), findsOneWidget);

    await tester.pumpWidget(build(const ColoredBox(color: Color(0xFF00FF00))));
    expect(find.byType(Placeholder), findsNothing);
    expect(find.byType(ColoredBox), findsOneWidget);
    expect(windowController.destroyCount, 0);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('A different controller does not destroy the previous window', (
    WidgetTester tester,
  ) async {
    final first = _StubPopupWindowController(tester);
    final second = _StubPopupWindowController(tester);
    addTearDown(first.destroy);
    addTearDown(second.destroy);

    Widget build(BaseWindowController controller) {
      return buildAnchoredWindow(
        nestedWindow: NestedWindow(
          controller: controller,
          builder: _placeholderBuilder,
          child: const SizedBox.expand(),
        ),
      );
    }

    await tester.pumpWidget(build(first));
    await tester.pumpWidget(build(second));

    expect(first.destroyCount, 0);
    expect(second.isDestroyed, isFalse);
    expect(find.byType(Placeholder), findsOneWidget);

    // Destroying the previous controller no longer affects the NestedWindow.
    first.destroy();
    await tester.pump();
    expect(find.byType(Placeholder), findsOneWidget);

    await tester.pumpWidget(
      buildAnchoredWindow(
        nestedWindow: NestedWindow<BaseWindowController>(
          key: UniqueKey(),
          builder: _placeholderBuilder,
          child: const SizedBox.expand(),
        ),
      ),
    );
    expect(find.byType(Placeholder), findsNothing);
    expect(second.destroyCount, 0);
    expect(first.destroyCount, 1);
  });

  testWidgets('Removing a showing NestedWindow does not destroy its native window', (
    WidgetTester tester,
  ) async {
    final windowController = _StubPopupWindowController(tester);
    addTearDown(windowController.destroy);

    await tester.pumpWidget(
      buildAnchoredWindow(
        nestedWindow: NestedWindow(
          controller: windowController,
          builder: _placeholderBuilder,
          child: const SizedBox.expand(),
        ),
      ),
    );

    await tester.pumpWidget(const SizedBox.shrink());

    expect(windowController.isDestroyed, isFalse);
    expect(windowController.destroyCount, 0);
    expect(find.byType(Placeholder), findsNothing);
  });

  testWidgets('The owner can destroy the controller when it is disposed', (
    WidgetTester tester,
  ) async {
    final windowController = _StubPopupWindowController(tester);

    await tester.pumpWidget(
      buildAnchoredWindow(
        nestedWindow: _DestroyOnDispose(
          controller: windowController,
          child: NestedWindow(
            controller: windowController,
            builder: _placeholderBuilder,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
    expect(find.byType(Placeholder), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());

    expect(windowController.isDestroyed, isTrue);
    expect(windowController.destroyCount, 1);
    expect(find.byType(Placeholder), findsNothing);
  });

  testWidgets('NestedWindow forwards anchor movement to PopupWindowController.updatePosition', (
    WidgetTester tester,
  ) async {
    final GlobalKey key = GlobalKey();
    _StubPopupWindowController? stub;

    Widget build(Offset offset) {
      return buildAnchoredWindow(
        offset: offset,
        nestedWindow: NestedWindow(
          key: key,
          controller: stub,
          builder: _placeholderBuilder,
          child: const SizedBox.expand(),
        ),
      );
    }

    await tester.pumpWidget(build(const Offset(30, 20)));
    // Create the window from the last layout, as an event handler would.
    expect(
      NestedWindow.layoutInfoOf(key.currentContext!).anchorRect,
      const Rect.fromLTWH(30, 20, 100, 50),
    );
    stub = _StubPopupWindowController(tester);
    await tester.pumpWidget(build(const Offset(30, 20)));
    expect(stub.positionUpdates, isEmpty);

    await tester.pumpWidget(build(const Offset(80, 90)));
    expect(stub.positionUpdates, <Rect>[const Rect.fromLTWH(80, 90, 100, 50)]);

    // A frame that does not move the anchor does not report a new position.
    await tester.pump();
    expect(stub.positionUpdates, hasLength(1));

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('NestedWindow stops forwarding anchor movement once the window is destroyed', (
    WidgetTester tester,
  ) async {
    final windowController = _StubPopupWindowController(tester);

    Widget build(Offset offset) {
      return buildAnchoredWindow(
        offset: offset,
        nestedWindow: NestedWindow(
          controller: windowController,
          builder: _placeholderBuilder,
          child: const SizedBox.expand(),
        ),
      );
    }

    await tester.pumpWidget(build(const Offset(30, 20)));
    final int updatesBeforeDestroy = windowController.positionUpdates.length;

    windowController.destroy();
    await tester.pump();

    await tester.pumpWidget(build(const Offset(80, 90)));
    expect(windowController.positionUpdates, hasLength(updatesBeforeDestroy));
  });
}
