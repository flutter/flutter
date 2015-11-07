import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

void main() {
  test('Events bubble up the tree', () {
    testWidgets((WidgetTester tester) {
      List<String> log = new List<String>();

      tester.pumpWidget(
        new Listener(
          onPointerDown: (_) {
            log.add('top');
          },
          child: new Listener(
            onPointerDown: (_) {
              log.add('middle');
            },
            child: new DecoratedBox(
              decoration: const BoxDecoration(),
              child: new Listener(
                onPointerDown: (_) {
                  log.add('bottom');
                },
                child: new Text('X')
              )
            )
          )
        )
      );

      tester.tap(tester.findText('X'));

      expect(log, equals([
        'bottom',
        'middle',
        'top',
      ]));
    });
  });
}
