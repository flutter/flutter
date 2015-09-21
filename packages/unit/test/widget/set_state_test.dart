import 'package:sky/widgets.dart';
import 'package:test/test.dart';

import '../engine/mock_events.dart';
import 'widget_tester.dart';

class Inside extends StatefulComponent {
  void syncConstructorArguments(Inside source) {
  }

  Widget build() {
    return new Listener(
      onPointerDown: _handlePointerDown,
      child: new Text('INSIDE')
    );
  }

  void _handlePointerDown(_) {
    setState(() { });
  }
}

class Middle extends StatefulComponent {
  Inside child;

  Middle({ this.child });

  void syncConstructorArguments(Middle source) {
    child = source.child;
  }

  Widget build() {
    return new Listener(
      onPointerDown: _handlePointerDown,
      child: child
    );
  }

  void _handlePointerDown(_) {
    setState(() { });
  }

}

class Outside extends App {
  Widget build() {
    return new Middle(child: new Inside());
  }
}

void main() {
  test('setState() smoke test', () {
    WidgetTester tester = new WidgetTester();

    tester.pumpFrame(() {
      return new Outside();
    });

    TestPointer pointer = new TestPointer(1);
    Point location = tester.getCenter(tester.findText('INSIDE'));
    tester.dispatchEvent(pointer.down(location), location);

    tester.pumpFrameWithoutChange();

    tester.dispatchEvent(pointer.up(), location);

    tester.pumpFrameWithoutChange();

  });
}
