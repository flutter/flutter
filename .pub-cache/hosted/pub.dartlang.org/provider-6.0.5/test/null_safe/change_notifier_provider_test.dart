import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'common.dart';

void main() {
  group('ChangeNotifierProvider', () {
    testWidgets('value', (tester) async {
      final myNotifier = ValueNotifier<int>(0);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: myNotifier),
          ],
          child: Consumer<ValueNotifier<int>>(
            builder: (_, value, __) {
              return Text(
                value.value.toString(),
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      myNotifier.value++;
      await tester.pump();

      expect(find.text('1'), findsOneWidget);

      await tester.pumpWidget(Container());

      // would throw if myNotifier is disposed
      myNotifier.notifyListeners();
    });

    testWidgets('builder', (tester) async {
      final myNotifier = ValueNotifier<int>(0);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => myNotifier),
          ],
          child: Consumer<ValueNotifier<int>>(
            builder: (_, value, __) {
              return Text(
                value.value.toString(),
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      myNotifier.value++;
      await tester.pump();

      expect(find.text('1'), findsOneWidget);

      await tester.pumpWidget(Container());

      expect(myNotifier.notifyListeners, throwsAssertionError);
    });

    testWidgets('builder1', (tester) async {
      final myNotifier = ValueNotifier<int>(0);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider(create: (_) => A()),
            ChangeNotifierProxyProvider<A, ValueNotifier<int>?>(
              create: (_) => null,
              update: (_, __, ___) => myNotifier,
            ),
          ],
          child: Consumer<ValueNotifier<int>?>(
            builder: (_, value, __) {
              return Text(
                value!.value.toString(),
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      myNotifier.value++;
      await tester.pump();

      expect(find.text('1'), findsOneWidget);

      await tester.pumpWidget(Container());

      expect(myNotifier.notifyListeners, throwsAssertionError);
    });

    testWidgets('builder2', (tester) async {
      final myNotifier = ValueNotifier<int>(0);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider(create: (_) => A()),
            Provider(create: (_) => B()),
            ChangeNotifierProxyProvider2<A, B, ValueNotifier<int>?>(
              create: (_) => null,
              update: (_, _a, _b, ___) => myNotifier,
            ),
          ],
          child: Consumer<ValueNotifier<int>?>(
            builder: (_, value, __) {
              return Text(
                value!.value.toString(),
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      myNotifier.value++;
      await tester.pump();

      expect(find.text('1'), findsOneWidget);

      await tester.pumpWidget(Container());

      expect(myNotifier.notifyListeners, throwsAssertionError);
    });

    testWidgets('builder3', (tester) async {
      final myNotifier = ValueNotifier<int>(0);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider(create: (_) => A()),
            Provider(create: (_) => B()),
            Provider(create: (_) => C()),
            ChangeNotifierProxyProvider3<A, B, C, ValueNotifier<int>?>(
              create: (_) => null,
              update: (_, _a, _b, _c, ___) => myNotifier,
            ),
          ],
          child: Consumer<ValueNotifier<int>?>(
            builder: (_, value, __) {
              return Text(
                value!.value.toString(),
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      myNotifier.value++;
      await tester.pump();

      expect(find.text('1'), findsOneWidget);

      await tester.pumpWidget(Container());

      expect(myNotifier.notifyListeners, throwsAssertionError);
    });

    testWidgets('builder4', (tester) async {
      final myNotifier = ValueNotifier<int>(0);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider(create: (_) => A()),
            Provider(create: (_) => B()),
            Provider(create: (_) => C()),
            Provider(create: (_) => D()),
            ChangeNotifierProxyProvider4<A, B, C, D, ValueNotifier<int>?>(
              create: (_) => null,
              update: (_, _a, _b, _c, _d, ___) => myNotifier,
            ),
          ],
          child: Consumer<ValueNotifier<int>?>(
            builder: (_, value, __) {
              return Text(
                value!.value.toString(),
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      myNotifier.value++;
      await tester.pump();

      expect(find.text('1'), findsOneWidget);

      await tester.pumpWidget(Container());

      expect(myNotifier.notifyListeners, throwsAssertionError);
    });

    testWidgets('builder5', (tester) async {
      final myNotifier = ValueNotifier<int>(0);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider(create: (_) => A()),
            Provider(create: (_) => B()),
            Provider(create: (_) => C()),
            Provider(create: (_) => D()),
            Provider(create: (_) => E()),
            ChangeNotifierProxyProvider5<A, B, C, D, E, ValueNotifier<int>?>(
              create: (_) => null,
              update: (_, _a, _b, _c, _d, _e, ___) => myNotifier,
            ),
          ],
          child: Consumer<ValueNotifier<int>?>(
            builder: (_, value, __) {
              return Text(
                value!.value.toString(),
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      myNotifier.value++;
      await tester.pump();

      expect(find.text('1'), findsOneWidget);

      await tester.pumpWidget(Container());

      expect(myNotifier.notifyListeners, throwsAssertionError);
    });

    testWidgets('builder6', (tester) async {
      final myNotifier = ValueNotifier<int>(0);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider(create: (_) => A()),
            Provider(create: (_) => B()),
            Provider(create: (_) => C()),
            Provider(create: (_) => D()),
            Provider(create: (_) => E()),
            Provider(create: (_) => F()),
            ChangeNotifierProxyProvider6<A, B, C, D, E, F, ValueNotifier<int>?>(
              create: (_) => null,
              update: (_, _a, _b, _c, _d, _e, _f, ___) => myNotifier,
            ),
          ],
          child: Consumer<ValueNotifier<int>?>(
            builder: (_, value, __) {
              return Text(
                value!.value.toString(),
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      myNotifier.value++;
      await tester.pump();

      expect(find.text('1'), findsOneWidget);

      await tester.pumpWidget(Container());

      expect(myNotifier.notifyListeners, throwsAssertionError);
    });

    testWidgets('builder0', (tester) async {
      final myNotifier = ValueNotifier<int>(0);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProxyProvider0<ValueNotifier<int>?>(
              create: (_) => null,
              update: (_, ___) => myNotifier,
            ),
          ],
          child: Consumer<ValueNotifier<int>?>(
            builder: (_, value, __) {
              return Text(
                value!.value.toString(),
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      myNotifier.value++;
      await tester.pump();

      expect(find.text('1'), findsOneWidget);

      await tester.pumpWidget(Container());

      expect(myNotifier.notifyListeners, throwsAssertionError);
    });
  });

  testWidgets('Use builder property, not child', (tester) async {
    final myNotifier = ValueNotifier<int>(0);

    await tester.pumpWidget(
      ChangeNotifierProvider<ValueNotifier<int>>(
        create: (context) => myNotifier,
        builder: (context, _) {
          final notifier = context.watch<ValueNotifier<int>>();
          return Text(
            '${notifier.value}',
            textDirection: TextDirection.ltr,
          );
        },
      ),
    );

    expect(find.text('0'), findsOneWidget);

    myNotifier.value++;
    await tester.pump();

    expect(find.text('1'), findsOneWidget);

    await tester.pumpWidget(Container());

    expect(myNotifier.notifyListeners, throwsAssertionError);
  });
}
