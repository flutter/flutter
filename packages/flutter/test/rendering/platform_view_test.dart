// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../services/fake_platform_views.dart';
import 'rendering_tester.dart';

void main() {

  group('PlatformViewRenderBox', () {
    FakePlatformViewController fakePlatformViewController;
    PlatformViewRenderBox platformViewRenderBox;
    setUp(() {
      renderer; // Initialize bindings
      fakePlatformViewController = FakePlatformViewController(0);
      platformViewRenderBox = PlatformViewRenderBox(
        controller: fakePlatformViewController,
        hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
          Factory<VerticalDragGestureRecognizer>(
            () {
              return VerticalDragGestureRecognizer();
            },
          ),
        },
      );
    });

    test('layout should size to max constraint', () {
      layout(platformViewRenderBox);
      platformViewRenderBox.layout(const BoxConstraints(minWidth: 50, minHeight: 50, maxWidth: 100, maxHeight: 100));
      expect(platformViewRenderBox.size, const Size(100, 100));
    });

    test('send semantics update if id is changed', (){
      final RenderConstrainedBox tree = RenderConstrainedBox(
        additionalConstraints: const BoxConstraints.tightFor(height: 20.0, width: 20.0),
        child: platformViewRenderBox,
      );
      int semanticsUpdateCount = 0;
      final SemanticsHandle semanticsHandle = renderer.pipelineOwner.ensureSemantics(
          listener: () {
            ++semanticsUpdateCount;
          }
      );
      layout(tree, phase: EnginePhase.flushSemantics);
      // Initial semantics update
      expect(semanticsUpdateCount, 1);

      semanticsUpdateCount = 0;

      // Request semantics update even though nothing changed.
      platformViewRenderBox.markNeedsSemanticsUpdate();
      pumpFrame(phase: EnginePhase.flushSemantics);
      expect(semanticsUpdateCount, 0);

      semanticsUpdateCount = 0;

      final FakePlatformViewController updatedFakePlatformViewController = FakePlatformViewController(10);
      platformViewRenderBox.controller = updatedFakePlatformViewController;
      pumpFrame(phase: EnginePhase.flushSemantics);
      // Update id should update the semantics.
      expect(semanticsUpdateCount, 1);

      semanticsHandle.dispose();
    });

    test('mouse hover events are dispatched via PlatformViewController.dispatchPointerEvent', () {
      layout(platformViewRenderBox);
      pumpFrame(phase: EnginePhase.flushSemantics);

      ui.window.onPointerDataPacket(ui.PointerDataPacket(data: <ui.PointerData>[
        _pointerData(ui.PointerChange.add, const Offset(0, 0)),
        _pointerData(ui.PointerChange.hover, const Offset(10, 10)),
        _pointerData(ui.PointerChange.remove, const Offset(10, 10)),
      ]));

      expect(fakePlatformViewController.dispatchedPointerEvents, isNotEmpty);
    });

  }, skip: isBrowser); // TODO(yjbanov): fails on Web with obscured stack trace: https://github.com/flutter/flutter/issues/42770
}

ui.PointerData _pointerData(
  ui.PointerChange change,
  Offset logicalPosition, {
  int device = 0,
  PointerDeviceKind kind = PointerDeviceKind.mouse,
}) {
  return ui.PointerData(
    change: change,
    physicalX: logicalPosition.dx * ui.window.devicePixelRatio,
    physicalY: logicalPosition.dy * ui.window.devicePixelRatio,
    kind: kind,
    device: device,
  );
}
