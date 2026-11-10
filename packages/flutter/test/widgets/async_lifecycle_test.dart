// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

class InvalidOnInitLifecycleWidget extends StatefulWidget {
  const InvalidOnInitLifecycleWidget({super.key});

  @override
  InvalidOnInitLifecycleWidgetState createState() => InvalidOnInitLifecycleWidgetState();
}

class InvalidOnInitLifecycleWidgetState extends State<InvalidOnInitLifecycleWidget> {
  @override
  Future<void> initState() async {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class InvalidDidUpdateWidgetLifecycleWidget extends StatefulWidget {
  const InvalidDidUpdateWidgetLifecycleWidget({super.key, required this.color});

  final Color color;

  @override
  InvalidDidUpdateWidgetLifecycleWidgetState createState() =>
      InvalidDidUpdateWidgetLifecycleWidgetState();
}

class InvalidDidUpdateWidgetLifecycleWidgetState
    extends State<InvalidDidUpdateWidgetLifecycleWidget> {
  @override
  Future<void> didUpdateWidget(InvalidDidUpdateWidgetLifecycleWidget oldWidget) async {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: widget.color);
  }
}

class AsyncDisposeAfterAwaitWidget extends StatefulWidget {
  const AsyncDisposeAfterAwaitWidget({super.key});

