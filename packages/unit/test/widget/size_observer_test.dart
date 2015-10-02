
import 'package:sky/rendering.dart';
import 'package:sky/widgets.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

void main() {
  test('SizeObserver notices zero size', () {
    testWidgets((WidgetTester tester) {
      List results = [];
      tester.pumpWidget(new Center(
        child: new SizeObserver(
          callback: (size) { results.add(size); },
          child: new Container(width:0.0, height:0.0)
        )
      ));
      expect(results, equals([Size.zero]));
      tester.pump();
      expect(results, equals([Size.zero]));
      tester.pumpWidget(new Center(
        child: new SizeObserver(
          callback: (size) { results.add(size); },
          child: new Container(width:100.0, height:0.0)
        )
      ));
      expect(results, equals([Size.zero, const Size(100.0, 0.0)]));
      tester.pump();
      expect(results, equals([Size.zero, const Size(100.0, 0.0)]));
      tester.pumpWidget(new Center(
        child: new SizeObserver(
          callback: (size) { results.add(size); },
          child: new Container(width:0.0, height:0.0)
        )
      ));
      expect(results, equals([Size.zero, const Size(100.0, 0.0), Size.zero]));
      tester.pump();
      expect(results, equals([Size.zero, const Size(100.0, 0.0), Size.zero]));
      tester.pumpWidget(new Center(
        child: new SizeObserver(
          callback: (size) { results.add(size); },
          child: new Container(width:0.0, height:0.0)
        )
      ));
      expect(results, equals([Size.zero, const Size(100.0, 0.0), Size.zero]));
    });
  });
}
