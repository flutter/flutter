import 'package:sky/rendering.dart';

const Size _kTestViewSize = const Size(800.0, 600.0);

class TestRenderView extends RenderView {
  TestRenderView({ RenderBox child }) : super(child: child) {
    attach();
    rootConstraints = new ViewConstraints(size: _kTestViewSize);
    scheduleInitialLayout();
  }

  void beginFrame(double timeStamp) {
    RenderObject.flushLayout();
  }
}

RenderView layout(RenderBox box, { BoxConstraints constraints }) {
  if (constraints != null) {
    box = new RenderPositionedBox(
      child: new RenderConstrainedBox(
        additionalConstraints: constraints,
        child: box
      )
    );
  }

  TestRenderView renderView = new TestRenderView(child: box);
  renderView.beginFrame(0.0);
  return renderView;
}
