import 'package:flutter/rendering.dart';
import 'package:test/test.dart';

import 'rendering_tester.dart';

void main() {
  test('RenderPositionedBox expands', () {
    RenderConstrainedBox sizer = new RenderConstrainedBox(
      additionalConstraints: new BoxConstraints.tight(new Size(100.0, 100.0)),
      child: new RenderDecoratedBox(decoration: new BoxDecoration())
    );
    RenderPositionedBox positioner = new RenderPositionedBox(child: sizer);
    layout(positioner, constraints: new BoxConstraints.loose(new Size(200.0, 200.0)));

    expect(positioner.size.width, equals(200.0), reason: "positioner width");
    expect(positioner.size.height, equals(200.0), reason: "positioner height");
  });

  test('RenderPositionedBox shrink wraps', () {
    RenderConstrainedBox sizer = new RenderConstrainedBox(
      additionalConstraints: new BoxConstraints.tight(new Size(100.0, 100.0)),
      child: new RenderDecoratedBox(decoration: new BoxDecoration())
    );
    RenderPositionedBox positioner = new RenderPositionedBox(child: sizer, shrinkWrap: ShrinkWrap.width);
    layout(positioner, constraints: new BoxConstraints.loose(new Size(200.0, 200.0)));

    expect(positioner.size.width, equals(100.0), reason: "positioner width");
    expect(positioner.size.height, equals(200.0), reason: "positioner height");

    positioner.shrinkWrap = ShrinkWrap.height;
    pumpFrame();

    expect(positioner.size.width, equals(200.0), reason: "positioner width");
    expect(positioner.size.height, equals(100.0), reason: "positioner height");

    positioner.shrinkWrap = ShrinkWrap.both;
    pumpFrame();

    expect(positioner.size.width, equals(100.0), reason: "positioner width");
    expect(positioner.size.height, equals(100.0), reason: "positioner height");
  });
}
