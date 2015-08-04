import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/object.dart';

import '../resources/display_list.dart';
import '../resources/third_party/unittest/unittest.dart';
import '../resources/unit.dart';

void main() {
  initUnit();

  test('Should be able to hit with negative scroll offset', () {
    RenderBox size = new RenderConstrainedBox(
      additionalConstraints: new BoxConstraints.tight(const Size(100.0, 100.0)));
  
    RenderBox red = new RenderDecoratedBox(
      decoration: new BoxDecoration(
        backgroundColor: const Color(0xFFFF0000)
      ),
      child: size);
  
    RenderViewport viewport = new RenderViewport(child: red, scrollOffset: new Offset(0.0, -10.0));
    TestRenderView renderView = new TestRenderView(viewport);
  
    HitTestResult result;

    result = new HitTestResult();  
    renderView.hitTest(result, position: new Point(15.0, 0.0));
    expect(result.path.first.target, equals(viewport));

    result = new HitTestResult();  
    renderView.hitTest(result, position: new Point(15.0, 15.0));
    expect(result.path.first.target, equals(size));
  });
}
