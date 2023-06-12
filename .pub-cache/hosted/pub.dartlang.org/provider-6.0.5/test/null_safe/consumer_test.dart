import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'common.dart';

class ConsumerBuilderMock extends Mock {
  void call(Combined? foo);
}

@immutable
class Combined {
  const Combined(
    this.context,
    this.child,
    this.a, [
    this.b,
    this.c,
    this.d,
    this.e,
    this.f,
  ]);

  final A? a;
  final B? b;
  final C? c;
  final D? d;
  final E? e;
  final F? f;
  final Widget? child;
  final BuildContext? context;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is Combined &&
      other.context == context &&
      other.child == child &&
      other.a == a &&
      other.b == b &&
      other.c == c &&
      other.e == e &&
      other.f == f;
}

void main() {
  final a = A();
  final b = B();
  final c = C();
  final d = D();
  final e = E();
  final f = F();

  final multiProviderNodes = [
    Provider.value(value: a),
    Provider.value(value: b),
    Provider.value(value: c),
    Provider.value(value: d),
    Provider.value(value: e),
    Provider.value(value: f),
  ];

  final mock = ConsumerBuilderMock();
  tearDown(() {
    clearInteractions(mock);
  });

  group('consumer', () {
    testWidgets('obtains value from Provider<T>', (tester) async {
      final key = GlobalKey();
      final child = Container();

      await tester.pumpWidget(
        MultiProvider(
          providers: multiProviderNodes,
          child: Consumer<A>(
            key: key,
            builder: (context, value, child) {
              mock(Combined(context, child, value));
              return Container();
            },
            child: child,
          ),
        ),
      );

      verify(mock(Combined(key.currentContext, child, a)));
    });

    testWidgets('can be used inside MultiProvider', (tester) async {
      final key = GlobalKey();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ...multiProviderNodes,
            Consumer<A>(
              key: key,
              builder: (_, a, child) => Container(child: child),
            )
          ],
          child: const Text('foo', textDirection: TextDirection.ltr),
        ),
      );

      expect(find.text('foo'), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
      expect(key.currentContext, isNotNull);
    });
  });

  group('consumer2', () {
    testWidgets('obtains value from Provider<T>', (tester) async {
      final key = GlobalKey();
      final child = Container();

      await tester.pumpWidget(
        MultiProvider(
          providers: multiProviderNodes,
          child: Consumer2<A, B>(
            key: key,
            builder: (context, value, v2, child) {
              mock(Combined(context, child, value, v2));
              return Container();
            },
            child: child,
          ),
        ),
      );

      verify(mock(Combined(key.currentContext, child, a, b)));
    });

    testWidgets('can be used inside MultiProvider', (tester) async {
      final key = GlobalKey();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ...multiProviderNodes,
            Consumer2<A, B>(
              key: key,
              builder: (_, a, b, child) => Container(child: child),
            )
          ],
          child: const Text('foo', textDirection: TextDirection.ltr),
        ),
      );

      expect(find.text('foo'), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
      expect(key.currentContext, isNotNull);
    });
  });

  group('consumer3', () {
    testWidgets('obtains value from Provider<T>', (tester) async {
      final key = GlobalKey();
      final child = Container();

      await tester.pumpWidget(
        MultiProvider(
          providers: multiProviderNodes,
          child: Consumer3<A, B, C>(
            key: key,
            builder: (context, value, v2, v3, child) {
              mock(Combined(context, child, value, v2, v3));
              return Container();
            },
            child: child,
          ),
        ),
      );

      verify(mock(Combined(key.currentContext, child, a, b, c)));
    });

    testWidgets('can be used inside MultiProvider', (tester) async {
      final key = GlobalKey();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ...multiProviderNodes,
            Consumer3<A, B, C>(
              key: key,
              builder: (_, a, b, c, child) => Container(child: child),
            )
          ],
          child: const Text('foo', textDirection: TextDirection.ltr),
        ),
      );

      expect(find.text('foo'), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
      expect(key.currentContext, isNotNull);
    });
  });

  group('consumer4', () {
    testWidgets('obtains value from Provider<T>', (tester) async {
      final key = GlobalKey();
      final child = Container();

      await tester.pumpWidget(
        MultiProvider(
          providers: multiProviderNodes,
          child: Consumer4<A, B, C, D>(
            key: key,
            builder: (context, value, v2, v3, v4, child) {
              mock(Combined(context, child, value, v2, v3, v4));
              return Container();
            },
            child: child,
          ),
        ),
      );

      verify(mock(Combined(key.currentContext, child, a, b, c, d)));
    });

    testWidgets('can be used inside MultiProvider', (tester) async {
      final key = GlobalKey();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ...multiProviderNodes,
            Consumer4<A, B, C, D>(
              key: key,
              builder: (_, a, b, c, d, child) => Container(child: child),
            )
          ],
          child: const Text('foo', textDirection: TextDirection.ltr),
        ),
      );

      expect(find.text('foo'), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
      expect(key.currentContext, isNotNull);
    });
  });

  group('consumer5', () {
    testWidgets('obtains value from Provider<T>', (tester) async {
      final key = GlobalKey();
      final child = Container();

      await tester.pumpWidget(
        MultiProvider(
          providers: multiProviderNodes,
          child: Consumer5<A, B, C, D, E>(
            key: key,
            builder: (context, value, v2, v3, v4, v5, child) {
              mock(Combined(context, child, value, v2, v3, v4, v5));
              return Container();
            },
            child: child,
          ),
        ),
      );

      verify(mock(Combined(key.currentContext, child, a, b, c, d, e)));
    });

    testWidgets('can be used inside MultiProvider', (tester) async {
      final key = GlobalKey();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ...multiProviderNodes,
            Consumer5<A, B, C, D, E>(
              key: key,
              builder: (_, a, b, c, d, e, child) => Container(child: child),
            )
          ],
          child: const Text('foo', textDirection: TextDirection.ltr),
        ),
      );

      expect(find.text('foo'), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
      expect(key.currentContext, isNotNull);
    });
  });

  group('consumer6', () {
    testWidgets('obtains value from Provider<T>', (tester) async {
      final key = GlobalKey();
      final child = Container();

      await tester.pumpWidget(
        MultiProvider(
          providers: multiProviderNodes,
          child: Consumer6<A, B, C, D, E, F>(
            key: key,
            builder: (context, value, v2, v3, v4, v5, v6, child) {
              mock(Combined(context, child, value, v2, v3, v4, v5, v6));
              return Container();
            },
            child: child,
          ),
        ),
      );

      verify(mock(Combined(key.currentContext, child, a, b, c, d, e, f)));
    });

    testWidgets('can be used inside MultiProvider', (tester) async {
      final key = GlobalKey();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ...multiProviderNodes,
            Consumer6<A, B, C, D, E, F>(
              key: key,
              builder: (_, a, b, c, d, e, f, child) => Container(child: child),
            )
          ],
          child: const Text('foo', textDirection: TextDirection.ltr),
        ),
      );

      expect(find.text('foo'), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
      expect(key.currentContext, isNotNull);
    });
  });
}
