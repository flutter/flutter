// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryPressureObserver with WidgetsBindingObserver {
  bool sawMemoryPressure = false;

  @override
  void didHaveMemoryPressure() {
    sawMemoryPressure = true;
  }
}

class AppLifecycleStateObserver with WidgetsBindingObserver {
  List<AppLifecycleState> accumulatedStates = <AppLifecycleState>[];

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    accumulatedStates.add(state);
  }
}

class ViewFocusObserver with WidgetsBindingObserver {
  List<ViewFocusEvent> accumulatedEvents = <ViewFocusEvent>[];

  @override
  void didChangeViewFocus(ViewFocusEvent state) {
    accumulatedEvents.add(state);
  }
}

class PushRouteObserver with WidgetsBindingObserver {
  late String pushedRoute;

  @override
  Future<bool> didPushRoute(String route) async {
    pushedRoute = route;
    return true;
  }
}

class PushRouteInformationObserver with WidgetsBindingObserver {
  late RouteInformation pushedRouteInformation;

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) async {
    pushedRouteInformation = routeInformation;
    return true;
  }
}

class ThrowingObserver with WidgetsBindingObserver {
  @override
  Future<AppExitResponse> didRequestAppExit() {
    throw Exception('Intentional test exception from observer');
  }

  @override
  void didChangeMetrics() {
    throw Exception('Intentional test exception from observer');
  }

  @override
  void didChangeTextScaleFactor() {
    throw Exception('Intentional test exception from observer');
  }

  @override
  void didChangePlatformBrightness() {
    throw Exception('Intentional test exception from observer');
  }

  @override
  void didChangeAccessibilityFeatures() {
    throw Exception('Intentional test exception from observer');
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    throw Exception('Intentional test exception from observer');
  }

  @override
  Future<bool> didPopRoute() async {
    throw Exception('Intentional test exception from observer');
  }

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    throw Exception('Intentional test exception from observer');
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    throw Exception('Intentional test exception from observer');
  }

  @override
  void handleCommitBackGesture() {
    throw Exception('Intentional test exception from observer');
  }

  @override
  void handleCancelBackGesture() {
    throw Exception('Intentional test exception from observer');
  }

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) {
    throw Exception('Intentional test exception from observer');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    throw Exception('Intentional test exception from observer');
  }

  @override
  void didChangeViewFocus(ViewFocusEvent event) {
    throw Exception('Intentional test exception from observer');
  }

  @override
  void didHaveMemoryPressure() {
    throw Exception('Intentional test exception from observer');
  }
}

class BackGestureThrowingObserver with WidgetsBindingObserver {
  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    return true; // Return true to get tracked for subsequent events
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    throw Exception('Intentional test exception from observer');
  }

  @override
  void handleCommitBackGesture() {
    throw Exception('Intentional test exception from observer');
  }

  @override
  void handleCancelBackGesture() {
    throw Exception('Intentional test exception from observer');
  }
}

class LoggingObserver with WidgetsBindingObserver {
  LoggingObserver(this.log);

  final List<String> log;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    log.add('didChangeAppLifecycleState');
  }

  @override
  void didChangeMetrics() {
    log.add('didChangeMetrics');
  }

  @override
  Future<bool> didPopRoute() async {
    log.add('didPopRoute');
    return false;
  }

  @override
  Future<AppExitResponse> didRequestAppExit() {
    log.add('didRequestAppExit');
    return Future<AppExitResponse>.value(AppExitResponse.exit);
  }

  @override
  void didChangeTextScaleFactor() {
    log.add('didChangeTextScaleFactor');
  }

  @override
  void didChangePlatformBrightness() {
    log.add('didChangePlatformBrightness');
  }

  @override
  void didChangeAccessibilityFeatures() {
    log.add('didChangeAccessibilityFeatures');
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    log.add('didChangeLocales');
  }

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    log.add('handleStartBackGesture');
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    log.add('handleUpdateBackGestureProgress');
  }

  @override
  void handleCommitBackGesture() {
    log.add('handleCommitBackGesture');
  }

  @override
  void handleCancelBackGesture() {
    log.add('handleCancelBackGesture');
  }

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) {
    log.add('didPushRouteInformation');
    return Future<bool>.value(false);
  }

  @override
  void didChangeViewFocus(ViewFocusEvent event) {
    log.add('didChangeViewFocus');
  }

  @override
  void didHaveMemoryPressure() {
    log.add('didHaveMemoryPressure');
  }
}

