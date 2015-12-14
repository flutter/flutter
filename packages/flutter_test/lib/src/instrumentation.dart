// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
  Instrumentation() : binding = WidgetFlutterBinding.ensureInitialized();

  final WidgetFlutterBinding binding;

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
  List<Layer> get layers => _layers(binding.renderView.layer);


  void walkElements(ElementVisitor visitor) {
    void walk(Element element) {
      visitor(element);
      element.visitChildren(walk);
    }
    binding.renderViewElement.visitChildren(walk);
  }

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

  Element findElementByKey(Key key) {
    return findElement((Element element) => element.widget.key == key);
  }

  Element findText(String text) {
    return findElement((Element element) {
      return element.widget is Text && element.widget.data == text;
    });
  }

  State findStateOfType(Type type) {
    StatefulComponentElement element = findElement((Element element) {
      return element is StatefulComponentElement && element.state.runtimeType == type;
    });
    return element?.state;
  }

  State findStateByConfig(Widget config) {
    StatefulComponentElement element = findElement((Element element) {
      return element is StatefulComponentElement && element.state.config == config;
    });
    return element?.state;
  }

  Point getCenter(Element element) {
    return _getElementPoint(element, (Size size) => size.center(Point.origin));
  }

  Point getTopLeft(Element element) {
    return _getElementPoint(element, (_) => Point.origin);
  }

  Point getTopRight(Element element) {
    return _getElementPoint(element, (Size size) => size.topRight(Point.origin));
  }

  Point getBottomLeft(Element element) {
    return _getElementPoint(element, (Size size) => size.bottomLeft(Point.origin));
  }

  Point getBottomRight(Element element) {
    return _getElementPoint(element, (Size size) => size.bottomRight(Point.origin));
  }

  Point _getElementPoint(Element element, SizeToPointFunction sizeToPoint) {
    assert(element != null);
    RenderBox box = element.renderObject as RenderBox;
    assert(box != null);
    return box.localToGlobal(sizeToPoint(box.size));
  }


  void tap(Element element, { int pointer: 1 }) {
    tapAt(getCenter(element), pointer: pointer);
  }

  void tapAt(Point location, { int pointer: 1 }) {
    HitTestResult result = _hitTest(location);
    TestPointer p = new TestPointer(pointer);
    _dispatchEvent(p.down(location), result);
    _dispatchEvent(p.up(), result);
  }

  void fling(Element element, Offset offset, double velocity, { int pointer: 1 }) {
    flingFrom(getCenter(element), offset, velocity, pointer: pointer);
  }

  void flingFrom(Point startLocation, Offset offset, double velocity, { int pointer: 1 }) {
    assert(offset.distance > 0.0);
    assert(velocity != 0.0);   // velocity is pixels/second
    final TestPointer p = new TestPointer(pointer);
    final HitTestResult result = _hitTest(startLocation);
    const int kMoveCount = 50; // Needs to be >= kHistorySize, see _LeastSquaresVelocityTrackerStrategy
    final double timeStampDelta = 1000.0 * offset.distance / (kMoveCount * velocity);
    double timeStamp = 0.0;
    _dispatchEvent(p.down(startLocation, timeStamp: new Duration(milliseconds: timeStamp.round())), result);
    for(int i = 0; i < kMoveCount; i++) {
      final Point location = startLocation + Offset.lerp(Offset.zero, offset, i / kMoveCount);
      _dispatchEvent(p.move(location, timeStamp: new Duration(milliseconds: timeStamp.round())), result);
      timeStamp += timeStampDelta;
    }
    _dispatchEvent(p.up(timeStamp: new Duration(milliseconds: timeStamp.round())), result);
  }

  void scroll(Element element, Offset offset, { int pointer: 1 }) {
    scrollAt(getCenter(element), offset, pointer: pointer);
  }

  void scrollAt(Point startLocation, Offset offset, { int pointer: 1 }) {
    Point endLocation = startLocation + offset;
    TestPointer p = new TestPointer(pointer);
    // Events for the entire press-drag-release gesture are dispatched
    // to the widgets "hit" by the pointer down event.
    HitTestResult result = _hitTest(startLocation);
    _dispatchEvent(p.down(startLocation), result);
    _dispatchEvent(p.move(endLocation), result);
    _dispatchEvent(p.up(), result);
  }

  void dispatchEvent(PointerEvent event, Point location) {
    _dispatchEvent(event, _hitTest(location));
  }

  HitTestResult _hitTest(Point location) {
    HitTestResult result = new HitTestResult();
    binding.hitTest(result, location);
    return result;
  }

  void _dispatchEvent(PointerEvent event, HitTestResult result) {
    binding.dispatchEvent(event, result);
  }
}
