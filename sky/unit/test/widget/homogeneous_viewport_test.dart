import 'package:sky/widgets.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

class TestComponent extends StatefulComponent {
  TestComponent(this.viewport);
  HomogeneousViewport viewport;
  void syncConstructorArguments(TestComponent source) {
    viewport = source.viewport;
  }
  bool _flag = true;
  void go(bool flag) {
    setState(() {
      _flag = flag;
    });
  }
  Widget build() {
    return _flag ? viewport : new Text('Not Today');
  }
}

void main() {
  test('HomogeneousViewport mount/dismount smoke test', () {
    WidgetTester tester = new WidgetTester();

    List<int> callbackTracker = <int>[];

    // the root view is 800x600 in the test environment
    // so if our widget is 100 pixels tall, it should fit exactly 6 times.

    TestComponent testComponent;
    Widget builder() {
      testComponent = new TestComponent(new HomogeneousViewport(
        builder: (int start, int count) {
          List<Widget> result = <Widget>[];
          for (int index = start; index < start + count; index += 1) {
            callbackTracker.add(index);
            result.add(new Container(
              key: new ValueKey<int>(index),
              height: 100.0,
              child: new Text("$index")
            ));
          }
          return result;
        },
        startOffset: 0.0,
        itemExtent: 100.0
      ));
      return testComponent;
    }

    tester.pumpFrame(builder);

    expect(callbackTracker, equals([0, 1, 2, 3, 4, 5]));

    callbackTracker.clear();
    testComponent.go(false);
    tester.pumpFrameWithoutChange();

    expect(callbackTracker, equals([]));

    callbackTracker.clear();
    testComponent.go(true);
    tester.pumpFrameWithoutChange();

    expect(callbackTracker, equals([0, 1, 2, 3, 4, 5]));
  });

  test('HomogeneousViewport vertical', () {
    WidgetTester tester = new WidgetTester();

    List<int> callbackTracker = <int>[];

    // the root view is 800x600 in the test environment
    // so if our widget is 200 pixels tall, it should fit exactly 3 times.
    // but if we are offset by 300 pixels, there will be 4, numbered 1-4.

    double offset = 300.0;

    ListBuilder itemBuilder = (int start, int count) {
      List<Widget> result = <Widget>[];
      for (int index = start; index < start + count; index += 1) {
        callbackTracker.add(index);
        result.add(new Container(
          key: new ValueKey<int>(index),
          width: 500.0, // this should be ignored
          height: 400.0, // should be overridden by itemExtent
          child: new Text("$index")
        ));
      }
      return result;
    };

    TestComponent testComponent;
    Widget builder() {
      testComponent = new TestComponent(new HomogeneousViewport(
        builder: itemBuilder,
        startOffset: offset,
        itemExtent: 200.0
      ));
      return testComponent;
    }

    tester.pumpFrame(builder);

    expect(callbackTracker, equals([1, 2, 3, 4]));

    callbackTracker.clear();

    offset = 400.0; // now only 3 should fit, numbered 2-4.

    tester.pumpFrame(builder);

    expect(callbackTracker, equals([2, 3, 4]));

    callbackTracker.clear();
  });

  test('HomogeneousViewport horizontal', () {
    WidgetTester tester = new WidgetTester();

    List<int> callbackTracker = <int>[];

    // the root view is 800x600 in the test environment
    // so if our widget is 200 pixels wide, it should fit exactly 4 times.
    // but if we are offset by 300 pixels, there will be 5, numbered 1-5.

    double offset = 300.0;

    ListBuilder itemBuilder = (int start, int count) {
      List<Widget> result = <Widget>[];
      for (int index = start; index < start + count; index += 1) {
        callbackTracker.add(index);
        result.add(new Container(
          key: new ValueKey<int>(index),
          width: 400.0, // this should be overridden by itemExtent
          height: 500.0, // this should be ignored
          child: new Text("$index")
        ));
      }
      return result;
    };

    TestComponent testComponent;
    Widget builder() {
      testComponent = new TestComponent(new HomogeneousViewport(
        builder: itemBuilder,
        startOffset: offset,
        itemExtent: 200.0,
        direction: ScrollDirection.horizontal
      ));
      return testComponent;
    }

    tester.pumpFrame(builder);

    expect(callbackTracker, equals([1, 2, 3, 4, 5]));

    callbackTracker.clear();

    offset = 400.0; // now only 4 should fit, numbered 2-5.

    tester.pumpFrame(builder);

    expect(callbackTracker, equals([2, 3, 4, 5]));

    callbackTracker.clear();
  });
}
