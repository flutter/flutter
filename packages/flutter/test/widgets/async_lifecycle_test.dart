import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class InvalidOnInitLifecycleWidget extends StatefulWidget {
  const InvalidOnInitLifecycleWidget({Key key}) : super(key: key);

  @override
  InvalidOnInitLifecycleWidgetState createState() => InvalidOnInitLifecycleWidgetState();
}

class InvalidOnInitLifecycleWidgetState extends State<InvalidOnInitLifecycleWidget> {
  @override
  Future<void> initState() async {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class InvalidDidUpdateWidgetLifecycleWidget extends StatefulWidget {
  const InvalidDidUpdateWidgetLifecycleWidget({Key key, this.id}) : super(key: key);

  final int id;

  @override
  InvalidDidUpdateWidgetLifecycleWidgetState createState() => InvalidDidUpdateWidgetLifecycleWidgetState();
}

class InvalidDidUpdateWidgetLifecycleWidgetState extends State<InvalidDidUpdateWidgetLifecycleWidget> {
  @override
  Future<void> didUpdateWidget(InvalidDidUpdateWidgetLifecycleWidget oldWidget) async {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

void main() {
  testWidgets('async onInit throws FlutterError', (WidgetTester tester) async {
    await tester.pumpWidget(const InvalidOnInitLifecycleWidget());

    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('async didUpdateWidget throws FlutterError', (WidgetTester tester) async {
    await tester.pumpWidget(const InvalidDidUpdateWidgetLifecycleWidget(id: 1));
    await tester.pumpWidget(const InvalidDidUpdateWidgetLifecycleWidget(id: 2));

    expect(tester.takeException(), isFlutterError);
  });
}
