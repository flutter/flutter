// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'all_elements.dart';
import 'event_simulation.dart';
import 'finders.dart';
import 'test_async_utils.dart';
import 'test_pointer.dart';

/// The default drag touch slop used to break up a large drag into multiple
/// smaller moves.
///
/// This value must be greater than [kTouchSlop].
const double kDragSlopDefault = 20.0;

/// Class that programmatically interacts with widgets.
///
/// For a variant of this class suited specifically for unit tests, see
/// [WidgetTester]. For one suitable for live tests on a device, consider
/// [LiveWidgetController].
///
/// Concrete subclasses must implement the [pump] method.
abstract class WidgetController {
  /// Creates a widget controller that uses the given binding.
  WidgetController(this.binding);

  /// A reference to the current instance of the binding.
  final WidgetsBinding binding;

  // FINDER API

  // TODO(ianh): verify that the return values are of type T and throw
  // a good message otherwise, in all the generic methods below

  /// Checks if `finder` exists in the tree.
  bool any(Finder finder) {
    TestAsyncUtils.guardSync();
    return finder.evaluate().isNotEmpty;
  }

  /// All widgets currently in the widget tree (lazy pre-order traversal).
  ///
  /// Can contain duplicates, since widgets can be used in multiple
  /// places in the widget tree.
  Iterable<Widget> get allWidgets {
    TestAsyncUtils.guardSync();
    return allElements.map<Widget>((Element element) => element.widget);
  }

  /// The matching widget in the widget tree.
  ///
  /// Throws a [StateError] if `finder` is empty or matches more than
  /// one widget.
  ///
  /// * Use [firstWidget] if you expect to match several widgets but only want the first.
  /// * Use [widgetList] if you expect to match several widgets and want all of them.
  T widget<T extends Widget>(Finder finder) {
    TestAsyncUtils.guardSync();
    return finder.evaluate().single.widget as T;
  }

  /// The first matching widget according to a depth-first pre-order
  /// traversal of the widget tree.
  ///
  /// Throws a [StateError] if `finder` is empty.
  ///
  /// * Use [widget] if you only expect to match one widget.
  T firstWidget<T extends Widget>(Finder finder) {
    TestAsyncUtils.guardSync();
    return finder.evaluate().first.widget as T;
  }

  /// The matching widgets in the widget tree.
  ///
  /// * Use [widget] if you only expect to match one widget.
  /// * Use [firstWidget] if you expect to match several but only want the first.
  Iterable<T> widgetList<T extends Widget>(Finder finder) {
    TestAsyncUtils.guardSync();
    return finder.evaluate().map<T>((Element element) {
      final T result = element.widget as T;
      return result;
    });
  }

  /// All elements currently in the widget tree (lazy pre-order traversal).
  ///
  /// The returned iterable is lazy. It does not walk the entire widget tree
  /// immediately, but rather a chunk at a time as the iteration progresses
  /// using [Iterator.moveNext].
  Iterable<Element> get allElements {
    TestAsyncUtils.guardSync();
    return collectAllElementsFrom(binding.renderViewElement!, skipOffstage: false);
  }

  /// The matching element in the widget tree.
  ///
  /// Throws a [StateError] if `finder` is empty or matches more than
  /// one element.
  ///
  /// * Use [firstElement] if you expect to match several elements but only want the first.
  /// * Use [elementList] if you expect to match several elements and want all of them.
  T element<T extends Element>(Finder finder) {
    TestAsyncUtils.guardSync();
    return finder.evaluate().single as T;
  }

  /// The first matching element according to a depth-first pre-order
  /// traversal of the widget tree.
  ///
  /// Throws a [StateError] if `finder` is empty.
  ///
  /// * Use [element] if you only expect to match one element.
  T firstElement<T extends Element>(Finder finder) {
    TestAsyncUtils.guardSync();
    return finder.evaluate().first as T;
  }

  /// The matching elements in the widget tree.
  ///
  /// * Use [element] if you only expect to match one element.
  /// * Use [firstElement] if you expect to match several but only want the first.
  Iterable<T> elementList<T extends Element>(Finder finder) {
    TestAsyncUtils.guardSync();
    return finder.evaluate().cast<T>();
  }

  /// All states currently in the widget tree (lazy pre-order traversal).
  ///
  /// The returned iterable is lazy. It does not walk the entire widget tree
  /// immediately, but rather a chunk at a time as the iteration progresses
  /// using [Iterator.moveNext].
  Iterable<State> get allStates {
    TestAsyncUtils.guardSync();
    return allElements.whereType<StatefulElement>().map<State>((StatefulElement element) => element.state);
  }

  /// The matching state in the widget tree.
  ///
  /// Throws a [StateError] if `finder` is empty, matches more than
  /// one state, or matches a widget that has no state.
  ///
  /// * Use [firstState] if you expect to match several states but only want the first.
  /// * Use [stateList] if you expect to match several states and want all of them.
  T state<T extends State>(Finder finder) {
    TestAsyncUtils.guardSync();
    return _stateOf<T>(finder.evaluate().single, finder);
  }

  /// The first matching state according to a depth-first pre-order
  /// traversal of the widget tree.
  ///
  /// Throws a [StateError] if `finder` is empty or if the first
  /// matching widget has no state.
  ///
  /// * Use [state] if you only expect to match one state.
  T firstState<T extends State>(Finder finder) {
    TestAsyncUtils.guardSync();
    return _stateOf<T>(finder.evaluate().first, finder);
  }

  /// The matching states in the widget tree.
  ///
  /// Throws a [StateError] if any of the elements in `finder` match a widget
  /// that has no state.
  ///
  /// * Use [state] if you only expect to match one state.
  /// * Use [firstState] if you expect to match several but only want the first.
  Iterable<T> stateList<T extends State>(Finder finder) {
    TestAsyncUtils.guardSync();
    return finder.evaluate().map<T>((Element element) => _stateOf<T>(element, finder));
  }

  T _stateOf<T extends State>(Element element, Finder finder) {
    TestAsyncUtils.guardSync();
    if (element is StatefulElement)
      return element.state as T;
    throw StateError('Widget of type ${element.widget.runtimeType}, with ${finder.description}, is not a StatefulWidget.');
  }

