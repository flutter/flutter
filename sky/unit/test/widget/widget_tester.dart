import 'dart:sky' as sky;

import 'package:sky/rendering.dart';
import 'package:sky/widgets.dart';
import 'package:sky/base/scheduler.dart' as scheduler;

import '../engine/mock_events.dart';

typedef Widget WidgetBuilder();

class TestApp extends App {
  TestApp();

  WidgetBuilder _builder;
  void set builder (WidgetBuilder value) {
    setState(() {
      _builder = value;
    });
  }

  Widget build() {
    if (_builder != null)
      return _builder();
    return new Container();
  }
}

class WidgetTester {
  WidgetTester() {
    _app = new TestApp();
    runApp(_app);
  }

  TestApp _app;

  List<Layer> _layers(Layer layer) {
    List<Layer> result = [layer];
    if (layer is ContainerLayer) {
      ContainerLayer root = layer;
      Layer child = root.firstChild;
      while(child != null) {
        result.addAll(_layers(child));
        child = child.nextSibling;
      }
    }
    return result;
  }
  List<Layer> get layers => _layers(SkyBinding.instance.renderView.layer);

  void walkWidgets(WidgetTreeWalker walker) {
    void walk(Widget widget) {
      walker(widget);
      widget.walkChildren(walk);
    }

    _app.walkChildren(walk);
  }

  Widget findWidget(bool predicate(Widget widget)) {
    try {
      walkWidgets((Widget widget) {
        if (predicate(widget))
          throw widget;
      });
    } catch (e) {
      if (e is Widget)
        return e;
      rethrow;
    }
    return null;
  }

  Text findText(String text) {
    return findWidget((Widget widget) {
      return widget is Text && widget.data == text;
    });
  }

  Point getCenter(Widget widget) {
    assert(widget != null);
    RenderBox box = widget.renderObject as RenderBox;
    assert(box != null);
    return box.localToGlobal(box.size.center(Point.origin));
  }

  Point getTopLeft(Widget widget) {
    assert(widget != null);
    RenderBox box = widget.renderObject as RenderBox;
    assert(box != null);
    return box.localToGlobal(Point.origin);
  }

  Point getTopRight(Widget widget) {
    assert(widget != null);
    RenderBox box = widget.renderObject as RenderBox;
    assert(box != null);
    return box.localToGlobal(box.size.topRight(Point.origin));
  }

  HitTestResult _hitTest(Point location) => SkyBinding.instance.hitTest(location);

  EventDisposition _dispatchEvent(sky.Event event, HitTestResult result) {
    return SkyBinding.instance.dispatchEvent(event, result);
  }

  void tap(Widget widget, { int pointer: 1 }) {
    tapAt(getCenter(widget), pointer: pointer);
  }

  void tapAt(Point location, { int pointer: 1 }) {
    HitTestResult result = _hitTest(location);
    TestPointer p = new TestPointer(pointer);
    _dispatchEvent(p.down(location), result);
    _dispatchEvent(p.up(), result);
  }

  void scroll(Widget widget, Offset offset, { int pointer: 1 }) {
    Point startLocation = getCenter(widget);
    Point endLocation = startLocation + offset;
    TestPointer p = new TestPointer(pointer);
    // Events for the entire press-drag-release gesture are dispatched
    // to the widgets "hit" by the pointer down event.
    HitTestResult result = _hitTest(startLocation);
    _dispatchEvent(p.down(startLocation), result);
    _dispatchEvent(p.move(endLocation), result);
    _dispatchEvent(p.up(), result);
  }

  void dispatchEvent(sky.Event event, Point location) {
    _dispatchEvent(event, _hitTest(location));
  }

  void pumpFrame(WidgetBuilder builder, [double frameTimeMs = 0.0]) {
    _app.builder = builder;
    scheduler.beginFrame(frameTimeMs);
  }

  void pumpFrameWithoutChange([double frameTimeMs = 0.0]) {
    scheduler.beginFrame(frameTimeMs);
  }

}
