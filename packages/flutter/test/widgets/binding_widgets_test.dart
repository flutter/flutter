// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('handleLifecycleStateChanged callback', () async {
    final AppLifecycleStateObserver observer = AppLifecycleStateObserver();
    WidgetsBinding.instance.addObserver(observer);

    setAppLifeCycleState(AppLifecycleState.paused);
    expect(observer.lifecycleState, AppLifecycleState.paused);

    setAppLifeCycleState(AppLifecycleState.resumed);
    expect(observer.lifecycleState, AppLifecycleState.resumed);

    setAppLifeCycleState(AppLifecycleState.inactive);
    expect(observer.lifecycleState, AppLifecycleState.inactive);

    setAppLifeCycleState(AppLifecycleState.detached);
    expect(observer.lifecycleState, AppLifecycleState.detached);

    setAppLifeCycleState(AppLifecycleState.resumed);
  });

  testWidgets('Application lifecycle affects frame scheduling', (WidgetTester tester) async {
    expect(tester.binding.hasScheduledFrame, isFalse);

    setAppLifeCycleState(AppLifecycleState.paused);
    expect(tester.binding.hasScheduledFrame, isFalse);

    setAppLifeCycleState(AppLifecycleState.resumed);
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);

    setAppLifeCycleState(AppLifecycleState.inactive);
    expect(tester.binding.hasScheduledFrame, isFalse);

    setAppLifeCycleState(AppLifecycleState.detached);
    expect(tester.binding.hasScheduledFrame, isFalse);

    setAppLifeCycleState(AppLifecycleState.inactive);
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);

    setAppLifeCycleState(AppLifecycleState.paused);
    expect(tester.binding.hasScheduledFrame, isFalse);

    tester.binding.scheduleFrame();
    expect(tester.binding.hasScheduledFrame, isFalse);

    tester.binding.scheduleForcedFrame();
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump();

    int frameCount = 0;
    tester.binding.addPostFrameCallback((Duration duration) {
      frameCount += 1;
    });
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pump(const Duration(milliseconds: 1));
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(frameCount, 0);

    tester.binding.scheduleWarmUpFrame(); // this actually tests flutter_test's implementation
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(frameCount, 1);

    // Get the tester back to a resumed state for subsequent tests.
    setAppLifeCycleState(AppLifecycleState.resumed);
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump();
  });

  testWidgets('scheduleFrameCallback error control test', (WidgetTester tester) async {
    late FlutterError error;
    try {
      tester.binding.scheduleFrameCallback((Duration _) { }, rescheduling: true);
    } on FlutterError catch (e) {
      error = e;
    }
    expect(error, isNotNull);
    expect(error.diagnostics.length, 3);
    expect(error.diagnostics.last.level, DiagnosticLevel.hint);
    expect(
      error.diagnostics.last.toStringDeep(),
      equalsIgnoringHashCodes(
        'If this is the initial registration of the callback, or if the\n'
        'callback is asynchronous, then do not use the "rescheduling"\n'
        'argument.\n',
      ),
    );
    expect(
      error.toStringDeep(),
      'FlutterError\n'
      '   scheduleFrameCallback called with rescheduling true, but no\n'
      '   callback is in scope.\n'
      '   The "rescheduling" argument should only be set to true if the\n'
      '   callback is being reregistered from within the callback itself,\n'
      '   and only then if the callback itself is entirely synchronous.\n'
      '   If this is the initial registration of the callback, or if the\n'
      '   callback is asynchronous, then do not use the "rescheduling"\n'
      '   argument.\n',
    );
  });

  testWidgets('defaultStackFilter elides framework Element mounting stacks', (WidgetTester tester) async {
    final FlutterExceptionHandler? oldHandler = FlutterError.onError;
    late FlutterErrorDetails errorDetails;
    FlutterError.onError = (FlutterErrorDetails details) {
      errorDetails = details;
    };
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: TestStatefulWidget(
        child: Builder(
          builder: (BuildContext context) {
            return Opacity(
              opacity: .5,
              child: Builder(
                builder: (BuildContext context) {
                  assert(false);
                  return const Text('');
                },
              ),
            );
          },
        ),
      ),
    ));
    FlutterError.onError = oldHandler;
    expect(errorDetails.exception, isAssertionError);
    const String toMatch = '...     Normal element mounting (';
    expect(toMatch.allMatches(errorDetails.toString()).length, 1);
  }, skip: kIsWeb); // https://github.com/flutter/flutter/issues/87875
}

Future<void> setAppLifeCycleState(AppLifecycleState state) async {
  final ByteData? message = const StringCodec().encodeMessage(state.toString());
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage('flutter/lifecycle', message, (_) {});
}

class TestStatefulWidget extends StatefulWidget {
  const TestStatefulWidget({required this.child, super.key});

  final Widget child;

  @override
  State<StatefulWidget> createState() => TestStatefulWidgetState();
}

class TestStatefulWidgetState extends State<TestStatefulWidget> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class AppLifecycleStateObserver with WidgetsBindingObserver {
  late AppLifecycleState lifecycleState;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    lifecycleState = state;
  }
}
