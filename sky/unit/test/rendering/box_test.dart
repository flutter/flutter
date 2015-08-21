import 'package:sky/rendering.dart';
import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/theme/shadows.dart';
import 'package:test/test.dart';

import 'layout_utils.dart';

void main() {
  test("should size to render view", () {
    RenderBox root = new RenderDecoratedBox(
      decoration: new BoxDecoration(
        backgroundColor: const Color(0xFF00FF00),
        gradient: new RadialGradient(
          center: Point.origin, radius: 500.0,
          colors: [colors.Yellow[500], colors.Blue[500]]),
        boxShadow: shadows[3])
    );
    layout(root);
    expect(root.size.width, equals(800.0));
    expect(root.size.height, equals(600.0));
  });

  test('Flex and padding', () {
    RenderBox size = new RenderConstrainedBox(
      additionalConstraints: new BoxConstraints().applyHeight(100.0)
    );
    RenderBox inner = new RenderDecoratedBox(
      decoration: new BoxDecoration(
        backgroundColor: const Color(0xFF00FF00)
      ),
      child: size
    );
    RenderBox padding = new RenderPadding(
      padding: new EdgeDims.all(50.0),
      child: inner
    );
    RenderBox flex = new RenderFlex(
      children: [padding],
      direction: FlexDirection.vertical,
      alignItems: FlexAlignItems.stretch
    );
    RenderBox outer = new RenderDecoratedBox(
      decoration: new BoxDecoration(
        backgroundColor: const Color(0xFF0000FF)
      ),
      child: flex
    );

    layout(outer);

    expect(size.size.width, equals(700.0));
    expect(size.size.height, equals(100.0));
    expect(inner.size.width, equals(700.0));
    expect(inner.size.height, equals(100.0));
    expect(padding.size.width, equals(800.0));
    expect(padding.size.height, equals(200.0));
    expect(flex.size.width, equals(800.0));
    expect(flex.size.height, equals(600.0));
    expect(outer.size.width, equals(800.0));
    expect(outer.size.height, equals(600.0));
  });

  test("should not have a 0 sized colored Box", () {
    var coloredBox = new RenderDecoratedBox(
      decoration: new BoxDecoration()
    );
    var paddingBox = new RenderPadding(padding: const EdgeDims.all(10.0),
        child: coloredBox);
    RenderBox root = new RenderDecoratedBox(
      decoration: new BoxDecoration(),
      child: paddingBox
    );
    layout(root);
    expect(coloredBox.size.width, equals(780.0));
    expect(coloredBox.size.height, equals(580.0));
  });
}
