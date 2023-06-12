// Copyright 2018 the Dart project authors.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:visibility_detector_example/main.dart' as demo;

/// Maps [row, column] indices to the last reported [VisibilityInfo] for the
/// corresponding [VisibilityDetector] widget in the demo app.
final _positionToVisibilityInfo = <demo.RowColumn, VisibilityInfo>{};

/// [Key] used to identify the [_TestPropertyChange] widget.
final _testPropertyChangeKey = GlobalKey<_TestPropertyChangeState>();

/// [Key] used to identify the [_TestOffset] widget or its [VisibilityDetector].
final _testOffsetKey = UniqueKey();

void main() {
  setUpAll(() {
    demo.visibilityListeners.add((demo.RowColumn rc, VisibilityInfo info) {
      _positionToVisibilityInfo[rc] = info;
    });
  });

  tearDown(_positionToVisibilityInfo.clear);

  _wrapTest(
    'VisibilityDetector properly builds',
    callback: (tester) async {
      expect(find.byType(ErrorWidget), findsNothing);

      final cell = find.byKey(demo.cellKey(0, 0));
      expect(cell, findsOneWidget);
    },
  );

  _wrapTest(
    'VisibilityDetector reports initial visibility',
    callback: (tester) async {
      final cellKey = demo.cellKey(0, 0);
      final expectedRect =
          tester.getRect(find.byKey(demo.cellContentKey(0, 0)));
      var info = _positionToVisibilityInfo[demo.RowColumn(0, 0)];
      expect(info, isNotNull);

      info = info!;
      expect(info.size, expectedRect.size);
      expect(info.size.width, demo.cellWidth);
      expect(info.size.height, demo.cellHeight);
      expect(info.visibleBounds, Offset.zero & info.size);
      expect(info.visibleFraction, 1.0);

      final bounds =
          VisibilityDetectorController.instance.widgetBoundsFor(cellKey);
      expect(bounds, expectedRect);
    },
  );

  _wrapTest(
    'VisibilityDetector test with transform.scale',
    callback: (tester) async {
      final scaleButton = find.byKey(demo.scaleButtonKey);
      await tester.tap(scaleButton);
      await tester.pump();
      await tester.pump(VisibilityDetectorController.instance.updateInterval);

      var info = _positionToVisibilityInfo[demo.RowColumn(0, 1)];
      expect(info, isNotNull);

      info = info!;
      expect(info.visibleFraction, 1.0);
    },
  );

  _wrapTest(
    'VisibilityDetector reports partial visibility when part of it is '
    'vertically scrolled offscreen',
    callback: (tester) async {
      final mainList = find.byKey(demo.mainListKey);
      expect(mainList, findsOneWidget);
      final viewRect = tester.getRect(mainList);

      final cellKey = demo.cellKey(0, 0);
      final originalRect =
          tester.getRect(find.byKey(demo.cellContentKey(0, 0)));

      const dy = 30.0;
      await _doScroll(tester, find.byKey(demo.secondaryScrollableKey(0)),
          const Offset(0, dy));

      var info = _positionToVisibilityInfo[demo.RowColumn(0, 0)];
      expect(info, isNotNull);

      info = info!;
      expect(info.size, originalRect.size);

      final expectedVisibleBounds = Rect.fromLTRB(
          0,
          dy - (originalRect.top - viewRect.top),
          originalRect.width,
          originalRect.height);
      expect(info.visibleBounds, expectedVisibleBounds);
      expect(info.visibleFraction,
          info.visibleBounds.height / originalRect.height);

      final bounds =
          VisibilityDetectorController.instance.widgetBoundsFor(cellKey);
      expect(bounds, originalRect.shift(const Offset(0, -dy)));
    },
  );

  _wrapTest(
    'VisibilityDetector reports partial visibility when part of it is '
    'horizontally scrolled offscreen',
    callback: (tester) async {
      final mainList = find.byKey(demo.mainListKey);
      final viewRect = tester.getRect(mainList);

      final cellKey = demo.cellKey(2, 0);
      final originalRect =
          tester.getRect(find.byKey(demo.cellContentKey(2, 0)));
      const dx = 30.0;
      expect(dx < originalRect.width, true);

      final row = find.byKey(demo.secondaryScrollableKey(2));
      await _doScroll(tester, row, const Offset(dx, 0));

      var info = _positionToVisibilityInfo[demo.RowColumn(2, 0)];
      expect(info, isNotNull);

      info = info!;
      expect(info.size, originalRect.size);

      final expectedVisibleBounds = Rect.fromLTRB(
          dx - (originalRect.left - viewRect.left),
          0,
          originalRect.width,
          originalRect.height);
      expect(info.visibleBounds, expectedVisibleBounds);
      expect(
          info.visibleFraction, info.visibleBounds.width / originalRect.width);

      final bounds =
          VisibilityDetectorController.instance.widgetBoundsFor(cellKey);
      expect(bounds, originalRect.shift(const Offset(-dx, 0)));
    },
  );

  _wrapTest(
    'VisibilityDetector reports being not visible when fully scrolled '
    'offscreen',
    callback: (tester) async {
      final mainList = find.byKey(demo.mainListKey);
      expect(mainList, findsOneWidget);
      final viewRect = tester.getRect(mainList);

      final cellKey = demo.cellKey(0, 0);
      final originalRect =
          tester.getRect(find.byKey(demo.cellContentKey(0, 0)));

      final dy = originalRect.bottom - viewRect.top;
      await _doScroll(tester, mainList, Offset(0, dy));

      var info = _positionToVisibilityInfo[demo.RowColumn(0, 0)];
      expect(info, isNotNull);

      info = info!;
      expect(info.size, originalRect.size);
      expect(info.visibleBounds.size, Size.zero);
      expect(info.visibleFraction, 0.0);

      final bounds =
          VisibilityDetectorController.instance.widgetBoundsFor(cellKey);
      expect(bounds, null);
    },
  );

  _wrapTest(
    'VisibilityDetector reports partial visibility when almost fully scrolled '
    'offscreen',
    callback: (tester) async {
      final mainList = find.byKey(demo.mainListKey);
      expect(mainList, findsOneWidget);
      final viewRect = tester.getRect(mainList);

      final cellKey = demo.cellKey(0, 0);
      final originalRect =
          tester.getRect(find.byKey(demo.cellContentKey(0, 0)));

      final dy = (originalRect.bottom - viewRect.top) - 1;

      await _doScroll(
          tester, find.byKey(demo.secondaryScrollableKey(0)), Offset(0, dy));

      var info = _positionToVisibilityInfo[demo.RowColumn(0, 0)];
      expect(info, isNotNull);

      info = info!;
      expect(info.size, originalRect.size);

      final expectedVisibleBounds = Rect.fromLTRB(
          0, originalRect.height - 1, originalRect.width, originalRect.height);
      expect(info.visibleBounds, expectedVisibleBounds);
      expect(info.visibleFraction,
          info.visibleBounds.height / originalRect.height);

      final bounds =
          VisibilityDetectorController.instance.widgetBoundsFor(cellKey);
      expect(bounds, originalRect.shift(Offset(0, -dy)));
    },
  );

  _wrapTest(
    'VisibilityDetector reports being not visible when removed from the widget '
    'tree',
    callback: (tester) async {
      final cellKey = demo.cellKey(0, 0);
      final originalRect =
          tester.getRect(find.byKey(demo.cellContentKey(0, 0)));

      await _clearWidgetTree(tester, notifyNow: false);

      var info = _positionToVisibilityInfo[demo.RowColumn(0, 0)];
      expect(info, isNotNull);

      info = info!;
      expect(info.size, originalRect.size);
      expect(info.visibleBounds.size, Size.zero);
      expect(info.visibleFraction, 0.0);

      final bounds =
          VisibilityDetectorController.instance.widgetBoundsFor(cellKey);
      expect(bounds, null);
    },
  );

  testWidgets(
    'VisibilityDetector callbacks fire immediately when setting '
    'updateInterval=0',
    (tester) async {
      final controller = VisibilityDetectorController.instance;
      final oldDuration = controller.updateInterval;
      addTearDown(() {
        controller.updateInterval = oldDuration;
      });
      controller.updateInterval = Duration.zero;

      await tester.pumpWidget(const demo.VisibilityDetectorDemo());
      _expectVisibility(demo.RowColumn(0, 0), 1, epsilon: 0);

      await tester.pumpWidget(const Placeholder());
      _expectVisibility(demo.RowColumn(0, 0), 0, epsilon: 0);
    },
  );

  testWidgets(
    'Pending callback is cancelled when forget is called',
    (tester) async {
      final key = UniqueKey();
      final controller = VisibilityDetectorController.instance;

      await tester.pumpWidget(VisibilityDetector(
        key: key,
        onVisibilityChanged: (_) {},
        child: const Placeholder(),
      ));
      await tester.pumpWidget(const Placeholder());
      controller.forget(key);
    },
  );

  _wrapTest(
    'VisibilityDetector fires callbacks when becoming enabled and not when '
    'becoming disabled',
    widget: _TestPropertyChange(key: _testPropertyChangeKey),
    callback: (tester) async {
      final state = _testPropertyChangeKey.currentState!;

      // Validate the initial state.  The visibility callback should have fired
      // exactly once.
      expect(state.lastVisibleFraction, 1.0);
      expect(state.callbackCount, 1);

      // Disable the [VisibilityDetector].  This should not trigger the
      // visibility callback.
      await _doStateChange(tester, () {
        state.visibilityDetectorEnabled = false;
      });
      expect(state.lastVisibleFraction, 1.0);
      expect(state.callbackCount, 1);

      // Re-enable the [VisibilityDetector].  This should re-trigger the
      // visibility callback.
      await _doStateChange(tester, () {
        state.visibilityDetectorEnabled = true;
      });
      expect(state.lastVisibleFraction, 1.0);
      expect(state.callbackCount, 2);
    },
  );

  _wrapTest(
    'VisibilityDetector reports visibility changes after a simulated screen '
    'rotation',
    callback: (tester) async {
      _expectVisibility(demo.RowColumn(0, 6), 0.360);

      // This item was never visible, so we have no data for it.
      expect(_positionToVisibilityInfo[demo.RowColumn(5, 0)], null);

      await _simulateScreenRotation(tester);
      await tester.pump(VisibilityDetectorController.instance.updateInterval);

      _expectVisibility(demo.RowColumn(0, 6), 0, epsilon: 0);
      _expectVisibility(demo.RowColumn(5, 0), 1, epsilon: 0);

      // Rotate back to the original size.
      await _simulateScreenRotation(tester);
      await tester.pump(VisibilityDetectorController.instance.updateInterval);

      // Re-verify the original visibilities.
      _expectVisibility(demo.RowColumn(0, 6), 0.360);
      _expectVisibility(demo.RowColumn(5, 0), 0, epsilon: 0);
    },
  );

  _wrapTest(
    'VisibilityDetector computes widget bounds in global coordinates',
    widget: _TestOffset(key: _testOffsetKey),
    callback: (tester) async {
      final viewSize = tester.binding.renderView.size;

      final bounds =
          VisibilityDetectorController.instance.widgetBoundsFor(_testOffsetKey);
      expect(
        bounds,
        tester.getRect(find.byType(VisibilityDetector)),
      );
      expect(
        bounds,
        Rect.fromCenter(
          center: viewSize.center(Offset.zero),
          width: _TestOffset.detectorWidth,
          height: _TestOffset.detectorHeight,
        ),
      );
    },
  );
}

