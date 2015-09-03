import 'package:sky/widgets.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

class TestState extends StatefulComponent {
  TestState({this.child, this.state});
  Widget child;
  int state;
  int syncs = 0;
  void syncConstructorArguments(TestState source) {
    child = source.child;
    // we explicitly do NOT sync the state from the new instance
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
            state: 1,
            child: new Container()
          )
        )
      );
    });

    TestState stateWidget = tester.findWidget((widget) => widget is TestState);

    expect(stateWidget.state, equals(1));
    expect(stateWidget.syncs, equals(0));

    tester.pumpFrame(() {
      return new Container(
        child: new Container(
          child: new TestState(
            state: 2,
            child: new Container()
          )
        )
      );
    });

    expect(stateWidget.state, equals(1));
    expect(stateWidget.syncs, equals(1));

  });

  // Requires _shouldReparentDuringSync
  // test('remove one', () {
  //
  //   WidgetTester tester = new WidgetTester();
  //
  //   tester.pumpFrame(() {
  //     return new Container(
  //       child: new Container(
  //         child: new TestState(
  //           state: 10,
  //           child: new Container()
  //         )
  //       )
  //     );
  //   });
  //
  //   TestState stateWidget = tester.findWidget((widget) => widget is TestState);
  //
  //   expect(stateWidget.state, equals(10));
  //   expect(stateWidget.syncs, equals(0));
  //
  //   tester.pumpFrame(() {
  //     return new Container(
  //       child: new TestState(
  //         state: 11,
  //         child: new Container()
  //       )
  //     );
  //   });
  //
  //   expect(stateWidget.state, equals(10));
  //   expect(stateWidget.syncs, equals(1));
  //
  // });

}
