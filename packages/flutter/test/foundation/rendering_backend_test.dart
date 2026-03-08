// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show defaultRenderingBackend;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('defaultRenderingBackend', () {
    test('returns a valid RenderingBackend value', () {
      final ui.RenderingBackend backend = defaultRenderingBackend;
      expect(ui.RenderingBackend.values.contains(backend), true);
    });

    test('delegates to PlatformDispatcher.instance.renderingBackend', () {
      expect(
        defaultRenderingBackend,
        ui.PlatformDispatcher.instance.renderingBackend,
      );
    });

    test('returns a native backend in test runner', () {
      // The Flutter test runner uses a software renderer.
      final ui.RenderingBackend backend = defaultRenderingBackend;
      expect(
        backend == ui.RenderingBackend.opengl ||
            backend == ui.RenderingBackend.vulkan ||
            backend == ui.RenderingBackend.software ||
            backend == ui.RenderingBackend.metal,
        true,
        reason: 'Test runner should report a native backend, '
            'got ${backend.name}',
      );
    });
  });

  group('RenderingBackend enum', () {
    test('has exactly 6 values', () {
      expect(ui.RenderingBackend.values.length, 6);
    });

    test('indices are sequential starting from 0', () {
      for (int i = 0; i < ui.RenderingBackend.values.length; i++) {
        expect(ui.RenderingBackend.values[i].index, i);
      }
    });

    test('names are unique', () {
      final names = ui.RenderingBackend.values.map((e) => e.name).toSet();
      expect(names.length, ui.RenderingBackend.values.length);
    });

    test('contains expected native backends', () {
      expect(
        ui.RenderingBackend.values.map((e) => e.name),
        containsAll(<String>['opengl', 'vulkan', 'software', 'metal']),
      );
    });

    test('contains expected web backends', () {
      expect(
        ui.RenderingBackend.values.map((e) => e.name),
        containsAll(<String>['canvaskit', 'skwasm']),
      );
    });
  });
}
