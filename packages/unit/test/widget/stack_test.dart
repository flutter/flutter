import 'package:sky/src/fn3.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

void main() {
  test('Can change position data', () {
    WidgetTester tester = new WidgetTester();

    Key key = new Key('container');

    tester.pumpFrame(
      new Stack([
        new Positioned(
          left: 10.0,
          child: new Container(
            key: key,
            width: 10.0,
            height: 10.0
          )
        )
      ])
    );

    Element container = tester.findElementByKey(key);
    expect(container.renderObject.parentData.top, isNull);
    expect(container.renderObject.parentData.right, isNull);
    expect(container.renderObject.parentData.bottom, isNull);
    expect(container.renderObject.parentData.left, equals(10.0));

    tester.pumpFrame(
      new Stack([
        new Positioned(
          right: 10.0,
          child: new Container(
            key: key,
            width: 10.0,
            height: 10.0
          )
        )
      ])
    );

    container = tester.findElementByKey(key);
    expect(container.renderObject.parentData.top, isNull);
    expect(container.renderObject.parentData.right, equals(10.0));
    expect(container.renderObject.parentData.bottom, isNull);
    expect(container.renderObject.parentData.left, isNull);
  });

  test('Can remove parent data', () {
    WidgetTester tester = new WidgetTester();

    Key key = new Key('container');
    Container container = new Container(key: key, width: 10.0, height: 10.0);

    tester.pumpFrame(new Stack([ new Positioned(left: 10.0, child: container) ]));
    Element containerElement = tester.findElementByKey(key);

    expect(containerElement.renderObject.parentData.top, isNull);
    expect(containerElement.renderObject.parentData.right, isNull);
    expect(containerElement.renderObject.parentData.bottom, isNull);
    expect(containerElement.renderObject.parentData.left, equals(10.0));

    tester.pumpFrame(new Stack([ container ]));
    containerElement = tester.findElementByKey(key);

    expect(containerElement.renderObject.parentData.top, isNull);
    expect(containerElement.renderObject.parentData.right, isNull);
    expect(containerElement.renderObject.parentData.bottom, isNull);
    expect(containerElement.renderObject.parentData.left, isNull);
  });

}
