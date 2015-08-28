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

  void tap(Widget widget) {
    dispatchEvent(new TestGestureEvent(type: 'gesturetap'), getCenter(widget));
  }

  void scroll(Widget widget, Offset offset) {
    dispatchEvent(new TestGestureEvent(type: 'gesturescrollstart'), getCenter(widget));
    dispatchEvent(new TestGestureEvent(
      type: 'gesturescrollupdate',
      dx: offset.dx,
      dy: offset.dy), getCenter(widget));
    // pointerup to trigger scroll settling in Scrollable<T>
    dispatchEvent(new TestPointerEvent(
      type: 'pointerup', down: false, primary: true), getCenter(widget));
  }

  void dispatchEvent(sky.Event event, Point position) {
    HitTestResult result = SkyBinding.instance.hitTest(position);
    SkyBinding.instance.dispatchEvent(event, result);
  }

  void pumpFrame(WidgetBuilder builder, [double frameTimeMs = 0.0]) {
    _app.builder = builder;
    scheduler.beginFrame(frameTimeMs);
  }

}
