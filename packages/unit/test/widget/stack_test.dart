import 'package:sky/widgets.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

void main() {
  test('Can change position data', () {
    WidgetTester tester = new WidgetTester();

    tester.pumpFrame(() {
      return new Stack([
        new Positioned(
          left: 10.0,
          child: new Container(
            width: 10.0,
            height: 10.0
          )
        )
      ]);
    });

    Container container = tester.findWidget((Widget widget) => widget is Container);
    expect(container.renderObject.parentData.top, isNull);
    expect(container.renderObject.parentData.right, isNull);
    expect(container.renderObject.parentData.bottom, isNull);
    expect(container.renderObject.parentData.left, equals(10.0));

    tester.pumpFrame(() {
      return new Stack([
        new Positioned(
          right: 10.0,
          child: new Container(
            width: 10.0,
            height: 10.0
          )
        )
      ]);
    });

    container = tester.findWidget((Widget widget) => widget is Container);
    expect(container.renderObject.parentData.top, isNull);
    expect(container.renderObject.parentData.right, equals(10.0));
    expect(container.renderObject.parentData.bottom, isNull);
    expect(container.renderObject.parentData.left, isNull);
  });
}