// Implements to make sure all methods get coverage.
class RentrantObserver implements WidgetsBindingObserver {
  RentrantObserver() {
    WidgetsBinding.instance.addObserver(this);
  }

  bool active = true;

  int removeSelf() {
    active = false;
    var count = 0;
    while (WidgetsBinding.instance.removeObserver(this)) {
      count += 1;
    }
    return count;
  }

  @override
  void didChangeAccessibilityFeatures() {
    assert(active);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    assert(active);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeViewFocus(ViewFocusEvent event) {
    assert(active);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    assert(active);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    assert(active);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangePlatformBrightness() {
    assert(active);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeTextScaleFactor() {
    assert(active);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didHaveMemoryPressure() {
    assert(active);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Future<bool> didPopRoute() {
    assert(active);
    WidgetsBinding.instance.addObserver(this);
    return Future<bool>.value(true);
  }

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    assert(active);
    WidgetsBinding.instance.addObserver(this);
    return true;
  }

  @override
  bool handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    assert(active);
    WidgetsBinding.instance.addObserver(this);
    return true;
  }

  @override
  bool handleCommitBackGesture() {
    assert(active);
    WidgetsBinding.instance.addObserver(this);
    return true;
  }

  @override
  bool handleCancelBackGesture() {
    assert(active);
    WidgetsBinding.instance.addObserver(this);
    return true;
  }

  @override
  Future<bool> didPushRoute(String route) {
    assert(active);
    WidgetsBinding.instance.addObserver(this);
    return Future<bool>.value(true);
  }

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) {
    assert(active);
    WidgetsBinding.instance.addObserver(this);
    return Future<bool>.value(true);
  }

  @override
  Future<AppExitResponse> didRequestAppExit() {
    assert(active);
    WidgetsBinding.instance.addObserver(this);
    return Future<AppExitResponse>.value(AppExitResponse.exit);
  }
}

void main() {
  Future<void> setAppLifeCycleState(AppLifecycleState state) async {
    final ByteData? message = const StringCodec().encodeMessage(state.toString());
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/lifecycle',
      message,
      (_) {},
    );
  }

  testWidgets('Rentrant observer callbacks do not result in exceptions', (
    WidgetTester tester,
  ) async {
    final observer = RentrantObserver();
    WidgetsBinding.instance.handleAccessibilityFeaturesChanged();
    WidgetsBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    WidgetsBinding.instance.handleLocaleChanged();
    WidgetsBinding.instance.handleMetricsChanged();
    WidgetsBinding.instance.handlePlatformBrightnessChanged();
    WidgetsBinding.instance.handleTextScaleFactorChanged();
    WidgetsBinding.instance.handleMemoryPressure();
    WidgetsBinding.instance.handlePopRoute();
    WidgetsBinding.instance.handlePushRoute('/');
    WidgetsBinding.instance.handleRequestAppExit();
    WidgetsBinding.instance.handleViewFocusChanged(
      const ViewFocusEvent(
        viewId: 0,
        state: ViewFocusState.focused,
        direction: ViewFocusDirection.forward,
      ),
    );
    await tester.idle();
    expect(observer.removeSelf(), greaterThan(1));
    expect(observer.removeSelf(), 0);
  });

  testWidgets('didHaveMemoryPressure callback', (WidgetTester tester) async {
    final observer = MemoryPressureObserver();
    WidgetsBinding.instance.addObserver(observer);
    final ByteData message = const JSONMessageCodec().encodeMessage(<String, dynamic>{
      'type': 'memoryPressure',
    })!;
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/system',
      message,
      (_) {},
    );
    expect(observer.sawMemoryPressure, true);
    WidgetsBinding.instance.removeObserver(observer);
  });

