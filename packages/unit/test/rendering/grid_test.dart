import 'package:sky/rendering.dart';
import 'package:test/test.dart';

import 'rendering_tester.dart';

void main() {
  test('Basic grid layout test', () {
    List<RenderBox> children = [
      new RenderDecoratedBox(decoration: new BoxDecoration()),
      new RenderDecoratedBox(decoration: new BoxDecoration()),
      new RenderDecoratedBox(decoration: new BoxDecoration()),
      new RenderDecoratedBox(decoration: new BoxDecoration())
    ];

    RenderBox grid = new RenderGrid(children: children, maxChildExtent: 100.0);
    RenderingTester tester = layout(grid, constraints: const BoxConstraints(maxWidth: 200.0));

    children.forEach((child) {
      expect(child.size.width, equals(100.0), reason: "child width");
      expect(child.size.height, equals(100.0), reason: "child height");
    });

    expect(grid.size.width, equals(200.0), reason: "grid width");
    expect(grid.size.height, equals(200.0), reason: "grid height");

    expect(grid.needsLayout, equals(false));
    grid.maxChildExtent = 60.0;
    expect(grid.needsLayout, equals(true));

    tester.pumpFrame(phase: EnginePhase.layout);

    children.forEach((child) {
      expect(child.size.width, equals(50.0), reason: "child width");
      expect(child.size.height, equals(50.0), reason: "child height");
    });

    expect(grid.size.width, equals(200.0), reason: "grid width");
    expect(grid.size.height, equals(50.0), reason: "grid height");
  });
}
