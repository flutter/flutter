import 'dart:sky' as sky;
import 'package:sky/rendering.dart';
import 'package:sky/widgets.dart';
import 'package:test/test.dart';

const Size _kTestViewSize = const Size(800.0, 600.0);

class TestRenderView extends RenderView {
  TestRenderView({ RenderBox child }) : super(child: child) {
    attach();
    rootConstraints = new ViewConstraints(size: _kTestViewSize);
    scheduleInitialLayout();
  }
}

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

class TestGestureEvent extends sky.GestureEvent {
  TestGestureEvent({
    this.type,
    this.primaryPointer,
    this.x,
    this.y,
    this.dx,
    this.dy,
    this.velocityX,
    this.velocityY
  });

  String type;
  int primaryPointer;
  double x;
  double y;
  double dx;
  double dy;
  double velocityX;
  double velocityY;
}

class WidgetTester {
  WidgetTester() {
    _app = new TestApp();
    _renderView = new TestRenderView();
    runApp(_app, renderViewOverride: _renderView);
  }

  TestApp _app;
  RenderView _renderView;

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

  void dispatchEvent(sky.Event event, Point position) {
    HitTestResult result = SkyBinding.instance.hitTest(position);
    SkyBinding.instance.dispatchEvent(event, result);
  }

  void pumpFrame(WidgetBuilder builder) {
    _app.builder = builder;
    Component.flushBuild();
    RenderObject.flushLayout();
  }
}