/// Initializes the widget tree that is populated with [VisibilityDetector]
/// widgets and waits sufficiently long for their visibility callbacks to fire.
Future<void> _initWidgetTree(Widget widget, WidgetTester tester) async {
  expect(_positionToVisibilityInfo.isEmpty, true);
  await tester.pumpWidget(widget);

  final controller = VisibilityDetectorController.instance;
  if (controller.updateInterval != Duration.zero) {
    await tester.pumpAndSettle(controller.updateInterval);
  }
}

/// Replaces the widget tree with a [Placeholder] widget.  If `notifyNow` is
/// `true`, fires [VisibilityDetector] callbacks immediately.  Otherwise waits
/// sufficiently long for them to fire as normal.
Future<void> _clearWidgetTree(WidgetTester tester,
    {bool notifyNow = true}) async {
  await tester.pumpWidget(const Placeholder());

  final controller = VisibilityDetectorController.instance;
  if (notifyNow) {
    controller.notifyNow();
  } else if (controller.updateInterval != Duration.zero) {
    await tester.pumpAndSettle(controller.updateInterval);
  }
}

/// Wrapper around [testWidgets] to automatically do our own custom test
/// setup and teardown.
void _wrapTest(
  String description, {
  Widget? widget,
  required WidgetTesterCallback callback,
}) {
  testWidgets(description, (tester) async {
    // We can't use [setUp] and [tearDown] because we want access to the
    // [WidgetTester].  Additionally, [tearDown] is executed *after* the
    // widget tree is destroyed, which is too late for our purposes. (See
    // details below.)
    await _initWidgetTree(
      widget ?? demo.VisibilityDetectorDemo(useSlivers: false),
      tester,
    );
    await callback(tester);

    /// When the test destroys the widget tree with [VisibilityDetector] widgets
    /// in it, they will schedule callbacks to indicate that they've become
    /// non-visible.  The flutter_test framework then will fail assertions that
    /// there are no outstanding [Timer] objects.
    ///
    /// There currently is no direct way to suppress those assertions nor to
    /// flush those [Timer] objects. (See https://github.com/flutter/flutter/issues/24166.)
    /// Instead we must explicitly clear the widget tree ourselves and wait for
    /// callbacks to fire before ending the test.
    await _clearWidgetTree(tester);
  });

  // Test one more time using slivers version of the demo.
  testWidgets(description, (tester) async {
    await _initWidgetTree(
      widget ?? demo.VisibilityDetectorDemo(useSlivers: true),
      tester,
    );
    await callback(tester);
    await _clearWidgetTree(tester);
  });
}

