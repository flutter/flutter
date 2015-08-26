import 'package:sky/rendering.dart';

const Size _kTestViewSize = const Size(800.0, 600.0);

class TestRenderView extends RenderView {
  TestRenderView({ RenderBox child }) : super(child: child) {
    attach();
    rootConstraints = new ViewConstraints(size: _kTestViewSize);
    scheduleInitialLayout();
    scheduleInitialPaint(new TransformLayer(transform: new Matrix4.identity()));
  }
}

enum EnginePhase {
  layout,
  paint,
  composite
}

class RenderingTester {
  RenderingTester({ RenderBox root }) {
    renderView = new TestRenderView(child: root);
  }

  RenderView renderView;

  void pumpFrame({ EnginePhase phase: EnginePhase.composite }) {
    RenderObject.flushLayout();
    if (phase == EnginePhase.layout)
      return;
    renderView.updateCompositingBits();
    RenderObject.flushPaint();
    if (phase == EnginePhase.paint)
      return;
    renderView.compositeFrame();
  }
}

RenderingTester layout(RenderBox box, { BoxConstraints constraints }) {
  if (constraints != null) {
    box = new RenderPositionedBox(
      child: new RenderConstrainedBox(
        additionalConstraints: constraints,
        child: box
      )
    );
  }

  RenderingTester tester = new RenderingTester(root: box);
  tester.pumpFrame(phase: EnginePhase.layout);
  return tester;
}
