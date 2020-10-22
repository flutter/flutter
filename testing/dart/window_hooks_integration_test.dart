// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.10

// HACK: pretend to be dart.ui in order to access its internals
library dart.ui;

import 'dart:async';
// this needs to be imported because painting.dart expects it this way
import 'dart:collection' as collection;
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'dart:nativewrappers'; // ignore: unused_import
import 'dart:typed_data';


// HACK: these parts are to get access to private functions tested here.
part '../../lib/ui/annotations.dart';
part '../../lib/ui/channel_buffers.dart';
part '../../lib/ui/compositing.dart';
part '../../lib/ui/geometry.dart';
part '../../lib/ui/hash_codes.dart';
part '../../lib/ui/hooks.dart';
part '../../lib/ui/lerp.dart';
part '../../lib/ui/natives.dart';
part '../../lib/ui/painting.dart';
part '../../lib/ui/platform_dispatcher.dart';
part '../../lib/ui/pointer.dart';
part '../../lib/ui/semantics.dart';
part '../../lib/ui/text.dart';
part '../../lib/ui/window.dart';

void main() {
  VoidCallback? originalOnMetricsChanged;
  VoidCallback? originalOnLocaleChanged;
  FrameCallback? originalOnBeginFrame;
  VoidCallback? originalOnDrawFrame;
  TimingsCallback? originalOnReportTimings;
  PointerDataPacketCallback? originalOnPointerDataPacket;
  VoidCallback? originalOnSemanticsEnabledChanged;
  SemanticsActionCallback? originalOnSemanticsAction;
  PlatformMessageCallback? originalOnPlatformMessage;
  VoidCallback? originalOnTextScaleFactorChanged;

    Object? oldWindowId;
    double? oldDevicePixelRatio;
    Rect? oldGeometry;

    WindowPadding? oldPadding;
    WindowPadding? oldInsets;
    WindowPadding? oldSystemGestureInsets;

  void setUp() {
    PlatformDispatcher.instance._viewConfigurations.clear();
    PlatformDispatcher.instance._views.clear();
    PlatformDispatcher.instance._viewConfigurations[0] = const ViewConfiguration();
    PlatformDispatcher.instance._views[0] = FlutterWindow._(0, PlatformDispatcher.instance);
    oldWindowId = window._windowId;
    oldDevicePixelRatio = window.devicePixelRatio;
    oldGeometry = window.viewConfiguration.geometry;
    oldPadding = window.viewPadding;
    oldInsets = window.viewInsets;
    oldSystemGestureInsets = window.systemGestureInsets;

    originalOnMetricsChanged = window.onMetricsChanged;
    originalOnLocaleChanged = window.onLocaleChanged;
    originalOnBeginFrame = window.onBeginFrame;
    originalOnDrawFrame = window.onDrawFrame;
    originalOnReportTimings = window.onReportTimings;
    originalOnPointerDataPacket = window.onPointerDataPacket;
    originalOnSemanticsEnabledChanged = window.onSemanticsEnabledChanged;
    originalOnSemanticsAction = window.onSemanticsAction;
    originalOnPlatformMessage = window.onPlatformMessage;
    originalOnTextScaleFactorChanged = window.onTextScaleFactorChanged;
  }

    tearDown() {
      _updateWindowMetrics(
        oldWindowId!,                    // window id
        oldDevicePixelRatio!,            // device pixel ratio
        oldGeometry!.width,              // width
        oldGeometry!.height,             // height
        oldPadding!.top,                 // padding top
        oldPadding!.right,               // padding right
        oldPadding!.bottom,              // padding bottom
        oldPadding!.left,                // padding left
        oldInsets!.top,                  // inset top
        oldInsets!.right,                // inset right
        oldInsets!.bottom,               // inset bottom
        oldInsets!.left,                 // inset left
        oldSystemGestureInsets!.top,     // system gesture inset top
        oldSystemGestureInsets!.right,   // system gesture inset right
        oldSystemGestureInsets!.bottom,  // system gesture inset bottom
        oldSystemGestureInsets!.left,    // system gesture inset left
      );
      window.onMetricsChanged = originalOnMetricsChanged;
      window.onLocaleChanged = originalOnLocaleChanged;
      window.onBeginFrame = originalOnBeginFrame;
      window.onDrawFrame = originalOnDrawFrame;
      window.onReportTimings = originalOnReportTimings;
      window.onPointerDataPacket = originalOnPointerDataPacket;
      window.onSemanticsEnabledChanged = originalOnSemanticsEnabledChanged;
      window.onSemanticsAction = originalOnSemanticsAction;
      window.onPlatformMessage = originalOnPlatformMessage;
      window.onTextScaleFactorChanged = originalOnTextScaleFactorChanged;
  }

  void test(String description, void Function() testFunction) {
    print(description);
    setUp();
    testFunction();
    tearDown();
  }

  void expectEquals(dynamic actual, dynamic expected) {
    if (actual != expected) {
      throw Exception('Equality check failed:\n  Expected: $expected\n  Actual: $actual');
    }
  }

  void expectIterablesEqual(Iterable<dynamic> actual, Iterable<dynamic> expected) {
    expectEquals(actual.length, expected.length);
    final Iterator<dynamic> actualIter = actual.iterator;
    final Iterator<dynamic> expectedIter = expected.iterator;
    while (expectedIter.moveNext()) {
      expectEquals(actualIter.moveNext(), true);
      expectEquals(actualIter.current, expectedIter.current);
    }
    expectEquals(actualIter.moveNext(), false);
  }

  void expectNotEquals(dynamic actual, dynamic expected) {
    if (actual == expected) {
      throw Exception('Inequality check failed:\n  Expected: $expected\n  Actual: $actual');
    }
  }

  void expectIdentical(dynamic actual, dynamic expected) {
    if (!identical(actual, expected)) {
      throw Exception('Identity check failed:\n  Expected: $expected\n  Actual: $actual');
    }
  }

  test('updateUserSettings can handle an empty object', () {
    // this should not throw.
    _updateUserSettingsData('{}');
  });

  test('onMetricsChanged preserves callback zone', () {
    late Zone innerZone;
    late Zone runZone;
    late double devicePixelRatio;

    runZoned(() {
      innerZone = Zone.current;
      window.onMetricsChanged = () {
        runZone = Zone.current;
        devicePixelRatio = window.devicePixelRatio;
      };
    });

    window.onMetricsChanged!();
    _updateWindowMetrics(
      0,      // window id
      0.1234, // device pixel ratio
      0.0,    // width
      0.0,    // height
      0.0,    // padding top
      0.0,    // padding right
      0.0,    // padding bottom
      0.0,    // padding left
      0.0,    // inset top
      0.0,    // inset right
      0.0,    // inset bottom
      0.0,    // inset left
      0.0,    // system gesture inset top
      0.0,    // system gesture inset right
      0.0,    // system gesture inset bottom
      0.0,    // system gesture inset left
    );
    expectNotEquals(runZone, null);
    expectIdentical(runZone, innerZone);
    expectEquals(devicePixelRatio, 0.1234);
  });

  test('onLocaleChanged preserves callback zone', () {
    late Zone innerZone;
    late Zone runZone;
    Locale? locale;

    runZoned(() {
      innerZone = Zone.current;
      window.onLocaleChanged = () {
        runZone = Zone.current;
        locale = window.locale;
      };
    });

    _updateLocales(<String>['en', 'US', '', '']);
    expectNotEquals(runZone, null);
    expectIdentical(runZone, innerZone);
    expectEquals(locale, const Locale('en', 'US'));
  });

  test('onBeginFrame preserves callback zone', () {
    late Zone innerZone;
    late Zone runZone;
    late Duration start;

    runZoned(() {
      innerZone = Zone.current;
      window.onBeginFrame = (Duration value) {
        runZone = Zone.current;
        start = value;
      };
    });

    _beginFrame(1234);
    expectNotEquals(runZone, null);
    expectIdentical(runZone, innerZone);
    expectEquals(start, const Duration(microseconds: 1234));
  });

  test('onDrawFrame preserves callback zone', () {
    late Zone innerZone;
    late Zone runZone;

    runZoned(() {
      innerZone = Zone.current;
      window.onDrawFrame = () {
        runZone = Zone.current;
      };
    });

    _drawFrame();
    expectNotEquals(runZone, null);
    expectIdentical(runZone, innerZone);
  });

  test('onReportTimings preserves callback zone', () {
    late Zone innerZone;
    late Zone runZone;

    PlatformDispatcher.instance._setNeedsReportTimings = (bool _) {};

    runZoned(() {
      innerZone = Zone.current;
      window.onReportTimings = (List<FrameTiming> timings) {
        runZone = Zone.current;
      };
    });

    _reportTimings(<int>[]);
    expectNotEquals(runZone, null);
    expectIdentical(runZone, innerZone);
  });

  test('onPointerDataPacket preserves callback zone', () {
    late Zone innerZone;
    late Zone runZone;
    late PointerDataPacket data;

    runZoned(() {
      innerZone = Zone.current;
      window.onPointerDataPacket = (PointerDataPacket value) {
        runZone = Zone.current;
        data = value;
      };
    });

    final ByteData testData = ByteData.view(Uint8List(0).buffer);
    _dispatchPointerDataPacket(testData);
    expectNotEquals(runZone, null);
    expectIdentical(runZone, innerZone);
    expectIterablesEqual(data.data, PlatformDispatcher._unpackPointerDataPacket(testData).data);
  });

  test('onSemanticsEnabledChanged preserves callback zone', () {
    late Zone innerZone;
    late Zone runZone;
    late bool enabled;

    runZoned(() {
      innerZone = Zone.current;
      window.onSemanticsEnabledChanged = () {
        runZone = Zone.current;
        enabled = window.semanticsEnabled;
      };
    });

    final bool newValue = !window.semanticsEnabled; // needed?
    _updateSemanticsEnabled(newValue);
    expectNotEquals(runZone, null);
    expectIdentical(runZone, innerZone);
    expectNotEquals(enabled, null);
    expectEquals(enabled, newValue);
  });

  test('onSemanticsAction preserves callback zone', () {
    late Zone innerZone;
    late Zone runZone;
    late int id;
    late int action;

    runZoned(() {
      innerZone = Zone.current;
      window.onSemanticsAction = (int i, SemanticsAction a, ByteData? _) {
        runZone = Zone.current;
        action = a.index;
        id = i;
      };
    });

    _dispatchSemanticsAction(1234, 4, null);
    expectNotEquals(runZone, null);
    expectIdentical(runZone, innerZone);
    expectEquals(id, 1234);
    expectEquals(action, 4);
  });

  test('onPlatformMessage preserves callback zone', () {
    late Zone innerZone;
    late Zone runZone;
    late String name;

    runZoned(() {
      innerZone = Zone.current;
      window.onPlatformMessage = (String value, _, __) {
        runZone = Zone.current;
        name = value;
      };
    });

    _dispatchPlatformMessage('testName', null, 123456789);
    expectNotEquals(runZone, null);
    expectIdentical(runZone, innerZone);
    expectEquals(name, 'testName');
  });

  test('onTextScaleFactorChanged preserves callback zone', () {
    late Zone innerZone;
    late Zone runZoneTextScaleFactor;
    late Zone runZonePlatformBrightness;
    late double? textScaleFactor;
    late Brightness? platformBrightness;

    runZoned(() {
      innerZone = Zone.current;
      window.onTextScaleFactorChanged = () {
        runZoneTextScaleFactor = Zone.current;
        textScaleFactor = window.textScaleFactor;
      };
      window.onPlatformBrightnessChanged = () {
        runZonePlatformBrightness = Zone.current;
        platformBrightness = window.platformBrightness;
      };
    });

    window.onTextScaleFactorChanged!();

    _updateUserSettingsData('{"textScaleFactor": 0.5, "platformBrightness": "light", "alwaysUse24HourFormat": true}');
    expectNotEquals(runZoneTextScaleFactor, null);
    expectIdentical(runZoneTextScaleFactor, innerZone);
    expectEquals(textScaleFactor, 0.5);

    textScaleFactor = null;
    platformBrightness = null;

    window.onPlatformBrightnessChanged!();
    _updateUserSettingsData('{"textScaleFactor": 0.5, "platformBrightness": "dark", "alwaysUse24HourFormat": true}');
    expectNotEquals(runZonePlatformBrightness, null);
    expectIdentical(runZonePlatformBrightness, innerZone);
    expectEquals(platformBrightness, Brightness.dark);

  });

  test('Window padding/insets/viewPadding/systemGestureInsets', () {
    _updateWindowMetrics(
      0,     // window id
      0,     // screen id
      800.0, // width
      600.0, // height
      50.0,  // padding top
      0.0,   // padding right
      40.0,  // padding bottom
      0.0,   // padding left
      0.0,   // inset top
      0.0,   // inset right
      0.0,   // inset bottom
      0.0,   // inset left
      0.0,   // system gesture inset top
      0.0,   // system gesture inset right
      0.0,   // system gesture inset bottom
      0.0,   // system gesture inset left
    );

    expectEquals(window.viewInsets.bottom, 0.0);
    expectEquals(window.viewPadding.bottom, 40.0);
    expectEquals(window.padding.bottom, 40.0);
    expectEquals(window.systemGestureInsets.bottom, 0.0);

    _updateWindowMetrics(
      0,     // window id
      0,     // screen id
      800.0, // width
      600.0, // height
      50.0,  // padding top
      0.0,   // padding right
      40.0,  // padding bottom
      0.0,   // padding left
      0.0,   // inset top
      0.0,   // inset right
      400.0, // inset bottom
      0.0,   // inset left
      0.0,   // system gesture inset top
      0.0,   // system gesture inset right
      44.0,  // system gesture inset bottom
      0.0,   // system gesture inset left
    );

    expectEquals(window.viewInsets.bottom, 400.0);
    expectEquals(window.viewPadding.bottom, 40.0);
    expectEquals(window.padding.bottom, 0.0);
    expectEquals(window.systemGestureInsets.bottom, 44.0);
  });
}
