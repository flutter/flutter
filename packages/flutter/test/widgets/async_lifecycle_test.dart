import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class InvalidOnInitLifecycleWidget extends StatefulWidget {
  const InvalidOnInitLifecycleWidget({Key key}) : super(key: key);

  @override
  InvalidOnInitLifecycleWidgetState createState() => new InvalidOnInitLifecycleWidgetState();
}

class InvalidOnInitLifecycleWidgetState extends State<InvalidOnInitLifecycleWidget> {
  @override
  void initState() async {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Container();
  }
}

class InvalidDidUpdateWidgetLifecycleWidget extends StatefulWidget {
  const InvalidDidUpdateWidgetLifecycleWidget({Key key, this.id}) : super(key: key);

  final int id;

  @override
  InvalidDidUpdateWidgetLifecycleWidgetState createState() => new InvalidDidUpdateWidgetLifecycleWidgetState();
}

class InvalidDidUpdateWidgetLifecycleWidgetState extends State<InvalidDidUpdateWidgetLifecycleWidget> {
  @override
  void didUpdateWidget(InvalidDidUpdateWidgetLifecycleWidget oldWidget) async {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return new Container();
  }
}

void main() {
  testWidgets('async onInit throws FlutterError', (WidgetTester tester) async {
    const InvalidOnInitLifecycleWidget invalidWidget = const InvalidOnInitLifecycleWidget();

    await tester.pumpWidget(invalidWidget);

    expect(tester.takeException(), const isInstanceOf<FlutterError>());
  });

  testWidgets('async didUpdateWidget throws FlutterError', (WidgetTester tester) async {
    const InvalidDidUpdateWidgetLifecycleWidget invalidWidget = const InvalidDidUpdateWidgetLifecycleWidget(id: 1);

    await tester.pumpWidget(invalidWidget);

    const InvalidDidUpdateWidgetLifecycleWidget invalidWidgetUpdate = const InvalidDidUpdateWidgetLifecycleWidget(id: 2);

    await tester.pumpWidget(invalidWidgetUpdate);

    expect(tester.takeException(), const isInstanceOf<FlutterError>());
  });
}