  /// Render objects of all the widgets currently in the widget tree
  /// (lazy pre-order traversal).
  ///
  /// This will almost certainly include many duplicates since the
  /// render object of a [StatelessWidget] or [StatefulWidget] is the
  /// render object of its child; only [RenderObjectWidget]s have
  /// their own render object.
  Iterable<RenderObject> get allRenderObjects {
    TestAsyncUtils.guardSync();
    return allElements.map<RenderObject>((Element element) => element.renderObject!);
  }

  /// The render object of the matching widget in the widget tree.
  ///
  /// Throws a [StateError] if `finder` is empty or matches more than
  /// one widget (even if they all have the same render object).
  ///
  /// * Use [firstRenderObject] if you expect to match several render objects but only want the first.
  /// * Use [renderObjectList] if you expect to match several render objects and want all of them.
  T renderObject<T extends RenderObject>(Finder finder) {
    TestAsyncUtils.guardSync();
    return finder.evaluate().single.renderObject! as T;
  }

  /// The render object of the first matching widget according to a
  /// depth-first pre-order traversal of the widget tree.
  ///
  /// Throws a [StateError] if `finder` is empty.
  ///
  /// * Use [renderObject] if you only expect to match one render object.
  T firstRenderObject<T extends RenderObject>(Finder finder) {
    TestAsyncUtils.guardSync();
    return finder.evaluate().first.renderObject! as T;
  }

  /// The render objects of the matching widgets in the widget tree.
  ///
  /// * Use [renderObject] if you only expect to match one render object.
  /// * Use [firstRenderObject] if you expect to match several but only want the first.
  Iterable<T> renderObjectList<T extends RenderObject>(Finder finder) {
    TestAsyncUtils.guardSync();
    return finder.evaluate().map<T>((Element element) {
      final T result = element.renderObject! as T;
      return result;
    });
  }

  /// Returns a list of all the [Layer] objects in the rendering.
  List<Layer> get layers => _walkLayers(binding.renderView.debugLayer!).toList();
  Iterable<Layer> _walkLayers(Layer layer) sync* {
    TestAsyncUtils.guardSync();
    yield layer;
    if (layer is ContainerLayer) {
      final ContainerLayer root = layer;
      Layer? child = root.firstChild;
      while (child != null) {
        yield* _walkLayers(child);
        child = child.nextSibling;
      }
    }
  }

  // INTERACTION

  /// Dispatch a pointer down / pointer up sequence at the center of
  /// the given widget, assuming it is exposed.
  ///
  /// {@template flutter.flutter_test.WidgetController.tap.warnIfMissed}
  /// The `warnIfMissed` argument, if true (the default), causes a warning to be
  /// displayed on the console if the specified [Finder] indicates a widget and
  /// location that, were a pointer event to be sent to that location, would not
  /// actually send any events to the widget (e.g. because the widget is
  /// obscured, or the location is off-screen, or the widget is transparent to
  /// pointer events).
  ///
  /// Set the argument to false to silence that warning if you intend to not
  /// actually hit the specified element.
  /// {@endtemplate}
  ///
  /// For example, a test that verifies that tapping a disabled button does not
  /// trigger the button would set `warnIfMissed` to false, because the button
  /// would ignore the tap.
  Future<void> tap(Finder finder, {int? pointer, int buttons = kPrimaryButton, bool warnIfMissed = true}) {
    return tapAt(getCenter(finder, warnIfMissed: warnIfMissed, callee: 'tap'), pointer: pointer, buttons: buttons);
  }

  /// Dispatch a pointer down / pointer up sequence at the given location.
  Future<void> tapAt(Offset location, {int? pointer, int buttons = kPrimaryButton}) {
    return TestAsyncUtils.guard<void>(() async {
      final TestGesture gesture = await startGesture(location, pointer: pointer, buttons: buttons);
      await gesture.up();
    });
  }

  /// Dispatch a pointer down at the center of the given widget, assuming it is
  /// exposed.
  ///
  /// {@macro flutter.flutter_test.WidgetController.tap.warnIfMissed}
  ///
  /// The return value is a [TestGesture] object that can be used to continue the
  /// gesture (e.g. moving the pointer or releasing it).
  ///
  /// See also:
  ///
  ///  * [tap], which presses and releases a pointer at the given location.
  ///  * [longPress], which presses and releases a pointer with a gap in
  ///    between long enough to trigger the long-press gesture.
  Future<TestGesture> press(Finder finder, {int? pointer, int buttons = kPrimaryButton, bool warnIfMissed = true}) {
    return TestAsyncUtils.guard<TestGesture>(() {
      return startGesture(getCenter(finder, warnIfMissed: warnIfMissed, callee: 'press'), pointer: pointer, buttons: buttons);
    });
  }

  /// Dispatch a pointer down / pointer up sequence (with a delay of
  /// [kLongPressTimeout] + [kPressTimeout] between the two events) at the
  /// center of the given widget, assuming it is exposed.
  ///
  /// {@macro flutter.flutter_test.WidgetController.tap.warnIfMissed}
  ///
  /// For example, consider a widget that, when long-pressed, shows an overlay
  /// that obscures the original widget. A test for that widget might first
  /// long-press that widget with `warnIfMissed` at its default value true, then
  /// later verify that long-pressing the same location (using the same finder)
  /// has no effect (since the widget is now obscured), setting `warnIfMissed`
  /// to false on that second call.
  Future<void> longPress(Finder finder, {int? pointer, int buttons = kPrimaryButton, bool warnIfMissed = true}) {
    return longPressAt(getCenter(finder, warnIfMissed: warnIfMissed, callee: 'longPress'), pointer: pointer, buttons: buttons);
  }

  /// Dispatch a pointer down / pointer up sequence at the given location with
  /// a delay of [kLongPressTimeout] + [kPressTimeout] between the two events.
  Future<void> longPressAt(Offset location, {int? pointer, int buttons = kPrimaryButton}) {
    return TestAsyncUtils.guard<void>(() async {
      final TestGesture gesture = await startGesture(location, pointer: pointer, buttons: buttons);
      await pump(kLongPressTimeout + kPressTimeout);
      await gesture.up();
    });
  }