  testWidgets('handleLifecycleStateChanged callback', (WidgetTester tester) async {
    final observer = AppLifecycleStateObserver();
    WidgetsBinding.instance.addObserver(observer);

    await setAppLifeCycleState(AppLifecycleState.paused);
    expect(observer.accumulatedStates, <AppLifecycleState>[AppLifecycleState.paused]);

    observer.accumulatedStates.clear();
    await setAppLifeCycleState(AppLifecycleState.resumed);
    expect(observer.accumulatedStates, <AppLifecycleState>[
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]);

    observer.accumulatedStates.clear();
    await setAppLifeCycleState(AppLifecycleState.paused);
    expect(observer.accumulatedStates, <AppLifecycleState>[
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]);

    observer.accumulatedStates.clear();
    await setAppLifeCycleState(AppLifecycleState.inactive);
    expect(observer.accumulatedStates, <AppLifecycleState>[
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
    ]);

    observer.accumulatedStates.clear();
    await setAppLifeCycleState(AppLifecycleState.hidden);
    expect(observer.accumulatedStates, <AppLifecycleState>[AppLifecycleState.hidden]);

    observer.accumulatedStates.clear();
    await setAppLifeCycleState(AppLifecycleState.paused);
    expect(observer.accumulatedStates, <AppLifecycleState>[AppLifecycleState.paused]);

    observer.accumulatedStates.clear();
    await setAppLifeCycleState(AppLifecycleState.detached);
    expect(observer.accumulatedStates, <AppLifecycleState>[AppLifecycleState.detached]);

    observer.accumulatedStates.clear();
    await setAppLifeCycleState(AppLifecycleState.resumed);
    expect(observer.accumulatedStates, <AppLifecycleState>[AppLifecycleState.resumed]);

    observer.accumulatedStates.clear();
    await setAppLifeCycleState(AppLifecycleState.detached);
    expect(observer.accumulatedStates, <AppLifecycleState>[
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.detached,
    ]);
    WidgetsBinding.instance.removeObserver(observer);
  });

  testWidgets('handleViewFocusChanged callback', (WidgetTester tester) async {
    final observer = ViewFocusObserver();
    WidgetsBinding.instance.addObserver(observer);

    const expectedEvent = ViewFocusEvent(
      viewId: 0,
      state: ViewFocusState.focused,
      direction: ViewFocusDirection.forward,
    );

    PlatformDispatcher.instance.onViewFocusChange!(expectedEvent);
    expect(observer.accumulatedEvents, <ViewFocusEvent>[expectedEvent]);

    WidgetsBinding.instance.removeObserver(observer);
  });

