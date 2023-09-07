// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

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

// Implements to make sure all methods get coverage.
class RentrantObserver implements WidgetsBindingObserver {
  RentrantObserver() {
    WidgetsBinding.instance.addObserver(this);
  }

  bool active = true;

  int removeSelf() {
    active = false;
    int count = 0;
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
    final ByteData? message =
        const StringCodec().encodeMessage(state.toString());
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage('flutter/lifecycle', message, (_) { });
  }

  testWidgetsWithLeakTracking('Rentrant observer callbacks do not result in exceptions', (WidgetTester tester) async {
    final RentrantObserver observer = RentrantObserver();
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
    await tester.idle();
    expect(observer.removeSelf(), greaterThan(1));
    expect(observer.removeSelf(), 0);
  });

  testWidgetsWithLeakTracking('didHaveMemoryPressure callback', (WidgetTester tester) async {
    final MemoryPressureObserver observer = MemoryPressureObserver();
    WidgetsBinding.instance.addObserver(observer);
    final ByteData message = const JSONMessageCodec().encodeMessage(<String, dynamic>{'type': 'memoryPressure'})!;
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage('flutter/system', message, (_) { });
    expect(observer.sawMemoryPressure, true);
    WidgetsBinding.instance.removeObserver(observer);
  });

  testWidgetsWithLeakTracking('handleLifecycleStateChanged callback', (WidgetTester tester) async {
    final AppLifecycleStateObserver observer = AppLifecycleStateObserver();
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
    expect(observer.accumulatedStates, <AppLifecycleState>[
      AppLifecycleState.hidden,
    ]);

    observer.accumulatedStates.clear();
    await setAppLifeCycleState(AppLifecycleState.paused);
    expect(observer.accumulatedStates, <AppLifecycleState>[
      AppLifecycleState.paused,
    ]);

    observer.accumulatedStates.clear();
    await setAppLifeCycleState(AppLifecycleState.detached);
    expect(observer.accumulatedStates, <AppLifecycleState>[
      AppLifecycleState.detached,
    ]);

    observer.accumulatedStates.clear();
    await setAppLifeCycleState(AppLifecycleState.resumed);
    expect(observer.accumulatedStates, <AppLifecycleState>[
      AppLifecycleState.resumed,
    ]);

    observer.accumulatedStates.clear();
    await expectLater(() async => setAppLifeCycleState(AppLifecycleState.detached), throwsAssertionError);
    WidgetsBinding.instance.removeObserver(observer);
  });

  testWidgetsWithLeakTracking('didPushRoute callback', (WidgetTester tester) async {
    final PushRouteObserver observer = PushRouteObserver();
    WidgetsBinding.instance.addObserver(observer);

    const String testRouteName = 'testRouteName';
    final ByteData message = const JSONMethodCodec().encodeMethodCall(const MethodCall('pushRoute', testRouteName));
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage('flutter/navigation', message, (_) {});
    expect(observer.pushedRoute, testRouteName);

    WidgetsBinding.instance.removeObserver(observer);
  });

  testWidgetsWithLeakTracking('didPushRouteInformation calls didPushRoute by default', (WidgetTester tester) async {
    final PushRouteObserver observer = PushRouteObserver();
    WidgetsBinding.instance.addObserver(observer);

    const Map<String, dynamic> testRouteInformation = <String, dynamic>{
      'location': 'testRouteName',
      'state': 'state',
      'restorationData': <dynamic, dynamic>{'test': 'config'},
    };
    final ByteData message = const JSONMethodCodec().encodeMethodCall(
      const MethodCall('pushRouteInformation', testRouteInformation),
    );
    await tester.binding.defaultBinaryMessenger
        .handlePlatformMessage('flutter/navigation', message, (_) {});
    expect(observer.pushedRoute, 'testRouteName');
    WidgetsBinding.instance.removeObserver(observer);
  });