  /// Attempts a fling gesture starting from the center of the given
  /// widget, moving the given distance, reaching the given speed.
  ///
  /// {@macro flutter.flutter_test.WidgetController.tap.warnIfMissed}
  ///
  /// {@template flutter.flutter_test.WidgetController.fling}
  /// This can pump frames.
  ///
  /// Exactly 50 pointer events are synthesized.
  ///
  /// The `speed` is in pixels per second in the direction given by `offset`.
  ///
  /// The `offset` and `speed` control the interval between each pointer event.
  /// For example, if the `offset` is 200 pixels down, and the `speed` is 800
  /// pixels per second, the pointer events will be sent for each increment
  /// of 4 pixels (200/50), over 250ms (200/800), meaning events will be sent
  /// every 1.25ms (250/200).
  ///
  /// To make tests more realistic, frames may be pumped during this time (using
  /// calls to [pump]). If the total duration is longer than `frameInterval`,
  /// then one frame is pumped each time that amount of time elapses while
  /// sending events, or each time an event is synthesized, whichever is rarer.
  ///
  /// See [LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive] if the method
  /// is used in a live environment and accurate time control is important.
  ///
  /// The `initialOffset` argument, if non-zero, causes the pointer to first
  /// apply that offset, then pump a delay of `initialOffsetDelay`. This can be
  /// used to simulate a drag followed by a fling, including dragging in the
  /// opposite direction of the fling (e.g. dragging 200 pixels to the right,
  /// then fling to the left over 200 pixels, ending at the exact point that the
  /// drag started).
  /// {@endtemplate}
  ///
  /// A fling is essentially a drag that ends at a particular speed. If you
  /// just want to drag and end without a fling, use [drag].
  Future<void> fling(
    Finder finder,
    Offset offset,
    double speed, {
    int? pointer,
    int buttons = kPrimaryButton,
    Duration frameInterval = const Duration(milliseconds: 16),
    Offset initialOffset = Offset.zero,
    Duration initialOffsetDelay = const Duration(seconds: 1),
    bool warnIfMissed = true,
  }) {
    return flingFrom(
      getCenter(finder, warnIfMissed: warnIfMissed, callee: 'fling'),
      offset,
      speed,
      pointer: pointer,
      buttons: buttons,
      frameInterval: frameInterval,
      initialOffset: initialOffset,
      initialOffsetDelay: initialOffsetDelay,
    );
  }

  /// Attempts a fling gesture starting from the given location, moving the
  /// given distance, reaching the given speed.
  ///
  /// {@macro flutter.flutter_test.WidgetController.fling}
  ///
  /// A fling is essentially a drag that ends at a particular speed. If you
  /// just want to drag and end without a fling, use [dragFrom].
  Future<void> flingFrom(
    Offset startLocation,
    Offset offset,
    double speed, {
    int? pointer,
    int buttons = kPrimaryButton,
    Duration frameInterval = const Duration(milliseconds: 16),
    Offset initialOffset = Offset.zero,
    Duration initialOffsetDelay = const Duration(seconds: 1),
  }) {
    assert(offset.distance > 0.0);
    assert(speed > 0.0); // speed is pixels/second
    return TestAsyncUtils.guard<void>(() async {
      final TestPointer testPointer = TestPointer(pointer ?? _getNextPointer(), PointerDeviceKind.touch, null, buttons);
      const int kMoveCount = 50; // Needs to be >= kHistorySize, see _LeastSquaresVelocityTrackerStrategy
      final double timeStampDelta = 1000000.0 * offset.distance / (kMoveCount * speed);
      double timeStamp = 0.0;
      double lastTimeStamp = timeStamp;
      await sendEventToBinding(testPointer.down(startLocation, timeStamp: Duration(microseconds: timeStamp.round())));
      if (initialOffset.distance > 0.0) {
        await sendEventToBinding(testPointer.move(startLocation + initialOffset, timeStamp: Duration(microseconds: timeStamp.round())));
        timeStamp += initialOffsetDelay.inMicroseconds;
        await pump(initialOffsetDelay);
      }
      for (int i = 0; i <= kMoveCount; i += 1) {
        final Offset location = startLocation + initialOffset + Offset.lerp(Offset.zero, offset, i / kMoveCount)!;
        await sendEventToBinding(testPointer.move(location, timeStamp: Duration(microseconds: timeStamp.round())));
        timeStamp += timeStampDelta;
        if (timeStamp - lastTimeStamp > frameInterval.inMicroseconds) {
          await pump(Duration(microseconds: (timeStamp - lastTimeStamp).truncate()));
          lastTimeStamp = timeStamp;
        }
      }
      await sendEventToBinding(testPointer.up(timeStamp: Duration(microseconds: timeStamp.round())));
    });
  }

  /// A simulator of how the framework handles a series of [PointerEvent]s
  /// received from the Flutter engine.
  ///
  /// The [PointerEventRecord.timeDelay] is used as the time delay of the events
  /// injection relative to the starting point of the method call.
  ///
  /// Returns a list of the difference between the real delay time when the
  /// [PointerEventRecord.events] are processed and
  /// [PointerEventRecord.timeDelay].
  /// - For [AutomatedTestWidgetsFlutterBinding] where the clock is fake, the
  ///   return value should be exact zeros.
  /// - For [LiveTestWidgetsFlutterBinding], the values are typically small
  /// positives, meaning the event happens a little later than the set time,
  /// but a very small portion may have a tiny negative value for about tens of
  /// microseconds. This is due to the nature of [Future.delayed].
  ///
  /// The closer the return values are to zero the more faithful it is to the
  /// `records`.
  ///
  /// See [PointerEventRecord].
  Future<List<Duration>> handlePointerEventRecord(List<PointerEventRecord> records);

  /// Called to indicate that there should be a new frame after an optional
  /// delay.
  ///
  /// The frame is pumped after a delay of [duration] if [duration] is not null,
  /// or immediately otherwise.
  ///
  /// This is invoked by [flingFrom], for instance, so that the sequence of
  /// pointer events occurs over time.
  ///
  /// The [WidgetTester] subclass implements this by deferring to the [binding].
  ///
  /// See also [SchedulerBinding.endOfFrame], which returns a future that could
  /// be appropriate to return in the implementation of this method.
  Future<void> pump([Duration duration]);

