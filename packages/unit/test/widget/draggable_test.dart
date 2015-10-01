import 'package:sky/src/fn3.dart';
import 'package:test/test.dart';

import '../engine/mock_events.dart';
import 'widget_tester.dart';

void main() {
  test('Drag and drop - control test', () {
    WidgetTester tester = new WidgetTester();
    TestPointer pointer = new TestPointer(7);

    List accepted = [];

    tester.pumpFrame(new Navigator(
      routes: {
        '/': (NavigatorState navigator, Route route) { return new Column([
            new Draggable(
              navigator: navigator,
              data: 1,
              child: new Text('Source'),
              feedback: new Text('Dragging')
            ),
            new DragTarget(
              builder: (context, data, rejects) {
                return new Container(
                  height: 100.0,
                  child: new Text('Target')
                );
              },
              onAccept: (data) {
                accepted.add(data);
              }
            ),
          ]);
        },
      }
    ));

    expect(accepted, isEmpty);
    expect(tester.findText('Source'), isNotNull);
    expect(tester.findText('Dragging'), isNull);
    expect(tester.findText('Target'), isNotNull);

    Point firstLocation = tester.getCenter(tester.findText('Source'));
    tester.dispatchEvent(pointer.down(firstLocation), firstLocation);
    tester.pumpFrameWithoutChange();

    expect(accepted, isEmpty);
    expect(tester.findText('Source'), isNotNull);
    expect(tester.findText('Dragging'), isNotNull);
    expect(tester.findText('Target'), isNotNull);

    Point secondLocation = tester.getCenter(tester.findText('Target'));
    tester.dispatchEvent(pointer.move(secondLocation), firstLocation);
    tester.pumpFrameWithoutChange();

    expect(accepted, isEmpty);
    expect(tester.findText('Source'), isNotNull);
    expect(tester.findText('Dragging'), isNotNull);
    expect(tester.findText('Target'), isNotNull);

    tester.dispatchEvent(pointer.up(), firstLocation);
    tester.pumpFrameWithoutChange();

    expect(accepted, equals([1]));
    expect(tester.findText('Source'), isNotNull);
    expect(tester.findText('Dragging'), isNull);
    expect(tester.findText('Target'), isNotNull);
    
  });
}
