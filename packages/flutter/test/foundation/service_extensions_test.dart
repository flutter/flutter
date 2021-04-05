// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class TestServiceExtensionsBinding extends BindingBase
  with SchedulerBinding,
       ServicesBinding,
       GestureBinding,
       PaintingBinding,
       SemanticsBinding,
       RendererBinding,
       WidgetsBinding {

  final Map<String, ServiceExtensionCallback> extensions = <String, ServiceExtensionCallback>{};

  final Map<String, List<Map<String, dynamic>>> eventsDispatched = <String, List<Map<String, dynamic>>>{};

  @override
  @protected
  void registerServiceExtension({
    required String name,
    required ServiceExtensionCallback callback,
  }) {
    expect(extensions.containsKey(name), isFalse);
    extensions[name] = callback;
  }

  @override
  void postEvent(String eventKind, Map<String, dynamic> eventData) {
    getEventsDispatched(eventKind).add(eventData);
  }

  List<Map<String, dynamic>> getEventsDispatched(String eventKind) {
    return eventsDispatched.putIfAbsent(eventKind, () => <Map<String, dynamic>>[]);
  }

  Iterable<Map<String, dynamic>> getServiceExtensionStateChangedEvents(String extensionName) {
    return getEventsDispatched('Flutter.ServiceExtensionStateChanged')
      .where((Map<String, dynamic> event) => event['extension'] == extensionName);
  }

  Future<Map<String, dynamic>> testExtension(String name, Map<String, String> arguments) {
    expect(extensions.containsKey(name), isTrue);
    return extensions[name]!(arguments);
  }

  int reassembled = 0;
  bool pendingReassemble = false;
  @override
  Future<void> performReassemble() {
    reassembled += 1;
    pendingReassemble = true;
    return super.performReassemble();
  }

  bool frameScheduled = false;
  @override
  void scheduleFrame() {
    ensureFrameCallbacksRegistered();
    frameScheduled = true;
  }
  Future<void> doFrame() async {
    frameScheduled = false;
    ui.window.onBeginFrame?.call(Duration.zero);
    await flushMicrotasks();
    ui.window.onDrawFrame?.call();
    ui.window.onReportTimings?.call(<ui.FrameTiming>[]);
  }

  @override
  void scheduleForcedFrame() {
    expect(true, isFalse);
  }

  @override
  void scheduleWarmUpFrame() {
    expect(pendingReassemble, isTrue);
    pendingReassemble = false;
  }

  Future<void> flushMicrotasks() {
    final Completer<void> completer = Completer<void>();
    Timer.run(completer.complete);
    return completer.future;
  }
}

late TestServiceExtensionsBinding binding;

Future<Map<String, dynamic>> hasReassemble(Future<Map<String, dynamic>> pendingResult) async {
  bool completed = false;
  pendingResult.whenComplete(() { completed = true; });
  expect(binding.frameScheduled, isFalse);
  await binding.flushMicrotasks();
  expect(binding.frameScheduled, isTrue);
  expect(completed, isFalse);
  await binding.flushMicrotasks();
  await binding.doFrame();
  await binding.flushMicrotasks();
  expect(completed, isTrue);
  expect(binding.frameScheduled, isFalse);
  return pendingResult;
}

