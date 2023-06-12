import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock.dart';

void main() {
  group('useContext', () {
    testWidgets('returns current BuildContext during build', (tester) async {
      late BuildContext res;

      await tester.pumpWidget(HookBuilder(builder: (context) {
        res = useContext();
        return Container();
      }));

      final context = tester.firstElement(find.byType(HookBuilder));

      expect(res, context);
    });

    testWidgets('crashed outside of build', (tester) async {
      expect(useContext, throwsAssertionError);
      await tester.pumpWidget(HookBuilder(
        builder: (context) {
          useContext();
          return Container();
        },
      ));
      expect(useContext, throwsAssertionError);
    });
  });
}