  /// Repeatedly calls [pump] with the given `duration` until there are no
  /// longer any frames scheduled. This will call [pump] at least once, even if
  /// no frames are scheduled when the function is called, to flush any pending
  /// microtasks which may themselves schedule a frame.
  ///
  /// This essentially waits for all animations to have completed.
  ///
  /// If it takes longer that the given `timeout` to settle, then the test will
  /// fail (this method will throw an exception). In particular, this means that
  /// if there is an infinite animation in progress (for example, if there is an
  /// indeterminate progress indicator spinning), this method will throw.
  ///
  /// The default timeout is ten minutes, which is longer than most reasonable
  /// finite animations would last.
  ///
  /// If the function returns, it returns the number of pumps that it performed.
  ///
  /// In general, it is better practice to figure out exactly why each frame is
  /// needed, and then to [pump] exactly as many frames as necessary. This will
  /// help catch regressions where, for instance, an animation is being started
  /// one frame later than it should.
  ///
  /// Alternatively, one can check that the return value from this function
  /// matches the expected number of pumps.
  Future<int> pumpAndSettle([
    Duration duration = const Duration(milliseconds: 100),
  ]);

  /// Attempts to drag the given widget by the given offset, by
  /// starting a drag in the middle of the widget.
  ///
  /// {@macro flutter.flutter_test.WidgetController.tap.warnIfMissed}
  ///
  /// If you want the drag to end with a speed so that the gesture recognition
  /// system identifies the gesture as a fling, consider using [fling] instead.
  ///
  /// The operation happens at once. If you want the drag to last for a period
  /// of time, consider using [timedDrag].
  ///
  /// {@template flutter.flutter_test.WidgetController.drag}
  /// By default, if the x or y component of offset is greater than
  /// [kDragSlopDefault], the gesture is broken up into two separate moves
  /// calls. Changing `touchSlopX` or `touchSlopY` will change the minimum
  /// amount of movement in the respective axis before the drag will be broken
  /// into multiple calls. To always send the drag with just a single call to
  /// [TestGesture.moveBy], `touchSlopX` and `touchSlopY` should be set to 0.
  ///
  /// Breaking the drag into multiple moves is necessary for accurate execution
  /// of drag update calls with a [DragStartBehavior] variable set to
  /// [DragStartBehavior.start]. Without such a change, the dragUpdate callback
  /// from a drag recognizer will never be invoked.
  ///
  /// To force this function to a send a single move event, the `touchSlopX` and
  /// `touchSlopY` variables should be set to 0. However, generally, these values
  /// should be left to their default values.
  /// {@endtemplate}
  Future<void> drag(
    Finder finder,
    Offset offset, {
    int? pointer,
    int buttons = kPrimaryButton,
    double touchSlopX = kDragSlopDefault,
    double touchSlopY = kDragSlopDefault,
    bool warnIfMissed = true,
  }) {
    return dragFrom(
      getCenter(finder, warnIfMissed: warnIfMissed, callee: 'drag'),
      offset,
      pointer: pointer,
      buttons: buttons,
      touchSlopX: touchSlopX,
      touchSlopY: touchSlopY,
    );
  }

  /// Attempts a drag gesture consisting of a pointer down, a move by
  /// the given offset, and a pointer up.
  ///
  /// If you want the drag to end with a speed so that the gesture recognition
  /// system identifies the gesture as a fling, consider using [flingFrom]
  /// instead.
  ///
  /// The operation happens at once. If you want the drag to last for a period
  /// of time, consider using [timedDragFrom].
  ///
  /// {@macro flutter.flutter_test.WidgetController.drag}
  Future<void> dragFrom(
    Offset startLocation,
    Offset offset, {
    int? pointer,
    int buttons = kPrimaryButton,
    double touchSlopX = kDragSlopDefault,
    double touchSlopY = kDragSlopDefault,
  }) {
    assert(kDragSlopDefault > kTouchSlop);
    return TestAsyncUtils.guard<void>(() async {
      final TestGesture gesture = await startGesture(startLocation, pointer: pointer, buttons: buttons);
      assert(gesture != null);

      final double xSign = offset.dx.sign;
      final double ySign = offset.dy.sign;

      final double offsetX = offset.dx;
      final double offsetY = offset.dy;

      final bool separateX = offset.dx.abs() > touchSlopX && touchSlopX > 0;
      final bool separateY = offset.dy.abs() > touchSlopY && touchSlopY > 0;

      if (separateY || separateX) {
        final double offsetSlope = offsetY / offsetX;
        final double inverseOffsetSlope = offsetX / offsetY;
        final double slopSlope = touchSlopY / touchSlopX;
        final double absoluteOffsetSlope = offsetSlope.abs();
        final double signedSlopX = touchSlopX * xSign;
        final double signedSlopY = touchSlopY * ySign;
        if (absoluteOffsetSlope != slopSlope) {
          // The drag goes through one or both of the extents of the edges of the box.
          if (absoluteOffsetSlope < slopSlope) {
            assert(offsetX.abs() > touchSlopX);
            // The drag goes through the vertical edge of the box.
            // It is guaranteed that the |offsetX| > touchSlopX.
            final double diffY = offsetSlope.abs() * touchSlopX * ySign;

            // The vector from the origin to the vertical edge.
            await gesture.moveBy(Offset(signedSlopX, diffY));
            if (offsetY.abs() <= touchSlopY) {
              // The drag ends on or before getting to the horizontal extension of the horizontal edge.
              await gesture.moveBy(Offset(offsetX - signedSlopX, offsetY - diffY));
            } else {
              final double diffY2 = signedSlopY - diffY;
              final double diffX2 = inverseOffsetSlope * diffY2;

              // The vector from the edge of the box to the horizontal extension of the horizontal edge.
              await gesture.moveBy(Offset(diffX2, diffY2));
              await gesture.moveBy(Offset(offsetX - diffX2 - signedSlopX, offsetY - signedSlopY));
            }
          } else {
            assert(offsetY.abs() > touchSlopY);
            // The drag goes through the horizontal edge of the box.
            // It is guaranteed that the |offsetY| > touchSlopY.
            final double diffX = inverseOffsetSlope.abs() * touchSlopY * xSign;

            // The vector from the origin to the vertical edge.
            await gesture.moveBy(Offset(diffX, signedSlopY));
            if (offsetX.abs() <= touchSlopX) {
              // The drag ends on or before getting to the vertical extension of the vertical edge.
              await gesture.moveBy(Offset(offsetX - diffX, offsetY - signedSlopY));
            } else {
              final double diffX2 = signedSlopX - diffX;
              final double diffY2 = offsetSlope * diffX2;

              // The vector from the edge of the box to the vertical extension of the vertical edge.
              await gesture.moveBy(Offset(diffX2, diffY2));
              await gesture.moveBy(Offset(offsetX - signedSlopX, offsetY - diffY2 - signedSlopY));
            }
          }
        } else { // The drag goes through the corner of the box.
          await gesture.moveBy(Offset(signedSlopX, signedSlopY));
          await gesture.moveBy(Offset(offsetX - signedSlopX, offsetY - signedSlopY));
        }
      } else { // The drag ends inside the box.
        await gesture.moveBy(offset);
      }
      await gesture.up();
    });
  }

