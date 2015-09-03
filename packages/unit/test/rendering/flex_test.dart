import 'package:sky/rendering.dart';
import 'package:test/test.dart';

import 'rendering_tester.dart';

void main() {
  test('Overconstrained flex', () {
    RenderDecoratedBox box = new RenderDecoratedBox(decoration: new BoxDecoration());
    RenderFlex flex = new RenderFlex(children: [ box ]);
    layout(flex, constraints: const BoxConstraints(
      minWidth: 200.0, maxWidth: 100.0, minHeight: 200.0, maxHeight: 100.0));

    expect(flex.size.width, equals(200.0), reason: "flex width");
    expect(flex.size.height, equals(200.0), reason: "flex height");
  });
}