void main() {
  final List<String?> console = <String?>[];

  setUpAll(() async {
    binding = TestServiceExtensionsBinding()..scheduleFrame();
    expect(binding.frameScheduled, isTrue);

    // We need to test this service extension here because the result is true
    // after the first binding.doFrame() call.
    Map<String, dynamic> firstFrameResult;
    expect(binding.debugDidSendFirstFrameEvent, isFalse);
    firstFrameResult = await binding.testExtension('didSendFirstFrameEvent', <String, String>{});
    expect(firstFrameResult, <String, String>{'enabled': 'false'});

    expect(binding.firstFrameRasterized, isFalse);
    firstFrameResult = await binding.testExtension('didSendFirstFrameRasterizedEvent', <String, String>{});
    expect(firstFrameResult, <String, String>{'enabled': 'false'});

    await binding.doFrame();

    expect(binding.debugDidSendFirstFrameEvent, isTrue);
    firstFrameResult = await binding.testExtension('didSendFirstFrameEvent', <String, String>{});
    expect(firstFrameResult, <String, String>{'enabled': 'true'});

    expect(binding.firstFrameRasterized, isTrue);
    firstFrameResult = await binding.testExtension('didSendFirstFrameRasterizedEvent', <String, String>{});
    expect(firstFrameResult, <String, String>{'enabled': 'true'});

    expect(binding.frameScheduled, isFalse);

    expect(debugPrint, equals(debugPrintThrottled));
    debugPrint = (String? message, { int? wrapWidth }) {
      console.add(message);
    };
  });

  tearDownAll(() async {
    // See widget_inspector_test.dart for tests of the ext.flutter.inspector
    // service extensions included in this count.
    int widgetInspectorExtensionCount = 16;
    if (WidgetInspectorService.instance.isWidgetCreationTracked()) {
      // Some inspector extensions are only exposed if widget creation locations
      // are tracked.
      widgetInspectorExtensionCount += 2;
    }

    // The following service extensions are disabled in web:
    // 1. exit
    // 2. showPerformanceOverlay
    const int disabledExtensions = kIsWeb ? 2 : 0;
    // If you add a service extension... TEST IT! :-)
    // ...then increment this number.
    expect(binding.extensions.length, 31 + widgetInspectorExtensionCount - disabledExtensions);

    expect(console, isEmpty);
    debugPrint = debugPrintThrottled;
  });

  // The following list is alphabetical, one test per extension.

  test('Service extensions - debugAllowBanner', () async {
    Map<String, dynamic> result;

    expect(binding.frameScheduled, isFalse);
    expect(WidgetsApp.debugAllowBannerOverride, true);
    result = await binding.testExtension('debugAllowBanner', <String, String>{});
    expect(result, <String, String>{'enabled': 'true'});
    expect(WidgetsApp.debugAllowBannerOverride, true);
    result = await binding.testExtension('debugAllowBanner', <String, String>{'enabled': 'false'});
    expect(result, <String, String>{'enabled': 'false'});
    expect(WidgetsApp.debugAllowBannerOverride, false);
    result = await binding.testExtension('debugAllowBanner', <String, String>{});
    expect(result, <String, String>{'enabled': 'false'});
    expect(WidgetsApp.debugAllowBannerOverride, false);
    result = await binding.testExtension('debugAllowBanner', <String, String>{'enabled': 'true'});
    expect(result, <String, String>{'enabled': 'true'});
    expect(WidgetsApp.debugAllowBannerOverride, true);
    result = await binding.testExtension('debugAllowBanner', <String, String>{});
    expect(result, <String, String>{'enabled': 'true'});
    expect(WidgetsApp.debugAllowBannerOverride, true);
    expect(binding.frameScheduled, isFalse);
  });

  test('Service extensions - debugCheckElevationsEnabled', () async {
    expect(binding.frameScheduled, isFalse);
    expect(debugCheckElevationsEnabled, false);

    bool lastValue = false;
    Future<void> _updateAndCheck(bool newValue) async {
      Map<String, dynamic>? result;
      binding.testExtension(
        'debugCheckElevationsEnabled',
        <String, String>{'enabled': '$newValue'},
      ).then((Map<String, dynamic> answer) => result = answer);
      await binding.flushMicrotasks();
      expect(binding.frameScheduled, lastValue != newValue);
      await binding.doFrame();
      await binding.flushMicrotasks();
      expect(result, <String, String>{'enabled': '$newValue'});
      expect(debugCheckElevationsEnabled, newValue);
      lastValue = newValue;
    }

    await _updateAndCheck(false);
    await _updateAndCheck(true);
    await _updateAndCheck(true);
    await _updateAndCheck(false);
    await _updateAndCheck(false);
    expect(binding.frameScheduled, isFalse);
  });

  test('Service extensions - debugDumpApp', () async {
    final Map<String, dynamic> result = await binding.testExtension('debugDumpApp', <String, String>{});

    expect(result, <String, dynamic>{
      'data': matches('TestServiceExtensionsBinding - DEBUG MODE\n<no tree currently mounted>'),
    });
  });

  test('Service extensions - debugDumpRenderTree', () async {
    await binding.doFrame();
    final Map<String, dynamic> result = await binding.testExtension('debugDumpRenderTree', <String, String>{});

    expect(result, <String, dynamic>{
      'data': matches(
        r'^'
        r'RenderView#[0-9a-f]{5}\n'
        r'   debug mode enabled - [a-zA-Z]+\n'
        r'   window size: Size\(2400\.0, 1800\.0\) \(in physical pixels\)\n'
        r'   device pixel ratio: 3\.0 \(physical pixels per logical pixel\)\n'
        r'   configuration: Size\(800\.0, 600\.0\) at 3\.0x \(in logical pixels\)\n'
        r'$'
      ),
    });
  });

  test('Service extensions - debugDumpLayerTree', () async {
    await binding.doFrame();
    final Map<String, dynamic> result = await binding.testExtension('debugDumpLayerTree', <String, String>{});

    expect(result, <String, dynamic>{
      'data': matches(
        r'^'
        r'TransformLayer#[0-9a-f]{5}\n'
        r'   owner: RenderView#[0-9a-f]{5}\n'
        r'   creator: RenderView\n'
        r'   engine layer: (TransformEngineLayer|PersistedTransform)#[0-9a-f]{5}\n'
        r'   offset: Offset\(0\.0, 0\.0\)\n'
        r'   transform:\n'
        r'     \[0] 3\.0,0\.0,0\.0,0\.0\n'
        r'     \[1] 0\.0,3\.0,0\.0,0\.0\n'
        r'     \[2] 0\.0,0\.0,1\.0,0\.0\n'
        r'     \[3] 0\.0,0\.0,0\.0,1\.0\n'
        r'$'
      ),
    });
  });

  test('Service extensions - debugDumpSemanticsTreeInTraversalOrder', () async {
    await binding.doFrame();
    final Map<String, dynamic> result = await binding.testExtension('debugDumpSemanticsTreeInTraversalOrder', <String, String>{});

    expect(result, <String, String>{
      'data': 'Semantics not collected.'
    });
  });

  test('Service extensions - debugDumpSemanticsTreeInInverseHitTestOrder', () async {
    await binding.doFrame();
    final Map<String, dynamic> result = await binding.testExtension('debugDumpSemanticsTreeInInverseHitTestOrder', <String, String>{});

    expect(result, <String, String>{
      'data': 'Semantics not collected.'
    });
  });

  test('Service extensions - debugPaint', () async {
    final Iterable<Map<String, dynamic>> extensionChangedEvents = binding.getServiceExtensionStateChangedEvents('ext.flutter.debugPaint');
    Map<String, dynamic> extensionChangedEvent;
    Map<String, dynamic> result;
    Future<Map<String, dynamic>> pendingResult;
    bool completed;

    expect(binding.frameScheduled, isFalse);
    expect(debugPaintSizeEnabled, false);
    result = await binding.testExtension('debugPaint', <String, String>{});
    expect(result, <String, String>{'enabled': 'false'});
    expect(debugPaintSizeEnabled, false);
    expect(extensionChangedEvents, isEmpty);
    expect(binding.frameScheduled, isFalse);
    pendingResult = binding.testExtension('debugPaint', <String, String>{'enabled': 'true'});
    completed = false;
    pendingResult.whenComplete(() { completed = true; });
    await binding.flushMicrotasks();
    expect(binding.frameScheduled, isTrue);
    expect(completed, isFalse);
    await binding.doFrame();
    await binding.flushMicrotasks();
    expect(completed, isTrue);
    expect(binding.frameScheduled, isFalse);
    result = await pendingResult;
    expect(result, <String, String>{'enabled': 'true'});
    expect(debugPaintSizeEnabled, true);
    expect(extensionChangedEvents.length, 1);
    extensionChangedEvent = extensionChangedEvents.last;
    expect(extensionChangedEvent['extension'], 'ext.flutter.debugPaint');
    expect(extensionChangedEvent['value'], 'true');
    result = await binding.testExtension('debugPaint', <String, String>{});
    expect(result, <String, String>{'enabled': 'true'});
    expect(debugPaintSizeEnabled, true);
    expect(extensionChangedEvents.length, 1);
    expect(binding.frameScheduled, isFalse);
    pendingResult = binding.testExtension('debugPaint', <String, String>{'enabled': 'false'});
    await binding.flushMicrotasks();
    expect(binding.frameScheduled, isTrue);
    await binding.doFrame();
    expect(binding.frameScheduled, isFalse);
    result = await pendingResult;
    expect(result, <String, String>{'enabled': 'false'});
    expect(debugPaintSizeEnabled, false);
    expect(extensionChangedEvents.length, 2);
    extensionChangedEvent = extensionChangedEvents.last;
    expect(extensionChangedEvent['extension'], 'ext.flutter.debugPaint');
    expect(extensionChangedEvent['value'], 'false');
    result = await binding.testExtension('debugPaint', <String, String>{});
    expect(result, <String, String>{'enabled': 'false'});
    expect(debugPaintSizeEnabled, false);
    expect(extensionChangedEvents.length, 2);
    expect(binding.frameScheduled, isFalse);
  });

  test('Service extensions - debugPaintBaselinesEnabled', () async {
    Map<String, dynamic> result;
    Future<Map<String, dynamic>> pendingResult;
    bool completed;

    expect(binding.frameScheduled, isFalse);
    expect(debugPaintBaselinesEnabled, false);
    result = await binding.testExtension('debugPaintBaselinesEnabled', <String, String>{});
    expect(result, <String, String>{'enabled': 'false'});
    expect(debugPaintBaselinesEnabled, false);
    expect(binding.frameScheduled, isFalse);
    pendingResult = binding.testExtension('debugPaintBaselinesEnabled', <String, String>{'enabled': 'true'});
    completed = false;
    pendingResult.whenComplete(() { completed = true; });
    await binding.flushMicrotasks();
    expect(binding.frameScheduled, isTrue);
    expect(completed, isFalse);
    await binding.doFrame();
    await binding.flushMicrotasks();
    expect(completed, isTrue);
    expect(binding.frameScheduled, isFalse);
    result = await pendingResult;
    expect(result, <String, String>{'enabled': 'true'});
    expect(debugPaintBaselinesEnabled, true);
    result = await binding.testExtension('debugPaintBaselinesEnabled', <String, String>{});
    expect(result, <String, String>{'enabled': 'true'});
    expect(debugPaintBaselinesEnabled, true);
    expect(binding.frameScheduled, isFalse);
    pendingResult = binding.testExtension('debugPaintBaselinesEnabled', <String, String>{'enabled': 'false'});
    await binding.flushMicrotasks();
    expect(binding.frameScheduled, isTrue);
    await binding.doFrame();
    expect(binding.frameScheduled, isFalse);
    result = await pendingResult;
    expect(result, <String, String>{'enabled': 'false'});
    expect(debugPaintBaselinesEnabled, false);
    result = await binding.testExtension('debugPaintBaselinesEnabled', <String, String>{});
    expect(result, <String, String>{'enabled': 'false'});
    expect(debugPaintBaselinesEnabled, false);
    expect(binding.frameScheduled, isFalse);
  });

  test('Service extensions - invertOversizedImages', () async {
    Map<String, dynamic> result;
    Future<Map<String, dynamic>> pendingResult;
    bool completed;

    expect(binding.frameScheduled, isFalse);
    expect(debugInvertOversizedImages, false);
    result = await binding.testExtension('invertOversizedImages', <String, String>{});
    expect(result, <String, String>{'enabled': 'false'});
    expect(debugInvertOversizedImages, false);
    expect(binding.frameScheduled, isFalse);

    pendingResult = binding.testExtension('invertOversizedImages', <String, String>{'enabled': 'true'});
    completed = false;
    pendingResult.whenComplete(() { completed = true; });
    await binding.flushMicrotasks();
    expect(binding.frameScheduled, isTrue);
    expect(completed, isFalse);
    await binding.doFrame();
    await binding.flushMicrotasks();
    expect(completed, isTrue);
    expect(binding.frameScheduled, isFalse);
    result = await pendingResult;
    expect(result, <String, String>{'enabled': 'true'});
    expect(debugInvertOversizedImages, true);

    result = await binding.testExtension('invertOversizedImages', <String, String>{});
    expect(result, <String, String>{'enabled': 'true'});
    expect(debugInvertOversizedImages, true);
    expect(binding.frameScheduled, isFalse);

    pendingResult = binding.testExtension('invertOversizedImages', <String, String>{'enabled': 'false'});
    await binding.flushMicrotasks();
    expect(binding.frameScheduled, isTrue);
    await binding.doFrame();
    expect(binding.frameScheduled, isFalse);
    result = await pendingResult;
    expect(result, <String, String>{'enabled': 'false'});
    expect(debugInvertOversizedImages, false);

    result = await binding.testExtension('invertOversizedImages', <String, String>{});
    expect(result, <String, String>{'enabled': 'false'});
    expect(debugInvertOversizedImages, false);
    expect(binding.frameScheduled, isFalse);
  });

  test('Service extensions - profileWidgetBuilds', () async {
    Map<String, dynamic> result;

    expect(binding.frameScheduled, isFalse);
    expect(debugProfileBuildsEnabled, false);

    result = await binding.testExtension('profileWidgetBuilds', <String, String>{});
    expect(result, <String, String>{'enabled': 'false'});
    expect(debugProfileBuildsEnabled, false);

    result = await binding.testExtension('profileWidgetBuilds', <String, String>{'enabled': 'true'});
    expect(result, <String, String>{'enabled': 'true'});
    expect(debugProfileBuildsEnabled, true);

    result = await binding.testExtension('profileWidgetBuilds', <String, String>{});
    expect(result, <String, String>{'enabled': 'true'});
    expect(debugProfileBuildsEnabled, true);

    result = await binding.testExtension('profileWidgetBuilds', <String, String>{'enabled': 'false'});
    expect(result, <String, String>{'enabled': 'false'});
    expect(debugProfileBuildsEnabled, false);

    result = await binding.testExtension('profileWidgetBuilds', <String, String>{});
    expect(result, <String, String>{'enabled': 'false'});
    expect(debugProfileBuildsEnabled, false);

    expect(binding.frameScheduled, isFalse);
  });

  test('Service extensions - evict', () async {
    Map<String, dynamic> result;
    bool completed;

    completed = false;
    ServicesBinding.instance!.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (ByteData? message) async {
      expect(utf8.decode(message!.buffer.asUint8List()), 'test');
      completed = true;
      return ByteData(5); // 0x0000000000
    });
    bool data;
    data = await rootBundle.loadStructuredData<bool>('test', (String value) async {
      expect(value, '\x00\x00\x00\x00\x00');
      return true;
    });
    expect(data, isTrue);
    expect(completed, isTrue);
    completed = false;
    data = await rootBundle.loadStructuredData('test', (String value) async {
      throw Error();
    });
    expect(data, isTrue);
    expect(completed, isFalse);
    result = await binding.testExtension('evict', <String, String>{'value': 'test'});
    expect(result, <String, String>{'value': ''});
    expect(completed, isFalse);
    data = await rootBundle.loadStructuredData<bool>('test', (String value) async {
      expect(value, '\x00\x00\x00\x00\x00');
      return false;
    });
    expect(data, isFalse);
    expect(completed, isTrue);
    ServicesBinding.instance!.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', null);
  });

  test('Service extensions - exit', () async {
    // no test for _calling_ 'exit', because that should terminate the process!
    // Not expecting extension to be available for web platform.
    expect(binding.extensions.containsKey('exit'), !isBrowser);
  });

  test('Service extensions - platformOverride', () async {
    final Iterable<Map<String, dynamic>> extensionChangedEvents = binding.getServiceExtensionStateChangedEvents('ext.flutter.platformOverride');
    Map<String, dynamic> extensionChangedEvent;
    Map<String, dynamic> result;

    expect(binding.reassembled, 0);
    expect(defaultTargetPlatform, TargetPlatform.android);
    result = await binding.testExtension('platformOverride', <String, String>{});
    expect(result, <String, String>{'value': 'android'});
    expect(defaultTargetPlatform, TargetPlatform.android);
    expect(extensionChangedEvents, isEmpty);
    result = await hasReassemble(binding.testExtension('platformOverride', <String, String>{'value': 'iOS'}));
    expect(result, <String, String>{'value': 'iOS'});
    expect(binding.reassembled, 1);
    expect(defaultTargetPlatform, TargetPlatform.iOS);
    expect(extensionChangedEvents.length, 1);
    extensionChangedEvent = extensionChangedEvents.last;
    expect(extensionChangedEvent['extension'], 'ext.flutter.platformOverride');
    expect(extensionChangedEvent['value'], 'iOS');
    result = await hasReassemble(binding.testExtension('platformOverride', <String, String>{'value': 'macOS'}));
    expect(result, <String, String>{'value': 'macOS'});
    expect(binding.reassembled, 2);
    expect(defaultTargetPlatform, TargetPlatform.macOS);
    expect(extensionChangedEvents.length, 2);
    extensionChangedEvent = extensionChangedEvents.last;
    expect(extensionChangedEvent['extension'], 'ext.flutter.platformOverride');
    expect(extensionChangedEvent['value'], 'macOS');
    result = await hasReassemble(binding.testExtension('platformOverride', <String, String>{'value': 'android'}));
    expect(result, <String, String>{'value': 'android'});
    expect(binding.reassembled, 3);
    expect(defaultTargetPlatform, TargetPlatform.android);
    expect(extensionChangedEvents.length, 3);
    extensionChangedEvent = extensionChangedEvents.last;
    expect(extensionChangedEvent['extension'], 'ext.flutter.platformOverride');
    expect(extensionChangedEvent['value'], 'android');
    result = await hasReassemble(binding.testExtension('platformOverride', <String, String>{'value': 'fuchsia'}));
    expect(result, <String, String>{'value': 'fuchsia'});
    expect(binding.reassembled, 4);
    expect(defaultTargetPlatform, TargetPlatform.fuchsia);
    expect(extensionChangedEvents.length, 4);
    extensionChangedEvent = extensionChangedEvents.last;
    expect(extensionChangedEvent['extension'], 'ext.flutter.platformOverride');
    expect(extensionChangedEvent['value'], 'fuchsia');
    result = await hasReassemble(binding.testExtension('platformOverride', <String, String>{'value': 'default'}));
    expect(result, <String, String>{'value': 'android'});
    expect(binding.reassembled, 5);
    expect(defaultTargetPlatform, TargetPlatform.android);
    expect(extensionChangedEvents.length, 5);
    extensionChangedEvent = extensionChangedEvents.last;
    expect(extensionChangedEvent['extension'], 'ext.flutter.platformOverride');
    expect(extensionChangedEvent['value'], 'android');
    result = await hasReassemble(binding.testExtension('platformOverride', <String, String>{'value': 'iOS'}));
    expect(result, <String, String>{'value': 'iOS'});
    expect(binding.reassembled, 6);
    expect(defaultTargetPlatform, TargetPlatform.iOS);
    expect(extensionChangedEvents.length, 6);
    extensionChangedEvent = extensionChangedEvents.last;
    expect(extensionChangedEvent['extension'], 'ext.flutter.platformOverride');
    expect(extensionChangedEvent['value'], 'iOS');
    result = await hasReassemble(binding.testExtension('platformOverride', <String, String>{'value': 'linux'}));
    expect(result, <String, String>{'value': 'linux'});
    expect(binding.reassembled, 7);
    expect(defaultTargetPlatform, TargetPlatform.linux);
    expect(extensionChangedEvents.length, 7);
    extensionChangedEvent = extensionChangedEvents.last;
    expect(extensionChangedEvent['extension'], 'ext.flutter.platformOverride');
    expect(extensionChangedEvent['value'], 'linux');
    result = await hasReassemble(binding.testExtension('platformOverride', <String, String>{'value': 'windows'}));
    expect(result, <String, String>{'value': 'windows'});
    expect(binding.reassembled, 8);
    expect(defaultTargetPlatform, TargetPlatform.windows);
    expect(extensionChangedEvents.length, 8);
    extensionChangedEvent = extensionChangedEvents.last;
    expect(extensionChangedEvent['extension'], 'ext.flutter.platformOverride');
    expect(extensionChangedEvent['value'], 'windows');
    result = await hasReassemble(binding.testExtension('platformOverride', <String, String>{'value': 'bogus'}));
    expect(result, <String, String>{'value': 'android'});
    expect(binding.reassembled, 9);
    expect(defaultTargetPlatform, TargetPlatform.android);
    expect(extensionChangedEvents.length, 9);
    extensionChangedEvent = extensionChangedEvents.last;
    expect(extensionChangedEvent['extension'], 'ext.flutter.platformOverride');
    expect(extensionChangedEvent['value'], 'android');
    binding.reassembled = 0;
  });

  test('Service extensions - repaintRainbow', () async {
    Map<String, dynamic> result;
    Future<Map<String, dynamic>> pendingResult;
    bool completed;

    expect(binding.frameScheduled, isFalse);
    expect(debugRepaintRainbowEnabled, false);
    result = await binding.testExtension('repaintRainbow', <String, String>{});
    expect(result, <String, String>{'enabled': 'false'});
    expect(debugRepaintRainbowEnabled, false);
    expect(binding.frameScheduled, isFalse);
    pendingResult = binding.testExtension('repaintRainbow', <String, String>{'enabled': 'true'});
    completed = false;
    pendingResult.whenComplete(() { completed = true; });
    await binding.flushMicrotasks();
    expect(completed, true);
    expect(binding.frameScheduled, isFalse);
    result = await pendingResult;
    expect(result, <String, String>{'enabled': 'true'});
    expect(debugRepaintRainbowEnabled, true);
    result = await binding.testExtension('repaintRainbow', <String, String>{});
    expect(result, <String, String>{'enabled': 'true'});
    expect(debugRepaintRainbowEnabled, true);
    expect(binding.frameScheduled, isFalse);
    pendingResult = binding.testExtension('repaintRainbow', <String, String>{'enabled': 'false'});
    completed = false;
    pendingResult.whenComplete(() { completed = true; });
    await binding.flushMicrotasks();
    expect(completed, false);
    expect(binding.frameScheduled, isTrue);
    await binding.doFrame();
    await binding.flushMicrotasks();
    expect(completed, true);
    expect(binding.frameScheduled, isFalse);
    result = await pendingResult;
    expect(result, <String, String>{'enabled': 'false'});
    expect(debugRepaintRainbowEnabled, false);
    result = await binding.testExtension('repaintRainbow', <String, String>{});
    expect(result, <String, String>{'enabled': 'false'});
    expect(debugRepaintRainbowEnabled, false);
    expect(binding.frameScheduled, isFalse);
  });

  test('Service extensions - reassemble', () async {
    Map<String, dynamic> result;
    Future<Map<String, dynamic>> pendingResult;
    bool completed;

    completed = false;
    expect(binding.reassembled, 0);
    pendingResult = binding.testExtension('reassemble', <String, String>{});
    pendingResult.whenComplete(() { completed = true; });
    await binding.flushMicrotasks();
    expect(binding.frameScheduled, isTrue);
    expect(completed, false);
    await binding.flushMicrotasks();
    await binding.doFrame();
    await binding.flushMicrotasks();
    expect(completed, true);
    expect(binding.frameScheduled, isFalse);
    result = await pendingResult;
    expect(result, <String, String>{});
    expect(binding.reassembled, 1);
  });

  test('Service extensions - showPerformanceOverlay', () async {
    Map<String, dynamic> result;

    // The performance overlay service extension is disabled on the web.
    if (kIsWeb) {
      expect(binding.extensions.containsKey('showPerformanceOverlay'), isFalse);
      return;
    }

    expect(binding.frameScheduled, isFalse);
    expect(WidgetsApp.showPerformanceOverlayOverride, false);
    result = await binding.testExtension('showPerformanceOverlay', <String, String>{});
    expect(result, <String, String>{'enabled': 'false'});
    expect(WidgetsApp.showPerformanceOverlayOverride, false);
    result = await binding.testExtension('showPerformanceOverlay', <String, String>{'enabled': 'true'});
    expect(result, <String, String>{'enabled': 'true'});
    expect(WidgetsApp.showPerformanceOverlayOverride, true);
    result = await binding.testExtension('showPerformanceOverlay', <String, String>{});
    expect(result, <String, String>{'enabled': 'true'});
    expect(WidgetsApp.showPerformanceOverlayOverride, true);
    result = await binding.testExtension('showPerformanceOverlay', <String, String>{'enabled': 'false'});
    expect(result, <String, String>{'enabled': 'false'});
    expect(WidgetsApp.showPerformanceOverlayOverride, false);
    result = await binding.testExtension('showPerformanceOverlay', <String, String>{});
    expect(result, <String, String>{'enabled': 'false'});
    expect(WidgetsApp.showPerformanceOverlayOverride, false);
    expect(binding.frameScheduled, isFalse);
  });

  test('Service extensions - debugWidgetInspector', () async {
    Map<String, dynamic> result;
    expect(binding.frameScheduled, isFalse);
    expect(WidgetsApp.debugShowWidgetInspectorOverride, false);
    result = await binding.testExtension('debugWidgetInspector', <String, String>{});
    expect(result, <String, String>{'enabled': 'false'});
    expect(WidgetsApp.debugShowWidgetInspectorOverride, false);
    result = await binding.testExtension('debugWidgetInspector', <String, String>{'enabled': 'true'});
    expect(result, <String, String>{'enabled': 'true'});
    expect(WidgetsApp.debugShowWidgetInspectorOverride, true);
    result = await binding.testExtension('debugWidgetInspector', <String, String>{});
    expect(result, <String, String>{'enabled': 'true'});
    expect(WidgetsApp.debugShowWidgetInspectorOverride, true);
    result = await binding.testExtension('debugWidgetInspector', <String, String>{'enabled': 'false'});
    expect(result, <String, String>{'enabled': 'false'});
    expect(WidgetsApp.debugShowWidgetInspectorOverride, false);
    result = await binding.testExtension('debugWidgetInspector', <String, String>{});
    expect(result, <String, String>{'enabled': 'false'});
    expect(WidgetsApp.debugShowWidgetInspectorOverride, false);
    expect(binding.frameScheduled, isFalse);
  });

  test('Service extensions - timeDilation', () async {
    final Iterable<Map<String, dynamic>> extensionChangedEvents = binding.getServiceExtensionStateChangedEvents('ext.flutter.timeDilation');
    Map<String, dynamic> extensionChangedEvent;
    Map<String, dynamic> result;

    expect(binding.frameScheduled, isFalse);
    expect(timeDilation, 1.0);
    result = await binding.testExtension('timeDilation', <String, String>{});
    expect(result, <String, String>{'timeDilation': 1.0.toString()});
    expect(timeDilation, 1.0);
    expect(extensionChangedEvents, isEmpty);
    result = await binding.testExtension('timeDilation', <String, String>{'timeDilation': '100.0'});
    expect(result, <String, String>{'timeDilation': 100.0.toString()});
    expect(timeDilation, 100.0);
    expect(extensionChangedEvents.length, 1);
    extensionChangedEvent = extensionChangedEvents.last;
    expect(extensionChangedEvent['extension'], 'ext.flutter.timeDilation');
    expect(extensionChangedEvent['value'], 100.0.toString());
    result = await binding.testExtension('timeDilation', <String, String>{});
    expect(result, <String, String>{'timeDilation': 100.0.toString()});
    expect(timeDilation, 100.0);
    expect(extensionChangedEvents.length, 1);
    result = await binding.testExtension('timeDilation', <String, String>{'timeDilation': '1.0'});
    expect(result, <String, String>{'timeDilation': 1.0.toString()});
    expect(timeDilation, 1.0);
    expect(extensionChangedEvents.length, 2);
    extensionChangedEvent = extensionChangedEvents.last;
    expect(extensionChangedEvent['extension'], 'ext.flutter.timeDilation');
    expect(extensionChangedEvent['value'], 1.0.toString());
    result = await binding.testExtension('timeDilation', <String, String>{});
    expect(result, <String, String>{'timeDilation': 1.0.toString()});
    expect(timeDilation, 1.0);
    expect(extensionChangedEvents.length, 2);
    expect(binding.frameScheduled, isFalse);
  });

  test('Service extensions - brightnessOverride', () async {
    Map<String, dynamic> result;
    result = await binding.testExtension('brightnessOverride', <String, String>{});
    final String brightnessValue = result['value'] as String;

    expect(brightnessValue, 'Brightness.light');
  });

  test('Service extensions - activeDevToolsServerAddress', () async {
    Map<String, dynamic> result;
    result = await binding.testExtension('activeDevToolsServerAddress', <String, String>{});
    String serverAddress = result['value'] as String;
    expect(serverAddress, '');
    result = await binding.testExtension('activeDevToolsServerAddress', <String, String>{'value': 'http://127.0.0.1:9101'});
    serverAddress = result['value'] as String;
    expect(serverAddress, 'http://127.0.0.1:9101');
    result = await binding.testExtension('activeDevToolsServerAddress', <String, String>{'value': 'http://127.0.0.1:9102'});
    serverAddress = result['value'] as String;
    expect(serverAddress, 'http://127.0.0.1:9102');
  });

  test('Service extensions - connectedVmServiceUri', () async {
    Map<String, dynamic> result;
    result = await binding.testExtension('connectedVmServiceUri', <String, String>{});
    String serverAddress = result['value'] as String;
    expect(serverAddress, '');
    result = await binding.testExtension('connectedVmServiceUri', <String, String>{'value': 'http://127.0.0.1:54669/kMUMseKAnog=/'});
    serverAddress = result['value'] as String;
    expect(serverAddress, 'http://127.0.0.1:54669/kMUMseKAnog=/');
    result = await binding.testExtension('connectedVmServiceUri', <String, String>{'value': 'http://127.0.0.1:54000/kMUMseKAnog=/'});
    serverAddress = result['value'] as String;
    expect(serverAddress, 'http://127.0.0.1:54000/kMUMseKAnog=/');
  });
}