  /// Attempts to drag the given widget by the given offset in the `duration`
  /// time, starting in the middle of the widget.
  ///
  /// {@macro flutter.flutter_test.WidgetController.tap.warnIfMissed}
  ///
  /// This is the timed version of [drag]. This may or may not result in a
  /// [fling] or ballistic animation, depending on the speed from
  /// `offset/duration`.
  ///
  /// {@template flutter.flutter_test.WidgetController.timedDrag}
  /// The move events are sent at a given `frequency` in Hz (or events per
  /// second). It defaults to 60Hz.
  ///
  /// The movement is linear in time.
  ///
  /// See also [LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive] for
  /// more accurate time control.
  /// {@endtemplate}
  Future<void> timedDrag(
    Finder finder,
    Offset offset,
    Duration duration, {
    int? pointer,
    int buttons = kPrimaryButton,
    double frequency = 60.0,
    bool warnIfMissed = true,
  }) {
    return timedDragFrom(
      getCenter(finder, warnIfMissed: warnIfMissed, callee: 'timedDrag'),
      offset,
      duration,
      pointer: pointer,
      buttons: buttons,
      frequency: frequency,
    );
  }

  /// Attempts a series of [PointerEvent]s to simulate a drag operation in the
  /// `duration` time.
  ///
  /// This is the timed version of [dragFrom]. This may or may not result in a
  /// [flingFrom] or ballistic animation, depending on the speed from
  /// `offset/duration`.
  ///
  /// {@macro flutter.flutter_test.WidgetController.timedDrag}
  Future<void> timedDragFrom(
    Offset startLocation,
    Offset offset,
    Duration duration, {
    int? pointer,
    int buttons = kPrimaryButton,
    double frequency = 60.0,
  }) {
    assert(frequency > 0);
    final int intervals = duration.inMicroseconds * frequency ~/ 1E6;
    assert(intervals > 1);
    pointer ??= _getNextPointer();
    final List<Duration> timeStamps = <Duration>[
      for (int t = 0; t <= intervals; t += 1)
        duration * t ~/ intervals,
    ];
    final List<Offset> offsets = <Offset>[
      startLocation,
      for (int t = 0; t <= intervals; t += 1)
        startLocation + offset * (t / intervals),
    ];
    final List<PointerEventRecord> records = <PointerEventRecord>[
      PointerEventRecord(Duration.zero, <PointerEvent>[
          PointerAddedEvent(
            timeStamp: Duration.zero,
            position: startLocation,
          ),
          PointerDownEvent(
            timeStamp: Duration.zero,
            position: startLocation,
            pointer: pointer,
            buttons: buttons,
          ),
        ]),
      ...<PointerEventRecord>[
        for(int t = 0; t <= intervals; t += 1)
          PointerEventRecord(timeStamps[t], <PointerEvent>[
            PointerMoveEvent(
              timeStamp: timeStamps[t],
              position: offsets[t+1],
              delta: offsets[t+1] - offsets[t],
              pointer: pointer,
              buttons: buttons,
            )
          ]),
      ],
      PointerEventRecord(duration, <PointerEvent>[
        PointerUpEvent(
          timeStamp: duration,
          position: offsets.last,
          pointer: pointer,
          // The PointerData received from the engine with
          // change = PointerChange.up, which translates to PointerUpEvent,
          // doesn't provide the button field.
          // buttons: buttons,
        )
      ]),
    ];
    return TestAsyncUtils.guard<void>(() async {
      await handlePointerEventRecord(records);
    });
  }

  /// The next available pointer identifier.
  ///
  /// This is the default pointer identifier that will be used the next time the
  /// [startGesture] method is called without an explicit pointer identifier.
  int get nextPointer => _nextPointer;

  static int _nextPointer = 1;

  static int _getNextPointer() {
    final int result = _nextPointer;
    _nextPointer += 1;
    return result;
  }

  /// Creates gesture and returns the [TestGesture] object which you can use
  /// to continue the gesture using calls on the [TestGesture] object.
  ///
  /// You can use [startGesture] instead if your gesture begins with a down
  /// event.
  Future<TestGesture> createGesture({
    int? pointer,
    PointerDeviceKind kind = PointerDeviceKind.touch,
    int buttons = kPrimaryButton,
  }) async {
    return TestGesture(
      dispatcher: sendEventToBinding,
      kind: kind,
      pointer: pointer ?? _getNextPointer(),
      buttons: buttons,
    );
  }

  /// Creates a gesture with an initial down gesture at a particular point, and
  /// returns the [TestGesture] object which you can use to continue the
  /// gesture.
  ///
  /// You can use [createGesture] if your gesture doesn't begin with an initial
  /// down gesture.
  Future<TestGesture> startGesture(
    Offset downLocation, {
    int? pointer,
    PointerDeviceKind kind = PointerDeviceKind.touch,
    int buttons = kPrimaryButton,
  }) async {
    assert(downLocation != null);
    final TestGesture result = await createGesture(
      pointer: pointer,
      kind: kind,
      buttons: buttons,
    );
    await result.down(downLocation);
    return result;
  }

  /// Forwards the given location to the binding's hitTest logic.
  HitTestResult hitTestOnBinding(Offset location) {
    final HitTestResult result = HitTestResult();
    binding.hitTest(result, location);
    return result;
  }

