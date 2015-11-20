import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:test/test.dart';

import 'rendering_tester.dart';

void main() {
  test("offstage", () {
    RenderBox child;
    bool painted = false;
    // viewport incoming constraints are tight 800x600
    // viewport is vertical by default
    RenderBox root = new RenderViewport(
      child: new RenderOffStage(
        child: new RenderCustomPaint(
          painter: new TestCallbackPainter(
            onPaint: () { painted = true; }
          ),
          child: child = new RenderConstrainedBox(
            additionalConstraints: new BoxConstraints.tightFor(height: 10.0, width: 10.0)
          )
        )
      )
    );
    expect(child.hasSize, isFalse);
    expect(painted, isFalse);
    layout(root, phase: EnginePhase.paint);
    expect(child.hasSize, isTrue);
    expect(painted, isFalse);
    expect(child.size, equals(const Size(800.0, 10.0)));
  });
}
