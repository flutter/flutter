// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PaintingBinding with memory pressure before initInstances', () {
    // Observed in devicelab: the device sends a memory pressure event to us
    // after PaintingBinding has been created but before initInstances called,
    // meaning the imageCache member is still null.
    final PaintingBinding binding = TestPaintingBinding();
    expect(binding.imageCache, null);
    binding.handleMemoryPressure();
    expect(binding.imageCache, null);
    binding.initInstances();
    expect(binding.imageCache, isNotNull);
    expect(binding.imageCache!.currentSize, 0);
  });
}

class TestBindingBase implements BindingBase {
  @override
  void initInstances() {}

  @override
  void initServiceExtensions() {}

  @override
  Future<void> lockEvents(Future<void> Function() callback) async {}

  @override
  bool get locked => throw UnimplementedError();

  @override
  Future<void> performReassemble() {
    throw UnimplementedError();
  }

  @override
  void postEvent(String eventKind, Map<String, dynamic> eventData) {}

  @override
  Future<void> reassembleApplication() {
    throw UnimplementedError();
  }

  @override
  void registerBoolServiceExtension({required String name, required AsyncValueGetter<bool> getter, required AsyncValueSetter<bool> setter}) {}

  @override
  void registerNumericServiceExtension({required String name, required AsyncValueGetter<double> getter, required AsyncValueSetter<double> setter}) {}

  @override
  void registerServiceExtension({required String name, required ServiceExtensionCallback callback}) {}

  @override
  void registerSignalServiceExtension({required String name, required AsyncCallback callback}) {}

  @override
  void registerStringServiceExtension({required String name, required AsyncValueGetter<String> getter, required AsyncValueSetter<String> setter}) {}

  @override
  void unlocked() {}

  @override
  ui.SingletonFlutterWindow get window => TestWindow(window: ui.window);

  @override
  ui.PlatformDispatcher get platformDispatcher => TestWindow(window: ui.window).platformDispatcher;
}

class TestPaintingBinding extends TestBindingBase with SchedulerBinding, ServicesBinding, PaintingBinding { }
