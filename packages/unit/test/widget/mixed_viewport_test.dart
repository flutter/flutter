import 'package:sky/widgets.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

class TestComponent extends StatefulComponent {
  TestComponent(this.viewport);
  MixedViewport viewport;
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
  test('MixedViewport mount/dismount smoke test', () {
    WidgetTester tester = new WidgetTester();

    MixedViewportLayoutState layoutState = new MixedViewportLayoutState();

    List<int> callbackTracker = <int>[];

    // the root view is 800x600 in the test environment
    // so if our widget is 100 pixels tall, it should fit exactly 6 times.

    TestComponent testComponent;
    Widget builder() {
      testComponent = new TestComponent(new MixedViewport(
        builder: (int i) {
          callbackTracker.add(i);
          return new Container(
            key: new ValueKey<int>(i),
            height: 100.0,
            child: new Text("$i")
          );
        },
        startOffset: 0.0,
        layoutState: layoutState
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

  test('MixedViewport vertical', () {
    WidgetTester tester = new WidgetTester();

    MixedViewportLayoutState layoutState = new MixedViewportLayoutState();

    List<int> callbackTracker = <int>[];

    // the root view is 800x600 in the test environment
    // so if our widget is 200 pixels tall, it should fit exactly 3 times.
    // but if we are offset by 300 pixels, there will be 4, numbered 1-4.

    double offset = 300.0;

    IndexedBuilder itemBuilder = (int i) {
      callbackTracker.add(i);
      return new Container(
        key: new ValueKey<int>(i),
        width: 500.0, // this should be ignored
        height: 200.0,
        child: new Text("$i")
      );
    };

    TestComponent testComponent;
    Widget builder() {
      testComponent = new TestComponent(new MixedViewport(
        builder: itemBuilder,
        startOffset: offset,
        layoutState: layoutState
      ));
      return testComponent;
    }

    tester.pumpFrame(builder);

    // 0 is built to find its width
    expect(callbackTracker, equals([0, 1, 2, 3, 4]));

    callbackTracker.clear();

    offset = 400.0; // now only 3 should fit, numbered 2-4.

    tester.pumpFrame(builder);

    // 0 and 1 aren't built, we know their size and nothing else changed
    expect(callbackTracker, equals([2, 3, 4]));

    callbackTracker.clear();

  });

  test('MixedViewport horizontal', () {
    WidgetTester tester = new WidgetTester();

    MixedViewportLayoutState layoutState = new MixedViewportLayoutState();

    List<int> callbackTracker = <int>[];

    // the root view is 800x600 in the test environment
    // so if our widget is 200 pixels wide, it should fit exactly 4 times.
    // but if we are offset by 300 pixels, there will be 5, numbered 1-5.

    double offset = 300.0;

    IndexedBuilder itemBuilder = (int i) {
      callbackTracker.add(i);
      return new Container(
        key: new ValueKey<int>(i),
        height: 500.0, // this should be ignored
        width: 200.0,
        child: new Text("$i")
      );
    };

    TestComponent testComponent;
    Widget builder() {
      testComponent = new TestComponent(new MixedViewport(
        builder: itemBuilder,
        startOffset: offset,
        layoutState: layoutState,
        direction: ScrollDirection.horizontal
      ));
      return testComponent;
    }

    tester.pumpFrame(builder);

    // 0 is built to find its width
    expect(callbackTracker, equals([0, 1, 2, 3, 4, 5]));

    callbackTracker.clear();

    offset = 400.0; // now only 4 should fit, numbered 2-5.

    tester.pumpFrame(builder);

    // 0 and 1 aren't built, we know their size and nothing else changed
    expect(callbackTracker, equals([2, 3, 4, 5]));

    callbackTracker.clear();

  });
}
