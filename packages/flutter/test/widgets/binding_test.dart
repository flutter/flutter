// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

void main() {
  final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding();

  test('didHaveMemoryPressure callback', () async {
    final MemoryPressureObserver observer = MemoryPressureObserver();
    WidgetsBinding.instance.addObserver(observer);
    final ByteData message = const JSONMessageCodec().encodeMessage(<String, dynamic>{'type': 'memoryPressure'})!;
    await binding.defaultBinaryMessenger.handlePlatformMessage('flutter/system', message, (_) { });
    expect(observer.sawMemoryPressure, true);
    WidgetsBinding.instance.removeObserver(observer);
  });

  test('didPushRoute callback', () async {
    final PushRouteObserver observer = PushRouteObserver();
    WidgetsBinding.instance.addObserver(observer);

    const String testRouteName = 'testRouteName';
    final ByteData message = const JSONMethodCodec().encodeMethodCall(const MethodCall('pushRoute', testRouteName));
    await binding.defaultBinaryMessenger.handlePlatformMessage('flutter/navigation', message, (_) { });
    expect(observer.pushedRoute, testRouteName);

    WidgetsBinding.instance.removeObserver(observer);
  });

  test('didPushRouteInformation calls didPushRoute by default', () async {
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
    await binding.defaultBinaryMessenger.handlePlatformMessage('flutter/navigation', message, (_) {});
    expect(observer.pushedRoute, 'testRouteName');
    WidgetsBinding.instance.removeObserver(observer);
  });

  test('didPushRouteInformation callback', () async {
    final PushRouteInformationObserver observer = PushRouteInformationObserver();
    WidgetsBinding.instance.addObserver(observer);

    const Map<String, dynamic> testRouteInformation = <String, dynamic>{
      'location': 'testRouteName',
      'state': 'state',
    };
    final ByteData message = const JSONMethodCodec().encodeMethodCall(
      const MethodCall('pushRouteInformation', testRouteInformation),
    );
    await binding.defaultBinaryMessenger.handlePlatformMessage('flutter/navigation', message, (_) { });
    expect(observer.pushedRouteInformation.location, 'testRouteName');
    expect(observer.pushedRouteInformation.state, 'state');
    WidgetsBinding.instance.removeObserver(observer);
  });

  test('didPushRouteInformation callback with null state', () async {
    final PushRouteInformationObserver observer = PushRouteInformationObserver();
    WidgetsBinding.instance.addObserver(observer);

    const Map<String, dynamic> testRouteInformation = <String, dynamic>{
      'location': 'testRouteName',
      'state': null,
    };
    final ByteData message = const JSONMethodCodec().encodeMethodCall(
      const MethodCall('pushRouteInformation', testRouteInformation),
    );
    await binding.defaultBinaryMessenger.handlePlatformMessage('flutter/navigation', message, (_) { });
    expect(observer.pushedRouteInformation.location, 'testRouteName');
    expect(observer.pushedRouteInformation.state, null);
    WidgetsBinding.instance.removeObserver(observer);
  });
}

class TestWidgetsFlutterBinding extends WidgetsFlutterBinding with TestDefaultBinaryMessengerBinding { }
