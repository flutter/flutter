// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> setAppLifeCycleState(AppLifecycleState state) async {
    final ByteData? message = const StringCodec().encodeMessage(state.toString());
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage('flutter/lifecycle', message, (_) {});
  }

  Future<void> sendAppExitRequest() async {
    final ByteData message = const JSONMethodCodec().encodeMethodCall(const MethodCall('System.requestAppExit'));
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage('flutter/platform', message, (_) {});
  }

  setUp(() async {
    WidgetsFlutterBinding.ensureInitialized();
    WidgetsBinding.instance
      ..resetEpoch()
      ..platformDispatcher.onBeginFrame = null
      ..platformDispatcher.onDrawFrame = null;
    final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.instance;
    binding.platformDispatcher.resetInitialLifecycleState();
    binding.readTestInitialLifecycleStateFromNativeWindow();
    // Reset the state to detached. Going to paused first makes it a valid
    // transition from any state.
    await setAppLifeCycleState(AppLifecycleState.paused);
    await setAppLifeCycleState(AppLifecycleState.detached);
  });

  testWidgets('listens to AppLifecycleState', (WidgetTester tester) async {
    final List<AppLifecycleState> states = <AppLifecycleState>[tester.binding.lifecycleState!];
    void stateChange(AppLifecycleState state) {
      states.add(state);
    }

    final AppLifecycleListener listener = AppLifecycleListener(
      binding: WidgetsBinding.instance,
      onStateChange: stateChange,
    );
    expect(states, equals(<AppLifecycleState>[AppLifecycleState.detached]));
    await setAppLifeCycleState(AppLifecycleState.inactive);
    // "resumed" is generated.
    expect(states, equals(<AppLifecycleState>[AppLifecycleState.detached, AppLifecycleState.resumed, AppLifecycleState.inactive]));
    await setAppLifeCycleState(AppLifecycleState.resumed);
    expect(states, equals(<AppLifecycleState>[AppLifecycleState.detached, AppLifecycleState.resumed, AppLifecycleState.inactive, AppLifecycleState.resumed]));
    listener.dispose();
  });

  testWidgets('Triggers correct state transition callbacks', (WidgetTester tester) async {
    final List<String> transitions = <String>[];
    final AppLifecycleListener listener = AppLifecycleListener(
      binding: WidgetsBinding.instance,
      onDetach: () => transitions.add('detach'),
      onHide: () => transitions.add('hide'),
      onInactive: () => transitions.add('inactive'),
      onPause: () => transitions.add('pause'),
      onRestart: () => transitions.add('restart'),
      onResume: () => transitions.add('resume'),
      onShow: () => transitions.add('show'),
    );

    // Try "standard" sequence
    await setAppLifeCycleState(AppLifecycleState.resumed);
    expect(transitions, equals(<String>['resume']));
    await setAppLifeCycleState(AppLifecycleState.inactive);
    expect(transitions, equals(<String>['resume', 'inactive']));
    await setAppLifeCycleState(AppLifecycleState.hidden);
    expect(transitions, equals(<String>['resume', 'inactive', 'hide']));
    await setAppLifeCycleState(AppLifecycleState.paused);
    expect(transitions, equals(<String>['resume', 'inactive', 'hide', 'pause']));

    // Go back to resume
    transitions.clear();
    await setAppLifeCycleState(AppLifecycleState.hidden);
    expect(transitions, equals(<String>['restart']));
    await setAppLifeCycleState(AppLifecycleState.inactive);
    expect(transitions, equals(<String>['restart', 'show']));
    await setAppLifeCycleState(AppLifecycleState.resumed);
    expect(transitions, equals(<String>['restart', 'show', 'resume']));

    // Generates intermediate states.
    transitions.clear();
    await setAppLifeCycleState(AppLifecycleState.paused);
    expect(transitions, equals(<String>['inactive', 'hide', 'pause']));
    // Wraps around from pause to detach.
    await setAppLifeCycleState(AppLifecycleState.detached);
    expect(transitions, equals(<String>['inactive', 'hide', 'pause', 'detach']));
    await setAppLifeCycleState(AppLifecycleState.resumed);
    expect(transitions, equals(<String>['inactive', 'hide', 'pause', 'detach', 'resume']));
    await setAppLifeCycleState(AppLifecycleState.paused);
    expect(transitions, equals(<String>['inactive', 'hide', 'pause', 'detach', 'resume', 'inactive', 'hide', 'pause']));
    transitions.clear();
    await setAppLifeCycleState(AppLifecycleState.resumed);
    expect(transitions, equals(<String>['restart', 'show', 'resume']));

    // Asserts on bad transitions
    await expectLater(() => setAppLifeCycleState(AppLifecycleState.detached), throwsAssertionError);
    await setAppLifeCycleState(AppLifecycleState.paused);
    await setAppLifeCycleState(AppLifecycleState.detached);

    listener.dispose();
  });

  testWidgets('Receives exit requests', (WidgetTester tester) async {
    bool exitRequested = false;
    Future<AppExitResponse> handleExitRequested() async {
      exitRequested = true;
      return AppExitResponse.cancel;
    }

    final AppLifecycleListener listener = AppLifecycleListener(
      binding: WidgetsBinding.instance,
      onExitRequested: handleExitRequested,
    );
    await sendAppExitRequest();
    expect(exitRequested, isTrue);
    listener.dispose();
  });

  testWidgets('Diagnostics', (WidgetTester tester) async {
    Future<AppExitResponse> handleExitRequested() async {
      return AppExitResponse.cancel;
    }

    void stateChange(AppLifecycleState state) {}
    AppLifecycleListener listener = AppLifecycleListener(
      binding: WidgetsBinding.instance,
    );
    expect(listener.toString(),
        equalsIgnoringHashCodes('AppLifecycleListener#00000(binding: <AutomatedTestWidgetsFlutterBinding>)'));
    listener = AppLifecycleListener(
      binding: WidgetsBinding.instance,
      onExitRequested: handleExitRequested,
      onStateChange: stateChange,
    );
    expect(
        listener.toString(),
        equalsIgnoringHashCodes(
            'AppLifecycleListener#00000(binding: <AutomatedTestWidgetsFlutterBinding>, onStateChange, onExitRequested)'));
  });
}
