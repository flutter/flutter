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
        NestedWindowBuilder,
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

// A NestedWindow.windowBuilder that records the windows it creates and the
// layout information they were created with.
class _WindowRecorder {
  _WindowRecorder(this.tester, {this.contentBuilder = _buildPlaceholder});

  final WidgetTester tester;
  WidgetBuilder contentBuilder;
  final windows = <_StubPopupWindowController>[];
  final layoutInfos = <NestedWindowLayoutInfo>[];
  final contexts = <BuildContext>[];

  _StubPopupWindowController get last => windows.last;

  static Widget _buildPlaceholder(BuildContext context) => const Placeholder();

  ({BaseWindowController controller, WidgetBuilder builder}) call(
    BuildContext context,
    NestedWindowLayoutInfo info,
  ) {
    final window = _StubPopupWindowController(tester);
    windows.add(window);
    layoutInfos.add(info);
    contexts.add(context);
    return (controller: window, builder: (BuildContext context) => contentBuilder(context));
  }
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

  NestedWindowController createController() {
    final controller = NestedWindowController();
    addTearDown(controller.dispose);
    return controller;
  }

  // Builds a NestedWindow whose child is a 100x50 box whose top left corner is
  // at `offset` within the view.
  Widget buildAnchoredWindow({
    required NestedWindowController controller,
    required NestedWindowBuilder windowBuilder,
    Offset offset = const Offset(30, 20),
    Key? key,
  }) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: offset.dx,
            top: offset.dy,
            width: 100,
            height: 50,
            child: NestedWindow(
              key: key,
              controller: controller,
              windowBuilder: windowBuilder,
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  void expectAnchorGeometry(
    WidgetTester tester,
    NestedWindowLayoutInfo info, {
    Offset offset = const Offset(30, 20),
  }) {
    expect(info.childSize, const Size(100, 50));
    expect(info.anchorRect, offset & const Size(100, 50));
    expect(info.viewSize, tester.view.physicalSize / tester.view.devicePixelRatio);
    expect(MatrixUtils.transformPoint(info.childPaintTransform, Offset.zero), offset);
  }

  testWidgets('NestedWindow is initially hidden and does not call windowBuilder', (
    WidgetTester tester,
  ) async {
    final NestedWindowController controller = createController();
    final recorder = _WindowRecorder(tester);

    await tester.pumpWidget(
      buildAnchoredWindow(controller: controller, windowBuilder: recorder.call),
    );

    expect(controller.isShowing, isFalse);
    expect(recorder.windows, isEmpty);
    expect(find.byType(Placeholder), findsNothing);
  });

  testWidgets('NestedWindow passes the geometry of its child to windowBuilder', (
    WidgetTester tester,
  ) async {
    final NestedWindowController controller = createController();
    final recorder = _WindowRecorder(tester);

    await tester.pumpWidget(
      buildAnchoredWindow(controller: controller, windowBuilder: recorder.call),
    );
    controller.show();
    await tester.pump();

    expect(recorder.layoutInfos, hasLength(1));
    expectAnchorGeometry(tester, recorder.layoutInfos.single);
  });

  testWidgets('NestedWindow passes the current geometry on every show', (
    WidgetTester tester,
  ) async {
    final NestedWindowController controller = createController();
    final recorder = _WindowRecorder(tester);

    await tester.pumpWidget(
      buildAnchoredWindow(controller: controller, windowBuilder: recorder.call),
    );
    controller.show();
    await tester.pump();
    controller.hide();
    await tester.pump();

    await tester.pumpWidget(
      buildAnchoredWindow(
        controller: controller,
        windowBuilder: recorder.call,
        offset: const Offset(80, 90),
      ),
    );
    controller.show();
    await tester.pump();

    expect(recorder.layoutInfos, hasLength(2));
    expectAnchorGeometry(tester, recorder.layoutInfos[0]);
    expectAnchorGeometry(tester, recorder.layoutInfos[1], offset: const Offset(80, 90));
  });

  testWidgets('NestedWindowController.show throws before the child is laid out', (
    WidgetTester tester,
  ) async {
    final NestedWindowController controller = createController();
    final recorder = _WindowRecorder(tester);
    final Widget widget = buildAnchoredWindow(controller: controller, windowBuilder: recorder.call);

    await tester.pumpWidget(widget, phase: EnginePhase.build);

    expect(controller.show, throwsFlutterError);
    expect(recorder.windows, isEmpty);
    expect(controller.isShowing, isFalse);

    // Once the child is laid out, the window can be shown.
    await tester.pumpWidget(widget);
    controller.show();
    await tester.pump();
    expect(controller.isShowing, isTrue);
    expect(find.byType(Placeholder), findsOneWidget);
  });

  testWidgets('NestedWindowController asserts when it is not attached to a NestedWindow', (
    WidgetTester tester,
  ) async {
    final NestedWindowController controller = createController();

    expect(controller.show, throwsAssertionError);
    expect(controller.hide, throwsAssertionError);
    expect(controller.toggle, throwsAssertionError);
  });

  testWidgets('NestedWindow windowBuilder and content inherit from surrounding widgets', (
    WidgetTester tester,
  ) async {
    final NestedWindowController controller = createController();
    String? builderValue;
    String? contentValue;
    BaseWindowController? contentScope;
    BaseWindowController? createdWindow;

    await tester.pumpWidget(
      _TestScope(
        value: 'surrounding',
        child: buildAnchoredWindow(
          controller: controller,
          windowBuilder: (BuildContext context, NestedWindowLayoutInfo info) {
            builderValue = _TestScope.of(context);
            createdWindow = _StubPopupWindowController(tester);
            return (
              controller: createdWindow!,
              builder: (BuildContext context) {
                contentValue = _TestScope.of(context);
                contentScope = WindowScope.of(context);
                return const SizedBox.shrink();
              },
            );
          },
        ),
      ),
    );
    controller.show();
    await tester.pump();

    expect(builderValue, 'surrounding');
    expect(contentValue, 'surrounding');
    expect(contentScope, same(createdWindow));
  });

  testWidgets('NestedWindowController.isShowing tracks show, hide and toggle', (
    WidgetTester tester,
  ) async {
    final NestedWindowController controller = createController();
    final recorder = _WindowRecorder(tester);
    final notifications = <bool>[];
    controller.addListener(() => notifications.add(controller.isShowing));

    await tester.pumpWidget(
      buildAnchoredWindow(controller: controller, windowBuilder: recorder.call),
    );

    controller.show();
    expect(controller.isShowing, isTrue);
    // Showing an already showing window does nothing.
    controller.show();
    await tester.pump();
    expect(recorder.windows, hasLength(1));

    controller.hide();
    expect(controller.isShowing, isFalse);
    // Hiding an already hidden window does nothing.
    controller.hide();
    await tester.pump();

    controller.toggle();
    expect(controller.isShowing, isTrue);
    await tester.pump();
    controller.toggle();
    expect(controller.isShowing, isFalse);
    await tester.pump();

    expect(notifications, <bool>[true, false, true, false]);
    expect(recorder.windows, hasLength(2));
  });

  testWidgets('Hiding destroys the native window and removes its content', (
    WidgetTester tester,
  ) async {
    final NestedWindowController controller = createController();
    final recorder = _WindowRecorder(tester);

    await tester.pumpWidget(
      buildAnchoredWindow(controller: controller, windowBuilder: recorder.call),
    );
    controller.show();
    await tester.pump();
    expect(find.byType(Placeholder), findsOneWidget);
    final _StubPopupWindowController first = recorder.last;

    controller.hide();
    await tester.pump();
    expect(find.byType(Placeholder), findsNothing);
    expect(first.isDestroyed, isTrue);
    expect(first.destroyCount, 1);

    // Showing again creates a new window rather than reusing the destroyed one.
    controller.show();
    await tester.pump();
    expect(recorder.windows, hasLength(2));
    expect(recorder.last, isNot(same(first)));
    expect(recorder.last.isDestroyed, isFalse);
    expect(find.byType(Placeholder), findsOneWidget);
  });

  testWidgets('A window destroyed by the platform is removed and reported as hidden', (
    WidgetTester tester,
  ) async {
    final NestedWindowController controller = createController();
    final recorder = _WindowRecorder(tester);

    await tester.pumpWidget(
      buildAnchoredWindow(controller: controller, windowBuilder: recorder.call),
    );
    controller.show();
    await tester.pump();

    recorder.last.destroy();
    expect(controller.isShowing, isFalse);
    await tester.pump();
    expect(find.byType(Placeholder), findsNothing);

    // Removing the NestedWindow does not destroy the window a second time.
    await tester.pumpWidget(const SizedBox.shrink());
    expect(recorder.last.destroyCount, 1);
  });

  testWidgets('A windowBuilder that returns a destroyed window does not show it', (
    WidgetTester tester,
  ) async {
    final NestedWindowController controller = createController();
    final window = _StubPopupWindowController(tester)..destroy();

    await tester.pumpWidget(
      buildAnchoredWindow(
        controller: controller,
        windowBuilder: (BuildContext context, NestedWindowLayoutInfo info) =>
            (controller: window, builder: (BuildContext context) => const Placeholder()),
      ),
    );
    controller.show();
    await tester.pump();

    expect(controller.isShowing, isFalse);
    expect(find.byType(Placeholder), findsNothing);
    expect(window.destroyCount, 1);
  });

  testWidgets('Removing a showing NestedWindow destroys its native window', (
    WidgetTester tester,
  ) async {
    final NestedWindowController controller = createController();
    final recorder = _WindowRecorder(tester);

    // The label lives outside of the removed subtree, so it is notified while
    // the NestedWindow is disposed.
    Widget build({required bool showNestedWindow}) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: <Widget>[
            ListenableBuilder(
              listenable: controller,
              builder: (BuildContext context, Widget? child) =>
                  Text(controller.isShowing ? 'showing' : 'hidden'),
            ),
            if (showNestedWindow)
              SizedBox(
                width: 100,
                height: 50,
                child: NestedWindow(
                  controller: controller,
                  windowBuilder: recorder.call,
                  child: const SizedBox.expand(),
                ),
              ),
          ],
        ),
      );
    }

