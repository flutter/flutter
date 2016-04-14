// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'test_pointer.dart';

typedef Point SizeToPointFunction(Size size);

/// Helper class for flutter tests providing event dispatch.
///
/// This class provides hooks for accessing the rendering tree and dispatching
/// fake tap/drag/etc. events.
class Instrumentation {
  Instrumentation({ WidgetFlutterBinding binding })
    : this.binding = binding ?? WidgetFlutterBinding.ensureInitialized();

  final WidgetFlutterBinding binding;

  /// Returns a list of all the [Layer] objects in the rendering.
  List<Layer> get layers => _layers(binding.renderView.layer);
  // TODO(ianh): This should not be O(N) hidden behind a getter!
  List<Layer> _layers(Layer layer) {
    List<Layer> result = <Layer>[layer];
    if (layer is ContainerLayer) {
      ContainerLayer root = layer;
      Layer child = root.firstChild;
      while (child != null) {
        result.addAll(_layers(child));
        child = child.nextSibling;
      }
    }
    return result;
  }

  /// Walks all the elements in the tree, in depth-first pre-order,
  /// calling the given function for each one.
  void walkElements(ElementVisitor visitor) {
    void walk(Element element) {
      visitor(element);
      element.visitChildren(walk);
    }
    binding.renderViewElement.visitChildren(walk);
  }

  /// Returns the first element that for which the given predicate
  /// function returns true, if any, or null if the predicate function
  /// never returns true.
  Element findElement(bool predicate(Element element)) {
    try {
      walkElements((Element element) {
        if (predicate(element))
          throw element;
      });
    } on Element catch (e) {
      return e;
    }
    return null;
  }

  /// Returns all elements ordered in a depth-first traversal fashion.
  ///
  /// The returned iterable is lazy. It does not walk the entire element tree
  /// immediately, but rather a chunk at a time as the iteration progresses
  /// using [Iterator.moveNext].
  Iterable<Element> get allElements {
    return new _DepthFirstChildIterable(binding.renderViewElement);
  }

  /// Returns all elements that satisfy [predicate].
  Iterable<Element> findElements(bool predicate(Element element)) {
    return allElements.where(predicate);
  }

  /// Returns the first element that corresponds to a widget with the
  /// given [Key], or null if there is no such element.
  Element findElementByKey(Key key) {
    return findElement((Element element) => element.widget.key == key);
  }

  /// Returns the first element that corresponds to a [Text] widget
  /// whose data is the given string, or null if there is no such
  /// element.
  Element findText(String text) {
    return findElement((Element element) {
      if (element.widget is! Text)
        return false;
      Text textWidget = element.widget;
      return textWidget.data == text;
    });
  }

  /// Returns the first [Widget] of the given [runtimeType], if any. Returns
  /// null if there is no matching widget.
  Widget findWidgetOfType(Type type) {
    Element element = findElement((Element element) {
      return element.widget.runtimeType == type;
    });
    return element?.widget;
  }

  /// Returns the [State] object of the first element whose state has
  /// the given [runtimeType], if any. Returns null if there is no
  /// matching element.
  State findStateOfType(Type type) {
    StatefulElement element = findElement((Element element) {
      return element is StatefulElement && element.state.runtimeType == type;
    });
    return element?.state;
  }

  /// Returns the [State] object of the first element whose
  /// configuration is the given widget, if any. Returns null if the
  /// given configuration is not that of a stateful widget or if there
  /// is no matching element.
  State findStateByConfig(Widget config) {
    StatefulElement element = findElement((Element element) {
      return element is StatefulElement && element.state.config == config;
    });
    return element?.state;
  }

  /// Returns the point at the center of the given element.
  Point getCenter(Element element) {
    return _getElementPoint(element, (Size size) => size.center(Point.origin));
  }

  /// Returns the point at the top left of the given element.
  Point getTopLeft(Element element) {
    return _getElementPoint(element, (_) => Point.origin);
  }

  /// Returns the point at the top right of the given element. This
  /// point is not inside the object's hit test area.
  Point getTopRight(Element element) {
    return _getElementPoint(element, (Size size) => size.topRight(Point.origin));
  }

  /// Returns the point at the bottom left of the given element. This
  /// point is not inside the object's hit test area.
  Point getBottomLeft(Element element) {
    return _getElementPoint(element, (Size size) => size.bottomLeft(Point.origin));
  }

  /// Returns the point at the bottom right of the given element. This
  /// point is not inside the object's hit test area.
  Point getBottomRight(Element element) {
    return _getElementPoint(element, (Size size) => size.bottomRight(Point.origin));
  }

  /// Returns the size of the given element. This is only valid once
  /// the element's render object has been laid out at least once.
  Size getSize(Element element) {
    assert(element != null);
    RenderBox box = element.renderObject;
    assert(box != null);
    return box.size;
  }

  Point _getElementPoint(Element element, SizeToPointFunction sizeToPoint) {
    assert(element != null);
    RenderBox box = element.renderObject;
    assert(box != null);
    return box.localToGlobal(sizeToPoint(box.size));
  }

  /// Dispatch a pointer down / pointer up sequence at the center of
  /// the given element, assuming it is exposed. If the center of the
  /// element is not exposed, this might send events to another
  /// object.
  void tap(Element element, { int pointer: 1 }) {
    tapAt(getCenter(element), pointer: pointer);
  }