  testWidgets('didPushRoute callback', (WidgetTester tester) async {
    final observer = PushRouteObserver();
    WidgetsBinding.instance.addObserver(observer);

    const testRouteName = 'testRouteName';
    final ByteData message = const JSONMethodCodec().encodeMethodCall(
      const MethodCall('pushRoute', testRouteName),
    );
    final ByteData result = (await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      message,
      (_) {},
    ))!;
    final decodedResult = const JSONMethodCodec().decodeEnvelope(result) as bool;

    expect(decodedResult, true);
    expect(observer.pushedRoute, testRouteName);

    WidgetsBinding.instance.removeObserver(observer);
  });

  testWidgets('didPushRouteInformation calls didPushRoute by default', (WidgetTester tester) async {
    final observer = PushRouteObserver();
    WidgetsBinding.instance.addObserver(observer);

    const testRouteInformation = <String, dynamic>{
      'location': 'testRouteName',
      'state': 'state',
      'restorationData': <dynamic, dynamic>{'test': 'config'},
    };
    final ByteData message = const JSONMethodCodec().encodeMethodCall(
      const MethodCall('pushRouteInformation', testRouteInformation),
    );
    final ByteData result = (await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      message,
      (_) {},
    ))!;
    final decodedResult = const JSONMethodCodec().decodeEnvelope(result) as bool;

    expect(decodedResult, true);
    expect(observer.pushedRoute, 'testRouteName');
    WidgetsBinding.instance.removeObserver(observer);
  });

  testWidgets('didPushRouteInformation calls didPushRoute correctly when handling url', (
    WidgetTester tester,
  ) async {
    final observer = PushRouteObserver();
    WidgetsBinding.instance.addObserver(observer);

    // A url without any path.
    var testRouteInformation = const <String, dynamic>{
      'location': 'http://hostname',
      'state': 'state',
      'restorationData': <dynamic, dynamic>{'test': 'config'},
    };
    ByteData message = const JSONMethodCodec().encodeMethodCall(
      MethodCall('pushRouteInformation', testRouteInformation),
    );
    await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      message,
      (_) {},
    );
    expect(observer.pushedRoute, '/');

    // A complex url.
    testRouteInformation = const <String, dynamic>{
      'location': 'http://hostname/abc?def=123&def=456#789',
      'state': 'state',
      'restorationData': <dynamic, dynamic>{'test': 'config'},
    };
    message = const JSONMethodCodec().encodeMethodCall(
      MethodCall('pushRouteInformation', testRouteInformation),
    );
    await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      message,
      (_) {},
    );
    expect(observer.pushedRoute, '/abc?def=123&def=456#789');
    WidgetsBinding.instance.removeObserver(observer);
  });

  testWidgets('didPushRouteInformation callback', (WidgetTester tester) async {
    final observer = PushRouteInformationObserver();
    WidgetsBinding.instance.addObserver(observer);

    const testRouteInformation = <String, dynamic>{'location': 'testRouteName', 'state': 'state'};
    final ByteData message = const JSONMethodCodec().encodeMethodCall(
      const MethodCall('pushRouteInformation', testRouteInformation),
    );
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      message,
      (_) {},
    );
    expect(observer.pushedRouteInformation.uri.toString(), 'testRouteName');
    expect(observer.pushedRouteInformation.state, 'state');
    WidgetsBinding.instance.removeObserver(observer);
  });

  testWidgets('didPushRouteInformation callback can handle url', (WidgetTester tester) async {
    final observer = PushRouteInformationObserver();
    WidgetsBinding.instance.addObserver(observer);

    const testRouteInformation = <String, dynamic>{
      'location': 'http://hostname/abc?def=123&def=456#789',
      'state': 'state',
    };
    final ByteData message = const JSONMethodCodec().encodeMethodCall(
      const MethodCall('pushRouteInformation', testRouteInformation),
    );
    await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      message,
      (_) {},
    );
    expect(observer.pushedRouteInformation.location, '/abc?def=123&def=456#789');
    expect(
      observer.pushedRouteInformation.uri.toString(),
      'http://hostname/abc?def=123&def=456#789',
    );
    expect(observer.pushedRouteInformation.state, 'state');
    WidgetsBinding.instance.removeObserver(observer);
  });

  testWidgets('didPushRouteInformation callback with null state', (WidgetTester tester) async {
    final observer = PushRouteInformationObserver();
    WidgetsBinding.instance.addObserver(observer);

    const testRouteInformation = <String, dynamic>{'location': 'testRouteName', 'state': null};
    final ByteData message = const JSONMethodCodec().encodeMethodCall(
      const MethodCall('pushRouteInformation', testRouteInformation),
    );

    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      message,
      (_) {},
    );
    expect(observer.pushedRouteInformation.uri.toString(), 'testRouteName');
    expect(observer.pushedRouteInformation.state, null);
    WidgetsBinding.instance.removeObserver(observer);
  });

  testWidgets('pushRouteInformation not handled by observer returns false', (
    WidgetTester tester,
  ) async {
    const testRouteInformation = <String, dynamic>{'location': 'testRouteName', 'state': null};
    final ByteData message = const JSONMethodCodec().encodeMethodCall(
      const MethodCall('pushRouteInformation', testRouteInformation),
    );

    final ByteData result = (await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      message,
      (_) {},
    ))!;
    final decodedResult = const JSONMethodCodec().decodeEnvelope(result) as bool;

    expect(decodedResult, false);
  });

  testWidgets('pushRoute not handled by observer returns false', (WidgetTester tester) async {
    const testRoute = 'testRouteName';
    final ByteData message = const JSONMethodCodec().encodeMethodCall(
      const MethodCall('pushRoute', testRoute),
    );

    final ByteData result = (await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      message,
      (_) {},
    ))!;
    final decodedResult = const JSONMethodCodec().decodeEnvelope(result) as bool;

    expect(decodedResult, false);
  });

  testWidgets('popRoute not handled by observer returns false', (WidgetTester tester) async {
    final ByteData message = const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute'));

    final ByteData result = (await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      message,
      (_) {},
    ))!;
    final decodedResult = const JSONMethodCodec().decodeEnvelope(result) as bool;

    expect(decodedResult, false);
  });
  testWidgets('Application lifecycle affects frame scheduling', (WidgetTester tester) async {
    expect(tester.binding.hasScheduledFrame, isFalse);

    await setAppLifeCycleState(AppLifecycleState.paused);
    expect(tester.binding.hasScheduledFrame, isFalse);

    await setAppLifeCycleState(AppLifecycleState.resumed);
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);

    await setAppLifeCycleState(AppLifecycleState.inactive);
    expect(tester.binding.hasScheduledFrame, isFalse);

    await setAppLifeCycleState(AppLifecycleState.paused);
    expect(tester.binding.hasScheduledFrame, isFalse);

    await setAppLifeCycleState(AppLifecycleState.detached);
    expect(tester.binding.hasScheduledFrame, isFalse);

    await setAppLifeCycleState(AppLifecycleState.inactive);
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);

    await setAppLifeCycleState(AppLifecycleState.paused);
    expect(tester.binding.hasScheduledFrame, isFalse);

    tester.binding.scheduleFrame();
    expect(tester.binding.hasScheduledFrame, isFalse);

    tester.binding.scheduleForcedFrame();
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump();

    var frameCount = 0;
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
    await setAppLifeCycleState(AppLifecycleState.resumed);
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump();
  });

  testWidgets('resetInternalState resets lifecycleState and framesEnabled to initial state', (
    WidgetTester tester,
  ) async {
    // Initial state
    expect(tester.binding.lifecycleState, isNull);
    expect(tester.binding.framesEnabled, isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(tester.binding.lifecycleState, AppLifecycleState.paused);
    expect(tester.binding.framesEnabled, isFalse);

    tester.binding.resetInternalState();

    expect(tester.binding.lifecycleState, isNull);
    expect(tester.binding.framesEnabled, isTrue);
  });

  testWidgets('scheduleFrameCallback error control test', (WidgetTester tester) async {
    late FlutterError error;
    try {
      tester.binding.scheduleFrameCallback((Duration _) {}, rescheduling: true);
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

  testWidgets('defaultStackFilter elides framework Element mounting stacks', (
    WidgetTester tester,
  ) async {
    final FlutterExceptionHandler? oldHandler = FlutterError.onError;
    late FlutterErrorDetails errorDetails;
    FlutterError.onError = (FlutterErrorDetails details) {
      errorDetails = details;
    };
    await tester.pumpWidget(
      Directionality(
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
      ),
    );
    FlutterError.onError = oldHandler;
    expect(errorDetails.exception, isAssertionError);
    const toMatch = '...     Normal element mounting (';
    expect(toMatch.allMatches(errorDetails.toString()).length, 1);
  }, skip: kIsWeb); // https://github.com/flutter/flutter/issues/87875

  group('WidgetsBindingObserver callbacks handle exceptions gracefully', () {
    testWidgets('didChangeAppLifecycleState', (WidgetTester tester) async {
      final log = <String>[];
      final errors = <FlutterErrorDetails>[];
      final FlutterExceptionHandler? oldHandler = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) => errors.add(details);
      addTearDown(() {
        FlutterError.onError = oldHandler;
      });

      final throwingObserver = ThrowingObserver();
      final loggingObserver = LoggingObserver(log);
      WidgetsBinding.instance.addObserver(throwingObserver);
      WidgetsBinding.instance.addObserver(loggingObserver);
      addTearDown(() {
        WidgetsBinding.instance.removeObserver(throwingObserver);
        WidgetsBinding.instance.removeObserver(loggingObserver);
      });

      WidgetsBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      expect(log, contains('didChangeAppLifecycleState'));
      expect(errors, hasLength(1));
    });

    testWidgets('didPopRoute', (WidgetTester tester) async {
      final log = <String>[];
      final errors = <FlutterErrorDetails>[];
      final FlutterExceptionHandler? oldHandler = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) => errors.add(details);
      addTearDown(() {
        FlutterError.onError = oldHandler;
      });

      final throwingObserver = ThrowingObserver();
      final loggingObserver = LoggingObserver(log);
      WidgetsBinding.instance.addObserver(throwingObserver);
      WidgetsBinding.instance.addObserver(loggingObserver);
      addTearDown(() {
        WidgetsBinding.instance.removeObserver(throwingObserver);
        WidgetsBinding.instance.removeObserver(loggingObserver);
      });

      await WidgetsBinding.instance.handlePopRoute();
      expect(log, contains('didPopRoute'));
      expect(errors, hasLength(1));
    });

    testWidgets('didChangeMetrics', (WidgetTester tester) async {
      final log = <String>[];
      final errors = <FlutterErrorDetails>[];
      final FlutterExceptionHandler? oldHandler = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) => errors.add(details);
      addTearDown(() {
        FlutterError.onError = oldHandler;
      });

      final throwingObserver = ThrowingObserver();
      final loggingObserver = LoggingObserver(log);
      WidgetsBinding.instance.addObserver(throwingObserver);
      WidgetsBinding.instance.addObserver(loggingObserver);
      addTearDown(() {
        WidgetsBinding.instance.removeObserver(throwingObserver);
        WidgetsBinding.instance.removeObserver(loggingObserver);
      });

      WidgetsBinding.instance.handleMetricsChanged();
      expect(log, contains('didChangeMetrics'));
      expect(errors, hasLength(1));
    });

    testWidgets('didRequestAppExit', (WidgetTester tester) async {
      final log = <String>[];
      final errors = <FlutterErrorDetails>[];
      final FlutterExceptionHandler? oldHandler = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) => errors.add(details);
      addTearDown(() {
        FlutterError.onError = oldHandler;
      });

      final throwingObserver = ThrowingObserver();
      final loggingObserver = LoggingObserver(log);
      WidgetsBinding.instance.addObserver(throwingObserver);
      WidgetsBinding.instance.addObserver(loggingObserver);
      addTearDown(() {
        WidgetsBinding.instance.removeObserver(throwingObserver);
        WidgetsBinding.instance.removeObserver(loggingObserver);
      });

      await WidgetsBinding.instance.handleRequestAppExit();
      expect(log, contains('didRequestAppExit'));
      expect(errors, hasLength(1));
    });

    testWidgets('didChangeTextScaleFactor', (WidgetTester tester) async {
      final log = <String>[];
      final errors = <FlutterErrorDetails>[];
      final FlutterExceptionHandler? oldHandler = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) => errors.add(details);
      addTearDown(() {
        FlutterError.onError = oldHandler;
      });

      final throwingObserver = ThrowingObserver();
      final loggingObserver = LoggingObserver(log);
      WidgetsBinding.instance.addObserver(throwingObserver);
      WidgetsBinding.instance.addObserver(loggingObserver);
      addTearDown(() {
        WidgetsBinding.instance.removeObserver(throwingObserver);
        WidgetsBinding.instance.removeObserver(loggingObserver);
      });

      WidgetsBinding.instance.handleTextScaleFactorChanged();
      expect(log, contains('didChangeTextScaleFactor'));
      expect(errors, hasLength(1));
    });

    testWidgets('didChangePlatformBrightness', (WidgetTester tester) async {
      final log = <String>[];
      final errors = <FlutterErrorDetails>[];
      final FlutterExceptionHandler? oldHandler = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) => errors.add(details);
      addTearDown(() {
        FlutterError.onError = oldHandler;
      });

      final throwingObserver = ThrowingObserver();
      final loggingObserver = LoggingObserver(log);
      WidgetsBinding.instance.addObserver(throwingObserver);
      WidgetsBinding.instance.addObserver(loggingObserver);
      addTearDown(() {
        WidgetsBinding.instance.removeObserver(throwingObserver);
        WidgetsBinding.instance.removeObserver(loggingObserver);
      });

      WidgetsBinding.instance.handlePlatformBrightnessChanged();
      expect(log, contains('didChangePlatformBrightness'));
      expect(errors, hasLength(1));
    });

    testWidgets('didChangeAccessibilityFeatures', (WidgetTester tester) async {
      final log = <String>[];
      final errors = <FlutterErrorDetails>[];
      final FlutterExceptionHandler? oldHandler = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) => errors.add(details);
      addTearDown(() {
        FlutterError.onError = oldHandler;
      });

      final throwingObserver = ThrowingObserver();
      final loggingObserver = LoggingObserver(log);
      WidgetsBinding.instance.addObserver(throwingObserver);
      WidgetsBinding.instance.addObserver(loggingObserver);
      addTearDown(() {
        WidgetsBinding.instance.removeObserver(throwingObserver);
        WidgetsBinding.instance.removeObserver(loggingObserver);
      });

      WidgetsBinding.instance.handleAccessibilityFeaturesChanged();
      expect(log, contains('didChangeAccessibilityFeatures'));
      expect(errors, hasLength(1));
    });

    testWidgets('didChangeLocales', (WidgetTester tester) async {
      final log = <String>[];
      final errors = <FlutterErrorDetails>[];
      final FlutterExceptionHandler? oldHandler = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) => errors.add(details);
      addTearDown(() {
        FlutterError.onError = oldHandler;
      });

      final throwingObserver = ThrowingObserver();
      final loggingObserver = LoggingObserver(log);
      WidgetsBinding.instance.addObserver(throwingObserver);
      WidgetsBinding.instance.addObserver(loggingObserver);
      addTearDown(() {
        WidgetsBinding.instance.removeObserver(throwingObserver);
        WidgetsBinding.instance.removeObserver(loggingObserver);
      });

      WidgetsBinding.instance.handleLocaleChanged();
      expect(log, contains('didChangeLocales'));
      expect(errors, hasLength(1));
    });

    testWidgets('handleStartBackGesture', (WidgetTester tester) async {
      final log = <String>[];
      final errors = <FlutterErrorDetails>[];
      final FlutterExceptionHandler? oldHandler = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) => errors.add(details);
      addTearDown(() {
        FlutterError.onError = oldHandler;
      });

      final throwingObserver = ThrowingObserver();
      final loggingObserver = LoggingObserver(log);
      WidgetsBinding.instance.addObserver(throwingObserver);
      WidgetsBinding.instance.addObserver(loggingObserver);
      addTearDown(() {
        WidgetsBinding.instance.removeObserver(throwingObserver);
        WidgetsBinding.instance.removeObserver(loggingObserver);
      });

      final ByteData startBackGestureMessage = const StandardMethodCodec().encodeMethodCall(
        const MethodCall('startBackGesture', <String, dynamic>{
          'touchOffset': <double>[5.0, 300.0],
          'progress': 0.0,
          'swipeEdge': 0,
        }),
      );
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/backgesture',
        startBackGestureMessage,
        (ByteData? _) {},
      );
      expect(log, contains('handleStartBackGesture'));
      expect(errors, hasLength(1));
    });

    testWidgets('didPushRouteInformation', (WidgetTester tester) async {
      final log = <String>[];
      final errors = <FlutterErrorDetails>[];
      final FlutterExceptionHandler? oldHandler = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) => errors.add(details);
      addTearDown(() {
        FlutterError.onError = oldHandler;
      });

      final throwingObserver = ThrowingObserver();
      final loggingObserver = LoggingObserver(log);
      WidgetsBinding.instance.addObserver(throwingObserver);
      WidgetsBinding.instance.addObserver(loggingObserver);
      addTearDown(() {
        WidgetsBinding.instance.removeObserver(throwingObserver);
        WidgetsBinding.instance.removeObserver(loggingObserver);
      });

      const testRouteInformation = <String, dynamic>{'location': 'testRouteName', 'state': 'state'};
      final ByteData pushRouteMessage = const JSONMethodCodec().encodeMethodCall(
        const MethodCall('pushRouteInformation', testRouteInformation),
      );
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/navigation',
        pushRouteMessage,
        (ByteData? _) {},
      );
      expect(log, contains('didPushRouteInformation'));
      expect(errors, hasLength(1));
    });

    testWidgets('didChangeViewFocus', (WidgetTester tester) async {
      final log = <String>[];
      final errors = <FlutterErrorDetails>[];
      final FlutterExceptionHandler? oldHandler = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) => errors.add(details);
      addTearDown(() {
        FlutterError.onError = oldHandler;
      });

      final throwingObserver = ThrowingObserver();
      final loggingObserver = LoggingObserver(log);
      WidgetsBinding.instance.addObserver(throwingObserver);
      WidgetsBinding.instance.addObserver(loggingObserver);
      addTearDown(() {
        WidgetsBinding.instance.removeObserver(throwingObserver);
        WidgetsBinding.instance.removeObserver(loggingObserver);
      });

      WidgetsBinding.instance.handleViewFocusChanged(
        const ViewFocusEvent(
          viewId: 0,
          state: ViewFocusState.focused,
          direction: ViewFocusDirection.forward,
        ),
      );
      expect(log, contains('didChangeViewFocus'));
      expect(errors, hasLength(1));
    });

    testWidgets('didHaveMemoryPressure', (WidgetTester tester) async {
      final log = <String>[];
      final errors = <FlutterErrorDetails>[];
      final FlutterExceptionHandler? oldHandler = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) => errors.add(details);
      addTearDown(() {
        FlutterError.onError = oldHandler;
      });

      final throwingObserver = ThrowingObserver();
      final loggingObserver = LoggingObserver(log);
      WidgetsBinding.instance.addObserver(throwingObserver);
      WidgetsBinding.instance.addObserver(loggingObserver);
      addTearDown(() {
        WidgetsBinding.instance.removeObserver(throwingObserver);
        WidgetsBinding.instance.removeObserver(loggingObserver);
      });

      WidgetsBinding.instance.handleMemoryPressure();
      expect(log, contains('didHaveMemoryPressure'));
      expect(errors, hasLength(1));
    });

    testWidgets('handleUpdateBackGestureProgress', (WidgetTester tester) async {
      final log = <String>[];
      final errors = <FlutterErrorDetails>[];
      final FlutterExceptionHandler? oldHandler = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) => errors.add(details);
      addTearDown(() {
        FlutterError.onError = oldHandler;
      });

      final backGestureObserver = BackGestureThrowingObserver();
      final loggingObserver = LoggingObserver(log);
      WidgetsBinding.instance.addObserver(backGestureObserver);
      WidgetsBinding.instance.addObserver(loggingObserver);
      addTearDown(() {
        WidgetsBinding.instance.removeObserver(backGestureObserver);
        WidgetsBinding.instance.removeObserver(loggingObserver);
      });

      // First send startBackGesture to get the observer tracked
      final ByteData startMessage = const StandardMethodCodec().encodeMethodCall(
        const MethodCall('startBackGesture', <String, dynamic>{
          'touchOffset': <double>[5.0, 300.0],
          'progress': 0.0,
          'swipeEdge': 0,
        }),
      );
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/backgesture',
        startMessage,
        (ByteData? _) {},
      );

      // Now test updateBackGestureProgress
      final ByteData updateMessage = const StandardMethodCodec().encodeMethodCall(
        const MethodCall('updateBackGestureProgress', <String, dynamic>{
          'x': 100.0,
          'y': 300.0,
          'progress': 0.35,
          'swipeEdge': 0,
        }),
      );
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/backgesture',
        updateMessage,
        (ByteData? _) {},
      );
      expect(log, contains('handleUpdateBackGestureProgress'));
      expect(errors, hasLength(1));
    });

    testWidgets('handleCommitBackGesture', (WidgetTester tester) async {
      final log = <String>[];
      final errors = <FlutterErrorDetails>[];
      final FlutterExceptionHandler? oldHandler = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) => errors.add(details);
      addTearDown(() {
        FlutterError.onError = oldHandler;
      });

      final backGestureObserver = BackGestureThrowingObserver();
      final loggingObserver = LoggingObserver(log);
      WidgetsBinding.instance.addObserver(backGestureObserver);
      WidgetsBinding.instance.addObserver(loggingObserver);
      addTearDown(() {
        WidgetsBinding.instance.removeObserver(backGestureObserver);
        WidgetsBinding.instance.removeObserver(loggingObserver);
      });

      // First send startBackGesture to get the observer tracked
      final ByteData startMessage = const StandardMethodCodec().encodeMethodCall(
        const MethodCall('startBackGesture', <String, dynamic>{
          'touchOffset': <double>[5.0, 300.0],
          'progress': 0.0,
          'swipeEdge': 0,
        }),
      );
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/backgesture',
        startMessage,
        (ByteData? _) {},
      );

      // Now test commitBackGesture
      final ByteData commitMessage = const StandardMethodCodec().encodeMethodCall(
        const MethodCall('commitBackGesture'),
      );
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/backgesture',
        commitMessage,
        (ByteData? _) {},
      );
      expect(log, contains('handleCommitBackGesture'));
      expect(errors, hasLength(1));
    });

    testWidgets('handleCancelBackGesture', (WidgetTester tester) async {
      final log = <String>[];
      final errors = <FlutterErrorDetails>[];
      final FlutterExceptionHandler? oldHandler = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) => errors.add(details);
      addTearDown(() {
        FlutterError.onError = oldHandler;
      });

      final backGestureObserver = BackGestureThrowingObserver();
      final loggingObserver = LoggingObserver(log);
      WidgetsBinding.instance.addObserver(backGestureObserver);
      WidgetsBinding.instance.addObserver(loggingObserver);
      addTearDown(() {
        WidgetsBinding.instance.removeObserver(backGestureObserver);
        WidgetsBinding.instance.removeObserver(loggingObserver);
      });

      // First send startBackGesture to get the observer tracked
      final ByteData startMessage = const StandardMethodCodec().encodeMethodCall(
        const MethodCall('startBackGesture', <String, dynamic>{
          'touchOffset': <double>[5.0, 300.0],
          'progress': 0.0,
          'swipeEdge': 0,
        }),
      );
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/backgesture',
        startMessage,
        (ByteData? _) {},
      );

      // Now test cancelBackGesture
      final ByteData cancelMessage = const StandardMethodCodec().encodeMethodCall(
        const MethodCall('cancelBackGesture'),
      );
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/backgesture',
        cancelMessage,
        (ByteData? _) {},
      );
      expect(log, contains('handleCancelBackGesture'));
      expect(errors, hasLength(1));
    });
  });
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
