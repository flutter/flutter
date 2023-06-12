import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('diagnostics', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useValueNotifier(0);
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
        ' │ useValueNotifier: ValueNotifier<int>#00000(0)\n'
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });

  group('useValueNotifier', () {
    testWidgets('useValueNotifier basic', (tester) async {
      late ValueNotifier<int> state;
      late HookElement element;
      final listener = MockListener();

      await tester.pumpWidget(HookBuilder(
        builder: (context) {
          element = context as HookElement;
          state = useValueNotifier(42);
          return Container();
        },
      ));

      state.addListener(listener);

      expect(state.value, 42);
      expect(element.dirty, false);
      verifyNoMoreInteractions(listener);

      await tester.pump();

      verifyNoMoreInteractions(listener);
      expect(state.value, 42);
      expect(element.dirty, false);

      state.value++;
      verify(listener()).called(1);
      verifyNoMoreInteractions(listener);
      expect(element.dirty, false);
      await tester.pump();

      expect(state.value, 43);
      expect(element.dirty, false);
      verifyNoMoreInteractions(listener);

      // dispose
      await tester.pumpWidget(const SizedBox());

      // ignore: invalid_use_of_protected_member
      expect(() => state.hasListeners, throwsFlutterError);
    });

    testWidgets('no initial data', (tester) async {
      late ValueNotifier<int?> state;
      late HookElement element;
      final listener = MockListener();

      await tester.pumpWidget(HookBuilder(
        builder: (context) {
          element = context as HookElement;
          state = useValueNotifier<int?>(null);
          return Container();
        },
      ));

      state.addListener(listener);

      expect(state.value, null);
      expect(element.dirty, false);
      verifyNoMoreInteractions(listener);

      await tester.pump();

      expect(state.value, null);
      expect(element.dirty, false);
      verifyNoMoreInteractions(listener);

      state.value = 43;
      expect(element.dirty, false);
      verify(listener()).called(1);
      verifyNoMoreInteractions(listener);
      await tester.pump();

      expect(state.value, 43);
      expect(element.dirty, false);
      verifyNoMoreInteractions(listener);

      // dispose
      await tester.pumpWidget(const SizedBox());

      // ignore: invalid_use_of_protected_member
      expect(() => state.hasListeners, throwsFlutterError);
    });

    testWidgets('creates new valuenotifier when key change', (tester) async {
      late ValueNotifier<int> state;
      late ValueNotifier<int> previous;

      await tester.pumpWidget(HookBuilder(
        builder: (context) {
          state = useValueNotifier(42);
          return Container();
        },
      ));

      await tester.pumpWidget(HookBuilder(
        builder: (context) {
          previous = state;
          state = useValueNotifier(42, [42]);
          return Container();
        },
      ));

      expect(state, isNot(previous));
    });
    testWidgets("instance stays the same when keys don't change",
        (tester) async {
      late ValueNotifier<int> state;
      late ValueNotifier<int> previous;

      await tester.pumpWidget(HookBuilder(
        builder: (context) {
          state = useValueNotifier(0, [42]);
          return Container();
        },
      ));

      await tester.pumpWidget(HookBuilder(
        builder: (context) {
          previous = state;
          state = useValueNotifier(42, [42]);
          return Container();
        },
      ));

      expect(state, previous);
    });
  });
}

class MockListener extends Mock {
  void call();
}
