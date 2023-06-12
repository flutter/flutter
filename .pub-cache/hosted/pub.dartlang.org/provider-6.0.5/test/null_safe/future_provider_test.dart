import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'common.dart';

class ErrorBuilderMock<T> extends Mock {
  ErrorBuilderMock(this.fallback);

  final T fallback;

  T call(BuildContext? context, Object? error) {
    return super.noSuchMethod(
      Invocation.method(#call, [context, error]),
      returnValue: fallback,
      returnValueForMissingStub: fallback,
    ) as T;
  }
}

void main() {
  testWidgets('works with MultiProvider', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          FutureProvider.value(
            initialData: 0,
            value: Future.value(42),
          ),
        ],
        child: TextOf<int>(),
      ),
    );

    expect(find.text('0'), findsOneWidget);

    await Future.microtask(tester.pump);

    expect(find.text('42'), findsOneWidget);
  });

  testWidgets(
    '(catchError) previous future completes after transition is no-op',
    (tester) async {
      final controller = Completer<int>();
      final controller2 = Completer<int>();

      await tester.pumpWidget(
        FutureProvider.value(
          initialData: 0,
          value: controller.future,
          child: TextOf<int>(),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      await tester.pumpWidget(
        FutureProvider.value(
          initialData: 1,
          value: controller2.future,
          child: TextOf<int>(),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      controller.complete(1);
      await Future.microtask(tester.pump);

      expect(find.text('0'), findsOneWidget);

      controller2.complete(2);

      await Future.microtask(tester.pump);

      expect(find.text('0'), findsNothing);
      expect(find.text('2'), findsOneWidget);
    },
  );
  testWidgets(
    'previous future completes after transition is no-op',
    (tester) async {
      final controller = Completer<int>();
      final controller2 = Completer<int>();

      await tester.pumpWidget(
        FutureProvider.value(
          initialData: 0,
          value: controller.future,
          child: TextOf<int>(),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      await tester.pumpWidget(
        FutureProvider.value(
          initialData: 1,
          value: controller2.future,
          child: TextOf<int>(),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      controller.complete(1);
      await Future.microtask(tester.pump);

      expect(find.text('0'), findsOneWidget);

      controller2.complete(2);
      await Future.microtask(tester.pump);

      expect(find.text('2'), findsOneWidget);
    },
  );
  testWidgets(
    'transition from future to future preserve state',
    (tester) async {
      final controller = Completer<int>();
      final controller2 = Completer<int>();

      await tester.pumpWidget(
        FutureProvider.value(
          initialData: 0,
          value: controller.future,
          child: TextOf<int>(),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      controller.complete(1);

      await Future.microtask(tester.pump);

      expect(find.text('1'), findsOneWidget);

      await tester.pumpWidget(
        FutureProvider.value(
          initialData: 0,
          value: controller2.future,
          child: TextOf<int>(),
        ),
      );

      expect(find.text('1'), findsOneWidget);

      controller2.complete(2);
      await Future.microtask(tester.pump);

      expect(find.text('2'), findsOneWidget);
    },
  );
  testWidgets('throws if future has error and catchError is missing',
      (tester) async {
    final controller = Completer<int>();

    await tester.pumpWidget(
      FutureProvider.value(
        initialData: 0,
        value: controller.future,
        child: TextOf<int>(),
      ),
    );

    controller.completeError(42);
    await Future.microtask(tester.pump);

    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    expect(exception.toString(), equals('''
An exception was throw by Future<int> listened by
FutureProvider<int>, but no `catchError` was provided.

Exception:
42
'''));
  });

  testWidgets('calls catchError if present and future has error',
      (tester) async {
    final controller = Completer<int>();
    final catchError = ErrorBuilderMock<int>(0);
    when(catchError(any, 42)).thenReturn(42);

    await tester.pumpWidget(
      FutureProvider.value(
        initialData: null,
        value: controller.future,
        catchError: catchError,
        child: TextOf<int?>(),
      ),
    );

    expect(find.text('null'), findsOneWidget);

    controller.completeError(42);

    await Future.microtask(tester.pump);

    expect(find.text('42'), findsOneWidget);
    verify(catchError(argThat(isNotNull), 42)).called(1);
    verifyNoMoreInteractions(catchError);
  });

  testWidgets('works with null', (tester) async {
    await tester.pumpWidget(
      FutureProvider<int>.value(
        initialData: 42,
        value: null,
        child: TextOf<int>(),
      ),
    );

    expect(find.text('42'), findsOneWidget);

    await tester.pumpWidget(Container());
  });

  testWidgets('create and dispose future with builder', (tester) async {
    final completer = Completer<int>();

    await tester.pumpWidget(
      FutureProvider<int>(
        initialData: 42,
        create: (_) => completer.future,
        child: TextOf<int>(),
      ),
    );

    expect(find.text('42'), findsOneWidget);

    completer.complete(24);

    await Future.microtask(tester.pump);

    expect(find.text('24'), findsOneWidget);
  });
}
