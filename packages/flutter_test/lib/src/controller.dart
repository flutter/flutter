// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'all_elements.dart';
import 'finders.dart';
import 'test_async_utils.dart';
import 'test_pointer.dart';

/// Class that programmatically interacts with widgets.
///
/// For a variant of this class suited specifically for unit tests, see [WidgetTester].
class WidgetController {
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
    return allElements
           .map((Element element) => element.widget);
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
    return finder.evaluate().single.widget;
  }

  /// The first matching widget according to a depth-first pre-order
  /// traversal of the widget tree.
  ///
  /// Throws a [StateError] if `finder` is empty.
  ///
  /// * Use [widget] if you only expect to match one widget.
  T firstWidget<T extends Widget>(Finder finder) {
    TestAsyncUtils.guardSync();
    return finder.evaluate().first.widget;
  }

  /// The matching widgets in the widget tree.
  ///
  /// * Use [widget] if you only expect to match one widget.
  /// * Use [firstWidget] if you expect to match several but only want the first.
  Iterable<T> widgetList<T extends Widget>(Finder finder) {
    TestAsyncUtils.guardSync();
    return finder.evaluate().map<T>((Element element) {
      final T result = element.widget;
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
    return collectAllElementsFrom(binding.renderViewElement, skipOffstage: false);
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
    return finder.evaluate().single;
  }

  /// The first matching element according to a depth-first pre-order
  /// traversal of the widget tree.
  ///
  /// Throws a [StateError] if `finder` is empty.
  ///
  /// * Use [element] if you only expect to match one element.
  T firstElement<T extends Element>(Finder finder) {
    TestAsyncUtils.guardSync();
    return finder.evaluate().first;
  }

  /// The matching elements in the widget tree.
  ///
  /// * Use [element] if you only expect to match one element.
  /// * Use [firstElement] if you expect to match several but only want the first.
  Iterable<T> elementList<T extends Element>(Finder finder) {
    TestAsyncUtils.guardSync();
    return finder.evaluate();
  }


  /// All states currently in the widget tree (lazy pre-order traversal).
  ///
  /// The returned iterable is lazy. It does not walk the entire widget tree
  /// immediately, but rather a chunk at a time as the iteration progresses
  /// using [Iterator.moveNext].
  Iterable<State> get allStates {
    TestAsyncUtils.guardSync();
    return allElements
           // TODO(vegorov) replace with Iterable.whereType, when it is available. https://github.com/dart-lang/sdk/issues/27827
           .where((Element element) => element is StatefulElement)
           .map((Element element) {
             final StatefulElement statefulElement = element;
             return statefulElement.state;
           });
  }

  /// The matching state in the widget tree.
  ///
  /// Throws a [StateError] if `finder` is empty, matches more than
  /// one state, or matches a widget that has no state.
  ///
  /// * Use [firstState] if you expect to match several states but only want the first.
  /// * Use [stateList] if you expect to match several states and want all of them.
  T state<T extends State<StatefulWidget>>(Finder finder) { // TODO(leafp): remove '<StatefulWidget>' when https://github.com/dart-lang/sdk/issues/28580 is fixed
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
  T firstState<T extends State<StatefulWidget>>(Finder finder) { // TODO(leafp): remove '<StatefulWidget>' when https://github.com/dart-lang/sdk/issues/28580 is fixed
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
  Iterable<T> stateList<T extends State<StatefulWidget>>(Finder finder) { // TODO(leafp): remove '<StatefulWidget>' when https://github.com/dart-lang/sdk/issues/28580 is fixed
    TestAsyncUtils.guardSync();
    return finder.evaluate().map((Element element) => _stateOf<T>(element, finder));
  }

  T _stateOf<T extends State<StatefulWidget>>(Element element, Finder finder) { // TODO(leafp): remove '<StatefulWidget>' when https://github.com/dart-lang/sdk/issues/28580 is fixed
    TestAsyncUtils.guardSync();
    if (element is StatefulElement)
      return element.state;
    throw new StateError('Widget of type ${element.widget.runtimeType}, with ${finder.description}, is not a StatefulWidget.');
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
    return allElements
           .map((Element element) => element.renderObject);
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
    return finder.evaluate().single.renderObject;
  }

  /// The render object of the first matching widget according to a
  /// depth-first pre-order traversal of the widget tree.
  ///
  /// Throws a [StateError] if `finder` is empty.
  ///
  /// * Use [renderObject] if you only expect to match one render object.
  T firstRenderObject<T extends RenderObject>(Finder finder) {
    TestAsyncUtils.guardSync();
    return finder.evaluate().first.renderObject;
  }

  /// The render objects of the matching widgets in the widget tree.
  ///
  /// * Use [renderObject] if you only expect to match one render object.
  /// * Use [firstRenderObject] if you expect to match several but only want the first.
  Iterable<T> renderObjectList<T extends RenderObject>(Finder finder) {
    TestAsyncUtils.guardSync();
    return finder.evaluate().map<T>((Element element) {
      final T result = element.renderObject;
      return result;
    });
  }


  /// Returns a list of all the [Layer] objects in the rendering.
  List<Layer> get layers => _walkLayers(binding.renderView.layer).toList();
  Iterable<Layer> _walkLayers(Layer layer) sync* {
    TestAsyncUtils.guardSync();
    yield layer;
    if (layer is ContainerLayer) {
      final ContainerLayer root = layer;
      Layer child = root.firstChild;
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
  /// If the center of the widget is not exposed, this might send events to
  /// another object.
  Future<Null> tap(Finder finder, { int pointer }) {
    return tapAt(getCenter(finder), pointer: pointer);
  }

  /// Dispatch a pointer down / pointer up sequence at the given location.
  Future<Null> tapAt(Offset location, { int pointer }) {
    return TestAsyncUtils.guard(() async {
      final TestGesture gesture = await startGesture(location, pointer: pointer);
      await gesture.up();
      return null;
    });
  }

  /// Dispatch a pointer down / pointer up sequence (with a delay of
  /// [kLongPressTimeout] + [kPressTimeout] between the two events) at the
  /// center of the given widget, assuming it is exposed.
  ///
  /// If the center of the widget is not exposed, this might send events to
  /// another object.
  Future<Null> longPress(Finder finder, { int pointer }) {
    return longPressAt(getCenter(finder), pointer: pointer);
  }

  /// Dispatch a pointer down / pointer up sequence at the given location with
  /// a delay of [kLongPressTimeout] + [kPressTimeout] between the two events.
  Future<Null> longPressAt(Offset location, { int pointer }) {
    return TestAsyncUtils.guard(() async {
      final TestGesture gesture = await startGesture(location, pointer: pointer);
      await pump(kLongPressTimeout + kPressTimeout);
      await gesture.up();
      return null;
    });
  }

  /// Attempts a fling gesture starting from the center of the given
  /// widget, moving the given distance, reaching the given speed.
  ///
  /// If the middle of the widget is not exposed, this might send
  /// events to another object.
  ///
  /// This can pump frames. See [flingFrom] for a discussion of how the
  /// `offset`, `velocity` and `frameInterval` arguments affect this.
  ///
  /// The `speed` is in pixels per second in the direction given by `offset`.
  ///
  /// A fling is essentially a drag that ends at a particular speed. If you
  /// just want to drag and end without a fling, use [drag].
  ///
  /// The `initialOffset` argument, if non-zero, causes the pointer to first
  /// apply that offset, then pump a delay of `initialOffsetDelay`. This can be
  /// used to simulate a drag followed by a fling, including dragging in the
  /// opposite direction of the fling (e.g. dragging 200 pixels to the right,
  /// then fling to the left over 200 pixels, ending at the exact point that the
  /// drag started).
  Future<Null> fling(Finder finder, Offset offset, double speed, {
    int pointer,
    Duration frameInterval: const Duration(milliseconds: 16),
    Offset initialOffset: Offset.zero,
    Duration initialOffsetDelay: const Duration(seconds: 1),
  }) {
    return flingFrom(
      getCenter(finder),
      offset,
      speed,
      pointer: pointer,
      frameInterval: frameInterval,
      initialOffset: initialOffset,
      initialOffsetDelay: initialOffsetDelay,
    );
  }

  /// Attempts a fling gesture starting from the given location, moving the
  /// given distance, reaching the given speed.
  ///
  /// Exactly 50 pointer events are synthesized.
  ///
  /// The offset and speed control the interval between each pointer event. For
  /// example, if the offset is 200 pixels down, and the speed is 800 pixels per
  /// second, the pointer events will be sent for each increment of 4 pixels
  /// (200/50), over 250ms (200/800), meaning events will be sent every 1.25ms
  /// (250/200).
  ///
  /// To make tests more realistic, frames may be pumped during this time (using
  /// calls to [pump]). If the total duration is longer than `frameInterval`,
  /// then one frame is pumped each time that amount of time elapses while
  /// sending events, or each time an event is synthesized, whichever is rarer.
  ///
  /// A fling is essentially a drag that ends at a particular speed. If you
  /// just want to drag and end without a fling, use [dragFrom].
  ///
  /// The `initialOffset` argument, if non-zero, causes the pointer to first
  /// apply that offset, then pump a delay of `initialOffsetDelay`. This can be
  /// used to simulate a drag followed by a fling, including dragging in the
  /// opposite direction of the fling (e.g. dragging 200 pixels to the right,
  /// then fling to the left over 200 pixels, ending at the exact point that the
  /// drag started).
  Future<Null> flingFrom(Offset startLocation, Offset offset, double speed, {
    int pointer,
    Duration frameInterval: const Duration(milliseconds: 16),
    Offset initialOffset: Offset.zero,
    Duration initialOffsetDelay: const Duration(seconds: 1),
  }) {
    assert(offset.distance > 0.0);
    assert(speed > 0.0); // speed is pixels/second
    return TestAsyncUtils.guard(() async {
      final TestPointer testPointer = new TestPointer(pointer ?? _getNextPointer());
      final HitTestResult result = hitTestOnBinding(startLocation);
      const int kMoveCount = 50; // Needs to be >= kHistorySize, see _LeastSquaresVelocityTrackerStrategy
      final double timeStampDelta = 1000.0 * offset.distance / (kMoveCount * speed);
      double timeStamp = 0.0;
      double lastTimeStamp = timeStamp;
      await sendEventToBinding(testPointer.down(startLocation, timeStamp: new Duration(milliseconds: timeStamp.round())), result);
      if (initialOffset.distance > 0.0) {
        await sendEventToBinding(testPointer.move(startLocation + initialOffset, timeStamp: new Duration(milliseconds: timeStamp.round())), result);
        timeStamp += initialOffsetDelay.inMilliseconds;
        await pump(initialOffsetDelay);
      }
      for (int i = 0; i <= kMoveCount; i += 1) {
        final Offset location = startLocation + initialOffset + Offset.lerp(Offset.zero, offset, i / kMoveCount);
        await sendEventToBinding(testPointer.move(location, timeStamp: new Duration(milliseconds: timeStamp.round())), result);
        timeStamp += timeStampDelta;
        if (timeStamp - lastTimeStamp > frameInterval.inMilliseconds) {
          await pump(new Duration(milliseconds: (timeStamp - lastTimeStamp).truncate()));
          lastTimeStamp = timeStamp;
        }
      }
      await sendEventToBinding(testPointer.up(timeStamp: new Duration(milliseconds: timeStamp.round())), result);
      return null;
    });
  }

  /// Called to indicate that time should advance.
  ///
  /// This is invoked by [flingFrom], for instance, so that the sequence of
  /// pointer events occurs over time.
  ///
  /// The default implementation does nothing.
  ///
  /// The [WidgetTester] subclass implements this by deferring to the [binding].
  Future<Null> pump(Duration duration) => new Future<Null>.value(null);

  /// Attempts to drag the given widget by the given offset, by
  /// starting a drag in the middle of the widget.
  ///
  /// If the middle of the widget is not exposed, this might send
  /// events to another object.
  ///
  /// If you want the drag to end with a speed so that the gesture recognition
  /// system identifies the gesture as a fling, consider using [fling] instead.
  Future<Null> drag(Finder finder, Offset offset, { int pointer }) {
    return dragFrom(getCenter(finder), offset, pointer: pointer);
  }

  /// Attempts a drag gesture consisting of a pointer down, a move by
  /// the given offset, and a pointer up.
  ///
  /// If you want the drag to end with a speed so that the gesture recognition
  /// system identifies the gesture as a fling, consider using [flingFrom]
  /// instead.
  Future<Null> dragFrom(Offset startLocation, Offset offset, { int pointer }) {
    return TestAsyncUtils.guard(() async {
      final TestGesture gesture = await startGesture(startLocation, pointer: pointer);
      assert(gesture != null);
      await gesture.moveBy(offset);
      await gesture.up();
      return null;
    });
  }

  /// The next available pointer identifier.
  ///
  /// This is the default pointer identifier that will be used the next time the
  /// [startGesture] method is called without an explicit pointer identifier.
  int nextPointer = 1;

  int _getNextPointer() {
    final int result = nextPointer;
    nextPointer += 1;
    return result;
  }

  /// Begins a gesture at a particular point, and returns the
  /// [TestGesture] object which you can use to continue the gesture.
  Future<TestGesture> startGesture(Offset downLocation, { int pointer }) {
    return TestGesture.down(
      downLocation,
      pointer: pointer ?? _getNextPointer(),
      hitTester: hitTestOnBinding,
      dispatcher: sendEventToBinding,
    );
  }

  /// Forwards the given location to the binding's hitTest logic.
  HitTestResult hitTestOnBinding(Offset location) {
    final HitTestResult result = new HitTestResult();
    binding.hitTest(result, location);
    return result;
  }

  /// Forwards the given pointer event to the binding.
  Future<Null> sendEventToBinding(PointerEvent event, HitTestResult result) {
    return TestAsyncUtils.guard(() async {
      binding.dispatchEvent(event, result);
      return null;
    });
  }


  // GEOMETRY

  /// Returns the point at the center of the given widget.
  Offset getCenter(Finder finder) {
    return _getElementPoint(finder, (Size size) => size.center(Offset.zero));
  }

  /// Returns the point at the top left of the given widget.
  Offset getTopLeft(Finder finder) {
    return _getElementPoint(finder, (Size size) => Offset.zero);
  }

  /// Returns the point at the top right of the given widget. This
  /// point is not inside the object's hit test area.
  Offset getTopRight(Finder finder) {
    return _getElementPoint(finder, (Size size) => size.topRight(Offset.zero));
  }

  /// Returns the point at the bottom left of the given widget. This
  /// point is not inside the object's hit test area.
  Offset getBottomLeft(Finder finder) {
    return _getElementPoint(finder, (Size size) => size.bottomLeft(Offset.zero));
  }

  /// Returns the point at the bottom right of the given widget. This
  /// point is not inside the object's hit test area.
  Offset getBottomRight(Finder finder) {
    return _getElementPoint(finder, (Size size) => size.bottomRight(Offset.zero));
  }

  Offset _getElementPoint(Finder finder, Offset sizeToPoint(Size size)) {
    TestAsyncUtils.guardSync();
    final Element element = finder.evaluate().single;
    final RenderBox box = element.renderObject;
    assert(box != null);
    return box.localToGlobal(sizeToPoint(box.size));
  }

  /// Returns the size of the given widget. This is only valid once
  /// the widget's render object has been laid out at least once.
  Size getSize(Finder finder) {
    TestAsyncUtils.guardSync();
    final Element element = finder.evaluate().single;
    final RenderBox box = element.renderObject;
    assert(box != null);
    return box.size;
  }

  /// Returns the rect of the given widget. This is only valid once
  /// the widget's render object has been laid out at least once.
  Rect getRect(Finder finder) => getTopLeft(finder) & getSize(finder);
}