/// Scrolls the specified widget by the specified offset and waits sufficiently
/// long for the [VisibilityDetector] callbacks to fire.
Future<void> _doScroll(
    WidgetTester tester, Finder finder, Offset scrollOffset) async {
  // The scroll direction is the opposite of the direction to drag.  We also
  // must drag by [kDragSlopDefault] first to start the drag.
  final dragOffset = -Offset.fromDirection(
      scrollOffset.direction, scrollOffset.distance + kDragSlopDefault);
  await tester.drag(finder, dragOffset);

  // Wait for the drag to complete.
  await tester.pumpAndSettle();

  // Wait for callbacks to fire.
  await tester.pump(VisibilityDetectorController.instance.updateInterval);
}

/// Invokes a callback to mutate a [State] object and waits sufficiently long
/// for the [VisibilityDetector] callbacks to fire.
Future<void> _doStateChange(WidgetTester tester, VoidCallback callback) async {
  callback();

  // Wait for the state change to rebuild the widget.
  await tester.pump();

  // Wait for callbacks to fire.
  await tester.pump(VisibilityDetectorController.instance.updateInterval);
}

// Simulates a screen rotation by swapping the screen width and height.
Future<void> _simulateScreenRotation(WidgetTester tester) async {
  final oldViewSize = tester.binding.renderView.size;

  final newViewSize = Size(oldViewSize.height, oldViewSize.width);

  // The typical way to simulate a screen rotation is to wrap the widget tree
  // in a [SizedBox] and change its dimensions.  However, empirical testing
  // indicates that that approach does extra work that an actual screen rotation
  // doesn't do.  For example, an actual screen rotation might trigger
  // [VisibilityDetectorLayer.attach] without triggering
  // [VisibilityDetectorLayer.addToScene], whereas the [SizedBox] approach
  // triggers both.
  //
  // TODO(https://github.com/flutter/flutter/issues/62451): Use TestWindow.physicalSizeTestValue.
  await tester.binding.setSurfaceSize(newViewSize);
  tester.binding.scheduleFrame();

  // Wait for the new frame.
  await tester.pump();
}