  testWidgetsWithLeakTracking('didPushRouteInformation calls didPushRoute correctly when handling url', (WidgetTester tester) async {
    final PushRouteObserver observer = PushRouteObserver();
    WidgetsBinding.instance.addObserver(observer);

    // A url without any path.
    Map<String, dynamic> testRouteInformation = const <String, dynamic>{
      'location': 'http://hostname',
      'state': 'state',
      'restorationData': <dynamic, dynamic>{'test': 'config'},
    };
    ByteData message = const JSONMethodCodec().encodeMethodCall(
      MethodCall('pushRouteInformation', testRouteInformation),
    );
    await ServicesBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage('flutter/navigation', message, (_) {});
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
    await ServicesBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage('flutter/navigation', message, (_) {});
    expect(observer.pushedRoute, '/abc?def=123&def=456#789');
    WidgetsBinding.instance.removeObserver(observer);
  });

  testWidgetsWithLeakTracking('didPushRouteInformation callback', (WidgetTester tester) async {
    final PushRouteInformationObserver observer = PushRouteInformationObserver();
    WidgetsBinding.instance.addObserver(observer);

    const Map<String, dynamic> testRouteInformation = <String, dynamic>{
      'location': 'testRouteName',
      'state': 'state',
    };
    final ByteData message = const JSONMethodCodec().encodeMethodCall(
      const MethodCall('pushRouteInformation', testRouteInformation),
    );
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage('flutter/navigation', message, (_) { });
    expect(observer.pushedRouteInformation.uri.toString(), 'testRouteName');
    expect(observer.pushedRouteInformation.state, 'state');
    WidgetsBinding.instance.removeObserver(observer);
  });

  testWidgetsWithLeakTracking('didPushRouteInformation callback can handle url', (WidgetTester tester) async {
    final PushRouteInformationObserver observer = PushRouteInformationObserver();
    WidgetsBinding.instance.addObserver(observer);

    const Map<String, dynamic> testRouteInformation = <String, dynamic>{
      'location': 'http://hostname/abc?def=123&def=456#789',
      'state': 'state',
    };
    final ByteData message = const JSONMethodCodec().encodeMethodCall(
      const MethodCall('pushRouteInformation', testRouteInformation),
    );
    await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage('flutter/navigation', message, (_) { });
    expect(observer.pushedRouteInformation.location, '/abc?def=123&def=456#789');
    expect(observer.pushedRouteInformation.uri.toString(), 'http://hostname/abc?def=123&def=456#789');
    expect(observer.pushedRouteInformation.state, 'state');
    WidgetsBinding.instance.removeObserver(observer);
  });

  testWidgetsWithLeakTracking('didPushRouteInformation callback with null state', (WidgetTester tester) async {
    final PushRouteInformationObserver observer = PushRouteInformationObserver();
    WidgetsBinding.instance.addObserver(observer);

    const Map<String, dynamic> testRouteInformation = <String, dynamic>{
      'location': 'testRouteName',
      'state': null,
    };
    final ByteData message = const JSONMethodCodec().encodeMethodCall(
      const MethodCall('pushRouteInformation', testRouteInformation),
    );

    await tester.binding.defaultBinaryMessenger.handlePlatformMessage('flutter/navigation', message, (_) { });
    expect(observer.pushedRouteInformation.uri.toString(), 'testRouteName');
    expect(observer.pushedRouteInformation.state, null);
    WidgetsBinding.instance.removeObserver(observer);
  });

  testWidgetsWithLeakTracking('Application lifecycle affects frame scheduling', (WidgetTester tester) async {
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
    await setAppLifeCycleState(AppLifecycleState.resumed);
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump();
  });

  testWidgetsWithLeakTracking('scheduleFrameCallback error control test', (WidgetTester tester) async {
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

  testWidgetsWithLeakTracking('defaultStackFilter elides framework Element mounting stacks', (WidgetTester tester) async {
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
