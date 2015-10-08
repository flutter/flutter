import 'package:sky/widgets.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

void main() {
  test('Can construct an empty Stack', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new Stack([]));
    });
  });

  test('Can construct an empty Centered Stack', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new Center(child: new Stack([])));
    });
  });

  test('Can change position data', () {
    testWidgets((WidgetTester tester) {
      Key key = new Key('container');

      tester.pumpWidget(
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

      tester.pumpWidget(
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
  });

  test('Can remove parent data', () {
    testWidgets((WidgetTester tester) {
      Key key = new Key('container');
      Container container = new Container(key: key, width: 10.0, height: 10.0);

      tester.pumpWidget(new Stack([ new Positioned(left: 10.0, child: container) ]));
      Element containerElement = tester.findElementByKey(key);

      expect(containerElement.renderObject.parentData.top, isNull);
      expect(containerElement.renderObject.parentData.right, isNull);
      expect(containerElement.renderObject.parentData.bottom, isNull);
      expect(containerElement.renderObject.parentData.left, equals(10.0));

      tester.pumpWidget(new Stack([ container ]));
      containerElement = tester.findElementByKey(key);

      expect(containerElement.renderObject.parentData.top, isNull);
      expect(containerElement.renderObject.parentData.right, isNull);
      expect(containerElement.renderObject.parentData.bottom, isNull);
      expect(containerElement.renderObject.parentData.left, isNull);
    });
  });

  test('Can align non-positioned children', () {
    testWidgets((WidgetTester tester) {
      Key child0Key = new Key('child0');
      Key child1Key = new Key('child1');

      tester.pumpWidget(
        new Center(
          child: new Stack([
              new Container(key: child0Key, width: 20.0, height: 20.0),
              new Container(key: child1Key, width: 10.0, height: 10.0)
            ],
            horizontalAlignment: 0.5,
            verticalAlignment: 0.5
          )
        )
      );

      Element child0 = tester.findElementByKey(child0Key);
      expect(child0.renderObject.parentData.position, equals(const Point(0.0, 0.0)));

      Element child1 = tester.findElementByKey(child1Key);
      expect(child1.renderObject.parentData.position, equals(const Point(5.0, 5.0)));
    });
  });

  test('Can construct an empty IndexedStack', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new IndexedStack([]));
    });
  });

  test('Can construct an empty Centered IndexedStack', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new Center(child: new IndexedStack([])));
    });
  });

  test('Can construct an IndexedStack', () {
    testWidgets((WidgetTester tester) {
      int itemCount = 3;
      List<int> itemsPainted;

      Widget buildFrame(int index) {
        itemsPainted = [];
        List<Widget> items = new List.generate(itemCount, (i) {
          return new CustomPaint(child: new Text('$i'), callback: (_0, _1) { itemsPainted.add(i); });
        });
        return new Center(child: new IndexedStack(items, index: index));
      }

      tester.pumpWidget(buildFrame(0));
      expect(tester.findText('0'), isNotNull);
      expect(tester.findText('1'), isNotNull);
      expect(tester.findText('2'), isNotNull);
      expect(itemsPainted, equals([0]));

      tester.pumpWidget(buildFrame(1));
      expect(itemsPainted, equals([1]));

      tester.pumpWidget(buildFrame(2));
      expect(itemsPainted, equals([2]));
    });
  });

  test('Can hit test an IndexedStack', () {
    testWidgets((WidgetTester tester) {
      Key key = new Key('indexedStack');
      int itemCount = 3;
      List<int> itemsTapped;

      Widget buildFrame(int index) {
        itemsTapped = [];
        List<Widget> items = new List.generate(itemCount, (i) {
          return new GestureDetector(child: new Text('$i'), onTap: () { itemsTapped.add(i); });
        });
        return new Center(child: new IndexedStack(items, key: key, index: index));
      }

      tester.pumpWidget(buildFrame(0));
      expect(itemsTapped, isEmpty);
      tester.tap(tester.findElementByKey(key));
      expect(itemsTapped, [0]);

      tester.pumpWidget(buildFrame(2));
      expect(itemsTapped, isEmpty);
      tester.tap(tester.findElementByKey(key));
      expect(itemsTapped, [2]);
    });
  });

}
