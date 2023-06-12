import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';

Widget build(int value) => HookBuilder(
      builder: (context) =>
          Text(usePrevious(value).toString(), textDirection: TextDirection.ltr),
    );
void main() {
  group('usePrevious', () {
    testWidgets('default value is null', (tester) async {
      await tester.pumpWidget(build(0));

      expect(find.text('null'), findsOneWidget);
    });
    testWidgets('subsequent build returns previous value', (tester) async {
      await tester.pumpWidget(build(0));
      await tester.pumpWidget(build(1));

      expect(find.text('0'), findsOneWidget);

      await tester.pumpWidget(build(1));

      expect(find.text('1'), findsOneWidget);

      await tester.pumpWidget(build(2));
      expect(find.text('1'), findsOneWidget);

      await tester.pumpWidget(build(3));
      expect(find.text('2'), findsOneWidget);
    });
  });

  testWidgets('debugFillProperties', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        usePrevious(42);
        return const SizedBox();
      }),
    );

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        usePrevious(21);
        return const SizedBox();
      }),
    );

    final element = tester.element(find.byType(HookBuilder));

    expect(
      element
          .toDiagnosticsNode(style: DiagnosticsTreeStyle.offstage)
          .toStringDeep(),
      equalsIgnoringHashCodes(
        'HookBuilder\n'
        ' │ usePrevious: 42\n'
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });
}