  /// Dispatch a pointer down / pointer up sequence at the given
  /// location.
  void tapAt(Point location, { int pointer: 1 }) {
    HitTestResult result = _hitTest(location);
    TestPointer p = new TestPointer(pointer);
    dispatchEvent(p.down(location), result);
    dispatchEvent(p.up(), result);
  }

  /// Attempts a fling gesture starting from the center of the given
  /// element, moving the given distance, reaching the given velocity.
  ///
  /// If the middle of the element is not exposed, this might send
  /// events to another object.
  void fling(Element element, Offset offset, double velocity, { int pointer: 1 }) {
    flingFrom(getCenter(element), offset, velocity, pointer: pointer);
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
    dispatchEvent(p.down(startLocation, timeStamp: new Duration(milliseconds: timeStamp.round())), result);
    for(int i = 0; i <= kMoveCount; i++) {
      final Point location = startLocation + Offset.lerp(Offset.zero, offset, i / kMoveCount);
      dispatchEvent(p.move(location, timeStamp: new Duration(milliseconds: timeStamp.round())), result);
      timeStamp += timeStampDelta;
    }
    dispatchEvent(p.up(timeStamp: new Duration(milliseconds: timeStamp.round())), result);
  }

  /// Attempts to drag the given element by the given offset, by
  /// starting a drag in the middle of the element.
  ///
  /// If the middle of the element is not exposed, this might send
  /// events to another object.
  void scroll(Element element, Offset offset, { int pointer: 1 }) {
    scrollAt(getCenter(element), offset, pointer: pointer);
  }

  /// Attempts a drag gesture consisting of a pointer down, a move by
  /// the given offset, and a pointer up.
  void scrollAt(Point startLocation, Offset offset, { int pointer: 1 }) {
    Point endLocation = startLocation + offset;
    TestPointer p = new TestPointer(pointer);
    // Events for the entire press-drag-release gesture are dispatched
    // to the widgets "hit" by the pointer down event.
    HitTestResult result = _hitTest(startLocation);
    dispatchEvent(p.down(startLocation), result);
    dispatchEvent(p.move(endLocation), result);
    dispatchEvent(p.up(), result);
  }

  /// Begins a gesture at a particular point, and returns the
  /// [TestGesture] object which you can use to continue the gesture.
  TestGesture startGesture(Point downLocation, { int pointer: 1 }) {
    TestPointer p = new TestPointer(pointer);
    HitTestResult result = _hitTest(downLocation);
    dispatchEvent(p.down(downLocation), result);
    return new TestGesture._(this, result, p);
  }

  HitTestResult _hitTest(Point location) {
    HitTestResult result = new HitTestResult();
    binding.hitTest(result, location);
    return result;
  }

  /// Sends a [PointerEvent] at a particular [HitTestResult].
  ///
  /// Generally speaking, it is preferred to use one of the more
  /// semantically meaningful ways to dispatch events in tests, in
  /// particular: [tap], [tapAt], [fling], [flingFrom], [scroll],
  /// [scrollAt], or [startGesture].
  void dispatchEvent(PointerEvent event, HitTestResult result) {
    binding.dispatchEvent(event, result);
  }
}

/// A class for performing gestures in tests. To create a
/// [TestGesture], call [WidgetTester.startGesture].
class TestGesture {
  TestGesture._(this._target, this._result, this.pointer);

  final Instrumentation _target;
  final HitTestResult _result;
  final TestPointer pointer;
  bool _isDown = true;

  /// Send a move event moving the pointer to the given location.
  void moveTo(Point location) {
    assert(_isDown);
    _target.dispatchEvent(pointer.move(location), _result);
  }

  /// Send a move event moving the pointer by the given offset.
  void moveBy(Offset offset) {
    assert(_isDown);
    moveTo(pointer.location + offset);
  }

  /// End the gesture by releasing the pointer.
  void up() {
    assert(_isDown);
    _isDown = false;
    _target.dispatchEvent(pointer.up(), _result);
  }

  /// End the gesture by canceling the pointer (as would happen if the
  /// system showed a modal dialog on top of the Flutter application,
  /// for instance).
  void cancel() {
    assert(_isDown);
    _isDown = false;
    _target.dispatchEvent(pointer.cancel(), _result);
  }
}

class _DepthFirstChildIterable extends IterableBase<Element> {
  _DepthFirstChildIterable(this.rootElement);

  Element rootElement;

  @override
  Iterator<Element> get iterator => new _DepthFirstChildIterator(rootElement);
}

class _DepthFirstChildIterator implements Iterator<Element> {
  _DepthFirstChildIterator(Element rootElement)
      : _stack = _reverseChildrenOf(rootElement).toList();

  Element _current;

  final List<Element> _stack;

  @override
  Element get current => _current;

  @override
  bool moveNext() {
    if (_stack.isEmpty)
      return false;

    _current = _stack.removeLast();
    // Stack children in reverse order to traverse first branch first
    _stack.addAll(_reverseChildrenOf(_current));

    return true;
  }

  static Iterable<Element> _reverseChildrenOf(Element element) {
    List<Element> children = <Element>[];
    element.visitChildren(children.add);
    return children.reversed;
  }
}
