import 'package:sky/rendering.dart';
import 'package:test/test.dart';

import 'rendering_tester.dart';

void main() {
  test('Should be able to hit with negative scroll offset', () {
    RenderBox size = new RenderConstrainedBox(
      additionalConstraints: new BoxConstraints.tight(const Size(100.0, 100.0)));

    RenderBox red = new RenderDecoratedBox(
      decoration: new BoxDecoration(
        backgroundColor: const Color(0xFFFF0000)
      ),
      child: size);

    RenderViewport viewport = new RenderViewport(child: red, scrollOffset: new Offset(0.0, -10.0));
    RenderingTester tester = layout(viewport);

    HitTestResult result;

    result = new HitTestResult();
    tester.renderView.hitTest(result, position: new Point(15.0, 0.0));
    expect(result.path.first.target, equals(viewport));

    result = new HitTestResult();
    tester.renderView.hitTest(result, position: new Point(15.0, 15.0));
    expect(result.path.first.target, equals(size));
  });
}