    await tester.pumpWidget(build(showNestedWindow: true));
    controller.show();
    await tester.pump();
    expect(find.text('showing'), findsOneWidget);

    await tester.pumpWidget(build(showNestedWindow: false));
    expect(recorder.last.isDestroyed, isTrue);
    expect(recorder.last.destroyCount, 1);
    expect(controller.isShowing, isFalse);
    expect(find.byType(Placeholder), findsNothing);

    await tester.pump();
    expect(find.text('hidden'), findsOneWidget);
  });

  testWidgets('Removing a hidden NestedWindow does not destroy anything twice', (
    WidgetTester tester,
  ) async {
    final NestedWindowController controller = createController();
    final recorder = _WindowRecorder(tester);

    await tester.pumpWidget(
      buildAnchoredWindow(controller: controller, windowBuilder: recorder.call),
    );
    controller.show();
    await tester.pump();
    controller.hide();
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    expect(recorder.last.destroyCount, 1);
  });

  testWidgets('NestedWindow can be removed together with a disposed controller', (
    WidgetTester tester,
  ) async {
    final controller = NestedWindowController();
    final recorder = _WindowRecorder(tester);

    await tester.pumpWidget(
      buildAnchoredWindow(controller: controller, windowBuilder: recorder.call),
    );
    controller.show();
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    await tester.pump();

    expect(recorder.last.destroyCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Rebuilding updates the content without recreating the window', (
    WidgetTester tester,
  ) async {
    final NestedWindowController controller = createController();
    final recorder = _WindowRecorder(
      tester,
      contentBuilder: (BuildContext context) => Text(_TestScope.of(context)),
    );

    Widget build(String value) {
      return _TestScope(
        value: value,
        child: buildAnchoredWindow(controller: controller, windowBuilder: recorder.call),
      );
    }

    await tester.pumpWidget(build('first'));
    controller.show();
    await tester.pump();
    expect(find.text('first'), findsOneWidget);

    await tester.pumpWidget(build('second'));
    expect(find.text('second'), findsOneWidget);
    expect(recorder.windows, hasLength(1));
    expect(recorder.last.destroyCount, 0);
  });

  testWidgets('A different NestedWindowController takes over the showing window', (
    WidgetTester tester,
  ) async {
    final NestedWindowController first = createController();
    final NestedWindowController second = createController();
    final recorder = _WindowRecorder(tester);

    await tester.pumpWidget(buildAnchoredWindow(controller: first, windowBuilder: recorder.call));
    first.show();
    await tester.pump();

    await tester.pumpWidget(buildAnchoredWindow(controller: second, windowBuilder: recorder.call));
    expect(first.isShowing, isFalse);
    expect(second.isShowing, isTrue);
    expect(recorder.windows, hasLength(1));
    expect(recorder.last.destroyCount, 0);
    expect(find.byType(Placeholder), findsOneWidget);

    expect(first.hide, throwsAssertionError);
    second.hide();
    await tester.pump();
    expect(second.isShowing, isFalse);
    expect(recorder.last.destroyCount, 1);
    expect(find.byType(Placeholder), findsNothing);
  });

  testWidgets('NestedWindow forwards anchor movement to PopupWindowController.updatePosition', (
    WidgetTester tester,
  ) async {
    final NestedWindowController controller = createController();
    final recorder = _WindowRecorder(tester);

    Widget build(Offset offset) {
      return buildAnchoredWindow(
        controller: controller,
        windowBuilder: recorder.call,
        offset: offset,
      );
    }

    await tester.pumpWidget(build(const Offset(30, 20)));
    controller.show();
    await tester.pump();
    // The window is created at the current anchor, so it is not repositioned.
    expect(recorder.last.positionUpdates, isEmpty);

    await tester.pumpWidget(build(const Offset(80, 90)));
    expect(recorder.last.positionUpdates, <Rect>[const Rect.fromLTWH(80, 90, 100, 50)]);

    // A frame that does not move the anchor does not report a new position.
    await tester.pump();
    expect(recorder.last.positionUpdates, hasLength(1));
  });

  testWidgets('NestedWindow stops forwarding anchor movement once hidden', (
    WidgetTester tester,
  ) async {
    final NestedWindowController controller = createController();
    final recorder = _WindowRecorder(tester);

    Widget build(Offset offset) {
      return buildAnchoredWindow(
        controller: controller,
        windowBuilder: recorder.call,
        offset: offset,
      );
    }

    await tester.pumpWidget(build(const Offset(30, 20)));
    controller.show();
    await tester.pump();
    controller.hide();
    await tester.pump();

    await tester.pumpWidget(build(const Offset(80, 90)));
    expect(recorder.last.positionUpdates, isEmpty);
  });
}
