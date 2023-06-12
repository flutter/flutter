import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  group('useAppLifecycleState', () {
    testWidgets('returns initial value and rebuild widgets on change',
        (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            final state = useAppLifecycleState();
            return Text('$state', textDirection: TextDirection.ltr);
          },
        ),
      );

      expect(find.text('AppLifecycleState.resumed'), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      expect(find.text('AppLifecycleState.inactive'), findsOneWidget);
    });
  });

  group('useOnAppLifecycleStateChange', () {
    testWidgets(
        'sends previous and new value on change, without rebuilding widgets',
        (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      var buildCount = 0;
      final listener = AppLifecycleStateListener();

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            buildCount++;
            useOnAppLifecycleStateChange(listener);
            return Container();
          },
        ),
      );

      expect(buildCount, 1);
      verifyZeroInteractions(listener);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      expect(buildCount, 1);
      verify(listener(AppLifecycleState.resumed, AppLifecycleState.paused));
      verifyNoMoreInteractions(listener);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(buildCount, 1);
      verify(listener(AppLifecycleState.paused, AppLifecycleState.resumed));
      verifyNoMoreInteractions(listener);
    });
  });
}

class AppLifecycleStateListener extends Mock {
  void call(AppLifecycleState? prev, AppLifecycleState state);
}
