// ignore_for_file: invalid_use_of_protected_member
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'common.dart';

// ignore: prefer_mixin, must_be_immutable
class _ListenableCombined = Combined with ChangeNotifier;

void main() {
  final a = A();
  final b = B();
  final c = C();
  final d = D();
  final e = E();
  final f = F();

  final combinedConsumerMock = MockCombinedBuilder();
  setUp(() => when(combinedConsumerMock(any)).thenReturn(Container()));
  tearDown(() {
    clearInteractions(combinedConsumerMock);
  });

  final mockConsumer = Consumer<_ListenableCombined>(
    builder: (context, combined, child) => combinedConsumerMock(combined),
  );

  group('ListenableProxyProvider', () {
    testWidgets('rebuilds dependendents when listeners are called',
        (tester) async {
      final notifier = ValueNotifier(0);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: 0),
            ListenableProxyProvider<int, ValueNotifier<int>>(
              create: (_) => notifier,
              update: (_, count, value) => value!,
            )
          ],
          child: Consumer<ValueNotifier<int>>(builder: (_, value, __) {
            return Text(
              value.value.toString(),
              textDirection: TextDirection.ltr,
            );
          }),
        ),
      );

      expect(find.text('0'), findsOneWidget);
      expect(find.text('1'), findsNothing);

      notifier.value++;
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets(
      'update returning a new Listenable disposes the previously created value'
      ' and update dependents',
      (tester) async {
        final builder = MockConsumerBuilder<MockNotifier>();
        when(builder(any, any, any)).thenReturn(Container());
        final child = Consumer<MockNotifier>(builder: builder);

        final dispose = DisposeMock<MockNotifier>();
        final notifier = MockNotifier();
        when(notifier.hasListeners).thenReturn(false);
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider.value(value: 0),
              ListenableProxyProvider<int, MockNotifier>(
                update: (_, count, value) => notifier,
                dispose: dispose,
              )
            ],
            child: child,
          ),
        );

        clearInteractions(builder);

        final dispose2 = DisposeMock<MockNotifier>();
        final notifier2 = MockNotifier();
        when(notifier2.hasListeners).thenReturn(false);
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider.value(value: 1),
              ListenableProxyProvider<int, MockNotifier>(
                update: (_, count, value) => notifier2,
                dispose: dispose2,
              )
            ],
            child: child,
          ),
        );

        verify(builder(argThat(isNotNull), notifier2, null)).called(1);
        verifyNoMoreInteractions(builder);
        verify(dispose(argThat(isNotNull), notifier)).called(1);
        verifyNoMoreInteractions(dispose);
        verifyNoMoreInteractions(dispose2);

        await tester.pumpWidget(Container());

        verify(dispose2(argThat(isNotNull), notifier2)).called(1);
        verifyNoMoreInteractions(dispose);
        verifyNoMoreInteractions(dispose2);
      },
    );
    testWidgets('disposes of created value', (tester) async {
      final dispose = DisposeMock<ValueNotifier<int>>();
      final notifier = ValueNotifier(0);
      final key = GlobalKey();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: 0),
            ListenableProxyProvider<int, ValueNotifier<int>>(
              key: key,
              create: (_) => notifier,
              update: (_, count, value) => value!..value = count,
              dispose: dispose,
            )
          ],
          child: TextOf<ValueNotifier<int>>(),
        ),
      );

      verifyZeroInteractions(dispose);

      await tester.pumpWidget(Container());

      verify(dispose(argThat(isNotNull), notifier)).called(1);
      verifyNoMoreInteractions(dispose);
    });
  });

  group('ListenableProxyProvider variants', () {
    InheritedContext<Combined?> findInheritedProvider() =>
        findInheritedContext<Combined>();
    testWidgets('ListenableProxyProvider', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            Provider.value(value: b),
            Provider.value(value: c),
            Provider.value(value: d),
            Provider.value(value: e),
            Provider.value(value: f),
            ListenableProxyProvider0<_ListenableCombined>(
              create: (_) => _ListenableCombined(),
              update: (context, previous) => _ListenableCombined(
                context,
                previous,
                Provider.of<A>(context),
                Provider.of<B>(context),
                Provider.of<C>(context),
                Provider.of<D>(context),
                Provider.of<E>(context),
                Provider.of<F>(context),
              ),
            )
          ],
          child: mockConsumer,
        ),
      );

      final context = findInheritedProvider();

      verify(
        combinedConsumerMock(
          _ListenableCombined(
            context,
            _ListenableCombined(),
            a,
            b,
            c,
            d,
            e,
            f,
          ),
        ),
      ).called(1);
    });

    testWidgets('ListenableProxyProvider2', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            Provider.value(value: b),
            Provider.value(value: c),
            Provider.value(value: d),
            Provider.value(value: e),
            Provider.value(value: f),
            ListenableProxyProvider2<A, B, _ListenableCombined>(
              create: (_) => _ListenableCombined(),
              update: (context, a, b, previous) =>
                  _ListenableCombined(context, previous, a, b),
            )
          ],
          child: mockConsumer,
        ),
      );

      final context = findInheritedProvider();

      verify(
        combinedConsumerMock(
          _ListenableCombined(context, _ListenableCombined(), a, b),
        ),
      ).called(1);
    });

    testWidgets('ListenableProxyProvider3', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            Provider.value(value: b),
            Provider.value(value: c),
            Provider.value(value: d),
            Provider.value(value: e),
            Provider.value(value: f),
            ListenableProxyProvider3<A, B, C, _ListenableCombined>(
              create: (_) => _ListenableCombined(),
              update: (context, a, b, c, previous) =>
                  _ListenableCombined(context, previous, a, b, c),
            )
          ],
          child: mockConsumer,
        ),
      );

      final context = findInheritedProvider();

      verify(
        combinedConsumerMock(
          _ListenableCombined(context, _ListenableCombined(), a, b, c),
        ),
      ).called(1);
    });

    testWidgets('ListenableProxyProvider4', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            Provider.value(value: b),
            Provider.value(value: c),
            Provider.value(value: d),
            Provider.value(value: e),
            Provider.value(value: f),
            ListenableProxyProvider4<A, B, C, D, _ListenableCombined>(
              create: (_) => _ListenableCombined(),
              update: (context, a, b, c, d, previous) =>
                  _ListenableCombined(context, previous, a, b, c, d),
            )
          ],
          child: mockConsumer,
        ),
      );

      final context = findInheritedProvider();

      verify(
        combinedConsumerMock(
          _ListenableCombined(context, _ListenableCombined(), a, b, c, d),
        ),
      ).called(1);
    });

    testWidgets('ListenableProxyProvider5', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            Provider.value(value: b),
            Provider.value(value: c),
            Provider.value(value: d),
            Provider.value(value: e),
            Provider.value(value: f),
            ListenableProxyProvider5<A, B, C, D, E, _ListenableCombined>(
              create: (_) => _ListenableCombined(),
              update: (context, a, b, c, d, e, previous) =>
                  _ListenableCombined(context, previous, a, b, c, d, e),
            )
          ],
          child: mockConsumer,
        ),
      );

      final context = findInheritedProvider();

      verify(
        combinedConsumerMock(
          _ListenableCombined(context, _ListenableCombined(), a, b, c, d, e),
        ),
      ).called(1);
    });

    testWidgets('ListenableProxyProvider6', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            Provider.value(value: b),
            Provider.value(value: c),
            Provider.value(value: d),
            Provider.value(value: e),
            Provider.value(value: f),
            ListenableProxyProvider6<A, B, C, D, E, F, _ListenableCombined>(
              create: (_) => _ListenableCombined(),
              update: (context, a, b, c, d, e, f, previous) =>
                  _ListenableCombined(context, previous, a, b, c, d, e, f),
            )
          ],
          child: mockConsumer,
        ),
      );

      final context = findInheritedProvider();
      verify(
        combinedConsumerMock(
          _ListenableCombined(context, _ListenableCombined(), a, b, c, d, e, f),
        ),
      ).called(1);
    });
  });
}
