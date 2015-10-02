import 'package:sky/rendering.dart';
import 'package:sky/widgets.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

void main() {
  test('AnimatedContainer control test', () {
    testWidgets((WidgetTester tester) {
      GlobalKey key = new GlobalKey();

      BoxDecoration decorationA = new BoxDecoration(
        backgroundColor: new Color(0xFF00FF00)
      );

      BoxDecoration decorationB = new BoxDecoration(
        backgroundColor: new Color(0xFF0000FF)
      );

      tester.pumpWidget(
        new AnimatedContainer(
          key: key,
          duration: const Duration(milliseconds: 200),
          decoration: decorationA
        )
      );

      RenderDecoratedBox box = key.currentState.context.findRenderObject();
      expect(box.decoration.backgroundColor, equals(decorationA.backgroundColor));

      tester.pumpWidget(
        new AnimatedContainer(
          key: key,
          duration: const Duration(milliseconds: 200),
          decoration: decorationB
        )
      );

      expect(key.currentState.context.findRenderObject(), equals(box));
      expect(box.decoration.backgroundColor, equals(decorationA.backgroundColor));

      tester.pump(const Duration(seconds: 1));

      expect(box.decoration.backgroundColor, equals(decorationB.backgroundColor));

    });
  });
}
