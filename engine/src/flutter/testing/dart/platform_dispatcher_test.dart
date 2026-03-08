// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';

import 'package:test/test.dart';

void main() {
  test('ViewConstraints.tight', () {
    final tightConstraints = ViewConstraints.tight(const Size(200, 300));
    expect(tightConstraints.minWidth, 200);
    expect(tightConstraints.maxWidth, 200);
    expect(tightConstraints.minHeight, 300);
    expect(tightConstraints.maxHeight, 300);

    expect(tightConstraints.isTight, true);
    expect(tightConstraints.isSatisfiedBy(const Size(200, 300)), true);
    expect(tightConstraints.isSatisfiedBy(const Size(400, 500)), false);
    expect(tightConstraints / 2, ViewConstraints.tight(const Size(100, 150)));
  });

  test('ViewConstraints unconstrained', () {
    const defaultValues = ViewConstraints();
    expect(defaultValues.minWidth, 0);
    expect(defaultValues.maxWidth, double.infinity);
    expect(defaultValues.minHeight, 0);
    expect(defaultValues.maxHeight, double.infinity);

    expect(defaultValues.isTight, false);
    expect(defaultValues.isSatisfiedBy(const Size(200, 300)), true);
    expect(defaultValues.isSatisfiedBy(const Size(400, 500)), true);
    expect(defaultValues / 2, const ViewConstraints());
  });

  test('ViewConstraints', () {
    const constraints = ViewConstraints(
      minWidth: 100,
      maxWidth: 200,
      minHeight: 300,
      maxHeight: 400,
    );
    expect(constraints.minWidth, 100);
    expect(constraints.maxWidth, 200);
    expect(constraints.minHeight, 300);
    expect(constraints.maxHeight, 400);

    expect(constraints.isTight, false);
    expect(constraints.isSatisfiedBy(const Size(200, 300)), true);
    expect(constraints.isSatisfiedBy(const Size(400, 500)), false);
    expect(
      constraints / 2,
      const ViewConstraints(minWidth: 50, maxWidth: 100, minHeight: 150, maxHeight: 200),
    );
  });

  test('RenderingBackend has expected values and indices', () {
    expect(RenderingBackend.values.length, 6);
    expect(RenderingBackend.opengl.index, 0);
    expect(RenderingBackend.vulkan.index, 1);
    expect(RenderingBackend.software.index, 2);
    expect(RenderingBackend.metal.index, 3);
    expect(RenderingBackend.canvaskit.index, 4);
    expect(RenderingBackend.skwasm.index, 5);
  });

  test('RenderingBackend.name returns correct string', () {
    expect(RenderingBackend.opengl.name, 'opengl');
    expect(RenderingBackend.vulkan.name, 'vulkan');
    expect(RenderingBackend.software.name, 'software');
    expect(RenderingBackend.metal.name, 'metal');
    expect(RenderingBackend.canvaskit.name, 'canvaskit');
    expect(RenderingBackend.skwasm.name, 'skwasm');
  });

  test('PlatformDispatcher.renderingBackend returns a valid value', () {
    final backend = PlatformDispatcher.instance.renderingBackend;
    expect(RenderingBackend.values.contains(backend), true);
    // On native test runners, the backend should be one of the native values
    // (not canvaskit or skwasm, which are web-only).
    expect(
      backend == RenderingBackend.opengl ||
          backend == RenderingBackend.vulkan ||
          backend == RenderingBackend.software ||
          backend == RenderingBackend.metal,
      true,
      reason: 'Native test runner should report a native backend, '
          'got ${backend.name}',
    );
  });

  test('RenderingBackend values cover all indices 0..length-1', () {
    // Validates that _fromIndex can resolve every valid index.
    for (int i = 0; i < RenderingBackend.values.length; i++) {
      expect(RenderingBackend.values[i].index, i);
    }
    // Ensure the enum is not accidentally extended without updating
    // dart_ui.cc constants.
    expect(RenderingBackend.values.length, 6,
        reason: 'If you add a new RenderingBackend, update dart_ui.cc too');
  });

  test('RenderingBackend.values OOB access throws RangeError', () {
    // Validates that out-of-bounds indices cannot silently resolve to a
    // valid enum value through the values list, which is what _fromIndex
    // guards against with its assert + fallback.
    expect(() => RenderingBackend.values[-1], throwsRangeError);
    expect(() => RenderingBackend.values[6], throwsRangeError);
    expect(() => RenderingBackend.values[999], throwsRangeError);
  });

  test('scheduleWarmupFrame should call both callbacks and flush microtasks', () async {
    var microtaskFlushed = false;
    var beginFrameCalled = false;
    final drawFrameCalled = Completer<void>();
    PlatformDispatcher.instance.scheduleWarmUpFrame(
      beginFrame: () {
        expect(microtaskFlushed, false);
        expect(drawFrameCalled.isCompleted, false);
        expect(beginFrameCalled, false);
        beginFrameCalled = true;
        scheduleMicrotask(() {
          expect(microtaskFlushed, false);
          expect(drawFrameCalled.isCompleted, false);
          microtaskFlushed = true;
        });
        expect(microtaskFlushed, false);
      },
      drawFrame: () {
        expect(beginFrameCalled, true);
        expect(microtaskFlushed, true);
        expect(drawFrameCalled.isCompleted, false);
        drawFrameCalled.complete();
      },
    );
    await drawFrameCalled.future;
    expect(beginFrameCalled, true);
    expect(drawFrameCalled.isCompleted, true);
    expect(microtaskFlushed, true);
  });
}
