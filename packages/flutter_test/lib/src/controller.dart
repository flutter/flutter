// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'test_pointer.dart';
import 'finders.dart';
import 'all_elements.dart';

/// Class that programmatically interacts with widgets.
///
/// For a variant of this class suited specifically for unit tests, see [WidgetTester].
class WidgetController {
  WidgetController(this.binding);

  final WidgetsBinding binding;

  // FINDER API

  // TODO(ianh): verify that the return values are of type T and throw
  // a good message otherwise, in all the generic methods below

  /// Checks if `finder` exists in the tree.
  bool any(Finder finder) => finder.evaluate().isNotEmpty;

  /// All widgets currently in the widget tree (lazy pre-order traversal).
  ///
  /// Can contain duplicates, since widgets can be used in multiple
  /// places in the widget tree.
  Iterable<Widget> get allWidgets {
    return allElements
           .map((Element element) => element.widget);
  }

  /// The matching widget in the widget tree.
  ///
  /// Throws a [StateError] if `finder` is empty or matches more than
  /// one widget.
  Widget/*=T*/ widget/*<T extends Widget>*/(Finder finder) {
    return finder.evaluate().single.widget;
  }

  /// The first matching widget according to a depth-first pre-order
  /// traversal of the widget tree.
  ///
  /// Throws a [StateError] if `finder` is empty.
  Widget/*=T*/ firstWidget/*<T extends Widget>*/(Finder finder) {
    return finder.evaluate().first.widget;
  }

  /// All elements currently in the widget tree (lazy pre-order traversal).
  ///
  /// The returned iterable is lazy. It does not walk the entire widget tree
  /// immediately, but rather a chunk at a time as the iteration progresses
  /// using [Iterator.moveNext].
  Iterable<Element> get allElements {
    return collectAllElementsFrom(binding.renderViewElement);
  }

  /// The matching element in the widget tree.
  ///
  /// Throws a [StateError] if `finder` is empty or matches more than
  /// one element.
  Element/*=T*/ element/*<T extends Element>*/(Finder finder) {
    return finder.evaluate().single;
  }

  /// The first matching element according to a depth-first pre-order
  /// traversal of the widget tree.
  ///
  /// Throws a [StateError] if `finder` is empty.
  Element/*=T*/ firstElement/*<T extends Element>*/(Finder finder) {
    return finder.evaluate().first;
  }

  /// All states currently in the widget tree (lazy pre-order traversal).
  ///
  /// The returned iterable is lazy. It does not walk the entire widget tree
  /// immediately, but rather a chunk at a time as the iteration progresses
  /// using [Iterator.moveNext].
  Iterable<State> get allStates {
    return allElements
           .where((Element element) => element is StatefulElement)
           .map((StatefulElement element) => element.state);
  }

  /// The matching state in the widget tree.
  ///
  /// Throws a [StateError] if `finder` is empty, matches more than
  /// one state, or matches a widget that has no state.
  State/*=T*/ state/*<T extends State>*/(Finder finder) {
    return _stateOf/*<T>*/(finder.evaluate().single, finder);
  }

  /// The first matching state according to a depth-first pre-order
  /// traversal of the widget tree.
  ///
  /// Throws a [StateError] if `finder` is empty or if the first
  /// matching widget has no state.
  State/*=T*/ firstState/*<T extends State>*/(Finder finder) {
    return _stateOf/*<T>*/(finder.evaluate().first, finder);
  }

  State/*=T*/ _stateOf/*<T extends State>*/(Element element, Finder finder) {
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
    return allElements
           .map((Element element) => element.renderObject);
  }

  /// The render object of the matching widget in the widget tree.
  ///
  /// Throws a [StateError] if `finder` is empty or matches more than
  /// one widget (even if they all have the same render object).
  RenderObject/*=T*/ renderObject/*<T extends RenderObject>*/(Finder finder) {
    return finder.evaluate().single.renderObject;
  }

  /// The render object of the first matching widget according to a
  /// depth-first pre-order traversal of the widget tree.
  ///
  /// Throws a [StateError] if `finder` is empty.
  RenderObject/*=T*/ firstRenderObject/*<T extends RenderObject>*/(Finder finder) {
    return finder.evaluate().first.renderObject;
  }


  /// Returns a list of all the [Layer] objects in the rendering.
  List<Layer> get layers => _walkLayers(binding.renderView.layer).toList();
  Iterable<Layer> _walkLayers(Layer layer) sync* {
    yield layer;
    if (layer is ContainerLayer) {
      ContainerLayer root = layer;
      Layer child = root.firstChild;
      while (child != null) {
        yield* _walkLayers(child);
        child = child.nextSibling;
      }
    }
  }


  // INTERACTION

