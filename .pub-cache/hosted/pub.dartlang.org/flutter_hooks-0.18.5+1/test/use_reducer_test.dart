import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('debugFillProperties', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useReducer<int?, int?>(
          (state, action) => 42,
          initialAction: null,
          initialState: null,
        );
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
        ' │ useReducer: 42\n'
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });

  group('useReducer', () {
    testWidgets('supports null initial state', (tester) async {
      Store<Object?, Object?>? store;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            store = useReducer(
              (state, action) => state,
              initialAction: null,
              initialState: null,
            );

            return Container();
          },
        ),
      );

      expect(store!.state, isNull);
    });

    testWidgets('supports null state after dispatch', (tester) async {
      Store<int?, int?>? store;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            store = useReducer(
              (state, action) => action,
              initialAction: 0,
              initialState: null,
            );

            return Container();
          },
        ),
      );

      expect(store?.state, 0);

      store!.dispatch(null);

      expect(store!.state, null);
    });

    testWidgets('initialize the state even "state" is never read',
        (tester) async {
      final reducer = MockReducer();

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            useReducer<int?, String?>(
              reducer,
              initialAction: '',
              initialState: 0,
            );
            return Container();
          },
        ),
      );

      verify(reducer(null, null)).called(1);
      verifyNoMoreInteractions(reducer);
    });

    testWidgets('basic', (tester) async {
      final reducer = MockReducer();

      Store<int?, String?>? store;

      Future<void> pump() {
        return tester.pumpWidget(
          HookBuilder(
            builder: (context) {
              store = useReducer(
                reducer,
                initialAction: null,
                initialState: null,
              );
              return Container();
            },
          ),
        );
      }

      when(reducer(null, null)).thenReturn(0);

      await pump();
      final element = tester.firstElement(find.byType(HookBuilder));

      verify(reducer(null, null)).called(1);
      verifyNoMoreInteractions(reducer);

      expect(store!.state, 0);

      await pump();

      verifyNoMoreInteractions(reducer);
      expect(store!.state, 0);

      when(reducer(0, 'foo')).thenReturn(1);

      store!.dispatch('foo');

      verify(reducer(0, 'foo')).called(1);
      verifyNoMoreInteractions(reducer);
      expect(element.dirty, true);

      await pump();

      when(reducer(1, 'bar')).thenReturn(1);

      store!.dispatch('bar');

      verify(reducer(1, 'bar')).called(1);
      verifyNoMoreInteractions(reducer);
      expect(element.dirty, false);
    });

    testWidgets('dispatch during build works', (tester) async {
      Store<int?, int?>? store;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            store = useReducer<int?, int?>(
              (state, action) => action,
              initialAction: 0,
              initialState: null,
            )..dispatch(42);
            return Container();
          },
        ),
      );

      expect(store!.state, 42);
    });

    testWidgets('first reducer call receive initialAction and initialState',
        (tester) async {
      final reducer = MockReducer();
      when(reducer(0, 'Foo')).thenReturn(42);

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            final result = useReducer<int?, String?>(
              reducer,
              initialAction: 'Foo',
              initialState: 0,
            ).state;
            return Text('$result', textDirection: TextDirection.ltr);
          },
        ),
      );

      expect(find.text('42'), findsOneWidget);
    });
  });
}

class MockReducer extends Mock {
  int? call(int? state, String? action) {
    return super.noSuchMethod(
      Invocation.getter(#call),
      returnValue: 0,
    ) as int?;
  }
}
