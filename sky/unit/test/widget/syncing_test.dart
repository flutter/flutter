import 'package:sky/widgets.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

class TestState extends StatefulComponent {
  TestState({ this.child, this.persistentState, this.syncedState });
  Widget child;
  int persistentState;
  int syncedState;
  int syncs = 0;
  void syncConstructorArguments(TestState source) {
    child = source.child;
    syncedState = source.syncedState;
    // we explicitly do NOT sync the persistentState from the new instance
    // because we're using that to track whether we got recreated
    syncs += 1;
  }
  Widget build() {
    return child;
  }
}

void main() {

  test('no change', () {

    WidgetTester tester = new WidgetTester();

    tester.pumpFrame(() {
      return new Container(
        child: new Container(
          child: new TestState(
            persistentState: 1,
            child: new Container()
          )
        )
      );
    });

    TestState stateWidget = tester.findWidget((widget) => widget is TestState);

    expect(stateWidget.persistentState, equals(1));
    expect(stateWidget.syncs, equals(0));

    tester.pumpFrame(() {
      return new Container(
        child: new Container(
          child: new TestState(
            persistentState: 2,
            child: new Container()
          )
        )
      );
    });

    expect(stateWidget.persistentState, equals(1));
    expect(stateWidget.syncs, equals(1));

  });

  test('remove one', () {

    WidgetTester tester = new WidgetTester();

    tester.pumpFrame(() {
      return new Container(
        child: new Container(
          child: new TestState(
            persistentState: 10,
            child: new Container()
          )
        )
      );
    });

    TestState stateWidget = tester.findWidget((widget) => widget is TestState);

    expect(stateWidget.persistentState, equals(10));
    expect(stateWidget.syncs, equals(0));

    tester.pumpFrame(() {
      return new Container(
        child: new TestState(
          persistentState: 11,
          child: new Container()
        )
      );
    });

    expect(stateWidget.persistentState, equals(10));
    expect(stateWidget.syncs, equals(1));

  });

  test('swap instances around', () {

    WidgetTester tester = new WidgetTester();

    Widget a, b;
    tester.pumpFrame(() {
      a = new TestState(persistentState: 0x61, syncedState: 0x41, child: new Text('apple'));
      b = new TestState(persistentState: 0x62, syncedState: 0x42, child: new Text('banana'));
      return new Column([]);
    });
    GlobalKey keyA = new GlobalKey();
    GlobalKey keyB = new GlobalKey();

    TestState foundA, foundB;

    tester.pumpFrame(() {
      return new Column([
        new Container(
          key: keyA,
          child: a
        ),
        new Container(
          key: keyB,
          child: b
        )
      ]);
    });

    foundA = (tester.findWidget((widget) => widget.key == keyA) as Container).child as TestState;
    foundB = (tester.findWidget((widget) => widget.key == keyB) as Container).child as TestState;

    expect(foundA, equals(a));
    expect(foundA.persistentState, equals(0x61));
    expect(foundA.syncedState, equals(0x41));
    expect(foundB, equals(b));
    expect(foundB.persistentState, equals(0x62));
    expect(foundB.syncedState, equals(0x42));

    tester.pumpFrame(() {
      return new Column([
        new Container(
          key: keyA,
          child: a
        ),
        new Container(
          key: keyB,
          child: b
        )
      ]);
    });

    foundA = (tester.findWidget((widget) => widget.key == keyA) as Container).child as TestState;
    foundB = (tester.findWidget((widget) => widget.key == keyB) as Container).child as TestState;

    // same as before
    expect(foundA, equals(a));
    expect(foundA.persistentState, equals(0x61));
    expect(foundA.syncedState, equals(0x41));
    expect(foundB, equals(b));
    expect(foundB.persistentState, equals(0x62));
    expect(foundB.syncedState, equals(0x42));

    // now we swap the nodes over
    // since they are both "old" nodes, they shouldn't sync with each other even though they look alike

    tester.pumpFrame(() {
      return new Column([
        new Container(
          key: keyA,
          child: b
        ),
        new Container(
          key: keyB,
          child: a
        )
      ]);
    });

    foundA = (tester.findWidget((widget) => widget.key == keyA) as Container).child as TestState;
    foundB = (tester.findWidget((widget) => widget.key == keyB) as Container).child as TestState;

    expect(foundA, equals(b));
    expect(foundA.persistentState, equals(0x62));
    expect(foundA.syncedState, equals(0x42));
    expect(foundB, equals(a));
    expect(foundB.persistentState, equals(0x61));
    expect(foundB.syncedState, equals(0x41));

  });

}
