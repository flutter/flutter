import 'package:flutter/rendering.dart';

const Size _kTestViewSize = const Size(800.0, 600.0);

class TestRenderView extends RenderView {
  TestRenderView() {
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

RenderView _renderView;
RenderView get renderView => _renderView;

void layout(RenderBox box, { BoxConstraints constraints, EnginePhase phase: EnginePhase.layout }) {
  assert(box != null); // if you want to just repump the last box, call pumpFrame().

  if (renderView == null)
    _renderView = new TestRenderView();

  if (renderView.child != null)
    renderView.child = null;

  if (constraints != null) {
    box = new RenderPositionedBox(
      child: new RenderConstrainedBox(
        additionalConstraints: constraints,
        child: box
      )
    );
  }

  renderView.child = box;

  pumpFrame(phase: phase);
}

void pumpFrame({ EnginePhase phase: EnginePhase.layout }) {
  RenderObject.flushLayout();
  if (phase == EnginePhase.layout)
    return;
  renderView.updateCompositingBits();
  RenderObject.flushPaint();
  if (phase == EnginePhase.paint)
    return;
  renderView.compositeFrame();
}

class TestCallbackPainter extends CustomPainter {
  const TestCallbackPainter({ this.onPaint });

  final VoidCallback onPaint;

  void paint(Canvas canvas, Size size) {
    onPaint();
  }

  bool shouldRepaint(TestCallbackPainter oldPainter) => true;
}
