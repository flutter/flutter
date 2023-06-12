import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'common.dart';

Finder findProvider<T>() => find.byWidgetPredicate(
    // comparing `runtimeType` instead of using `is` because `is` accepts
    // subclasses but InheritedWidgets don't.
    (widget) => widget.runtimeType == typeOf<InheritedProvider<T>>());

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

  final mockConsumer = Consumer<Combined>(
    builder: (context, combined, child) => combinedConsumerMock(combined),
  );

  InheritedContext<Combined?> findProxyProvider() =>
      findInheritedContext<Combined>();

  group('ProxyProvider', () {
    final combiner = CombinerMock();
    setUp(() {
      when(combiner(any, any, any)).thenAnswer((Invocation invocation) {
        return Combined(
          invocation.positionalArguments.first as BuildContext,
          invocation.positionalArguments[2] as Combined?,
          invocation.positionalArguments[1] as A,
        );
      });
    });
    tearDown(() => clearInteractions(combiner));

    testWidgets('throws if the provided value is a Listenable/Stream',
        (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            ProxyProvider<A, MyListenable>(
              update: (_, __, ___) => MyListenable(),
            )
          ],
          child: TextOf<MyListenable>(),
        ),
      );

      expect(tester.takeException(), isFlutterError);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            ProxyProvider<A, MyStream>(
              update: (_, __, ___) => MyStream(),
            )
          ],
          child: TextOf<MyStream>(),
        ),
      );

      expect(tester.takeException(), isFlutterError);
    });

    testWidgets('debugCheckInvalidValueType can be disabled', (tester) async {
      final previous = Provider.debugCheckInvalidValueType;
      Provider.debugCheckInvalidValueType = null;
      addTearDown(() => Provider.debugCheckInvalidValueType = previous);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            ProxyProvider<A, MyListenable>(
              update: (_, __, ___) => MyListenable(),
            )
          ],
          child: TextOf<MyListenable>(),
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            ProxyProvider<A, MyStream>(
              update: (_, __, ___) => MyStream(),
            )
          ],
          child: TextOf<MyStream>(),
        ),
      );
    });

    testWidgets('create creates initial value', (tester) async {
      final create = InitialValueBuilderMock<Combined>(const Combined());

      when(create(any)).thenReturn(const Combined());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            ProxyProvider<A, Combined>(
              create: create,
              update: combiner,
            )
          ],
          child: mockConsumer,
        ),
      );

      verify(create(argThat(isNotNull))).called(1);

      verify(combiner(argThat(isNotNull), a, const Combined()));
    });

    testWidgets('consume another providers', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            ProxyProvider<A, Combined>(
              update: combiner,
            )
          ],
          child: mockConsumer,
        ),
      );

      final context = findProxyProvider();

      verify(combinedConsumerMock(Combined(context, null, a))).called(1);
      verifyNoMoreInteractions(combinedConsumerMock);

      verify(combiner(context, a, null)).called(1);
      verifyNoMoreInteractions(combiner);
    });

    testWidgets('rebuild descendants if value change', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            ProxyProvider<A, Combined>(
              update: combiner,
            )
          ],
          child: mockConsumer,
        ),
      );

      final a2 = A();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a2),
            ProxyProvider<A, Combined>(
              update: combiner,
            )
          ],
          child: mockConsumer,
        ),
      );
      final context = findProxyProvider();

      verifyInOrder([
        combiner(context, a, null),
        combinedConsumerMock(Combined(context, null, a)),
        combiner(context, a2, Combined(context, null, a)),
        combinedConsumerMock(Combined(context, Combined(context, null, a), a2)),
      ]);

      verifyNoMoreInteractions(combiner);
      verifyNoMoreInteractions(combinedConsumerMock);
    });

    testWidgets('call dispose when unmounted with the latest result',
        (tester) async {
      final dispose = DisposeMock<Combined>();
      final dispose2 = DisposeMock<Combined>();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            ProxyProvider<A, Combined>(update: combiner, dispose: dispose),
          ],
          child: mockConsumer,
        ),
      );

      final a2 = A();

      // ProxyProvider creates a new Combined instance
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a2),
            ProxyProvider<A, Combined>(update: combiner, dispose: dispose2),
          ],
          child: mockConsumer,
        ),
      );
      final context = findProxyProvider();

      verify(
        dispose(context, Combined(context, null, a)),
      );

      await tester.pumpWidget(Container());

      verify(
        dispose2(context, Combined(context, Combined(context, null, a), a2)),
      );
      verifyNoMoreInteractions(dispose);
    });

    testWidgets("don't rebuild descendants if value doesn't change",
        (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            ProxyProvider<A, Combined>(
              update: (c, a, p) => combiner(c, a, null),
            )
          ],
          child: mockConsumer,
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(
              value: a,
              updateShouldNotify: (A _, A __) => true,
            ),
            ProxyProvider<A, Combined>(
              update: (c, a, p) {
                combiner(c, a, p);
                return p!;
              },
            )
          ],
          child: mockConsumer,
        ),
      );
      final context = findProxyProvider();

      verifyInOrder([
        combiner(context, a, null),
        combinedConsumerMock(Combined(context, null, a)),
        combiner(context, a, Combined(context, null, a)),
      ]);

      verifyNoMoreInteractions(combiner);
      verifyNoMoreInteractions(combinedConsumerMock);
    });

    testWidgets('pass down updateShouldNotify', (tester) async {
      var buildCount = 0;
      final child = Builder(builder: (context) {
        buildCount++;

        return Text(
          '$buildCount ${Provider.of<String>(context)}',
          textDirection: TextDirection.ltr,
        );
      });

      final shouldNotify = UpdateShouldNotifyMock<String>();
      when(shouldNotify('Hello', 'Hello')).thenReturn(false);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<String>.value(
                value: 'Hello', updateShouldNotify: (_, __) => true),
            ProxyProvider<String, String>(
              update: (_, value, __) => value,
              updateShouldNotify: shouldNotify,
            ),
          ],
          child: child,
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<String>.value(
                value: 'Hello', updateShouldNotify: (_, __) => true),
            ProxyProvider<String, String>(
              update: (_, value, __) => value,
              updateShouldNotify: shouldNotify,
            ),
          ],
          child: child,
        ),
      );

      verify(shouldNotify('Hello', 'Hello')).called(1);
      verifyNoMoreInteractions(shouldNotify);

      expect(find.text('2 Hello'), findsNothing);
      expect(find.text('1 Hello'), findsOneWidget);
    });

    testWidgets('works with MultiProvider', (tester) async {
      final key = GlobalKey();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            ProxyProvider<A, Combined>(update: (c, a, p) => Combined(c, p, a)),
          ],
          child: Container(key: key),
        ),
      );
      final context = findProxyProvider();

      expect(
        Provider.of<Combined>(key.currentContext!, listen: false),
        Combined(context, null, a),
      );
    });

    // useful for libraries such as Mobx where events are synchronously
    // dispatched
    testWidgets(
        'update callback can trigger descendants setState synchronously',
        (tester) async {
      var statefulBuildCount = 0;
      void Function(VoidCallback)? setState;

      final statefulBuilder = StatefulBuilder(builder: (context, s) {
        // force update to be called
        Provider.of<Combined>(context, listen: false);

        setState = s;
        statefulBuildCount++;
        return Container();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            ProxyProvider<A, Combined>(update: (c, a, p) => Combined(c, p, a)),
          ],
          child: statefulBuilder,
        ),
      );

      expect(
        statefulBuildCount,
        1,
        reason: 'update must not be called asynchronously',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: A()),
            ProxyProvider<A, Combined>(update: (c, a, p) {
              setState!(() {});
              return Combined(c, p, a);
            }),
          ],
          child: statefulBuilder,
        ),
      );

      expect(
        statefulBuildCount,
        2,
        reason: 'update must not be called asynchronously',
      );
    });
  });

  group('ProxyProvider variants', () {
    testWidgets('ProxyProvider2', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            Provider.value(value: b),
            Provider.value(value: c),
            Provider.value(value: d),
            Provider.value(value: e),
            Provider.value(value: f),
            ProxyProvider2<A, B, Combined>(
              create: (_) => const Combined(),
              update: (context, a, b, previous) =>
                  Combined(context, previous, a, b),
            )
          ],
          child: mockConsumer,
        ),
      );

      final context = findProxyProvider();

      verify(
        combinedConsumerMock(
          Combined(context, const Combined(), a, b),
        ),
      ).called(1);
    });

    testWidgets('ProxyProvider3', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            Provider.value(value: b),
            Provider.value(value: c),
            Provider.value(value: d),
            Provider.value(value: e),
            Provider.value(value: f),
            ProxyProvider3<A, B, C, Combined>(
              create: (_) => const Combined(),
              update: (context, a, b, c, previous) =>
                  Combined(context, previous, a, b, c),
            )
          ],
          child: mockConsumer,
        ),
      );

      final context = findProxyProvider();

      verify(
        combinedConsumerMock(
          Combined(context, const Combined(), a, b, c),
        ),
      ).called(1);
    });

    testWidgets('ProxyProvider4', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            Provider.value(value: b),
            Provider.value(value: c),
            Provider.value(value: d),
            Provider.value(value: e),
            Provider.value(value: f),
            ProxyProvider4<A, B, C, D, Combined>(
              create: (_) => const Combined(),
              update: (context, a, b, c, d, previous) =>
                  Combined(context, previous, a, b, c, d),
            )
          ],
          child: mockConsumer,
        ),
      );

      final context = findProxyProvider();

      verify(
        combinedConsumerMock(
          Combined(context, const Combined(), a, b, c, d),
        ),
      ).called(1);
    });

    testWidgets('ProxyProvider5', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            Provider.value(value: b),
            Provider.value(value: c),
            Provider.value(value: d),
            Provider.value(value: e),
            Provider.value(value: f),
            ProxyProvider5<A, B, C, D, E, Combined>(
              create: (_) => const Combined(),
              update: (context, a, b, c, d, e, previous) =>
                  Combined(context, previous, a, b, c, d, e),
            )
          ],
          child: mockConsumer,
        ),
      );

      final context = findProxyProvider();

      verify(
        combinedConsumerMock(
          Combined(context, const Combined(), a, b, c, d, e),
        ),
      ).called(1);
    });

    testWidgets('ProxyProvider6', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: a),
            Provider.value(value: b),
            Provider.value(value: c),
            Provider.value(value: d),
            Provider.value(value: e),
            Provider.value(value: f),
            ProxyProvider6<A, B, C, D, E, F, Combined>(
              create: (_) => const Combined(),
              update: (context, a, b, c, d, e, f, previous) =>
                  Combined(context, previous, a, b, c, d, e, f),
            )
          ],
          child: mockConsumer,
        ),
      );

      final context = findProxyProvider();

      verify(
        combinedConsumerMock(
          Combined(context, const Combined(), a, b, c, d, e, f),
        ),
      ).called(1);
    });
  });
}