/// Verifies that the specified cell of the demo app reported the expected
/// visibility.
void _expectVisibility(demo.RowColumn rc, double expectedFraction,
    {double epsilon = 0.001}) {
  var info = _positionToVisibilityInfo[rc];
  expect(info, isNotNull);

  info = info!;
  expect(info.visibleFraction, closeTo(expectedFraction, epsilon));
}

/// A widget used to test that disabling a [VisibilityDetector] does not trigger
/// its visibility callback and that re-enabling it does.
class _TestPropertyChange extends StatefulWidget {
  const _TestPropertyChange({Key? key}) : super(key: key);

  @override
  _TestPropertyChangeState createState() => _TestPropertyChangeState();
}

class _TestPropertyChangeState extends State<_TestPropertyChange> {
  /// Whether our [VisibilityDetector] should be enabled (i.e., whether it
  /// should fire visibility callbacks).
  bool _visibilityDetectorEnabled = true;

  bool get visibilityDetectorEnabled => _visibilityDetectorEnabled;

  set visibilityDetectorEnabled(bool value) {
    setState(() {
      _visibilityDetectorEnabled = value;
    });
  }

  /// The last reported visibility of our [VisibilityDetector].
  double _lastVisibleFraction = 0;

  double get lastVisibleFraction => _lastVisibleFraction;

  /// The number of times that our [VisibilityDetector]'s callback has been
  /// triggered.
  int _callbackCount = 0;

  int get callbackCount => _callbackCount;

  /// [VisibilityDetector] callback for when the visibility of the widget
  /// changes.
  void _handleVisibilityChanged(VisibilityInfo info) {
    _lastVisibleFraction = info.visibleFraction;
    _callbackCount += 1;
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const Key('TestPropertyChange'),
      onVisibilityChanged:
          visibilityDetectorEnabled ? _handleVisibilityChanged : null,
      child: const Placeholder(),
    );
  }
}

/// A widget to exercise calling [RenderVisibilityDetector.paint] with a
/// non-zero [Offset].
class _TestOffset extends StatelessWidget {
  const _TestOffset({required Key key}) : super(key: key);

  static const detectorWidth = 200.0;
  static const detectorHeight = 100.0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: VisibilityDetector(
            key: key!,
            onVisibilityChanged: (visibilityInfo) {},
            child: const SizedBox(
              width: detectorWidth,
              height: detectorHeight,
              child: Placeholder(),
            ),
          ),
        ),
      ),
    );
  }
}
