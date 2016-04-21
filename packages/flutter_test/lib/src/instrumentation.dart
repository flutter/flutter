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
  Instrumentation({ Widgeteer binding })
    : this.binding = binding ?? WidgetFlutterBinding.ensureInitialized();

  final Widgeteer binding;

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
    binding.dispatchEvent(p.down(location), result);
    binding.dispatchEvent(p.up(), result);
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
    binding.dispatchEvent(p.down(startLocation, timeStamp: new Duration(milliseconds: timeStamp.round())), result);
    for(int i = 0; i <= kMoveCount; i++) {
      final Point location = startLocation + Offset.lerp(Offset.zero, offset, i / kMoveCount);
      binding.dispatchEvent(p.move(location, timeStamp: new Duration(milliseconds: timeStamp.round())), result);
      timeStamp += timeStampDelta;
    }
    binding.dispatchEvent(p.up(timeStamp: new Duration(milliseconds: timeStamp.round())), result);
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
    binding.dispatchEvent(p.down(startLocation), result);
    binding.dispatchEvent(p.move(endLocation), result);
    binding.dispatchEvent(p.up(), result);
  }

  /// Begins a gesture at a particular point, and returns the
  /// [TestGesture] object which you can use to continue the gesture.
  TestGesture startGesture(Point downLocation, { int pointer: 1 }) {
    return new TestGesture(downLocation, pointer: pointer);
  }

  HitTestResult _hitTest(Point location) {
    HitTestResult result = new HitTestResult();
    binding.hitTest(result, location);
    return result;
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
