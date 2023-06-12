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
          StreamProvider(
            initialData: 0,
            create: (_) => Stream.value(42),
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
    'transition from stream to stream preserve state',
    (tester) async {
      final controller = StreamController<int>(sync: true);
      final controller2 = StreamController<int>(sync: true);

      await tester.pumpWidget(
        StreamProvider.value(
          initialData: 0,
          value: controller.stream,
          child: TextOf<int>(),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      controller.add(1);

      await tester.pump();

      expect(find.text('1'), findsOneWidget);

      await tester.pumpWidget(
        StreamProvider.value(
          initialData: 0,
          value: controller2.stream,
          child: TextOf<int>(),
        ),
      );

      expect(find.text('1'), findsOneWidget);

      controller.add(0);
      await tester.pump();

      expect(find.text('1'), findsOneWidget);

      controller2.add(2);
      await tester.pump();

      expect(find.text('2'), findsOneWidget);

      await tester.pump();
      // ignore: unawaited_futures
      controller.close();
      // ignore: unawaited_futures
      controller2.close();
    },
  );
  testWidgets('throws if stream has error and catchError is missing',
      (tester) async {
    final controller = StreamController<int>();

    await tester.pumpWidget(
      StreamProvider.value(
        initialData: -1,
        value: controller.stream,
        child: TextOf<int>(),
      ),
    );

    controller.addError(42);
    await Future.microtask(tester.pump);

    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    expect(exception.toString(), equals('''
An exception was throw by _ControllerStream<int> listened by
StreamProvider<int>, but no `catchError` was provided.

Exception:
42
'''));

    // ignore: unawaited_futures
    controller.close();
  });

  testWidgets('calls catchError if present and stream has error',
      (tester) async {
    final controller = StreamController<int>(sync: true);
    final catchError = ErrorBuilderMock<int>(0);
    when(catchError(any, 42)).thenReturn(42);

    await tester.pumpWidget(
      StreamProvider.value(
        initialData: -1,
        value: controller.stream,
        catchError: catchError,
        child: TextOf<int>(),
      ),
    );

    expect(find.text('-1'), findsOneWidget);

    controller.addError(42);

    await Future.microtask(tester.pump);

    expect(find.text('42'), findsOneWidget);
    verify(catchError(argThat(isNotNull), 42)).called(1);
    verifyNoMoreInteractions(catchError);

    // ignore: unawaited_futures
    controller.close();
  });

  testWidgets('works with null', (tester) async {
    await tester.pumpWidget(
      StreamProvider<int>.value(
        initialData: 42,
        value: null,
        child: TextOf<int>(),
      ),
    );

    expect(find.text('42'), findsOneWidget);

    await tester.pumpWidget(Container());
  });

  group('StreamProvider()', () {
    testWidgets('create and dispose stream with builder', (tester) async {
      final stream = StreamMock<int>();
      final sub = StreamSubscriptionMock<int>();
      when(stream.listen(any, onError: anyNamed('onError'))).thenReturn(sub);

      final builder = InitialValueBuilderMock(stream);

      await tester.pumpWidget(
        StreamProvider<int>(
          initialData: -1,
          create: builder,
          child: TextOf<int>(),
        ),
      );

      verify(builder(argThat(isNotNull))).called(1);

      verify(stream.listen(any, onError: anyNamed('onError'))).called(1);
      verifyNoMoreInteractions(stream);

      await tester.pumpWidget(Container());

      verifyNoMoreInteractions(builder);
      verify(sub.cancel()).called(1);
      verifyNoMoreInteractions(sub);
      verifyNoMoreInteractions(stream);
    });
  });
}