  /// Forwards the given pointer event to the binding.
  Future<void> sendEventToBinding(PointerEvent event) {
    return TestAsyncUtils.guard<void>(() async {
      binding.handlePointerEvent(event);
    });
  }

  /// Calls [debugPrint] with the given message.
  ///
  /// This is overridden by the WidgetTester subclass to use the test binding's
  /// [TestWidgetsFlutterBinding.debugPrintOverride], so that it appears on the
  /// console even if the test is logging output from the application.
  @protected
  void printToConsole(String message) {
    debugPrint(message);
  }

  // GEOMETRY

  /// Returns the point at the center of the given widget.
  ///
  /// {@template flutter.flutter_test.WidgetController.getCenter.warnIfMissed}
  /// If `warnIfMissed` is true (the default is false), then the returned
  /// coordinate is checked to see if a hit test at the returned location would
  /// actually include the specified element in the [HitTestResult], and if not,
  /// a warning is printed to the console.
  ///
  /// The `callee` argument is used to identify the method that should be
  /// referenced in messages regarding `warnIfMissed`. It can be ignored unless
  /// this method is being called from another that is forwarding its own
  /// `warnIfMissed` parameter (see e.g. the implementation of [tap]).
  /// {@endtemplate}
  Offset getCenter(Finder finder, { bool warnIfMissed = false, String callee = 'getCenter' }) {
    return _getElementPoint(finder, (Size size) => size.center(Offset.zero), warnIfMissed: warnIfMissed, callee: callee);
  }

  /// Returns the point at the top left of the given widget.
  ///
  /// {@macro flutter.flutter_test.WidgetController.getCenter.warnIfMissed}
  Offset getTopLeft(Finder finder, { bool warnIfMissed = false, String callee = 'getTopLeft' }) {
    return _getElementPoint(finder, (Size size) => Offset.zero, warnIfMissed: warnIfMissed, callee: callee);
  }

  /// Returns the point at the top right of the given widget. This
  /// point is not inside the object's hit test area.
  ///
  /// {@macro flutter.flutter_test.WidgetController.getCenter.warnIfMissed}
  Offset getTopRight(Finder finder, { bool warnIfMissed = false, String callee = 'getTopRight' }) {
    return _getElementPoint(finder, (Size size) => size.topRight(Offset.zero), warnIfMissed: warnIfMissed, callee: callee);
  }

  /// Returns the point at the bottom left of the given widget. This
  /// point is not inside the object's hit test area.
  ///
  /// {@macro flutter.flutter_test.WidgetController.getCenter.warnIfMissed}
  Offset getBottomLeft(Finder finder, { bool warnIfMissed = false, String callee = 'getBottomLeft' }) {
    return _getElementPoint(finder, (Size size) => size.bottomLeft(Offset.zero), warnIfMissed: warnIfMissed, callee: callee);
  }

  /// Returns the point at the bottom right of the given widget. This
  /// point is not inside the object's hit test area.
  ///
  /// {@macro flutter.flutter_test.WidgetController.getCenter.warnIfMissed}
  Offset getBottomRight(Finder finder, { bool warnIfMissed = false, String callee = 'getBottomRight' }) {
    return _getElementPoint(finder, (Size size) => size.bottomRight(Offset.zero), warnIfMissed: warnIfMissed, callee: callee);
  }

  /// Whether warnings relating to hit tests not hitting their mark should be
  /// fatal (cause the test to fail).
  ///
  /// Some methods, e.g. [tap], have an argument `warnIfMissed` which causes a
  /// warning to be displayed if the specified [Finder] indicates a widget and
  /// location that, were a pointer event to be sent to that location, would not
  /// actually send any events to the widget (e.g. because the widget is
  /// obscured, or the location is off-screen, or the widget is transparent to
  /// pointer events).
  ///
  /// This warning was added in 2021. In ordinary operation this warning is
  /// non-fatal since making it fatal would be a significantly breaking change
  /// for anyone who already has tests relying on the ability to target events
  /// using finders where the events wouldn't reach the widgets specified by the
  /// finders in question.
  ///
  /// However, doing this is usually unintentional. To make the warning fatal,
  /// thus failing any tests where it occurs, this property can be set to true.
  ///
  /// Typically this is done using a `flutter_test_config.dart` file, as described
  /// in the documentation for the [flutter_test] library.
  static bool hitTestWarningShouldBeFatal = false;

