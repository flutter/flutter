import 'package:sky/widgets.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

void main() {
  test('Mimic can track tree movements', () {
    GlobalKey globalKey = new GlobalKey();
    WidgetTester tester = new WidgetTester();

    tester.pumpFrame(() {
      return new Flex([
        new Mimicable(
          key: globalKey,
          child: new Container(
            key: new Key.stringify('inner'),
            height: 10.0,
            width: 10.0
          )
        )
      ]);
    });

    bool mimicReady = false;

    tester.pumpFrame(() {
      return new Flex([
        new Mimicable(
          key: globalKey,
          child: new Container(
            height: 10.0,
            width: 10.0
          )
        ),
        new SizedBox(
          height: 10.0,
          width: 10.0,
          child: new Mimic(
            original: globalKey,
            onMimicReady: () {
              mimicReady = true;
            }
          )
        )
      ]);
    });

    expect(mimicReady, isTrue);

    tester.pumpFrame(() {
      return new Flex([
        new Container(
          key: new Key.stringify('outer'),
          height: 10.0,
          width: 10.0,
          child: new Mimicable(
            key: globalKey,
            child: new Container(
              key: new Key.stringify('inner'),
              height: 10.0,
              width: 10.0
            )
          )
        ),
        new SizedBox(
          height: 10.0,
          width: 10.0,
          child: new Mimic(original: globalKey)
        )
      ]);
    });

  });
}