  /// Dispatch a pointer down / pointer up sequence at the center of
  /// the given widget, assuming it is exposed. If the center of the
  /// widget is not exposed, this might send events to another
  /// object.
  void tap(Finder finder, { int pointer: 1 }) {
    tapAt(getCenter(finder), pointer: pointer);
  }

  /// Dispatch a pointer down / pointer up sequence at the given
  /// location.
  void tapAt(Point location, { int pointer: 1 }) {
    startGesture(location, pointer: pointer)
      ..up();
  }

  /// Attempts a fling gesture starting from the center of the given
  /// widget, moving the given distance, reaching the given velocity.
  ///
  /// If the middle of the widget is not exposed, this might send
  /// events to another object.
  void fling(Finder finder, Offset offset, double velocity, { int pointer: 1 }) {
    flingFrom(getCenter(finder), offset, velocity, pointer: pointer);
  }

  /// Attempts a fling gesture starting from the given location,
  /// moving the given distance, reaching the given velocity.
  void flingFrom(Point startLocation, Offset offset, double velocity, { int pointer: 1 }) {
    assert(offset.distance > 0.0);
    assert(velocity != 0.0);   // velocity is pixels/second
    final TestPointer p = new TestPointer(pointer);
    final HitTestResult result = _hitTest(startLocation);
    const int kMoveCount = 50; // Needs to be >= kHistorySize, see _LeastSquaresVelocityTrackerStrategy
    final double timeStampDelta = 1000.0 * offset.distance / (kMoveCount * velocity);
    double timeStamp = 0.0;
    binding.dispatchEvent(p.down(startLocation, timeStamp: new Duration(milliseconds: timeStamp.round())), result);
    for (int i = 0; i <= kMoveCount; i++) {
      final Point location = startLocation + Offset.lerp(Offset.zero, offset, i / kMoveCount);
      binding.dispatchEvent(p.move(location, timeStamp: new Duration(milliseconds: timeStamp.round())), result);
      timeStamp += timeStampDelta;
    }
    binding.dispatchEvent(p.up(timeStamp: new Duration(milliseconds: timeStamp.round())), result);
  }

  /// Attempts to drag the given widget by the given offset, by
  /// starting a drag in the middle of the widget.
  ///
  /// If the middle of the widget is not exposed, this might send
  /// events to another object.
  void scroll(Finder finder, Offset offset, { int pointer: 1 }) {
    scrollAt(getCenter(finder), offset, pointer: pointer);
  }

  /// Attempts a drag gesture consisting of a pointer down, a move by
  /// the given offset, and a pointer up.
  void scrollAt(Point startLocation, Offset offset, { int pointer: 1 }) {
    startGesture(startLocation, pointer: pointer)
      ..moveBy(offset)
      ..up();
  }

  /// Begins a gesture at a particular point, and returns the
  /// [TestGesture] object which you can use to continue the gesture.
  TestGesture startGesture(Point downLocation, { int pointer: 1 }) {
    return new TestGesture(downLocation, pointer: pointer);
  }

  HitTestResult _hitTest(Point location) {
    final HitTestResult result = new HitTestResult();
    binding.hitTest(result, location);
    return result;
  }


  // GEOMETRY

  /// Returns the point at the center of the given widget.
  Point getCenter(Finder finder) {
    return _getElementPoint(finder, (Size size) => size.center(Point.origin));
  }

  /// Returns the point at the top left of the given widget.
  Point getTopLeft(Finder finder) {
    return _getElementPoint(finder, (Size size) => Point.origin);
  }

  /// Returns the point at the top right of the given widget. This
  /// point is not inside the object's hit test area.
  Point getTopRight(Finder finder) {
    return _getElementPoint(finder, (Size size) => size.topRight(Point.origin));
  }

  /// Returns the point at the bottom left of the given widget. This
  /// point is not inside the object's hit test area.
  Point getBottomLeft(Finder finder) {
    return _getElementPoint(finder, (Size size) => size.bottomLeft(Point.origin));
  }

  /// Returns the point at the bottom right of the given widget. This
  /// point is not inside the object's hit test area.
  Point getBottomRight(Finder finder) {
    return _getElementPoint(finder, (Size size) => size.bottomRight(Point.origin));
  }

  Point _getElementPoint(Finder finder, Point sizeToPoint(Size size)) {
    Element element = finder.evaluate().single;
    RenderBox box = element.renderObject;
    assert(box != null);
    return box.localToGlobal(sizeToPoint(box.size));
  }

  /// Returns the size of the given widget. This is only valid once
  /// the widget's render object has been laid out at least once.
  Size getSize(Finder finder) {
    Element element = finder.evaluate().single;
    RenderBox box = element.renderObject;
    assert(box != null);
    return box.size;
  }
}