  Offset _getElementPoint(Finder finder, Offset Function(Size size) sizeToPoint, { required bool warnIfMissed, required String callee }) {
    TestAsyncUtils.guardSync();
    final Iterable<Element> elements = finder.evaluate();
    if (elements.isEmpty) {
      throw FlutterError('The finder "$finder" (used in a call to "$callee()") could not find any matching widgets.');
    }
    if (elements.length > 1) {
      throw FlutterError('The finder "$finder" (used in a call to "$callee()") ambiguously found multiple matching widgets. The "$callee()" method needs a single target.');
    }
    final Element element = elements.single;
    final RenderObject? renderObject = element.renderObject;
    if (renderObject == null) {
      throw FlutterError(
        'The finder "$finder" (used in a call to "$callee()") found an element, but it does not have a corresponding render object. '
        'Maybe the element has not yet been rendered?'
      );
    }
    if (renderObject is! RenderBox) {
      throw FlutterError(
        'The finder "$finder" (used in a call to "$callee()") found an element whose corresponding render object is not a RenderBox (it is a ${renderObject.runtimeType}: "$renderObject"). '
        'Unfortunately "$callee()" only supports targeting widgets that correspond to RenderBox objects in the rendering.'
      );
    }
    final RenderBox box = element.renderObject! as RenderBox;
    final Offset location = box.localToGlobal(sizeToPoint(box.size));
    if (warnIfMissed) {
      final HitTestResult result = HitTestResult();
      binding.hitTest(result, location);
      bool found = false;
      for (final HitTestEntry entry in result.path) {
        if (entry.target == box) {
          found = true;
          break;
        }
      }
      if (!found) {
        bool outOfBounds = false;
        if (binding.renderView != null && binding.renderView.size != null) {
          outOfBounds = !(Offset.zero & binding.renderView.size).contains(location);
        }
        if (hitTestWarningShouldBeFatal) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary('Finder specifies a widget that would not receive pointer events.'),
            ErrorDescription('A call to $callee() with finder "$finder" derived an Offset ($location) that would not hit test on the specified widget.'),
            ErrorHint('Maybe the widget is actually off-screen, or another widget is obscuring it, or the widget cannot receive pointer events.'),
            if (outOfBounds)
              ErrorHint('Indeed, $location is outside the bounds of the root of the render tree, ${binding.renderView.size}.'),
            box.toDiagnosticsNode(name: 'The finder corresponds to this RenderBox', style: DiagnosticsTreeStyle.singleLine),
            ErrorDescription('The hit test result at that offset is: $result'),
            ErrorDescription('If you expected this target not to be able to receive pointer events, pass "warnIfMissed: false" to "$callee()".'),
            ErrorDescription('To make this error into a non-fatal warning, set WidgetController.hitTestWarningShouldBeFatal to false.'),
          ]);
        }
        printToConsole(
          '\n'
          'Warning: A call to $callee() with finder "$finder" derived an Offset ($location) that would not hit test on the specified widget.\n'
          'Maybe the widget is actually off-screen, or another widget is obscuring it, or the widget cannot receive pointer events.\n'
          '${outOfBounds ? "Indeed, $location is outside the bounds of the root of the render tree, ${binding.renderView.size}.\n" : ""}'
          'The finder corresponds to this RenderBox: $box\n'
          'The hit test result at that offset is: $result\n'
          '${StackTrace.current}'
          'To silence this warning, pass "warnIfMissed: false" to "$callee()".\n'
          'To make this warning fatal, set WidgetController.hitTestWarningShouldBeFatal to true.\n'
          ''
        );
      }
    }
    return location;
  }

  /// Returns the size of the given widget. This is only valid once
  /// the widget's render object has been laid out at least once.
  Size getSize(Finder finder) {
    TestAsyncUtils.guardSync();
    final Element element = finder.evaluate().single;
    final RenderBox box = element.renderObject! as RenderBox;
    return box.size;
  }

  /// Simulates sending physical key down and up events through the system channel.
  ///
  /// This only simulates key events coming from a physical keyboard, not from a
  /// soft keyboard.
  ///
  /// Specify `platform` as one of the platforms allowed in
  /// [Platform.operatingSystem] to make the event appear to be from that type
  /// of system. Defaults to "android". Must not be null. Some platforms (e.g.
  /// Windows, iOS) are not yet supported.
  ///
  /// Keys that are down when the test completes are cleared after each test.
  ///
  /// This method sends both the key down and the key up events, to simulate a
  /// key press. To simulate individual down and/or up events, see
  /// [sendKeyDownEvent] and [sendKeyUpEvent].
  ///
  /// Returns true if the key down event was handled by the framework.
  ///
  /// See also:
  ///
  ///  - [sendKeyDownEvent] to simulate only a key down event.
  ///  - [sendKeyUpEvent] to simulate only a key up event.
  Future<bool> sendKeyEvent(LogicalKeyboardKey key, { String platform = 'android' }) async {
    assert(platform != null);
    final bool handled = await simulateKeyDownEvent(key, platform: platform);
    // Internally wrapped in async guard.
    await simulateKeyUpEvent(key, platform: platform);
    return handled;
  }

  /// Simulates sending a physical key down event through the system channel.
  ///
  /// This only simulates key down events coming from a physical keyboard, not
  /// from a soft keyboard.
  ///
  /// Specify `platform` as one of the platforms allowed in
  /// [Platform.operatingSystem] to make the event appear to be from that type
  /// of system. Defaults to "android". Must not be null. Some platforms (e.g.
  /// Windows, iOS) are not yet supported.
  ///
  /// Keys that are down when the test completes are cleared after each test.
  ///
  /// Returns true if the key event was handled by the framework.
  ///
  /// See also:
  ///
  ///  - [sendKeyUpEvent] to simulate the corresponding key up event.
  ///  - [sendKeyEvent] to simulate both the key up and key down in the same call.
  Future<bool> sendKeyDownEvent(LogicalKeyboardKey key, { String platform = 'android' }) async {
    assert(platform != null);
    // Internally wrapped in async guard.
    return simulateKeyDownEvent(key, platform: platform);
  }

  /// Simulates sending a physical key up event through the system channel.
  ///
  /// This only simulates key up events coming from a physical keyboard,
  /// not from a soft keyboard.
  ///
  /// Specify `platform` as one of the platforms allowed in
  /// [Platform.operatingSystem] to make the event appear to be from that type
  /// of system. Defaults to "android". May not be null.
  ///
  /// Returns true if the key event was handled by the framework.
  ///
  /// See also:
  ///
  ///  - [sendKeyDownEvent] to simulate the corresponding key down event.
  ///  - [sendKeyEvent] to simulate both the key up and key down in the same call.
  Future<bool> sendKeyUpEvent(LogicalKeyboardKey key, { String platform = 'android' }) async {
    assert(platform != null);
    // Internally wrapped in async guard.
    return simulateKeyUpEvent(key, platform: platform);
  }

  /// Returns the rect of the given widget. This is only valid once
  /// the widget's render object has been laid out at least once.
  Rect getRect(Finder finder) => getTopLeft(finder) & getSize(finder);

  /// Attempts to find the [SemanticsNode] of first result from `finder`.
  ///
  /// If the object identified by the finder doesn't own it's semantic node,
  /// this will return the semantics data of the first ancestor with semantics.
  /// The ancestor's semantic data will include the child's as well as
  /// other nodes that have been merged together.
  ///
  /// If the [SemanticsNode] of the object identified by the finder is
  /// force-merged into an ancestor (e.g. via the [MergeSemantics] widget)
  /// the node into which it is merged is returned. That node will include
  /// all the semantics information of the nodes merged into it.
  ///
  /// Will throw a [StateError] if the finder returns more than one element or
  /// if no semantics are found or are not enabled.
  SemanticsNode getSemantics(Finder finder) {
    if (binding.pipelineOwner.semanticsOwner == null)
      throw StateError('Semantics are not enabled.');
    final Iterable<Element> candidates = finder.evaluate();
    if (candidates.isEmpty) {
      throw StateError('Finder returned no matching elements.');
    }
    if (candidates.length > 1) {
      throw StateError('Finder returned more than one element.');
    }
    final Element element = candidates.single;
    RenderObject? renderObject = element.findRenderObject();
    SemanticsNode? result = renderObject?.debugSemantics;
    while (renderObject != null && (result == null || result.isMergedIntoParent)) {
      renderObject = renderObject.parent as RenderObject?;
      result = renderObject?.debugSemantics;
    }
    if (result == null)
      throw StateError('No Semantics data found.');
    return result;
  }

  /// Enable semantics in a test by creating a [SemanticsHandle].
  ///
  /// The handle must be disposed at the end of the test.
  SemanticsHandle ensureSemantics() {
    return binding.pipelineOwner.ensureSemantics();
  }

  /// Given a widget `W` specified by [finder] and a [Scrollable] widget `S` in
  /// its ancestry tree, this scrolls `S` so as to make `W` visible.
  ///
  /// Usually the `finder` for this method should be labeled
  /// `skipOffstage: false`, so that [Finder] deals with widgets that's out of
  /// the screen correctly.
  ///
  /// This does not work when the `S` is long and `W` far away from the
  /// displayed part does not have a cached element yet. See
  /// https://github.com/flutter/flutter/issues/61458
  ///
  /// Shorthand for `Scrollable.ensureVisible(element(finder))`
  Future<void> ensureVisible(Finder finder) => Scrollable.ensureVisible(element(finder));

  /// Repeatedly scrolls a [Scrollable] by `delta` in the
  /// [Scrollable.axisDirection] until `finder` is visible.
  ///
  /// Between each scroll, wait for `duration` time for settling.
  ///
  /// If `scrollable` is `null`, this will find a [Scrollable].
  ///
  /// Throws a [StateError] if `finder` is not found for maximum `maxScrolls`
  /// times.
  ///
  /// This is different from [ensureVisible] in that this allows looking for
  /// `finder` that is not built yet, but the caller must specify the scrollable
  /// that will build child specified by `finder` when there are multiple
  ///[Scrollable]s.
  ///
  /// Scroll is performed until the start of the `finder` is visible. This is
  /// due to the default parameter values of [Scrollable.ensureVisible] method.
  ///
  /// See also [dragUntilVisible].
  Future<void> scrollUntilVisible(
    Finder finder,
    double delta, {
      Finder? scrollable,
      int maxScrolls = 50,
      Duration duration = const Duration(milliseconds: 50),
    }
  ) {
    assert(maxScrolls > 0);
    scrollable ??= find.byType(Scrollable);
    return TestAsyncUtils.guard<void>(() async {
      Offset moveStep;
      switch (widget<Scrollable>(scrollable!).axisDirection) {
        case AxisDirection.up:
          moveStep = Offset(0, delta);
          break;
        case AxisDirection.down:
          moveStep = Offset(0, -delta);
          break;
        case AxisDirection.left:
          moveStep = Offset(delta, 0);
          break;
        case AxisDirection.right:
          moveStep = Offset(-delta, 0);
          break;
      }
      await dragUntilVisible(
        finder,
        scrollable,
        moveStep,
        maxIteration: maxScrolls,
        duration: duration);
    });
  }

  /// Repeatedly drags the `view` by `moveStep` until `finder` is visible.
  ///
  /// Between each operation, wait for `duration` time for settling.
  ///
  /// Throws a [StateError] if `finder` is not found for maximum `maxIteration`
  /// times.
  Future<void> dragUntilVisible(
    Finder finder,
    Finder view,
    Offset moveStep, {
      int maxIteration = 50,
      Duration duration = const Duration(milliseconds: 50),
  }) {
    return TestAsyncUtils.guard<void>(() async {
      while(maxIteration > 0 && finder.evaluate().isEmpty) {
        await drag(view, moveStep);
        await pump(duration);
        maxIteration-= 1;
      }
      await Scrollable.ensureVisible(element(finder));
    });
  }
}