  @override
  AsyncDisposeAfterAwaitWidgetState createState() => AsyncDisposeAfterAwaitWidgetState();
}

class AsyncDisposeAfterAwaitWidgetState extends State<AsyncDisposeAfterAwaitWidget> {
  @override
  Future<void> dispose() async {
    await Future<void>.value();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class VoidAsyncDisposeAfterAwaitWidget extends StatefulWidget {
  const VoidAsyncDisposeAfterAwaitWidget({super.key});

  @override
  VoidAsyncDisposeAfterAwaitWidgetState createState() => VoidAsyncDisposeAfterAwaitWidgetState();
}

class VoidAsyncDisposeAfterAwaitWidgetState extends State<VoidAsyncDisposeAfterAwaitWidget> {
  @override
  // Tests a dispose() that is declared to return void but is marked async.
  // Even though its return type is void, it still returns a Future at runtime.
  // ignore: avoid_void_async
  void dispose() async {
    await Future<void>.value();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class SyncDisposeWithoutSuperWidget extends StatefulWidget {
  const SyncDisposeWithoutSuperWidget({super.key});

  @override
  SyncDisposeWithoutSuperWidgetState createState() => SyncDisposeWithoutSuperWidgetState();
}

class SyncDisposeWithoutSuperWidgetState extends State<SyncDisposeWithoutSuperWidget> {
  bool skipSuperDispose = true;

  @override
  void dispose() {
    // Returns early so that super.dispose() is never called.
    if (skipSuperDispose) {
      return;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class AsyncDisposeBeforeAwaitWidget extends StatefulWidget {
  const AsyncDisposeBeforeAwaitWidget({super.key});

  @override
  AsyncDisposeBeforeAwaitWidgetState createState() => AsyncDisposeBeforeAwaitWidgetState();
}

class AsyncDisposeBeforeAwaitWidgetState extends State<AsyncDisposeBeforeAwaitWidget> {
  @override
  Future<void> dispose() async {
    super.dispose();
    await Future<void>.value();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class VoidAsyncDisposeBeforeAwaitWidget extends StatefulWidget {
  const VoidAsyncDisposeBeforeAwaitWidget({super.key});

  @override
  VoidAsyncDisposeBeforeAwaitWidgetState createState() => VoidAsyncDisposeBeforeAwaitWidgetState();
}

class VoidAsyncDisposeBeforeAwaitWidgetState extends State<VoidAsyncDisposeBeforeAwaitWidget> {
  @override
  // Tests a dispose() that is declared to return void but is marked async,
  // and calls super.dispose() before the first await.
  // ignore: avoid_void_async
  void dispose() async {
    super.dispose();
    await Future<void>.value();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

String _asyncDisposeErrorMessage(String stateType) {
  return '$stateType.dispose failed to call super.dispose.\n'
      'dispose() implementations must always call their superclass dispose() method, to '
      'ensure that all the resources used by the widget are fully released.\n'
      '$stateType.dispose() returned a Future, but the framework does not await '
      'dispose(), so super.dispose() must be called synchronously, not after an await. '
      'Consider making dispose() synchronous and starting any asynchronous cleanup '
      'without awaiting it.';
}

void main() {
  const red = Color(0xffff0000);
  const green = Color(0xff00ff00);

  testWidgets(
    'async onInit throws FlutterError',
    experimentalLeakTesting: LeakTesting.settings
        .withIgnoredAll(), // leaking by design because of exception
    (WidgetTester tester) async {
      await tester.pumpWidget(const InvalidOnInitLifecycleWidget());

      expect(tester.takeException(), isFlutterError);
    },
  );

  testWidgets(
    'async didUpdateWidget throws FlutterError',
    experimentalLeakTesting: LeakTesting.settings
        .withIgnoredAll(), // leaking by design because of exception
    (WidgetTester tester) async {
      await tester.pumpWidget(const InvalidDidUpdateWidgetLifecycleWidget(color: green));
      await tester.pumpWidget(const InvalidDidUpdateWidgetLifecycleWidget(color: red));

      expect(tester.takeException(), isFlutterError);
    },
  );

  testWidgets(
    'async dispose that calls super.dispose after an await throws FlutterError',
    experimentalLeakTesting: LeakTesting.settings
        .withIgnoredAll(), // leaking by design because of exception
    (WidgetTester tester) async {
      await tester.pumpWidget(const AsyncDisposeAfterAwaitWidget());

      // Removing the widget calls dispose(), which returns before it reaches
      // super.dispose() because of the await.
      await tester.pumpWidget(Container());

      expect(
        tester.takeException(),
        isA<FlutterError>().having(
          (FlutterError error) => error.toString(),
          'message',
          _asyncDisposeErrorMessage('AsyncDisposeAfterAwaitWidgetState'),
        ),
      );
    },
  );

  testWidgets(
    'void async dispose that calls super.dispose after an await throws FlutterError',
    experimentalLeakTesting: LeakTesting.settings
        .withIgnoredAll(), // leaking by design because of exception
    (WidgetTester tester) async {
      await tester.pumpWidget(const VoidAsyncDisposeAfterAwaitWidget());
      await tester.pumpWidget(Container());

      expect(
        tester.takeException(),
        isA<FlutterError>().having(
          (FlutterError error) => error.toString(),
          'message',
          _asyncDisposeErrorMessage('VoidAsyncDisposeAfterAwaitWidgetState'),
        ),
      );
    },
  );

  testWidgets(
    'sync dispose that does not call super.dispose throws FlutterError without the async hint',
    experimentalLeakTesting: LeakTesting.settings
        .withIgnoredAll(), // leaking by design because of exception
    (WidgetTester tester) async {
      await tester.pumpWidget(const SyncDisposeWithoutSuperWidget());
      await tester.pumpWidget(Container());

      expect(
        tester.takeException(),
        isA<FlutterError>().having(
          (FlutterError error) => error.toString(),
          'message',
          'SyncDisposeWithoutSuperWidgetState.dispose failed to call super.dispose.\n'
              'dispose() implementations must always call their superclass dispose() method, to '
              'ensure that all the resources used by the widget are fully released.',
        ),
      );
    },
  );

  testWidgets('async dispose that calls super.dispose before an await does not throw', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AsyncDisposeBeforeAwaitWidget());
    await tester.pumpWidget(Container());

    expect(tester.takeException(), isNull);
  });

  testWidgets('void async dispose that calls super.dispose before an await does not throw', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const VoidAsyncDisposeBeforeAwaitWidget());
    await tester.pumpWidget(Container());

    expect(tester.takeException(), isNull);
  });
}
