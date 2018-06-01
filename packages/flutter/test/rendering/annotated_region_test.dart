import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class Example extends StatefulWidget {
  const Example();

  @override
  _ExampleState createState() => new _ExampleState();
}

class _ExampleState extends State<Example> {
  @override
  Widget build(BuildContext context) {
    return new ListView.builder(
      itemBuilder: (BuildContext context, int index) {
        return new AnnotatedRegion<bool>(
          value: index.isEven,
          child: new Container(),
        );
      },
      itemCount: 100,
      itemExtent: 100.0,
    );
  }
}



void main() {
  testWidgets('', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: const Example(),
      ),
    );

    final ContainerLayer root = tester.layers.first;

    expect(root.findRegion(const Offset(0.0, 1.0), bool), true);
    expect(root.findRegion(const Offset(0.0, 101.0), bool), false);
    expect(root.findRegion(const Offset(0.0, 201.0), bool), true);
  });
}

