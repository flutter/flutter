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

  HitTestResult _hitTest(Point location) => SkyBinding.instance.hitTest(location);

  EventDisposition _dispatchEvent(sky.Event event, HitTestResult result) {
    return SkyBinding.instance.dispatchEvent(event, result);
  }

  void tap(Widget widget) {
    Point location = getCenter(widget);
    HitTestResult result = _hitTest(location);
    _dispatchEvent(new TestPointerEvent(type: 'pointerdown', x: location.x, y: location.y), result);
    _dispatchEvent(new TestPointerEvent(type: 'pointerup', x: location.x, y: location.y), result);
  }

  void scroll(Widget widget, Offset offset) {
    Point startLocation = getCenter(widget);
    HitTestResult result = _hitTest(startLocation);
    _dispatchEvent(new TestPointerEvent(type: 'pointerdown', x: startLocation.x, y: startLocation.y), result);
    Point endLocation = startLocation + offset;
    _dispatchEvent(
      new TestPointerEvent(
        type: 'pointermove',
        x: endLocation.x,
        y: endLocation.y,
        dx: offset.dx,
        dy: offset.dy
      ),
      result
    );
    _dispatchEvent(new TestPointerEvent(type: 'pointerup', x: endLocation.x, y: endLocation.y), result);
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