/// Variant of [WidgetController] that can be used in tests running
/// on a device.
///
/// This is used, for instance, by [FlutterDriver].
class LiveWidgetController extends WidgetController {
  /// Creates a widget controller that uses the given binding.
  LiveWidgetController(WidgetsBinding binding) : super(binding);

  @override
  Future<void> pump([Duration? duration]) async {
    if (duration != null)
      await Future<void>.delayed(duration);
    binding.scheduleFrame();
    await binding.endOfFrame;
  }

  @override
  Future<int> pumpAndSettle([
    Duration duration = const Duration(milliseconds: 100),
  ]) {
    assert(duration != null);
    assert(duration > Duration.zero);
    return TestAsyncUtils.guard<int>(() async {
      int count = 0;
      do {
        await pump(duration);
        count += 1;
      } while (binding.hasScheduledFrame);
      return count;
    });
  }

  @override
  Future<List<Duration>> handlePointerEventRecord(List<PointerEventRecord> records) {
    assert(records != null);
    assert(records.isNotEmpty);
    return TestAsyncUtils.guard<List<Duration>>(() async {
      // hitTestHistory is an equivalence of _hitTests in [GestureBinding],
      // used as state for all pointers which are currently down.
      final Map<int, HitTestResult> hitTestHistory = <int, HitTestResult>{};
      final List<Duration> handleTimeStampDiff = <Duration>[];
      DateTime? startTime;
      for (final PointerEventRecord record in records) {
        final DateTime now = clock.now();
        startTime ??= now;
        // So that the first event is promised to receive a zero timeDiff
        final Duration timeDiff = record.timeDelay - now.difference(startTime);
        if (timeDiff.isNegative) {
          // This happens when something (e.g. GC) takes a long time during the
          // processing of the events.
          // Flush all past events
          handleTimeStampDiff.add(-timeDiff);
          record.events.forEach(binding.handlePointerEvent);
        } else {
          await Future<void>.delayed(timeDiff);
          handleTimeStampDiff.add(
            // Recalculating the time diff for getting exact time when the event
            // packet is sent. For a perfect Future.delayed like the one in a
            // fake async this new diff should be zero.
            clock.now().difference(startTime) - record.timeDelay,
          );
          record.events.forEach(binding.handlePointerEvent);
        }
      }
      // This makes sure that a gesture is completed, with no more pointers
      // active.
      assert(hitTestHistory.isEmpty);
      return handleTimeStampDiff;
    });
  }
}
