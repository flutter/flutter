import 'package:sky/rendering.dart';
import 'package:sky/widgets.dart';

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

class WidgetTester {
  WidgetTester() {
    _app = new TestApp();
    _renderView = new TestRenderView();
    runApp(_app, renderViewOverride: _renderView);
  }

  TestApp _app;
  RenderView _renderView;

  void pumpFrame(WidgetBuilder builder) {
    _app.builder = builder;
    Component.flushBuild();
    RenderObject.flushLayout();
  }
}
