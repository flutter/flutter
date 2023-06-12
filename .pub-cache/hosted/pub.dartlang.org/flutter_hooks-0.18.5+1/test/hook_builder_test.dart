import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('simple build', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        final state = useState(42).value;
        return Text('$state', textDirection: TextDirection.ltr);
      }),
    );

    expect(find.text('42'), findsOneWidget);
  });
}
